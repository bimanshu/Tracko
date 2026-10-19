import SwiftUI

@main
struct TrackoApp: App {
    @AppStorage(StorageKey.onboardingComplete) private var onboardingComplete = false
    @AppStorage(StorageKey.firstRunComplete) private var firstRunComplete = false
    @State private var store: WorkoutStore

    init() {
        Fonts.register()
        Appearance.apply()
        #if DEBUG
        // CI screenshots: `-TrackoStartScene` shows the onboarding; `-TrackoScreen` skips it and
        // opens a screen over demo history, kept in memory so nothing real is touched.
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "TrackoStartScene") != nil {
            defaults.set(false, forKey: StorageKey.onboardingComplete)
        }
        if let screen = LaunchScreen.current {
            defaults.set(true, forKey: StorageKey.onboardingComplete)
            defaults.set(screen != .firstRun, forKey: StorageKey.firstRunComplete)
            _store = State(initialValue: DemoHistory.store(for: screen))
            return
        }
        #endif
        _store = State(initialValue: WorkoutStore())
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !onboardingComplete {
                    OnboardingFlowView { onboardingComplete = true }
                        .transition(.opacity)
                } else if !firstRunComplete {
                    FirstRunView { firstRunComplete = true }
                        .transition(.opacity)
                } else {
                    MainView { onboardingComplete = false }
                        .transition(.opacity)
                }
            }
            .animation(Motion.fade, value: onboardingComplete)
            .animation(Motion.fade, value: firstRunComplete)
            .environment(store)
            .preferredColorScheme(.dark)
        }
    }
}
