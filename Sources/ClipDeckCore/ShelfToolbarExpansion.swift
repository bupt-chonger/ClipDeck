public enum ShelfToolbarExpansion: Equatable, Sendable {
    case showSearch
    case showSearchAndHidePinboardCreator
    case showPinboardCreator
    case showPinboardCreatorAndHideSearch

    public static func resolveOpeningSearch(isPinboardCreatorVisible: Bool) -> ShelfToolbarExpansion {
        isPinboardCreatorVisible ? .showSearchAndHidePinboardCreator : .showSearch
    }

    public static func resolveOpeningPinboardCreator(isSearching: Bool) -> ShelfToolbarExpansion {
        isSearching ? .showPinboardCreatorAndHideSearch : .showPinboardCreator
    }
}
