import AppKit
import ClipDeckCore

enum PasteboardImageTransfer {
    private static let preferredImageTypes: [NSPasteboard.PasteboardType] = [
        .png,
        .tiff,
        NSPasteboard.PasteboardType("public.jpeg")
    ]

    static func readImage(from pasteboard: NSPasteboard) -> (data: Data, type: String)? {
        for type in preferredImageTypes {
            if let data = pasteboard.data(forType: type), !data.isEmpty {
                return (data, type.rawValue)
            }
        }

        guard
            let image = NSImage(pasteboard: pasteboard),
            let data = image.tiffRepresentation,
            !data.isEmpty
        else {
            return nil
        }

        return (data, NSPasteboard.PasteboardType.tiff.rawValue)
    }

    @discardableResult
    static func write(_ item: ClipItem, to pasteboard: NSPasteboard) -> Bool {
        guard item.kind == .image, let data = item.imageData, !data.isEmpty else {
            return false
        }

        pasteboard.clearContents()

        if let image = NSImage(data: data), pasteboard.writeObjects([image]) {
            return true
        }

        let type = NSPasteboard.PasteboardType(item.imagePasteboardType ?? NSPasteboard.PasteboardType.tiff.rawValue)
        return pasteboard.setData(data, forType: type)
    }
}
