# UI reference library

Screenshots from other apps and sites that set the bar for how Tracko should look and feel. Every UI change should be able to point at a reference here, or at a pattern below.

## How it works

- **Adding references:** send screenshots or links (Mobbin flows work) in a Claude session, with a line on what you like if you have one, or upload them to `inbox/` on GitHub. Claude files each one as `NNN-source-subject.jpg`, writes an entry below, and empties the inbox.
- **Flows:** a whole flow gets one number. Its screens are `NNN-source-subject-1-name.jpg`, `-2-…` in order, with a `-sheet.jpg` overview. When a recording exists it's kept as `NNN-….mp4` with a `-timeline.jpg` of frames for studying motion.
- **Citing:** refer to a reference by number ("use 004's card corners"). Numbers never change, and deleted numbers are not reused.
- **Patterns:** once a few references agree on something, it moves up into **Patterns**. Patterns turn into design tokens and rules in the Tracko skill (§9) when they're applied to the app.
- **Each entry says:** what the image is, what to take from it (concrete: spacing, type, colour, layout, motion), what to leave, and which Tracko screens it's for.

Tags: `onboarding` `typography` `colour` `layout` `cards` `numbers` `charts` `body` `buttons` `motion` `share-card` `empty-state` `paywall` `navigation` `logging`

## Before

The onboarding as of v0.1 (the code CI screenshots on every push), kept for before-and-after comparison:
[iPhone 17 Pro](../baseline/v0.1-iphone-17-pro.jpg) · [iPhone SE](../baseline/v0.1-iphone-se.jpg).

Known problems going in: scene 5's "Week 12" overlaps the figure; scene 6's "+18%" collides with the end of the line; the figure reads as a mannequin and its red is heavy; every scene uses the same stage-above-headline layout, so the flow feels flat; and the type has one weight and one size jump.

## Patterns

_None yet. These get written once three or more references point the same way._

## References

### 001 · Opal · iOS onboarding (flow, 9 screens + recording)
![001](001-opal-onboarding-sheet.jpg)

Recording: [001-opal-onboarding.mp4](001-opal-onboarding.mp4) (42 s) · frame timeline: [001-opal-onboarding-timeline.jpg](001-opal-onboarding-timeline.jpg) · source: [Mobbin](https://mobbin.com/explore/flows/be4b5aa1-ba9d-494c-acbb-9ce8faa0d6f5)

- **What it is:** a screen-time app's onboarding. A short story told with one object (a dull rock that cracks open into a glowing opal), then a setup that runs as a conversation, then sign-up.
- **Take:**
  - **One hero object across the whole story.** The rock appears, cracks over three taps, becomes the opal, then shrinks and docks at the top of the screen to preside over the conversation (19.3–20.7 s). Nothing else competes for attention. Tracko's version: the notes line is the rock, the verdict number is the opal, and the same element carries from scene to scene with a shared-element move instead of nine separate stages.
  - **Story scenes are almost empty.** One centred line of about 22 pt medium weight, at most three lines, sits about a quarter of the way down; the object sits in the middle; a quiet "tap to continue" sits at the bottom. No cards, no button bar, no progress chrome. Tapping anywhere advances.
  - **Text swaps by blur.** The outgoing line blurs and fades (about 0.4 s) while the next fades in. Nothing slides.
  - **Setup as a conversation.** The app types its lines (about 25 characters a second); each older line dims to about 35 % and blurs as the next arrives and pushes it up; the answer control (text field or two options) appears under the newest question. This is "your log talks back" taken literally.
  - **Black, lit from within.** Pure black base; the only light comes from the hero (a soft glow around the opal) and a faint green tint fading down from the top of the conversation screens.
  - **Controls.** Full-capsule text field and buttons, about 56 pt tall and 20 pt from the screen edges, filled near-black (#111) with a hairline border. Continue sits dim and dark while disabled and visibly lights up once there's an answer.
  - **Intro.** Logo mark, then the wordmark grows out of it (0.7 s), then everything blurs away into the story (2 s).
- **Leave:**
  - The rainbow, iridescent gradients. Each Tracko colour has one meaning (§9.2), so the "lights up" moment uses target yellow, or gain green for a win.
  - "TAP TO CONTINUE" in capitals. §9.3 rules out all-caps, so use sentence case in chalk-muted.
  - The photoreal 3D rock. It needs 3D or video art. Tracko's transformation (a note becoming numbers) can be built natively in SwiftUI.
  - The slow pace: 42 s for 9 screens. Lifters are impatient, so type faster and let a tap finish the line instantly.
  - Asking for a name first. Tracko shows the maths before it asks for anything (§11).
- **For:** the whole onboarding structure (scenes 1–6 as a story around one object, scenes 7–9 as a conversation), scene and text transitions, the primary button and text field, backgrounds.
- **Tags:** `onboarding` `motion` `layout` `typography` `buttons` `colour`

<!--
Entry template:

### NNN · Source · Subject
![NNN](NNN-source-subject.png)

- **What it is:** one line.
- **Take:** concrete things to copy (sizes, spacing, type, colour use, layout, motion).
- **Leave:** what doesn't fit Tracko, and why.
- **For:** Tracko screens or components (e.g. scene 2, Wrapped card, primary button).
- **Tags:** `typography` `numbers`
-->
