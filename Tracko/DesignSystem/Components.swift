import SwiftUI
import UIKit

// MARK: - Page chrome

/// The near-black page with the brand glow falling from the top, and a faint grain over both so
/// the long, dark gradient never bands on screen. The glow fades up once, when the screen first
/// appears (an opacity fade, so it suits Reduce Motion too).
struct GlowBackground: View {
    @State private var isLit = false

    var body: some View {
        ZStack {
            Theme.bgPage
            Theme.glow()
                .opacity(isLit ? 1 : 0)
            Image("grain")
                .resizable(resizingMode: .tile)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
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
    /// A trailing icon sits optically further out, so that side gets 2 pt less padding.
    var hasTrailingIcon = false
    @Environment(\.legibilityWeight) private var legibilityWeight

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypeScale.button(legibilityWeight))
            .foregroundStyle(Theme.textInverse)
            .padding(.leading, Space.xl)
            .padding(.trailing, hasTrailingIcon ? Space.xl - 2 : Space.xl)
            .frame(minHeight: 48)
            .background(Theme.bgInverse, in: Capsule())
            .contentShape(Capsule())
            .pressScale(configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.legibilityWeight) private var legibilityWeight

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypeScale.button(legibilityWeight))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, Space.xl)
            .frame(minHeight: 48)
            .background(Theme.bgRaised, in: Capsule())
            .contentShape(Capsule())
            .pressScale(configuration.isPressed)
    }
}

private extension View {
    /// Tactile press feedback: 0.96, eased out over 150 ms, interruptible.
    func pressScale(_ isPressed: Bool) -> some View {
        scaleEffect(isPressed ? 0.96 : 1)
            .animation(Motion.press, value: isPressed)
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
                    .fill(index == current ? Theme.textPrimary : Theme.fillSubtle)
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

/// A page headline: Geist Bold at 1.1 line height, balanced over its lines.
struct PageHeadline: View {
    let text: String
    var style = TypeScale.headline
    var alignment: NSTextAlignment = .center

    init(_ text: String, style: BalancedText.Style = TypeScale.headline, alignment: NSTextAlignment = .center) {
        self.text = text
        self.style = style
        self.alignment = alignment
    }

    var body: some View {
        BalancedText(text: text, style: style, alignment: alignment, isHeader: true)
    }
}

/// The line under a headline, balanced so it never ends on one short word.
struct PageSubline: View {
    let text: String
    var alignment: NSTextAlignment = .center

    init(_ text: String, alignment: NSTextAlignment = .center) {
        self.text = text
        self.alignment = alignment
    }

    var body: some View {
        BalancedText(text: text, style: TypeScale.body, color: Theme.textSecondary, alignment: alignment)
    }
}

// MARK: - First-launch entrance

private struct HasEnteredKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// False until the onboarding first appears; parts with `.entrance(_:)` wait for it.
    var hasEntered: Bool {
        get { self[HasEnteredKey.self] }
        set { self[HasEnteredKey.self] = newValue }
    }
}

/// A staged entrance for the first launch: each part rises 12 pt out of a 4 pt blur, 100 ms after
/// the one before, so the screen reads top to bottom. With Reduce Motion it only fades.
private struct Entrance: ViewModifier {
    let step: Int
    @Environment(\.hasEntered) private var hasEntered
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let isMoving = !hasEntered && !reduceMotion
        content
            .opacity(hasEntered ? 1 : 0)
            .offset(y: isMoving ? 12 : 0)
            .blur(radius: isMoving ? 4 : 0)
            .animation(Motion.enter.delay(Double(step) * 0.1), value: hasEntered)
    }
}

extension View {
    func entrance(_ step: Int) -> some View {
        modifier(Entrance(step: step))
    }
}

extension String {
    /// Keeps a short value such as "8 × 12, 11, 10" on one line.
    var keptTogether: String {
        replacingOccurrences(of: " ", with: "\u{00A0}")
    }
}

#Preview("Components") {
    VStack(spacing: Space.xl) {
        LogoMark()
        PageHeadline("Always know the number to beat")
        PageSubline("Each lift shows what beats last time.")
        PageDots(count: 4, current: 1) { _ in }
        Button {} label: { AdvanceLabel(title: "Continue") }
            .buttonStyle(PrimaryButtonStyle(hasTrailingIcon: true))
        Button("Replay onboarding") {}
            .buttonStyle(SecondaryButtonStyle())
    }
    .padding(Space.gutter)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background { GlowBackground() }
    .onAppear { Fonts.register() }
}
