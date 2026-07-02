import ClipDeckCore
import SwiftUI

struct HeaderView: View {
    @Binding var query: String
    @AppStorage(AppLanguagePreferenceStore.defaultsKey) private var languageRawValue = AppLanguagePreferenceStore().load().rawValue

    private var strings: AppStrings {
        AppStrings(AppLanguagePreference(rawValue: languageRawValue) ?? .simplifiedChinese)
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ClipDeck")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(strings.headerDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(strings.searchClips, text: $query)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(width: 300, height: 36)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }
}
