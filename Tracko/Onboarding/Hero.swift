import SwiftUI

/// Where the giant phone's screen sits in a hero render: fractions of the image, top-left
/// origin, and the corner radius as a fraction of the image width. Written by the render
/// pipeline into `HeroRender`.
struct PhoneScreenRect {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let corner: CGFloat
}

/// One onboarding hero: the rendered diorama (characters/build), an optional second render with
/// the payoff expression, and a live screen drawn over the giant phone, so its numbers come from
/// `LiftMath` and follow the user's units.
struct HeroStage<Screen: View>: View {
    let image: String
    var payoffImage: String?
    var showsPayoff = false
    var screenRect: PhoneScreenRect?
    @ViewBuilder var screen: () -> Screen

    var body: some View {
        Color.clear
            .aspectRatio(HeroRender.aspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    ZStack(alignment: .topLeading) {
                        Image(image)
                            .resizable()
                        if let payoffImage {
                            // Expressions swap like a cut; the short fade only hides the seam.
                            Image(payoffImage)
                                .resizable()
                                .opacity(showsPayoff ? 1 : 0)
                                .animation(Motion.faceSwap, value: showsPayoff)
                        }
                        if let screenRect {
                            PhoneScreenLayer(rect: screenRect, size: proxy.size, content: screen())
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
    }
}

extension HeroStage where Screen == EmptyView {
    init(image: String) {
        self.init(image: image, screen: { EmptyView() })
    }
}

/// Lays the screen out at a fixed design width, then scales it onto the render, so it looks the
/// same on every phone.
private struct PhoneScreenLayer<Content: View>: View {
    let rect: PhoneScreenRect
    let size: CGSize
    let content: Content

    static var designWidth: CGFloat { 150 }

    var body: some View {
        let width = rect.width * size.width
        let height = rect.height * size.height
        let scale = width / Self.designWidth
        content
            .frame(width: Self.designWidth, height: height / scale)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: width, height: height, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: rect.corner * size.width, style: .continuous))
            .offset(x: rect.x * size.width, y: rect.y * size.height)
    }
}

/// The giant phone's screen: Tracko's dark UI with a soft brand glow at the top (as the
/// reference's phone shows its own app), and the Dynamic Island. Laid out 150 pt wide.
struct PhoneScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            Theme.canvas
            Theme.glow(fadesOutAt: 0.42)
                .opacity(0.9)
            content()
                .padding(.horizontal, 12)
                .padding(.top, 32)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Capsule()
                .fill(.black)
                .frame(width: 42, height: 12)
                .padding(.top, 7)
        }
    }
}

/// Restarts a phone screen's script when its page becomes active or is tapped.
struct ScriptRun: Hashable {
    let isActive: Bool
    let replay: Int
}
