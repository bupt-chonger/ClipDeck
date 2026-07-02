import Foundation
import Testing
@testable import ClipDeckCore

@Suite("Clipboard retention preference")
struct ClipboardRetentionPreferenceTests {
    @Test("retention preference defaults to unlimited")
    func retentionPreferenceDefaultsToUnlimited() {
        let suiteName = "ClipDeckRetentionTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ClipboardRetentionPreferenceStore(defaults: defaults)

        #expect(store.load() == .unlimited)
    }

    @Test("retention preference round trips limited values")
    func retentionPreferenceRoundTripsLimitedValues() {
        let suiteName = "ClipDeckRetentionTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = ClipboardRetentionPreferenceStore(defaults: defaults)

        store.save(.limited(500))

        #expect(store.load() == .limited(500))
    }
}
