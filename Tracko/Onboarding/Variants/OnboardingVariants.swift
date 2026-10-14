#if DEBUG
import SwiftUI

// Variant harness (the `variant` skill). Debug builds only: production never refers to anything
// in this folder except through `VariantHost`, which TrackoApp uses in Debug in place of
// OnboardingFlowView. Promote one variant, then delete this folder.
//
// All three keep the shipped centred layout (logo, hero, two-line headline, dots, pill). One axis
// varies, emphasis: where the light, and the brand green with it, goes.
// - Stage: the glow falls from the top of the screen (the shipped look, after 005/006).
// - Window: the light is held inside a lit case around the logo and the hero; the page is dark.
// - Spotlight: a soft beam falls on the platform and pools around the figures; the page is dark.
//   The figures also blink and smile now and then (subtle idle expressions, as asked).
// Copy, characters, type and layout stay the same, so the light is what you compare.

enum OnboardingVariant: String, CaseIterable, Identifiable {
    case stage, window, spotlight

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    /// `-TrackoVariant <name>` opens on a variant (CI uses it); the picker remembers the last one.
    static var launch: OnboardingVariant {
        UserDefaults.standard.string(forKey: "TrackoVariant").flatMap(OnboardingVariant.init(rawValue:)) ?? .stage
    }
}

struct VariantHost: View {
    var onFinish: () -> Void

    @State private var variant = OnboardingVariant.launch

    var body: some View {
        GeometryReader { proxy in
            // The picker sits in the home-indicator strip, clear of every variant's button; on a
            // phone without one it sits in the status bar strip instead.
            let atBottom = proxy.safeAreaInsets.bottom > 0
            onboarding
                .overlay(alignment: atBottom ? .bottom : .top) {
                    VariantPicker(selection: $variant)
                        .offset(y: atBottom ? proxy.safeAreaInsets.bottom - 2 : -proxy.safeAreaInsets.top)
                }
        }
    }

    @ViewBuilder
    private var onboarding: some View {
        switch variant {
        case .stage: OnboardingFlowView(onFinish: onFinish).id(variant)
        case .window: CenteredVariantView(light: .window, onFinish: onFinish).id(variant)
        case .spotlight: CenteredVariantView(light: .spotlight, onFinish: onFinish).id(variant)
        }
    }
}

/// The picker (variant/picker.md): deliberately outside the design system, so it never becomes
/// part of what's being judged. Dark neutral, system font, instant switching.
struct VariantPicker: View {
    @Binding var selection: OnboardingVariant

    var body: some View {
        HStack(spacing: 2) {
            ForEach(OnboardingVariant.allCases) { variant in
                let isCurrent = variant == selection
                Button {
                    selection = variant
                    UserDefaults.standard.set(variant.rawValue, forKey: "TrackoVariant")
                } label: {
                    Text(variant.name)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(isCurrent ? 1 : 0.6))
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
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
        .accessibilityLabel("Variants")
    }
}
#endif
