/**
 * capture-website.ts — Playwright capture pipeline.  [TEMPLATE]
 *
 * Copy into <project>/showcase-video/scripts/ and edit the CONFIG region
 * (BASE, SHOTS, and the hazard handling in freeze()/addInitScript).
 *
 * Produces:
 *   1. Full-page 2x textures  -> public/textures/<name>-full.png
 *   2. Section plates + element cutouts
 *   3. src/layout.json        (pageH, pageW, scale, bboxes, cutout pads)
 *
 * ⚠️ READ references/capture-playbook.md FIRST. Every hazard it lists fails
 * SILENTLY — the script exits 0, the PNGs look like screenshots, and the defect
 * only shows up once the video is assembled.
 *
 * The hazards already handled below (delete what a given site does not need,
 * but understand each before removing it):
 *
 *   · esbuild `keepNames` breaking page.evaluate  -> __name no-op
 *   · whileInView + once:false                    -> IntersectionObserver stub
 *   · typing / cycling headlines                  -> waitForCompleteWord()
 *   · consent banners with no storage key         -> dismissConsent()
 *   · dev overlays (Next.js / Vite)               -> freeze() CSS
 *   · element badges clipped by the border box    -> pad via page clip
 *   · full-page raster limit (~16000 device px)   -> scale fallback
 *
 * NOT handled here — add per project if present:
 *
 *   · auto-advancing carousels   -> drop the interval at source
 *   · Lenis / locomotive scroll  -> destroy before capture
 *   · <video> elements           -> seek to a fixed time and pause
 *
 * NEVER inject `animation-duration: 0s !important`. An !important declaration
 * outranks framer-motion's Web Animations and pins elements at opacity 0.
 *
 * Usage:  npm run showcase:capture
 *         BASE=http://localhost:3000 npm run showcase:capture
 */

import { chromium, type Browser, type Page, type Locator } from "playwright";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import net from "node:net";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PROJECT = path.resolve(HERE, "..");
const OUT_DIR = path.join(PROJECT, "public", "textures");
const LAYOUT_JSON = path.join(PROJECT, "src", "layout.json");

const BASE = process.env.BASE ?? "http://localhost:3000";   // TODO: project port

const SETTLE_MS = 800;
const DESKTOP = { width: 1920, height: 1080, deviceScaleFactor: 2 } as const;
const MOBILE = { width: 430, height: 932, deviceScaleFactor: 3 } as const;
const MAX_DEVICE_PX = 16000;

/** The four words the hero headline cycles through. */
const TYPED_WORDS = ["sites", "programas", "aplicativos", "sistemas"] as const;

type Cutout = {
  name: string;
  selector: string;
  all?: boolean;
  max?: number;
  omitBackground?: boolean;
  pad?: number;
};

type Shot = {
  name: string;
  path: string;
  viewport: typeof DESKTOP | typeof MOBILE;
  fullPage?: boolean;
  viewportAt?: string;
  sections?: { name: string; selector: string; align?: "top" | "center" }[];
  boxes?: { key: string; selector: string; all?: boolean; max?: number }[];
  cutouts?: Cutout[];
  prepare?: (page: Page) => Promise<void>;
};

/**
 * Section geometry verified against the live DOM:
 *   hero 0 · services 1144 · cases 2016 · process 2682 · faq 3230 · contact 4186
 * The hero is matched by :has(h1) — nth-of-type counts within each parent, so
 * a positional selector lands on #cases instead.
 */
const HERO = "section:has(h1)";

const SHOTS: Shot[] = [
  {
    name: "home",
    path: "/",
    viewport: DESKTOP,
    fullPage: true,
    sections: [
      { name: "hero", selector: HERO, align: "top" },
      { name: "services", selector: "#services", align: "center" },
      { name: "cases", selector: "#cases", align: "center" },
      { name: "process", selector: "#process", align: "center" },
      { name: "faq", selector: "#faq", align: "center" },
    ],
    boxes: [
      { key: "hero", selector: HERO },
      { key: "services", selector: "#services" },
      { key: "cases", selector: "#cases" },
      { key: "process", selector: "#process" },
      { key: "serviceCards", selector: "#services .container > div:nth-of-type(2) > *", all: true, max: 6 },
      { key: "caseCards", selector: "#cases .container > div:nth-of-type(2) > *", all: true, max: 6 },
    ],
    cutouts: [
      { name: "nav", selector: "nav", pad: 0 },
      { name: "headline", selector: "h1", pad: 12 },
      { name: "service", selector: "#services .container > div:nth-of-type(2) > *", all: true, max: 4, pad: 8 },
      { name: "case", selector: "#cases .container > div:nth-of-type(2) > *", all: true, max: 4, pad: 8 },
    ],
  },
  {
    name: "mobile-home",
    path: "/",
    viewport: MOBILE,
    fullPage: false,
    viewportAt: HERO,
    sections: [{ name: "services", selector: "#services", align: "center" }],
  },
];

