/**
 * HeroVideo — the site's real hero footage, playing behind an alpha plate.
 *
 * The homepage hero's background is a <video>. The capture pipeline freezes it
 * at a fixed timestamp so the screenshots stay reproducible, which is correct
 * for a screenshot and wrong for a film: the water stops moving.
 *
 * So the capture also emits alpha plates (`*-full-alpha.png`, `*--hero-alpha.png`)
 * shot with the video hidden and the document background cleared. Those are
 * transparent exactly over the hero — every section below paints its own
 * background — and the site's gradients survive in them as semi-transparent
 * black. Drop this component behind such a plate and the hero moves again,
 * darkened by the page's own gradients, with the real headline and CTAs on top.
 *
 * Positioned in PAGE coordinates when used inside PageCam, so it travels with
 * the 2.5D camera like any other page-space layer.
 */

import { Video } from "@remotion/media";
import { staticFile } from "remotion";

/** Intrinsic size of public/media/hero.mp4. */
const SRC_W = 1920;
const SRC_H = 1080;

export const HeroVideo: React.FC<{
  /** Hero box in page CSS px. Defaults to the desktop hero. */
  width?: number;
  height?: number;
  x?: number;
  y?: number;
  /**
   * Frames to skip into the clip. Pass the accumulated length of the earlier
   * scenes so the footage stays continuous across a cut instead of snapping
   * back to its first frame.
   */
  trimBefore?: number;
  /** Absolute layout instead of filling the parent. */
  absolute?: boolean;
}> = ({ width = 1920, height = 1080, x = 0, y = 0, trimBefore = 0, absolute = true }) => {
  /*
   * Cover-fit computed explicitly rather than via `objectFit: "cover"`.
   *
   * That CSS property is not reliably honoured on this media element, which is
   * invisible while the box stays 16:9 (the landscape frame) and very visible
   * the moment it is not: in a 9:16 Story box the 16:9 clip came out as a
   * letterboxed band with black above and below. Doing the arithmetic matches
   * the site's own `object-cover` in every frame size.
   */
  const scale = Math.max(width / SRC_W, height / SRC_H);
  const drawW = SRC_W * scale;
  const drawH = SRC_H * scale;

  return (
    <div
      style={
        absolute
          ? { position: "absolute", left: x, top: y, width, height, overflow: "hidden" }
          : { position: "absolute", inset: 0, overflow: "hidden" }
      }
    >
      <Video
        src={staticFile("media/hero.mp4")}
        trimBefore={trimBefore}
        // The site plays it muted; the film has its own sound design.
        volume={0}
        style={{
          position: "absolute",
          width: drawW,
          height: drawH,
          left: (width - drawW) / 2,
          top: (height - drawH) / 2,
        }}
      />
    </div>
  );
};
