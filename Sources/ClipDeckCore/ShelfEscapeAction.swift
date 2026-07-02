import Foundation

public enum ShelfEscapeAction: Equatable, Sendable {
    case collapseSearch
    case closeShelf

    public static func resolve(isSearching: Bool) -> ShelfEscapeAction {
        isSearching ? .collapseSearch : .closeShelf
    }
}
