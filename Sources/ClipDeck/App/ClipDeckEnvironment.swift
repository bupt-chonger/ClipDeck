import ClipDeckCore
import Foundation
import Observation

@MainActor
@Observable
final class ClipDeckEnvironment {
    static let shared = ClipDeckEnvironment()

    var library: ClipboardLibrary?
    var store: LibrarySnapshotStore?
    var hotKeyMonitor: GlobalHotKeyMonitor?
    var policyStore: ClipboardCapturePolicyStore?
    var settingsWindowController: SettingsWindowController?
    var settingsTargetSource: String?
    var settingsTargetBundleIdentifier: String?

    private init() {}

    var settingsTargetTitle: String {
        settingsTargetSource ?? "当前 App"
    }

    func configure(
        library: ClipboardLibrary,
        store: LibrarySnapshotStore,
        hotKeyMonitor: GlobalHotKeyMonitor,
        policyStore: ClipboardCapturePolicyStore,
        settingsWindowController: SettingsWindowController
    ) {
        self.library = library
        self.store = store
        self.hotKeyMonitor = hotKeyMonitor
        self.policyStore = policyStore
        self.settingsWindowController = settingsWindowController
    }

    func setSettingsTarget(from item: ClipItem?) {
        settingsTargetSource = item?.source
        settingsTargetBundleIdentifier = item?.sourceBundleIdentifier
    }

    func showSettingsWindow(for item: ClipItem?) {
        setSettingsTarget(from: item)
        settingsWindowController?.show()
    }

    @discardableResult
    func clearAllRecords() -> Int {
        guard let library else { return 0 }
        let removed = library.clearAll()
        store?.save(library)
        return removed
    }

    func loadCapturePolicy() -> ClipboardCapturePolicy {
        policyStore?.load() ?? .default
    }

    func saveCapturePolicy(_ policy: ClipboardCapturePolicy) {
        policyStore?.save(policy)
    }

    func ignoreSettingsTargetApp() -> ClipboardCapturePolicy {
        var policy = loadCapturePolicy()
        if let bundleIdentifier = settingsTargetBundleIdentifier, !bundleIdentifier.isEmpty {
            policy.ignoredBundleIdentifiers.insert(bundleIdentifier)
            saveCapturePolicy(policy)
        }
        return policy
    }

    func allowCaptureFromBundleIdentifier(_ bundleIdentifier: String) -> ClipboardCapturePolicy {
        let policy = loadCapturePolicy().allowingBundleIdentifier(bundleIdentifier)
        saveCapturePolicy(policy)
        return policy
    }
}
