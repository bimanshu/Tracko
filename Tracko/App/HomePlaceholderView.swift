import SwiftUI

/// Stands in for home until logging is built.
struct HomePlaceholderView: View {
    var replayOnboarding: () -> Void

    @AppStorage(StorageKey.goal) private var savedGoal = ""
    @AppStorage(StorageKey.name) private var savedName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            Spacer()
            SceneHeadline(savedName.isEmpty ? "You're set." : "You're set, \(savedName).")
            Text("Logging, the number to beat and your first growth report come next.")
                .font(.body)
                .foregroundStyle(Theme.chalkMuted)
            if let goal = Goal(rawValue: savedGoal) {
                Text("Goal: \(goal.title)")
                    .font(.headline)
                    .foregroundStyle(Theme.chalk)
            }
            Spacer()
            Button("Replay onboarding", action: replayOnboarding)
                .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal, Space.gutter)
        .padding(.bottom, Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.ink.ignoresSafeArea())
    }
}

#Preview {
    HomePlaceholderView {}
}
