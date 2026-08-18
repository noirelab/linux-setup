/**
 * Atmosphere — the film's constant grade: mineral grain, technical grid and
 * vignette. Sits above every scene at low opacity so cuts feel like one piece
 * of film rather than six separate compositions.
 */

import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { COLORS, mulberry32 } from "../theme";

/**
 * Film grain. Rendered as a fixed field of specks whose *opacity* cycles on a
 * short deterministic loop — real grain moves, but a per-frame reshuffle reads
 * as noise. Seeded, so every render produces identical grain.
 */
export const FilmGrain: React.FC<{ opacity?: number; count?: number }> = ({
  opacity = 0.05,
  count = 420,
}) => {
  const frame = useCurrentFrame();
  // 6 distinct grain fields, cycled — enough to read as movement, cheap to draw.
  const phase = frame % 6;
  const rand = mulberry32(9137 + phase * 733);

  const specks = new Array(count).fill(0).map(() => ({
    x: rand() * 100,
    y: rand() * 100,
    r: 0.4 + rand() * 1.1,
    o: 0.25 + rand() * 0.75,
  }));

  return (
    <AbsoluteFill style={{ pointerEvents: "none", opacity, mixBlendMode: "overlay" }}>
      <svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none">
        {specks.map((sp, i) => (
          <circle key={i} cx={sp.x} cy={sp.y} r={sp.r * 0.06} fill="#ffffff" opacity={sp.o} />
        ))}
      </svg>
    </AbsoluteFill>
  );
};

/**
 * Vignette — very subtle. Enough to hold the eye centre-frame, never enough to
 * read as a filter.
 */
export const Vignette: React.FC<{ strength?: number }> = ({ strength = 0.55 }) => (
  <AbsoluteFill
    style={{
      pointerEvents: "none",
      background: `radial-gradient(ellipse 78% 68% at 50% 50%, rgba(0,0,0,0) 42%, rgba(0,0,0,${strength}) 100%)`,
    }}
  />
);

/**
 * TechGrid — a fine orthogonal grid.
 *
 * The background texture should echo the brand: a plotted grid for engineering
 * and software, a 45° hatch for industry, nothing at all for luxury. Swap the
 * backgroundImage below; keep the opacity in the 0.03–0.05 range so it reads as
 * texture rather than decoration.
 */
export const TechGrid: React.FC<{ opacity?: number; drift?: number; size?: number }> = ({
  opacity = 0.05,
  drift = 0,
  size = 64,
}) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{
        pointerEvents: "none",
        opacity,
        // Slow diagonal creep gives dead-black frames a sense of being alive.
        translate: `${((frame * drift) % size).toFixed(3)}px ${((frame * drift) % size).toFixed(3)}px`,
        backgroundImage: `linear-gradient(to right, ${COLORS.border} 1px, transparent 1px), linear-gradient(to bottom, ${COLORS.border} 1px, transparent 1px)`,
        backgroundSize: `${size}px ${size}px`,
      }}
    />
  );
};

/**
 * AccentGlow — a wide bloom in the brand colour.
 *
 * Copy the position and falloff from a radial-gradient the site already paints
 * over its hero, so the film's lighting matches the page's.
 */
export const AccentGlow: React.FC<{ opacity?: number }> = ({ opacity = 0.5 }) => (
  <AbsoluteFill
    style={{
      pointerEvents: "none",
      opacity,
      // TODO: match the site's own hero highlight (position, size, falloff).
      background: `radial-gradient(ellipse 70% 50% at 50% -8%, color-mix(in oklab, ${COLORS.accent} 16%, transparent) 0%, transparent 70%)`,
    }}
  />
);

/**
 * FinalFade — the last breath of the film. Holds fully transparent until the
 * very end, so it costs nothing until it matters.
 */
export const FinalFade: React.FC<{ startFrame: number; durationInFrames: number }> = ({
  startFrame,
  durationInFrames,
}) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{
        pointerEvents: "none",
        backgroundColor: COLORS.black,
        opacity: interpolate(frame, [startFrame, startFrame + durationInFrames], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        }),
      }}
    />
  );
};
