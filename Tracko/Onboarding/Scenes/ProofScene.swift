import SwiftUI

/// Scene 6, Proof on a clock. A timeline from today to month 3; the curve rises, dips for
/// recovery (in a neutral colour, never red) and rises again. "Proof, on a clock."
struct ProofScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var replay = 0
    @State private var drawn: CGFloat = 0
    @State private var revealed = 0

    /// Normalised points: x is time (not to scale), y is strength. Index 3 is the dip.
    private let points: [CGPoint] = [
        CGPoint(x: 0, y: 0.08),
        CGPoint(x: 0.3, y: 0.26),
        CGPoint(x: 0.5, y: 0.5),
        CGPoint(x: 0.62, y: 0.4),
        CGPoint(x: 0.8, y: 0.62),
        CGPoint(x: 1, y: 0.86),
    ]

    private struct Tick: Identifiable {
        let label: String
        let x: CGFloat
        var id: String { label }
    }

    private let ticks = [Tick(label: "Today", x: 0), Tick(label: "Week 1", x: 0.3), Tick(label: "Month 3", x: 1)]

    var body: some View {
        SceneLayout("Proof, on a clock.", subline: "Checkpoints with real numbers, not a promise.") {
            chart
                .padding(Space.l)
                .background(Theme.slab, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "A strength line from today to month 3. Up 4 percent by week 1, a dip for recovery, then up 18 percent by month 3."
                )
        }
        .contentShape(Rectangle())
        .onTapGesture { replay += 1 }
        .task(id: replay) { await play() }
        .sensoryFeedback(.success, trigger: revealed) { _, new in new == 3 }
    }

    private var chart: some View {
        GeometryReader { geo in
            let plot = CGSize(width: geo.size.width, height: max(geo.size.height - 32, 0))
            ZStack(alignment: .topLeading) {
                ForEach(1..<4) { line in
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(width: plot.width, height: 1)
                        .offset(y: plot.height * CGFloat(line) / 4)
                }

                ProofCurve(points: points)
                    .trim(from: 0, to: drawn)
                    .stroke(Theme.gain, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(width: plot.width, height: plot.height)

                marker(at: points[1], in: plot, color: Theme.gain)
                    .opacity(revealed >= 1 ? 1 : 0)
                Text("+4%")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Theme.gain)
                    .position(location(of: points[1], in: plot, dx: 0, dy: -24))
                    .opacity(revealed >= 1 ? 1 : 0)

                marker(at: points[3], in: plot, color: Theme.chalkMuted)
                    .opacity(revealed >= 2 ? 1 : 0)
                Text("recovery")
                    .font(.subheadline)
                    .foregroundStyle(Theme.chalkMuted)
                    .position(location(of: points[3], in: plot, dx: 0, dy: 26))
                    .opacity(revealed >= 2 ? 1 : 0)

                marker(at: points[5], in: plot, color: Theme.gain)
                    .opacity(revealed >= 3 ? 1 : 0)
                Text("+18%")
                    .font(.score(40))
                    .monospacedDigit()
                    .foregroundStyle(Theme.gain)
                    .position(location(of: points[5], in: plot, dx: -44, dy: 4))
                    .opacity(revealed >= 3 ? 1 : 0)

                ForEach(ticks) { tick in
                    Text(tick.label)
                        .font(.subheadline)
                        .foregroundStyle(Theme.chalkMuted)
                        .fixedSize()
                        .position(x: min(max(tick.x * plot.width, 30), plot.width - 30), y: plot.height + 20)
                }
            }
        }
    }

    private func location(of point: CGPoint, in plot: CGSize, dx: CGFloat, dy: CGFloat) -> CGPoint {
        CGPoint(x: point.x * plot.width + dx, y: (1 - point.y) * plot.height + dy)
    }

    private func marker(at point: CGPoint, in plot: CGSize, color: Color) -> some View {
        Circle()
            .fill(color)
            .overlay(Circle().stroke(Theme.slab, lineWidth: 3))
            .frame(width: 14, height: 14)
            .position(location(of: point, in: plot, dx: 0, dy: 0))
    }

    @MainActor
    private func play() async {
        guard !reduceMotion else {
            drawn = 1
            revealed = 3
            return
        }
        Script.reset {
            drawn = 0
            revealed = 0
        }
        guard await Script.wait(0.4) else { return }
        withAnimation(.easeInOut(duration: 2.4)) { drawn = 1 }
        // Reveal each checkpoint as the line reaches it.
        for (step, delay) in [(1, 0.7), (2, 0.8), (3, 0.95)] {
            guard await Script.wait(delay) else { return }
            withAnimation(Motion.settle) { revealed = step }
        }
    }
}

/// A smooth line through normalised points (x right, y up), via Catmull-Rom.
struct ProofCurve: Shape {
    var points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        let mapped = points.map {
            CGPoint(x: rect.minX + $0.x * rect.width, y: rect.maxY - $0.y * rect.height)
        }
        var path = Path()
        guard let first = mapped.first else { return path }
        path.move(to: first)
        for index in 0..<(mapped.count - 1) {
            let p0 = mapped[max(index - 1, 0)]
            let p1 = mapped[index]
            let p2 = mapped[index + 1]
            let p3 = mapped[min(index + 2, mapped.count - 1)]
            path.addCurve(
                to: p2,
                control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            )
        }
        return path
    }
}

#Preview {
    ProofScene()
        .background(Theme.ink)
}
