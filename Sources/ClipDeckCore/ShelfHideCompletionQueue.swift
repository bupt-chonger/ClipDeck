import Foundation

public enum ShelfHideRequestResult: Equatable, Sendable {
    case startHide
    case alreadyHiding
}

public struct ShelfHideCompletionQueue {
    private var isHiding = false
    private var completions: [() -> Void] = []

    public init() {}

    public mutating func beginHide(afterHide completion: (() -> Void)?) -> ShelfHideRequestResult {
        if let completion {
            completions.append(completion)
        }
        guard !isHiding else { return .alreadyHiding }
        isHiding = true
        return .startHide
    }

    public mutating func finishHide() -> [() -> Void] {
        isHiding = false
        let completions = completions
        self.completions = []
        return completions
    }

    public mutating func reset() {
        isHiding = false
        completions = []
    }
}
