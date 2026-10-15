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
| Onboarding (4 pages) | Built v0.2 | Any Distance layout (§11): welcome, log it like a note, number to beat, get stronger. 3D heroes with live phone screens, under a green spotlight; the characters blink and smile |
| Design system | Built v0.2 | OKLCH tokens rendered in Display P3, type scale (Geist until a new face is picked), green spotlight (§9) |
| Characters (female, male) | Built v0.2 | Vinyl-toy finish, onboarding heroes, sheets (`characters/`). The "gym log" clip is still the v0.1 look |
| Goal, notes import, baseline, notification ask | Moved out of onboarding | Owner capped onboarding at 4 pages; these move to the app's first run (not built) |
| Typeface | Under evaluation (Debug) | Geist reads too technical (owner, 2026-10-15). Candidates: Satoshi, Figtree, Outfit, Rubik, Bricolage Grotesque. Picker in Debug builds; `-TrackoFont <name>`; release builds stay on Geist until one is picked, then `Onboarding/Variants/` is deleted |
| Logo | Placeholder | A "T" in a capsule, until the brand mark is designed |
| Logging, growth report, home | Not started | |

Code lives in `Tracko/` (see §10). Builds and tests run in CI, which also screenshots every onboarding page; the app runs on a real iPhone.

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
- Buttons say what happens: "Continue", "Start tracking", "Import notes". No arrow characters in label text; the onboarding's advance button carries a trailing arrow icon, as in the reference, hidden from VoiceOver.

---

## 9. Design system

### 9.0 References
UI decisions draw on the reference library in `design/references/README.md`: numbered screenshots and recordings (Mobbin links are fetched with `design/references/tools/fetch_mobbin.py`), and the **Patterns** taken from them. Entries are filing only; the product owner decides what to extract from each, so don't apply a reference until a takeaway is recorded. The library's **Priority** list is the owner's ranking and wins when references disagree; two references share priority 1: 005 (Any Distance; its whole flow is 006) for how the onboarding should look, with a 3D character matching Tracko's; 004 (BitePal) for illustration and storytelling. Read it before any UI work. When a pattern is applied to the app, write the resulting rule or token into this section.

**Applied:** the onboarding layout, hero dioramas and button come from 005/006 (library pattern P1, owner's direction 2026-10-14), with green as the brand colour instead of the reference's red. The reference's glow from the top became our own spotlight on the platform (variant round, owner's pick 2026-10-15), so it reads as Tracko rather than a copy. The hero phone's size and the platform's size and colours were measured from 006 (see §9.7).

UI craft skills from `jakubkrehel/skills` are installed in `.claude/skills/` (`better-ui`, `better-layout`, `better-typography`, `better-colors`, `better-accessibility`, `better-writing`, `better-interface`; user-invoked: `interface-review`, `variant`, `break`, `explain-interface`). They're written for the web: apply their principles (concentric radii, optical alignment, hit areas, type scale, surface depth, contrast) in SwiftUI terms, and ignore CSS- or React-specific mechanics. Where they conflict with this skill, this skill wins. Update them with `npx skills update`.

### 9.1 Concept
**Your log, on a stage.** A near-black canvas with a soft green spotlight falling on a round platform; 3D characters on a round platform beside a giant phone that shows Tracko's own live screen; one bold headline. Numbers do the shouting, in brand green. Motion still flows **note → maths → proof**.

### 9.2 Colour (OKLCH, rendered in Display P3)
Tokens are written in OKLCH. `Palette` holds the primitives (ramps named by hue and step); `Theme.Roles` maps each role to a primitive for the standard appearance and for **Increase Contrast**; `Theme.<role>` is the dynamic colour views use. Views never use `Palette`, and never borrow a token outside its role (no text colour as a fill, no page colour as text). `design/tools/palette.py` prints every primitive's P3/sRGB values and gamut, and every pair's **WCAG 2 ratio and APCA Lc in both appearances**; `ColorTests` checks the same in CI.

