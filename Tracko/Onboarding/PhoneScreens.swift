import SwiftUI

// The live screens on the heroes' giant phone. Each plays one moment when its page is active,
// says when it lands (`answered`, which swaps the character's face and plays a haptic), and
// jumps straight to the end with Reduce Motion. Numbers come from DemoContent and LiftMath.
// Laid out 140 pt wide (see PhoneScreenLayer); one idea per screen, with the number largest.
// Labels in the top ~80 pt sit on the screen's glow, so they use textSecondary, not textTertiary.

private enum PhoneText {
    static let label = TypeScale.illustration(.semibold, 10.5)
    static let title = TypeScale.illustration(.bold, 15)
    static let note = TypeScale.illustration(.regular, 14)
    static let detail = TypeScale.illustration(.regular, 11.5)
    static let tile = TypeScale.illustration(.bold, 14)
    static let score = TypeScale.illustration(.extraBold, 40)
}

/// The verdict at the foot of a phone screen: the number first, then the plain reason (§8).
private struct PhoneVerdict: View {
    let percent: Int
    let reason: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LiftMath.formatPercent(percent))
                .font(PhoneText.score)
                .monospacedDigit()
                .foregroundStyle(Theme.accent)
                .contentTransition(.numericText(value: Double(percent)))
            Text(reason)
                .font(PhoneText.detail)
                .lineSpacing(1.5)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Log it like a note

struct LogPhoneScreen: View {
    let demo: DemoContent
    let run: ScriptRun
    @Binding var answered: Bool

    @State private var typed = 0
    @State private var showsMonday = false
    @State private var showsVerdict = false
    @State private var percent = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var line: String { demo.noteLine(demo.thursday) }
    private var verdict: Verdict { demo.thursdayVerdict }

    var body: some View {
        PhoneScreen {
            VStack(alignment: .leading, spacing: 0) {
                Text("Thursday")
                    .font(PhoneText.label)
                    .foregroundStyle(Theme.textSecondary)
                Text(demo.exerciseName)
                    .font(PhoneText.title)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 2)

                // The note, typed in, with a caret while typing.
                HStack(spacing: 1) {
                    Text(line.prefix(typed))
                        .font(PhoneText.note)
                        .foregroundStyle(Theme.textPrimary)
                    Capsule()
                        .fill(Theme.textPrimary)
                        .frame(width: 1.5, height: 16)
                        .opacity(typed < line.count ? 1 : 0)
                }
                .padding(.top, 12)

                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1)
                    .padding(.vertical, 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Monday")
                        .font(PhoneText.label)
                        .foregroundStyle(Theme.textTertiary)
                    Text(demo.noteLine(demo.monday))
                        .font(PhoneText.detail)
                        .foregroundStyle(Theme.textSecondary)
                }
                .opacity(showsMonday ? 1 : 0)
                .offset(y: showsMonday ? 0 : 6)

                Spacer(minLength: 8)

                PhoneVerdict(percent: percent, reason: verdict.reason)
                    .opacity(showsVerdict ? 1 : 0)
            }
        }
        .task(id: run) { await play() }
    }

    @MainActor
    private func play() async {
        Script.reset {
            typed = 0
            showsMonday = false
            showsVerdict = false
            percent = 0
            answered = false
        }
        guard run.isActive else { return }
        if reduceMotion {
            typed = line.count
            showsMonday = true
            showsVerdict = true
            percent = verdict.percent
            answered = true
            return
        }
        guard await Script.wait(0.6) else { return }
        for count in 1...line.count {
            typed = count
            guard await Script.wait(0.07) else { return }
        }
        guard await Script.wait(0.3) else { return }
        withAnimation(Motion.settle) { showsMonday = true }
        guard await Script.wait(0.6) else { return }
        withAnimation(Motion.fade) { showsVerdict = true }
        for value in 0...max(verdict.percent, 0) {
            withAnimation(Motion.snappy) { percent = value }
            guard await Script.wait(0.045) else { return }
        }
        answered = true
    }
}

