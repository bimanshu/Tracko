import SwiftUI

/// The first run after onboarding (skill §12): at most two screens, both skippable. Old notes
/// come in first, because they're the history the number to beat needs; then the goal.
struct FirstRunView: View {
    var onFinish: () -> Void

    @State private var step = Step.importNotes

    enum Step {
        case importNotes, goal
    }

    var body: some View {
        ZStack {
            switch step {
            case .importNotes:
                ImportScreen { withAnimation(Motion.fade) { step = .goal } }
                    .transition(.opacity)
            case .goal:
                GoalScreen(onFinish: onFinish)
                    .transition(.opacity)
            }
        }
        .background { GlowBackground() }
    }
}

/// "Got old logs?" Paste notes, see what Tracko read, then save. Nothing is saved before the
/// preview (rule 2).
struct ImportScreen: View {
    var onNext: () -> Void

    @Environment(WorkoutStore.self) private var store
    @State private var text = ""
    @State private var found: [Workout]?

    var body: some View {
        // Always a scroll view (not a fallback): the keyboard opening must never swap the layout,
        // which would rebuild the editor and drop its focus.
        ScrollView {
            content
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            VStack(alignment: .leading, spacing: Space.s) {
                PageHeadline("Got old logs?", alignment: .left)
                PageSubline(
                    found == nil
                        ? "Paste your workout notes. Tracko shows what it read before saving anything."
                        : "Here’s what Tracko read. Save it, or go back and edit.",
                    alignment: .left
                )
            }
            if let found {
                preview(found)
            } else {
                editor
            }
            buttons
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.xxl)
        .padding(.bottom, Space.l)
    }

    private var editor: some View {
        TextEditor(text: $text)
            .typeRole(.body)
            .foregroundStyle(Theme.textPrimary)
            .scrollContentBackground(.hidden)
            .autocorrectionDisabled()
            .padding(Space.m)
            .frame(height: 240)
            .background(Theme.bgRaised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Mon 13 Oct\nLateral raise\n8 × 10, 10, 10")
                        .typeRole(.body)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, Space.m + 5)
                        .padding(.vertical, Space.m + 8)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("Workout notes")
    }

    private func preview(_ workouts: [Workout]) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            if workouts.isEmpty {
                Text("Tracko couldn’t find any sets. Lines like “Bench 60 × 8, 8, 7” work best, under a date like “Mon 13 Oct”.")
                    .typeRole(.body)
                    .foregroundStyle(Theme.textSecondary)
            }
            ForEach(workouts) { workout in
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text(DayText.relative(workout.date))
                        .typeRole(.rowTitle)
                        .foregroundStyle(Theme.textPrimary)
                    ForEach(workout.loggedLifts(unit: store.unit)) { lift in
                        Text("\(lift.name): \(lift.session.summary(unit: store.unit).keptTogether)")
                            .typeRole(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .cardStyle()
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: Space.s) {
            if let found {
                if !found.isEmpty {
                    Button("Save \(found.count) \(found.count == 1 ? "workout" : "workouts")") {
                        store.add(found)
                        onNext()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                Button("Edit") { self.found = nil }
                    .buttonStyle(SecondaryButtonStyle())
            } else {
                Button("Read my notes") {
                    found = NoteImporter.workouts(from: text, unit: store.unit)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Start fresh", action: onNext)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// "What’s the goal?" One tap, or Not now. Lose fat turns on cut mode once it's built (§6.6).
struct GoalScreen: View {
    var onFinish: () -> Void

    @AppStorage(StorageKey.goal) private var goal = ""

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView {
                content
            }
            .scrollIndicatorsFlash(onAppear: true)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            VStack(alignment: .leading, spacing: Space.s) {
                PageHeadline("What’s the goal?", alignment: .left)
                PageSubline("It changes what counts as a win. You can switch it later.", alignment: .left)
            }
            VStack(spacing: Space.m) {
                GoalOption(title: "Get stronger", detail: "Beat last time, lift by lift.") {
                    goal = "stronger"
                    onFinish()
                }
                GoalOption(title: "Lose fat", detail: "Get lighter and keep your strength.") {
                    goal = "cut"
                    onFinish()
                }
            }
            Spacer(minLength: 0)
            Button("Not now", action: onFinish)
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.xxl)
        .padding(.bottom, Space.l)
    }
}

private struct GoalOption: View {
    let title: String
    let detail: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.m) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text(title)
                        .typeRole(.rowTitle)
                        .foregroundStyle(Theme.textPrimary)
                    Text(detail)
                        .typeRole(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
            }
            .cardStyle()
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
