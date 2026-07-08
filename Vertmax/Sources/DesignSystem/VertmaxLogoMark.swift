import SwiftUI

/// The brand mark: an asymmetric "V" whose right arm continues into an
/// upward arrowhead — reads as both the Vertmax initial and a jump
/// trajectory. Same geometry as the app icon (see Resources/Assets.xcassets/
/// AppIcon.appiconset) so the in-app mark and the icon match exactly.
struct VertmaxLogoMark: View {
    var color: Color = .voltGreen

    private static let leftTop = CGPoint(x: 250, y: 290)
    private static let vertex = CGPoint(x: 480, y: 760)
    private static let rightTop = CGPoint(x: 740, y: 260)

    var body: some View {
        GeometryReader { geo in
            // Path coordinates scale with the view's rendered size (via `s`
            // inside path(in:)), but StrokeStyle.lineWidth is in absolute
            // points — it has to be scaled here too, or the stroke stays a
            // fixed 88pt regardless of how small the mark is drawn.
            let s = geo.size.width / 1024
            ZStack {
                VShape(leftTop: Self.leftTop, vertex: Self.vertex, rightTop: Self.rightTop)
                    .stroke(color, style: StrokeStyle(lineWidth: 88 * s, lineCap: .round, lineJoin: .miter, miterLimit: 4))
                ArrowHeadShape(vertex: Self.vertex, rightTop: Self.rightTop)
                    .fill(color)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct VShape: Shape {
    let leftTop: CGPoint
    let vertex: CGPoint
    let rightTop: CGPoint

    func path(in rect: CGRect) -> Path {
        let s = rect.width / 1024
        var p = Path()
        p.move(to: CGPoint(x: leftTop.x * s, y: leftTop.y * s))
        p.addLine(to: CGPoint(x: vertex.x * s, y: vertex.y * s))
        p.addLine(to: CGPoint(x: rightTop.x * s, y: rightTop.y * s))
        return p
    }
}

private struct ArrowHeadShape: Shape {
    let vertex: CGPoint
    let rightTop: CGPoint

    func path(in rect: CGRect) -> Path {
        let s = rect.width / 1024
        let vertexPt = CGPoint(x: vertex.x * s, y: vertex.y * s)
        let rightTopPt = CGPoint(x: rightTop.x * s, y: rightTop.y * s)

        let dx = rightTopPt.x - vertexPt.x
        let dy = rightTopPt.y - vertexPt.y
        let len = (dx * dx + dy * dy).squareRoot()
        let ux = dx / len, uy = dy / len
        let px = -uy, py = ux

        let tipExtend: CGFloat = 100 * s
        let tip = CGPoint(x: rightTopPt.x + ux * tipExtend, y: rightTopPt.y + uy * tipExtend)
        let baseHalfWidth: CGFloat = 115 * s
        let baseCenter = CGPoint(x: rightTopPt.x - ux * 55 * s, y: rightTopPt.y - uy * 55 * s)
        let base1 = CGPoint(x: baseCenter.x + px * baseHalfWidth, y: baseCenter.y + py * baseHalfWidth)
        let base2 = CGPoint(x: baseCenter.x - px * baseHalfWidth, y: baseCenter.y - py * baseHalfWidth)

        var p = Path()
        p.move(to: tip)
        p.addLine(to: base1)
        p.addLine(to: base2)
        p.closeSubpath()
        return p
    }
}

#Preview {
    ZStack {
        Color.ink.ignoresSafeArea()
        VertmaxLogoMark()
            .frame(width: 160, height: 160)
    }
}
