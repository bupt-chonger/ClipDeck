import Foundation

public enum ShelfItemClickAction: Equatable, Sendable {
    case select
    case paste

    public static func resolve(clickedID: UUID, selectedID: UUID?) -> ShelfItemClickAction {
        clickedID == selectedID ? .paste : .select
    }

    public static func resolveDoubleClick() -> ShelfItemClickAction {
        .paste
    }
}
