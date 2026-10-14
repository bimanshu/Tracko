import SwiftUI

/// The onboarding: four pages, laid out like the reference (design/references/005 and 006).
/// The logo, page dots and button hold still while the hero and words swipe between pages.
struct OnboardingFlowView: View {
    var onFinish: () -> Void

    @State private var page = OnboardingPage.launchPage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            // Spacing follows the reference on a 6.1" phone and tightens on smaller screens.
            let isCompact = proxy.size.height < 700
            VStack(spacing: 0) {
                LogoMark(isCompact: isCompact)
                    .padding(.top, isCompact ? Space.s : 40)

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

                Button(action: advance) {
                    AdvanceLabel(title: page.isLast ? "Start tracking" : "Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .animation(Motion.snappy, value: page.isLast)
                .padding(.top, isCompact ? Space.l : Space.xxl)
                .padding(.bottom, isCompact ? Space.m : 48)
            }
            .frame(maxWidth: .infinity)
        }
        .background { GlowBackground() }
        .sensoryFeedback(.selection, trigger: page)
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
