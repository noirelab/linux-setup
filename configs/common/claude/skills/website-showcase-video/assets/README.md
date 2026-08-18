# Assets

Working code from two shipped films. Copy into the project and re-skin — do not
import from here.

## Setup

```bash
npx create-video@latest --yes --blank --no-tailwind showcase-video
cd showcase-video
npm i
npm i @remotion/media @remotion/transitions @remotion/google-fonts   # match the remotion version
npm i -D playwright tsx
npx playwright install chromium
```

Then copy:

```
capture-website.ts   -> scripts/     edit the CONFIG region + hazard handling
qa-stills.ts         -> scripts/     edit COMPOSITION and the BEATS list
templates/*.ts       -> src/         fill in every TODO
*.tsx                -> src/components/   (SoundDesign.tsx goes in src/)
```

## Components

| File | Exports | Notes |
|---|---|---|
| `PageCam.tsx` | `PageCam`, `PageChip`, `PagePlate` | 2.5D camera over a full-page texture. **Read the header comment** — magnification uses CSS `zoom`, not `transform: scale`, and the coordinate conversion is not optional. |
| `Frames.tsx` | `BrowserFrame`, `DevicePanel`, `FloatingPanel` | The objects the site is presented on. Built from the site's surface tokens, not a mockup skin. |
| `Type.tsx` | `MaskedTitle`, `KineticText`, `SectionLabel` | Reveal by moving mask + settling tracking. Never plain fades. |
| `Atmosphere.tsx` | `FilmGrain`, `Vignette`, `TechGrid`, `AccentGlow`, `FinalFade` | The constant grade. Seeded grain, so it is reproducible. |
| `Accent.tsx` | `AccentRule`, `ScreenWipe`, `LightSweep` | The connective element. `LightSweep` is used **once per film** and must be clipped by its container's radius. |
| `SoundDesign.tsx` | `SoundDesign`, `HAS_MUSIC` | Renders the cue table from `timing.ts`. Music is an opt-in prop. |

All six colour tokens come from `theme.ts` (`accent`, `black`, `surface`,
`border`, `white`, `muted`), so re-skinning a whole film is one block.

## Sound effects

Not shipped here. A good free source is Mixkit's Sound Effects Free License
(commercial use, no attribution). A workable starter set:

| Role | Character to look for |
|---|---|
| impact | one deep hit, plus one with material meaning for the brand |
| transition | a deep whoosh and a quick metallic sweep |
| riser | one long riser, doubles as a low atmosphere bed |
| mech | a short mechanical activate / lock click |
| light | one shimmer sweep, for the single light sweep |

Avoid synthesised game-UI tones (`bleep`, `notify`, `success`). Real-object
foley is encouraged where the picture shows an action.

## Sanity check before building

```bash
npx tsc --noEmit
```

The components assume Remotion 4.0.5xx with `Interactive`, `CanvasImage` and
`@remotion/media` available.
