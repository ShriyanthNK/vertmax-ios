import SwiftUI

/// Three-role type system per PRD §12.
///
/// - `display`  Archivo Black — the loud voice. Used with restraint: the
///   wordmark, eyebrow labels, and the handful of moments that should feel
///   physical and shouted rather than spoken.
/// - `numeric`  IBM Plex Mono — every measured value in the app (the vert
///   itself, PRs, deltas, set×rep, weights) reads like an instrument
///   readout. Vertmax's whole premise is that the camera measures you
///   precisely — the numbers should look measured, not decorated.
/// - `body`     SF Pro (system) — the workhorse face for descriptions,
///   buttons, and nav labels. Keeps Dynamic Type and VoiceOver behavior
///   free, which matters more for body copy than a distinctive face does.
enum VertFont {
    enum Weight {
        case regular, medium, semibold, bold

        fileprivate var postscriptName: String {
            switch self {
            case .regular: "IBMPlexMono-Regular"
            case .medium: "IBMPlexMono-Medium"
            case .semibold: "IBMPlexMono-SemiBold"
            case .bold: "IBMPlexMono-Bold"
            }
        }
    }

    static func display(_ size: CGFloat) -> Font {
        .custom("ArchivoBlack-Regular", size: size)
    }

    static func numeric(_ size: CGFloat, weight: Weight = .regular) -> Font {
        .custom(weight.postscriptName, size: size)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    // MARK: Scale — keep every screen on this instead of ad-hoc sizes.

    /// The vert number itself. Mono, not the display face — this is a
    /// reading, not a headline.
    static let heroNumber = numeric(64, weight: .semibold)
    static let heroUnit = numeric(19, weight: .medium)

    /// The "Vertmax" logotype next to the mark. The one place the display
    /// face appears on most screens.
    static let wordmark = display(18)

    /// Page-level headers only (empty states, the odd full-bleed title).
    /// Not for card titles — see `headline`.
    static let screenTitle = display(24)

    /// All-caps section labels ("TODAY'S WORKOUT", "BEST VERT"). Pair with
    /// `Text.eyebrowTracking()` for the letterspacing.
    static let eyebrow = display(11)

    static let headline = body(20, weight: .semibold)
    static let bodyText = body(17)
    static let caption = body(13)

    /// Set×rep counts, PR deltas, stat-grid values — anything that's a
    /// measured number rather than prose. Not for dates, which read as
    /// language, not instrumentation.
    static let dataLabel = numeric(15, weight: .medium)
    static let dataCaption = numeric(12, weight: .regular)
}

extension Text {
    /// Letterspacing for `VertFont.eyebrow` labels. Archivo Black is dense
    /// at small sizes; a little air keeps all-caps tags legible.
    func eyebrowTracking() -> Text {
        tracking(1.2)
    }
}
