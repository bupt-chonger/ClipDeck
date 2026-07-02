import Foundation

public enum Pinboard: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case all
    case links
    case images
    case code
    case colors

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: "History"
        case .links: "Links"
        case .images: "Images"
        case .code: "Code"
        case .colors: "Colors"
        }
    }

    public func contains(_ item: ClipItem) -> Bool {
        switch self {
        case .all:
            true
        case .links:
            item.kind == .link
        case .images:
            item.kind == .image
        case .code:
            item.kind == .code
        case .colors:
            item.kind == .color
        }
    }
}
