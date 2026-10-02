import SwiftUI

/// Scene 4, Try it. Drag the last set's reps; the % and the shoulder glow change live.
/// Nudges the slider once if it isn't touched.
struct TryItScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lastSetReps: Double = 10
    @State private var touched = false

    private let demo = DemoContent()
    private let range: ClosedRange<Double> = 4...16

    private var session: LiftSession {
        var reps = demo.thursdayReps
        reps[reps.count - 1] = Int(lastSetReps)
        return LiftSession(weight: demo.weight, reps: reps)
    }

    private var verdict: Verdict {
        LiftMath.verdict(from: demo.monday, to: session, unit: demo.unit)
    }

    /// Shoulders always show as trained; they glow brighter the more you beat Monday.
    private var glow: Double {
        min(max(Double(verdict.percent) / 25, 0.15), 1)
    }

    private var earlierSets: String {
        demo.thursdayReps.dropLast().map { String($0) }.joined(separator: ", ")
    }

    var body: some View {
        SceneLayout("Try it.", subline: "Drag the reps.") {
            VStack(spacing: Space.l) {
                HStack(spacing: Space.l) {
                    BodyFigure(growth: [.shoulders: glow * 0.4], highlight: [.shoulders: glow])
                        .frame(maxWidth: 150, maxHeight: .infinity)
                        .animation(Motion.settle, value: glow)
                    readout
                }
                repSlider
            }
        }
        .sensoryFeedback(.selection, trigger: Int(lastSetReps))
        .task { await nudge() }
    }

    private var readout: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Text("vs Monday")
                .font(.subheadline)
                .foregroundStyle(Theme.chalkMuted)
            PercentScore(
                value: verdict.percent,
                size: 84,
                color: verdict.trend == .up ? Theme.gain : Theme.chalkMuted
            )
            .animation(Motion.snappy, value: verdict.percent)
            HStack(spacing: 0) {
                Text("\(demo.weightText) × \(earlierSets), ")
                Text("\(Int(lastSetReps))")
                    .foregroundStyle(Theme.target)
                    .contentTransition(.numericText(value: lastSetReps))
                    .animation(Motion.snappy, value: lastSetReps)
            }
            .font(.callout.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(Theme.chalk)
            Text(verdict.reason)
                .font(.subheadline)
                .foregroundStyle(Theme.chalkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Versus Monday: \(verdict.sentence)")
    }

    private var repSlider: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text("Last set reps")
                .font(.subheadline)
                .foregroundStyle(Theme.chalkMuted)
            Slider(value: $lastSetReps, in: range, step: 1) {
                Text("Last set reps")
            } minimumValueLabel: {
                Text("\(Int(range.lowerBound))")
            } maximumValueLabel: {
                Text("\(Int(range.upperBound))")
            } onEditingChanged: { editing in
                if editing { touched = true }
            }
            .tint(Theme.target)
            .font(.subheadline)
            .foregroundStyle(Theme.chalkMuted)
            .accessibilityValue("\(Int(lastSetReps)) reps")
        }
    }

    /// Moves the slider once, to show it's live, if nobody has touched it yet.
    @MainActor
    private func nudge() async {
        guard !reduceMotion else { return }
        guard await Script.wait(1.4), !touched else { return }
        for value in [11.0, 12.0] {
            guard !touched else { return }
            withAnimation(Motion.snappy) { lastSetReps = value }
            guard await Script.wait(0.35) else { return }
        }
    }
}

#Preview {
    TryItScene()
        .background(Theme.ink)
}
