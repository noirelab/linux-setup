/**
 * PageCam — a 2.5D camera flying over a real full-page screenshot.
 *
 * (cx, cy) is the page-space CSS point held at frame centre; `zoom` is scale
 * (1 => 1 CSS px = 1 output px).
 *
 * The frame centre is read from useVideoConfig(), NOT hardcoded, so the same
 * camera works in a 1920x1080 film and a 1080x1920 Story without touching the
 * keyframes. Hardcoding 960/540 silently offsets every shot in any other size.
 *
 * THE IMPORTANT PART — why magnification uses the CSS `zoom` property and not
 * `transform: scale()`: Chromium rasterises a 3D-composited layer at its LAYOUT
 * size and then GPU-upscales it, so every glyph is downsampled before
 * being magnified — text goes to mush and no amount of camera or DoF tuning fixes
 * it. `zoom` scales the layout box itself, so the page rasterises at the enlarged
 * device size and samples DOWN from the 2x texture. Sharp type under perspective.
 *
 * Coordinate math that follows from that: `zoom` scales this element's local
 * coordinate space, so a page point (cx,cy) lands at (cx*zoom, cy*zoom) device px
 * from the box origin and a translate(Tx) renders as Tx*zoom. To hold (cx,cy) at
 * the frame centre (halfW,halfH):  cx*zoom + Tx*zoom = halfW  =>  Tx = halfW/zoom - cx.
 * Skip that conversion and the camera silently drifts off its focal point.
 */

import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { COLORS, EASE } from "../theme";

export type CamKey = {
  frame: number;
  /** Page-space point held at frame centre, in CSS px. */
  cx: number;
  cy: number;
  zoom: number;
  /** Tilt about the vertical axis; positive = right edge recedes. */
  rotY?: number;
  /** Tilt about the horizontal axis; positive = top leans away. */
  rotX?: number;
  rotZ?: number;
  /** Perspective strength in px — smaller is stronger. */
  persp?: number;
};

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

export const PageCam: React.FC<{
  /** Texture path under public/, e.g. "textures/home-full.png". */
  src: string;
  /** Page height in CSS px (from layout.json). */
  pageH: number;
  pageW?: number;
  keys: CamKey[];
  /** Page-space overlays, positioned in CSS px inside the page plane. */
  children?: React.ReactNode;
  /**
   * Page-space layer rendered BEHIND the texture.
   *
   * For pages whose hero is a <video>: capture the page with the video hidden
   * and the document background cleared (alpha plate), then pass the real
   * video here at the hero's page coordinates. The site's own gradients are
   * semi-transparent in the plate, so they darken the moving footage exactly
   * as they do live — and the hero stops being a frozen frame.
   */
  backdrop?: React.ReactNode;
  /** Screen-space depth-of-field band approximating a focal plane. */
  dof?: { focusY: number; strength: number };
  ease?: (t: number) => number;
  /** Absolute frame override when mounted inside a rebased <Sequence>. */
  frame?: number;
}> = ({
  src,
  pageH,
  pageW = 1920,
  keys,
  children,
  backdrop,
  dof,
  ease = Easing.bezier(...EASE.drift),
  frame: frameProp,
}) => {
  const ownFrame = useCurrentFrame();
  const frame = frameProp ?? ownFrame;
  const { width: compW, height: compH } = useVideoConfig();
  const halfW = compW / 2;
  const halfH = compH / 2;

  // Locate the active keyframe segment.
  let a = keys[0];
  let b = keys[keys.length - 1];
  for (let i = 0; i < keys.length - 1; i++) {
    if (frame >= keys[i].frame && frame <= keys[i + 1].frame) {
      a = keys[i];
      b = keys[i + 1];
      break;
    }
  }

  const t =
    a.frame === b.frame
      ? 1
      : interpolate(frame, [a.frame, b.frame], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease,
        });

  const cx = lerp(a.cx, b.cx, t);
  const cy = lerp(a.cy, b.cy, t);
  const zoom = lerp(a.zoom, b.zoom, t);
  const rotX = lerp(a.rotX ?? 0, b.rotX ?? 0, t);
  const rotY = lerp(a.rotY ?? 0, b.rotY ?? 0, t);
  const rotZ = lerp(a.rotZ ?? 0, b.rotZ ?? 0, t);
  const persp = lerp(a.persp ?? 1600, b.persp ?? 1600, t);

  return (
    <AbsoluteFill style={{ overflow: "hidden", backgroundColor: COLORS.black }}>
      <div
        style={{
          position: "absolute",
          inset: 0,
          perspective: `${persp * zoom}px`,
          perspectiveOrigin: `${halfW}px ${halfH}px`,
        }}
      >
        <div
          style={{
            position: "absolute",
            width: pageW,
            height: pageH,
            // Layout-scale magnification — see the header comment.
            zoom,
            transform: `translate(${halfW / zoom - cx}px, ${halfH / zoom - cy}px) rotateY(${rotY}deg) rotateX(${rotX}deg) rotateZ(${rotZ}deg)`,
            // Rotations pivot about the focal point, so it stays framed.
            transformOrigin: `${cx}px ${cy}px`,
            transformStyle: "preserve-3d",
          }}
        >
          {backdrop}
          <Img
            src={staticFile(src)}
            style={{ position: "absolute", width: pageW, height: pageH }}
          />
          {children}
        </div>
      </div>

      {dof ? (
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            top: 0,
            height: Math.max(0, dof.focusY),
            backdropFilter: `blur(${dof.strength}px)`,
            WebkitBackdropFilter: `blur(${dof.strength}px)`,
            maskImage:
              "linear-gradient(to bottom, rgba(0,0,0,1) 0%, rgba(0,0,0,1) 40%, rgba(0,0,0,0) 100%)",
            WebkitMaskImage:
              "linear-gradient(to bottom, rgba(0,0,0,1) 0%, rgba(0,0,0,1) 40%, rgba(0,0,0,0) 100%)",
            pointerEvents: "none",
          }}
        />
      ) : null}
    </AbsoluteFill>
  );
};

