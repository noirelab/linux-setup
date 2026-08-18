/**
 * AccentRule + ScreenWipe + LightSweep — the film's connective tissue.
 *
 * The rule should be lifted from something the SITE already draws — a glowing
 * divider, a highlighted border, a progress bar. Ported to the film it becomes
 * the connective element: it opens, marks each beat, and closes.
 *
 * All colour comes from theme.ts, so re-skinning is one file.
 */

import { Easing, Interactive, interpolate, useCurrentFrame } from "remotion";
import { COLORS, EASE } from "../theme";

const ease = Easing.bezier(...EASE.out);

export const AccentRule: React.FC<{
  delay?: number;
  durationInFrames?: number;
  /** Rule width at rest, in px. */
  width?: number;
  thickness?: number;
  /** Fade the rule back out starting here. */
  exitAt?: number;
  glow?: number;
  name?: string;
}> = ({
  delay = 0,
  durationInFrames = 18,
  width = 760,
  thickness = 3,
  exitAt,
  glow = 30,
  name = "AccentRule",
}) => {
  const frame = useCurrentFrame();
  const outEnd = exitAt === undefined ? undefined : exitAt + 12;

  return (
    <Interactive.Div
      name={name}
      style={{
        width,
        height: thickness,
        // Grows out of its own centre — the gesture of a measuring tool.
        scale: `${interpolate(frame, [delay, delay + durationInFrames], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease,
        })} 1`,
        opacity:
          outEnd === undefined
            ? 1
            : interpolate(frame, [exitAt!, outEnd], [1, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
        background: `linear-gradient(to right, transparent, ${COLORS.accent} 22%, ${COLORS.accent} 78%, transparent)`,
        boxShadow: `0 0 ${glow}px ${COLORS.accent}`,
      }}
    />
  );
};

/**
 * ScreenWipe — a full-bleed accent bar that crosses the frame. Used at hard
 * cuts so the edit reads as one continuous gesture instead of six splices.
 */
export const ScreenWipe: React.FC<{
  delay?: number;
  durationInFrames?: number;
  height?: number;
  direction?: "ltr" | "rtl";
}> = ({ delay = 0, durationInFrames = 16, height = 6, direction = "ltr" }) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [delay, delay + durationInFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...EASE.inOut),
  });
  const x = direction === "ltr" ? -1920 + t * 3840 : 1920 - t * 3840;

  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        top: `calc(50% - ${height / 2}px)`,
        width: 1920,
        height,
        translate: `${x}px 0px`,
        background: `linear-gradient(to right, transparent, ${COLORS.accent} 40%, ${COLORS.accent} 60%, transparent)`,
        boxShadow: `0 0 46px ${COLORS.accent}`,
        // Vanishes at the extremes so it never parks on screen.
        opacity: interpolate(t, [0, 0.12, 0.88, 1], [0, 1, 1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        }),
      }}
    />
  );
};

/**
 * LightSweep — a single specular pass over a surface.
 *
 * Deliberately used ONCE in the whole film, on the browser glass in scene 2.
 * The parent must clip it (border-radius + overflow hidden): light spilling
 * past a rounded corner is the classic tell of a cheap template.
 */
export const LightSweep: React.FC<{
  delay: number;
  durationInFrames?: number;
  /** Sweep angle in degrees. */
  angle?: number;
  opacity?: number;
}> = ({ delay, durationInFrames = 34, angle = 18, opacity = 0.16 }) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [delay, delay + durationInFrames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...EASE.inOut),
  });

  // Nothing renders outside the sweep window — keeps the surface clean.
  if (t <= 0 || t >= 1) return null;

  return (
    <div
      style={{
        position: "absolute",
        inset: "-30%",
        pointerEvents: "none",
        translate: `${-140 + t * 280}%  0%`,
        rotate: `${angle}deg`,
        background: `linear-gradient(to right, rgba(255,255,255,0) 0%, rgba(255,255,255,${opacity}) 45%, rgba(255,255,255,${opacity * 1.5}) 50%, rgba(255,255,255,${opacity}) 55%, rgba(255,255,255,0) 100%)`,
        // Ease the sweep's own presence so it doesn't pop at the edges.
        opacity: interpolate(t, [0, 0.15, 0.85, 1], [0, 1, 1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        }),
      }}
    />
  );
};
