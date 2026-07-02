import CoreGraphics
import Foundation

public enum BottomShelfPlacement {
    public static func panelFrame(
        in visibleFrame: CGRect,
        preferredHeight: CGFloat = 340
    ) -> CGRect {
        let height = min(preferredHeight, max(220, visibleFrame.height * 0.42))
        return CGRect(
            x: visibleFrame.minX,
            y: visibleFrame.minY,
            width: visibleFrame.width,
            height: height
        )
    }
}
