#if DEBUG
import SwiftUI

/// Variant "Window" (structure: the hero contained). The diorama sits in its own lit case near
/// the top, like a vinyl figure in its box, with the wordmark inside the case; the headline and
/// subline sit below, left-aligned on the case's inner edge; page dots and the button share one
/// row at the foot. Harness only (see OnboardingVariants.swift).
struct WindowOnboardingView: View {
    var onFinish: () -> Void

    @State private var page = OnboardingPage.launchPage
    @State private var hasEntered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height < 700
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(OnboardingPage.allCases) { item in
                        WindowPage(page: item, isActive: item == page, isCompact: isCompact)
                            .tag(item)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: Space.l) {
                    PageDots(count: OnboardingPage.allCases.count, current: page.rawValue) { index in
                        if let target = OnboardingPage(rawValue: index) { move(to: target) }
                    }
                    Spacer(minLength: 0)
                    Button(action: advance) {
                        AdvanceLabel(title: page.buttonTitle)
                    }
                    .buttonStyle(PrimaryButtonStyle(hasTrailingIcon: true))
                    .animation(Motion.snappy, value: page.isLast)
                }
                .padding(.horizontal, WindowPage.textInset)
                .padding(.top, Space.l)
                .padding(.bottom, isCompact ? Space.l : 40)
                .entrance(3)
            }
        }
        .environment(\.hasEntered, hasEntered)
        .background {
            ZStack {
                Theme.bgPage
                Image("grain")
                    .resizable(resizingMode: .tile)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
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
        VariantFlowState.move($page, to: target, reduceMotion: reduceMotion)
    }
}

private struct WindowPage: View {
    let page: OnboardingPage
    let isActive: Bool
    let isCompact: Bool

    private let demo = DemoContent()

    /// The case sits 12 pt in from the screen edges.
    static let caseInset: CGFloat = 12
    /// Text lines up with the wordmark inside the case: 12 pt case inset + 20 pt inner padding.
    static let textInset: CGFloat = 32

    private static let headline = BalancedText.Style(
        weight: .bold, boldWeight: .extraBold, size: 30, textStyle: .largeTitle, lineHeight: 1.1, tracking: -0.02
    )

    /// Concentric with the screen's own corners (about 55 pt on Face ID iPhones) at a 12 pt
    /// inset; square-cornered screens get a smaller radius.
    private var caseRadius: CGFloat { isCompact ? 24 : 43 }

    var body: some View {
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
        VStack(alignment: .leading, spacing: 0) {
            displayCase
                .padding(.horizontal, Self.caseInset)
                .padding(.top, Space.s)
                .layoutPriority(1)
                .entrance(0)

            VStack(alignment: .leading, spacing: 10) {
                PageHeadline(page.headline, style: Self.headline, alignment: .natural)
                PageSubline(page.subline(demo), alignment: .natural)
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(.horizontal, Self.textInset)
            .padding(.top, Space.xl)
            .entrance(1)

            Spacer(minLength: 0)
        }
    }

    /// The lit case: the brand glow fills it from the top, a hairline ring of light marks its
    /// edge, and the wordmark sits in its top-leading corner.
    private var displayCase: some View {
        let shape = RoundedRectangle(cornerRadius: caseRadius, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            SmallWordmark()
                .padding(.leading, Self.textInset - Self.caseInset)
                .padding(.top, 18)
            OnboardingHero(page: page, isActive: isActive)
                .frame(minHeight: 140, idealHeight: 140)
                .padding(.top, Space.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Theme.glow(fadesOutAt: 1)
                .accessibilityHidden(true)
        }
        .clipShape(shape)
        // Dark-mode depth: a 1 px ring of white at 8%, never a tinted border.
        .overlay(shape.strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }
}

#Preview {
    WindowOnboardingView {}
        .onAppear { Fonts.register() }
}
#endif
