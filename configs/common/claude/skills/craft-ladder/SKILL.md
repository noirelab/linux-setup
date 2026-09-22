---
name: craft-ladder
description: Diagnose how finished an interface actually is by placing it on a measured four-level craft ladder, then name the specific move that raises it one level. Use when a UI "looks fine but cheap", when a landing page or dashboard needs to go from acceptable to convincing, when reviewing generated or vibe-coded UI, when deciding what to fix first on a screen, or when someone asks why their design looks amateur. Levels and thresholds come from measured evidence, not taste; see reference/evidence.md.
---

# The craft ladder

Most interfaces are not broken. They are unfinished, and stop at a level their
author cannot see. This skill locates that level and names the next move.

The ladder comes from a design file containing the same landing page built
four times at four levels of craft, and is confirmed against twenty-one other
files. Every threshold below is a number measured off those files.
`reference/evidence.md` carries the raw measurements, per file, with sources.

## Diagnose first

Do not start fixing. Place the screen on the ladder, because the fix at L1 is
worthless at L3 and vice versa.

**Answer from the rendered pixels, not from the source.** A declaration in the
stylesheet is not evidence that anything reaches the screen. This is not a
technicality: a review using this skill once answered question 1 "yes" about a
page whose entire product mockup rendered invisible, because the markup was
present and the reviewer never checked the shot. Render the page, look at it,
and where source and screen disagree, the screen wins.

Then answer these in order. The first "no" is the level.

1. **Is the product visible in the shot you just took?** Not an illustration of
   it, not a stock photo, not a generic gradient blob. The real interface, real
   data, real numbers. Confirm it twice: in the normal render, and in a render
   with the `<script>` blocks stripped out. Reveal animations gated on
   `opacity: 0` plus an `IntersectionObserver` never fire for a renderer that
   loads the page at full height and never scrolls, which is how most
   screenshot tooling works.
2. **Does anything sit above the surface?** Any shadow, any blur, any border
   under 1px, any layering that says one thing is nearer than another. Check
   the rule is reached: a shadow behind a dead selector or a `.js` guard is a
   rule, not depth.
3. **Does color mean something?** A green that only appears on success, a red
   only on failure, an amber only on warning. Not a palette, a vocabulary. A
   token declared and never referenced is not part of the vocabulary; grep for
   its uses before counting it.
4. **Do things respond?** Hover, focus, press, empty, loading, error. A state
   that exists in code but was never designed does not count.

Zero yes = L1. One = L2. Two or three = L3. Four = L4.

Two capture traps, both of which have produced wrong answers here. Chromium
ignores `--disable-javascript` silently, and
`--blink-settings=scriptEnabled=false` makes `--screenshot` write no file at
all, so to see the no-JS render, delete the `<script>` blocks from a copy and
shoot that instead. And a very tall `--window-size` changes which elements an
`IntersectionObserver` treats as visible, so shoot at a real viewport
(1440x900) as well as at full height.

## L1: it exists

**Signature, measured:** 95 nodes for a full landing page. Headline 32px.
Body 20px. Borders 2px. Padding 80 / 20 / 10, gaps 59 / 24 / 10, all
round numbers, all arbitrary. Radii only 18 and 100. Four Pexels stock
photos and nothing else visual.

L1 is a layout, correctly assembled, that shows the reader nothing. The copy
is a feature list in sentence form: *"With Linkd you can track clicks to
links, revenue attribution, filter bots, A/B route traffic. You can also
connect custom domain names, and password protect any page you wish with just
one setting!"* Everything is stated and nothing is shown.

**The move to L2: replace every stock photo with the product.** This is the
single highest-value change in the entire ladder. In the source file the four
Pexels images disappear at L2 and the actual dashboard appears, drawn in
full, 2151 nodes of it. Ship a screenshot of the real thing before you touch
anything else. Do not proceed down this list until the product is on screen.

The one licensed exception: bespoke illustration, drawn for this product,
carrying the hero on purpose. `Kill boring designs.fig` does exactly that with
hand-drawn vector marks at 0.2 to 3.83px stroke, and it works. A stock
illustration from a pack is not that, and neither is a gradient blob.

## L2: it shows the product

