import Foundation

public struct ClipItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var content: String
    public var source: String
    public var sourceBundleIdentifier: String?
    public var kind: ClipKind
    public var imageData: Data?
    public var imagePasteboardType: String?
    public var pinboardID: String?
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case content
        case source
        case sourceBundleIdentifier
        case kind
        case imageData
        case imagePasteboardType
        case pinboardID
        case tags
        case createdAt
        case updatedAt
    }

    public init(
        id: UUID = UUID(),
        content: String,
        source: String = "Clipboard",
        sourceBundleIdentifier: String? = nil,
        kind: ClipKind? = nil,
        imageData: Data? = nil,
        imagePasteboardType: String? = nil,
        pinboardID: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.source = source
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.kind = kind ?? (imageData == nil ? ClipItem.detectKind(for: content) : .image)
        self.imageData = imageData
        self.imagePasteboardType = imagePasteboardType
        self.pinboardID = pinboardID
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        source = try container.decode(String.self, forKey: .source)
        sourceBundleIdentifier = try container.decodeIfPresent(String.self, forKey: .sourceBundleIdentifier)
        kind = try container.decode(ClipKind.self, forKey: .kind)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        imagePasteboardType = try container.decodeIfPresent(String.self, forKey: .imagePasteboardType)
        pinboardID = try container.decodeIfPresent(String.self, forKey: .pinboardID)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public var title: String {
        let firstLine = content
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? content
        return firstLine.isEmpty ? kind.label : firstLine
    }

    public var preview: String {
        content.replacingOccurrences(of: "\n", with: " ")
    }

    public var hasImagePreview: Bool {
        kind == .image && imageData?.isEmpty == false
    }

    public static func detectKind(for content: String) -> ClipKind {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return .link
        }
        if trimmed.range(of: #"^#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})$"#, options: .regularExpression) != nil {
            return .color
        }
        if trimmed.contains("func ") || trimmed.contains("class ") || trimmed.contains("let ") || trimmed.contains("const ") {
            return .code
        }
        return .text
    }
}
