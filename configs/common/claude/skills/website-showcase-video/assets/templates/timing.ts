/**
 * timing.ts — the film's edit, in one place.  [TEMPLATE]
 *
 * Every scene boundary and every sound cue is declared here. Change a duration
 * and the following scenes, the composition length and the whole audio pass
 * move with it, because nothing downstream ever hardcodes an absolute frame.
 *
 * Adding a scene is three edits: a key in SCENE_FRAMES, its name in ORDER, and
 * a <Series.Sequence> in Showcase.tsx.
 */

export const FPS = 30;
export const WIDTH = 1920;
export const HEIGHT = 1080;

const s = (seconds: number) => Math.round(seconds * FPS);

/**
 * Scene durations. Comments carry the derived frame ranges — update them when
 * you re-time, they are the fastest way to read the edit.
 *
 * A 25–35s film usually lands near: opening 4s · site reveal 5.5–6s · content
 * travel 5–8s · detail 3.5–5.5s · value 3–4s · end card 3.5s.
 */
export const SCENE_FRAMES = {
  open: s(4.0), //    0 –  119
  reveal: s(6.0), //  120 –  299
  travel: s(6.0), //  300 –  479
  detail: s(4.5), //  480 –  614
  value: s(4.0), //  615 –  734
  endCard: s(3.5), //  735 –  839
} as const;

export type SceneName = keyof typeof SCENE_FRAMES;

/** Playback order. Must list every key in SCENE_FRAMES. */
const ORDER: SceneName[] = ["open", "reveal", "travel", "detail", "value", "endCard"];

/** Derived — never hand-written. */
export const SCENE_START = ORDER.reduce<Record<SceneName, number>>(
  (acc, name, i) => {
    acc[name] = i === 0 ? 0 : acc[ORDER[i - 1]] + SCENE_FRAMES[ORDER[i - 1]];
    return acc;
  },
  {} as Record<SceneName, number>,
);

export const TOTAL_FRAMES = ORDER.reduce((n, name) => n + SCENE_FRAMES[name], 0);

/** Scene-relative frame -> absolute composition frame. */
export const at = (scene: SceneName, offset = 0) => SCENE_START[scene] + offset;

export type Cue = {
  /** File under public/audio/sfx/ */
  file: string;
  /** Absolute frame of the hit — always via at(), never a literal. */
  frame: number;
  volume: number;
  /** Cut the sample here. Long samples must not outlive their action. */
  durationInFrames?: number;
  /** WHICH picture action this punctuates. Do not omit. */
  note: string;
};

/**
 * Sound cues.
 *
 * The `note` is what makes a re-time survivable: after moving the edit you can
 * re-check the entire audio pass in one read instead of hunting through JSX.
 *
 * Repeated hits step DOWN in level so a burst reads as rhythm rather than a
 * machine gun (0.30 -> 0.22 -> 0.18 -> 0.15).
 */
export const CUES: Cue[] = [
  // ---- Scene 1 · opening --------------------------------------------------
  { file: "TODO.mp3", frame: at("open", 10), volume: 0.35, durationInFrames: s(1.6), note: "accent rule draws" },
  { file: "TODO.mp3", frame: at("open", 28), volume: 0.5, note: "wordmark lands — pick a sound with material meaning" },

  // ---- Scene 2 · site reveal ----------------------------------------------
  { file: "TODO.mp3", frame: at("reveal", 0), volume: 0.4, durationInFrames: s(2.0), note: "cut into the browser frame" },
  { file: "TODO.mp3", frame: at("reveal", 18), volume: 0.3, note: "browser chrome assembles" },
  // Very low sustained bed keeps an SFX-only film off true silence.
  { file: "TODO.mp3", frame: at("reveal", 8), volume: 0.1, durationInFrames: s(4.8), note: "atmosphere bed" },

  // ---- Scene 3 · travel ---------------------------------------------------
  { file: "TODO.mp3", frame: at("travel", 0), volume: 0.35, durationInFrames: s(2.0), note: "camera departs" },
  { file: "TODO.mp3", frame: at("travel", 54), volume: 0.3, note: "card 1 seats into its slot" },
  { file: "TODO.mp3", frame: at("travel", 66), volume: 0.22, note: "card 2 — stepped down" },
  { file: "TODO.mp3", frame: at("travel", 78), volume: 0.18, note: "card 3" },
  { file: "TODO.mp3", frame: at("travel", 90), volume: 0.15, note: "card 4 — end of the run" },

  // ---- Scene 6 · end card -------------------------------------------------
  { file: "TODO.mp3", frame: at("endCard", 0), volume: 0.45, note: "hard cut to black" },
  // Long tail left uncut on purpose: it rings out under the logo hold.
  { file: "TODO.mp3", frame: at("endCard", 10), volume: 0.4, note: "logo lands" },
];

/**
 * Optional music bed. Ship empty unless a cleared track exists; leave this as a
 * documented drop-in slot and deliver both versions when one is supplied.
 * Never use music with unverifiable licensing.
 */
export const MUSIC = {
  file: "audio/music.mp3",
  /** Music never covers the effects. */
  volume: 0.28,
  fadeInFrames: s(1.0),
  fadeOutFrames: s(1.5),
} as const;
