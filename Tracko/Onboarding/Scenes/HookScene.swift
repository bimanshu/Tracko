import SwiftUI

/// Scene 1, Hook. A notes page full of sets scrolls by, freezes and dims.
/// "You log every set. It never answers."
struct HookScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var replay = 0
    @State private var scroll: CGFloat = 0
    @State private var frozen = false

    private let demo = DemoContent()
    private let scrollDistance: CGFloat = 900

    var body: some View {
        SceneLayout {
            notesPage
        } caption: {
            VStack(alignment: .leading, spacing: 0) {
                SceneHeadline("You log every set.")
                SceneHeadline("It never answers.")
                    .opacity(frozen ? 1 : 0)
            }
            .accessibilityElement(children: .combine)
        }
        .contentShape(Rectangle())
        .onTapGesture { replay += 1 }
        .task(id: replay) { await play() }
    }

    private var notesPage: some View {
        Theme.paper
            .overlay(alignment: .top) {
                notes.offset(y: -scroll)
            }
            .overlay(Theme.ink.opacity(frozen ? 0.6 : 0))
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("A notes page full of logged sets scrolls by, then stops. None of it is added up.")
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gym log")
                .font(.title2.weight(.bold))
                .padding(.bottom, Space.xs)
            ForEach(demo.notesPage) { line in
                Text(line.text)
                    .font(line.isHeading ? Font.callout.weight(.semibold) : Font.callout)
                    .padding(.top, line.isHeading ? Space.m : 0)
            }
        }
        .foregroundStyle(Theme.pencil)
        .fixedSize(horizontal: false, vertical: true)
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @MainActor
    private func play() async {
        guard !reduceMotion else {
            scroll = scrollDistance
            frozen = true
            return
        }
        Script.reset {
            scroll = 0
            frozen = false
        }
        guard await Script.wait(0.4) else { return }
        // Speeds up and stops dead: the freeze.
        withAnimation(.timingCurve(0.5, 0, 0.75, 0.75, duration: 3)) {
            scroll = scrollDistance
        }
        guard await Script.wait(3.1) else { return }
        withAnimation(.easeOut(duration: 0.6)) {
            frozen = true
        }
    }
}

#Preview {
    HookScene()
        .background(Theme.ink)
}
