import ClipDeckCore
import SwiftUI

struct KindBadge: View {
    let kind: ClipKind
    @AppStorage(AppLanguagePreferenceStore.defaultsKey) private var languageRawValue = AppLanguagePreferenceStore().load().rawValue

    private var strings: AppStrings {
        AppStrings(AppLanguagePreference(rawValue: languageRawValue) ?? .simplifiedChinese)
    }

    var body: some View {
        Label(strings.kindLabel(kind), systemImage: iconName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
    }

    private var iconName: String {
        switch kind {
        case .text: "text.alignleft"
        case .link: "link"
        case .image: "photo"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .color: "paintpalette"
        }
    }

    private var color: Color {
        switch kind {
        case .text: .secondary
        case .link: AppPalette.teal
        case .image: AppPalette.indigo
        case .code: AppPalette.amber
        case .color: AppPalette.mint
        }
    }
}
