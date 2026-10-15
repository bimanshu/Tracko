import SwiftUI

@main
struct TrackoApp: App {
    @AppStorage(StorageKey.onboardingComplete) private var onboardingComplete = false

    init() {
        Fonts.register()
        #if DEBUG
        FontVariantHost.prepare()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if onboardingComplete {
                    HomePlaceholderView { onboardingComplete = false }
                        .transition(.opacity)
                } else {
                    #if DEBUG
                    // Debug builds host the typeface candidates behind a picker (Onboarding/Variants).
                    FontVariantHost { onboardingComplete = true }
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
