# Capture Playbook

Turning a live site into film-grade textures with Playwright.

**Read this before writing the capture script.** Every hazard below fails
*silently* — the script exits 0, the PNGs look like screenshots, and the defect
only surfaces when the video is already assembled.

The rule that makes all of this tractable: **after every capture run, open the
PNGs and look at them.** Not the log. The pixels.

---

## 0. The determinism contract

Re-running the script against an unchanged site must produce byte-identical
PNGs. Verify it:

```bash
npm run showcase:capture && cp public/textures/home--products.png /tmp/run1.png
npm run showcase:capture && cmp /tmp/run1.png public/textures/home--products.png \
  && echo "deterministic" || echo "something is still moving"
```

The one acceptable exception is a live WebGL/canvas background (§9), which must
be called out in the README.

---

## 1. Never zero out animation durations

**The single most destructive mistake in this pipeline.**

```ts
// ☠️ DO NOT DO THIS
await page.addStyleTag({ content: `
  *, *::before, *::after {
    animation-duration: 0s !important;
    transition-duration: 0s !important;
  }` });
```

**Symptom:** a whole section renders blank — cards, list items, anything
animated is simply absent. Everything else looks perfect.

**Cause:** Framer Motion (and any WAAPI-based library) animates via the Web
Animations API. An `!important` CSS declaration outranks WAAPI in the cascade,
so the animation is clamped to zero duration and the element is pinned at its
`initial` variant — usually `opacity: 0`.

**Fix:** don't. Playwright's `screenshot({ animations: "disabled" })` already
fast-forwards CSS animations to their end state. For JS-driven animation, let it
run and wait for it to settle.

Safe things to inject:

```ts
await page.addStyleTag({ content: `
  * { caret-color: transparent !important; }
  ::-webkit-scrollbar { width: 0 !important; height: 0 !important; }
  nextjs-portal, [data-nextjs-toast], [data-nextjs-dev-tools-button],
  next-route-announcer, vite-error-overlay { display: none !important; }
` });
```

---

## 2. `whileInView` with `once: false`

**Symptom:** the full-page texture is mostly empty. Sections you *scrolled past*
are blank too, so "scroll everything into view first" doesn't help.

**Cause:** `viewport={{ once: false }}` means the element animates back to
`hidden` when it leaves the viewport. A full-page screenshot uses
`captureBeyondViewport` — it does not resize the layout viewport — so everything
offscreen sits at `opacity: 0`.

**Fix:** stub `IntersectionObserver` so every observed element reports as
permanently intersecting. Install via `addInitScript` so it lands before any
page script runs.

```ts
await ctx.addInitScript(() => {
  class AlwaysIntersecting {
    private cb: IntersectionObserverCallback;
    root = null; rootMargin = "0px"; thresholds = [0];
    constructor(cb: IntersectionObserverCallback) { this.cb = cb; }
    observe(el: Element) {
      const rect = el.getBoundingClientRect();
      this.cb([{
        target: el, isIntersecting: true, intersectionRatio: 1,
        boundingClientRect: rect, intersectionRect: rect,
        rootBounds: null, time: 0,
      } as IntersectionObserverEntry], this as unknown as IntersectionObserver);
    }
    unobserve() {} disconnect() {} takeRecords() { return []; }
  }
  (window as any).IntersectionObserver = AlwaysIntersecting;
});
```

Every reveal animates to its final state and stays — exactly what to photograph.

**Do not** try to solve this by setting a page-height viewport. A `h-screen`
hero becomes 5000px tall and the layout collapses.

---

## 3. Auto-advancing carousels

**Symptom:** every run lands on a different slide.

**Fix in order of preference:**

1. **Kill the timer at the source.** Find the autoplay delay in the component
   and drop that exact registration:

   ```ts
   await ctx.addInitScript(() => {
     const CAROUSEL_AUTOPLAY_MS = 5000;   // read from the component
     const native = window.setInterval.bind(window);
     window.setInterval = ((fn: TimerHandler, delay?: number, ...args: unknown[]) =>
       delay === CAROUSEL_AUTOPLAY_MS ? 0 : native(fn, delay, ...args)
     ) as typeof window.setInterval;
   });
   ```

   Verify the delay is unique in the codebase before doing this.

