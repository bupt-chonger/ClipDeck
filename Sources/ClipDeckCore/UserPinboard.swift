import Foundation

public struct UserPinboard: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var colorHex: String

    public init(id: String, name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    public static func make(name: String, colorHex: String) -> UserPinboard? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return UserPinboard(
            id: stableID(for: trimmed),
            name: trimmed,
            colorHex: normalizedColorHex(colorHex)
        )
    }

    public static func stableID(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let scalars = trimmed.unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(scalars)
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return collapsed.isEmpty ? UUID().uuidString.lowercased() : collapsed
    }

    static func normalizedColorHex(_ colorHex: String) -> String {
        let trimmed = colorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "#", trimmed.count == 7 else { return "#007AFF" }
        return trimmed.uppercased()
    }
}