/**
 * PagePlate — a captured region pinned over its real coordinates in the page,
 * cross-fading in and out.
 *
 * Used for the product tab switch: the ornamental-stones section is a separate
 * capture (the tab makes the section grow 663px -> 810px, so it cannot reuse the
 * base plate's geometry) laid over the same page-space origin. Because it sits
 * inside the page plane it inherits the camera's perspective for free, so the
 * swap reads as the site's own tab interaction rather than a cut.
 */
export const PagePlate: React.FC<{
  src: string;
  x: number;
  y: number;
  w: number;
  h: number;
  /** Absolute frames: fade in over [in, in+dur], out over [out, out+dur]. */
  fadeIn: number;
  fadeOut?: number;
  fadeFrames?: number;
  frame?: number;
}> = ({ src, x, y, w, h, fadeIn, fadeOut, fadeFrames = 16, frame: frameProp }) => {
  const ownFrame = useCurrentFrame();
  const frame = frameProp ?? ownFrame;

  const opacity =
    fadeOut === undefined
      ? interpolate(frame, [fadeIn, fadeIn + fadeFrames], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: Easing.bezier(...EASE.out),
        })
      : interpolate(
          frame,
          [fadeIn, fadeIn + fadeFrames, fadeOut, fadeOut + fadeFrames],
          [0, 1, 1, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.bezier(...EASE.out) },
        );

  if (opacity <= 0) return null;

  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: w,
        height: h,
        opacity,
        // Nudged toward camera so it wins the depth test over the base texture.
        transform: "translateZ(0.5px)",
        transformStyle: "preserve-3d",
      }}
    >
      <Img src={staticFile(src)} style={{ width: "100%", height: "100%" }} />
    </div>
  );
};

/**
 * PageChip — an element cutout that flies into its REAL slot in the page layout.
 *
 * Coordinates come from layout.json, so the chip lands exactly where the browser
 * put it: the element seats into the page instead of hovering above it. Travel
 * happens on translateZ (toward camera) plus a small offset, so it shares the
 * page's perspective the whole way in.
 */
export const PageChip: React.FC<{
  src: string;
  /** Page-space bbox from layout.json. */
  x: number;
  y: number;
  w: number;
  h: number;
  /** Extra padding baked into the cutout PNG (capture script `pad`). */
  pad?: number;
  /** Absolute frame the chip starts flying in. */
  from: number;
  durationInFrames?: number;
  /** Z distance it travels from, in px. */
  liftZ?: number;
  /** Y offset it travels from, in px. */
  liftY?: number;
  /**
   * Frames to reach full opacity.
   *
   * Keep this SHORT (2–4) whenever the base texture already contains the same
   * element underneath — which it does unless an "empty plate" was captured.
   * A slow fade over identical baked content shows both copies at once and
   * reads as a ghost, most visibly on high-contrast text.
   */
  fadeFrames?: number;
  frame?: number;
}> = ({
  src,
  x,
  y,
  w,
  h,
  pad = 0,
  from,
  durationInFrames = 26,
  liftZ = 150,
  liftY = 34,
  fadeFrames = 8,
  frame: frameProp,
}) => {
  const ownFrame = useCurrentFrame();
  const frame = frameProp ?? ownFrame;

  // Weighted entry: breaks inertia slowly, arrives decisively, no overshoot.
  const t = interpolate(frame, [from, from + durationInFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...EASE.out),
  });

  return (
    <div
      style={{
        position: "absolute",
        left: x - pad,
        top: y - pad,
        width: w + pad * 2,
        height: h + pad * 2,
        opacity: interpolate(frame, [from, from + fadeFrames], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        }),
        transform: `translateZ(${(1 - t) * liftZ}px) translateY(${(1 - t) * liftY}px)`,
        transformStyle: "preserve-3d",
        // Contact shadow fades in as the chip seats down onto the page.
        filter: `drop-shadow(0 ${18 * (1 - t) + 6}px ${30 * (1 - t) + 12}px rgba(0,0,0,${0.55 * (1 - t) + 0.25}))`,
      }}
    >
      <Img src={staticFile(src)} style={{ width: "100%", height: "100%" }} />
    </div>
  );
};
