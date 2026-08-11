import SwiftUI

enum ClipDeckGlassLayer {
    case panel
    case card
    case control

    var usesNativeGlass: Bool {
        self == .control
    }

    var fallbackMaterial: Material {
        switch self {
        case .panel: .regularMaterial
        case .card: .thinMaterial
        case .control: .ultraThinMaterial
        }
    }
}

struct ClipDeckGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(spacing: CGFloat = 12, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        if #available(macOS 26.0, *), !reduceTransparency {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

extension View {
    func clipDeckGlass<S: Shape>(
        in shape: S,
        layer: ClipDeckGlassLayer,
        tint: Color? = nil
    ) -> some View {
        modifier(ClipDeckGlassModifier(shape: shape, layer: layer, tint: tint))
    }
}

private struct ClipDeckGlassModifier<S: Shape>: ViewModifier {
    let shape: S
    let layer: ClipDeckGlassLayer
    let tint: Color?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *), !reduceTransparency, layer.usesNativeGlass {
            content
                .clipShape(shape)
                .glassEffect(.regular, in: shape)
                .overlay {
                    if let tint {
                        shape
                            .fill(tint.opacity(0.14))
                            .allowsHitTesting(false)
                    }
                }
        } else {
            content
                .clipShape(shape)
                .background(layer.fallbackMaterial, in: shape)
                .overlay {
                    if let tint {
                        shape
                            .fill(tint.opacity(reduceTransparency ? 0.20 : 0.12))
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}
