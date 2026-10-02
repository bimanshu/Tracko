import SwiftUI

@main
struct TrackoApp: App {
    @AppStorage(StorageKey.onboardingComplete) private var onboardingComplete = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if onboardingComplete {
                    HomePlaceholderView { onboardingComplete = false }
                        .transition(.opacity)
                } else {
                    OnboardingFlowView { onboardingComplete = true }
                        .transition(.opacity)
                }
            }
            .animation(Motion.fade, value: onboardingComplete)
            .preferredColorScheme(.dark)
        }
    }
}
