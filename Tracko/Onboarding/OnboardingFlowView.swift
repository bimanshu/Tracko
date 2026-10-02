import SwiftUI

/// The onboarding container: progress, back and skip on top, one scene, the primary button below.
struct OnboardingFlowView: View {
    var onFinish: () -> Void

    @State private var model = OnboardingModel.launch()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(StorageKey.goal) private var savedGoal = ""
    @AppStorage(StorageKey.history) private var savedHistory = ""
    @AppStorage(StorageKey.name) private var savedName = ""

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(
                scene: model.scene,
                onBack: { move { model.back() } },
                onSkip: { move { model.skipStory() } }
            )

            ZStack {
                sceneView(model.scene)
                    .id(model.scene)
                    .transition(sceneTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            PrimaryButton(model.isLast ? "Start tracking" : "Continue", isEnabled: model.canContinue) {
                if model.isLast {
                    finish()
                } else {
                    move { model.next() }
                }
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.m)
            .padding(.bottom, Space.s)
        }
        .background(Theme.ink.ignoresSafeArea())
    }

    @ViewBuilder
    private func sceneView(_ scene: OnboardingScene) -> some View {
        switch scene {
        case .hook: HookScene()
        case .noteToVerdict: NoteToVerdictScene()
        case .numberToBeat: NumberToBeatScene()
        case .tryIt: TryItScene()
        case .grow: GrowScene()
        case .proof: ProofScene()
        case .goal: GoalScene(goal: $model.goal)
        case .history: HistoryScene(choice: $model.history)
        case .wrapped: WrappedScene(name: $model.name)
        }
    }

    private var sceneTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let edge: Edge = model.direction == .forward ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .opacity
        )
    }

    private func move(_ change: () -> Void) {
        withAnimation(reduceMotion ? Motion.fade : Motion.settle, change)
    }

    private func finish() {
        savedGoal = model.goal?.rawValue ?? ""
        savedHistory = model.history?.rawValue ?? ""
        savedName = model.name.trimmingCharacters(in: .whitespacesAndNewlines)
        onFinish()
    }
}

struct OnboardingTopBar: View {
    let scene: OnboardingScene
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: Space.s) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Back")
            .opacity(scene == .hook ? 0 : 1)
            .disabled(scene == .hook)
            .accessibilityHidden(scene == .hook)

            ProgressSegments(count: OnboardingScene.allCases.count, current: scene.rawValue)

            Button(action: onSkip) {
                Text("Skip")
                    .font(.body)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .opacity(scene.isStory ? 1 : 0)
            .disabled(!scene.isStory)
            .accessibilityHidden(!scene.isStory)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.chalkMuted)
        .padding(.horizontal, Space.s)
    }
}

struct ProgressSegments: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Space.xs) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Theme.chalk : Theme.hairline)
                    .frame(height: 4)
            }
        }
        .animation(Motion.snappy, value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}

#Preview {
    OnboardingFlowView {}
}
