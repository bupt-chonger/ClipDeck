import AppKit
import ClipDeckCore
import Foundation
import UniformTypeIdentifiers

struct ClipboardCapturePayload {
    let content: String
    let kind: ClipKind
    let imageData: Data?
    let imagePasteboardType: String?
    let pasteboardRepresentations: [String: Data]
}

/// Builds typed clipboard payloads from the pasteboard while retaining the
/// original UTI representations for a later lossless write-back.
enum ClipboardPasteboardBuilder {
    private static let imageTypes: [UTType] = [
        .png,
        .tiff,
        .jpeg,
        .gif,
        .bmp,
        .heic
    ]

    private static let fileURLType = NSPasteboard.PasteboardType("public.file-url")
    private static let urlType = NSPasteboard.PasteboardType("public.url")
    private static let rtfType = NSPasteboard.PasteboardType("public.rtf")

    static func buildItems(from pasteboard: NSPasteboard, sourceName: String) -> [ClipboardCapturePayload] {
        guard let pasteboardItems = pasteboard.pasteboardItems, !pasteboardItems.isEmpty else {
            return []
        }

        return pasteboardItems.compactMap { buildItem($0, sourceName: sourceName) }
    }

    private static func buildItem(_ item: NSPasteboardItem, sourceName: String) -> ClipboardCapturePayload? {
        let representations = item.types.reduce(into: [String: Data]()) { result, type in
            guard let data = item.data(forType: type), !data.isEmpty else { return }
            result[type.rawValue] = data
        }

        if let imageType = imageType(in: item), let imageData = item.data(forType: imageType) {
            return ClipboardCapturePayload(
                content: "Image from \(sourceName)",
                kind: .image,
                imageData: imageData,
                imagePasteboardType: imageType.rawValue,
                pasteboardRepresentations: representations
            )
        }

        if let fileURL = stringValue(for: fileURLType, in: item), !fileURL.isEmpty {
            return ClipboardCapturePayload(
                content: fileURL,
                kind: .file,
                imageData: nil,
                imagePasteboardType: nil,
                pasteboardRepresentations: representations
            )
        }

        if let url = stringValue(for: urlType, in: item), !url.isEmpty {
            return ClipboardCapturePayload(
                content: url,
                kind: .link,
                imageData: nil,
                imagePasteboardType: nil,
                pasteboardRepresentations: representations
            )
        }

        if let text = text(in: item) {
            return ClipboardCapturePayload(
                content: text,
                kind: ClipItem.detectKind(for: text),
                imageData: nil,
                imagePasteboardType: nil,
                pasteboardRepresentations: representations
            )
        }

        return nil
    }

    private static func imageType(in item: NSPasteboardItem) -> NSPasteboard.PasteboardType? {
        item.types.first { pasteboardType in
            guard let type = UTType(pasteboardType.rawValue) else { return false }
            return imageTypes.contains { type.conforms(to: $0) }
        }
    }

    private static func text(in item: NSPasteboardItem) -> String? {
        let plainTextTypes = [
            NSPasteboard.PasteboardType.string,
            NSPasteboard.PasteboardType("public.text")
        ]

        for type in plainTextTypes {
            if let value = item.string(forType: type), !value.isEmpty {
                return value
            }
        }

        guard let rtfData = item.data(forType: rtfType), !rtfData.isEmpty else {
            return nil
        }

        return NSAttributedString(rtf: rtfData, documentAttributes: nil)?.string
    }

    private static func stringValue(for type: NSPasteboard.PasteboardType, in item: NSPasteboardItem) -> String? {
        if let string = item.string(forType: type) {
            return string
        }
        if let url = item.propertyList(forType: type) as? NSURL {
            return url.absoluteString
        }
        if let url = item.propertyList(forType: type) as? URL {
            return url.absoluteString
        }
        return item.propertyList(forType: type) as? String
    }
}
