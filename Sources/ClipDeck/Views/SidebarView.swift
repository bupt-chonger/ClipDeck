import ClipDeckCore
import SwiftUI

struct SidebarView: View {
    @Binding var selectedBoard: Pinboard
    let counts: [Pinboard: Int]
    @AppStorage(AppLanguagePreferenceStore.defaultsKey) private var languageRawValue = AppLanguagePreferenceStore().load().rawValue

    private var strings: AppStrings {
        AppStrings(AppLanguagePreference(rawValue: languageRawValue) ?? .simplifiedChinese)
    }

    var body: some View {
        List(Pinboard.allCases, selection: $selectedBoard) { board in
            Label {
                HStack {
                    Text(strings.boardTitle(board))
                    Spacer()
                    Text("\(counts[board, default: 0])")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            } icon: {
                Image(systemName: iconName(for: board))
                    .foregroundStyle(color(for: board))
            }
            .tag(board)
        }
        .listStyle(.sidebar)
        .navigationTitle(strings.pinboardsTitle)
    }

    private func iconName(for board: Pinboard) -> String {
        switch board {
        case .all: "rectangle.stack"
        case .links: "link"
        case .images: "photo"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .colors: "eyedropper"
        }
    }

    private func color(for board: Pinboard) -> Color {
        switch board {
        case .all: .secondary
        case .links: AppPalette.teal
        case .images: AppPalette.indigo
        case .code: AppPalette.amber
        case .colors: AppPalette.mint
        }
    }
}
