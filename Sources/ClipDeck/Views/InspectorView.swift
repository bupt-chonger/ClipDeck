import ClipDeckCore
import SwiftUI

struct InspectorView: View {
    let item: ClipItem
    let onCopy: (ClipItem) -> Void
    let onDelete: (ClipItem) -> Void
    let onSave: (ClipItem, String) -> Void
    @State private var draft = ""
    @AppStorage(AppLanguagePreferenceStore.defaultsKey) private var languageRawValue = AppLanguagePreferenceStore().load().rawValue

    private var strings: AppStrings {
        AppStrings(AppLanguagePreference(rawValue: languageRawValue) ?? .simplifiedChinese)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    KindBadge(kind: item.kind)
                    Text(item.title)
                        .font(.title2.weight(.semibold))
                        .lineLimit(2)
                }
                Spacer()
                Button {
                    onCopy(item)
                } label: {
                    Label(strings.copy, systemImage: "doc.on.doc")
                }
                Button(role: .destructive) {
                    onDelete(item)
                } label: {
                    Image(systemName: "trash")
                }
                .help(strings.delete)
            }

            if item.hasImagePreview {
                ImagePreviewView(item: item, contentMode: .fit)
                    .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.08))
                    }
            } else {
                TextEditor(text: $draft)
                    .font(.system(.body, design: item.kind == .code ? .monospaced : .default))
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.08))
                    }
            }

            HStack {
                Label(item.source, systemImage: "app.badge")
                Spacer()
                Text(item.updatedAt, style: .relative)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button(strings.saveEdit) {
                    onSave(item, draft)
                }
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(item.hasImagePreview || draft == item.content)
            }
        }
        .padding(24)
        .onAppear {
            draft = item.content
        }
        .onChange(of: item.id) {
            draft = item.content
        }
    }
}
