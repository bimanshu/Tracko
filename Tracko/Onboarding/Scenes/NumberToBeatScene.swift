import SwiftUI

/// Scene 3, Number to beat. Today's bar fills set by set towards Thursday's dashed line,
/// the app says what the last set needs, then the bar passes the line.
/// "Always know the number to beat."
struct NumberToBeatScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var replay = 0
    @State private var logged = 0
    @State private var hintShown = false

    private let demo = DemoContent()

    private var target: Double { demo.thursday.volume }
    private var today: LiftSession { demo.today }
    private var loggedVolume: Double { LiftMath.volume(Array(today.sets.prefix(logged))) }
    private var beaten: Bool { loggedVolume > target }

    private var need: LiftMath.LastSetNeed {
        LiftMath.lastSetNeed(target: target, done: Array(today.sets.dropLast()), weight: demo.weight)
    }

    private var goUp: LiftSession {
        LiftMath.goUpOption(target: target, weight: demo.weight, step: demo.weightStep, sets: today.sets.count)
    }

    private var verdict: Verdict {
        LiftMath.verdict(from: demo.thursday, to: today, unit: demo.unit)
    }

    private var hint: String {
        if let tie = need.tie {
            return "\(tie) reps ties Thursday. \(need.beat) beats it."
        }
        return "\(need.beat) reps beats Thursday."
    }

    var body: some View {
        SceneLayout("Always know the number to beat.") {
            VStack {
                Spacer(minLength: 0)
                card
                Spacer(minLength: 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { replay += 1 }
        .task(id: replay) { await play() }
        .sensoryFeedback(.impact(weight: .light), trigger: logged) { old, new in new > old }
        .sensoryFeedback(.success, trigger: beaten) { old, new in !old && new }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            header
            progress
            tiles
            footer
        }
        .padding(Space.l)
        .background(Theme.slab, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(demo.exerciseName)
                    .font(.headline)
                    .foregroundStyle(Theme.chalk)
                Text("Number to beat")
                    .font(.subheadline)
                    .foregroundStyle(Theme.chalkMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(demo.weightString(target))
                    .font(.score(34))
                    .monospacedDigit()
                    .foregroundStyle(Theme.target)
                Text("Thursday")
                    .font(.subheadline)
                    .foregroundStyle(Theme.past)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var progress: some View {
        let scale = target * 1.12
        return VStack(alignment: .leading, spacing: Space.s) {
            VolumeBar(fraction: loggedVolume / scale, color: beaten ? Theme.gain : Theme.chalk, height: 18)
                .overlay {
                    GeometryReader { geo in
                        Path { path in
                            let x = geo.size.width * target / scale
                            path.move(to: CGPoint(x: x, y: -6))
                            path.addLine(to: CGPoint(x: x, y: geo.size.height + 6))
                        }
                        .stroke(Theme.target, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    }
                }
            HStack(spacing: Space.xs) {
                Text("Today")
                    .foregroundStyle(Theme.chalkMuted)
                Text(demo.weightString(loggedVolume))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(beaten ? Theme.gain : Theme.chalk)
                    .contentTransition(.numericText(value: loggedVolume))
            }
            .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }

    private var tiles: some View {
        HStack(spacing: Space.s) {
            ForEach(Array(today.sets.enumerated()), id: \.offset) { index, set in
                SetTile(
                    number: index + 1,
                    reps: index < logged ? set.reps : nil,
                    isNext: hintShown && index == logged
                )
            }
        }
    }

    private var footer: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(hint)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.target)
                Text("or go up: \(goUp.summary(unit: demo.unit))")
                    .font(.callout)
                    .foregroundStyle(Theme.chalkMuted)
            }
            .opacity(hintShown && !beaten ? 1 : 0)

            Text(verdict.sentence)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.gain)
                .opacity(beaten ? 1 : 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @MainActor
    private func play() async {
        guard !reduceMotion else {
            hintShown = true
            logged = today.sets.count
            return
        }
        Script.reset {
            logged = 0
            hintShown = false
        }
        guard await Script.wait(0.7) else { return }
        for set in 1..<today.sets.count {
            withAnimation(Motion.settle) { logged = set }
            guard await Script.wait(0.8) else { return }
        }
        withAnimation(Motion.fade) { hintShown = true }
        guard await Script.wait(1.6) else { return }
        withAnimation(Motion.settle) { logged = today.sets.count }
    }
}

private struct SetTile: View {
    let number: Int
    let reps: Int?
    let isNext: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("Set \(number)")
                .font(.caption)
                .foregroundStyle(Theme.chalkMuted)
            Text(reps.map { String($0) } ?? (isNext ? "?" : "–"))
                .font(.score(30))
                .monospacedDigit()
                .foregroundStyle(reps != nil ? Theme.chalk : (isNext ? Theme.target : Theme.chalkDim))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(
            Theme.slabRaised.opacity(reps == nil ? 0.5 : 1),
            in: RoundedRectangle(cornerRadius: Radius.chip + 4, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Radius.chip + 4, style: .continuous)
                .strokeBorder(isNext ? Theme.target : Color.clear, lineWidth: 1.5)
        }
        .scaleEffect(reps == nil ? 0.96 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reps.map { "Set \(number): \($0) reps" } ?? "Set \(number): not logged yet")
    }
}

#Preview {
    NumberToBeatScene()
        .background(Theme.ink)
}
