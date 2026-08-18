---
name: website-showcase-video
description: Turn a website into a cinematic showcase/promo video — Remotion + real Playwright screenshots + 2.5D camera + frame-driven motion + sound design. Use when asked to make a launch video, product film, portfolio case video, agency showcase, "vídeo de apresentação do site", or to film/present an existing web project. Also use when a Remotion video must composite real page screenshots rather than rebuilt UI.
metadata:
  tags: remotion, playwright, motion-design, video, showcase
---

# Website Showcase Video

Build a 25–35s cinematic film that presents a real website, from real
screenshots, with a 2.5D camera — not a scroll recording, not a slideshow.

Proven on two production films (an industrial mining site, a software studio
site). The expensive knowledge here is in `references/capture-playbook.md`:
**every capture hazard fails silently**, producing a plausible-looking but
broken video rather than an error.

---

## Non-negotiables

1. **Real screenshots, never rebuilt UI.** When the film shows a page that
   exists, it shows pixels captured from that page. Hand-built UI is allowed
   only for things the page does not have (title cards, brand beats).
2. **The visual language grows from the product.** Extract colours, type,
   radii and signature devices from the site's own CSS before designing
   anything. Do not invent a "promo skin".
3. **Everything is frame-driven.** `useCurrentFrame()` + `interpolate()`. No
   `setTimeout`, `@keyframes`, CSS `transition`, rAF, or free-running GSAP
   inside the composition — they do not render.
4. **Deterministic.** No `Math.random()` / `Date.now()`. Seeded PRNG only
   (`mulberry32`, seed from index).
5. **Verify with frames, not vibes.** Render stills at every beat and look at
   them before claiming anything works.

---

## Workflow

### 1. Analyse (before any code)

Run the site locally. Extract into notes:

- **Colours** — read computed styles, not just the design doc. Design docs go
  stale; on one project `DESIGN.md` said teal and the app shipped green.
- **Type** — check `document.fonts` actually resolves. A declared display face
  that never loads means every heading falls back, and setting the film in the
  declared face makes it clash with the screenshots.
- **Signature device** — the one visual move the brand owns (a glowing rule, a
  typing caret, a specific hatch). This becomes the film's connective element.
- **Sections + page height** — `document.querySelectorAll('section')` with
  offsets. These become the camera path.
- **Real copy** — every line the film says must be traceable to the site.

### 2. Storyboard

Write `STORYBOARD.md` first: concept, per-scene frames, copy with source
attribution, camera keys, SFX. Then **proceed to implementation without
waiting for approval** unless the user asked to review it.

