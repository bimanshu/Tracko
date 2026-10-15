import SwiftUI

/// Where the hero sits: what the spotlight aims at.
struct HeroSpot: Equatable {
    var top: CGFloat
    var height: CGFloat
    var width: CGFloat

    init(top: CGFloat, height: CGFloat, width: CGFloat) {
        self.top = top
        self.height = height
        self.width = width
    }

    /// From a frame, in whole points, so sub-point layout jitter never redraws the light.
    init(_ frame: CGRect) {
        self.init(top: frame.minY.rounded(), height: frame.height.rounded(), width: frame.width.rounded())
    }

    func shifted(by distance: CGFloat) -> HeroSpot {
        HeroSpot(top: top + distance, height: height, width: width)
    }
}

extension View {
    /// Reports this view's place on screen (window coordinates) when it appears, and whenever it
    /// moves up or down or resizes. Moving sideways, as in a page swipe, doesn't count.
    func reportsHeroSpot(_ report: @escaping (HeroSpot) -> Void) -> some View {
        background {
            GeometryReader { proxy in
                let spot = HeroSpot(proxy.frame(in: .global))
                Color.clear
                    .onAppear { report(spot) }
                    .onChange(of: spot) { _, new in report(new) }
            }
        }
    }
}

/// The onboarding's light: the near-black page, a soft green beam falling from above the screen
/// onto the hero's platform, a pool of light around the figures, and a faint grain over it all so
/// the long dark gradients never band. The light holds still while pages swipe, like a stage light
/// on a turntable, and comes up once when the screen first appears (an opacity fade, so it suits
/// Reduce Motion too).
struct SpotlightBackground: View {
    /// The hero, in this view's coordinates.
    let spot: HeroSpot
    /// The screen's width: the beam falls from its middle.
    let width: CGFloat
    /// How far the screen reaches above this view. The beam starts beyond the top edge.
    let topInset: CGFloat

    @State private var isLit = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.bgPage
                .ignoresSafeArea()
            light
                .opacity(isLit ? 1 : 0)
            Image("grain")
                .resizable(resizingMode: .tile)
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { isLit = true }
        }
    }

    private var light: some View {
        // In the render, the platform spans about 88% of the hero's width with its top at about
        // 86% of the height, and the figures' middle sits at about 58%.
        let centre = width / 2
        let floor = spot.top + spot.height * 0.86
        let figures = spot.top + spot.height * 0.58
        return ZStack(alignment: .topLeading) {
            // The beam: a fifth of the screen wide above it, as wide as the platform at the floor.
            Path { path in
                path.move(to: CGPoint(x: centre - width * 0.1, y: -topInset))
                path.addLine(to: CGPoint(x: centre + width * 0.1, y: -topInset))
                path.addLine(to: CGPoint(x: centre + spot.width * 0.44, y: floor))
                path.addLine(to: CGPoint(x: centre - spot.width * 0.44, y: floor))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Theme.spotlight.opacity(0.08), Theme.spotlight.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blur(radius: 26)

            // The pool, brightest behind the figures and gone before the headline.
            Rectangle()
                .fill(
                    EllipticalGradient(
                        stops: [
                            .init(color: Theme.spotlight.opacity(0.6), location: 0),
                            .init(color: Theme.spotlight.opacity(0.32), location: 0.35),
                            .init(color: Theme.spotlight.opacity(0.1), location: 0.7),
                            .init(color: Theme.spotlight.opacity(0), location: 1),
                        ],
                        center: .center,
                        startRadiusFraction: 0,
                        endRadiusFraction: 0.5
                    )
                )
                .frame(width: spot.width * 1.15, height: spot.height * 0.95)
                .position(x: centre, y: figures)
        }
        .frame(width: width, alignment: .topLeading)
    }
}
