#if DEBUG
import SwiftUI

// Variant harness (the `variant` skill), round 2: the typeface. Debug builds only: TrackoApp shows
// `FontVariantHost` in Debug in place of OnboardingFlowView, and production never refers to
// anything in this folder. Promote one (set `TypeScale.Family.default`), then delete this folder.
//
// One axis, type: each candidate is a different voice on the same scale (sizes, weights, line
// heights and tracking stay as they are), so the face is what you compare. All are sans serif,
// and all less technical than Geist:
// - Satoshi: a modern grotesk on geometric bones. Crisp and current, with a fashion edge.
//   Fontshare, ITF Free Font License: fetched by scripts/fetch-fonts.sh, never committed.
// - Figtree: geometric, friendly and plain. The most legible at small sizes.
// - Outfit: pure geometric, perfectly round letters. Light-hearted, poster-like in bold.
// - Rubik: softly rounded corners. The warmest and sportiest.
// - Bricolage (Grotesque): a quirky grotesque with ink traps. The most character.
// Switching redraws the screen in place (TypeScale.family is observable), so you stay on the page.

private let candidates: [TypeScale.Family] = [.satoshi, .figtree, .outfit, .rubik, .bricolage]

private extension TypeScale.Family {
    /// `-TrackoFont <name>` opens in a typeface (CI uses it); the picker remembers the last one.
    static var launch: TypeScale.Family {
        UserDefaults.standard.string(forKey: "TrackoFont").flatMap(TypeScale.Family.init(rawValue:)) ?? .satoshi
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
                    FontPicker(noteAbove: atBottom)
                        .offset(y: atBottom ? proxy.safeAreaInsets.bottom - 2 : -proxy.safeAreaInsets.top)
                }
        }
    }
}

/// The picker (variant/picker.md): deliberately outside the design system, so it never becomes
/// part of what's being judged. Dark neutral, system font, instant switching.
private struct FontPicker: View {
    /// Where the "not installed" note goes: away from the screen edge.
    let noteAbove: Bool

    var body: some View {
        VStack(spacing: 6) {
            if noteAbove { note }
            picker
            if !noteAbove { note }
        }
    }

    @ViewBuilder
    private var note: some View {
        let family = TypeScale.family
        if !Fonts.isAvailable(family) {
            Text("\(family.name) isn't installed: run scripts/fetch-fonts.sh")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color(white: 0.08).opacity(0.9)))
        }
    }

    private var picker: some View {
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
