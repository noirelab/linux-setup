/**
 * qa-stills.ts — render one still per storyboard beat into out/qa/.
 *
 * Reviewing a film by watching it is how composition errors survive to
 * delivery. This pulls the frames that matter — every entrance, every hold,
 * every hand-over — so each one can be inspected at full resolution.
 *
 * Copy into <project>/showcase-video/scripts/ and edit COMPOSITION plus the
 * BEATS list so it names this film's actual scenes.
 *
 * Usage:  npm run showcase:stills
 */

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { SCENE_START, TOTAL_FRAMES } from "../src/timing";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PROJECT = path.resolve(HERE, "..");
const OUT = path.join(PROJECT, "out", "qa");

const COMPOSITION = "TODO";   // the composition id from src/Root.tsx

/** [absolute frame, label] — the beats worth looking at. */
const BEATS: [number, string][] = [
  [SCENE_START.impact + 20, "s1-rule-drawing"],
  [SCENE_START.impact + 58, "s1-wordmark-landed"],
  [SCENE_START.impact + 76, "s1-logo-mark"],
  [SCENE_START.impact + 100, "s1-hold"],

  [SCENE_START.reveal + 14, "s2-frame-assembling"],
  [SCENE_START.reveal + 40, "s2-page-in"],
  [SCENE_START.reveal + 62, "s2-light-sweep"],
  [SCENE_START.reveal + 120, "s2-caption"],
  [SCENE_START.reveal + 172, "s2-hold"],

  [SCENE_START.navigate + 30, "s3-benefits"],
  [SCENE_START.navigate + 80, "s3-card1-flying"],
  [SCENE_START.navigate + 118, "s3-sands-seated"],
  [SCENE_START.navigate + 150, "s3-tab-switching"],
  [SCENE_START.navigate + 175, "s3-stones"],
  [SCENE_START.navigate + 200, "s3-stones-hold"],
  [SCENE_START.navigate + 228, "s3-stones-out"],

  [SCENE_START.details + 30, "s4-quote-panel"],
  [SCENE_START.details + 60, "s4-quote-caption"],
  [SCENE_START.details + 96, "s4-mobile-entering"],
  [SCENE_START.details + 130, "s4-mobile-settled"],
  [SCENE_START.details + 165, "s4-hold"],

  [SCENE_START.value + 34, "s5-pulled-back"],
  [SCENE_START.value + 50, "s5-line1"],
  [SCENE_START.value + 95, "s5-line2"],

  [SCENE_START.endCard + 8, "s6-wipe"],
  [SCENE_START.endCard + 40, "s6-logo"],
  [SCENE_START.endCard + 70, "s6-wordmark"],
  [SCENE_START.endCard + 96, "s6-full-lockup"],
  [SCENE_START.endCard + 106, "s6-fading-out"],

  [SCENE_START.outro + 20, "s7-logo-pop"],
  [SCENE_START.outro + 40, "s7-wordmark"],
  [SCENE_START.outro + 62, "s7-full"],
  [TOTAL_FRAMES - 1, "s7-final-frame"],
];

fs.mkdirSync(OUT, { recursive: true });

console.log(`Rendering ${BEATS.length} stills to out/qa/ …\n`);

let failed = 0;
for (const [frame, label] of BEATS) {
  const file = path.join(OUT, `${String(frame).padStart(4, "0")}-${label}.png`);
  try {
    execFileSync(
      "npx",
      ["remotion", "still", COMPOSITION, file, `--frame=${frame}`, "--image-format=png", "--log=error"],
      { cwd: PROJECT, stdio: ["ignore", "ignore", "pipe"] },
    );
    console.log(`  ✓ f${String(frame).padStart(4)}  ${label}`);
  } catch (err) {
    failed++;
    const stderr = (err as { stderr?: Buffer }).stderr?.toString().trim().split("\n").slice(-3).join("\n");
    console.error(`  ✗ f${frame} ${label}\n${stderr}`);
  }
}

console.log(`\n${BEATS.length - failed}/${BEATS.length} stills written to out/qa/`);
if (failed) process.exit(1);
