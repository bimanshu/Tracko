import SwiftUI

/// A page's hero: the rendered diorama with its live phone screen, the face swap and haptic when
/// the moment lands, tap (or the VoiceOver action) to replay, and a description for VoiceOver.
///
/// `isLively` adds subtle idle expressions: the characters blink every few seconds, and a laugh
/// eases into a calm smile. They play only on the active page and never with Reduce Motion
/// (looping decoration is the first thing it turns off).
struct OnboardingHero: View {
    let page: OnboardingPage
    let isActive: Bool
    var isLively = false

    private let demo = DemoContent()
    @State private var answered = false
    @State private var replay = 0
    @State private var mood = Mood.laugh
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The idle faces: a laugh (the ^ ^ render), a calm open-eyed smile, and a blink.
    enum Mood {
        case laugh, smile, blink
    }

    private struct IdleRun: Hashable {
        let isPlaying: Bool
        let replay: Int
        let answered: Bool
    }

    var body: some View {
        stage
            .contentShape(Rectangle())
            .onTapGesture { replay += 1 }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(description)
            .accessibilityAddTraits(.isImage)
            .accessibilityAction(named: "Replay animation") { replay += 1 }
            .sensoryFeedback(.success, trigger: answered) { _, new in new }
            .task(id: IdleRun(isPlaying: isPlaying, replay: replay, answered: answered)) { await idle() }
    }

    private var isPlaying: Bool { isLively && isActive && !reduceMotion }
    private var run: ScriptRun { ScriptRun(isActive: isActive, replay: replay) }

    // MARK: Faces

    /// The renders for a smiling face: "hero-grow", "hero-grow-open", "hero-grow-blink".
    private func moodFrames(_ laugh: String) -> [String] {
        [laugh, laugh + "-open", laugh + "-blink"]
    }

    private func moodFace(_ laugh: String) -> String {
        switch mood {
        case .laugh: return laugh
        case .smile: return laugh + "-open"
        case .blink: return laugh + "-blink"
        }
    }

    private var isLivelyNow: Bool { isLively && !reduceMotion }

    /// Every face the hero may show.
    private var frames: [String] {
        switch page {
        case .welcome:
            return isLivelyNow ? moodFrames("hero-welcome") : ["hero-welcome"]
        case .grow:
            return isLivelyNow ? moodFrames("hero-grow") : ["hero-grow"]
        case .log:
            return isLivelyNow ? ["hero-log-a", "hero-log-a-blink"] + moodFrames("hero-log-b") : ["hero-log-a", "hero-log-b"]
        case .beat:
            return isLivelyNow ? ["hero-beat-a"] + moodFrames("hero-beat-b") : ["hero-beat-a", "hero-beat-b"]
        }
    }

    /// The face showing now.
    private var face: String {
        switch page {
        case .welcome:
            return isLivelyNow ? moodFace("hero-welcome") : "hero-welcome"
        case .grow:
            return isLivelyNow ? moodFace("hero-grow") : "hero-grow"
        case .log:
            if answered { return isLivelyNow ? moodFace("hero-log-b") : "hero-log-b" }
            return isLivelyNow && mood == .blink ? "hero-log-a-blink" : "hero-log-a"
        case .beat:
            // Before the payoff he's straining (eyes squeezed), so there's nothing to blink.
            if answered { return isLivelyNow ? moodFace("hero-beat-b") : "hero-beat-b" }
            return "hero-beat-a"
        }
    }

    @ViewBuilder
    private var stage: some View {
        switch page {
        case .welcome:
            HeroStage(frames: frames, face: face)
        case .log:
            HeroStage(frames: frames, face: face, screenRect: HeroRender.logScreen) {
                LogPhoneScreen(demo: demo, run: run, answered: $answered)
            }
        case .beat:
            HeroStage(frames: frames, face: face, screenRect: HeroRender.beatScreen) {
                BeatPhoneScreen(demo: demo, run: run, answered: $answered)
            }
        case .grow:
            HeroStage(frames: frames, face: face, screenRect: HeroRender.growScreen) {
                GrowPhoneScreen(demo: demo, run: run, answered: $answered)
            }
        }
    }

    // MARK: Idle expressions

    /// Laughs when the page opens (welcome, growth) or when the payoff lands, then settles into a
    /// smile and blinks every few seconds, now and then twice. The welcome and growth pages laugh
    /// again now and then.
    @MainActor
    private func idle() async {
        let laughsFirst = page == .welcome || page == .grow || answered
        Script.reset { mood = laughsFirst ? .laugh : .smile }
        guard isPlaying else { return }
        if laughsFirst {
            guard await Script.wait(answered ? 1.6 : 1.2) else { return }
            mood = .smile
        }
        var beats = 0
        while true {
            guard await Script.wait(Double.random(in: 2.6...5.2)) else { return }
            beats += 1
            if page == .welcome || page == .grow, beats % 3 == 0 {
                mood = .laugh
                guard await Script.wait(0.9) else { return }
                mood = .smile
                continue
            }
            guard await blink() else { return }
            if beats % 2 == 1, Bool.random() {
                guard await Script.wait(0.18), await blink() else { return }
            }
        }
    }

    @MainActor
    private func blink() async -> Bool {
        mood = .blink
        guard await Script.wait(0.13) else { return false }
        mood = .smile
        return true
    }

    // MARK: VoiceOver

    private var description: String {
        switch page {
        case .welcome:
            return "The two Tracko characters wave hello from a stand with a kettlebell and a weight plate."
        case .log:
            let verdict = demo.thursdayVerdict
            return "She types \(demo.noteLine(demo.thursday)) on a giant phone, and it answers: \(verdict.sentence)"
        case .beat:
            let need = demo.lastSetNeed
            let tie = need.tie.map { "\($0) reps ties Thursday and " } ?? ""
            return "He does lateral raises beside a giant phone that says \(tie)\(need.beat) beats it. "
                + "His last set beats it: \(demo.todayVerdict.number)."
        case .grow:
            return "Both characters celebrate beside a giant phone. Its curve shows the lift \(demo.growthPercent) percent "
                + "stronger after \(demo.growthWeeks) weeks."
        }
    }
}
