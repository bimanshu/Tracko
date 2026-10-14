#if DEBUG
import SwiftUI

// Variant harness (the `variant` skill). Debug builds only: production never refers to anything
// in this folder except through `VariantHost`, which TrackoApp uses in Debug in place of
// OnboardingFlowView. Promote one variant, then delete this folder.
//
// One axis, structure: how the hero and the words are composed.
// - Stage: centred stack, hero first, nothing contained (the shipped layout, after 005/006).
// - Editorial: words first, left-aligned under a wordmark and progress; the hero below, bleeding
//   off the right edge, lit from behind it.
// - Window: the hero contained in its own lit case; words below, left-aligned on the case's
//   inner edge; dots and button share one row.
// Colour, copy, characters and motion stay the same, so the structure is what you compare.

enum OnboardingVariant: String, CaseIterable, Identifiable {
    case stage, editorial, window

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
        case .editorial: EditorialOnboardingView(onFinish: onFinish).id(variant)
        case .window: WindowOnboardingView(onFinish: onFinish).id(variant)
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

/// Shared by the variants: page state, the staged entrance and moving between pages.
struct VariantFlowState {
    static func move(_ page: Binding<OnboardingPage>, to target: OnboardingPage, reduceMotion: Bool) {
        withAnimation(reduceMotion ? Motion.fade : .smooth(duration: 0.45)) {
            page.wrappedValue = target
        }
    }
}

/// The page dots' sibling for layouts that show progress at the top: one segment per page, filled
/// up to the current one, so position shows progress as well as brightness.
struct ProgressSegments: View {
    let count: Int
    let current: Int
    let select: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Theme.textPrimary : Theme.fillSubtle)
                    .frame(height: 4)
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

/// A small Tracko wordmark, for layouts without the logo capsule.
struct SmallWordmark: View {
    var body: some View {
        Text("Tracko")
            .font(.custom(TypeScale.Weight.extraBold.rawValue, size: 20, relativeTo: .title3))
            .tracking(-0.6)
            .foregroundStyle(Theme.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}
#endif
