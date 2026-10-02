---
name: tracko
description: The living source of truth for Tracko, an iOS workout-tracking app where "your log talks back". Use this skill for ANY work on Tracko, including SwiftUI code, onboarding scenes, features, the growth-report maths, copy, design tokens, motion, pricing, market or competitor questions, and product decisions, even when the request doesn't say "Tracko" but clearly continues this project (onboarding, cut mode, growth report, Wrapped, number to beat, notes import). Read it before writing code or copy so every screen follows the same rules, and update the Status and Changelog sections whenever something ships or a decision changes.
---

# Tracko

> **Your log talks back.** Log a set the way you'd type it in Notes. Tracko does the maths, tells you whether you got better, gives you the number to beat next time, and shows you changing over weeks and months.

Working name in the early concept decks: "Everything Gym". The product is now **Tracko**.

## How to use and update this file

- Read the relevant section before building. The **Rules** sections are decisions, not suggestions; change them only on purpose and record why in the Changelog.
- After each work session, update **Status** (what's built) and add one line per change to **Changelog** (newest first).
- Keep this file under ~500 lines. When a section grows past ~60 lines, move detail to `references/<topic>.md` and leave a pointer here.

---

## 1. Status

| Area | State | Notes |
|---|---|---|
| Onboarding scene 1, Hook | Built v0.1 | Notes page scrolls, freezes, dims |
| Onboarding scene 2, Note to verdict | Built v0.1 | Matched-geometry parse, ghost, bars, +10% count-up |
| Onboarding scene 3, Number to beat | Built v0.1 | Live bar vs dashed line, set tiles, haptics |
| Onboarding scene 4, Try it | Built v0.1 | Rep slider, live % and muscle glow, auto-nudge |
| Onboarding scene 5, Watch yourself grow | Built v0.1 | 12-week time-lapse on the honest curve; shape-based figure (Rive later) |
| Onboarding scene 6, Proof on a clock | Built v0.1 | Curve draws Today → Week 1 → Month 3 with a neutral "recovery" dip |
| Onboarding scene 7, Goal | Built v0.1 | Build / Lose fat / Both; figure morphs |
| Onboarding scene 8, History fork | Built v0.1 (choice only) | Import and baseline flows not built |
| Onboarding scene 9, Future Wrapped | Built v0.1 | 9:16 card with name field, 90 days to go, "Notify me" asks permission |
| Onboarding UI polish | Next | Driven by the reference library (§9.0) |
| Logging, growth report, home | Not started | |

Code lives in `Tracko/` (see §10). Builds and tests pass in CI; runs on a real iPhone. The flow works, but the visuals are first-pass and need a lot of polish.

---

## 2. The problem

Lifters log every set in a notes app or notebook and never get a number back. Three questions go unanswered:

1. **Was Thursday better?** The answer is in the notes; nobody does the maths between sets.
2. **What do I need today?** Progressive overload needs a target; notes only show the past.
3. **Am I actually growing?** No week-on-week, month-on-month or year-on-year proof.

The question under "how long until I look good?" is "will I see myself change?". People want checkpoints with proof, not a date.

## 3. Who it's for

- **Core:** intermediate lifters (≈6 months to 3 years in) who already log on paper or in phone notes, in the US, UK and Europe. They have the habit and the history.
- **Next:** people switching from apps they find heavy (Hevy, Strong); beginners (needs templates and a guided first month).
- **Cut mode users:** lifters losing fat (see §6.6). US opportunity: people on GLP-1 medication told to lift to protect muscle.
- **India and other lower-income markets:** local pricing, bonus volume, not the revenue plan.
- **Not yet:** cardio-only users; athletes in non-strength sports (different metrics).

## 4. Market and business (summary)

- 152M gym members in the US (77M, 2024) and Europe incl. UK (75.5M, 2025).
- About 30% of regular US/UK gym-goers log on paper or in notes (YouGov 2022) → SAM 23–45M.
- About 50% of new gym members quit within six months; tracking progress has a proven effect on goal attainment (Harkin 2016, d = 0.40).
- **Pricing hypothesis:** Free forever = logging + per-lift verdict. **Pro ≈ $40/yr**, 7-day trial with a reminder before it converts = next targets, full history, quarterly Wrapped with photos. Local pricing in India.
- **Growth:** organic first (notes import "wow", shared Wrapped cards). Paid ads only pay back with a trial (LTV ≈ $51 vs ≈ $70 ad cost per payer freemium, ≈ $33 with a trial).
- **Year-3 scenarios:** $0.27M conservative / $2.0M base / $10.5M stretch.

Full decks: `Market.pdf`, `Everything-Gym-Competitive-Landscape.pdf`, `Everything-Gym-Cut-Mode.pdf`.

## 5. Competitors and where Tracko fits

| App | Strength | Gap Tracko fills |
|---|---|---|
| Hevy (16M+) | Fast logging, previous values, monthly report, photos | Charts, not verdicts; forms, not notes; Wrapped only yearly |
| Fitbod | AI plans, recovery map, yearly Flex | Follows its plan, not yours; pricey; trust issues |
| Liftoff (4M+) | Ranks, bodygraph, game feel | Ranks vs others, not you vs last week; forced flows; crashes |
| GymLevels | XP, 17 muscle ranks | Subscription wall; no long-term story |
| Gym Note Plus / Elevus / Gym Analyst | Notes or voice input | iOS-only or tiny; no motivation layer, no recap |
| Strava | Social, Year in Sport | No targets; shallow strength stats |

**Position:** the empty corner, "write it like a note" × "get a verdict". Notes apps fixed the input; game apps fixed the feeling; nobody did both.

**Still open (our wedge):** per-lift verdict in words; a Wrapped on the user's own clock (3/6/12 months from their start, not December); photos + strength in one proof moment; a body that grows with you; notes import.

### Rules from ~170 competitor reviews

1. **No money traps.** Remind before a trial converts. No looping paywall. The per-lift verdict is always free.
2. **Never lose a set.** Offline-first, save every set instantly, show the parsed import before saving.
3. **Never force a workflow.** Typing "8 × 12, 11, 10" is enough. Log during or after. Skip a lift without deleting it. Photos always optional.
4. **Compare you only to you,** and show the maths behind every %.
5. **Every session ends with an answer:** a verdict and the next target.
6. **Stay narrow:** no nutrition tracking, no social feed at launch.

---

## 6. Features

### 6.1 Growth report (after every workout)
One sentence and one number per lift, comparing with the last time the user did the same lift. Example: "Lateral raise vs Monday: +10%. You did 3 extra reps at the same weight." Bench, pushdown etc. listed below with their own change.

### 6.2 Number to beat (during the workout)
Each lift opens with last session's total. A bar fills against a dashed line; the app says exactly what the last set needs ("10 reps ties Thursday. 11 beats it."). Offer the other route too ("or go up: 9 kg × 10, 10, 10").

### 6.3 The living body
An illustrated figure that gains a little muscle where the user trained, driven only by real strength numbers, on a slowing curve. Under-trained muscles are shown gently, never shrinking. Never grows faster than reality.

### 6.4 Wrapped, on the user's own clock
At 3, 6, 9, 12, 15 months from the user's start: side-by-side photos if uploaded, the illustrated body otherwise, one headline number, then a nudge to the next checkpoint. Shareable as a 9:16 card. Photos private by default.

### 6.5 Loops
- **Every session:** number to beat → log → verdict → body grows → next target set.
- **Every Sunday:** week-on-week report (up, stalled, skipped muscle). Streaks count **weeks** trained, not days, so rest days never break them.
- **Every 3 months:** Wrapped.

### 6.6 Cut mode (goal = lose fat)
The question changes from "did I get stronger?" to "did I get lighter without getting weaker?".
- Verdict uses **relative strength** (§7.4): "Strength kept at 4 kg lighter: +5% for your size."
- Number to beat becomes **match** last week; holding is the win, beating is a bonus.
- Bodyweight shown only as a **7-day trend**, never a single weigh-in.
- The body gets leaner (waist narrows) instead of bulkier.
- Wrapped: "−6 kg, strength kept on every main lift."
- Inputs: bodyweight from Apple Health / smart scale or typed `bw 86.2`; waist and photos optional; **no calorie tracking**.
- Guardrails: celebrate a steady pace (~0.5–1% bodyweight/week); flag gently if weight drops fast while lifts slip; the scale never shames (users can hide it; weight is never red).

### 6.7 Later (not before month 2–3 of a user's data)
- **When you perform best:** compare each session's estimated 1RM against the user's own trend, grouped by time of day. Claim "you perform best in the evening", never "your body grows best". Show only with ≥6 sessions per time window on the same lifts, with a confidence label. Also nudge consistency (people adapt to the time they train).
- **Sleep:** pull sleep from Health; "you lift 6% more after 7+ hours".

---

## 7. The maths (single source of truth)

All in `Core/LiftMath.swift`. Keep formulas here and in code identical.

### 7.1 Per lift
- **Volume** = weight × total reps across working sets.
- **Estimated 1RM (Epley)** = weight × (1 + reps ÷ 30), using the best set.
- **% change** = (new − old) ÷ old × 100, rounded to the nearest whole number for display.

Reference example (must stay true): Monday 8 kg × 10, 10, 10 = 240 kg, e1RM 10.7. Thursday 8 kg × 12, 11, 10 = 264 kg (**+10%** volume), e1RM 11.2 (**+5%** strength), **+3 reps**.

### 7.2 Comparing like for like
- Compare a lift with the **last session of the same exercise**, not the last workout.
- Splits repeat by type: compare Push day with last Push day.
- Different weight? Lead with estimated 1RM change; mention volume second.

### 7.3 Bad days
- Never show a single red "−8%". Judge against the **last 4 sessions** trend. A dip reads as "lighter day, that's recovery", in neutral colour.
- Deload weeks are recovery, not a drop.

### 7.4 Cut mode
- **Relative strength** = estimated 1RM ÷ 7-day average bodyweight. Example: 76 kg e1RM at 90 kg = 0.84×; at 86 kg = 0.88× → **+5%**.
- **Trend weight** = rolling 7-day mean of weigh-ins.
- **Pace** = weekly change in trend weight as % of bodyweight. Steady ≈ 0.5–1%/week.

### 7.5 Units
Default from `Locale.measurementSystem`: `.us` → lb, else kg. Demo content localizes (8 kg ↔ 20 lb lateral raise; percentages are unit-free).

---

## 8. Voice and copy

- Plain words, active voice, sentence case. No jargon users don't already use.
- Speak lifter: progressive overload, PR, 3 × 10, push/pull/legs, leg day, deload, RPE (optional), progress pic, bulk/cut/recomp.
- Verdict pattern: **number first, then the plain reason.** "+10%. You did 3 extra reps at the same weight."
- Onboarding headlines: ≤ 7 words. If a scene needs a paragraph, the animation isn't working yet.
- Never say "AI". Show understanding instead (shorthand parsed, maths done).
- No shame words. A dip is "recovery". A missed week is "pick it back up", not "streak lost".
- Buttons say what happens: "Continue", "Start tracking", "Import notes". No arrows in labels.

---

## 9. Design system

### 9.0 References
UI decisions draw on the reference library in `design/references/README.md`: numbered screenshots and recordings (Mobbin links are fetched with `design/references/tools/fetch_mobbin.py`), and the **Patterns** taken from them. Entries are filing only; the product owner decides what to extract from each, so don't apply a reference until a takeaway is recorded. Read it before any UI work. When a pattern is applied to the app, write the resulting rule or token into this section.

UI craft skills from `jakubkrehel/skills` are installed in `.claude/skills/` (`better-ui`, `better-layout`, `better-typography`, `better-colors`, `better-accessibility`, `better-writing`, `better-interface`; user-invoked: `interface-review`, `variant`, `break`, `explain-interface`). They're written for the web: apply their principles (concentric radii, optical alignment, hit areas, type scale, surface depth, contrast) in SwiftUI terms, and ignore CSS- or React-specific mechanics. Where they conflict with this skill, this skill wins. Update them with `npx skills update`.

### 9.1 Concept
**The notebook becomes the scoreboard.** The "before" is a light paper notes page; the "after" is a dark scoreboard where numbers do the shouting. Motion always flows the same way: **note → maths → proof** (past on the left/top, proof on the right/bottom).

### 9.2 Colour (each signal has one meaning; never decorative)
| Token | Hex | Meaning |
|---|---|---|
| ink | #16171B | App background |
| slab / slabRaised | #1E2027 / #262931 | Cards / cards on cards |
| hairline | #2E313A | Borders, dividers |
| chalk / chalkMuted / chalkDim | #EDEEF0 / #9AA0A8 / #6B7079 | Text on dark |
| paper / pencil / highlighter | #FAF8F2 / #26262A / #FCE8A6 | The notes page |
| **gain** | #3DBA6E | You improved |
| **target** | #F2C230 | What to do next; primary button |
| **muscle** | #E5484D | Muscles you trained (never "bad") |
| **past** | #4C8BF5 | History, last time, the ghost |
| figure | #3A3F4B | Body illustration |

Red is reserved for muscles; it is never used for losses or bodyweight.

### 9.3 Type
- **Scoreboard numbers and scene headlines:** SF Pro **Compressed Black** (`.width(.compressed)`), large.
- **Everything else:** SF Pro at Dynamic Type text styles.
- **Notes page:** SF Pro callout, like the Notes app.
- No monospace labels, no all-caps eyebrows. Use `.monospacedDigit()` for changing numbers.

### 9.4 Motion
- One orchestrated moment per scene; everything else still.
- Springs for things that settle (`spring(duration: 0.55, bounce: 0.22)`), snappy for UI feedback, long soft spring for growing bars.
- Numbers roll with `.contentTransition(.numericText(value:))`.
- Honest motion: growth curves slow down over time.
- **Reduce Motion:** jump to the final frame (or crossfade). Every scene must handle it.

### 9.5 Haptics (`.sensoryFeedback`)
- Set logged → `.impact(weight: .light)`
- Target beaten / verdict revealed → `.success`
- Slider and option changes → `.selection`

### 9.6 Accessibility
Dynamic Type for all non-score text; VoiceOver labels describe what an animation shows; illustrations `accessibilityHidden`; tap targets ≥ 44 pt; never rely on colour alone (always a number or word).

---

## 10. Engineering

- **Platform:** iOS 17+, SwiftUI, Observation (`@Observable`). Dark appearance for now.
- **Dependencies:** none yet. Rive is the candidate for the living body (state machine for grow/lean).
- **Structure:**
  ```
  Tracko/
    App/            TrackoApp, HomePlaceholderView
    Core/           LiftMath (formulas, units)
    DesignSystem/   Theme (tokens), Components, BodyFigure
    Onboarding/     OnboardingModel, OnboardingFlowView, Script, DemoContent
      Scenes/       one file per scene
  TrackoTests/      LiftMathTests (keeps §7 examples true)
  ```
- **Project:** `Tracko.xcodeproj` (Xcode 16+) uses synchronized folders: files added under `Tracko/` or `TrackoTests/` join their target automatically, so never hand-edit the project for a new file. Swift 5 language mode, iPhone only, portrait. Bundle ID `com.bimanshu.tracko`.
- **CI:** `.github/workflows/ios.yml` runs on every push that touches the app: builds, runs the tests, then launches each onboarding scene on an iPhone Pro and an iPhone SE simulator and uploads screenshots (plus a contact sheet per device) as the `screenshots` artifact. The JPEGs are also force-pushed to the `ci-screenshots` branch (`git fetch origin ci-screenshots`), which cloud sessions can read when the artifact host is blocked. Check both after every change; cloud sessions can't compile locally.
- **Running on a phone:** steps in `README.md` (Xcode + free Apple ID, 7-day expiry).
- **Debug launch argument:** `-TrackoStartScene <0–8>` opens onboarding on that scene (used by CI screenshots).
- **Conventions:**
  - Scripted animations: `@MainActor func play() async` driven by `.task(id: replay)`, steps separated by `guard await Script.wait(x) else { return }` so leaving a scene cancels cleanly. Tap a scene to replay.
  - Every scene: works with Reduce Motion, has a `#Preview`, takes data from `DemoContent` (localized units), no hard-coded maths (call `LiftMath`).
  - Colours, fonts, spacing and animations only via `Theme`, `Font`, `Space`, `Radius`, `Motion`.
  - Unit-test every formula with the reference examples in §7.

---

## 11. Onboarding spec

### Why onboarding exists
1. **Set the mental model:** "I log once, it does the maths and talks back."
2. **Get the "before":** a % needs two data points. Import old notes or log one recent lift.
3. **Deliver the first win** before onboarding ends: the first "+%" or the first number to beat.

### The one message
**Your log talks back**, in three beats: you already do the work → we do the maths → you watch yourself change.

### Storyboard (60–90 s, skippable to the goal scene)
| # | Scene | Visual and motion | Words | Collects |
|---|---|---|---|---|
| 1 | Hook | Notes page scrolls endlessly, freezes, dims | "You log every set. It never answers." | – |
| 2 | Note → verdict | Line breaks into chips (matched geometry), Monday's ghost slides in, bars grow, +10% rolls up | "Log it like a note. We do the maths." | – |
| 3 | Number to beat | Bar fills set by set past a dashed line; haptic per set; success | "Always know the number to beat." | – |
| 4 | Try it | Rep slider; % and shoulder glow change live; auto-nudge once | "Try it." / "Drag the reps." | – |
| 5 | Watch yourself grow | 12-week time-lapse; trained muscles grow, fast then slowing | "Watch yourself grow." | – |
| 6 | Proof on a clock | Timeline Today → Week 1 → Month 3; curve rises, dips ("recovery"), rises | "Proof, on a clock." | – |
| 7 | Goal | Build / Lose fat / Both; figure bulks or leans | "What's your goal?" | goal |
| 8 | History fork | Yes → paste/photo notes → parse → "Found 6 months, bench +24%" and the body fills in. No → log one lift → "This is your Day 1" | "Do you already track?" | history or baseline |
| 9 | Future Wrapped | Card with their name, "90 days to go" | "We'll tell you when it's ready." | notification permission |

### Onboarding rules
- One idea per screen; the animation carries the explanation.
- Personal beats generic: show the user's own numbers as early as possible.
- Ask permissions only when they make sense: Health when choosing "Lose fat", notifications when promising the Wrapped, Photos when importing.
- Skip jumps to scene 7; story scenes are optional, data scenes are not.

### Onboarding metrics
Share reaching a first verdict or baseline; time to that moment; notes-import completion; notification opt-in; day-7 retention.

---

## 12. Open questions to validate
1. Why do notebook lifters stay on paper when Hevy is free? (20 US/UK interviews)
2. Will ≥5% pay ≈ $40/yr? (pricing page + trial before the product exists)
3. Is notes import the "wow" moment? (parse 30 real logs, watch reactions)
4. Do people share their Wrapped? (hand-made cards; do they post?)
5. Does "+5% for your size" motivate people on a cut?

---

## 13. Changelog (newest first)
- **2026-10-02** Started the UI reference library (`design/references/`) ahead of a big visual polish pass; skill §9.0 points to it.
- **2026-10-02 · v0.1 code** Xcode project (synchronized folders), all nine onboarding scenes, LiftMath + tests, CI that builds, tests and screenshots every scene. Scenes 5, 6 and 9 built (were placeholders). Runs on device via Xcode.
- **2026-10-02 · v0.1** Created this skill. Onboarding foundation in SwiftUI: tokens, components, body figure, LiftMath + tests, flow container (progress, back, skip), scenes 1–4 and 7 built, scene 8 choice only, scenes 5, 6, 9 as placeholders.
