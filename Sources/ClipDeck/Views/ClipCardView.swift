import ClipDeckCore
import SwiftUI

struct ClipCardView: View {
    let item: ClipItem
    let isSelected: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void
    @AppStorage(AppLanguagePreferenceStore.defaultsKey) private var languageRawValue = AppLanguagePreferenceStore().load().rawValue

    private var strings: AppStrings {
        AppStrings(AppLanguagePreference(rawValue: languageRawValue) ?? .simplifiedChinese)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                KindBadge(kind: item.kind)
                Spacer()
            }

            if item.hasImagePreview {
                ImagePreviewView(item: item)
                    .frame(height: 108)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            } else {
                Text(item.preview)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            HStack {
                Label(item.source, systemImage: "app.badge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                }
                .help(strings.copy)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .help(strings.delete)
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
        .frame(width: 238, height: 196)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? AppPalette.teal : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
        }
    }

    private var cardBackground: some ShapeStyle {
        isSelected ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.thinMaterial)
    }
}