2. Click a pagination dot to pin a slide.

**Do not rely on hover-to-pause.** Many carousels stop on `mouseenter` — but
scrolling moves the page under a stationary cursor, fires `mouseleave`, and the
timer restarts. This looks like it works and then silently doesn't.

---

## 4. Typing / cycling text

**Symptom:** headline captured as `"aplicat"`, or empty, or a different word
each run.

**For a plate that should show a word:** poll until the text matches a complete
word, then shoot immediately. Re-poll before *each* plate that contains it —
the word advances during scrolls and waits.

```ts
const word = await page.evaluate((words) => new Promise<string>((resolve) => {
  const started = Date.now();
  const tick = () => {
    const typed = document.querySelector("h1")?.children[2];   // the typing span
    const txt = (typed?.textContent ?? "").replace(/[|_▌]\s*$/, "").trim();
    if (words.includes(txt)) return resolve(txt);
    if (Date.now() - started > 15000) return resolve(txt);
    requestAnimationFrame(tick);
  };
  tick();
}), WORDS);
```

**For a plate that should show the slot empty** (so the film can drive the
typing itself): **hide the span, don't wait for it to empty.**

```ts
const hide = await page.addStyleTag({
  content: `h1 > span:nth-child(3) { visibility: hidden !important; }`,
});
await page.screenshot({ path: "hero-empty.png", scale: "device" });
await hide.evaluate((el) => (el as Element).remove());
```

Waiting for `textContent === ""` is a race: the site keeps typing between the
check resolving and the shutter, and the plate comes back with a stray `s|`
baked in. `visibility: hidden` preserves the line box, so layout is untouched.

This is worth the effort: replaying the site's own typing **inside the browser
frame**, at the real page coordinates, is far stronger than duplicating the
headline as a caption underneath it.

---

## 5. Consent banners and modals

Check whether consent persists. If the context stores nothing (in-memory only),
there is no key to pre-seed — dismiss it by clicking, the way a visitor would:

```ts
const accept = page.getByRole("button", { name: /^aceitar$/i }).first();
if (await accept.count()) { await accept.click(); await page.waitForTimeout(500); }
```

Do this **before** anything is photographed, including the first plate.

---

## 6. Smooth scroll and video

**Lenis / locomotive** hijack scrolling. Destroy before capturing:

```ts
const lenis = (window as any).lenis;
lenis?.destroy?.();
document.documentElement.classList.remove("lenis", "lenis-smooth");
```

**`<video>`** must be pinned to a fixed frame or the hero differs every run:

```ts
v.pause();
v.removeAttribute("autoplay");
v.loop = false;
v.currentTime = Math.min(FIXED_TIME, v.duration || FIXED_TIME);
// resolve on requestVideoFrameCallback, fall back to "seeked", cap with a timeout
```

Always cap the wait — a stalled video must not hang the pipeline.

---

## 6b. A hero that is a `<video>` — alpha plates

Pinning the video to a fixed frame (§6) makes the capture reproducible and the
**film dead**: the hero stops moving.

Fix: capture the page twice. Once normally, and once with the video hidden and
the document background cleared, so `omitBackground` yields real alpha:

```ts
const strip = await page.addStyleTag({ content: `
  html, body { background: transparent !important; }
  video { visibility: hidden !important; }
` });
await page.screenshot({ path: "home-full-alpha.png", fullPage: true,
                        scale: "device", omitBackground: true });
await strip.evaluate((el) => (el as Element).remove());
```

**Why the alpha lands only on the hero:** every section below it paints its own
background (`bg-black`, card surfaces, footer). Only the hero relies on the
video, so only the hero comes back transparent. Verify before trusting it —
sample the alpha channel at a few page offsets:

