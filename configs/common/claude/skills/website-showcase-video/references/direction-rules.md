# Direction Rules

Motion, typography, editing and sound decisions that survived review on real
films. Each is a rule, the case that produced it, and a self-check.

Rules may be broken deliberately — but write down which one and why.

---

## Typography

### T1. Legibility floors, measured in output pixels

Narrative captions **≥56px** (~5.2% of frame height). Supporting text **≥32px**.
Safe area **96px** on every edge.

Measure the *rendered* pixel height, not the `fontSize` in code: multiply by
every ancestor scale and, in 3D shots, by the perspective compression
(≈`cos(rotY)`).

Text has exactly two states:

- **Texture** — small type inside a screenshot. Not meant to be read; let it be
  soft.
- **Read** — the film's own captions. Must clear the floor and carry enough
  contrast (a scrim or text-shadow over busy plates).

There is no middle state. Text that is meant to be read but can't be is worse
than no text.

*Self-check:* scale a frame to 480px wide (phone-in-feed) — is every caption
still readable?

### T2. Never caption what the screen already says

**Case:** three consecutive scenes captioned "O que desenvolvemos", "Cases
Recentes", "Como trabalhamos" — verbatim repeats of section headings that were
already large in frame. Replaced with the narrative line instead
("Do levantamento de requisitos à entrega."), which says something new.

Same rule caught a hero scene captioned "Transformamos ideias em" while the
identical headline was typing inside the browser frame directly above it.

*Self-check:* for every caption — is that string already legible on screen?

### T3. Reveal by mask, not by fade

Titles are uncovered by a moving edge (`clip-path: inset()`), with tracking
settling from wide to normal. That tracking move is what makes type read as
*machined* rather than *animated*. Fades alone read as a slideshow.

---

## Motion

### M1. Match the easing to the brand

Heavy industry: long decisive settles, `bezier(0.16, 1, 0.3, 1)`, mass and
inertia. Software studio: quicker and drier, `bezier(0.4, 0, 0.2, 1)`, precision
and snap.

Neither bounces. Springs use high damping and near-zero overshoot.

### M2. Only `transform`, `opacity`, `clip-path`, `filter`

Never animate layout properties. Use `scale`/`translate`/`rotate` shorthands
with `output: "perceptual-scale"` on scale so it reads linearly to the eye.

### M3. Page textures must bleed past the frame

Keep camera `zoom ≥ 1.0` when travelling a page. Below that, the page floats on
black with visible margins and instantly reads as "screenshot in a slideshow" —
the exact thing the 2.5D camera exists to avoid.

**Case:** a travel scene at zoom 0.74–0.86 left 134px black bars either side.
Raising it to 1.05–1.16 fixed it with no loss of context.

### M4. Elements land in real slots

A cutout flying in must end at the coordinates the browser actually gave it, so
it **seats into** the layout. Elements that stop hovering above the page look
fake.

### M5. Hold after landing

Minimum ~1s of completely settled image on brand moments. Pacing feedback runs
one way in practice: reviewers ask for *slower and longer*, never faster.

Budget hold frames when laying out the timeline — the first cut is always too
quick.

### M6. Repeated entries step down

Batch arrivals accelerate and stagger (12–16 frames apart), and their sound
levels descend. Uniform timing reads as a template.

---

## Composition

### C0. Never redraw a brand mark

Use the client's own artwork file. If the supplied logo is unsuitable for the
film (baked-in text, wrong crop, no alpha), **ask for the variant** — do not
reconstruct it.

**Case:** the site's `logo.svg` carried arc-set text that duplicated the
wordmark, so I rebuilt the seal by hand in SVG. It looked plausible and was
wrong: hull, material pile, script monogram and funnel were all subtly off. The
client supplied the correct file and it replaced the whole reconstruction.

Two things to check on a supplied logo before using it:

- **Alpha.** `file logo.png` must report RGBA; a white background reads as a
  white box on a dark film. A preview showing white does not prove there is no
  alpha — sample the corner pixels.
- **Content box.** Artwork is often a small island in a large transparent
  canvas. Measure the non-transparent bounding box and pre-crop, otherwise every
  size you specify renders roughly half as large as intended.

*Self-check:* is every brand asset in this film a file someone gave me?

### C1. One protagonist per scene

**Case:** an opening had a brand mark and a wordmark competing. The mark carried
its own arc-set company name, so the frame said the name twice — and at mark
size that arc text degraded into a smudge.

The *diagnosis* was right; the first fix was not. I redrew the seal without the
text, which violated C0 and got the artwork wrong. The correct fix was to ask,
and the client supplied a text-free version of the real mark. Note the shape of
the mistake: a composition problem tempted me into fabricating an asset, when
the composition problem only needed a different file.

