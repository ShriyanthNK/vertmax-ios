import SwiftUI

/// The app's signature background motif: a single rising arc, echoing the
/// jump trajectory built into the logo mark (see VertmaxLogoMark). Used at
/// most once per screen, always faint — it's atmosphere behind the number
/// that matters, not another thing competing for attention.
struct TrajectoryArc: Shape {
    /// Where along the arc's height the curve starts, 0...1 from the
    /// bottom. Lets a card clip a low, wide slice or a tall, steep one.
    var liftoff: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let start = CGPoint(x: rect.minX, y: rect.maxY - rect.height * liftoff)
        let end = CGPoint(x: rect.maxX, y: rect.minY)
        let control = CGPoint(x: rect.maxX * 0.62, y: rect.maxY)

        var path = Path()
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)
        return path
    }
}

extension View {
    /// Drops a faint trajectory arc behind the view, anchored bottom-leading
    /// to top-trailing. Intended for hero cards only.
    ///
    /// `nonisolated` — see the note on `cardStyle` in Chrome.swift.
    nonisolated func trajectoryBackdrop(color: Color = .voltGreen, opacity: Double = 0.14) -> some View {
        background(
            TrajectoryArc()
                .stroke(color.opacity(opacity), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .allowsHitTesting(false)
        )
    }
}