| Role | Standard → Increase Contrast | Use |
|---|---|---|
| bgPage | neutral950 (L 0.090) | The page, near-black (the reference's is black); also the phone screens |
| bgRaised | neutral850 (0.225) | Set tiles, bar tracks, secondary buttons |
| bgInverse | neutral50 (0.975) | The one light surface: the primary button |
| border | neutral800 (0.290) → neutral600 | Dividers only |
| textPrimary | neutral50 (0.975) | Headlines, titles (APCA Lc −102) |
| textSecondary | neutral300 (0.850) → neutral50 | Sublines, details (Lc −77) |
| textTertiary | neutral400 (0.770) → neutral100 | Labels on the page (Lc −62) |
| textInverse | neutral950 | Text on bgInverse and on accent fills |
| fillSubtle | neutral600 (0.570) → neutral400 | Inactive page dots (Lc −31) |
| fillStrong | neutral300 → neutral50 | Neutral bars and markers |
| **accent** | green300 (0.850 0.235 152) | **Brand and growth:** gains, the +%, a beaten target. Beyond sRGB on purpose |
| spotlight | green600 (0.500 0.170 152) | The onboarding light (`SpotlightBackground`): a beam from above the screen to the platform (8 → 40% opacity) and a pool around the figures (60% at its heart), under a faint grain against banding |
| glow | green600 | `Theme.glow()`: the home screen and the giant phone's own screen; fades to the page by 52% of the height, mixed in OKLab |

- Thresholds (APCA |Lc| / WCAG): body 75 / 4.5, labels 60 / 4.5, large text 45 / 3, UI parts 30 / 3. Fix failures by lightness only, holding hue and chroma. Increase Contrast moves each muted role 15+ points of lightness further from the page.
- **Green means growth, and is the brand** (merged with "gain"); light (the spotlight, the glow) is its only decorative use. Never use green for anything else.
- Neutrals carry a trace of the brand hue (160°, chroma ≤ 0.012). Steps sit closer at the light end, where text lives. Primitives nothing uses are removed.
- **Reserved for later features**, added in OKLCH when first used: target (yellow), muscle (red; never losses or bodyweight), past (blue).

### 9.3 Type
- **Typeface: under review.** Release builds use **Geist** (SIL OFL); the owner finds it too technical. Debug builds switch between five sans-serif candidates (`TypeScale.Family`, picker at the bottom of the onboarding, `-TrackoFont <name>`): **Satoshi** (modern grotesk, geometric bones), **Figtree** (friendly geometric, plain), **Outfit** (pure geometric, round), **Rubik** (softly rounded corners, sporty), **Bricolage Grotesque** (quirky grotesque with ink traps). To pick one, set `TypeScale.Family.default` and delete `Onboarding/Variants/`.
- Fonts live in `DesignSystem/Fonts/` (four faces each: regular, semibold, bold, extra bold) and `Fonts.register()` registers them all at launch. The Google Fonts families are SIL OFL, each with its `<Family>-OFL.txt`. **Satoshi** (Fontshare, ITF Free Font License) may be embedded in the app but not redistributed, and this repo is public: it's never committed. `scripts/fetch-fonts.sh` downloads it (git-ignored), and CI runs it before building. Satoshi has no 600 or 800, so Medium and Black stand in.
- `TypeScale.family` is observable: views resolve font names as they draw, so switching it redraws in place.
- **Scale (`TypeScale`, Dynamic Type):** wordmark 52 ExtraBold, −3.5% · intro 24 SemiBold · headline 34 Bold, −2%, line height 1.1 · body 17 Regular, line height 1.45 · button 17 SemiBold.
- **Headlines and sublines use `BalancedText`** (a UILabel bridge): it sets the line height (SwiftUI on iOS 17 can't go below a font's own, about 1.3) and balances the lines like CSS `text-wrap: balance`, so two-line headlines split evenly and nothing ends on one short word.
- **Bold Text** steps every face up one weight (`TypeScale.Weight.resolved`).
- Keep short values on one line with `.keptTogether` (non-breaking spaces): "8 × 12, 11, 10".
- Text inside an illustration (the hero phone) uses fixed sizes via `TypeScale.illustration`, laid out near its drawn size (140 pt wide) so nothing renders below ~8 pt; the illustration carries a VoiceOver label instead.
- `.monospacedDigit()` on changing numbers. No monospace labels, no all-caps eyebrows. Curly quotes and the true × and − signs.

### 9.4 Motion
- One orchestrated moment per scene; everything else still.
- Springs for things that settle (`spring(duration: 0.55, bounce: 0.22)`), snappy for UI feedback, long soft spring for growing bars.
- Numbers roll with `.contentTransition(.numericText(value:))`.
- Honest motion: growth curves slow down over time.
- **Reduce Motion:** jump to the final frame (or crossfade). Every page must handle it.
- Buttons scale to 0.96 when pressed, eased out over 150 ms (`Motion.press`). The light fades in once when the app opens.
- **First launch enters in stages** (`.entrance(step)`): logo, hero, words, dots, button, 100 ms apart, each rising 12 pt out of a 4 pt blur; with Reduce Motion they only fade. Never stagger routine changes.
- Each onboarding page has one moment: its phone screen's script.

### 9.5 Haptics (`.sensoryFeedback`)
- Set logged → `.impact(weight: .light)`
- Target beaten / verdict revealed → `.success`
- Slider and option changes → `.selection`

### 9.6 Accessibility
Dynamic Type for all non-score text; VoiceOver labels describe what an animation shows (each hero is one image element with a description built from the demo numbers); decorative pieces `accessibilityHidden`; tap targets ≥ 44 pt (the pill is 48); never rely on colour alone (the current page dot is also longer). Page dots are adjustable for VoiceOver; each hero has a "Replay animation" action. At the largest text sizes an onboarding page scrolls rather than clipping (`ViewThatFits`). Decorative layers (light, grain) take no touches. CI screenshots every page with Increase Contrast, and at the largest accessibility text size in every candidate typeface.

### 9.7 Characters
Two chibi characters, female and male, carry the story. Idle expressions (blinks; a laugh easing into a smile) cut between extra renders (`-open`, `-blink`), only on the active page and never with Reduce Motion. **v0.2 look** (owner: "polish it more like the Any Distance mascot"): glossy vinyl-toy finish, black-and-white colour blocking with brand-green details (she: white top, black leggings, green hair tie; he: black top, white shorts, white cap with a green badge), big glossy eyes with a white rim, thumbs, chunky sneakers on a green midsole. Both come from one recipe (`characters/build/tracko_characters.py`), so any pose works for both; expressions swap rather than morph; numbers are drawn by the app, never baked into a render.

**Onboarding heroes** (`render_all.py heroes`): one shared camera and platform, so the stage holds still as pages swipe. Matched to 006: the platform spans 82% of the screen width, the phone 32% (about 2:1, centred), the camera sits ~5° above the platform and frames with lens shift; platform top ≈ rgb(31,31,37), side ≈ rgb(10,10,15), phone frame ≈ rgb(20,19,20). The pipeline writes the PNGs into `Assets.xcassets/Onboarding/` and the phone-screen rectangles into `Onboarding/HeroRender.swift`.

---

## 10. Engineering

- **Platform:** iOS 17+, SwiftUI, Observation (`@Observable`). Dark appearance for now.
- **Dependencies:** none yet. Rive is the candidate for the living body (state machine for grow/lean).
- **Structure:**
  ```
  Tracko/
    App/            TrackoApp, HomePlaceholderView
    Core/           LiftMath (formulas, units)
    DesignSystem/   OKLCH, Theme (Palette, Theme, TypeScale, Space, Radius, Motion), Components, Fonts (+ font files)
    Onboarding/     OnboardingModel, OnboardingFlowView, OnboardingPageView, OnboardingHero, Hero, Spotlight,
                    PhoneScreens, HeroRender (generated), Script, DemoContent
                    Variants/ (Debug only: the typeface picker, deleted once one is chosen)
  scripts/          fetch-fonts.sh (Satoshi, which can't be committed)
    Assets.xcassets/Onboarding/   hero renders (generated)
  TrackoTests/      LiftMathTests (§7 examples), ColorTests (gamut, contrast), DemoContentTests
  ```
- **Project:** `Tracko.xcodeproj` (Xcode 16+) uses synchronized folders: files added under `Tracko/` or `TrackoTests/` join their target automatically, so never hand-edit the project for a new file. Swift 5 language mode, iPhone only, portrait. Bundle ID `com.bimanshu.tracko`.
- **CI:** `.github/workflows/ios.yml` runs on every push that touches the app: builds, runs the tests, then launches each onboarding scene on an iPhone Pro and an iPhone SE simulator and uploads screenshots (plus a contact sheet per device) as the `screenshots` artifact. The JPEGs are also force-pushed to the `ci-screenshots` branch (`git fetch origin ci-screenshots`), which cloud sessions can read when the artifact host is blocked. Check both after every change; cloud sessions can't compile locally.
- **Running on a phone:** steps in `README.md` (Xcode + free Apple ID, 7-day expiry).
- **Debug launch arguments:** `-TrackoStartScene <0–3>` opens onboarding on that page; `-TrackoFont <satoshi|figtree|outfit|rubik|bricolage>` picks the typeface (both used by CI screenshots).
- **Generated files:** `HeroRender.swift` and the hero PNGs come from `python3 characters/build/render_all.py heroes` (Blender 4.5). Re-render rather than edit them.
- **Conventions:**
  - Scripted animations: `@MainActor func play() async` driven by `.task(id: ScriptRun(isActive:replay:))`, steps separated by `guard await Script.wait(x) else { return }` so leaving a page cancels and rewinds cleanly. Tap a hero to replay.
  - Every page: works with Reduce Motion, has a `#Preview`, takes data from `DemoContent` (localized units), no hard-coded maths (call `LiftMath`).
  - Colours, fonts, spacing and animations only via `Theme`, `TypeScale`, `Space`, `Radius`, `Motion`. New colours go into `Palette` in OKLCH first.
  - Unit-test every formula with the reference examples in §7.

---

## 11. Onboarding spec

### Why onboarding exists
1. **Set the mental model:** "I log once, it does the maths and talks back."
2. **Show the payoff before asking for anything:** a verdict, a number to beat, growth over time.

Getting the "before" (notes import or one baseline lift) and the first win now happen in the app's first run, not in onboarding (owner's decision, 2026-10-14: at most 4 screens).

