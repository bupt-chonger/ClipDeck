import ClipDeckCore
import SwiftUI

struct ClipCarouselView: View {
    let items: [ClipItem]
    @Binding var selectedItemID: ClipItem.ID?
    let onCopy: (ClipItem) -> Void
    let onDelete: (ClipItem) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 14) {
                ForEach(items) { item in
                    ClipCardView(
                        item: item,
                        isSelected: selectedItemID == item.id,
                        onCopy: { onCopy(item) },
                        onDelete: { onDelete(item) }
                    )
                    .onTapGesture {
                        selectedItemID = item.id
                    }
                }
            }
            .padding(24)
        }
        .frame(height: 250)
        .scrollIndicators(.visible)
    }
}
