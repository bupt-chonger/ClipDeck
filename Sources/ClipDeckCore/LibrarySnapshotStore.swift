import Foundation

public struct LibrarySnapshotStore: Sendable {
    private let fileURL: URL
    private struct Snapshot: Codable {
        var items: [ClipItem]
        var customPinboards: [UserPinboard]?
        var customTags: [String]?
    }

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public var hasSnapshot: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    public func load() -> [ClipItem] {
        loadSnapshot().items
    }

    public func loadSnapshot() -> (items: [ClipItem], pinboards: [UserPinboard], customTags: [String]) {
        guard let data = try? Data(contentsOf: fileURL) else { return ([], [], []) }
        if let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            return (snapshot.items, snapshot.customPinboards ?? [], snapshot.customTags ?? [])
        }
        return ((try? JSONDecoder().decode([ClipItem].self, from: data)) ?? [], [], [])
    }

    public func save(_ items: [ClipItem]) {
        save(items: items, pinboards: [])
    }

    public func save(_ library: ClipboardLibrary) {
        save(items: library.items, pinboards: library.pinboards)
    }

    public func save(items: [ClipItem], pinboards: [UserPinboard]) {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(Snapshot(items: items, customPinboards: pinboards, customTags: nil))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Unable to save ClipDeck library: \(error.localizedDescription)")
        }
    }
}
