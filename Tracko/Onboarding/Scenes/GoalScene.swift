import SwiftUI

/// Scene 7, Goal. Build, lose fat or both; the figure bulks or leans to match.
struct GoalScene: View {
    @Binding var goal: Goal?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var growth: [Muscle: Double] {
        let amount: Double
        switch goal {
        case .build: amount = 0.9
        case .both: amount = 0.5
        case .loseFat: amount = 0.15
        case nil: amount = 0
        }
        return [.shoulders: amount, .chest: amount, .arms: amount, .legs: amount * 0.7]
    }

    private var lean: Double {
        switch goal {
        case .loseFat: return 1
        case .both: return 0.6
        default: return 0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            SceneHeadline("What's your goal?")
            BodyFigure(growth: growth, lean: lean)
                .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            VStack(spacing: Space.s) {
                ForEach(Goal.allCases) { option in
                    ChoiceCard(title: option.title, detail: option.detail, isSelected: goal == option) {
                        withAnimation(reduceMotion ? Motion.fade : Motion.settle) {
                            goal = option
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.m)
        .sensoryFeedback(.selection, trigger: goal)
    }
}

#Preview {
    GoalScene(goal: .constant(.build))
        .background(Theme.ink)
}