**Signature, measured:** node count jumps 95 to 3550. Headline 40px. Drop
shadows appear (`0 1px 2px rgba(0,0,0,.05)`) and a `background_blur` of 21.
Border widths leave the integers: 0.88, 0.92, 1.07. Radii leave them too:
8.6, 7.2, 6.1, 5.5. Copy tightens to one sentence: *"Real-time click
tracking, revenue attribution, bot filtering, and A/B routing."*

Depth arrives at L2. Not decoration: a shadow is the claim that a card is
nearer than the page, and until something makes that claim every element is
equally flat and equally ignorable.

Two calibrations for that first shadow, both measured:

- **The beginner shadow is tight and dark.** `0 4px 4px rgba(0,0,0,.35)` is
  what appears in the "before" of a beginner file. The same file's "after"
  keeps it but adds `0 0 30px #D4D4D4`, a wide soft ambient. Tight-and-dark
  alone reads as a drop shadow filter; wide-and-soft reads as light.
- **Shadows may be tinted, and good ones often are.** Measured across the
  corpus: `#EBEBEB`, `#B7B7B7`, `#828282@0.15`, `#0F0843@0.04`,
  `#3826C1@0.07`. Black at low alpha is the safe default, not the only one.

**The moves to L3:**

- **Sharpen the headline until it is a claim, not a description.** Measured
  progression across the four levels: "Track your links with Linkd for better
  results." (32px) then "The smarter way to share links" (40px) then "Know
  Where Every Click Goes" (56px) then "Stop Guessing, Start Tracking" (56px).
  Copy gets shorter as type gets bigger. Those move together, always.
- **Widen the type scale.** L1 runs 16/18/20/24/32, a six-point spread doing
  all the work. L3 runs 10/12/13/16/18/20/36/56. Small text gets smaller so
  large text can get larger without shouting.
- **Give color a job.** L3 introduces exactly three semantic hues and uses
  them nowhere else: `#04C40A` success, `#FF4949` failure, `#FFCB49` warning.
- **Assign roles to typefaces, do not collect them.** Two files land on the
  same answer independently: a serif for display only, a sans for everything
  else. New York at 18/25/34/35/36px over Axiforma at 12/14/16px; New York
  at 24/52.7px over Manrope at 12/13/14/16/18px. One face never does both
  jobs, and a third face never appears.

## L3: it reads and it means

**Signature, measured:** headline 56px. Feature blocks are 18px title over
16px body, repeated three times. Semantic color in place. Neutral ramp doing
the rest of the work.

L3 is the level most competent work stops at, and it is genuinely fine. What
separates it from L4 is not polish. It is that L3 shows a product and L4
shows a product being used.

**The moves to L4:**

- **Design the states, all of them, with real copy.** This is the largest
  measurable gap in the corpus and it is worth its own section below.
- **Add a second surface above the page.** Menus and overlays sit on
  `#131313` over a `#0D0D0D` page, a 6-point lift, edged with a
  `#171717` transparent-to-80% gradient rather than a border, plus a
  `foreground_blur` of 20.
- **Pair every data hue with its own dark tint.** L4 uses `#FD61B2` on
  `#3C0D26`, `#876AFF` on `#2C234F`, `#009E18` on `#173B1F`. One accent per
  series, each with a background mixed from itself. Never a hue on a shared
  neutral chip. The light-mode form of the same rule: a pale tint fill with
  saturated text of the same hue, measured as `#BCFFC9` fill with `#149610`
  text, `#FFEEBC` with amber, `#CDD1FF` with `#3C3E5D`.
- **Show proof and show mechanism.** GDPR, SOC2, ISO 27001 badges. A real
  code sample with the actual import. A customer timeline with timestamps,
  country and browser. Specific beats impressive.
- **Let the display type break its own scale.** 56px goes to 70px on the
  final hero. One size, once, on the single most important line.

## L4: it is used

**Signature, measured:** 3367 nodes. Every hover, menu and modal drawn.
Multi-hue data palette with paired tints. Proof and mechanism on the page.

## States are the work

Counted across the animation files, hover is designed more often than click:
ON_HOVER 28, ON_CLICK 20. But the states that separate L3 from L4 are the
ones nobody screenshots. Three complete examples, measured:

