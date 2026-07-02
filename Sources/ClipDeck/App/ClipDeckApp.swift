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
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appending(path: "ClipDeck")
            .appending(path: "library.json")
        let store = LibrarySnapshotStore(fileURL: supportURL)
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

        let poller = ClipboardPoller(library: library, store: store, policyStore: policyStore)
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

        ClipDeckEnvironment.shared.configure(
            library: library,
            store: store,
            hotKeyMonitor: hotKeyMonitor,
            policyStore: policyStore,
            settingsWindowController: settingsWindowController
        )

        hotKeyMonitor.start(shortcut: HotKeyPreferenceStore.load())
        floatingController.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        poller?.stop()
        hotKeyMonitor?.stop()
    }
}