*Self-check:* how many things in this frame want to be looked at?

### C2. Text and subject share the frame, not the same space

A full-height page centred in frame becomes a thin column with type stamped
across it. Push the subject to one third, tilt it, and give the copy the other
third. Use a **directional** scrim (a left-weighted gradient), not a flat wash:
the type side goes dark enough to read while the subject stays legible.

### C3. One light sweep in the entire film

Clipped by its container's `border-radius`. Light spilling past a rounded corner
is the classic tell of a cheap template. Never sweep a group of elements.

### C4. Device panels, not device mockups

Use the site's own card language at device proportions — real radius, the site's
1px border, a directional shadow. No notches, no chunky bezels, no glossy
plastic. Pair two panels with opposite Y-tilts for volume.

### C5. Frames need a light direction

A browser shell gets a soft top rim (`inset` highlight) and drops its weight
downward. Shadows without a consistent key look pasted on.

---

## Editing

### E1. Assemble, don't fade in

A browser frame draws its chrome, then its controls in sequence, then the page.
Assembly order is what reads as construction.

### E2. Cut on meaning

**Case:** a travel scene was going to continue to the calculator and CTA, but
ending it on the product cards and cutting straight to the quote assistant was
stronger — *product → ask for a price*. It also removed a compositing seam.
Take the cut that helps the story.

### E3. Breathe before the fade

Let the last element settle, hold ~10 frames of completely still image, and only
then fade. Verify by extracting the tail frames.

### E4. The studio signs after the film, not inside it

A client end card belongs entirely to the client. If the studio needs credit,
give it its own bumper **after** the client's card has faded to black — that is
how a production company signs, and it reads as more respectful than a credit
line sharing the client's lockup.

Run the bumper in the studio's own identity: a signature only reads as a
signature if it is visibly a different mark. Keep it restrained and short
(~2.5s), and keep its sound quiet — the film already ended; this is not a second
climax.

Never do both. A credit line *and* a bumper says the same thing twice.

---

## Sound

### S1. Choose by film type, not by event

Product-film vocabulary: `whoosh` (camera), `impact` (landing), `riser`
(build), `sweep`/`transition` (cuts). Avoid synthesised game-UI feedback tones
(`bleep`, `notify`, `success`) unless the narrative wants a system prompt.

Real-object foley is *encouraged* where the picture shows an action — a click, a
switch, a shutter. The test: does it sound like the real object, or like a game
engine?

Pick sounds with material meaning. A mining film's wordmark landed on
`gravel-fall-hit` rather than a generic boom.

### S2. Pin cues to frames, in a table

Frame number + file + volume + a note naming the picture action. Never sprinkle
audio through scenes.

### S3. Step levels on repeats

Four cards landing: `0.30 → 0.22 → 0.18 → 0.15`. Equal levels read as a machine
gun.

### S4. Cut samples to their action

Give long samples an explicit `durationInFrames`. The exception is a closing
impact, whose tail should ring out under the hold.

### S5. Re-check the whole table after any re-time

Changing a scene duration moves everything downstream. This is why cues use
`at("scene", offset)` and carry a note.

### S6. Music never covers the effects

Bed at ~0.28 with frame-driven fades. Ship SFX-only when no cleared track
exists, and leave a documented drop-in slot. Never use music with unverifiable
licensing.

If a film would otherwise fall to silence between hits, layer a very low
sustained bed (~0.09–0.11) from the licensed library rather than reaching for
unlicensed music.

---

## Forbidden

Generic template look · particle showers · neon on non-tech brands · generic
startup purple gradients · elastic/bouncy easing · constant motion with no rest
· continuous zoom · cheap mockups · PowerPoint transitions · text flying without
purpose · decorative elements with no function.

---

## Verification

### V1. Never hand the first review to the user

Render stills at every beat and inspect them. Use pixel tools when needed (crop
and magnify to check glyph edges; diff two frames). Archive them under
`out/qa/`.

### V2. Contact sheets lie about dark frames

At 320px wide, a dark-but-correct frame reads as pure black. Before declaring a
frame broken, render that single frame at full size. Two "bugs" found this way
turned out to be correct frames.

### V3. Prove determinism

Render the same frame twice and compare hashes. Run the capture twice and `cmp`
the PNGs. Claims of reproducibility need evidence.

### V4. Check the audio objectively

`ffmpeg -af volumedetect` — confirm no clipping (max below 0 dB) and that the
track isn't silent. Confirm the container actually has an audio stream.
