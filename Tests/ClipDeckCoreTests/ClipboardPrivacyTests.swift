import Foundation
import Testing
@testable import ClipDeckCore

@Suite("Clipboard privacy filtering")
struct ClipboardPrivacyTests {
    @Test("default policy ignores password managers")
    func defaultPolicyIgnoresPasswordManagers() {
        let policy = ClipboardCapturePolicy.default
        let source = ClipboardSourceApp(
            name: "1Password",
            bundleIdentifier: "com.1password.1password",
            windowTitle: "1Password"
        )

        #expect(policy.shouldCaptureText("personal@example.com", source: source) == false)
        #expect(policy.shouldCaptureImage(source: source) == false)
    }

    @Test("default policy ignores private browsing windows")
    func defaultPolicyIgnoresPrivateBrowsingWindows() {
        let policy = ClipboardCapturePolicy.default
        let source = ClipboardSourceApp(
            name: "Safari",
            bundleIdentifier: "com.apple.Safari",
            windowTitle: "Private Browsing - Apple"
        )

        #expect(policy.shouldCaptureText("https://example.com/private", source: source) == false)
    }

    @Test("default policy ignores sensitive text")
    func defaultPolicyIgnoresSensitiveText() {
        let policy = ClipboardCapturePolicy.default
        let source = ClipboardSourceApp(name: "Notes", bundleIdentifier: "com.apple.Notes")

        #expect(policy.shouldCaptureText("Your verification code is 482913", source: source) == false)
        #expect(policy.shouldCaptureText("sk-abc1234567890abcdefghijklmnopqrstuvwxyz", source: source) == false)
        #expect(policy.shouldCaptureText("-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----", source: source) == false)
    }

    @Test("disabled filters allow normal capture decisions")
    func disabledFiltersAllowNormalCaptureDecisions() {
        let policy = ClipboardCapturePolicy(
            ignoresPasswordManagers: false,
            ignoresPrivateBrowsing: false,
            ignoresSensitiveContent: false,
            ignoredBundleIdentifiers: ["com.example.SecretApp"]
        )
        let passwordManager = ClipboardSourceApp(
            name: "1Password",
            bundleIdentifier: "com.1password.1password",
            windowTitle: "Private Browsing"
        )
        let ignoredApp = ClipboardSourceApp(name: "Secret", bundleIdentifier: "com.example.SecretApp")

        #expect(policy.shouldCaptureText("Your verification code is 482913", source: passwordManager))
        #expect(policy.shouldCaptureImage(source: passwordManager))
        #expect(policy.shouldCaptureText("ordinary note", source: ignoredApp) == false)
    }

    @Test("policy store round trips defaults")
    func policyStoreRoundTripsDefaults() {
        let suiteName = "ClipDeckPrivacyTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ClipboardCapturePolicyStore(defaults: defaults)

        let saved = ClipboardCapturePolicy(
            ignoresPasswordManagers: false,
            ignoresPrivateBrowsing: true,
            ignoresSensitiveContent: false,
            ignoredBundleIdentifiers: ["com.apple.Terminal"]
        )
        store.save(saved)

        #expect(store.load() == saved)
    }
}
