/**
 * Frames.tsx — the physical objects the website is presented on.
 *
 * BrowserFrame and DevicePanel are built from the site's own surface tokens
 * (#18181B chrome, #3F3F46 hairline) rather than a generic mockup skin. No
 * laptop bezels, no floating drop shadows without a light direction.
 */

import { Easing, Img, interpolate, staticFile, useCurrentFrame } from "remotion";
import { COLORS, EASE, FONT } from "../theme";
import { LightSweep } from "./YellowRule";

const ease = Easing.bezier(...EASE.out);

/**
 * BrowserFrame — a restrained browser shell that assembles itself.
 *
 * The chrome bar wipes in first, then its contents, then the page. Assembly
 * order is what makes it read as construction rather than a fade-in.
 */
export const BrowserFrame: React.FC<{
  /** Screenshot under public/. */
  src: string;
  url: string;
  width: number;
  height: number;
  /** Scene-relative frame the frame starts drawing. */
  delay?: number;
  /** Frame the light sweep crosses the glass. Omit for no sweep. */
  sweepAt?: number;
  /**
   * Layer rendered BEHIND the page screenshot — for an alpha plate whose hero
   * is a live <video> rather than a baked frame.
   */
  backdrop?: React.ReactNode;
  children?: React.ReactNode;
}> = ({ src, url, width, height, delay = 0, sweepAt, backdrop, children }) => {
  const frame = useCurrentFrame();
  const CHROME = 52;

  return (
    <div
      style={{
        width,
        height: height + CHROME,
        borderRadius: 16,
        overflow: "hidden",
        backgroundColor: COLORS.charcoalLight,
        border: `1px solid ${COLORS.border}`,
        // Directional light: the key is above and slightly left, so the shell
        // carries a soft top rim and drops its weight downward.
        boxShadow: `
          0 2px 0 rgba(255,255,255,0.06) inset,
          0 60px 120px -30px rgba(0,0,0,0.9),
          0 18px 44px -12px rgba(0,0,0,0.7)`,
        // Vertical assembly wipe.
        clipPath: `inset(0% 0% ${interpolate(frame, [delay, delay + 20], [100, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease,
        })}% 0%)`,
        position: "relative",
      }}
    >
      {/* ---- chrome bar ---- */}
      <div
        style={{
          height: CHROME,
          display: "flex",
          alignItems: "center",
          gap: 10,
          paddingInline: 20,
          backgroundColor: COLORS.charcoalLight,
          borderBottom: `1px solid ${COLORS.border}`,
          opacity: interpolate(frame, [delay + 8, delay + 20], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            style={{
              width: 11,
              height: 11,
              borderRadius: "50%",
              backgroundColor: COLORS.border,
              // Dots arrive in sequence — a small mechanical tell.
              scale: `${interpolate(frame, [delay + 10 + i * 3, delay + 20 + i * 3], [0, 1], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
                easing: ease,
              })}`,
            }}
          />
        ))}
        <div
          style={{
            marginLeft: 16,
            flex: 1,
            maxWidth: 460,
            height: 30,
            borderRadius: 8,
            backgroundColor: COLORS.black,
            border: `1px solid ${COLORS.border}`,
            display: "flex",
            alignItems: "center",
            paddingInline: 14,
            fontFamily: FONT.family,
            fontSize: 15,
            fontWeight: 600,
            color: COLORS.muted,
            letterSpacing: "0.01em",
            opacity: interpolate(frame, [delay + 16, delay + 28], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
          }}
        >
          {url}
        </div>
      </div>

      {/* ---- page ---- */}
      <div style={{ position: "relative", width, height, overflow: "hidden" }}>
        {backdrop ? (
          <div
            style={{
              position: "absolute",
              inset: 0,
              opacity: interpolate(frame, [delay + 20, delay + 32], [0, 1], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
            }}
          >
            {backdrop}
          </div>
        ) : null}
        <Img
          src={staticFile(src)}
          style={{
            width,
            height,
            objectFit: "cover",
            objectPosition: "top center",
            opacity: interpolate(frame, [delay + 20, delay + 32], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
            // Settles from a hair over-scale; reads as the page "arriving".
            scale: interpolate(frame, [delay + 20, delay + 58], [1.06, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
              easing: ease,
              output: "perceptual-scale",
            }),
          }}
        />
        {children}
        {sweepAt !== undefined ? <LightSweep delay={sweepAt} /> : null}
      </div>
    </div>
  );
};

/**
 * DevicePanel — a phone-shaped panel, not a phone mockup.
 *
 * Just the site's own card language at device proportions: 44px radius, the
 * same 1px zinc hairline, real directional shadow. No notch, no chunky bezel,
 * no glossy plastic — those are the things that make showcase reels look cheap.
 */
export const DevicePanel: React.FC<{
  src: string;
  width: number;
  height: number;
  delay?: number;
  /** Y-axis tilt in degrees; pair two panels with opposite signs for volume. */
  rotY?: number;
  /** Direction the panel travels in from, in px. */
  fromX?: number;
  /**
   * Crop anchor. The mobile drawer occupies the right 360px of a 430px
   * viewport, so "top right" is what shows the drawer cleanly instead of a
   * muddy strip of the dimmed page behind it.
   */
  objectPosition?: string;
}> = ({ src, width, height, delay = 0, rotY = 0, fromX = 0, objectPosition = "top center" }) => {
  const frame = useCurrentFrame();

  const t = interpolate(frame, [delay, delay + 30], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease,
  });

  return (
    <div
      style={{
        width,
        height,
        borderRadius: 44,
        overflow: "hidden",
        border: `1px solid ${COLORS.border}`,
        backgroundColor: COLORS.black,
        opacity: interpolate(frame, [delay, delay + 12], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        }),
        transform: `translateX(${(1 - t) * fromX}px) rotateY(${rotY}deg) translateZ(0px)`,
        boxShadow: `
          0 1px 0 rgba(255,255,255,0.07) inset,
          0 48px 90px -24px rgba(0,0,0,0.95),
          0 14px 30px -8px rgba(0,0,0,0.7)`,
      }}
    >
      <Img src={staticFile(src)} style={{ width, height, objectFit: "cover", objectPosition }} />
    </div>
  );
};

/**
 * FloatingPanel — a captured UI element presented on its own, with depth.
 * Used for the quote assistant close-up.
 */
export const FloatingPanel: React.FC<{
  src: string;
  width: number;
  height: number;
  delay?: number;
  rotY?: number;
}> = ({ src, width, height, delay = 0, rotY = 0 }) => {
  const frame = useCurrentFrame();

  return (
    <div
      style={{
        width,
        height,
        borderRadius: 24,
        overflow: "hidden",
        border: `1px solid ${COLORS.border}`,
        transform: `rotateY(${rotY}deg)`,
        boxShadow: `
          0 1px 0 rgba(255,255,255,0.08) inset,
          0 56px 110px -28px rgba(0,0,0,0.95),
          0 16px 36px -10px rgba(0,0,0,0.75)`,
        // Uncovered bottom-up, matching the film's masking language.
        clipPath: `inset(${interpolate(frame, [delay, delay + 22], [100, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease,
        })}% 0% 0% 0%)`,
      }}
    >
      <Img src={staticFile(src)} style={{ width, height, objectFit: "cover" }} />
    </div>
  );
};
