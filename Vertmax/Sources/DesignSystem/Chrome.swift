import SwiftUI

/// Card and button chrome shared across every screen. Centralizing this is
/// what keeps ~15 screens feeling like one product instead of a dozen
/// separately-styled ones.
struct CardBackground: ViewModifier {
    /// Pass a color for the rare card that needs to read as "active" (e.g.
    /// today's workout) — mirrors the volt-rationing rule in Colors.swift.
    var accent: Color?

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.surface, Color.surface.opacity(0.92)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(accent?.opacity(0.4) ?? Color.white.opacity(0.06), lineWidth: accent != nil ? 1.5 : 1)
            )
            .shadow(color: .black.opacity(0.32), radius: 20, x: 0, y: 10)
    }
}

extension View {
    /// Standard elevated card: gradient surface fill, hairline border, soft
    /// drop shadow. Use `accent:` only for the single "this needs attention
    /// right now" card on a screen.
    ///
    /// `nonisolated` because it's pure view-tree construction — without it,
    /// Swift 6 infers `@MainActor` from the `View` conformance, which then
    /// fails to call from framework closures (e.g. `PhotosPicker`'s label)
    /// that aren't themselves `@MainActor`-annotated in this SDK.
    nonisolated func cardStyle(accent: Color? = nil) -> some View {
        modifier(CardBackground(accent: accent))
    }
}

/// Press feedback for the volt CTA. SwiftUI's stock `.borderedProminent`
/// gives no tactile response on press, which reads as unfinished on a
/// screen whose whole job is "tap this to measure something."
struct VoltButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(VertFont.headline)
            .foregroundStyle(.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(isEnabled ? Color.voltGreen : Color.voltGreen.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Secondary action: outline only, no fill — for the second-priority action
/// next to a `VoltButtonStyle` primary, or standalone low-emphasis actions.
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(VertFont.headline)
            .foregroundStyle(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(Color.white.opacity(configuration.isPressed ? 0.06 : 0.02))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A row/card that scales down slightly on press — for tappable rows that
/// aren't full buttons (program cards, exercise rows).
struct PressableRowStyle: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    /// `nonisolated` for the same reason as `cardStyle` above.
    nonisolated func pressableRow() -> some View {
        modifier(PressableRowStyle())
    }
}

/// Small stamped tag for plyometric exercises. Archivo Black at a tiny size
/// reads like a stat marker rather than a soft rounded label.
struct PlyoBadge: View {
    var body: some View {
        Text("PLYO")
            .font(VertFont.display(9))
            .tracking(0.5)
            .foregroundStyle(.ink)
            .padding(.horizontal, Spacing.xxs)
            .padding(.vertical, 2)
            .background(Color.voltGreen)
            .clipShape(Capsule())
    }
}

/// "Verified by Video" pill — shown on the measurement result screen and
/// reused on the shareable card so the two can't visually drift apart.
struct CredibilityBadge: View {
    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.voltGreen)
            Text("Verified by Video")
                .font(VertFont.caption)
                .foregroundStyle(.textPrimary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(Color.surface)
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
        .clipShape(Capsule())
    }
}

/// Takeoff/landing evidence thumbnail — image-or-placeholder in a rounded,
/// volt-stroked frame. Shared by the result screen and the shareable card.
struct FrameThumbnail: View {
    let image: CGImage?
    var size: CGSize = CGSize(width: 120, height: 160)
    var label: String?

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Group {
                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.surface
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.sm)
                    .strokeBorder(Color.voltGreen.opacity(0.5), lineWidth: 1.5)
            )
            if let label {
                Text(label)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
        }
    }
}

/// "Volume up" note shown wherever a boosted week (see `ProgramProgression`)
/// appears — Home, the Program tab, and the full schedule. One definition so
/// the copy/icon/color can't drift between the three.
struct BoostBadge: View {
    var body: some View {
        Label("Volume up — last week fully completed", systemImage: "arrow.up.forward")
            .font(VertFont.caption)
            .foregroundStyle(.voltGreen)
    }
}

/// A selectable pill: volt-filled when active, surface otherwise. Shared by
/// the program week picker and the exercise library's category filters so
/// "choose one of these tags" reads the same way everywhere it appears.
struct ChipToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(VertFont.body(13, weight: .semibold))
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.voltGreen : Color.surface)
                .foregroundStyle(isSelected ? .ink : .textPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
