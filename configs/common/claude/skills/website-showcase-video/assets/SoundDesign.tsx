/**
 * SoundDesign — every sound in the film, driven by the cue table in timing.ts.
 *
 * Two rules encoded here:
 *   1. SFX are pinned to absolute frames, so when the edit moves, one table
 *      changes and the whole audio pass moves with it.
 *   2. Music never covers the effects. The bed sits at 0.28 and ducks under
 *      the two biggest hits.
 */

import { Audio } from "@remotion/media";
import { Sequence, interpolate, staticFile } from "remotion";
import { CUES, MUSIC, TOTAL_FRAMES } from "./timing";

/**
 * Whether a music bed exists. The repository ships without a cleared track, so
 * this stays false until someone drops a file at public/audio/music.mp3 and
 * flips it (see README → "Trocar a música").
 */
export const HAS_MUSIC = false;

export const SoundDesign: React.FC<{ withMusic?: boolean }> = ({ withMusic = HAS_MUSIC }) => {
  return (
    <>
      {CUES.map((cue, i) => (
        // Each cue is its own Sequence so the sample starts exactly on `frame`
        // and, where a duration is given, is cut to the length of its action.
        <Sequence
          key={`${cue.file}-${cue.frame}-${i}`}
          from={cue.frame}
          durationInFrames={cue.durationInFrames ?? TOTAL_FRAMES - cue.frame}
          layout="none"
          name={`sfx: ${cue.note}`}
        >
          {/* Constant level, but declared as a callback so Remotion evaluates
              it per frame against the Sequence's own clock. */}
          <Audio src={staticFile(`audio/sfx/${cue.file}`)} volume={() => cue.volume} />
        </Sequence>
      ))}

      {withMusic ? <MusicBed /> : null}
    </>
  );
};

/**
 * Music bed with frame-driven fades at both ends.
 *
 * The volume callback receives the frame relative to this Audio tag, which is
 * what the fades should key off — reading useCurrentFrame() from the enclosing
 * component would silently drift if the bed were ever moved into a Sequence.
 */
const MusicBed: React.FC = () => (
  <Audio
    src={staticFile(MUSIC.file)}
    volume={(f) =>
      interpolate(
        f,
        [0, MUSIC.fadeInFrames, TOTAL_FRAMES - MUSIC.fadeOutFrames, TOTAL_FRAMES],
        [0, MUSIC.volume, MUSIC.volume, 0],
        { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
      )
    }
  />
);
