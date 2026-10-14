import SwiftUI

/// One onboarding page, laid out like the reference (design/references/006): the hero full
/// width, then a two-line headline and a short subline. The logo, page dots and button stay put
/// around it while pages swipe.
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    private let demo = DemoContent()
    @State private var answered = false
    @State private var replay = 0

    var body: some View {
        // At the largest text sizes the words need the room: the page scrolls instead.
        ViewThatFits(in: .vertical) {
            content
            ScrollView {
                content
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .sensoryFeedback(.success, trigger: answered) { _, new in new }
    }

    private var content: some View {
        VStack(spacing: 0) {
            hero
                .frame(minHeight: 150, idealHeight: 150)
                .layoutPriority(1)
                .contentShape(Rectangle())
                .onTapGesture { replay += 1 }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(heroDescription)
                .accessibilityAddTraits(.isImage)
                .accessibilityAction(named: "Replay animation") { replay += 1 }
                .entrance(1)
            words
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.l)
                .entrance(2)
            Spacer(minLength: 0)
        }
    }

    // MARK: Hero

    private var run: ScriptRun { ScriptRun(isActive: isActive, replay: replay) }

    @ViewBuilder
    private var hero: some View {
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

    private var heroDescription: String {
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

    // MARK: Words

    @ViewBuilder
    private var words: some View {
        VStack(spacing: 10) {
            switch page {
            case .welcome:
                WelcomeTitle()
                PageSubline("The gym log that talks back.")
            case .log:
                PageHeadline("Log it like a note")
                PageSubline("Type \(demo.noteLine(demo.thursday).keptTogether) and Tracko does the maths.")
            case .beat:
                PageHeadline("Always know the number to beat")
                PageSubline("Each lift shows what beats last time.")
            case .grow:
                PageHeadline("Watch yourself get stronger")
                PageSubline("Proof you’re growing, week by week.")
            }
        }
        .frame(maxWidth: 520)
    }
}

/// "Welcome to" over the Tracko wordmark, read as one heading.
private struct WelcomeTitle: View {
    @ScaledMetric(relativeTo: .largeTitle) private var tracking = 52 * TypeScale.wordmarkTracking
    @Environment(\.legibilityWeight) private var legibilityWeight

    var body: some View {
        VStack(spacing: 0) {
            Text("Welcome to")
                .font(TypeScale.intro(legibilityWeight))
                .foregroundStyle(Theme.textPrimary)
            Text("Tracko")
                .font(TypeScale.wordmark)
                .tracking(tracking)
                .foregroundStyle(Theme.textPrimary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#Preview("Log page") {
    OnboardingPageView(page: .log, isActive: true)
        .background { GlowBackground() }
        .onAppear { Fonts.register() }
}
