# Measured evidence

Every number in SKILL.md comes from here. Source: 22 Figma community files,
parsed directly from the `.fig` container. Extraction date 2026-08-19. All 22
were read; each has a section below saying what it contributed.

Read this file when a threshold in SKILL.md needs backing, when a number
looks wrong, or when adapting the ladder to a different product surface.

---

# 1. The ladder source

## `4 levels.fig`

One landing page for a link-shortener, built four times. Same product, same
sections, four levels of craft. The only file in the corpus that isolates
craft as the single variable, and the origin of the whole ladder.

| | L1 | L2 | L3 | L4 |
|---|---|---|---|---|
| nodes | 95 | 3550 | 881 | 3367 |
| page height | 3656 | 4472 | 4472 | 4472 |
| headline | 32px | 40px | 56px | 56px, 70px on final hero |
| type scale | 16/18/20/24/32 | 9.2/11/12/12.1/16/20/24 | 9/10.3/11.5/13/15.2/16/18/36/56 | 7.5/9/9.3/10/10.3/11.5/12/13/14/16/36/56 |
| border widths | 2.0 only | 0.88, 0.92, 0.99, 1.07, 1.25 | 0.88, 0.97, 1.09, 1.15, 1.34 | 0.62, 0.64, 0.75, 0.88, 1.0, 1.25 |
| radii | 18, 100 | 4.7, 5.5, 6.1, 7.2, 8.6, 9, 10, 10.5, 16, 18.4 | 4.8, 5, 6.8, 7.5, 8, 9, 11.6, 12, 16, 100 | 3, 4, 4.5, 5, 5.4, 8, 9, 12, 16, 20 |
| padding | 10, 20, 80 | 3.5, 4.6, 5.3, 5.5, 6.4, 7, 8, 10, 11, 12 | 1, 3, 3.9, 5.8, 7.8, 8, 8.1, 12, 13.8, 15 | 1, 2.6, 3, 3.9, 4, 10, 12, 15, 16, 24 |
| gaps | 6, 7, 10, 24, 30, 59 | 3.7, 5.5, 6, 7, 7.4, 8.8, 9.2, 10, 10.1, 24 | 4.6, 5.2, 6, 6.9, 7, 7.8, 9.7, 10, 12, 12.6 | 2, 4, 5.1, 5.2, 5.3, 6, 7, 7.1, 10, 12 |
| shadows | none | 6 kinds, incl. `0 1px 2px rgba(0,0,0,.05)` and a 4-layer purple stack | 1 kind | 7 kinds |
| blurs | none | background_blur 21.0, 15.8 | none | foreground_blur 20 (hover frame) |
| images | 4 Pexels stock photos + 1 | 22, product UI drawn as vectors | 12 | 20 |

Page background is `#0D0D0D` at every level. The ladder is not a re-skin.

**The four Level 1 images, by node name:** `pexels-mart-production-7255727 1`,
`pexels-canvastudio-3153204 1`, `pexels-eye4dtail-792034 1`,
`pexels-ivan-s-8117466 1`, plus `image 184`. They are the entire visual
content of L1. From L2 on, the product itself is drawn: the 2151 `#404040`
nodes in L2 and L4 are one chart.

**Headline copy, verbatim:**

- L1, 32px: "Track your links with Linkd for better results."
- L2, 40px: "The smarter way to share links"
- L3, 56px: "Know Where Every Click Goes"
- L4, 56px: "Stop Guessing, Start Tracking"
- L4 hover frame, 70px: same line, larger