// ---------------------------------------------------------------------------

const log = (...a: unknown[]) => console.log("  ", ...a);

async function assertServer(url: string): Promise<void> {
  const { hostname, port } = new URL(url);
  const open = await new Promise<boolean>((resolve) => {
    const sock = net
      .createConnection({ host: hostname, port: Number(port || 80) })
      .once("connect", () => (sock.end(), resolve(true)))
      .once("error", () => resolve(false));
    setTimeout(() => (sock.destroy(), resolve(false)), 4000);
  });
  if (!open) {
    throw new Error(
      `No dev server reachable at ${url}.\n` +
        `Start the site first:  npm run dev   (in the repository root)\n` +
        `Then re-run, or point elsewhere:  BASE=http://localhost:5173 npm run showcase:capture`,
    );
  }
}

async function freeze(page: Page): Promise<void> {
  await page.addStyleTag({
    content: `
      /* Never zero out animation/transition durations with !important here:
         an !important declaration outranks framer-motion's Web Animations and
         pins elements at their "initial" variant (opacity: 0). Playwright's
         screenshot animations:"disabled" already settles CSS animations. */
      * { caret-color: transparent !important; }
      ::-webkit-scrollbar { width: 0 !important; height: 0 !important; }
      [data-vite-dev-id], vite-error-overlay, #vite-error-overlay { display: none !important; }
    `,
  });
}

/** Wait until fonts are ready and every image has decoded. */
async function settle(page: Page): Promise<void> {
  await page.evaluate(async () => {
    await document.fonts.ready;
    await Promise.all(
      Array.from(document.images).map((img) =>
        img.complete && img.naturalWidth > 0
          ? img.decode().catch(() => undefined)
          : new Promise<void>((r) => {
              img.addEventListener("load", () => r(), { once: true });
              img.addEventListener("error", () => r(), { once: true });
              setTimeout(r, 4000);
            }),
      ),
    );
  });
  await page.waitForTimeout(SETTLE_MS);
}

/**
 * Hold until the typing headline is showing a COMPLETE word.
 *
 * TextType types and deletes on a timer, so an unsynchronised screenshot lands
 * on "aplicat" or an empty string. This polls the DOM and returns as soon as
 * the visible text matches one of the four words exactly.
 */
async function waitForCompleteWord(page: Page): Promise<string> {
  const word = await page.evaluate(
    (words) =>
      new Promise<string>((resolve) => {
        const started = Date.now();
        const read = () => {
          const h1 = document.querySelector("h1");
          if (!h1) return "";
          // h1 children are [0] sr-only full sentence, [1] static lead-in,
          // [2] the TextType span. Only [2] holds the word being typed, and it
          // carries a trailing cursor glyph that must come off before matching.
          const typed = h1.children[2];
          return (typed?.textContent ?? "").replace(/[|_▌]\s*$/, "").trim();
        };
        const tick = () => {
          const txt = read();
          if (words.includes(txt)) return resolve(txt);
          if (Date.now() - started > 15000) return resolve(txt);
          requestAnimationFrame(tick);
        };
        tick();
      }),
    TYPED_WORDS as unknown as string[],
  );
  return word;
}

/** Accept the cookie banner so it stays out of every capture. */
async function dismissConsent(page: Page): Promise<void> {
  const accept = page.getByRole("button", { name: /^aceitar$/i }).first();
  if (await accept.count()) {
    await accept.click({ timeout: 3000 }).catch(() => undefined);
    await page.waitForTimeout(500);
  }
}

async function pageBox(el: Locator) {
  return el.evaluate((e) => {
    const r = e.getBoundingClientRect();
    return {
      x: Math.round(r.x + window.scrollX),
      y: Math.round(r.y + window.scrollY),
      w: Math.round(r.width),
      h: Math.round(r.height),
    };
  });
}

// ---------------------------------------------------------------------------

