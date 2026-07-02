import Foundation

public struct ClipboardCapturePolicyStore {
    public static let ignoresPasswordManagersKey = "privacy.ignoresPasswordManagers"
    public static let ignoresPrivateBrowsingKey = "privacy.ignoresPrivateBrowsing"
    public static let ignoresSensitiveContentKey = "privacy.ignoresSensitiveContent"
    public static let ignoredBundleIdentifiersKey = "privacy.ignoredBundleIdentifiers"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> ClipboardCapturePolicy {
        ClipboardCapturePolicy(
            ignoresPasswordManagers: bool(forKey: Self.ignoresPasswordManagersKey, defaultValue: true),
            ignoresPrivateBrowsing: bool(forKey: Self.ignoresPrivateBrowsingKey, defaultValue: true),
            ignoresSensitiveContent: bool(forKey: Self.ignoresSensitiveContentKey, defaultValue: true),
            ignoredBundleIdentifiers: Set(defaults.stringArray(forKey: Self.ignoredBundleIdentifiersKey) ?? [])
        )
    }

    public func save(_ policy: ClipboardCapturePolicy) {
        defaults.set(policy.ignoresPasswordManagers, forKey: Self.ignoresPasswordManagersKey)
        defaults.set(policy.ignoresPrivateBrowsing, forKey: Self.ignoresPrivateBrowsingKey)
        defaults.set(policy.ignoresSensitiveContent, forKey: Self.ignoresSensitiveContentKey)
        defaults.set(Array(policy.ignoredBundleIdentifiers).sorted(), forKey: Self.ignoredBundleIdentifiersKey)
    }

    private func bool(forKey key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return defaults.bool(forKey: key)
    }
}
