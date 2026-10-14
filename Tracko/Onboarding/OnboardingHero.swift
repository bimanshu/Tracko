import SwiftUI

/// A page's hero: the rendered diorama with its live phone screen, the face swap and haptic when
/// the moment lands, tap (or the VoiceOver action) to replay, and a description for VoiceOver.
struct OnboardingHero: View {
    let page: OnboardingPage
    let isActive: Bool

    private let demo = DemoContent()
    @State private var answered = false
    @State private var replay = 0

    var body: some View {
        stage
            .contentShape(Rectangle())
            .onTapGesture { replay += 1 }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(description)
            .accessibilityAddTraits(.isImage)
            .accessibilityAction(named: "Replay animation") { replay += 1 }
            .sensoryFeedback(.success, trigger: answered) { _, new in new }
    }

    private var run: ScriptRun { ScriptRun(isActive: isActive, replay: replay) }

    @ViewBuilder
    private var stage: some View {
        switch page {
        case .welcome:
            HeroStage(image: "hero-welcome")
        case .log:
            HeroStage(image: "hero-log-a", payoffImage: "hero-log-b", showsPayoff: answered,
                      screenRect: HeroRender.logScreen) {
                LogPhoneScreen(demo: demo, run: run, answered: $answered)
            }
        case .beat:
            HeroStage(image: "hero-beat-a", payoffImage: "hero-beat-b", showsPayoff: answered,
                      screenRect: HeroRender.beatScreen) {
                BeatPhoneScreen(demo: demo, run: run, answered: $answered)
            }
        case .grow:
            HeroStage(image: "hero-grow", screenRect: HeroRender.growScreen) {
                GrowPhoneScreen(demo: demo, run: run, answered: $answered)
            }
        }
    }

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