async function main() {
  await assertServer(BASE);
  fs.mkdirSync(OUT_DIR, { recursive: true });
  fs.mkdirSync(path.dirname(LAYOUT_JSON), { recursive: true });

  const layout: Record<string, unknown> = { base: BASE, capturedWith: "playwright" };
  let browser: Browser | undefined;

  try {
    browser = await chromium.launch({
      args: [
        "--force-color-profile=srgb",
        "--disable-lcd-text",
        "--hide-scrollbars",
        // The hero background is a WebGL shader; make sure it actually renders.
        "--use-gl=swiftshader",
        "--enable-unsafe-swiftshader",
      ],
    });

    for (const shot of SHOTS) {
      console.log(`\n▸ ${shot.name}  ${shot.path}  ${shot.viewport.width}x${shot.viewport.height}@${shot.viewport.deviceScaleFactor}x`);

      const ctx = await browser.newContext({
        viewport: { width: shot.viewport.width, height: shot.viewport.height },
        deviceScaleFactor: shot.viewport.deviceScaleFactor,
        isMobile: shot.viewport === MOBILE,
        hasTouch: shot.viewport === MOBILE,
        colorScheme: "dark",
        locale: "pt-BR",
        timezoneId: "America/Sao_Paulo",
      });

      await ctx.addInitScript(() => {
        const g = globalThis as unknown as Record<string, unknown>;
        // tsx compiles this file with esbuild's keepNames, which rewrites the
        // functions passed to page.evaluate into calls to a `__name` helper
        // that only exists in the Node bundle. Provide a no-op.
        g.__name ??= (fn: unknown) => fn;

        // Reveal animations use whileInView with once:false, so any element
        // outside the viewport is held at opacity 0 and REVERTS once scrolled
        // past — a full-page capture would be almost entirely blank. Stubbing
        // IntersectionObserver to report every target as permanently
        // intersecting makes each section animate to its final visible state
        // and stay there, which is exactly the state we want to photograph.
        class AlwaysIntersecting {
          private cb: IntersectionObserverCallback;
          root = null;
          rootMargin = "0px";
          thresholds = [0];
          constructor(cb: IntersectionObserverCallback) {
            this.cb = cb;
          }
          observe(el: Element) {
            const rect = el.getBoundingClientRect();
            this.cb(
              [
                {
                  target: el,
                  isIntersecting: true,
                  intersectionRatio: 1,
                  boundingClientRect: rect,
                  intersectionRect: rect,
                  rootBounds: null,
                  time: 0,
                } as IntersectionObserverEntry,
              ],
              this as unknown as IntersectionObserver,
            );
          }
          unobserve() {}
          disconnect() {}
          takeRecords(): IntersectionObserverEntry[] {
            return [];
          }
        }
        (window as unknown as Record<string, unknown>).IntersectionObserver = AlwaysIntersecting;
      });

      const page = await ctx.newPage();

      try {
        await page.goto(`${BASE}${shot.path}`, { waitUntil: "networkidle", timeout: 60_000 });
        await freeze(page);
        await settle(page);

        // The consent banner is in-memory only (no storage key to pre-seed),
        // so it reappears on every load and would sit in the corner of every
        // plate. Dismiss it the way a visitor would.
        await dismissConsent(page);

        const word = await waitForCompleteWord(page);
        log(`headline word: "${word}"`);

        if (shot.prepare) {
          await shot.prepare(page);
          await settle(page);
        }

        const entry: Record<string, unknown> = {};
        const pageH = await page.evaluate(() => document.documentElement.scrollHeight);
        entry.pageW = shot.viewport.width;
        entry.pageH = pageH;
        entry.scale = shot.viewport.deviceScaleFactor;
        entry.headlineWord = word;

        // ---- full-page plate ----
        if (shot.fullPage) {
          const devicePx = pageH * shot.viewport.deviceScaleFactor;
          if (devicePx > MAX_DEVICE_PX) {
            console.warn(`   ! ${shot.name}: ${devicePx}px exceeds the ${MAX_DEVICE_PX}px raster limit — capturing at 1x.`);
          }
          await page.screenshot({
            path: path.join(OUT_DIR, `${shot.name}-full.png`),
            fullPage: true,
            scale: devicePx > MAX_DEVICE_PX ? "css" : "device",
            animations: "disabled",
          });
          log(`${shot.name}-full.png  pageH=${pageH}`);
        }

        // ---- viewport frame ----
        if (shot.viewportAt) {
          const target = page.locator(shot.viewportAt).first();
          if (await target.count()) {
            const box = await pageBox(target);
            await page.evaluate((y) => window.scrollTo(0, y), box.y);
            await page.waitForTimeout(400);
            await waitForCompleteWord(page);
            await page.screenshot({
              path: path.join(OUT_DIR, `${shot.name}-view.png`),
              scale: "device",
              animations: "disabled",
            });
            log(`${shot.name}-view.png`);
            await page.evaluate(() => window.scrollTo(0, 0));
            await page.waitForTimeout(250);
          }
        }

        // ---- section plates ----
        if (shot.sections?.length) {
          const plates: unknown[] = [];
          for (const s of shot.sections) {
            const target = page.locator(s.selector).first();
            if ((await target.count()) === 0) {
              console.warn(`   ! section "${s.name}" matched nothing: ${s.selector}`);
              continue;
            }
            const box = await pageBox(target);
            const vh = shot.viewport.height;
            const y =
              s.align === "top" || box.h >= vh
                ? box.y
                : Math.max(0, Math.round(box.y - (vh - box.h) / 2));
            await page.evaluate((top) => window.scrollTo(0, top), y);
            await page.waitForTimeout(450);
            // Only the hero plate contains the typing headline, and the word
            // will have advanced during the scroll — re-sync before shooting.
            if (s.name === "hero") await waitForCompleteWord(page);
            const file = `${shot.name}--${s.name}.png`;
            await page.screenshot({
              path: path.join(OUT_DIR, file),
              scale: "device",
              animations: "disabled",
            });
            plates.push({ file, ...box, scrollY: y });
            log(`${file}  @y=${y}`);
          }
          // A hero plate with the typed word REMOVED.
          //
          // Waiting for TextType to report an empty string is not enough: it
          // keeps typing between the check resolving and the shutter, so the
          // plate came back with a stray "s|" baked in. Hiding the span is
          // timing-independent — visibility:hidden keeps the line box, so the
          // layout is untouched and the slot is guaranteed clean. The film
          // composites the four word cutouts into that slot instead.
          if (shot.name === "home") {
            await page.evaluate(() => window.scrollTo(0, 0));
            await page.waitForTimeout(300);
            const hide = await page.addStyleTag({
              content: `h1 > span:nth-child(3) { visibility: hidden !important; }`,
            });
            await page.waitForTimeout(250);
            await page.screenshot({
              path: path.join(OUT_DIR, "home--hero-empty.png"),
              scale: "device",
              animations: "disabled",
            });
            log("home--hero-empty.png");
            await hide.evaluate((el) => (el as Element).remove());
            await page.waitForTimeout(150);
          }

          entry.sections = plates;
          await page.evaluate(() => window.scrollTo(0, 0));
          await page.waitForTimeout(250);
        }

        // ---- boxes ----
        if (shot.boxes?.length) {
          const boxes: Record<string, unknown> = {};
          for (const b of shot.boxes) {
            const loc = page.locator(b.selector);
            const n = await loc.count();
            if (n === 0) {
              console.warn(`   ! box "${b.key}" matched nothing: ${b.selector}`);
              boxes[b.key] = b.all ? [] : null;
              continue;
            }
            const take = b.all ? Math.min(n, b.max ?? n) : 1;
            const out = [];
            for (let i = 0; i < take; i++) out.push(await pageBox(loc.nth(i)));
            boxes[b.key] = b.all ? out : out[0];
          }
          entry.boxes = boxes;
        }

        // ---- cutouts ----
        if (shot.cutouts?.length) {
          const cutouts: unknown[] = [];
          for (const c of shot.cutouts) {
            const loc = page.locator(c.selector);
            const n = await loc.count();
            if (n === 0) {
              console.warn(`   ! cutout "${c.name}" matched nothing: ${c.selector}`);
              continue;
            }
            const take = c.all ? Math.min(n, c.max ?? n) : 1;
            for (let i = 0; i < take; i++) {
              const el = loc.nth(i);
              const file = `${shot.name}__${c.name}${c.all ? i + 1 : ""}.png`;
              try {
                await el.scrollIntoViewIfNeeded({ timeout: 5000 });
                await page.waitForTimeout(220);
                const bb = await pageBox(el);
                const pad = c.pad ?? 0;
                if (pad > 0) {
                  const vp = await el.evaluate((e) => {
                    const r = e.getBoundingClientRect();
                    return { x: r.x, y: r.y, w: r.width, h: r.height };
                  });
                  await page.screenshot({
                    path: path.join(OUT_DIR, file),
                    omitBackground: !!c.omitBackground,
                    scale: "device",
                    animations: "disabled",
                    clip: {
                      x: Math.max(0, vp.x - pad),
                      y: Math.max(0, vp.y - pad),
                      width: Math.min(shot.viewport.width, vp.w + pad * 2),
                      height: Math.min(shot.viewport.height, vp.h + pad * 2),
                    },
                  });
                } else {
                  await el.screenshot({
                    path: path.join(OUT_DIR, file),
                    omitBackground: !!c.omitBackground,
                    scale: "device",
                    animations: "disabled",
                  });
                }
                cutouts.push({ file, ...bb, pad });
                log(`${file}  ${bb.w}x${bb.h}${pad ? ` +${pad}pad` : ""}`);
              } catch (err) {
                console.warn(`   ! cutout ${file} failed: ${(err as Error).message.split("\n")[0]}`);
              }
            }
            await page.evaluate(() => window.scrollTo(0, 0));
          }
          entry.cutouts = cutouts;
        }

        layout[shot.name] = entry;
      } catch (err) {
        console.error(`   ✗ ${shot.name} failed: ${(err as Error).message.split("\n")[0]}`);
        layout[shot.name] = { error: (err as Error).message };
      } finally {
        await ctx.close();
      }
    }

    // ---- the typing headline, one cutout per word ----
    layout.headlineWords = await captureHeadlineWords(browser);

    fs.writeFileSync(LAYOUT_JSON, JSON.stringify(layout, null, 2));
    console.log(`\n✓ wrote ${path.relative(PROJECT, LAYOUT_JSON)}`);
    console.log(`✓ textures in ${path.relative(PROJECT, OUT_DIR)}\n`);
  } finally {
    await browser?.close();
  }
}

