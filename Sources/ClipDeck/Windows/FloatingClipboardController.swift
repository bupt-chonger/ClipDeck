import AppKit
import ClipDeckCore
import SwiftUI

@MainActor
final class FloatingClipboardController {
    private let panel = FloatingClipboardPanel()
    private let library: ClipboardLibrary
    private let store: LibrarySnapshotStore
    private let animationState = FloatingClipboardAnimationState()
    private var notificationTokens: [NSObjectProtocol] = []
    private var hideCompletions = ShelfHideCompletionQueue()
    private var pasteFocusTarget: PasteFocusTarget?

    init(library: ClipboardLibrary, store: LibrarySnapshotStore) {
        self.library = library
        self.store = store
        panel.contentView = TransparentHostingView(
            rootView: FloatingClipboardView(
                library: library,
                store: store,
                animationState: animationState,
                close: { [weak self] in self?.hide() },
                pasteIntoTargetApplication: { [weak self] in self?.hideAndPasteIntoTargetApplication() },
                openSettings: { [weak self] item in
                    self?.hide()
                    ClipDeckEnvironment.shared.showSettingsWindow(for: item)
                }
            )
        )
        installFocusObservers()
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        let screen = ActiveScreenResolver.screenForMouse()
        let targetFrame = BottomShelfPlacement.panelFrame(in: screen.visibleFrame)
        pasteFocusTarget = PasteFocusTarget.capture()

        hideCompletions.reset()
        animationState.isPresented = false
        panel.setFrame(targetFrame, display: true)
        panel.orderFrontRegardless()
        panel.makeKey()

        withAnimation(.easeOut(duration: 0.22)) {
            animationState.isPresented = true
        }
    }

    func hide() {
        hide(afterHide: nil)
    }

    private func hideAndPasteIntoTargetApplication() {
        let focusTarget = pasteFocusTarget
        hide { [weak self] in
            focusTarget?.restore()
            self?.sendPasteShortcutAfterFocusRestores(to: focusTarget)
        }
    }

    private func hide(afterHide completion: (() -> Void)?) {
        guard panel.isVisible else { return }
        guard hideCompletions.beginHide(afterHide: completion) == .startHide else { return }

        withAnimation(.easeIn(duration: ShelfPasteTiming.hideAnimationDuration)) {
            animationState.isPresented = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + ShelfPasteTiming.hideAnimationDuration) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.panel.orderOut(nil)
                self.hideCompletions.finishHide().forEach { $0() }
            }
        }
    }

    private func sendPasteShortcutAfterFocusRestores(to focusTarget: PasteFocusTarget?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + ShelfPasteTiming.activationDelay) {
            focusTarget?.sendPasteShortcut()
        }
    }

    private func installFocusObservers() {
        let center = NotificationCenter.default
        notificationTokens.append(
            center.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: panel,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.hide()
                }
            }
        )
        notificationTokens.append(
            center.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: NSApp,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.hide()
                }
            }
        )
    }
}
