/**
 * Type.tsx — the film's typographic devices.
 *
 * All three reveal text the same way the site's design language implies:
 * a hard edge moves and uncovers the letterforms. Nothing fades in from
 * nowhere, nothing flies.
 */

import { Easing, Interactive, interpolate, useCurrentFrame } from "remotion";
import { COLORS, EASE, FONT, TYPE } from "../theme";

const ease = Easing.bezier(...EASE.out);

/**
 * MaskedTitle — the film's headline device.
 *
 * The line is uncovered by a clip-path edge travelling upward while the text
 * itself rises a few pixels and its tracking tightens from wide to settled.
 * That tracking move is what makes it read as "machined" rather than "animated".
 */
export const MaskedTitle: React.FC<{
  text: string;
  /** Scene-relative frame the reveal starts on. */
  delay?: number;
  durationInFrames?: number;
  fontSize?: number;
  weight?: number;
  color?: string;
  /** Starting letter-spacing in em; settles to `trackingTo`. */
  trackingFrom?: number;
  trackingTo?: number;
  align?: "left" | "center";
  name?: string;
}> = ({
  text,
  delay = 0,
  durationInFrames = 30,
  fontSize = TYPE.hero,
  weight = 800,
  color = COLORS.white,
  trackingFrom = 0.34,
  trackingTo = 0.14,
  align = "center",
  name = "MaskedTitle",
}) => {
  const frame = useCurrentFrame();
  const end = delay + durationInFrames;

  return (
    <Interactive.Div
      name={name}
      style={{
        fontFamily: FONT.family,
        fontSize,
        fontWeight: weight,
        color,
        lineHeight: 1.06,
        textAlign: align,
        whiteSpace: "pre",
        // Reveal edge sweeps up from the baseline. 118% bottom inset keeps
        // descenders hidden until the very end of the move.
        clipPath: `inset(-25% -12% ${interpolate(frame, [delay, end], [118, -25], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease,
        })}% -12%)`,
        letterSpacing: `${interpolate(frame, [delay, end + 8], [trackingFrom, trackingTo], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease,
        })}em`,
        translate: `0px ${interpolate(frame, [delay, end], [26, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease,
        })}px`,
      }}
    >
      {text}
    </Interactive.Div>
  );
};

/**
 * KineticText — supporting copy. Rises and fades, with an optional exit so a
 * line can hand over to the next one without a cut.
 */
export const KineticText: React.FC<{
  text: string;
  delay?: number;
  durationInFrames?: number;
  /** Frame (scene-relative) at which the line starts leaving. Omit to persist. */
  exitAt?: number;
  fontSize?: number;
  weight?: number;
  color?: string;
  opacity?: number;
  letterSpacing?: string;
  align?: "left" | "center";
  maxWidth?: number;
  name?: string;
}> = ({
  text,
  delay = 0,
  durationInFrames = 22,
  exitAt,
  fontSize = TYPE.support,
  weight = 500,
  color = COLORS.muted,
  opacity = 1,
  letterSpacing = "0em",
  align = "center",
  maxWidth,
  name = "KineticText",
}) => {
  const frame = useCurrentFrame();
  const inEnd = delay + durationInFrames;
  const outEnd = exitAt === undefined ? undefined : exitAt + 14;

  return (
    <Interactive.Div
      name={name}
      style={{
        fontFamily: FONT.family,
        fontSize,
        fontWeight: weight,
        color,
        letterSpacing,
        textAlign: align,
        lineHeight: 1.35,
        maxWidth,
        opacity:
          outEnd === undefined
            ? interpolate(frame, [delay, inEnd], [0, opacity], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
                easing: ease,
              })
            : interpolate(frame, [delay, inEnd, exitAt!, outEnd], [0, opacity, opacity, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
                easing: ease,
              }),
        translate: `0px ${interpolate(frame, [delay, inEnd], [14, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease,
        })}px`,
      }}
    >
      {text}
    </Interactive.Div>
  );
};

/**
 * SectionLabel — the small tag used while travelling through the site.
 *
 * A short accent rule draws first, then the word appears beside it. Sized at
 * 40px so it stays above the film's 32px floor for supporting text.
 */
export const SectionLabel: React.FC<{
  text: string;
  delay?: number;
  exitAt?: number;
  name?: string;
}> = ({ text, delay = 0, exitAt, name = "SectionLabel" }) => {
  const frame = useCurrentFrame();
  const outEnd = exitAt === undefined ? undefined : exitAt + 12;

  const groupOpacity =
    outEnd === undefined
      ? interpolate(frame, [delay, delay + 14], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease,
        })
      : interpolate(frame, [delay, delay + 14, exitAt!, outEnd], [0, 1, 1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: ease,
        });

  return (
    <Interactive.Div
      name={name}
      style={{
        display: "flex",
        alignItems: "center",
        gap: 20,
        opacity: groupOpacity,
      }}
    >
      <div
        style={{
          height: 4,
          width: 72,
          backgroundColor: COLORS.accent,
          boxShadow: `0 0 22px ${COLORS.accent}`,
          // The rule draws itself before the word arrives.
          scale: `${interpolate(frame, [delay, delay + 18], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: ease,
          })} 1`,
          transformOrigin: "left center",
        }}
      />
      <div
        style={{
          fontFamily: FONT.family,
          fontSize: TYPE.label,
          fontWeight: 800,
          color: COLORS.white,
          letterSpacing: "0.02em",
          whiteSpace: "nowrap",
          // Text follows the rule by 6 frames — a beat, not a simultaneity.
          clipPath: `inset(-20% ${interpolate(frame, [delay + 6, delay + 26], [100, -10], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: ease,
          })}% -20% -4%)`,
          // Scrim so the label survives over bright parts of the page texture.
          textShadow: "0 2px 18px rgba(0,0,0,0.95), 0 0 42px rgba(0,0,0,0.8)",
        }}
      >
        {text}
      </div>
    </Interactive.Div>
  );
};
