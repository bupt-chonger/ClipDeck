import AppKit
import ClipDeckCore
import SwiftUI

@main
struct ClipDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(environment: ClipDeckEnvironment.shared)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var library: ClipboardLibrary?
    private var store: LibrarySnapshotStore?
    private var poller: ClipboardPoller?
    private var floatingController: FloatingClipboardController?
    private var hotKeyMonitor: GlobalHotKeyMonitor?
    private var policyStore: ClipboardCapturePolicyStore?
    private var retentionStore: ClipboardRetentionPreferenceStore?
    private var settingsWindowController: SettingsWindowController?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appending(path: "ClipDeck")
            .appending(path: "library.json")
        let cloudKitContainerIdentifier = Bundle.main.object(
            forInfoDictionaryKey: "CloudKitContainerIdentifier"
        ) as? String
        let store = LibrarySnapshotStore(
            fileURL: supportURL,
            cloudKitContainerIdentifier: cloudKitContainerIdentifier
        )
        let snapshot = store.loadSnapshot()
        let library = ClipboardLibrary(
            seed: store.hasSnapshot ? snapshot.items : ClipboardLibrary.demo().items,
            pinboards: snapshot.pinboards,
            customTags: snapshot.customTags
        )

        self.library = library
        self.store = store

        let policyStore = ClipboardCapturePolicyStore()
        self.policyStore = policyStore
        let retentionStore = ClipboardRetentionPreferenceStore()
        self.retentionStore = retentionStore

        let poller = ClipboardPoller(library: library, store: store, policyStore: policyStore, retentionStore: retentionStore)
        self.poller = poller
        poller.start()

        let floatingController = FloatingClipboardController(library: library, store: store)
        self.floatingController = floatingController

        let hotKeyMonitor = GlobalHotKeyMonitor {
            Task { @MainActor in
                floatingController.toggle()
            }
        }
        self.hotKeyMonitor = hotKeyMonitor

        let settingsWindowController = SettingsWindowController(environment: ClipDeckEnvironment.shared)
        self.settingsWindowController = settingsWindowController

        let statusBarController = StatusBarController(
            floatingController: floatingController,
            settingsWindowController: settingsWindowController
        )
        self.statusBarController = statusBarController

        ClipDeckEnvironment.shared.configure(
            library: library,
            store: store,
            hotKeyMonitor: hotKeyMonitor,
            policyStore: policyStore,
            retentionStore: retentionStore,
            settingsWindowController: settingsWindowController
        )

        hotKeyMonitor.start(shortcut: HotKeyPreferenceStore.load())
        floatingController.show()

        // The SwiftUI Settings scene can restore its window when a menu-bar
        // app is launched. ClipDeck owns settings through its AppKit window
        // controller, so dismiss only that automatically restored scene on
        // launch while keeping the explicit Settings actions available.
        Task { @MainActor in
            closeAutomaticallyRestoredSettingsWindow()
            try? await Task.sleep(for: .milliseconds(120))
            closeAutomaticallyRestoredSettingsWindow()
        }
    }

    @MainActor
    private func closeAutomaticallyRestoredSettingsWindow() {
        NSApp.windows
            .filter { $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" }
            .forEach { $0.close() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        poller?.stop()
        hotKeyMonitor?.stop()
    }
}
