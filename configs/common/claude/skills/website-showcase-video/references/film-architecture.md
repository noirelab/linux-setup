# Film Architecture

How to lay the Remotion project out so the edit stays changeable.

---

## Directory

```
showcase-video/                     # isolated; the host app never imports it
├── STORYBOARD.md                   # concept, per-scene beats, copy sources
├── README.md                       # install, recapture, edit, render
├── scripts/
│   ├── capture-website.ts          # Playwright pipeline
│   └── qa-stills.ts                # one still per storyboard beat
├── public/
│   ├── textures/                   # captured screenshots
│   ├── brand/                      # logos, poster frames
│   └── audio/sfx/                  # licensed effects
├── src/
│   ├── theme.ts                    # colours, type scale, easings, PRNG
│   ├── timing.ts                   # the edit + the SFX cue table
│   ├── copy.ts                     # every word on screen
│   ├── layout.json                 # written by the capture script
│   ├── components/                 # PageCam, Frames, Type, Atmosphere, Accent
│   ├── scenes/                      # Scene1…SceneN
│   ├── SoundDesign.tsx
│   ├── Showcase.tsx                # <Series> assembly
│   └── Root.tsx                    # composition + font/texture gate
└── out/
    ├── <name>.mp4
    └── qa/
```

Keep it **out of the host app's build**. Its own `package.json`, its own
`node_modules`. Nothing in the product imports it, and it never modifies the
product — if the film needs a variant asset (e.g. a logo without baked-in
text), create it under `public/brand/`, don't edit the site's.

---

## The three config files

Scenes read values. They never define them.

### `theme.ts`

Colours copied from the site's own CSS. **Keep the site's colour space** — if
the site is in `oklch`, keep `oklch`; Chromium renders it natively and the film
then sits in the same space as the screenshots.

```ts
export const COLORS = { accent: "…", black: "…", border: "…", muted: "… " };
export const FONT   = { family: "…", weights: [400, 700, 800] };
export const TYPE   = { hero: 92, title: 72, caption: 60, support: 34, fine: 30 };
export const SAFE   = 96;
export const EASE   = {
  out:   [0.16, 1, 0.3, 1],    // long decisive settle — the default
  inOut: [0.65, 0, 0.35, 1],   // camera travel between rest points
  drift: [0.33, 0, 0.15, 1],   // barely-there acceleration
};
export function mulberry32(seed: number) { /* deterministic PRNG */ }
```

Tune `EASE` to the brand: heavy industry wants long settles; a software studio
wants a quicker, drier snap (`[0.4, 0, 0.2, 1]`).

### `timing.ts`

The edit, and the sound, in one file.

```ts
export const SCENE_FRAMES = {
  open:    s(4.0),
  reveal:  s(6.0),
  /* … */
} as const;

const ORDER: SceneName[] = ["open", "reveal", /* … */];

// Derived — never hand-written
export const SCENE_START  = ORDER.reduce(/* … */);
export const TOTAL_FRAMES = ORDER.reduce((n, k) => n + SCENE_FRAMES[k], 0);
export const at = (scene: SceneName, offset = 0) => SCENE_START[scene] + offset;
```

Change one duration and the following scenes, the composition length and every
sound cue move with it — because cues are declared as `at("scene", offset)`,
never as absolute frames.

**Adding a scene is three edits**: a key in `SCENE_FRAMES`, its name in
`ORDER`, a `Series.Sequence` in `Showcase.tsx`. Nothing else.

### `copy.ts`

Every on-screen word, each with a comment naming its source on the site.

```ts
export const COPY = {
  brand: "…",
  /** #services subtitle, verbatim. */
  buildCaption: "…",
};
```

Author line breaks here as `\n` (scenes render with `white-space: pre`) so
ragging is a typographic decision, not a container-width side effect.

---

## The cue table

Sound as data, not as JSX scattered through scenes:

```ts
export type Cue = {
  file: string;
  frame: number;               // absolute, via at()
  volume: number;
  durationInFrames?: number;   // cut long samples to their action
  note: string;                // WHICH picture action this punctuates
};
```

The `note` is what makes a re-time survivable: after moving the edit, you can
re-check the whole audio pass in one read instead of hunting through scenes.

Each cue renders as its own `<Sequence from={cue.frame} layout="none">`.
Give long samples an explicit `durationInFrames` so they don't outlive their
action — except a final impact, whose tail should ring out.

---

## Scene assembly

`<Series>` so each scene's `useCurrentFrame()` is scene-relative:

```tsx
<Series>
  <Series.Sequence durationInFrames={SCENE_FRAMES.open} name="1 · Abertura">
    <Scene1Open />
  </Series.Sequence>
  …
</Series>
<FinalFade startFrame={TOTAL_FRAMES - FADE} durationInFrames={FADE} />
<SoundDesign withMusic={withMusic} />
```

Every delay inside a scene is relative to that scene. A scene can be re-timed
without touching any other.

---

## The asset gate

Block the first frame until fonts *and* the heavy textures are ready:

```tsx
const handle = delayRender("Loading fonts and page textures");
Promise.all([
  waitUntilDone(),
  preload("textures/home-full.png"),
  preload("textures/home--hero.png"),
]).catch(() => undefined).then(() => { setReady(true); continueRender(handle); });
```

Resolve image preloads on `error` too — a missing texture should show as a
visible gap, never hang the render forever.

Without this, the first frames of a scene can rasterise before the screenshot
decodes, or with a fallback font.

---