### The one message
**Your log talks back**, in three beats: you already do the work → we do the maths → you watch yourself change.

### Pages (layout from 005/006)
Logo capsule on top; hero full width under the spotlight, which holds still as pages swipe and follows the hero when it shrinks or scrolls (`HeroSpot`); two-line headline (≤ 7 words) and one subline; page dots; a light pill button ("Continue", then "Start tracking"). Pages swipe; the logo, dots and button stay put.

| # | Page | Hero | Phone screen moment | Words |
|---|---|---|---|---|
| 1 | Welcome | Both characters wave on the stand | – (the light comes up) | "Welcome to Tracko" / "The gym log that talks back." |
| 2 | Log it like a note | She reaches for the giant phone; surprised → happy | "8 × 12, 11, 10" types in, Monday appears, +10% counts up with the reason | "Log it like a note" / "Type 8 × 12, 11, 10 and Tracko does the maths." |
| 3 | Number to beat | He does lateral raises; effort → happy | Two sets fill a bar toward Thursday's line; "10 reps ties Thursday. 11 beats it."; the last set beats it; +3% | "Always know the number to beat" / "Every lift opens with what beats last time." |
| 4 | Get stronger | Both celebrate | The honest curve draws over 12 weeks; +25% | "Watch yourself get stronger" / "Proof you're growing, week by week." |

