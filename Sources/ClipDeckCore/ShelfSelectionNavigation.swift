import Foundation

public enum ShelfSelectionNavigationDirection: Sendable {
    case left
    case right
}

public enum ShelfSelectionNavigation {
    public static func move(
        _ direction: ShelfSelectionNavigationDirection,
        selectedID: UUID?,
        itemIDs: [UUID]
    ) -> UUID? {
        guard !itemIDs.isEmpty else { return nil }
        guard let selectedID, let index = itemIDs.firstIndex(of: selectedID) else {
            return itemIDs.first
        }

        switch direction {
        case .left:
            return itemIDs[max(itemIDs.startIndex, index - 1)]
        case .right:
            return itemIDs[min(itemIDs.index(before: itemIDs.endIndex), index + 1)]
        }
    }
}
