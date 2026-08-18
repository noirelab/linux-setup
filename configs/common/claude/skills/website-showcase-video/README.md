# website-showcase-video

A Claude Code / Agent skill for turning a live website into a cinematic
showcase film — **Remotion** + real **Playwright** screenshots + a 2.5D camera +
frame-driven motion + sound design.

Not a scroll recording. Not a slideshow. Not rebuilt UI.

Distilled from two shipped films, delivered in both 16:9 and 9:16.

---

## Why this exists

Building one of these is not hard because Remotion is hard. It is hard because
**every browser-capture hazard fails silently.** The script exits 0, the PNGs
look like screenshots, and the defect only surfaces once the video is
assembled — a section that renders blank, a carousel on a different slide every
run, a headline caught mid-keystroke, a hero frozen on one frame.

Rediscovering those costs hours each time. They are written down here, as
symptom → cause → fix.

A sample of what is in [`references/capture-playbook.md`](references/capture-playbook.md):

- Injecting `animation-duration: 0s !important` **outranks Framer Motion's Web
  Animations** and pins elements at `opacity: 0`. A whole section renders blank
  and everything else looks perfect.
- `whileInView` with `once: false` reverts offscreen sections to invisible, so a
  full-page capture comes back almost empty — and scrolling first does not help.
- `omitBackground` cannot produce alpha when the page paints its own background
  (a WebGL canvas, a gradient on `body`).
- Element screenshots clip to the border box, silently cutting off badges that
  overflow it.
- `nth-of-type` counts *within each parent*, so a positional selector quietly
  matches the wrong section.

---

## Contents

```
SKILL.md                          workflow + hazard checklist (entry point)
references/
  capture-playbook.md             browser capture hazards, symptom → fix
  film-architecture.md            project layout, config discipline, 9:16 cuts
  direction-rules.md              motion, typography, editing, sound
assets/
  capture-website.ts              Playwright pipeline (template)
  qa-stills.ts                    one still per storyboard beat
  PageCam.tsx                     2.5D camera + PageChip + PagePlate
  Frames.tsx                      BrowserFrame, DevicePanel, FloatingPanel
  Type.tsx                        MaskedTitle, KineticText, SectionLabel
  Atmosphere.tsx                  grain, vignette, grid, glow, final fade
  Accent.tsx                      brand rule, screen wipe, light sweep
  HeroVideo.tsx                   live footage behind an alpha plate
  SoundDesign.tsx                 renders the cue table
  format.ts                       16:9 / 9:16 adaptation hook
  templates/                      theme.ts · timing.ts · copy.ts
```

The components read six colour tokens from `theme.ts`, so re-skinning a whole
film is one block.

---

## Install

Clone into your agent's skills directory:

```bash
git clone <this-repo> ~/.claude/skills/website-showcase-video
```

It is then discovered automatically. Invoke with `/website-showcase-video`, or
just ask for a video of a website — the description triggers it.

---

## Principles

1. **Real screenshots, never rebuilt UI.** Hand-built UI only for what the page
   does not have (title cards, brand beats).
2. **The visual language grows from the product.** Read the site's computed
   styles, not its design doc — docs go stale.
3. **Everything is frame-driven.** No `setTimeout`, `@keyframes`, CSS
   `transition` or free-running GSAP inside the composition; they do not render.
4. **Deterministic.** Seeded PRNG only. Re-running the capture on an unchanged
   site must produce byte-identical PNGs, and that is worth verifying.
5. **Verify with frames, not vibes.** Render stills at every beat and look at
   them.
6. **Never redraw a brand mark.** Use the client's file; ask for a variant if it
   is unsuitable.

---

## Licence

The methodology and code here are free to use. The SFX referenced in the docs
are **not bundled** — source them yourself (Mixkit's Sound Effects Free License
covers commercial use without attribution and is a safe default).
