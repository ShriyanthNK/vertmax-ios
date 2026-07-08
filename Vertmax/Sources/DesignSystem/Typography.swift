import SwiftUI

/// Two-family type system per PRD §12: a display face for the hero vert
/// number/headlines, a workhorse face for everything else.
///
/// Placeholder: using rounded/default system fonts until a licensed
/// display face is chosen and added to the asset catalog. Swap the
/// `.custom(...)` cases below once that decision is made.
enum VertFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    // Common scale — keep every screen on this instead of ad-hoc sizes.
    static let heroNumber = display(72, weight: .heavy)
    static let title = display(28, weight: .bold)
    static let headline = body(20, weight: .semibold)
    static let bodyText = body(17)
    static let caption = body(13)
}
