import SwiftUI

/// Scene 8, History fork. Old notes give a first +% today; no history means Day 1.
/// v0.1 records the choice only; the import and baseline flows come next.
struct HistoryScene: View {
    @Binding var choice: HistoryChoice?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let demo = DemoContent()

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            SceneCaption(headline: "Do you already track?", subline: "Your old notes are the fastest way to a first +%.")
            Spacer(minLength: 0)
            illustration
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
            VStack(spacing: Space.s) {
                ForEach(HistoryChoice.allCases) { option in
                    ChoiceCard(title: option.title, detail: option.detail, isSelected: choice == option) {
                        withAnimation(reduceMotion ? Motion.fade : Motion.settle) {
                            choice = option
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.m)
        .sensoryFeedback(.selection, trigger: choice)
    }

    @ViewBuilder
    private var illustration: some View {
        if choice == .startFresh {
            dayOne
                .transition(.opacity)
        } else {
            notesToProof
                .transition(.opacity)
        }
    }

    /// A scrap of notes becomes a number.
    private var notesToProof: some View {
        HStack(spacing: Space.m) {
            VStack(alignment: .leading, spacing: Space.xs) {
                ForEach(demo.notesPage.filter { !$0.isHeading }.prefix(3)) { line in
                    Text(line.text)
                        .lineLimit(1)
                }
            }
            .font(.footnote)
            .foregroundStyle(Theme.pencil)
            .padding(Space.m)
            .background(Theme.paper, in: RoundedRectangle(cornerRadius: Radius.chip + 4, style: .continuous))
            .rotationEffect(.degrees(-3))

            Image(systemName: "arrow.right")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.chalkDim)

            VStack(alignment: .leading, spacing: 0) {
                Text("Bench")
                    .font(.subheadline)
                    .foregroundStyle(Theme.chalkMuted)
                PercentScore(value: 24, size: 44)
                Text("in 6 months")
                    .font(.footnote)
                    .foregroundStyle(Theme.chalkMuted)
            }
            .fixedSize()
            .padding(Space.m)
            .background(Theme.slab, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Example: notes become a number, bench up 24 percent in 6 months.")
    }

    private var dayOne: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text("Day 1")
                .font(.score(56))
                .foregroundStyle(Theme.chalk)
            Text("Your first lift sets the number to beat.")
                .font(.subheadline)
                .foregroundStyle(Theme.chalkMuted)
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.slab, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Capsule()
                .fill(Theme.target)
                .frame(width: 36, height: 6)
                .padding(Space.l)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HistoryScene(choice: .constant(nil))
        .background(Theme.ink)
}
