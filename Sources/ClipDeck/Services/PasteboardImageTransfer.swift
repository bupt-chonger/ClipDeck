import AppKit
import ClipDeckCore
import Foundation

final class ClipboardWriteTracker: @unchecked Sendable {
    static let shared = ClipboardWriteTracker()

    private let lock = NSLock()
    private var ignoredChangeCounts: Set<Int> = []

    func mark(changeCount: Int) {
        lock.lock()
        ignoredChangeCounts.insert(changeCount)
        if ignoredChangeCounts.count > 32 {
            ignoredChangeCounts.remove(ignoredChangeCounts.first!)
        }
        lock.unlock()
    }

    func consume(changeCount: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return ignoredChangeCounts.remove(changeCount) != nil
    }
}

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
        // Keep text insertion compatible with the 1.0.1 path. Some target
        // editors prefer an archived URL/file/RTF representation over the
        // insertion-point text when multiple UTIs are written at once.
        guard item.kind == .image else {
            return writePlainText(item.content, to: pasteboard)
        }

        if !item.pasteboardRepresentations.isEmpty {
            pasteboard.clearContents()
            let pasteboardItem = NSPasteboardItem()
            for (rawType, data) in item.pasteboardRepresentations where !data.isEmpty {
                pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(rawType))
            }
            if pasteboard.writeObjects([pasteboardItem]) {
                ClipboardWriteTracker.shared.mark(changeCount: pasteboard.changeCount)
                return true
            }
        }

        if item.kind == .image, let data = item.imageData, !data.isEmpty {
            pasteboard.clearContents()

            if let image = NSImage(data: data), pasteboard.writeObjects([image]) {
                ClipboardWriteTracker.shared.mark(changeCount: pasteboard.changeCount)
                return true
            }

            let type = NSPasteboard.PasteboardType(item.imagePasteboardType ?? NSPasteboard.PasteboardType.tiff.rawValue)
            let success = pasteboard.setData(data, forType: type)
            if success {
                ClipboardWriteTracker.shared.mark(changeCount: pasteboard.changeCount)
            }
            return success
        }

        return writePlainText(item.content, to: pasteboard)
    }

    @discardableResult
    static func writePlainText(_ text: String, to pasteboard: NSPasteboard) -> Bool {
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        if success {
            ClipboardWriteTracker.shared.mark(changeCount: pasteboard.changeCount)
        }
        return success
    }
}
