import SwiftUI
import UIKit

/// The app after onboarding (skill §12): two tabs, each answering one question. Today: what do I
/// need today? Progress: am I actually growing?
struct MainView: View {
    var replayOnboarding: () -> Void

    @State private var tab: MainTab = LaunchScreen.current?.tab ?? .today

    var body: some View {
        TabView(selection: $tab) {
            TodayScreen()
                .tabBarStyle()
                .tabItem { Label("Today", systemImage: "square.and.pencil") }
                .tag(MainTab.today)
            ProgressScreen(replayOnboarding: replayOnboarding)
                .tabBarStyle()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(MainTab.progress)
        }
        .tint(Theme.textPrimary)
        .sensoryFeedback(.selection, trigger: tab)
    }
}

enum MainTab: Hashable {
    case today, progress
}

private extension View {
    func tabBarStyle() -> some View {
        toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(Theme.bgPage, for: .tabBar)
    }
}

/// Debug builds can open on a screen with `-TrackoScreen <name>`, over demo history (CI
/// screenshots use it). Release builds always return nil.
enum LaunchScreen: String {
    case firstRun = "firstrun"
    case today, log, report, progress, lift

    static var current: LaunchScreen? {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "TrackoScreen").flatMap(LaunchScreen.init(rawValue:))
        #else
        return nil
        #endif
    }

    var tab: MainTab {
        switch self {
        case .progress, .lift: return .progress
        default: return .today
        }
    }
}

/// UIKit bars in Lexend, so the system navigation and tab bars match the type (§9.3).
enum Appearance {
    static func apply() {
        func font(_ weight: TypeScale.Weight, _ size: CGFloat, _ style: UIFont.TextStyle) -> UIFont {
            let base = UIFont(name: weight.fontName, size: size) ?? .systemFont(ofSize: size)
            return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
        }
        let navigationBar = UINavigationBar.appearance()
        navigationBar.titleTextAttributes = [.font: font(.semibold, 17, .headline)]
        navigationBar.largeTitleTextAttributes = [.font: font(.bold, 34, .largeTitle)]
        UIBarButtonItem.appearance().setTitleTextAttributes([.font: font(.regular, 17, .body)], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.font: font(.semibold, 10, .caption2)], for: .normal)
    }
}
