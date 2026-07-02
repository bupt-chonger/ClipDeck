import Foundation

public enum AppLanguagePreference: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: "English"
        case .simplifiedChinese: "中文简体"
        }
    }
}

public struct AppLanguagePreferenceStore {
    public static let defaultsKey = "appLanguage"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppLanguagePreference {
        guard let rawValue = defaults.string(forKey: Self.defaultsKey),
              let language = AppLanguagePreference(rawValue: rawValue) else {
            return .simplifiedChinese
        }
        return language
    }

    public func save(_ language: AppLanguagePreference) {
        defaults.set(language.rawValue, forKey: Self.defaultsKey)
    }
}
