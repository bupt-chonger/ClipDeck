import AppKit
import ApplicationServices
import ClipDeckCore

@MainActor
final class PasteFocusTarget {
    private enum KeyCode {
        static let command: CGKeyCode = 0x37
        static let v: CGKeyCode = 0x09
    }

    private let application: NSRunningApplication?
    private let focusedElement: AXUIElement?
    var processIdentifier: pid_t? {
        application?.processIdentifier
    }

    private init(application: NSRunningApplication?, focusedElement: AXUIElement?) {
        self.application = application
        self.focusedElement = focusedElement
    }

    static func capture() -> PasteFocusTarget {
        guard let application = NSWorkspace.shared.frontmostApplication,
              application.processIdentifier != NSRunningApplication.current.processIdentifier
        else {
            return PasteFocusTarget(application: nil, focusedElement: nil)
        }

        guard isAccessibilityTrusted(promptPolicy: .silent) else {
            return PasteFocusTarget(application: application, focusedElement: nil)
        }

        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        var focusedValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        return PasteFocusTarget(
            application: application,
            focusedElement: result == .success ? (focusedValue as! AXUIElement?) : nil
        )
    }

    static func isAccessibilityTrusted(promptPolicy: AccessibilityPermissionPromptPolicy = .silent) -> Bool {
        guard promptPolicy.shouldPromptSystemDialog else {
            return AXIsProcessTrusted()
        }
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func restore() {
        application?.activate(options: [])

        guard let application, let focusedElement else { return }
        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        AXUIElementSetAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            focusedElement
        )
        AXUIElementSetAttributeValue(
            focusedElement,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )
    }

    func sendPasteShortcut() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let commandDown = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.command, keyDown: true)
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.v, keyDown: true)
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.v, keyDown: false)
        let commandUp = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.command, keyDown: false)

        commandDown?.flags = .maskCommand
        vDown?.flags = .maskCommand
        vUp?.flags = .maskCommand
        commandUp?.flags = []

        [commandDown, vDown, vUp, commandUp].forEach { event in
            event?.post(tap: .cghidEventTap)
        }
    }
}
