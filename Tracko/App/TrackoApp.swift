import SwiftUI

@main
struct TrackoApp: App {
    @AppStorage(StorageKey.onboardingComplete) private var onboardingComplete = false

    init() {
        Fonts.register()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if onboardingComplete {
                    HomePlaceholderView { onboardingComplete = false }
                        .transition(.opacity)
                } else {
                    #if DEBUG
                    // Debug builds host the onboarding variants behind a picker (Onboarding/Variants).
                    VariantHost { onboardingComplete = true }
                        .transition(.opacity)
                    #else
                    OnboardingFlowView { onboardingComplete = true }
                        .transition(.opacity)
                    #endif
                }
            }
            .animation(Motion.fade, value: onboardingComplete)
            .preferredColorScheme(.dark)
        }
    }
}
