import SwiftUI

/// The onboarding: four pages, laid out like the reference (design/references/005 and 006), lit
/// by a spotlight on the hero. The logo, page dots, button and light hold still while the hero
/// and words swipe between pages.
struct OnboardingFlowView: View {
    var onFinish: () -> Void

    @State private var page = OnboardingPage.launchPage
    @State private var hasEntered = false
    /// Where each page's hero sits on screen, measured, so the light stays on it at every size.
    @State private var heroSpots: [OnboardingPage: HeroSpot] = [:]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            // Spacing follows the reference (design/references/006): the button's foot sits about
            // 8% of the usable height above the home indicator. Smaller screens tighten.
            let isCompact = proxy.size.height < 700
            let logoTop: CGFloat = isCompact ? Space.s : 40
            let pagesTop: CGFloat = isCompact ? Space.m : 44
            VStack(spacing: 0) {
                LogoMark(isCompact: isCompact)
                    .padding(.top, logoTop)
                    .entrance(0)

                TabView(selection: $page) {
                    ForEach(OnboardingPage.allCases) { item in
                        OnboardingPageView(page: item, isActive: item == page) { spot in
                            heroSpots[item] = spot
                        }
                        .tag(item)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, pagesTop)

                PageDots(count: OnboardingPage.allCases.count, current: page.rawValue) { index in
                    if let target = OnboardingPage(rawValue: index) { move(to: target) }
                }
                .padding(.top, Space.l)
                .entrance(3)

                Button(action: advance) {
                    AdvanceLabel(title: page.buttonTitle)
                }
                .buttonStyle(PrimaryButtonStyle(hasTrailingIcon: true))
                .animation(Motion.snappy, value: page.isLast)
                .padding(.top, isCompact ? Space.l : Space.xxl)
                .padding(.bottom, isCompact ? Space.l : 60)
                .entrance(4)
            }
            .frame(maxWidth: .infinity)
            .background(alignment: .topLeading) {
                // Until the hero reports in, aim where the layout puts it at full width.
                let origin = proxy.frame(in: .global).minY
                let spot = heroSpots[page]?.shifted(by: -origin) ?? HeroSpot(
                    top: logoTop + LogoMark.height(isCompact: isCompact) + pagesTop,
                    height: proxy.size.width / HeroRender.aspectRatio,
                    width: proxy.size.width
                )
                SpotlightBackground(spot: spot, width: proxy.size.width, topInset: proxy.safeAreaInsets.top)
            }
        }
        .environment(\.hasEntered, hasEntered)
        .sensoryFeedback(.selection, trigger: page)
        .onAppear { hasEntered = true }
    }

    private func advance() {
        if let next = OnboardingPage(rawValue: page.rawValue + 1) {
            move(to: next)
        } else {
            onFinish()
        }
    }

    private func move(to target: OnboardingPage) {
        withAnimation(reduceMotion ? Motion.fade : .smooth(duration: 0.45)) {
            page = target
        }
    }
}

#Preview {
    OnboardingFlowView {}
        .onAppear { Fonts.register() }
}
