import AppKit
import ClipDeckCore
import SwiftUI

struct SourceAppIconView: View {
    let item: ClipItem
    var iconSize: CGFloat = 44
    var padding: CGFloat = 8
    var cornerRadius: CGFloat = 10

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .padding(padding)
            .clipDeckGlass(
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                layer: .control
            )
            .help(item.source)
    }

    private var icon: NSImage {
        if
            let bundleIdentifier = item.sourceBundleIdentifier,
            let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }

        return NSWorkspace.shared.icon(for: .application)
    }
}
