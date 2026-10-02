# UI reference library

Screenshots from other apps and sites that set the bar for how Tracko should look and feel. Every UI change should be able to point at a reference here, or at a pattern below.

## How it works

- **Adding references:** send screenshots in a Claude session, with a line on what you like if you have one, or upload them to `inbox/` on GitHub. Claude files each one as `NNN-source-subject.png`, writes an entry below, and empties the inbox.
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

_None yet._

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
