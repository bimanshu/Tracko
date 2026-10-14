#if DEBUG
import SwiftUI

/// Variant "Editorial" (structure: words first). A wordmark and progress segments on top; the
/// headline and subline left-aligned beneath, larger, like the opening of an article; the hero
/// below, bigger than the screen, bleeding off the right edge and lit from behind it; a
/// full-width button. Harness only (see OnboardingVariants.swift).
struct EditorialOnboardingView: View {
    var onFinish: () -> Void

    @State private var page = OnboardingPage.launchPage
    @State private var hasEntered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Space.l) {
                SmallWordmark()
                ProgressSegments(count: OnboardingPage.allCases.count, current: page.rawValue) { index in
                    if let target = OnboardingPage(rawValue: index) { move(to: target) }
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.s)
            .entrance(0)

            TabView(selection: $page) {
                ForEach(OnboardingPage.allCases) { item in
                    EditorialPage(page: item, isActive: item == page)
                        .tag(item)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            Button(action: advance) {
                AdvanceLabel(title: page.buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.l)
            .entrance(3)
        }
        .environment(\.hasEntered, hasEntered)
        .background { EditorialBackground() }
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

private struct EditorialPage: View {
    let page: OnboardingPage
    let isActive: Bool

    private let demo = DemoContent()

    /// Bigger and tighter than the stage headline: here the words lead.
    private static let headline = BalancedText.Style(
        weight: .bold, boldWeight: .extraBold, size: 40, textStyle: .largeTitle, lineHeight: 1.05, tracking: -0.025
    )
    /// How much wider than the screen the hero is drawn, and where it starts.
    private static let heroScale: CGFloat = 1.25
    private static let heroInset: CGFloat = 0.04

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
            VStack(alignment: .leading, spacing: Space.m) {
                PageHeadline(page.headline, style: Self.headline, alignment: .natural)
                PageSubline(page.subline(demo), alignment: .natural)
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(.horizontal, Space.gutter)
            .padding(.top, 28)
            .entrance(1)

            Spacer(minLength: Space.l)

            // The hero, wider than the screen: it starts just inside the leading edge and runs
            // off the trailing one, so the stage reads as a cropped photograph, not a centrepiece.
            Color.clear
                .aspectRatio(HeroRender.aspectRatio / Self.heroScale, contentMode: .fit)
                .frame(minHeight: 160, idealHeight: 160)
                .overlay(alignment: .topLeading) {
                    GeometryReader { proxy in
                        OnboardingHero(page: page, isActive: isActive)
                            .frame(width: proxy.size.width * Self.heroScale,
                                   height: proxy.size.width * Self.heroScale / HeroRender.aspectRatio)
                            .offset(x: proxy.size.width * Self.heroInset)
                    }
                }
                .clipped()
                .layoutPriority(1)
                .entrance(2)
        }
    }
}

/// The page with the glow behind the hero, low and to the trailing side, instead of falling from
/// the top: the stage is the light source and the words sit on plain dark.
private struct EditorialBackground: View {
    var body: some View {
        ZStack {
            Theme.bgPage
            EllipticalGradient(
                stops: (0...10).map { index -> Gradient.Stop in
                    let t = Double(index) / 10
                    return .init(color: Palette.green600.mixed(with: Palette.neutral950, amount: t), location: t)
                },
                // Kept below the words: the glow is spent by the subline, so text stays on dark.
                center: UnitPoint(x: 0.68, y: 0.8),
                startRadiusFraction: 0,
                endRadiusFraction: 0.55
            )
            Image("grain")
                .resizable(resizingMode: .tile)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    EditorialOnboardingView {}
        .onAppear { Fonts.register() }
}
#endif
