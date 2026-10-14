import SwiftUI

// MARK: - Page chrome

/// The near-black canvas with the brand glow falling from the top. The glow fades up once, when
/// the screen first appears.
struct GlowBackground: View {
    @State private var isLit = false

    var body: some View {
        ZStack {
            Theme.canvas
            Theme.glow()
                .opacity(isLit ? 1 : 0)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .onAppear {
            // An opacity fade only, so it suits Reduce Motion as well.
            withAnimation(.easeOut(duration: 1.2)) { isLit = true }
        }
    }
}

/// Tracko's mark: a T in an outlined capsule, sized like the reference's (43 × 64 pt).
/// A placeholder until the brand mark is designed.
struct LogoMark: View {
    var isCompact = false

    var body: some View {
        let height: CGFloat = isCompact ? 48 : 64
        Capsule()
            .strokeBorder(Theme.textPrimary, lineWidth: isCompact ? 3 : 3.5)
            .frame(width: height * 0.67, height: height)
            .overlay {
                Text("T")
                    .font(TypeScale.illustration(.extraBold, height * 0.44))
                    .foregroundStyle(Theme.textPrimary)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Buttons

/// The one filled action on a screen: a light pill, like the reference's Start button.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypeScale.button)
            .foregroundStyle(Theme.canvas)
            .padding(.horizontal, Space.xl)
            .frame(minHeight: 48)
            .background(Theme.textPrimary, in: Capsule())
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypeScale.button)
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, Space.xl)
            .frame(minHeight: 48)
            .background(Theme.surfaceRaised, in: Capsule())
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

/// A button label with a trailing arrow, for moving forward. The arrow is decoration: the
/// accessible name is the title alone.
struct AdvanceLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: Space.s) {
            Text(title)
                .contentTransition(.opacity)
            Image(systemName: "arrow.right")
                .fontWeight(.semibold)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Paging

/// Page dots. The current page is a longer pill, so it doesn't rely on brightness alone.
/// VoiceOver reads "Page, 2 of 4" and can swipe up or down to change page.
struct PageDots: View {
    let count: Int
    let current: Int
    let select: (Int) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Theme.textPrimary : Theme.indicator)
                    .frame(width: index == current ? 18 : 7, height: 7)
            }
        }
        .animation(Motion.snappy, value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue("\(current + 1) of \(count)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment where current < count - 1: select(current + 1)
            case .decrement where current > 0: select(current - 1)
            default: break
            }
        }
    }
}

// MARK: - Words

/// A page headline: Geist Bold, centred, slightly tightened, scaled with Dynamic Type.
struct PageHeadline: View {
    let text: String
    @ScaledMetric(relativeTo: .largeTitle) private var tracking = 34 * TypeScale.headlineTracking

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(TypeScale.headline)
            .tracking(tracking)
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

/// The line under a headline.
struct PageSubline: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(TypeScale.body)
            .lineSpacing(3)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Components") {
    VStack(spacing: Space.xl) {
        LogoMark()
        PageHeadline("Always know the number to beat")
        PageSubline("Every lift opens with what beats last time.")
        PageDots(count: 4, current: 1) { _ in }
        Button {} label: { AdvanceLabel(title: "Continue") }
            .buttonStyle(PrimaryButtonStyle())
        Button("Replay onboarding") {}
            .buttonStyle(SecondaryButtonStyle())
    }
    .padding(Space.gutter)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background { GlowBackground() }
    .onAppear { Fonts.register() }
}
