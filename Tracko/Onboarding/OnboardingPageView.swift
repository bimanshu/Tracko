import SwiftUI

/// One onboarding page, laid out like the reference (design/references/006): the hero full
/// width, then a two-line headline and a short subline. The logo, page dots and button stay put
/// around it while pages swipe.
struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    /// Told where the hero sits on screen, so the spotlight can follow it.
    var onHeroSpot: (HeroSpot) -> Void = { _ in }

    private let demo = DemoContent()

    var body: some View {
        // At the largest text sizes the words need the room: the page scrolls instead, and
        // flashes its scroll indicator so the text below the edge doesn't look cut off.
        ViewThatFits(in: .vertical) {
            content
            ScrollView {
                content
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicatorsFlash(onAppear: true)
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            OnboardingHero(page: page, isActive: isActive)
                .frame(minHeight: 150, idealHeight: 150)
                .layoutPriority(1)
                .entrance(1)
                // Measured outside the entrance, so the light doesn't follow its 12 pt rise.
                .reportsHeroSpot(onHeroSpot)
            words
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.l)
                .entrance(2)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var words: some View {
        VStack(spacing: 10) {
            if page == .welcome {
                WelcomeTitle()
            } else {
                PageHeadline(page.headline)
            }
            PageSubline(page.subline(demo))
        }
        .frame(maxWidth: 520)
    }
}

/// "Welcome to" over the Tracko wordmark, read as one heading.
struct WelcomeTitle: View {
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
        .background(Theme.bgPage)
        .onAppear { Fonts.register() }
}
