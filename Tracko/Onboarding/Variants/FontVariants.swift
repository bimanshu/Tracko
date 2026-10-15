#if DEBUG
import SwiftUI

// Variant harness (the `variant` skill): the typeface. Debug builds only: TrackoApp shows
// `FontVariantHost` in Debug in place of OnboardingFlowView, and production never refers to
// anything in this folder. Promote one (set `TypeScale.Family.default`), then delete this folder.
//
// Round 3, around Outfit (the owner's lean in round 2): round geometric faces with a taller
// x-height, so text reads larger at the same size. One axis, x-height, with the scale held
// still (sizes, weights, line heights, tracking), so the face is what you compare. Lowercase
// height as a share of the font size, and the round letters:
// - Outfit, 0.475: the reference. Perfect circles, poster-like in bold, tight spacing.
// - Lexend, 0.525: wide and evenly spaced, drawn for reading ease. No tabular figures.
// - Sora, 0.534: geometric with squared-off details; a little wide and crisp.
// - Jakarta (Plus Jakarta Sans), 0.536: tall caps, elegant and tightly spaced.
// - Poppins, 0.548: the tallest; round like Outfit, with fuller bold. No tabular figures.
// Round 2 (Satoshi, Figtree, Rubik, Bricolage) is in git history (2b8bb0a).
// Switching redraws the screen in place (TypeScale.family is observable), so you stay on the page.

private let candidates: [TypeScale.Family] = [.outfit, .lexend, .sora, .jakarta, .poppins]

private extension TypeScale.Family {
    /// `-TrackoFont <name>` opens in a typeface (CI uses it); the picker remembers the last one.
    static var launch: TypeScale.Family {
        let saved = UserDefaults.standard.string(forKey: "TrackoFont").flatMap(TypeScale.Family.init(rawValue:))
        // A pick from an earlier round falls back to the reference.
        return saved.flatMap { candidates.contains($0) ? $0 : nil } ?? .outfit
    }
}

struct FontVariantHost: View {
    var onFinish: () -> Void

    /// Sets the launch typeface. TrackoApp calls this once, before anything draws.
    static func prepare() {
        TypeScale.family = .launch
    }

    var body: some View {
        GeometryReader { proxy in
            // The picker sits in the home-indicator strip, clear of the button; on a phone without
            // one it sits in the status bar strip instead.
            let atBottom = proxy.safeAreaInsets.bottom > 0
            OnboardingFlowView(onFinish: onFinish)
                .overlay(alignment: atBottom ? .bottom : .top) {
                    FontPicker()
                        .offset(y: atBottom ? proxy.safeAreaInsets.bottom - 2 : -proxy.safeAreaInsets.top)
                }
        }
    }
}

/// The picker (variant/picker.md): deliberately outside the design system, so it never becomes
/// part of what's being judged. Dark neutral, system font, instant switching.
private struct FontPicker: View {
    var body: some View {
        HStack(spacing: 2) {
            ForEach(candidates) { family in
                let isCurrent = family == TypeScale.family
                Button {
                    TypeScale.family = family
                    UserDefaults.standard.set(family.rawValue, forKey: "TrackoFont")
                } label: {
                    Text(family.name)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(isCurrent ? 1 : 0.6))
                        .padding(.vertical, 7)
                        .padding(.horizontal, 9)
                        .background(Capsule().fill(Color.white.opacity(isCurrent ? 0.14 : 0)))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isCurrent ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule().fill(Color(white: 0.08).opacity(0.9)))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 12, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Typefaces")
    }
}
#endif
