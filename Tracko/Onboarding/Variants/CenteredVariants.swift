#if DEBUG
import SwiftUI

/// The Window and Spotlight variants: the shipped centred layout with the light placed
/// differently. Spacing matches OnboardingFlowView, so only the light changes. Harness only (see
/// OnboardingVariants.swift).
struct CenteredVariantView: View {
    enum Light {
        /// Held inside a lit case around the logo and the hero.
        case window
        /// A soft beam onto the platform, pooling around the figures, which blink and smile.
        case spotlight
    }

    let light: Light
    var onFinish: () -> Void

    @State private var page = OnboardingPage.launchPage
    @State private var hasEntered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height < 700
            let logoTop: CGFloat = isCompact ? Space.s : 40
            let logoHeight: CGFloat = isCompact ? 48 : 64
            let pagesTop: CGFloat = isCompact ? Space.m : 44
            VStack(spacing: 0) {
                if light == .spotlight {
                    LogoMark(isCompact: isCompact)
                        .padding(.top, logoTop)
                        .entrance(0)
                }

                TabView(selection: $page) {
                    ForEach(OnboardingPage.allCases) { item in
                        CenteredVariantPage(page: item, isActive: item == page, light: light, isCompact: isCompact)
                            .tag(item)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, light == .spotlight ? pagesTop : 0)

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
                ZStack(alignment: .topLeading) {
                    Theme.bgPage
                        .ignoresSafeArea()
                    if light == .spotlight {
                        SpotlightLight(
                            width: proxy.size.width,
                            heroTop: logoTop + logoHeight + pagesTop,
                            heroHeight: proxy.size.width / HeroRender.aspectRatio,
                            topInset: proxy.safeAreaInsets.top
                        )
                    }
                    Image("grain")
                        .resizable(resizingMode: .tile)
                        .ignoresSafeArea()
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
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

private struct CenteredVariantPage: View {
    let page: OnboardingPage
    let isActive: Bool
    let light: CenteredVariantView.Light
    let isCompact: Bool

    private let demo = DemoContent()

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
        VStack(spacing: 0) {
            hero
                .layoutPriority(1)
                .entrance(1)
            VStack(spacing: 10) {
                if page == .welcome {
                    WelcomeTitle()
                } else {
                    PageHeadline(page.headline)
                }
                PageSubline(page.subline(demo))
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, Space.gutter)
            .padding(.top, light == .window ? Space.xl : Space.l)
            .entrance(2)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var hero: some View {
        switch light {
        case .spotlight:
            OnboardingHero(page: page, isActive: isActive, isLively: true)
                .frame(minHeight: 150, idealHeight: 150)
        case .window:
            displayCase
                .padding(.horizontal, 12)
                .padding(.top, Space.s)
        }
    }

    /// The lit case: the brand glow fills it from the top and fades out by the platform, a 1 pt
    /// ring of white at 8% marks its edge (dark-mode depth, never a tinted border), and the logo
    /// sits at its head, like the brand on a figure's box.
    private var displayCase: some View {
        let shape = RoundedRectangle(cornerRadius: caseRadius, style: .continuous)
        return VStack(spacing: 0) {
            LogoMark(isCompact: isCompact)
                .padding(.top, isCompact ? 14 : 22)
            OnboardingHero(page: page, isActive: isActive)
                .frame(minHeight: 140, idealHeight: 140)
                .padding(.top, isCompact ? Space.s : Space.m)
        }
        .frame(maxWidth: .infinity)
        .background {
            Theme.glow(fadesOutAt: 0.9)
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }
}

/// A soft spotlight: a beam from above the screen, as wide as the platform at the floor, and a
/// pool of light around the figures. Placed from the layout's known hero position.
private struct SpotlightLight: View {
    let width: CGFloat
    let heroTop: CGFloat
    let heroHeight: CGFloat
    let topInset: CGFloat

    /// The brand glow colour (Palette.green600). Harness only: promotion adds a Theme role.
    private let beam = Color(Palette.green600)

    var body: some View {
        // In the render, the platform's top sits at about 86% of the hero's height and the
        // figures' middle at about 58%.
        let floor = heroTop + heroHeight * 0.86
        let figures = heroTop + heroHeight * 0.58
        ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: CGPoint(x: width * 0.40, y: -topInset))
                path.addLine(to: CGPoint(x: width * 0.60, y: -topInset))
                path.addLine(to: CGPoint(x: width * 0.94, y: floor))
                path.addLine(to: CGPoint(x: width * 0.06, y: floor))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [beam.opacity(0.08), beam.opacity(0.4)], startPoint: .top, endPoint: .bottom))
            .blur(radius: 26)

            Rectangle()
                .fill(
                    EllipticalGradient(
                        stops: [
                            .init(color: beam.opacity(0.6), location: 0),
                            .init(color: beam.opacity(0.32), location: 0.35),
                            .init(color: beam.opacity(0.1), location: 0.7),
                            .init(color: beam.opacity(0), location: 1),
                        ],
                        center: .center,
                        startRadiusFraction: 0,
                        endRadiusFraction: 0.5
                    )
                )
                .frame(width: width * 1.15, height: heroHeight * 0.95)
                .position(x: width / 2, y: figures)
        }
        .frame(width: width, alignment: .topLeading)
    }
}

#Preview("Window") {
    CenteredVariantView(light: .window) {}
        .onAppear { Fonts.register() }
}

#Preview("Spotlight") {
    CenteredVariantView(light: .spotlight) {}
        .onAppear { Fonts.register() }
}
#endif
