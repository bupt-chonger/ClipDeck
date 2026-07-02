import CoreGraphics

public enum ShelfCardLayout {
    public static let cardWidth: CGFloat = 220
    public static let cardHeight: CGFloat = 220
    public static let headerHeight: CGFloat = 58
    public static let bodyHeight: CGFloat = cardHeight - headerHeight
    public static let bodyTopOffset: CGFloat = headerHeight
    public static let bodyZIndex: Double = 0
    public static let headerZIndex: Double = 1
    public static let cardSpacing: CGFloat = 16
    public static let horizontalContentInset: CGFloat = 16
    public static let compactTwoCardViewportWidth: CGFloat = 504
    public static let headerVerticalPadding: CGFloat = 8
    public static let sourceIconSize: CGFloat = 30
    public static let sourceIconPadding: CGFloat = 5
    public static let sourceIconContainerSize: CGFloat = sourceIconSize + (sourceIconPadding * 2)
}

public enum ShelfPinboardCreatorLayout {
    public static let colorChoiceCount: CGFloat = 8
    public static let colorChoiceSize: CGFloat = 13
    public static let colorChoiceSpacing: CGFloat = 5
    public static let sectionSpacing: CGFloat = 8
    public static let textFieldWidth: CGFloat = 92
    public static let confirmButtonWidth: CGFloat = 20
    public static let cancelButtonWidth: CGFloat = 18
    public static let contentWidth: CGFloat = (colorChoiceCount * colorChoiceSize) +
        ((colorChoiceCount - 1) * colorChoiceSpacing) +
        textFieldWidth +
        confirmButtonWidth +
        cancelButtonWidth +
        (sectionSpacing * 3)
    public static let expandedWidth: CGFloat = contentWidth + 8
    public static let collapsedWidth: CGFloat = 1
    public static let height: CGFloat = 28
    public static let leadingPadding: CGFloat = 18
    public static let trailingPadding: CGFloat = 7
    public static let verticalPadding: CGFloat = 4
}
