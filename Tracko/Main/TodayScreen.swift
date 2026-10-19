import SwiftUI

/// Today (skill §12): what do I need today? Start or continue the log, each lift's number to beat
/// from the last workout, and this week so far.
struct TodayScreen: View {
    @Environment(WorkoutStore.self) private var store
    @State private var openLog: OpenLog?
    @State private var hasOpenedLaunchLog = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    header
                    start
                    let targets = store.numbersToBeat()
                    if !targets.isEmpty {
                        numbersToBeat(targets)
                    }
                    if !store.loggedWorkouts.isEmpty {
                        thisWeek
                    }
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.l)
                .padding(.bottom, Space.xxl)
            }
            .background(Theme.bgPage)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { key in
                LiftDetailScreen(key: key)
            }
        }
        .fullScreenCover(item: $openLog) { log in
            LogFlow(workoutID: log.id)
        }
        .onAppear {
            // Debug: `-TrackoScreen log` or `report` opens on the demo workout.
            guard !hasOpenedLaunchLog, LaunchScreen.current == .log || LaunchScreen.current == .report,
                  let workout = store.workouts.first
            else { return }
            hasOpenedLaunchLog = true
            openLog = OpenLog(id: workout.id)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(DayText.full(.now))
                .typeRole(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text("Today")
                .typeRole(.screenTitle)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder
    private var start: some View {
        if let workout = store.inProgress {
            let lifts = workout.loggedLifts(unit: store.unit).count
            VStack(alignment: .leading, spacing: Space.m) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Workout in progress")
                        .typeRole(.rowTitle)
                        .foregroundStyle(Theme.textPrimary)
                    Text(lifts == 0 ? "Nothing logged yet." : "\(lifts) \(lifts == 1 ? "lift" : "lifts") so far.")
                        .typeRole(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Button {
                    openLog = OpenLog(id: workout.id)
                } label: {
                    AdvanceLabel(title: "Continue")
                }
                .buttonStyle(PrimaryButtonStyle(hasTrailingIcon: true))
            }
            .cardStyle()
        } else {
            VStack(alignment: .leading, spacing: Space.m) {
                if store.loggedWorkouts.isEmpty {
                    Text("Type a lift, then its sets, the way you would in Notes: 8 × 12, 11, 10. Next time, each lift opens with the number to beat.")
                        .typeRole(.body)
                        .foregroundStyle(Theme.textSecondary)
                }
                Button {
                    openLog = OpenLog(id: store.startWorkout().id)
                } label: {
                    AdvanceLabel(title: "Start logging")
                }
                .buttonStyle(PrimaryButtonStyle(hasTrailingIcon: true))
            }
        }
    }

    private func numbersToBeat(_ targets: [TargetRow]) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text("Numbers to beat")
                    .typeRole(.sectionTitle)
                    .foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let day = targets.first.map({ DayText.relative($0.last.date) }) {
                    Text("From \(day == "Today" || day == "Yesterday" ? day.lowercased() : day)")
                        .typeRole(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            VStack(spacing: 0) {
                ForEach(Array(targets.enumerated()), id: \.element.id) { index, target in
                    if index > 0 {
                        Rectangle().fill(Theme.border).frame(height: 1)
                    }
                    NavigationLink(value: target.key) {
                        TargetRowView(target: target, unit: store.unit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Space.l)
            .background(Theme.bgRaised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
    }

    private var thisWeek: some View {
        let workouts = store.workoutsThisWeek()
        let weeks = store.weeksInARow()
        return HStack(spacing: Space.m) {
            StatTile(number: "\(workouts)", label: workouts == 1 ? "workout this week" : "workouts this week")
            StatTile(number: "\(weeks)", label: weeks == 1 ? "week in a row" : "weeks in a row")
        }
        // Both tiles take the taller one's height.
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// The log to show over Today.
struct OpenLog: Identifiable {
    let id: Workout.ID
}

private struct TargetRowView: View {
    let target: TargetRow
    let unit: WeightUnit

    var body: some View {
        HStack(spacing: Space.m) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(target.name)
                    .typeRole(.rowTitle)
                    .foregroundStyle(Theme.textPrimary)
                Text("Last: \(target.last.session.summary(unit: unit).keptTogether)")
                    .typeRole(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Text("Next: \(target.next.summary(unit: unit).keptTogether)")
                    .typeRole(.caption)
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Space.l)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// A number and what it counts.
struct StatTile: View {
    let number: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(number)
                .typeRole(.screenTitle)
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .typeRole(.caption)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
