# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

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
