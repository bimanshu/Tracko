import SwiftUI

/// Stands in for home until logging is built.
struct HomePlaceholderView: View {
    var replayOnboarding: () -> Void

    var body: some View {
        VStack(spacing: Space.l) {
            Spacer()
            PageHeadline("You’re set")
            PageSubline("Logging, the number to beat and your first growth report are next.")
            Spacer()
            Button("Replay onboarding", action: replayOnboarding)
                .buttonStyle(SecondaryButtonStyle())
                .padding(.bottom, Space.l)
        }
        .padding(.horizontal, Space.gutter)
        .frame(maxWidth: .infinity)
        .background { GlowBackground() }
    }
}

#Preview {
    HomePlaceholderView {}
        .onAppear { Fonts.register() }
}
