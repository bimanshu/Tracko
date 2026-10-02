# Tracko

**Your log talks back.** Log a set the way you'd type it in Notes. Tracko does the maths, tells you whether you got better, gives you the number to beat next time, and shows you changing over weeks and months.

The product source of truth (features, maths, voice, design system, onboarding spec, status and changelog) is the Tracko skill: [`.claude/skills/tracko/SKILL.md`](.claude/skills/tracko/SKILL.md).

## What's here

- `Tracko.xcodeproj`: iOS 17+, SwiftUI, no dependencies. New files in `Tracko/` or `TrackoTests/` are picked up automatically, with no project edits needed.
- `Tracko/`: the app. `Core/LiftMath.swift` holds the formulas, `DesignSystem/` the tokens and components, `Onboarding/` the nine scenes.
- `TrackoTests/`: unit tests that keep the skill's reference examples true.
- `.github/workflows/ios.yml`: builds, runs the tests and screenshots every onboarding scene on an iPhone simulator for each push. The screenshots are attached to the run as an artifact.

## Run it on your iPhone

You need a Mac with Xcode 16 or later. A free Apple ID is enough.

1. Open `Tracko.xcodeproj` in Xcode.
2. In **Xcode → Settings → Accounts**, sign in with your Apple ID.
3. Select the **Tracko** project, then the **Tracko** target, then **Signing & Capabilities**. Set **Team** to your Personal Team. If Xcode says the bundle identifier is taken, change `com.bimanshu.tracko` to something unique.
4. Plug your iPhone in and tap **Trust** on the phone. On the iPhone, turn on **Settings → Privacy & Security → Developer Mode** and restart when asked.
5. Pick your iPhone in the device menu at the top of Xcode and press **Run** (⌘R).
6. The first time, the iPhone blocks the app until you trust it: **Settings → General → VPN & Device Management**, tap your Apple ID, then **Trust**.

With a free Apple ID the app stops opening after 7 days. Press Run again to renew it. After the first run you can also run over Wi-Fi: in **Window → Devices and Simulators**, tick **Connect via network**.

### Handy while developing

- Tap any story scene to replay its animation.
- In Debug builds, the launch argument `-TrackoStartScene <0–8>` opens onboarding on that scene. Set it in **Product → Scheme → Edit Scheme → Run → Arguments**.
- After onboarding finishes, the placeholder home screen has **Replay onboarding**.
- Every scene has a SwiftUI preview, so you can open the canvas with ⌥⌘↩.