## PageCam: the one thing that must not be simplified

Magnification uses the CSS **`zoom`** property, not `transform: scale()`.

Chromium rasterises a 3D-composited layer at its **layout** size (1920 wide)
and GPU-upscales afterwards. With `scale()`, every glyph is downsampled before
being magnified — text turns to mush, and no camera or depth-of-field tuning
fixes it. `zoom` scales the layout box itself, so the page rasterises at the
enlarged device size and samples *down* from the 2x texture.

The coordinate math that follows: `zoom` scales the element's local coordinate
space, so a page point `(cx, cy)` renders at `(cx·zoom, cy·zoom)` device px from
the box origin, and `translate(Tx)` renders as `Tx·zoom`. To hold `(cx, cy)` at
the frame centre — read from `useVideoConfig()`, never hardcoded, or the same
camera breaks the moment you add a 9:16 cut:

```
cx·zoom + Tx·zoom = halfW   ⟹   Tx = halfW/zoom − cx        (likewise Ty)
```

Skip that conversion and the camera silently drifts off its focal point.

**Debug order for blurry text:** texture source resolution → rasterisation path
→ scaling method. Depth of field is atmosphere; it is never the fix.

---

## Compositing captured elements

- **`PageChip`** — a cutout that flies into its real slot. Travels on
  `translateZ` plus a small Y offset, so it shares the page's perspective the
  whole way in, and lands on coordinates from `layout.json`. Contact shadow
  fades in as it seats.
- **`PagePlate`** — a captured region pinned over its real page coordinates,
  cross-fading. Used for tab switches: the alternate section is a separate
  capture laid over the same origin, so the swap reads as the site's own
  interaction rather than a cut.

**Watch the geometry when a plate changes the page height.** If selecting a tab
makes a section grow, everything below it shifts on the real page and the
plate's bottom edge will not line up with the base texture. Keep that seam out
of frame for the plate's whole visible life, and prefer *not* fading the plate
back out — cross-dissolving to the old content underneath reads as a double
exposure. End the scene on it and cut.

---

## Delivering a vertical (9:16) cut

Instagram Stories and Reels want 1080x1920. That is a re-edit, not a re-render.

**Share timing.ts.** Same `SCENE_FRAMES`, same cue table, same total length —
the sound design then lines up in both orientations with no second pass, and a
re-time moves both cuts at once. Only scene *contents* differ.

**Split scenes by whether they can reflow:**

- Centred layouts (title cards, end cards) adapt on their own. Give them a
  `useFormat()` hook (`{ isVertical, safe, contentWidth }`) and pick explicit
  sizes: `fontSize={isVertical ? 82 : TYPE.hero}`. A long wordmark usually needs
  a stacked variant in `copy.ts` — on one line it overruns 1080px at any
  readable size.
- Scenes built on the desktop page cannot reflow: a 1920px-wide page does not
  fit a 1080px frame. Rebuild those in `src/vertical/` on Story-viewport
  captures.

**Capture at 540x960 @2x.** That is 9:16, and at 2x it rasterises to exactly
1080 wide — a 1:1 map into the frame, nothing upscaled. Check the full-page
height stays under the ~16000px raster limit.

**PageCam must read the frame centre from `useVideoConfig()`**, not hardcoded
960/540, or every vertical shot is silently offset.

Three traps specific to vertical:

1. **Below zoom 2.0 you get black bars.** At the Story viewport, 540 CSS px only
   fill 1080 output px at exactly zoom 2.0. To show a section taller than the
   frame, **pan** down it rather than zooming out.
2. **Do not force the whole page to fit.** A mobile page is often ~540x7000 — a
   1:13 sliver that scales to ~150px wide and reads as a bug. When the beat is
   "the whole site", use the **desktop** capture, whose 1:3 proportion sits
   upright in the Story frame with clean margins.
3. **Flying chips ghost against high-contrast text.** The base texture already
   contains the same element underneath, so a slow fade shows both copies. Keep
   the opacity ramp to 2–4 frames and the Y offset small, or capture an
   element-free "empty plate" to fly onto.

Captions need a wrap width in vertical. A line that fits 1920px runs straight
off a 1080px frame, and `white-space: nowrap` hides the problem until render.

---

## Scripts

```json
{
  "showcase:capture":      "tsx scripts/capture-website.ts",
  "showcase:studio":       "remotion studio",
  "showcase:render:test":  "remotion render <Comp> out/test-540p.mp4 --scale=0.5 --jpeg-quality=80",
  "showcase:render":       "remotion render <Comp> out/<name>.mp4 --crf=16",
  "showcase:render:story": "remotion render <Comp>Story out/<name>-1080x1920.mp4 --crf=16",
  "showcase:render:music": "remotion render <Comp> out/<name>-music.mp4 --crf=16 --props='{\"withMusic\":true}'",
  "showcase:stills":       "tsx scripts/qa-stills.ts"
}
```

---

## README contents

Write it for someone who has never seen the project:

1. Install (including `npx playwright install chromium`)
2. Run the site (and the `BASE=` override)
3. Re-capture — **with the site's specific hazards spelled out**
4. Open the Studio
5. Render (all four commands)
6. Change copy — plus the legibility floors
7. Swap music — the exact file path and flag
8. Adjust timing — and the reminder to re-check the cue table
9. Structure
10. Implementation rules (frame-driven, deterministic, `zoom` not `scale`)

The hazard section is the highest-value part: it stops the next person from
"fixing" the IntersectionObserver stub or re-adding the duration killer.