Typical 6-scene shape (adapt, don't copy blindly):

| # | Scene | ~Dur | Function |
|---|---|---|---|
| 1 | Opening | 4.0s | Brand + promise, one protagonist |
| 2 | Site reveal | 5.5–6.0s | Browser frame, camera push, hero |
| 3 | Content travel | 5–8s | 2.5D through real sections |
| 4 | Detail / mobile | 3.5–5.7s | Real interactions, responsive |
| 5 | Value | 3–4s | Whole-page pull-back or method |
| 6 | End card | 3.5s | Client's lockup, alone |
| 7 | Studio bumper | 2.5s | Optional, AFTER the client's fade |

### 3. Capture

**Read `references/capture-playbook.md` in full before writing the script.**
Copy `assets/capture-website.ts` and edit only its CONFIG block.

Then verify: run it twice and `cmp` the PNGs. If they differ, something
non-deterministic is still live.

### 4. Build

Copy from `assets/`: `PageCam.tsx`, `Frames.tsx`, `Type.tsx`,
`Atmosphere.tsx`, `Accent.tsx`, `SoundDesign.tsx`. Re-skin to the site's
palette — they read all colour from `theme.ts`.

Layout follows `references/film-architecture.md`: three config files
(`theme.ts`, `timing.ts`, `copy.ts`) own every value; scenes own none.

### 5. Review

```bash
npm run showcase:stills     # one still per storyboard beat
```

**Look at every still.** Then render a 540p test, build a contact sheet, and
watch for pacing. Fix, re-render, repeat at least once.

> Contact sheets at 320px make dark frames read as pure black. Before calling
> a frame broken, render that single frame full-size.

### 6. Deliver

Final 1080p MP4 + `STORYBOARD.md` + `README.md` (install, re-capture, edit
copy, swap music, adjust timing, render) + QA stills.

---

## Hazard checklist

Every one of these produces a *plausible but wrong* video. Details and fixes in
`references/capture-playbook.md`.

- [ ] `animation-duration: 0s !important` injected → **freezes framer-motion at
      `opacity: 0`**. Never do this.
- [ ] `whileInView` + `once: false` → offscreen sections revert to invisible in
      full-page captures.
- [ ] Carousels/sliders auto-advancing → different slide every run.
- [ ] Typing/cycling text → captured mid-keystroke.
- [ ] Cookie banners with no storage key → in every plate.
- [ ] Dev overlays (`nextjs-portal`, Vite error overlay).
- [ ] Smooth-scroll libraries (Lenis) fighting the capture.
- [ ] `<video>` at an arbitrary frame — and, once pinned, **frozen in the film**.
      Capture alpha plates and composite the real clip behind them (§6b).
- [ ] WebGL/canvas backgrounds → inherently non-reproducible; document it.
- [ ] Element screenshots clipping badges that overflow the border box.
- [ ] `omitBackground` not producing alpha when the page paints its own bg.
- [ ] Full-page height × deviceScaleFactor over ~16000px.
- [ ] `nth-of-type` matching the wrong element (it counts *within each parent*).
- [ ] Hardcoded frame centre in the camera → every vertical shot silently offset.
- [ ] tsx/esbuild `keepNames` breaking `page.evaluate` with `__name is not defined`.

---

## Direction rules

`references/direction-rules.md` has the full set. The ones most often violated:

- **Never redraw a brand mark.** Use the client's file; ask for a variant if it
  is unsuitable. Check it has real alpha and pre-crop it to its content box.
- **Legibility floors**: narrative captions ≥56px, supporting text ≥32px, in
  final output pixels. Safe area 96px.
- **Never caption what the screen already says.** If the section heading is
  large in frame, the film's caption carries the *narrative* line instead.
- **Hold after every landing.** Minimum ~1s of settled image on brand moments.
- **One protagonist per scene.** One device used as the star once per film.
- **Stepped SFX.** Repeated hits descend in level (0.30 → 0.22 → 0.18 → 0.15).
- **One light sweep in the whole film**, clipped by its container's radius.
- **Page textures must bleed past frame edges** (zoom ≥ 1.0) or they read as a
  screenshot floating on black.

---

## Vertical (9:16) delivery

Stories/Reels want 1080x1920, and that is a re-edit rather than a re-render.
Share `timing.ts` between both cuts so the sound design lines up once; give
centred scenes a `useFormat()` hook; rebuild page-based scenes on 540x960 @2x
captures (which rasterise 1:1 into the frame). See
`references/film-architecture.md` → "Delivering a vertical (9:16) cut" for the
three traps: black bars below zoom 2.0, the 1:13 mobile-page sliver, and chips
ghosting against baked content.

---

## Music

Ship SFX only unless a cleared track exists. Leave `public/audio/music.mp3` as
a documented drop-in slot with a `withMusic` prop, and deliver both versions
when a track is supplied. Never use music with unverifiable licensing.

Mixkit Sound Effects Free License covers commercial use without attribution and
is a safe default for SFX.

---

## Files

- `references/capture-playbook.md` — browser capture hazards, symptom → fix
- `references/film-architecture.md` — project layout and config discipline
- `references/direction-rules.md` — motion, typography, editing, sound
- `assets/` — working `capture-website.ts`, `qa-stills.ts`, `format.ts`, and the
  component set (`PageCam`, `Frames`, `Type`, `Atmosphere`, `Accent`,
  `SoundDesign`)
- `assets/templates/` — `theme.ts`, `timing.ts`, `copy.ts` starting points
