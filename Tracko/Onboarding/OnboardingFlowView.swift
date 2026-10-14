import SwiftUI

/// The onboarding: four pages, laid out like the reference (design/references/005 and 006).
/// The logo, page dots and button hold still while the hero and words swipe between pages.
struct OnboardingFlowView: View {
    var onFinish: () -> Void

    @State private var page = OnboardingPage.launchPage
    @State private var hasEntered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            // Spacing follows the reference (design/references/006): the button's foot sits about
            // 8% of the usable height above the home indicator. Smaller screens tighten.
            let isCompact = proxy.size.height < 700
            VStack(spacing: 0) {
                LogoMark(isCompact: isCompact)
                    .padding(.top, isCompact ? Space.s : 40)
                    .entrance(0)

                TabView(selection: $page) {
                    ForEach(OnboardingPage.allCases) { item in
                        OnboardingPageView(page: item, isActive: item == page)
                            .tag(item)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, isCompact ? Space.m : 44)

                PageDots(count: OnboardingPage.allCases.count, current: page.rawValue) { index in
                    if let target = OnboardingPage(rawValue: index) { move(to: target) }
                }
                .padding(.top, Space.l)
                .entrance(3)

                Button(action: advance) {
                    AdvanceLabel(title: page.isLast ? "Start tracking" : "Continue")
                }
                .buttonStyle(PrimaryButtonStyle(hasTrailingIcon: true))
                .animation(Motion.snappy, value: page.isLast)
                .padding(.top, isCompact ? Space.l : Space.xxl)
                .padding(.bottom, isCompact ? Space.l : 60)
                .entrance(4)
            }
            .frame(maxWidth: .infinity)
        }
        .environment(\.hasEntered, hasEntered)
        .background { GlowBackground() }
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