```bash
file plate.png     # must say RGBA
ffmpeg -v error -i plate.png -vf "crop=4:4:X:Y,alphaextract,scale=1:1"   -pix_fmt gray -f rawvideo - | od -An -tu1     # 0 = clear, 255 = opaque
```

Expect a mid value over the hero (the site's gradients are semi-transparent
black and survive in the plate, so they still darken the footage) and 255
everywhere below.

Then composite in the film: the real clip goes BEHIND the plate, in page
coordinates, through a `backdrop` slot on `PageCam` / `BrowserFrame`. Pass
`trimBefore` = the accumulated length of earlier scenes so the footage stays
continuous across cuts.

**`objectFit: "cover"` is not reliably honoured on the media element.** Compute
the cover fit yourself:

```ts
const scale = Math.max(boxW / srcW, boxH / srcH);
// draw at srcW*scale x srcH*scale, centred, inside an overflow:hidden box
```

This is invisible while the box stays 16:9 and very visible the moment it does
not — in a 9:16 Story frame the clip renders as a letterboxed band.

**Proving it animates:** compare two frames inside a window where the CAMERA IS
STATIC. With the camera moving, any diff proves nothing.

```bash
ffmpeg -v error -i a.png -i b.png \
  -filter_complex "[0:v][1:v]blend=all_mode=difference,format=gray" \
  -frames:v 1 -f rawvideo - | od -An -tu1 -v | tr -s " " "\n" | sort -rn | head -1
```

Use the MAX, not the mean: a whole-frame average of slow footage rounds to 0
and reads as a false negative.

---

## 7. Element cutouts

**Element screenshots clip to the border box.** Anything overflowing — a badge
floating above a card, a glow, a focus ring — is cut off.

Use a page-level `clip` with padding instead:

```ts
const vp = await el.evaluate((e) => {
  const r = e.getBoundingClientRect();
  return { x: r.x, y: r.y, w: r.width, h: r.height };
});
await page.screenshot({
  path: file, scale: "device", animations: "disabled",
  clip: {
    x: Math.max(0, vp.x - pad), y: Math.max(0, vp.y - pad),
    width: Math.min(viewportW, vp.w + pad * 2),
    height: Math.min(viewportH, vp.h + pad * 2),
  },
});
```

Record the pad in `layout.json` — the film needs it to position the cutout
against the element's real bbox.

**Always `scrollIntoViewIfNeeded()` before measuring**, and measure *after*
scrolling, not before.

---

## 8. `omitBackground` cannot remove a painted background

**Symptom:** a cutout meant to be transparent comes back as RGB with a grey or
black slab behind it.

**Cause:** `omitBackground: true` only drops the browser's *default* white
backdrop. If the page paints its own background — a WebGL canvas, a gradient on
`body` — those pixels are real content.

**Two fixes:**

1. **Hide the background layers before capturing**, then `omitBackground` works:
   ```ts
   await page.addStyleTag({ content: `
     html, body { background: transparent !important; }
     canvas { visibility: hidden !important; }
     section:has(h1) > div:not(:last-child) { visibility: hidden !important; }
   ` });
   ```

2. **Accept black and composite with `screen`.** If the cutout is light type on
   pure black, `mixBlendMode: "screen"` in the film drops the black with no
   matte edge. Often more robust than chasing real alpha.

Verify which you got:

```bash
file cutout.png    # "8-bit/color RGBA" = alpha,  "RGB" = no alpha
```

---

## 9. WebGL / canvas backgrounds

Live shaders have no fixed seed and no exposed clock, so their pixels differ
slightly between runs. Freezing `performance.now()` usually doesn't help
because `requestAnimationFrame` receives its timestamp from the compositor.

**Accept it and document it.** Note in the README that the hero background is a
live shader and that this one element is not byte-reproducible. Everything else
must be.

Some headless setups render WebGL as a blank rectangle. If so:

```ts
chromium.launch({ args: ["--use-gl=swiftshader", "--enable-unsafe-swiftshader"] })
```

