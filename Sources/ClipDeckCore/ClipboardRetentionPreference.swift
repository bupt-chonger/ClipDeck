import Foundation

public enum ClipboardRetentionPreference: Equatable, Sendable {
    case unlimited
    case limited(Int)

    public var maxItems: Int? {
        switch self {
        case .unlimited:
            nil
        case .limited(let value):
            max(0, value)
        }
    }
}

public struct ClipboardRetentionPreferenceStore {
    public static let maxItemsKey = "retention.maxItems"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> ClipboardRetentionPreference {
        guard defaults.object(forKey: Self.maxItemsKey) != nil else { return .unlimited }
        let value = defaults.integer(forKey: Self.maxItemsKey)
        guard value > 0 else { return .unlimited }
        return .limited(value)
    }

    public func save(_ preference: ClipboardRetentionPreference) {
        switch preference {
        case .unlimited:
            defaults.removeObject(forKey: Self.maxItemsKey)
        case .limited(let value):
            if value > 0 {
                defaults.set(value, forKey: Self.maxItemsKey)
            } else {
                defaults.removeObject(forKey: Self.maxItemsKey)
            }
        }
    }
}
