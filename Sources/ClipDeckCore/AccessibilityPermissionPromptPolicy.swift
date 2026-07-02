public enum AccessibilityPermissionPromptPolicy: Equatable, Sendable {
    case silent
    case promptOnce(hasPrompted: Bool)

    public var shouldPromptSystemDialog: Bool {
        switch self {
        case .silent:
            false
        case .promptOnce(let hasPrompted):
            !hasPrompted
        }
    }
}
