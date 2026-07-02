import Foundation

public struct KeyboardShortcutPreference: Hashable, RawRepresentable, Sendable {
    public static let commandModifier: UInt32 = 1 << 8
    public static let shiftModifier: UInt32 = 1 << 9
    public static let optionModifier: UInt32 = 1 << 11
    public static let controlModifier: UInt32 = 1 << 12

    public static let `default` = KeyboardShortcutPreference(keyCode: 49, modifiers: optionModifier)

    public var keyCode: UInt32
    public var modifiers: UInt32

    public init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public init?(rawValue: String) {
        let parts = rawValue.split(separator: ":", maxSplits: 1)
        guard
            parts.count == 2,
            let keyCode = UInt32(parts[0]),
            let modifiers = UInt32(parts[1])
        else {
            return nil
        }
        self.init(keyCode: keyCode, modifiers: modifiers)
    }

    public var rawValue: String {
        "\(keyCode):\(modifiers)"
    }

    public var displayString: String {
        let modifiers = [
            modifierName(Self.commandModifier, "Command"),
            modifierName(Self.shiftModifier, "Shift"),
            modifierName(Self.optionModifier, "Option"),
            modifierName(Self.controlModifier, "Control")
        ].compactMap(\.self)

        return (modifiers + [keyName]).joined(separator: " ")
    }

    private func modifierName(_ flag: UInt32, _ name: String) -> String? {
        modifiers & flag == flag ? name : nil
    }

    private var keyName: String {
        switch keyCode {
        case 0: "A"
        case 1: "S"
        case 2: "D"
        case 3: "F"
        case 4: "H"
        case 5: "G"
        case 6: "Z"
        case 7: "X"
        case 8: "C"
        case 9: "V"
        case 11: "B"
        case 12: "Q"
        case 13: "W"
        case 14: "E"
        case 15: "R"
        case 16: "Y"
        case 17: "T"
        case 31: "O"
        case 32: "U"
        case 34: "I"
        case 35: "P"
        case 37: "L"
        case 38: "J"
        case 40: "K"
        case 45: "N"
        case 46: "M"
        case 49: "Space"
        default: "Key \(keyCode)"
        }
    }
}
