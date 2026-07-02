import Foundation

public enum ClipboardFilter: Equatable, Hashable, Sendable {
    case board(Pinboard)
    case pinboard(String)

    public static var history: ClipboardFilter {
        .board(.all)
    }

    public func contains(_ item: ClipItem) -> Bool {
        switch self {
        case .board(let board):
            board.contains(item)
        case .pinboard(let pinboardID):
            item.pinboardID == pinboardID
        }
    }
}