Subheads shrink in step: L1 runs 46 words, L4 runs 11 ("From first click to
final conversion, never miss a thing.").

**L4 exclusive elements:** mega menus at 971x325 and 978x325 on `#131313`
over `#0D0D0D`, edged with `grad-linear(#171717@0.00 > #171717@0.80)`; a
1801x1068 hover frame with `foreground_blur 20`; data hues with paired dark
tints `#FD61B2`/`#3C0D26`, `#876AFF`/`#2C234F`, `#009E18`/`#173B1F`, plus
`#1480FF`, `#FF751F`, `#541FFF`; a GDPR / SOC2 / ISO 27001 trust row; a live
code sample from `import { Linkd } from "linkd"` to
`linkd.links.analytics({ linkId, period: "30d" })`; and a customer timeline
of Subscribed / Signed up / Clicked with timestamp, `country: UK`,
`browser: Chrome`.

---

# 2. The failure files

## `Colors That Ruin.fig`

Same 390x844 screen, three palettes. Layout, spacing and type identical in
all three: the font stack `SF Pro Regular 12px x22, 13px x6, Medium 14px x4,
Medium 20px x1` and the radii `4 x32, 10 x18, 40 x10` are byte-identical
across variants.

| | light | dark | ruined |
|---|---|---|---|
| page | `#F7F6F9` | `#050505` | `grad-linear(#FEEB9D > #988D5E)` |
| surface | `#FFFFFF` | `#111112` | `#FFFFFF` |
| text | `#070723` | `#D1D1D1` | `#000000` |
| muted | `#727270` | `#727270` | `#727270` |
| border | `#EEEEEE` | `#2E2E2E` | `#EEEEEE`, `#000000`, `#FF0000` |
| accent | `#5D51E4` | `#5B50DC` | `#AF3DFF #FF3B94 #A6FD29 #F66E35 #75DDFF #52CD91 #ED676A #FD8A5A #77FF00` |

The dark variant never uses `#FFFFFF` for body text or `#000000` for the page.

## `Financial Dashboard.fig`

`Original Design` (289 nodes) against `Kole's Redesign` (376 nodes), both
1440x1023 on `#000000`.

Before: PingFang SC **Semibold at all 14 sizes present**, no other weight; no
auto layout at all (zero gap and zero padding values in the file); copy with
lost spaces (`Totalpaid`, `HRmanagement`, `Businessplans`,
`WalletVerification`); bare numbers (`43.20`, `$ 16,073.49` with no
comparison).

After: Regular, Medium and Semibold all in use; auto layout present with gaps
5 and 10, padding 5 and 10; copy fixed; a neutral ramp added
(`#B4B4B4 #E4E4E4 #D9D9D9 #464646 #252525`); sub-pixel borders 0.44, 1.07,
1.43; pill radius usage tripled (`100` x14 becomes x36); and information
**added**, not removed: chart axis labels (`1k 2k 3k`, `15 22 29`),
year-over-year deltas (`+36% -2% +26% +17%` under `Y/Y`), cents split at half
size (`$46,724` 26px + `.67` 14px), task metadata (`Deadline`, `Status`,
`Urgent`, `Non-urgent`), and named comparisons (`Remaining Credit` against
`Amount Borrowed`).

## `Skincare Redesign.fig`

An imported original against a redesign, both 1440 wide.

Original (`Figma design - original-…webp`, 78 nodes, `#FFFFFF`): three
families, Inter Semi Bold at nine sizes (9.4 to 15.7) plus Space Grotesk
(15.4 / 15.7 / 24.3 / 46.1) plus Neue Machina (27 / 73.3); four unrelated
pastels `#FFA200 #CAEEB4 #CCB6EF #F5F1FA`; a 73.3px display line; and one
flat row of thirteen all-caps links mixing navigation, account and social:
`HOME FAVOURITE CART PROFILE NOTIFICATION ABOUT COLLECTION FACEBOOK FEATURES
INSTAGRAM REVIEW TWITTER-X YOUTUBE`.

Redesign (`Mockup`, 133 nodes, `#F8F8F8`): two families with assigned roles,
New York (serif) for display only at 24 and 52.7px, Manrope for everything
else at 12/13/14/16/18px; palette collapses to `#F8F8F8` page, `#000000`,
`#26190C` warm brown, one `#DFEAB6` accent; radii become a system
(30 x20, 100 x18, 30.3, 30.4, 32.5); product cards carry real spec
(`Skin Serum / Salicylic acid mix / 10ml / $28.60`).

## `Vibe Coding Results.fig` and `Vibe Coded SaaS.fig`

Fingerprint of the imported vibe-coded dashboard: Roboto Regular 12px x27
against everything else in single digits; `#A0A8C0` x32, one muted blue-grey
doing every secondary job; radii 4 x34, 6 x18, 12 x12, 16 x10 and nothing
between; no shadows, no blurs, no hover frames; placeholder artifacts left in
(`variant / 1` through `variant / 14`, `default`, `hover` as literal labels).

The refined file fixes it with Geist Medium 14 as the base, a green brand
gradient `grad-linear(#3ECF8E > #228759)`, a 4-layer purple shadow stack
(`0 2.71/0.51 #0F0843@0.04`, `0 7.50/5.66 #4032AB@0.05`,
`0 18.07/24.21 #3624B8@0.05`, `0 59.93/40.29 #3826C1@0.07`),
`background_blur 24`, and a real neutral ramp. Its `Pricing` frame is a
useful reference: `radii 122.2 x56` with `pad 4.9 x112`, four plan columns,
strikethrough prices (`$2 / mo` at 34px over `$10 / mo` at 20px).

## `Beginner UI.fig`

A recipe app, two passes of the same three screens (frames 24/25/26 against
42/43/46), 393x852 on `#F3F3F3`.

Before: `0 4px 4px rgba(0,0,0,.35)` as the only shadow, tight blur and high
alpha. After: keeps it at .25 and .35 but adds `0 0 30px #D4D4D4`, a wide
soft ambient, plus a `grad-linear(#21412F > #5596A6)` brand gradient, a
radius 8 that did not exist, a `Save` action and a promoted search field.

Type pairing throughout: New York (serif) for headings at 18/25/34/35/36px,
Axiforma (sans) for everything else at 12/14/16px. One brand green `#21412F`
on `#F3F3F3`; `#FF2121` used exactly once, on a notification dot.

---

# 3. The state files

## `Sidebar Tutorial.fig`

Not a sidebar tutorial: a command-palette integration flow at roughly 2x
scale, 31 keyframes reducing to 11 unique states. The most complete state
sequence in the corpus.

Quick actions list (`Post a job opening / Search for candidates / Schedule an
interview / Integrations`), then search, then an integration list with real
one-line value copy per item (`Centralize notes, reports, calendars,
databases with Notion`, `Build spreadsheets and automations with Google
Sheets`, `Manage global employment and HR solutions with Remote`, `Create
complex automations and workflows with Zapier`, `HR, payroll and spend all in
one platform with Rippling`), then a requirements checklist (`Notion account
/ Notion database / Workspace access` with a `Connect` action), then
in-progress (`Connecting to Notion... / Please wait while we authenticate
your account and set up the integration`, amber `#FFB20C` edge,
`foreground_blur 24`), then success (`Notion is now connected! / You can
manage integration settings anytime in the Integrations panel.` plus
`Manage settings`).

One shadow token throughout: `0 5.58px 11.15px #EBEBEB`, a light grey tint,
not black at alpha.

## `Design 2025.fig`

One screen and its four states: populated (170 nodes), three modals
(199 / 204 / 197), empty (90). 1440x770.

The modal shadow is a single value in all three modals:
`0 4px 20px rgba(0,0,0,.15)`. One elevation token, not per-modal invention.

The empty state keeps its chrome: sidebar, search, `Display` and
`Create Listing` all remain; only the content region empties, carrying
`No applicants yet` (17px) over `Start posting job listings to start
receiving applications` (17px) plus `Learn more`. Title and body at the same
size, deliberately flattened.

Status chips are pale tint plus saturated same-hue text: `#BCFFC9` and
`#D9F7D7` fills with `#149610`, `#FFEEBC` and `#FFEBBC` amber, `#CDD1FF` with
a `#3C3E5D` border. Required-field markers sit at 8px, the smallest type in
the file on the least important label.

## `Mobile App UI.fig`

A dark note app (`Notely`) on `#141414`, eleven frames, plus its desktop at
1440x1053 on `#101011`.

`glass` is a distinct effect type here, separate from `background_blur`:
glass 3.8, 4, 24, 50 alongside background_blur 16, 64, 70. The glass fill and
border recipe is `grad-linear(#FFFFFF@0.12 > #FFFFFF@0.04)` with a
`grad-linear(#FFFFFF@0.14 > #FFFFFF@0.03)` border and a
`grad-linear(#FFFFFF@0.60 > #FFFFFF@0.04)` specular pass.

Designed empty state (71 nodes against 188): `Get started with Notely` 22px
over `Add notes, calendar events, tasks files and more with the action bar`
16px, with gradient placeholder shapes (`#303030>#262626`, `#3D3D3D>#2E2E2E`).

Long-press context menu: `Pin Note / Lock Note / Share Note / Note History /
Delete`, on `background_blur 70` under `0 -8px 40px rgba(0,0,0,.70)`. A
negative Y offset and heavy alpha, for a sheet rising from the bottom.
Destructive colors `#FF2222` (stroke) and `#FF4538` appear only there.

Mobile to desktop is a re-layout, not a stretch: dark shifts `#141414` to
`#101011`, type 12 to 13px, and the desktop adds a `Good morning, Kole`
greeting at 32px that has no mobile equivalent.

Attachments are shown as real content, not icons: an `IMAGE` tile, a `CODE`
tile containing actual `class ImageSlider extends HTMLElement` source, a
`PDF` tile containing actual prose.

## `Micro-Animations.fig`

50 keyframes, 33 unique. Several distinct scenes.

An update event with all three outcomes drawn: available (`A new update is
avaliable / v4.3 / New calendar view, and kanban mode. Databases with images
will now load faster` with `Skip this update` and `Install now`), installed
(`Update installed!`), failed (`Update failed to install / Please retry or
contact us for support. Ensure cookies are enabled.` with `Help center` and
`Retry`), and partial (`Some projects are incompatible / If projects are
incompatible, we'll try opening in legacy mode.` with `Learn more`).

A shortcut overlay on `#000000` with 60px key caps, whose border is an
animated gradient stepping `grad(#00FFFB > #1C45EC)` then
`grad(#385EF3 > #AA32FF)` then `grad(#A932FF > #FF5A13)` across frames.

An integration hero using `foreground_blur 215.09` and `71.86` for a glow
field, with a mesh drawn as 76 white strokes at 1.08px, and `gap -1.1` for
deliberate overlap.

A design-system callout scene rendering tokens as objects: `Primary-01`,
`Background-03`, `H1 - 65px`, `H4 - 24px`, `Aa`, `button`, `Search` at 27px
on `#F5F5F5`. An import wizard with a three-step progress: `Upload dataset /
Map fields / Confirm fields`.

## `Swipe Anims.fig`

34 keyframes, 23 unique, four separate sequences.

**Onboarding interest picker** on `#FDCEFF` with one `#7924F0` purple: the
45px Manrope SemiBold headline changes per step (`Choose your interests`,
`Local news stories`, `Wider Range Selection`) while the layout holds, and
`skip` sits at 14px.

**Drag between lists**: as each contact moves from `Contact List` to
`Invite List`, `radii 1000` goes x8, x10, x12, x14 and the travelling row's
type goes 18px to 19.8px, a 1.1x lift that settles back.

**Crypto wallet card stack**: three nested radii for three stacked cards
(36 outer, 35 mid, 32 inner), a grey-tinted `4/4 blur10 #828282@0.15` shadow,
and literal affordance labels `Slide To Buy` and `Swipe To Next Token`.

**Swipeable analyst deck**: `5 / 12` counters, `gap -7.3` for an overlapping
avatar stack, and the card's own background gradient encoding sentiment,
`grad(#8F8F8F@0.25 > #FFFFFF@0.00)` neutral against
`grad(#6CF979 > #FFFFFF@0.00)` bullish.

**Dark inbox** on `#2E3033` with `0 -5px 4px rgba(0,0,0,.25)` and the same
glass gradient recipe as `Mobile App UI`, independently.

### Motion, aggregated across the three animation files

89 prototype transitions carrying explicit duration and easing.

| curve | count | role |
|---|---|---|
| `cubic-bezier(0, 0, 0.58, 1)` | 51 | default, ease-out cubic |
| `cubic-bezier(0.8, 0, 1, 1)` | 17 | exit leg, accelerate away |
| `cubic-bezier(0, 0, 0.2, 1)` | 7 | entry leg, decelerate in |
| `linear` | 6 | ambient loops only |
| `cubic-bezier(0.8, 0, 0.2, 1)` | 1 | full traversal |

Springs, all on hover, as `[mass, stiffness, damping, initial velocity]`:
`[1, 300, 20]` (Figma's preset one), `[1, 432, 24]`, `[1, 550, 40]`,
`[1, 636, 24]`, `[1, 720, 29]`, `[1, 835, 39.3]`, `[1, 837, 39.3]`.

Durations, by count: 0.30s x39, 0.25s x11, 0.15s x11, 0.70s x6, 0.80s x4,
1.0s x2, 1.02 to 1.66s x7 (all `GENTLE_SPRING`), 2.5s x1, 4.0s x1 (a linear
ambient loop).

Triggers: ON_HOVER 28, ON_CLICK 20, DRAG throughout `Swipe Anims`,
ON_PRESS 1, ON_KEY_DOWN 1.

Animated properties, by count across all deltas: x 43, y 37, scale 10,
rotation 9, width 5, opacity 3, height 3, corner radius 1.

`AFTER_TIMEOUT 0.001s` appears 18 times: the chaining trick that makes a
prototype run itself. `INSTANT_TRANSITION` handles the invisible reset back
to the loop's first frame.

---

# 4. The system files

## `Software colors.fig`

A real 50 to 950 ramp for `#6449FF`: `#ECEEFF #DDDFFF #C2C5FF #9C9DFF
#7F75FF #6449FF #6136F5 #542AD8 #4425AE #3A2689 #241650`. Linear's neutral
ramp captured alongside: `#FCFCFC #F6F6F6 #F5F5F5 #EDEDED #E8E8E8 #E4E4E6
#D8D8D8 #59595B #2E2E30 #1B1B1B`.

Then a 15237x1950 board (19045 nodes) theming one app light, and a
13982x3322 board theming it dark, from those two ramps alone. Both share the
identical type scale (Axiforma 9 / 10.8 / 11.5 / 11.7 / 11.9 / 12.6 / 13.8 /
15.2 / 16.1, Bold at 11.9 / 15.2 / 19.3) and identical radii (7.1, 8.4, 18.1,
5.4, 9.0, 10.7, 6.9, 23.0, 4.6, 1.8). Theming changes color and nothing else.

## `Dashboard UI.fig`

Six frames of one dashboard: base, plus modal, plus popup, plus chart hover,
plus a link detail page.

`radii 6.0 x80` dominates; 7.8, 9.3 and 5.1 are the same components at other
scales. `foreground_blur 60` is present in every frame, an ambient field
behind the layout. The chart-hover state changes almost nothing: `#04C40A`
goes x9 to x10 and `#1F381F` x5 to x6, one highlighted data point and no
layout movement.

Status tints again: `#04C40A` on `#1F381F`, `#FF9100` on `#FFF1DF`, plus
`#FFEEED` and `#E0E7F3`.

The `Settings Page` frame is the odd one out and useful as contrast:
`#EAECF0`, Inter at 23px for everything, 2.0 and 2.4 borders, inner shadows,
and gaps of 364 / 449 / 500 / 508 (absolute positioning, no layout). It is
visibly L1 sitting next to L3 work.

## `Micro Dashboard.fig`

The same design at five scales. Type 11.3 to 13.1px, radii 4.5 to 5.2,
borders 1.13 to 1.31. Everything scales together, including border width.
Hero is 125px `Organized.` over 25px `So you don't have to be.` on `#000000`.
Accent set `#3072FF #FF2FF5 #FFC12F #2F5AFF #2FFFB3` with `#19965E` and
`#F9B21B` on strokes.

## `Every UI Concept-1.fig`

Two contributions.

**A re-themeable card**, four variants at 625x782, geometry byte-identical
(radii 50 / 15 / 250, gaps 40 / 25 / 5, padding 10 / 30 / 25 / 15 / 50, type
45 / 30 / 25px, one 2.5px stroke), differing only in a three-stop near-black
page gradient plus one bright accent plus a shared `#7E8FA0` muted:

| accent | page gradient | tint |
|---|---|---|
| `#04C4BC` | `#09171D > #111F26 > #0B1920` | `#153D3B` |
| `#8897FF` | `#10122D > #191A35 > #14142E` | `#222A55` |
| `#DDA9F0` | `#20101F > #261625 > #20111F` | `#4D314B` |
| `#05BB3D` | `#09171D > #141F17 > #101913` | `#153D25` |

**One card at four viewports**: 250x205 widget, 393x852 iPhone, 768x1194
iPad, 1604x891 desktop. Type 16 to 28 to 28 to 31px; radii 12/16.6 to 19.8 to
23.4 to 22.3; **padding stays 8 and 16 at every size** while gaps grow from
2/8/16 to 44/48. The `#FF0080` accent appears only at desktop size.

Also carries a `noise 17.6` effect and a menu drawn with 5.62px strokes.

## `UI Elements.fig`

A component library, every piece staged at 1932x1456 on the same `#414141`
neutral, drawn at roughly 2.2x (30px type for a mobile navbar, 5.46px
strokes) because a library is presented larger than life.

Chips: radius 100 x14, padding 12 / 10, gap 10. Pricing card: radii 66.6 and
25, one `#6E37E1`. Signup modal: radii 21.8 x16 and 43.5 x4, stroke 2.18.
Carousels: `background_blur 20` x4 and `40` x2 on the edge controls.

Card shadows come in pairs, one soft and wide plus one tight and dark:
`0 7.42px 44.54px rgba(0,0,0,.15)` with `0 8px 9.6px rgba(0,0,0,.25)`.
Stickers invert this with hard offset shadows at blur 0
(`28.17/57.61 #19154A`, `15.88/15.88 #AD7DCF`), a print convention, not a
UI one.

---

# 5. The pattern files

## `Software Sections.fig`

Marketing sections at 45px headline over 16px paragraph over a 16px text CTA
(`Show me more`, `See it in action`, `explore the interface`,
`success stories`), hero at 94px. A persistent tab row
(`Profit Breakdowns / Fraud Controls / Working Capital`) spans sections.
Each section's visual is a real slice of the product at the size it exists in
the product, never a generic illustration.

## `Learn Design.fig`

Six frames spanning two different products at two different craft levels,
useful as a contrast pair.

Frames 1-2, illustration-led fintech on `#FAF7F5` and `#F6F6F6`: strokes at
4.79 / 7.0 / 8.82 / 9.0 / 10.56 / 10.78px, radii 1000 / 2.8 / 1.7, palette
`#FFCD6C #E5D5C3 #64C6FF #00C978 #FF3E00`, headlines at 60 and 64px, a
`noise 14.9` grain.

Frames 3-6, clean SaaS onboarding on `#FAFAFA`: one shadow token
`0 1px 3px rgba(0,0,0,.05)` used four to seven times per frame, radii
50 / 10 / 100 / 20 / 5.5, green `#156F41` / `#149610` / `#D9F7D7`, borders
0.44 to 1.75. A four-step flow, each step keeping identical chrome and
changing only the card: sign up, create workspace, invite team, check email.
`Back` appears on steps 2 to 4; `Skip` only on the optional step; the final
step carries `Didn't receive a code? Resend`.

## `Kill boring designs.fig`

The licensed exception to the stock-photo rule. Mint `#BAFEB5` on `#F2F2F2`
with `#000000` strokes at 0.2 to 3.83px, 80px display type, hand-drawn vector
marks. Illustration carries the hero, and it works because the illustration
is bespoke. Its 404 frame flips the page to `#CAFEC6` and keeps the same
80px voice: `Looks like a deadline got lost in the wind` over
`Let's head back to base`.

## `Present like a pro.fig`

Presenting the work. Slide 1 is the page at full size on `#000000`; every
later slide is the same page shrunk to roughly 0.3x on a `#CF8171` terracotta
ground. No deck template, no bullet points. `foreground_blur 500` and
`background_blur 100` defocus the backdrop to spotlight the artifact;
`grad-angular(#343434 > #343434 > #A04735 > #343434)` draws a rotating conic
border; strokes drop to 0.33 / 0.75 / 0.8 because the artifact is shown small.

## `Dashboard Flaws.fig`

Dense data UI reference. 12px Plus Jakarta Sans with 8px chart labels, radii
2 / 4 / 6 / 14, gaps 4 / 6 / 8 / 12 / 16, padding 4 / 5 / 6 / 8 / 10.
Onboarding surfaces at 184 to 238px wide, each with its own copy and a
`Dismiss`. A share popover distinguishing `People with access` from
`General access` from `Link Access`, each with its own control. Severity as
text plus color (`Critical`, `High`, `Medium`, `Low`), incident IDs, and time
ranges spanning days (`Apr 2, 3:26pm - Apr 3, 12:41pm`).

---

# Re-running the extraction

The parser lives in `tools/` next to this file. Run
`python3 tools/extract2.py <file.fig>` for per-frame tokens and
`python3 tools/motion.py <file.fig>` for prototype transitions.

For reference, the container is: zip, member `canvas.fig`, magic `fig-kiwi`
plus uint32 version, then `uint32 length + raw-deflate` for the kiwi schema,
then `uint32 length + zstd` for the message (older files use deflate for both).
Kiwi floats are stored with the exponent rotated to the low byte, so a read is
`bits = (bits << 23) | (bits >> 9)` before reinterpreting as f32, with a
single `0x00` byte meaning 0.0. Node hierarchy comes from `parentIndex.guid`
with `parentIndex.position` as the fractional sort key. Prototype data lives
on `prototypeInteractions`.

Report tokens **per top-level frame, never per file**. Most of these files are
before/after or level-by-level pairs whose text is identical; the lesson is
entirely in fill, weight, depth and radius, and a file-level average erases it.
