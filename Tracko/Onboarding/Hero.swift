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

/// One onboarding hero: the rendered diorama (characters/build), shown in one of its faces, and a
/// live screen drawn over the giant phone, so its numbers come from `LiftMath` and follow the
/// user's units. Every face is stacked and only `face` shows, so a swap is a cut, never a reload.
struct HeroStage<Screen: View>: View {
    /// Every face this hero can show (renders of the same shot with different expressions).
    let frames: [String]
    /// The face showing now: one of `frames`.
    let face: String
    var screenRect: PhoneScreenRect?
    @ViewBuilder var screen: () -> Screen

    var body: some View {
        Color.clear
            .aspectRatio(HeroRender.aspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    ZStack(alignment: .topLeading) {
                        ForEach(frames, id: \.self) { frame in
                            Image(frame)
                                .resizable()
                                .opacity(frame == face ? 1 : 0)
                        }
                        // Expressions swap like a cut; the 50 ms fade only hides the seam.
                        .animation(Motion.faceSwap, value: face)
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
    init(frames: [String], face: String) {
        self.init(frames: frames, face: face, screen: { EmptyView() })
    }
}

/// Lays the screen out at a fixed design width, then scales it onto the render, so it looks the
/// same on every phone. The design width is close to the drawn width (about 120 pt on a 6.3"
/// phone), so text renders near its design size instead of shrinking to unreadable.
private struct PhoneScreenLayer<Content: View>: View {
    let rect: PhoneScreenRect
    let size: CGSize
    let content: Content

    static var designWidth: CGFloat { 140 }

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
/// reference's phone shows its own app), and the Dynamic Island. Laid out 140 pt wide.
struct PhoneScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bgPage
            // Labels near the top sit on this glow; they use textSecondary, which keeps APCA Lc 60+.
            Theme.glow(fadesOutAt: 0.42)
                .opacity(0.7)
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
