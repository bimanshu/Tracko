import SwiftUI

/// Progress (skill §12): am I actually growing? Time since the first workout and the next Wrapped,
/// then every lift's change since it was first logged. Settings sit behind the gear.
struct ProgressScreen: View {
    var replayOnboarding: () -> Void

    @Environment(WorkoutStore.self) private var store
    @State private var path: [String] = LaunchScreen.current == .lift ? [DemoHistory.featuredKey] : []
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    header
                    let histories = store.liftHistories()
                    if histories.isEmpty {
                        Text("Your progress shows up here after your first workout: every lift, and how far it’s come.")
                            .typeRole(.body)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        sinceYouStarted
                        lifts(histories)
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
        .sheet(isPresented: $isShowingSettings) {
            SettingsScreen(replayOnboarding: replayOnboarding)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Progress")
                .typeRole(.screenTitle)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Settings")
        }
    }

    @ViewBuilder
    private var sinceYouStarted: some View {
        if let first = store.firstWorkoutDate {
            let weeks = max(1, (Calendar.current.dateComponents([.weekOfYear], from: first, to: .now).weekOfYear ?? 0) + 1)
            let workouts = store.loggedWorkouts.count
            VStack(alignment: .leading, spacing: Space.m) {
                VStack(alignment: .leading, spacing: Space.xs) {
                    Text("Since you started")
                        .typeRole(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(weeks) \(weeks == 1 ? "week" : "weeks"), \(workouts) \(workouts == 1 ? "workout" : "workouts")")
                        .typeRole(.sectionTitle)
                        .foregroundStyle(Theme.textPrimary)
                }
                if let checkpoint = store.nextCheckpoint() {
                    VStack(alignment: .leading, spacing: Space.s) {
                        TargetBar(fraction: checkpoint.progress)
                        Text(checkpointText(checkpoint))
                            .typeRole(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .cardStyle()
        }
    }

    private func checkpointText(_ checkpoint: Checkpoint) -> String {
        let days = checkpoint.daysLeft
        let when = days <= 0 ? "today" : days == 1 ? "tomorrow" : "in \(days) days"
        return "Your \(checkpoint.months)-month Wrapped arrives \(when)."
    }

    private func lifts(_ histories: [LiftHistory]) -> some View {
        VStack(alignment: .leading, spacing: Space.m) {
            Text("Lifts")
                .typeRole(.sectionTitle)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                ForEach(Array(histories.enumerated()), id: \.element.id) { index, history in
                    if index > 0 {
                        Rectangle().fill(Theme.border).frame(height: 1)
                    }
                    NavigationLink(value: history.key) {
                        LiftRowView(history: history)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Space.l)
            .background(Theme.bgRaised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
    }
}

private struct LiftRowView: View {
    let history: LiftHistory

    var body: some View {
        HStack(spacing: Space.m) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(history.name)
                    .typeRole(.rowTitle)
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .typeRole(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            if history.sessions.count > 1 {
                Text(LiftMath.formatPercent(history.percent))
                    .typeRole(.rowTitle)
                    .foregroundStyle(history.percent > 0 ? Theme.accent : Theme.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Space.l)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var detail: String {
        let count = history.sessions.count
        let sessions = "\(count) \(count == 1 ? "session" : "sessions")"
        return count > 1 ? "\(sessions), since \(DayText.relative(history.first.date))" : sessions
    }
}

/// One lift's whole story: the change in estimated max since it was first logged, how that's
/// worked out (rule 4: show the maths), and every session with its verdict.
struct LiftDetailScreen: View {
    let key: String
    @Environment(WorkoutStore.self) private var store

    var body: some View {
        ScrollView {
            if let history = store.history(of: key) {
                content(history)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.s)
                    .padding(.bottom, Space.xxl)
            }
        }
        .background(Theme.bgPage)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Theme.bgPage, for: .navigationBar)
    }

    private func content(_ history: LiftHistory) -> some View {
        let unit = store.unit
        let firstMax = history.first.session.estimatedOneRepMax
        let latestMax = history.latest.session.estimatedOneRepMax
        return VStack(alignment: .leading, spacing: Space.xl) {
            Text(history.name)
                .typeRole(.screenTitle)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)

            if history.sessions.count > 1 {
                VStack(alignment: .leading, spacing: Space.s) {
                    Text(LiftMath.formatPercent(history.percent))
                        .typeRole(.score)
                        .foregroundStyle(history.percent > 0 ? Theme.accent : Theme.textSecondary)
                    Text("Estimated max \(LiftMath.format(weight: latestMax, unit: unit).keptTogether), \(history.percent > 0 ? "up from" : "from") \(LiftMath.format(weight: firstMax, unit: unit).keptTogether) on \(DayText.relative(history.first.date)).")
                        .typeRole(.body)
                        .foregroundStyle(Theme.textSecondary)
                    Text("Estimated max is your best set’s weight × (1 + reps ÷ 30), the Epley formula.")
                        .typeRole(.footnote)
                        .foregroundStyle(Theme.textTertiary)
                }
                .cardStyle()
            }

            VStack(alignment: .leading, spacing: Space.m) {
                Text("Sessions")
                    .typeRole(.sectionTitle)
                    .foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 0) {
                    let sessions = Array(history.sessions.enumerated()).reversed()
                    ForEach(Array(sessions), id: \.offset) { index, entry in
                        if index != history.sessions.count - 1 {
                            Rectangle().fill(Theme.border).frame(height: 1)
                        }
                        SessionRowView(
                            entry: entry,
                            verdict: index > 0
                                ? LiftMath.verdict(from: history.sessions[index - 1].session, to: entry.session, unit: unit)
                                : nil,
                            unit: unit
                        )
                    }
                }
                .padding(.horizontal, Space.l)
                .background(Theme.bgRaised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            }
        }
    }
}

private struct SessionRowView: View {
    let entry: PreviousSession
    let verdict: Verdict?
    let unit: WeightUnit

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.m) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(DayText.relative(entry.date))
                    .typeRole(.rowTitle)
                    .foregroundStyle(Theme.textPrimary)
                Text(entry.session.summary(unit: unit).keptTogether)
                    .typeRole(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            if let verdict {
                Text(verdict.number)
                    .typeRole(.rowTitle)
                    .foregroundStyle(verdict.trend == .up ? Theme.accent : Theme.textSecondary)
            } else {
                Text("First")
                    .typeRole(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.vertical, Space.l)
        .accessibilityElement(children: .combine)
    }
}

/// Units, the goal, and the onboarding again.
struct SettingsScreen: View {
    var replayOnboarding: () -> Void

    @Environment(WorkoutStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.goal) private var goal = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Weight", selection: Binding(get: { store.unit }, set: { store.setUnit($0) })) {
                        Text("kg").tag(WeightUnit.kg)
                        Text("lb").tag(WeightUnit.lb)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Units")
                } footer: {
                    Text("Workouts keep the unit they were logged in; everything is shown in this one.")
                }
                Section("Goal") {
                    Picker("Goal", selection: $goal) {
                        Text("Get stronger").tag("stronger")
                        Text("Lose fat").tag("cut")
                        Text("Not set").tag("")
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    Button("Replay onboarding") {
                        dismiss()
                        replayOnboarding()
                    }
                }
            }
            .typeRole(.body)
            .scrollContentBackground(.hidden)
            .background(Theme.bgPage)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
