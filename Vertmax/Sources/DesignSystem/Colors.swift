import SwiftUI

/// Brand palette per PRD §12. Volt is rationed — it should only ever mark
/// the vert number, PRs, positive deltas, and primary CTAs.
extension Color {
    static let voltGreen = Color(hex: 0xC8FF2E)
    static let ink = Color(hex: 0x0B0B10)
    static let surface = Color(hex: 0x17171F)
    static let raised = Color(hex: 0x262631)
    static let textPrimary = Color(hex: 0xF4F4F8)
    static let textMuted = Color(hex: 0x9C9CAB)

    // Safety colors — reserved for injury/fatigue flows only. Never decorative.
    static let cautionAmber = Color(hex: 0xFFB020)
    static let stopRed = Color(hex: 0xFF4757)

    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

/// Lets `.foregroundStyle(.textPrimary)` etc. resolve via implicit member
/// syntax — SwiftUI only does this for `ShapeStyle` statics, not `Color` ones.
extension ShapeStyle where Self == Color {
    static var voltGreen: Color { .voltGreen }
    static var ink: Color { .ink }
    static var surface: Color { .surface }
    static var raised: Color { .raised }
    static var textPrimary: Color { .textPrimary }
    static var textMuted: Color { .textMuted }
    static var cautionAmber: Color { .cautionAmber }
    static var stopRed: Color { .stopRed }
}