### Onboarding rules
- One idea per page; the hero and its phone screen carry the explanation.
- At most four pages. Ask for nothing here: goal, notes import and permissions belong to the first run, each asked when it makes sense (Health when choosing "Lose fat", notifications when promising the Wrapped, Photos when importing).
- Numbers on the phone come from `DemoContent` and `LiftMath`, in the user's units.

### Onboarding metrics
Onboarding completion (reaching page 4 and tapping Start tracking); time on each page; then, in the first run: share reaching a first verdict or baseline, notes-import completion, notification opt-in; day-7 retention.

---

## 12. Open questions to validate
1. Why do notebook lifters stay on paper when Hevy is free? (20 US/UK interviews)
2. Will ≥5% pay ≈ $40/yr? (pricing page + trial before the product exists)
3. Is notes import the "wow" moment? (parse 30 real logs, watch reactions)
4. Do people share their Wrapped? (hand-made cards; do they post?)
5. Does "+5% for your size" motivate people on a cut?

---

## 13. Changelog (newest first)
- **2026-10-15 · v0.2.2** Spotlight promoted from the onboarding variants (owner's pick over Stage and Window): a green beam onto the platform and a pool around the figures replace the glow from the top, and the characters blink and smile on the active page. New `spotlight` role. Typeface round started: Geist reads too technical, so Debug builds compare Satoshi, Figtree, Outfit, Rubik and Bricolage Grotesque; `TypeScale.family` is observable. Satoshi is fetched by `scripts/fetch-fonts.sh`, never committed (licence).
- **2026-10-14 · v0.2.1** Polish pass against the better-* skills: role tokens used only in their role, every colour pair passing APCA as well as WCAG in standard and Increase Contrast, grain against banding; balanced 1.1 headlines (BalancedText), Bold Text, kept-together values, larger phone-screen text and a simpler beat screen; optical button padding, 150 ms press, staged first-launch entrance; VoiceOver replay action; CI screenshots for Increase Contrast and the largest text size.
- **2026-10-14 · v0.2** Onboarding rebuilt in the style of the priority-1 reference (Any Distance, 005/006) at the owner's direction: 4 pages, 3D heroes with live phone screens, near-black canvas with a soft green glow, light pill button. Green is now the brand colour (merging "gain"). Colour tokens moved to OKLCH (Display P3), type to Geist. Characters v0.2 (vinyl-toy finish). Goal, history and the notification ask moved out of onboarding. The nine v0.1 scenes and the shape body figure were removed (see git history before 7d2a7e5).
- **2026-10-02** Characters v0.1: female and male clay chibis built in Blender from one script, character sheets, and an 8 s "gym log" clip (transparent master + preview). Added §9.7.
- **2026-10-02** Started the UI reference library (`design/references/`) ahead of a big visual polish pass; skill §9.0 points to it.
- **2026-10-02 · v0.1 code** Xcode project (synchronized folders), all nine onboarding scenes, LiftMath + tests, CI that builds, tests and screenshots every scene. Scenes 5, 6 and 9 built (were placeholders). Runs on device via Xcode.
- **2026-10-02 · v0.1** Created this skill. Onboarding foundation in SwiftUI: tokens, components, body figure, LiftMath + tests, flow container (progress, back, skip), scenes 1–4 and 7 built, scene 8 choice only, scenes 5, 6, 9 as placeholders.
