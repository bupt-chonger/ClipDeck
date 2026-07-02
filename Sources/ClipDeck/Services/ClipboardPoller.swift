import AppKit
import ClipDeckCore
import Foundation

@MainActor
final class ClipboardPoller {
    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private let library: ClipboardLibrary
    private let store: LibrarySnapshotStore
    private let policyStore: ClipboardCapturePolicyStore

    init(
        library: ClipboardLibrary,
        store: LibrarySnapshotStore,
        policyStore: ClipboardCapturePolicyStore = ClipboardCapturePolicyStore()
    ) {
        self.library = library
        self.store = store
        self.policyStore = policyStore
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        let sourceApp = currentSourceApp()
        if sourceApp.bundleIdentifier == Bundle.main.bundleIdentifier {
            return
        }

        let policy = policyStore.load()
        if let image = PasteboardImageTransfer.readImage(from: pasteboard) {
            guard policy.shouldCaptureImage(source: sourceApp) else { return }
            library.captureImage(
                data: image.data,
                pasteboardType: image.type,
                source: sourceApp.name,
                sourceBundleIdentifier: sourceApp.bundleIdentifier
            )
            store.save(library)
            return
        }

        if let text = pasteboard.string(forType: .string) {
            guard policy.shouldCaptureText(text, source: sourceApp) else { return }
            library.capture(
                text: text,
                source: sourceApp.name,
                sourceBundleIdentifier: sourceApp.bundleIdentifier
            )
            store.save(library)
        }
    }

    private func currentSourceApp() -> ClipboardSourceApp {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return ClipboardSourceApp(name: "Clipboard")
        }

        let name = app.localizedName?.isEmpty == false ? app.localizedName! : "Clipboard"
        return ClipboardSourceApp(
            name: name,
            bundleIdentifier: app.bundleIdentifier,
            windowTitle: frontmostWindowTitle(for: app.processIdentifier)
        )
    }

    private func frontmostWindowTitle(for processIdentifier: pid_t) -> String? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        return windowList.first { info in
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t else { return false }
            return ownerPID == processIdentifier
        }?[kCGWindowName as String] as? String
    }
}