---

## 10. Raster limits

Chromium refuses to rasterise a surface taller than ~16000 device px.
`pageHeight × deviceScaleFactor` crosses it easily on mobile viewports
(7600 CSS px × 3 = 22800).

```ts
const devicePx = pageH * deviceScaleFactor;
if (devicePx > 16000) console.warn(`${name}: falling back to 1x`);
await page.screenshot({
  fullPage: true,
  scale: devicePx > 16000 ? "css" : "device",
});
```

Prefer 2x for desktop full-page textures. The film's `PageCam` magnifies with
CSS `zoom`, so a 2x texture stays oversampled up to zoom 2.0.

---

## 11. Selector traps

**`nth-of-type` counts within each parent, not globally.** A page whose hero
lives in one wrapper and whose other sections live in another will silently
match the wrong element:

```
section:nth-of-type(2)   ->  #cases      ✗
section:has(h1)          ->  the hero    ✓
```

Verify every selector against the live DOM before trusting it. A short probe
script that prints each section's `id`, offset and height pays for itself
immediately.

Selectors that survive redesigns, in order: `#id` → `:has()` on distinctive
content → attribute contains (`[class*="z-[80]"]`) → positional. Never use a
generated class hash.

**Watch for full-viewport overlays.** `div.fixed` frequently matches a backdrop
before the panel you want. Scope to a child: `div[class*="z-[80]"] > section`.

---

## 12. `__name is not defined`

**Symptom:** every `page.evaluate` throws `ReferenceError: __name is not defined`.

**Cause:** `tsx`/esbuild compiles with `keepNames`, rewriting the arrow
functions handed to `page.evaluate` into calls to a `__name` helper that only
exists in the Node bundle.

**Fix:** provide a no-op in page scope, via `addInitScript`:

```ts
await ctx.addInitScript(() => {
  const g = globalThis as unknown as Record<string, unknown>;
  g.__name ??= (fn: unknown) => fn;
});
```

---

## 13. Settling before the shutter

```ts
await page.evaluate(async () => {
  await document.fonts.ready;
  await Promise.all(Array.from(document.images).map((img) =>
    img.complete && img.naturalWidth > 0
      ? img.decode().catch(() => undefined)
      : new Promise<void>((r) => {
          img.addEventListener("load", () => r(), { once: true });
          img.addEventListener("error", () => r(), { once: true });
          setTimeout(r, 4000);
        })));
});
await page.waitForTimeout(700);
```

`networkidle` alone is not enough — fonts swap and images decode after it.

Also walk the page once to commit anything lazy, then return to the top.

---

## 14. Context settings that matter

```ts
const ctx = await browser.newContext({
  viewport: { width: 1920, height: 1080 },
  deviceScaleFactor: 2,
  colorScheme: "dark",          // match the site's real appearance
  locale: "pt-BR",
  timezoneId: "America/Sao_Paulo",
  // NOT reducedMotion: "reduce" — entrance animations must run and settle
});
```

`reducedMotion: "reduce"` can leave elements in their pre-animation state. The
goal is *settled*, not *skipped*.

Launch args worth setting: `--force-color-profile=srgb`, `--disable-lcd-text`
(subpixel AA looks wrong when scaled), `--hide-scrollbars`.

---

## 15. What to capture

| Output | Purpose |
|---|---|
| `<page>-full.png` @2x | full-page texture for the 2.5D camera |
| `<page>--<section>.png` | viewport-framed plates, one per section |
| `<page>__<element>.png` | element cutouts that fly into real slots |
| `layout.json` | `pageH`, `pageW`, scale, bboxes, cutout pads |

`layout.json` is what lets a cutout land in the exact slot the browser gave it,
so elements **seat into** the layout instead of hovering above it. Record
page-space coordinates (`r.x + scrollX`), not viewport ones.

Also capture real interactions where they exist — an opened quote assistant, an
expanded mobile drawer, a selected tab. Perform the interaction, then shoot.
Never invent a feature the site does not have.
