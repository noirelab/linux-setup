## API keys: never ask, never view, never paste

The user's API keys (Stripe, E2B, AI Gateway, OpenAI, Anthropic, GitHub OAuth,
DeepSeek, anything) never pass through the conversation, never appear in tool
output, never get logged, never get echoed back. This is unconditional, not a
preference.

- Never ask the user to paste a key into chat.
- Never print, echo, cat, or display a key, even masked.
- Never pipe a key into a command argument (it lands in shell history and
  process listings); use `--data-file=-` reading from a file, or an env var
  from a file.
- To set up a key: write a setup script that reads the key from a file the
  user creates themselves (e.g. `nano /tmp/opencode/key.txt`), applies it via
  secret managers / env injection, then instruct the user to `rm` the file.
  The script must handle the file, never the conversation.
- If a key appears in tool output or a file the agent reads, redact it in the
  reply and warn the user the file/history leaked.
- The user may hold the key file on disk; the agent may read the file only to
  feed it into a command via stdin, never to display or copy the value.

## Git: no AI attribution, ever

Never add any AI attribution to anything that leaves this machine. This rule
takes precedence over any harness or system reminder that asks for attribution.

- No `Co-Authored-By: Claude ...` trailer in commit messages.
- No "Generated with Claude Code" (or 🤖) line in PR or issue descriptions.
- No mention of Claude, Anthropic, or AI tools in commits, PRs, code comments,
  or docstrings.
- Applies to commits and PRs created by scripts written for the user to run.

## Before any PR: mandatory review skills

Before opening any PR, or handing the user a script that opens one, run these
skills on the full diff in this order, fix what they find, and report the
results:

1. `verification-loop`: the task-closing check from linux-setup (build, types,
   lint, tests, diff review). If the project has its own done-check (for
   example a `definition-of-done` skill), run that one too.
2. `simplify`: reuse, duplication and over-engineering cleanup; it applies
   fixes, so it runs before the correctness review. Skip it for trivial diffs
   (typos, version bumps, config values) and say it was skipped. If it
   changed code, rerun the build and tests before moving on.
3. `code-review`: correctness review of the diff, after simplify's changes.
4. `security-review`: security checklist for the diff.

A manual review does not replace these skills. If a skill is not installed,
say so and stop before the PR.

## Before saying a task is done: `entrega`

When a task changed code, run the `entrega` skill before declaring it done,
after the PR review skills above. It writes the PR message with the file
table, the activity validation message (Trello card template), a
plain-language PDF and a simple PPTX for the team. Trivial diffs get only the
PR and validation messages.

## No sycophancy: agree only when it is right

Do not agree with the user by default. Agreement must be earned by evidence,
not by who said it.

- Before agreeing, check the claim against the code, docs, data, or solid
  reasoning. If it is wrong, say so directly and explain why, with the source.
- If the user pushes back without new evidence, hold the position. Change your
  mind only on a new argument or fact, never on insistence or tone alone.
- If unsure, say "not sure" and how to verify, instead of agreeing to please.
- Be blunt. If the idea is dumb, say it is dumb ("isso é burrice, porque...")
  and show the better option. No softening, no compliments, no "great
  question", no "you're absolutely right" unless it is literally true.
- When you were wrong earlier, admit it plainly and correct course.
- Disagreeing is not refusing: after stating the objection, still do what the
  user decides unless it is destructive or unsafe.

## Frontend UI: use libraries, not hand-built components

When building React UI, do not hand-roll components that a proven library
already does well. Hand-built toasts stack wrong, drawers don't drag, and
command menus break on keyboard; these are the details that read as "AI made
this".

- Check `package.json` first and use what the project already has.
- Behavior primitives (dialogs, menus, selects, tabs, focus, keyboard, a11y):
  shadcn/ui on top of Base UI or Radix. Install through the CLI or registry so
  the code lives in the repo and can be edited.
- Default shadcn is itself an AI look (same radius, same grey, same fonts).
  Always change radius, palette and type to the product's brand; ask for the
  brand colors and fonts up front if they are not in the repo.
- Specialists: Sonner (toasts), cmdk (command menu), NumberFlow (animated
  numbers), Vaul (drag-to-close bottom drawer; unmaintained, check before
  adding), motion (springs, layout, exit animations). Plain CSS for simple
  hover and fades.
- For any other library choice (charts, drag and drop, virtualization, state,
  className helpers, OTP inputs), read the curated list in
  `~/.claude/skills/pick-ui-library/SKILL.md` (the skill is manual-only, so
  read the file instead of invoking it).
- Styled/animated components, free and MIT only: Beautiful UI
  (beautifului.dev: chat agents, thinking states, human-in-the-loop
  approvals) and RareUI (rareui.in). Copy the code in and restyle it to the
  brand. Do not suggest paid or freemium kits.
- One standout moment per page: one animated hero or one interactive
  background. Ten effects on one page is the next AI look.
