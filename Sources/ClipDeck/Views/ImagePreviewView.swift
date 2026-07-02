import AppKit
import ClipDeckCore
import SwiftUI

struct ImagePreviewView: View {
    let item: ClipItem
    var contentMode: ContentMode = .fill

    var body: some View {
        ZStack {
            if let nsImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 28, weight: .semibold))
                    Text("Preview unavailable")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.black.opacity(0.025))
    }

    private var nsImage: NSImage? {
        guard let data = item.imageData else { return nil }
        return NSImage(data: data)
    }
}
