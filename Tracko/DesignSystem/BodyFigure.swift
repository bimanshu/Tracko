import SwiftUI

enum Muscle: Hashable, CaseIterable {
    case shoulders, chest, arms, core, legs
}

/// The living body (§6.3): an illustrated figure that gains a little muscle where you trained.
///
/// - `growth`: extra size per muscle, 0...1. Drive it only from real strength numbers, on a slowing curve.
/// - `highlight`: how strongly a muscle shows as trained (muscle red), 0...1.
/// - `lean`: narrows the waist for cut mode, 0...1.
///
/// Drawn from simple shapes for now; Rive is the candidate for the real thing (§10).
struct BodyFigure: View {
    var growth: [Muscle: Double] = [:]
    var highlight: [Muscle: Double] = [:]
    var lean: Double = 0

    private static let canvas = CGSize(width: 200, height: 420)

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / Self.canvas.width, geo.size.height / Self.canvas.height)
            figure
                .frame(width: Self.canvas.width, height: Self.canvas.height)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(Self.canvas.width / Self.canvas.height, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func amount(_ muscle: Muscle, in values: [Muscle: Double]) -> CGFloat {
        CGFloat(min(max(values[muscle] ?? 0, 0), 1))
    }

    private var figure: some View {
        let shoulders = amount(.shoulders, in: growth)
        let chest = amount(.chest, in: growth)
        let arms = amount(.arms, in: growth)
        let core = amount(.core, in: growth)
        let legs = amount(.legs, in: growth)
        let lean = CGFloat(min(max(self.lean, 0), 1))
        let span: CGFloat = 98 + 14 * shoulders
        let waist: CGFloat = 66 - 16 * lean + 4 * core
        let sides: [CGFloat] = [-1, 1]

        return ZStack {
            ForEach(sides, id: \.self) { side in
                part(Capsule(), .legs, x: 100 + side * 19, y: 292, width: 34 + 8 * legs, height: 96)
                part(Capsule(), .legs, x: 100 + side * 20, y: 378, width: 24 + 6 * legs, height: 70)
                part(Capsule(), nil, x: 100 + side * 24, y: 414, width: 28, height: 10)
            }
            part(RoundedRectangle(cornerRadius: 16, style: .continuous), nil, x: 100, y: 228, width: waist + 8, height: 36)

            ForEach(sides, id: \.self) { side in
                part(Capsule(), .arms, x: 100 + side * (span / 2 + 10), y: 140, width: 22 + 10 * arms, height: 62, angle: -side * 8)
                part(Capsule(), .arms, x: 100 + side * (span / 2 + 17), y: 200, width: 18 + 5 * arms, height: 58, angle: -side * 5)
                part(Circle(), nil, x: 100 + side * (span / 2 + 20), y: 236, width: 15, height: 15)
            }

            part(TorsoShape(shoulderWidth: span, waistWidth: waist), nil, x: 100, y: 150, width: 140, height: 130)
            ForEach(sides, id: \.self) { side in
                part(Ellipse(), .chest, x: 100 + side * (20 + 2 * chest), y: 118, width: 38 + 9 * chest, height: 30 + 6 * chest)
            }
            part(RoundedRectangle(cornerRadius: 12, style: .continuous), .core, x: 100, y: 172, width: 34 + 4 * core - 6 * lean, height: 56)
            ForEach(sides, id: \.self) { side in
                part(Ellipse(), .shoulders, x: 100 + side * (span / 2 + 2), y: 98, width: 30 + 12 * shoulders, height: 28 + 8 * shoulders)
            }

            part(RoundedRectangle(cornerRadius: 6, style: .continuous), nil, x: 100, y: 68, width: 20 + 4 * shoulders, height: 20)
            part(Circle(), nil, x: 100, y: 38, width: 42, height: 42)
        }
    }

    private func part<S: Shape>(
        _ shape: S,
        _ muscle: Muscle?,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        angle: CGFloat = 0
    ) -> some View {
        let glow: CGFloat = muscle.map { amount($0, in: highlight) } ?? 0
        return shape
            .fill(Theme.figure)
            .overlay { shape.fill(Theme.muscle.opacity(0.85 * glow)) }
            .overlay { shape.stroke(Theme.ink.opacity(0.5), lineWidth: 1.5) }
            .frame(width: max(width, 0), height: max(height, 0))
            .shadow(color: Theme.muscle.opacity(0.5 * glow), radius: 10 * glow)
            .rotationEffect(.degrees(angle))
            .position(x: x, y: y)
    }
}

/// Shoulders to waist. Animates between widths so the body can bulk or lean.
struct TorsoShape: Shape {
    var shoulderWidth: CGFloat
    var waistWidth: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(shoulderWidth, waistWidth) }
        set {
            shoulderWidth = newValue.first
            waistWidth = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let mid = rect.midX
        let shoulder = shoulderWidth / 2
        let waist = waistWidth / 2
        let top = rect.minY + 12
        var path = Path()
        path.move(to: CGPoint(x: mid - shoulder, y: top))
        path.addQuadCurve(to: CGPoint(x: mid + shoulder, y: top), control: CGPoint(x: mid, y: rect.minY - 4))
        path.addCurve(
            to: CGPoint(x: mid + waist, y: rect.maxY),
            control1: CGPoint(x: mid + shoulder, y: top + 50),
            control2: CGPoint(x: mid + waist, y: rect.maxY - 40)
        )
        path.addLine(to: CGPoint(x: mid - waist, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: mid - shoulder, y: top),
            control1: CGPoint(x: mid - waist, y: rect.maxY - 40),
            control2: CGPoint(x: mid - shoulder, y: top + 50)
        )
        path.closeSubpath()
        return path
    }
}

#Preview("Body figure") {
    HStack(spacing: Space.l) {
        BodyFigure()
        BodyFigure(growth: [.shoulders: 1, .chest: 1, .arms: 1, .legs: 0.6], highlight: [.shoulders: 1, .arms: 0.6])
        BodyFigure(growth: [.shoulders: 0.2, .arms: 0.2], lean: 1)
    }
    .frame(height: 320)
    .padding(Space.gutter)
    .background(Theme.ink)
}
