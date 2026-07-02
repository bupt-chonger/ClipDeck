import ClipDeckCore
import SwiftUI

struct EmptyStateView: View {
    @AppStorage(AppLanguagePreferenceStore.defaultsKey) private var languageRawValue = AppLanguagePreferenceStore().load().rawValue

    private var strings: AppStrings {
        AppStrings(AppLanguagePreference(rawValue: languageRawValue) ?? .simplifiedChinese)
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(strings.noClips)
                .font(.title3.weight(.semibold))
            Text(strings.emptyStateDescription)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
