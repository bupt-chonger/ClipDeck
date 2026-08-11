import AppKit
import ClipDeckCore
import Foundation

/// Tracks the last external frontmost application so clipboard changes are
/// attributed to the app that owned the insertion point, not to ClipDeck's
/// shelf after it becomes active.
@MainActor
final class ClipboardContextMonitor {
    private var activationObserver: NSObjectProtocol?
    private var latestExternalApplication: NSRunningApplication?

    init() {
        refresh()
        installObserver()
    }

    func start() {
        installObserver()
        refresh()
    }

    func stop() {
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
            self.activationObserver = nil
        }
    }

    func sourceApplication() -> ClipboardSourceApp? {
        guard let application = latestExternalApplication else { return nil }
        let name = application.localizedName?.isEmpty == false
            ? application.localizedName!
            : application.bundleIdentifier ?? ""
        guard !name.isEmpty else { return nil }

        return ClipboardSourceApp(
            name: name,
            bundleIdentifier: application.bundleIdentifier,
            windowTitle: frontmostWindowTitle(for: application.processIdentifier)
        )
    }

    private func installObserver() {
        guard activationObserver == nil else { return }
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func refresh() {
        guard let application = NSWorkspace.shared.frontmostApplication else { return }
        guard application.processIdentifier != NSRunningApplication.current.processIdentifier else { return }
        latestExternalApplication = application
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
