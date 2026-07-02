import AppKit
import ClipDeckCore
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let environment: ClipDeckEnvironment
    private var window: NSWindow?

    init(environment: ClipDeckEnvironment) {
        self.environment = environment
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window

        window.title = AppStrings(AppLanguagePreferenceStore().load()).settingsWindowTitle
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }

    private func makeWindow() -> NSWindow {
        let hostingView = NSHostingView(rootView: SettingsView(environment: environment))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 540),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = AppStrings(AppLanguagePreferenceStore().load()).settingsWindowTitle
        window.contentView = hostingView
        window.minSize = NSSize(width: 760, height: 500)
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.delegate = self
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        return window
    }
}
