/**
 * theme.ts — the film's single source of visual truth.  [TEMPLATE]
 *
 * Fill every value from the SITE's own CSS, not from its design doc. Design
 * docs go stale: on one project the doc said teal and the app shipped green.
 * Read computed styles on the running site and copy what it actually renders.
 *
 * Keep the site's colour space. If the site is authored in oklch, keep oklch —
 * Chromium renders it natively and the film then composites in the same space
 * as the screenshots.
 *
 * The component set (Accent, Atmosphere, Frames, Type) reads ONLY these six
 * colour tokens, so re-skinning a whole film is this one block.
 */

export const COLORS = {
  /** Brand accent. The one colour the film is allowed to use as light. */
  accent: "#TODO",
  /** Optional deeper / brighter variants for gradients. */
  accentDeep: "#TODO",
  accentBright: "#TODO",

  /** Page background. */
  black: "#TODO",
  /** Elevated surface — browser chrome, card fills. */
  surface: "#TODO",
  /** 1px hairline used across the site's cards. */
  border: "#TODO",
  /** High-contrast text. */
  white: "#TODO",
  /** Support copy. */
  muted: "#TODO",
} as const;

export const FONT = {
  /**
   * Use the face the site ACTUALLY renders.
   *
   * Check `document.fonts` on the running site: a declared display face that
   * never loads means every heading falls back to system-ui, and setting the
   * film in the declared face would clash with the screenshots beside it. If
   * the intended face is unavailable, pick the closest one that loads reliably
   * from @remotion/google-fonts and note the substitution in the README.
   */
  family: "TODO",
  weights: [400, 500, 600, 700, 800],
} as const;

/**
 * Type scale in FINAL OUTPUT PIXELS.
 *
 * The floors are not stylistic: narrative captions must clear 56px (~5.2% of
 * frame height) and supporting text 32px, because a 1080p film gets watched in
 * a phone-sized window. Measure the RENDERED pixel height — fontSize times
 * every ancestor scale, times perspective compression in 3D shots.
 */
export const TYPE = {
  hero: 92,
  title: 72,
  caption: 60,
  captionSmall: 52,
  label: 40,
  support: 34,
  fine: 30,
  credit: 26,
} as const;

/** Safe area. Nothing that must be read may sit outside this inset. */
export const SAFE = 96;

/**
 * Motion. Tune to the brand.
 *
 *   Heavy industry  -> long decisive settles; mass and inertia.
 *   Software studio -> quicker and drier; precision and snap, [0.4, 0, 0.2, 1].
 *
 * Neither bounces. Springs use high damping and near-zero overshoot.
 */
export const EASE = {
  /** Long, decisive settle. The film's default. */
  out: [0.16, 1, 0.3, 1] as const,
  /** Symmetric move for camera travel between two rest points. */
  inOut: [0.65, 0, 0.35, 1] as const,
  /** Weighted start — for mass breaking inertia. */
  in: [0.55, 0, 1, 0.45] as const,
  /** Camera drift: barely-there acceleration, never a hard stop. */
  drift: [0.33, 0, 0.15, 1] as const,
} as const;

/** Deterministic PRNG — never Math.random(), so every render matches. */
export function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