/**
 * Capture the hero's typed word once per word, transparent-backed.
 *
 * The cycling headline is this site's signature interaction, so the film
 * rebuilds it from real pixels rather than re-typesetting it: each word is
 * photographed as its own cutout and the video reveals them with a
 * frame-driven clip, in the site's own order.
 *
 * The word cannot be set directly — TextType owns its state — so we simply
 * wait for each one to come around, which takes a few seconds per word.
 */
async function captureHeadlineWords(browser: Browser) {
  console.log(`\n▸ headline words  (${TYPED_WORDS.join(", ")})`);
  const ctx = await browser.newContext({
    viewport: { width: DESKTOP.width, height: DESKTOP.height },
    deviceScaleFactor: 3, // small element, big magnification in the film
    colorScheme: "dark",
    locale: "pt-BR",
  });
  await ctx.addInitScript(() => {
    const g = globalThis as unknown as Record<string, unknown>;
    g.__name ??= (fn: unknown) => fn;
  });
  const page = await ctx.newPage();
  const out: unknown[] = [];

  try {
    await page.goto(`${BASE}/`, { waitUntil: "networkidle", timeout: 60_000 });
    await freeze(page);
    await settle(page);
    await dismissConsent(page);

    // omitBackground only drops the browser's default backdrop — it cannot
    // remove pixels the page paints itself. The hero sits on a WebGL shader
    // canvas plus tinted overlays, all of which would bake into the cutout as
    // a grey slab behind the word. Strip them so the alpha is genuinely clear.
    await page.addStyleTag({
      content: `
        html, body { background: transparent !important; }
        canvas { visibility: hidden !important; }
        section:has(h1) > div:not(:last-child) { visibility: hidden !important; }
      `,
    });
    await page.waitForTimeout(300);

    for (const target of TYPED_WORDS) {
      // Spin until TextType lands on the word we are waiting for.
      const got = await page.evaluate(
        (want) =>
          new Promise<boolean>((resolve) => {
            const started = Date.now();
            const tick = () => {
              const typed = document.querySelector("h1")?.children[2];
              const txt = (typed?.textContent ?? "").replace(/[|_▌]\s*$/, "").trim();
              if (txt === want) return resolve(true);
              if (Date.now() - started > 30000) return resolve(false);
              requestAnimationFrame(tick);
            };
            tick();
          }),
        target,
      );
      if (!got) {
        console.warn(`   ! never saw "${target}" — skipped`);
        continue;
      }
      const el = page.locator("h1 .text-type").first();
      if ((await el.count()) === 0) {
        console.warn("   ! .text-type not found");
        break;
      }
      const file = `headline__${target}.png`;
      const bb = await el.evaluate((e) => {
        const r = e.getBoundingClientRect();
        return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height) };
      });
      await el.screenshot({
        path: path.join(OUT_DIR, file),
        omitBackground: true,
        scale: "device",
        animations: "disabled",
      });
      out.push({ word: target, file, ...bb });
      log(`${file}  ${bb.w}x${bb.h}`);
    }
  } catch (err) {
    console.error(`   ✗ headline words failed: ${(err as Error).message.split("\n")[0]}`);
  } finally {
    await ctx.close();
  }
  return out;
}

main().catch((err) => {
  console.error(`\n✗ capture failed:\n${(err as Error).message}\n`);
  process.exit(1);
});
