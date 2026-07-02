import AppKit
import SwiftUI

final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }

    required init(rootView: Content) {
        super.init(rootView: rootView)
        configureTransparentSurface()
    }

    @MainActor @preconcurrency required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
        configureTransparentSurface()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureTransparentSurface()
        window?.isOpaque = false
        window?.backgroundColor = .clear
    }

    override func layout() {
        super.layout()
        configureTransparentSurface()
    }

    private func configureTransparentSurface() {
        wantsLayer = true
        layer?.isOpaque = false
        layer?.backgroundColor = NSColor.clear.cgColor
    }
}
