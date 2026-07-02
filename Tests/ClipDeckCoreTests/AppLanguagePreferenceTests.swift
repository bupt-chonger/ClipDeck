import Foundation
import Testing
@testable import ClipDeckCore

@Suite("App language preference")
struct AppLanguagePreferenceTests {
    @Test("language preference round trips through user defaults")
    func languagePreferenceRoundTrips() {
        let suiteName = "ClipDeckLanguageTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = AppLanguagePreferenceStore(defaults: defaults)

        #expect(store.load() == .simplifiedChinese)

        store.save(.english)
        #expect(store.load() == .english)

        store.save(.simplifiedChinese)
        #expect(store.load() == .simplifiedChinese)
    }

    @Test("language preference exposes localized names")
    func languagePreferenceExposesLocalizedNames() {
        #expect(AppLanguagePreference.english.displayName == "English")
        #expect(AppLanguagePreference.simplifiedChinese.displayName == "中文简体")
    }
}
