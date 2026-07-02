import ClipDeckCore
import Foundation

enum HotKeyPreferenceStore {
    static let defaultsKey = "globalHotKey"

    static func load(from defaults: UserDefaults = .standard) -> KeyboardShortcutPreference {
        guard
            let rawValue = defaults.string(forKey: defaultsKey),
            let shortcut = KeyboardShortcutPreference(rawValue: rawValue)
        else {
            return .default
        }
        return shortcut
    }

    static func save(_ shortcut: KeyboardShortcutPreference, to defaults: UserDefaults = .standard) {
        defaults.set(shortcut.rawValue, forKey: defaultsKey)
    }
}
