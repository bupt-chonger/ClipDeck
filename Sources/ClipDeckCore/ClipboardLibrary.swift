import Foundation
import Observation

@Observable
public final class ClipboardLibrary {
    public private(set) var items: [ClipItem]
    public private(set) var pinboards: [UserPinboard]
    private var now: @Sendable () -> Date

    public init(
        seed: [ClipItem] = [],
        pinboards: [UserPinboard] = [],
        customTags: [String] = [],
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        let migratedPinboards = ClipboardLibrary.normalizedPinboards(
            pinboards + customTags.compactMap { UserPinboard.make(name: $0, colorHex: ClipboardLibrary.colorHex(for: $0)) } +
            seed.flatMap(\.tags).compactMap { UserPinboard.make(name: $0, colorHex: ClipboardLibrary.colorHex(for: $0)) }
        )
        self.items = seed.map { item in
            var migratedItem = item
            if migratedItem.pinboardID == nil, let firstTag = migratedItem.tags.first {
                migratedItem.pinboardID = UserPinboard.stableID(for: firstTag)
            }
            return migratedItem
        }
        .sorted { left, right in
            return left.updatedAt > right.updatedAt
        }
        self.pinboards = migratedPinboards
        self.now = now
    }

    public func setNow(_ now: @escaping @Sendable () -> Date) {
        self.now = now
    }

    public func capture(text: String, source: String = "Clipboard", sourceBundleIdentifier: String? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let index = items.firstIndex(where: { $0.content == text }) {
            items[index].updatedAt = now()
            items[index].source = source
            items[index].sourceBundleIdentifier = sourceBundleIdentifier
            sort()
            return
        }

        items.insert(
            ClipItem(
                content: text,
                source: source,
                sourceBundleIdentifier: sourceBundleIdentifier,
                createdAt: now(),
                updatedAt: now()
            ),
            at: 0
        )
        sort()
    }

    public func captureImage(
        data: Data,
        pasteboardType: String,
        source: String = "Clipboard",
        sourceBundleIdentifier: String? = nil
    ) {
        guard !data.isEmpty else { return }

        if let index = items.firstIndex(where: { $0.kind == .image && $0.imageData == data }) {
            items[index].updatedAt = now()
            items[index].source = source
            items[index].sourceBundleIdentifier = sourceBundleIdentifier
            items[index].imagePasteboardType = pasteboardType
            sort()
            return
        }

        items.insert(
            ClipItem(
                content: "Image from \(source)",
                source: source,
                sourceBundleIdentifier: sourceBundleIdentifier,
                kind: .image,
                imageData: data,
                imagePasteboardType: pasteboardType,
                createdAt: now(),
                updatedAt: now()
            ),
            at: 0
        )
        sort()
    }

