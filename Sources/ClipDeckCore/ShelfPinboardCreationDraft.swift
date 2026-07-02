import Foundation

public struct UserPinboardCreationRequest: Equatable, Sendable {
    public var name: String
    public var colorHex: String

    public init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
    }
}

public struct ShelfPinboardCreationDraft: Equatable, Sendable {
    public static let colorOptions: [UserPinboardColorOption] = [
        UserPinboardColorOption(name: "Red", hex: "#FF3B30"),
        UserPinboardColorOption(name: "Orange", hex: "#FF9500"),
        UserPinboardColorOption(name: "Yellow", hex: "#FFCC00"),
        UserPinboardColorOption(name: "Green", hex: "#34C759"),
        UserPinboardColorOption(name: "Teal", hex: "#00C7BE"),
        UserPinboardColorOption(name: "Blue", hex: "#007AFF"),
        UserPinboardColorOption(name: "Indigo", hex: "#5856D6"),
        UserPinboardColorOption(name: "Purple", hex: "#AF52DE")
    ]

    public var name: String
    public var colorHex: String

    public init(name: String = "", colorHex: String = "#FF3B30") {
        self.name = name
        self.colorHex = colorHex
    }

    public init(pinboard: UserPinboard) {
        self.name = pinboard.name
        self.colorHex = pinboard.colorHex
    }

    public var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var canCreate: Bool {
        !trimmedName.isEmpty
    }

    public var request: UserPinboardCreationRequest? {
        guard canCreate else { return nil }
        return UserPinboardCreationRequest(name: trimmedName, colorHex: colorHex)
    }
}

public struct UserPinboardColorOption: Identifiable, Equatable, Sendable {
    public var name: String
    public var hex: String

    public var id: String { hex }

    public init(name: String, hex: String) {
        self.name = name
        self.hex = hex
    }
}
