import SwiftUI

// MARK: - Scene layout

/// Scene headline: SF Pro Compressed Black, scaled with Dynamic Type.
struct SceneHeadline: View {
    private let text: String
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 44

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.score(size))
            .foregroundStyle(Theme.chalk)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Headline plus an optional one-line subline.
struct SceneCaption: View {
    let headline: String
    var subline: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            SceneHeadline(headline)
            if let subline {
                Text(subline)
                    .font(.body)
                    .foregroundStyle(Theme.chalkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Story scene layout: the animated stage on top, the words underneath.
struct SceneLayout<Stage: View, Caption: View>: View {
    private let stage: Stage
    private let caption: Caption

    init(@ViewBuilder stage: () -> Stage, @ViewBuilder caption: () -> Caption) {
        self.stage = stage()
        self.caption = caption()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            stage
                .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            caption
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.m)
    }
}

extension SceneLayout where Caption == SceneCaption {
    init(_ headline: String, subline: String? = nil, @ViewBuilder stage: () -> Stage) {
        self.init(stage: stage) {
            SceneCaption(headline: headline, subline: subline)
        }
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    private let title: String
    private let isEnabled: Bool
    private let action: () -> Void

    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isEnabled)
    }
}

/// Target yellow: what to do next.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Theme.ink : Theme.chalkDim)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                isEnabled ? Theme.target : Theme.slabRaised,
                in: RoundedRectangle(cornerRadius: Radius.button, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.chalk)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Theme.slabRaised, in: RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

/// A selectable option card for data scenes.
struct ChoiceCard: View {
    let title: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.chalk)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.chalkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.chalk : Theme.chalkDim)
            }
            .multilineTextAlignment(.leading)
            .padding(Space.l)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(Theme.slab, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(isSelected ? Theme.chalk : Theme.hairline, lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Scoreboard pieces

/// A big rolling percentage: "+10%".
struct PercentScore: View {
    let value: Int
    var size: CGFloat = 88
    var color: Color = Theme.gain

    var body: some View {
        Text(LiftMath.formatPercent(value))
            .font(.score(size))
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(value)))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

/// A horizontal bar on a track. Animate `fraction` to grow it.
struct VolumeBar: View {
    /// Share of the track to fill, 0...1.
    let fraction: Double
    let color: Color
    var height: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.slabRaised)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: height)
    }
}

#Preview("Components") {
    VStack(alignment: .leading, spacing: Space.l) {
        SceneHeadline("Always know the number to beat.")
        PercentScore(value: 10)
        VolumeBar(fraction: 0.9, color: Theme.past)
        VolumeBar(fraction: 1, color: Theme.gain)
        ChoiceCard(title: "Build muscle", detail: "Beat your numbers week on week.", isSelected: true) {}
        PrimaryButton("Continue") {}
        PrimaryButton("Continue", isEnabled: false) {}
    }
    .padding(Space.gutter)
    .background(Theme.ink)
}