    public func replace(_ item: ClipItem, content: String) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].content = content
        items[index].kind = ClipItem.detectKind(for: content)
        items[index].imageData = nil
        items[index].imagePasteboardType = nil
        items[index].updatedAt = now()
        sort()
    }

    public func rename(_ item: ClipItem, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].content = trimmed
        items[index].updatedAt = now()
        sort()
    }

    @discardableResult
    public func createPinboard(name: String, colorHex: String) -> UserPinboard? {
        guard let pinboard = UserPinboard.make(name: name, colorHex: colorHex) else { return nil }
        guard !pinboards.contains(where: { $0.name.caseInsensitiveCompare(pinboard.name) == .orderedSame }) else { return nil }
        guard !pinboards.contains(where: { $0.id == pinboard.id }) else { return nil }
        pinboards.append(pinboard)
        pinboards = ClipboardLibrary.normalizedPinboards(pinboards)
        return pinboard
    }

    public func save(_ item: ClipItem, toPinboard pinboardID: String) {
        guard pinboards.contains(where: { $0.id == pinboardID }) else { return }
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].pinboardID = items[index].pinboardID == pinboardID ? nil : pinboardID
        items[index].tags.removeAll()
        items[index].updatedAt = now()
        sort()
    }

    @discardableResult
    public func renamePinboard(id pinboardID: String, to name: String) -> UserPinboard? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = pinboards.firstIndex(where: { $0.id == pinboardID }) else { return nil }
        guard !pinboards.contains(where: { $0.id != pinboardID && $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return nil }

        pinboards[index].name = trimmed
        pinboards = ClipboardLibrary.normalizedPinboards(pinboards)
        return pinboards.first { $0.id == pinboardID }
    }


    @discardableResult
    public func updatePinboard(id pinboardID: String, name: String, colorHex: String) -> UserPinboard? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = pinboards.firstIndex(where: { $0.id == pinboardID }) else { return nil }
        guard !pinboards.contains(where: { $0.id != pinboardID && $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return nil }

        pinboards[index].name = trimmed
        pinboards[index].colorHex = UserPinboard.normalizedColorHex(colorHex)
        pinboards = ClipboardLibrary.normalizedPinboards(pinboards)
        return pinboards.first { $0.id == pinboardID }
    }

    @discardableResult
    public func deletePinboard(id pinboardID: String) -> Int {
        guard pinboards.contains(where: { $0.id == pinboardID }) else { return 0 }
        pinboards.removeAll { $0.id == pinboardID }
        let previousCount = items.count
        items.removeAll { $0.pinboardID == pinboardID }
        return previousCount - items.count
    }

    public func remove(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
    }

    @discardableResult
    public func clearAll() -> Int {
        let previousCount = items.count
        items.removeAll()
        return previousCount
    }

    @discardableResult
    public func removeAppRecords(source: String, sourceBundleIdentifier: String?) -> Int {
        let previousCount = items.count
        if let sourceBundleIdentifier, !sourceBundleIdentifier.isEmpty {
            items.removeAll { $0.sourceBundleIdentifier == sourceBundleIdentifier }
        } else {
            items.removeAll { $0.source == source }
        }
        return previousCount - items.count
    }

    public func filteredItems(query: String, board: Pinboard = .all) -> [ClipItem] {
        filteredItems(query: query, filter: .board(board))
    }

    public func filteredItems(query: String, filter: ClipboardFilter) -> [ClipItem] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return items.filter { item in
            filter.contains(item) &&
            (normalized.isEmpty ||
             item.content.lowercased().contains(normalized) ||
             item.source.lowercased().contains(normalized) ||
             item.kind.label.lowercased().contains(normalized) ||
             pinboardName(for: item).lowercased().contains(normalized))
        }
    }

    public func shelfItems(query: String, board: Pinboard = .all, limit: Int? = nil) -> [ClipItem] {
        let results = filteredItems(query: query, board: board)
        guard let limit else { return results }
        return Array(results.prefix(max(0, limit)))
    }

    public func shelfItems(query: String, filter: ClipboardFilter, limit: Int? = nil) -> [ClipItem] {
        let results = filteredItems(query: query, filter: filter)
        guard let limit else { return results }
        return Array(results.prefix(max(0, limit)))
    }

    public func count(for board: Pinboard) -> Int {
        items.filter(board.contains).count
    }

    public func pinboardName(for item: ClipItem) -> String {
        guard let pinboardID = item.pinboardID else { return "" }
        return pinboards.first { $0.id == pinboardID }?.name ?? ""
    }

    public static func demo() -> ClipboardLibrary {
        let links = UserPinboard(id: "useful-links", name: "Useful Links", colorHex: "#30D158")
        let notes = UserPinboard(id: "important-notes", name: "Important Notes", colorHex: "#FFB340")
        return ClipboardLibrary(
            seed: [
                ClipItem(content: "https://pasteapp.io", source: "Safari", pinboardID: links.id),
                ClipItem(content: "Launch checklist\n- Pricing page\n- Onboarding copy\n- Shortcut QA", source: "Notes", pinboardID: notes.id),
                ClipItem(content: "#10B981", source: "Design"),
                ClipItem(content: "func pasteLatest() async throws -> ClipItem", source: "Xcode", kind: .code),
                ClipItem(content: "Screenshot 2026-06-29", source: "Preview", kind: .image)
            ],
            pinboards: [links, notes]
        )
    }

    private func sort() {
        items.sort { left, right in
            return left.updatedAt > right.updatedAt
        }
    }

    private static func normalizedPinboards(_ pinboards: [UserPinboard]) -> [UserPinboard] {
        var unique: [UserPinboard] = []
        for pinboard in pinboards {
            guard !pinboard.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            guard !unique.contains(where: { $0.name.caseInsensitiveCompare(pinboard.name) == .orderedSame }) else { continue }
            unique.append(pinboard)
        }
        return unique.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public static func colorHex(for name: String) -> String {
        let colors = ["#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#00C7BE", "#007AFF", "#5856D6", "#AF52DE"]
        let value = abs(name.lowercased().unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) })
        return colors[value % colors.count]
    }
}
