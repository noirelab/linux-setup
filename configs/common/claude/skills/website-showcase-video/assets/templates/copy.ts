/**
 * copy.ts — every word that appears on screen.  [TEMPLATE]
 *
 * Two rules:
 *
 * 1. Every line must be traceable to the live site. Annotate each with its
 *    source. If a claim is not on the site, it does not go in the film.
 *
 * 2. Never write a caption that repeats a heading already large on screen.
 *    The page's own titles are visible in most travel shots; the film's caption
 *    carries the NARRATIVE line — the thing the picture does not already say.
 *
 * Author line breaks here as `\n` (scenes render with `white-space: pre`) so
 * ragging is a typographic decision, not a container-width side effect.
 *
 * When changing copy, re-check the legibility floors in theme.ts (TYPE) and
 * confirm with `npm run showcase:stills` that nothing overruns the safe area.
 */

export const COPY = {
  /** The brand, as it should be set in the film. */
  brand: "TODO",

  /** Scene 1 — positioning line. Source: TODO */
  openingSub: "TODO",

  /** Scene 2 — over the real hero screenshot. Source: TODO */
  revealCaption: "TODO",

  /**
   * Scene 3 — section markers.
   *
   * Prefer the narrative line over the section's own title: if the heading is
   * already legible in frame, repeating it wastes the caption.
   */
  labels: {
    /** Source: TODO */
    first: "TODO",
    /** Source: TODO */
    second: "TODO",
  },

  /** Scene 4 — a real feature, captured in its real state. Source: TODO */
  detailCaption: "TODO",

  /** Scene 5 — commercial payoff. Source: TODO */
  valueLine1: "TODO",
  valueLine2: "TODO",

  /** Scene 6 — end card. Source: TODO */
  endTagline: "TODO",
  endContact: "TODO",

  /** The site's real production URL, for the browser frame. */
  browserUrl: "TODO",

  /**
   * Optional studio bumper (its own scene, AFTER the client's card has faded).
   * Do not also put a credit line inside the client's end card — that says the
   * same thing twice and divides the client's signature.
   */
  outroLead: "Website desenvolvido por",
  outroBrand: "TODO",
  outroUrl: "TODO",
} as const;