// MARK: - The number to beat

/// Thursday's sets on one line, today's as tiles that fill set by set, and a bar of the total
/// climbing to Thursday's mark. The last set beats it.
struct BeatPhoneScreen: View {
    let demo: DemoContent
    let run: ScriptRun
    @Binding var answered: Bool

    @State private var setsDone = 0
    @State private var showsNeed = false
    @State private var showsVerdict = false
    @State private var percent = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var target: Double { demo.thursday.volume }
    private var volumeSoFar: Double { LiftMath.volume(Array(demo.today.sets.prefix(setsDone))) }
    private var beaten: Bool { volumeSoFar > target }
    /// The bar's full width: a little past today's total, so the finish clears the mark.
    private var scaleMax: Double { demo.today.volume * 1.08 }

    var body: some View {
        PhoneScreen {
            VStack(alignment: .leading, spacing: 0) {
                Text(demo.exerciseName)
                    .font(PhoneText.title)
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 4) {
                    Text("Thursday")
                        .font(PhoneText.label)
                        .foregroundStyle(Theme.textSecondary)
                    Text(demo.thursdayReps.map(String.init).joined(separator: ", "))
                        .font(PhoneText.detail)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 10)

                HStack(spacing: 6) {
                    ForEach(Array(demo.todayReps.enumerated()), id: \.offset) { index, reps in
                        setTile(index: index, reps: reps)
                    }
                }
                .padding(.top, 10)

                progressBar
                    .padding(.top, 14)

                Spacer(minLength: 8)

                ZStack(alignment: .bottomLeading) {
                    Text(needText)
                        .font(PhoneText.detail)
                        .lineSpacing(1.5)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(showsNeed && !showsVerdict ? 1 : 0)
                    PhoneVerdict(percent: percent, reason: demo.todayVerdict.reason)
                        .opacity(showsVerdict ? 1 : 0)
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: setsDone) { _, new in new > 0 }
        .task(id: run) { await play() }
    }

    private var needText: String {
        let need = demo.lastSetNeed
        if let tie = need.tie {
            return "\(tie) reps ties Thursday. \(need.beat) beats it."
        }
        return "\(need.beat) reps beats Thursday."
    }

    private func setTile(index: Int, reps: Int) -> some View {
        let isDone = index < setsDone
        let isWinner = isDone && index == demo.todayReps.count - 1 && beaten
        return Text(isDone ? "\(reps)" : "–")
            .font(PhoneText.tile)
            .monospacedDigit()
            .foregroundStyle(isWinner ? Theme.textInverse : (isDone ? Theme.textPrimary : Theme.textTertiary))
            .frame(width: 32, height: 32)
            .background(
                isWinner ? Theme.accent : Theme.bgRaised,
                in: RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
            )
    }

    /// The bar fills set by set toward Thursday's total, marked by a line labelled underneath.
    private var progressBar: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let marker = width * target / scaleMax
            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(Theme.bgRaised)
                    .frame(height: 8)
                Capsule()
                    .fill(beaten ? Theme.accent : Theme.fillStrong)
                    .frame(width: width * min(volumeSoFar / scaleMax, 1), height: 8)
                Capsule()
                    .fill(Theme.fillStrong)
                    .frame(width: 2, height: 14)
                    .offset(x: marker - 1, y: -3)
                Text("Thursday")
                    .font(PhoneText.label)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize()
                    .frame(width: marker, alignment: .trailing)
                    .offset(y: 16)
            }
        }
        .frame(height: 30)
    }

    @MainActor
    private func play() async {
        Script.reset {
            setsDone = 0
            showsNeed = false
            showsVerdict = false
            percent = 0
            answered = false
        }
        guard run.isActive else { return }
        if reduceMotion {
            setsDone = demo.todayReps.count
            showsNeed = true
            showsVerdict = true
            percent = demo.todayVerdict.percent
            answered = true
            return
        }
        guard await Script.wait(0.6) else { return }
        withAnimation(Motion.grow) { setsDone = 1 }
        guard await Script.wait(0.7) else { return }
        withAnimation(Motion.grow) { setsDone = 2 }
        guard await Script.wait(0.5) else { return }
        withAnimation(Motion.fade) { showsNeed = true }
        guard await Script.wait(1.3) else { return }
        withAnimation(Motion.grow) { setsDone = 3 }
        guard await Script.wait(0.5) else { return }
        withAnimation(Motion.fade) { showsVerdict = true }
        for value in 0...max(demo.todayVerdict.percent, 0) {
            withAnimation(Motion.snappy) { percent = value }
            guard await Script.wait(0.08) else { return }
        }
        answered = true
    }
}

