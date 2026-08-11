import Foundation

public enum ClipKind: String, CaseIterable, Codable, Hashable, Sendable {
    case text
    case link
    case file
    case image
    case code
    case color

    public var label: String {
        switch self {
        case .text: "Text"
        case .link: "Link"
        case .file: "File"
        case .image: "Image"
        case .code: "Code"
        case .color: "Color"
        }
    }
}
