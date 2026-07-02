import AppKit
import ClipDeckCore

final class FloatingClipboardPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = ShelfWindowChrome.usesSystemWindowShadow
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        animationBehavior = .utilityWindow
    }
}