// MARK: - Watch yourself get stronger

struct GrowPhoneScreen: View {
    let demo: DemoContent
    let run: ScriptRun
    @Binding var answered: Bool

    @State private var drawn: CGFloat = 0
    @State private var percent = 0
    @State private var showsScore = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        PhoneScreen {
            VStack(alignment: .leading, spacing: 0) {
                Text(demo.exerciseName)
                    .font(PhoneText.title)
                    .foregroundStyle(Theme.textPrimary)
                Text("Estimated max")
                    .font(PhoneText.label)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 2)

                GrowthChart(curve: demo.growthCurve, drawn: drawn)
                    .frame(height: 92)
                    .padding(.top, 16)

                HStack {
                    Text("Week 1")
                    Spacer()
                    Text("Week \(demo.growthWeeks)")
                }
                .font(PhoneText.label)
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 6)

                Spacer(minLength: 8)

                PhoneVerdict(percent: percent, reason: "Since week 1.")
                    .opacity(showsScore ? 1 : 0)
            }
        }
        .task(id: run) { await play() }
    }

    @MainActor
    private func play() async {
        Script.reset {
            drawn = 0
            percent = 0
            showsScore = false
            answered = false
        }
        guard run.isActive else { return }
        if reduceMotion {
            drawn = 1
            percent = demo.growthPercent
            showsScore = true
            answered = true
            return
        }
        guard await Script.wait(0.5) else { return }
        withAnimation(.easeInOut(duration: 1.6)) { drawn = 1 }
        withAnimation(Motion.fade) { showsScore = true }
        let steps = max(demo.growthPercent, 1)
        for value in 0...demo.growthPercent {
            withAnimation(Motion.snappy) { percent = value }
            guard await Script.wait(1.6 / Double(steps)) else { return }
        }
        answered = true
    }
}

/// The honest growth curve: a line and a soft fill, drawn left to right as `drawn` goes 0 → 1.
private struct GrowthChart: View {
    let curve: [Double]
    let drawn: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let points = curve.enumerated().map { index, value in
                CGPoint(
                    x: proxy.size.width * CGFloat(index) / CGFloat(max(curve.count - 1, 1)),
                    y: proxy.size.height * (1 - (0.08 + 0.84 * CGFloat(value)))
                )
            }
            ZStack(alignment: .topLeading) {
                area(points, height: proxy.size.height)
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.3), Theme.accent.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: proxy.size.width * drawn)
                    }
                line(points)
                    .trim(from: 0, to: drawn)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                if let last = points.last {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)
                        .position(last)
                        .opacity(drawn >= 1 ? 1 : 0)
                }
            }
        }
    }

    private func line(_ points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }

    private func area(_ points: [CGPoint], height: CGFloat) -> Path {
        var path = line(points)
        if let last = points.last, let first = points.first {
            path.addLine(to: CGPoint(x: last.x, y: height))
            path.addLine(to: CGPoint(x: first.x, y: height))
            path.closeSubpath()
        }
        return path
    }
}
