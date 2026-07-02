import Foundation

public enum ClipKind: String, CaseIterable, Codable, Hashable, Sendable {
    case text
    case link
    case image
    case code
    case color

    public var label: String {
        switch self {
        case .text: "Text"
        case .link: "Link"
        case .image: "Image"
        case .code: "Code"
        case .color: "Color"
        }
    }
}
