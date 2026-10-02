import SwiftUI

/// Scene 2, Note to verdict. The typed line breaks into chips, Monday's ghost slides in,
/// the bars grow and +10% rolls up. "Log it like a note. We do the maths."
struct NoteToVerdictScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var tokens
    @State private var replay = 0
    @State private var parsed = false
    @State private var ghost = false
    @State private var bars = false
    @State private var percent = 0
    @State private var verdictShown = false

    private let demo = DemoContent()

    private var verdict: Verdict {
        LiftMath.verdict(from: demo.monday, to: demo.thursday, unit: demo.unit)
    }

    var body: some View {
        SceneLayout("Log it like a note. We do the maths.") {
            VStack(alignment: .leading, spacing: Space.m) {
                ghostRow
                noteLine
                volumeBars
                    .padding(.top, Space.xs)
                score
                Spacer(minLength: 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { replay += 1 }
        .task(id: replay) { await play() }
        .sensoryFeedback(.success, trigger: verdictShown) { old, new in !old && new }
    }

    // MARK: Pieces

    /// Monday, the past, in the ghost style.
    private var ghostRow: some View {
        HStack {
            Text("Monday")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(demo.monday.summary(unit: demo.unit))
                .font(.callout)
                .monospacedDigit()
        }
        .foregroundStyle(Theme.past)
        .padding(Space.m)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Theme.past.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        }
        .opacity(ghost ? 1 : 0)
        .offset(x: ghost ? 0 : -48)
        .accessibilityElement(children: .combine)
    }

    /// Thursday's line: a note on paper, then parsed into chips.
    @ViewBuilder
    private var noteLine: some View {
        if parsed {
            VStack(alignment: .leading, spacing: Space.s) {
                HStack {
                    token("name", demo.exerciseName, .label)
                    Spacer(minLength: 0)
                    Text("Thursday")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.chalkMuted)
                }
                HStack(spacing: Space.s) {
                    token("weight", demo.weightText, .chip)
                    ForEach(Array(demo.thursdayReps.enumerated()), id: \.offset) { index, reps in
                        token("rep\(index)", "\(reps)", .chip)
                    }
                }
            }
            .padding(Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.slab, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .transition(.opacity)
        } else {
            HStack(spacing: 5) {
                token("name", demo.exerciseName, .paper)
                token("weight", demo.weightText, .paper)
                Text("x")
                ForEach(Array(demo.thursdayReps.enumerated()), id: \.offset) { index, reps in
                    HStack(spacing: 0) {
                        token("rep\(index)", "\(reps)", .paper)
                        if index < demo.thursdayReps.count - 1 {
                            Text(",")
                        }
                    }
                }
            }
            .font(.callout)
            .foregroundStyle(Theme.pencil)
            .padding(Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.paper, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .transition(.opacity)
        }
    }

    private enum TokenStyle {
        case paper, label, chip
    }

    private func token(_ id: String, _ text: String, _ style: TokenStyle) -> some View {
        Text(text)
            .font(style == .paper ? Font.callout : Font.callout.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(style == .paper ? Theme.pencil : Theme.chalk)
            .fixedSize()
            .padding(.horizontal, style == .chip ? 10 : 0)
            .padding(.vertical, style == .chip ? 6 : 0)
            .background(
                style == .chip ? Theme.slabRaised : Color.clear,
                in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous)
            )
            .matchedGeometryEffect(id: id, in: tokens)
    }

    private var volumeBars: some View {
        let largest = max(demo.monday.volume, demo.thursday.volume)
        return VStack(alignment: .leading, spacing: Space.s) {
            barRow("Monday", volume: demo.monday.volume, of: largest, color: Theme.past)
            barRow("Thursday", volume: demo.thursday.volume, of: largest, color: Theme.gain)
        }
        .opacity(bars ? 1 : 0)
    }

    private func barRow(_ label: String, volume: Double, of largest: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack {
                Text(label)
                    .foregroundStyle(Theme.chalkMuted)
                Spacer()
                Text(demo.weightString(volume))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(Theme.chalk)
            }
            .font(.subheadline)
            VolumeBar(fraction: bars ? volume / largest : 0, color: color)
        }
        .accessibilityElement(children: .combine)
    }

    private var score: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(demo.exerciseName) vs Monday")
                .font(.subheadline)
                .foregroundStyle(Theme.chalkMuted)
            PercentScore(value: percent, size: 80)
            Text(verdict.reason)
                .font(.body)
                .foregroundStyle(Theme.chalk)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(verdictShown ? 1 : 0)
        }
        .opacity(bars ? 1 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(demo.exerciseName) versus Monday: \(verdict.sentence)")
    }

    // MARK: Script

    @MainActor
    private func play() async {
        let target = verdict.percent
        guard !reduceMotion else {
            parsed = true
            ghost = true
            bars = true
            percent = target
            verdictShown = true
            return
        }
        Script.reset {
            parsed = false
            ghost = false
            bars = false
            percent = 0
            verdictShown = false
        }
        guard await Script.wait(0.9) else { return }
        withAnimation(Motion.settle) { parsed = true }
        guard await Script.wait(0.8) else { return }
        withAnimation(Motion.settle) { ghost = true }
        guard await Script.wait(0.7) else { return }
        withAnimation(Motion.grow) { bars = true }
        guard await Script.wait(0.4) else { return }
        for value in stride(from: 1, through: target, by: 1) {
            withAnimation(.snappy(duration: 0.2)) { percent = value }
            guard await Script.wait(0.07) else { return }
        }
        guard await Script.wait(0.2) else { return }
        withAnimation(Motion.fade) { verdictShown = true }
    }
}

#Preview {
    NoteToVerdictScene()
        .background(Theme.ink)
}
