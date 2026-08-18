/**
 * format.ts — lets one scene serve both the 16:9 film and the 9:16 Story.
 *
 * Scenes that are pure centred layouts (title cards, end cards) reflow between
 * orientations on their own; all they need is a type scale that fits the
 * narrower frame. Those scenes call `useFormat()` and pick sizes from it,
 * instead of being duplicated.
 *
 * Scenes built around the desktop page — the browser frame, the page travel —
 * cannot reflow, because a 1920px-wide page simply does not fit a 1080px frame.
 * Those get purpose-built vertical variants in `src/vertical/`, driven by the
 * Story-viewport captures (540x960 @2x, which rasterise 1:1 into the frame).
 */

import { useVideoConfig } from "remotion";

export type Format = {
  isVertical: boolean;
  width: number;
  height: number;
  /**
   * Type multiplier. The Story frame is 1080 wide against the film's 1920, so
   * a headline set for the film overruns it; but a Story is watched full-screen
   * on a phone, so type does not need to shrink proportionally. 0.62 keeps the
   * long wordmark inside the safe area while staying comfortably above the
   * legibility floor.
   */
  typeScale: number;
  /** Safe area. Tighter horizontally in vertical, where width is the scarce axis. */
  safe: number;
  /** Width available to a centred block, after safe margins. */
  contentWidth: number;
};

export const useFormat = (): Format => {
  const { width, height } = useVideoConfig();
  const isVertical = height > width;
  const safe = isVertical ? 72 : 96;

  return {
    isVertical,
    width,
    height,
    typeScale: isVertical ? 0.62 : 1,
    safe,
    contentWidth: width - safe * 2,
  };
};
