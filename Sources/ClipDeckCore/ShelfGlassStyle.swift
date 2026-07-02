import CoreGraphics

public enum ShelfGlassStyle {
    public static let panelHighlightOpacity: CGFloat = 0.12
    public static let panelMidHighlightOpacity: CGFloat = 0.03
    public static let panelStrokeOpacity: CGFloat = 0.16
    public static let searchFieldTintOpacity: CGFloat = 0.025
    public static let selectedFilterTintOpacity: CGFloat = 0.032
    public static let cardBodyTintOpacity: CGFloat = 0.14
    public static let cardBodyHighlightOpacity: CGFloat = 0.12
    public static let cardHeaderTintOpacity: CGFloat = 0.66
    public static let cardHeaderHighlightOpacity: CGFloat = 0.18
    public static let cardStrokeOpacity: CGFloat = 0.18
    public static let selectedCardStrokeOpacity: CGFloat = 0.78
    public static let cardShadowOpacity: CGFloat = 0.10
    public static let selectedCardShadowOpacity: CGFloat = 0.18
}

public enum ShelfToolbarAnimationStyle {
    public static let response: Double = 0.56
    public static let dampingFraction: Double = 0.95
    public static let blendDuration: Double = 0.16
    public static let collapsedScale: CGFloat = 0.96
    public static let collapsedOpacity: Double = 0
    public static let unselectedFilterScale: CGFloat = 0.98
    public static let contentSwitchOffset: CGFloat = 8
}

public enum ShelfCardInteractionAnimationStyle {
    public static let selectionResponse: Double = 0.44
    public static let selectionDampingFraction: Double = 0.90
    public static let selectionBlendDuration: Double = 0.14
    public static let pinboardAssignmentResponse: Double = 0.58
    public static let pinboardAssignmentDampingFraction: Double = 0.94
    public static let pinboardAssignmentBlendDuration: Double = 0.16
    public static let scrollDuration: Double = 0.36
}