**A connect flow, four states, all drawn.** Idle list of integrations, then a
requirements checklist ("Notion account / Notion database / Workspace
access"), then in-progress with an amber `#FFB20C` edge and the copy
*"Connecting to Notion... Please wait while we authenticate your account and
set up the integration"*, then success: *"Notion is now connected! You can
manage integration settings anytime in the Integrations panel."* plus a
`Manage settings` action. The success state tells you where the thing lives
afterwards. That sentence is the whole difference.

**An update event, three outcomes, all drawn.** Success (*"Update installed!
v4.3"*), failure (*"Update failed to install. Please retry or contact us for
support. Ensure cookies are enabled."* with `Help center` and `Retry`), and
partial (*"Some projects are incompatible. If projects are incompatible,
we'll try opening in legacy mode."* with `Learn more`). Most work ships the
success frame only.

**An empty state that keeps its chrome.** 90 nodes against 170 populated. The
sidebar, search, filter and primary action all stay; only the content region
empties, and it carries *"No applicants yet"* over *"Start posting job
listings to start receiving applications"* plus `Learn more`. An empty state
that strips the navigation is a different screen, not an empty state.

Also worth stealing: a destructive action gets a color nothing else uses
(`#FF2222` / `#FF4538`, appearing exactly once each in their files), and a
long-press menu is a designed surface (`Pin / Lock / Share / Note History /
Delete` behind `background_blur 70` and `0 -8px 40px rgba(0,0,0,.70)`).

## The measured failures

Five ways work falls off the ladder, each taken from a file built to
demonstrate it.

**Rainbow accents.** The same screen appears three times, correct in light
(`#F7F6F9` page, `#070723` text, one `#5D51E4` accent), correct in dark
(`#050505` page, `#111112` surface, `#D1D1D1` text, `#2E2E2E` borders), and
ruined: a gradient page background under eight unrelated saturated accents
(`#AF3DFF #FF3B94 #A6FD29 #F66E35 #75DDFF #52CD91 #ED676A #FD8A5A`), a
`#FF0000` border and a `#77FF00` fill. Nothing else changed. Layout, spacing
and type are identical in all three. Color alone did it.

Note the dark version: text is `#D1D1D1`, not white, on `#050505`, not black.
Pure white on pure black is the amateur tell.

**One weight everywhere.** A dashboard redesign, before and after. Before:
PingFang SC Semibold at fourteen different sizes and no other weight, no auto
layout anywhere, and labels that lost their spaces (`Totalpaid`,
`HRmanagement`, `Businessplans`). After: Regular, Medium and Semibold in
play, auto layout with 5 and 10 gaps, spacing restored, and, decisively, more
information rather than less: axis labels, year-over-year deltas
(`+36%` `-2%` `+26%` `+17%`), the cents split off at half size
(`$46,724` at 26px with `.67` at 14px). Density read as craft, not clutter.

**Typeface sprawl and flattened navigation.** An e-commerce original runs
three families (Inter Semi Bold at nine sizes, Space Grotesk, Neue Machina),
four unrelated pastels (`#FFA200 #CAEEB4 #CCB6EF #F5F1FA`), and a single
undifferentiated row of thirteen all-caps links mixing navigation, account
actions and social (`HOME FAVOURITE CART PROFILE NOTIFICATION ABOUT
COLLECTION FACEBOOK FEATURES INSTAGRAM REVIEW TWITTER-X YOUTUBE`). The
redesign keeps two faces with assigned roles, collapses to one warm neutral
plus one accent, and separates the three kinds of link.

**Vibe-coded uniformity.** Generated UI has a fingerprint: Roboto or Inter at
12px for nearly everything, one muted blue-grey (`#A0A8C0`) doing every
non-primary job, radii of 4 and 6 and nothing else, zero designed states, and
placeholder strings left in the output (`variant / 1` through `variant / 14`,
`default`, `hover` as literal labels). It is L1 wearing L2 clothes. Treat it
as L1 and start at the product.

**Uniform stroke weight.** Border width is a style declaration, not a
default. Measured range across the corpus: 0.22px hairlines in a dense
dashboard, 0.44 to 1.75 in clean SaaS, 2.86 to 4.25 on a bold marketing page,
5.46 to 10.78 in illustration-led work, 12.28 on one deliberate accent. A
file where every stroke is 1px has not chosen anything.

## Recipes worth copying verbatim

These recurred with the same numbers in more than one file, which is why they
are here rather than in the evidence.

**Glass surface**, appearing identically in two unrelated files:

```css
background: linear-gradient(rgb(255 255 255 / .12), rgb(255 255 255 / .04));
border: 1px solid;
border-image: linear-gradient(rgb(255 255 255 / .14), rgb(255 255 255 / .03));
/* plus a specular pass: linear-gradient(rgb(255 255 255 / .60), rgb(255 255 255 / .04)) */
backdrop-filter: blur(16px);   /* 4 to 24 in the source files, 70 for a sheet */
```

**One radius, dominant.** In a six-frame dashboard, radius 6 accounts for 80
of the corners; everything else (7.8, 9.3, 5.1) is the same components at
other scales. Pick one, use it for nearly everything, and reserve the pill
(100) for chips and avatars.

**Everything scales together.** The same design at five sizes moves type
11.3 to 13.1px, radius 4.5 to 5.2, **and border 1.13 to 1.31**. Scaling type
while leaving borders at 1px is the tell that no system exists. Padding is
the exception: measured across one card at four viewports, padding stays 8
and 16 at every size while gaps grow from 2/8 to 44/48.

**Re-themeable card.** Four variants, geometry byte-identical (radii 50/15,
gaps 40/25/5, padding 10/30/25/15/50, type 45/30/25px), differing only in a
three-stop near-black page gradient plus one bright accent plus one shared
`#7E8FA0` muted: `#04C4BC` teal, `#8897FF` indigo, `#DDA9F0` orchid,
`#05BB3D` green. That is what a theme is.

## Motion, when you get there

Motion is an L4 concern. Do not animate an L2 screen; you will be polishing a
page that still shows a stock photo.

The measured vocabulary, from three animation files, 89 transitions:

- **Default ease:** `cubic-bezier(0, 0, 0.58, 1)`. 51 of 89.
- **Paired directional ease:** leaving uses `cubic-bezier(0.8, 0, 1, 1)`,
  arriving uses `cubic-bezier(0, 0, 0.2, 1)`. Accelerate out, decelerate in.
  Full traversals use `cubic-bezier(0.8, 0, 0.2, 1)`.
- **Durations:** 0.15 / 0.25 / 0.30s for feedback, 0.70 to 1.0s for a scene
  change. Above 1s only for ambient loops.
- **Springs, for hover only:** mass 1, stiffness 300 to 837, damping 20 to 40.
  Stiffer springs get more damping, never less.
- **What actually moves:** x 43, y 37, scale 10, rotation 9, width 5,
  opacity 3, height 3. Animate transforms. Animating width or height is a
  layout thrash and the files avoid it almost entirely.
- **A moved item scales up in transit.** In a drag-between-lists sequence the
  travelling row goes 18px to 19.8px type, a 1.1x lift, and settles back.
- **Let the surface carry the data.** In a swipeable card deck the card's own
  background gradient changes with sentiment: `#8F8F8F@0.25` fading out for
  neutral, `#6CF979` fading out for bullish. The chart is not the only thing
  allowed to encode a value.

## Applying this

When asked to review, give the level, the evidence for that level, and the
one move. Not a list of twelve things. The ladder is sequential because the
lower fix makes the higher one visible, and doing them out of order wastes
the work.

When asked to build, build to the level the task deserves and say which level
you built to and what L4 would have added. A named gap beats a silent one.

**The numbers are calibration, not a palette.** Almost everything measured here
is a ratio, a count or a relationship: how far the type scale spreads, how many
stroke weights exist, whether a hue has a job. Those transfer. The literal hex
values do not, and lifting them lands you in somebody else's brand. This has
already happened: a page built with this skill shipped `#173B1F` and `#3A2A0F`
straight out of `reference/evidence.md`, which are the tint values from one
link-shortener's dark theme and had nothing to do with the product being built.
The one section that does invite literal reuse says so in its heading; treat
everything else as a measuring stick.

Two things stay true at every level and are not tradeable: the product must
be visible, and any state a user can reach must have been designed.
