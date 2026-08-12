import AppKit
import ClipDeckCore

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private weak var floatingController: FloatingClipboardController?
    private weak var settingsWindowController: SettingsWindowController?
    private let menu = NSMenu()

    init(
        floatingController: FloatingClipboardController,
        settingsWindowController: SettingsWindowController
    ) {
        self.floatingController = floatingController
        self.settingsWindowController = settingsWindowController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
        configureMenu()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.image = NSImage(
            systemSymbolName: "doc.on.clipboard",
            accessibilityDescription: "ClipDeck"
        )
        button.image?.isTemplate = true
        button.toolTip = "ClipDeck"
        button.setAccessibilityLabel("ClipDeck")
    }

    private func configureMenu() {
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        let strings = AppStrings(AppLanguagePreferenceStore().load())
        menu.removeAllItems()

        let toggleItem = NSMenuItem(
            title: strings.showHideClipboard,
            action: #selector(toggleShelf),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        let settingsItem = NSMenuItem(
            title: strings.settings,
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: strings.quit,
            action: #selector(terminateApplication),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func toggleShelf() {
        floatingController?.toggle()
    }

    @objc private func openSettings() {
        settingsWindowController?.show()
    }

    @objc private func terminateApplication() {
        NSApp.terminate(nil)
    }
}
