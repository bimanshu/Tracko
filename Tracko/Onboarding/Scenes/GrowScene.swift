import SwiftUI

/// Scene 5, Watch yourself grow. A 12-week time-lapse: trained muscles grow, fast and then slowing.
/// The figure never grows faster than the honest curve (§6.3).
struct GrowScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var replay = 0
    @State private var week = 0

    private let weeks = 12
    /// Strength change by week 12 in the demo, shown on the same slowing curve.
    private let strengthByEnd = 24.0

    private var progress: Double {
        LiftMath.honestProgress(week: Double(week), of: Double(weeks))
    }

    private var strength: Int {
        Int((strengthByEnd * progress).rounded())
    }

    var body: some View {
        SceneLayout("Watch yourself grow.", subline: "Driven by your real numbers. Never faster.") {
            ZStack(alignment: .topLeading) {
                BodyFigure(
                    growth: [
                        .shoulders: 0.7 * progress,
                        .chest: 0.7 * progress,
                        .arms: 0.8 * progress,
                        .core: 0.3 * progress,
                        .legs: 0.35 * progress,
                    ],
                    highlight: [
                        .shoulders: 0.5 * progress,
                        .chest: 0.5 * progress,
                        .arms: 0.5 * progress,
                        .legs: 0.2 * progress,
                    ]
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Week \(week)")
                        .font(.score(40))
                        .monospacedDigit()
                        .foregroundStyle(Theme.chalk)
                        .contentTransition(.numericText(value: Double(week)))
                    Text("Strength \(LiftMath.formatPercent(strength))")
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(strength > 0 ? Theme.gain : Theme.chalkMuted)
                        .contentTransition(.numericText(value: Double(strength)))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Over \(weeks) weeks the muscles you train grow, quickly at first and then more slowly. Strength up \(Int(strengthByEnd)) percent."
            )
        }
        .contentShape(Rectangle())
        .onTapGesture { replay += 1 }
        .task(id: replay) { await play() }
    }

    @MainActor
    private func play() async {
        guard !reduceMotion else {
            week = weeks
            return
        }
        Script.reset { week = 0 }
        guard await Script.wait(0.6) else { return }
        for next in 1...weeks {
            withAnimation(.easeOut(duration: 0.25)) { week = next }
            guard await Script.wait(0.22) else { return }
        }
    }
}

#Preview {
    GrowScene()
        .background(Theme.ink)
}
