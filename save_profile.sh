#!/bin/bash
# save_profile.sh - Backs up your CURRENT system config into this repo

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$REPO_DIR/configs"

echo "Saving configuration to $REPO_DIR..."

# Excludes shared by every rsync call: build output, virtualenvs, vendored
# browsers and git metadata are all reinstallable and would bloat the repo.
EXCLUDES=(
    --exclude=node_modules/
    --exclude=.venv/
    --exclude=venv/
    --exclude=ms-playwright/
    --exclude=__pycache__/
    --exclude=.git/
    --exclude=.cache/
    --exclude='*.pyc'
    --exclude='*.log'
)

# sync <source-dir> <dest-dir> [extra rsync args...]
sync() {
    local src="$1" dest="$2"; shift 2
    [ -d "$src" ] || return 0
    mkdir -p "$dest"
    rsync -a --delete "${EXCLUDES[@]}" "$@" "$src/" "$dest/"
}

# --- 1. COMMON CONFIGS ---
echo "[+] Backing up Common Configs..."

sync ~/.config/kitty        "$CFG/common/kitty"        && echo "    - Kitty saved."
sync ~/.config/fish         "$CFG/common/fish"         && echo "    - Fish (config, functions, conf.d, variables) saved."
[ -f ~/.bashrc ]     && cp ~/.bashrc     "$CFG/common/.bashrc"          && echo "    - .bashrc saved."
[ -f ~/.tmux.conf ]  && mkdir -p "$CFG/common/tmux" && cp ~/.tmux.conf "$CFG/common/tmux/tmux.conf" && echo "    - Tmux saved."
[ -f ~/Pictures/wallpaper.jpg ] && mkdir -p "$CFG/common/wallpapers" && cp ~/Pictures/wallpaper.jpg "$CFG/common/wallpapers/wallpaper.jpg" && echo "    - Wallpaper saved."

# --- 2. CLAUDE CODE ---
echo "[+] Backing up Claude Code..."
CLAUDE_DST="$CFG/common/claude"
mkdir -p "$CLAUDE_DST/plugins"

[ -f ~/.claude/CLAUDE.md ]     && cp ~/.claude/CLAUDE.md     "$CLAUDE_DST/CLAUDE.md"
# settings.local.json is intentionally NOT saved: machine-local and may hold secrets.
[ -f ~/.claude/settings.json ] && cp ~/.claude/settings.json "$CLAUDE_DST/settings.json"
sync ~/.claude/hooks    "$CLAUDE_DST/hooks"
sync ~/.claude/agents   "$CLAUDE_DST/agents"
sync ~/.claude/commands "$CLAUDE_DST/commands"
echo "    - CLAUDE.md, settings.json, hooks, agents, commands saved."

# Skills: gstack and seo are huge upstream installs restored by their own
# installers (see external-skills.json / install-opencode-seo.sh), not vendored.
sync ~/.claude/skills "$CLAUDE_DST/skills" --exclude=gstack/ --exclude=seo/
echo "    - Claude skills saved ($(ls "$CLAUDE_DST/skills" | wc -l) skills, gstack/seo excluded)."

# Plugins: only the manifests. The 700M+ plugin cache is re-downloaded by
# `claude plugin install` on restore.
for f in installed_plugins.json known_marketplaces.json; do
    [ -f ~/.claude/plugins/$f ] && cp ~/.claude/plugins/$f "$CLAUDE_DST/plugins/$f"
done
echo "    - Claude plugin manifests saved ($(jq -r '.plugins | length' "$CLAUDE_DST/plugins/installed_plugins.json" 2>/dev/null) plugins)."

# Pin the externally-installed skills so setup.sh can clone the same revision.
if [ -d ~/.claude/skills/gstack/.git ]; then
    jq -n \
        --arg repo "$(git -C ~/.claude/skills/gstack remote get-url origin)" \
        --arg commit "$(git -C ~/.claude/skills/gstack rev-parse HEAD)" \
        --arg version "$(jq -r .version ~/.claude/skills/gstack/package.json 2>/dev/null)" \
        '{gstack: {repo: $repo, commit: $commit, version: $version, install: "git clone + bun install"}}' \
        > "$CLAUDE_DST/external-skills.json"
    echo "    - gstack pinned in external-skills.json."
fi

# --- 3. OPENCODE ---
echo "[+] Backing up OpenCode..."
# ~/.config/opencode (skills/seo holds a 1.4G venv + browser bundle; the SEO
# skill is reinstalled by install-opencode-seo.sh)
sync ~/.config/opencode "$CFG/common/opencode" \
    --exclude=skills/seo/bin/ \
    --exclude='opencode.json.bak'

# opencode.json carries MCP auth headers. Never commit them.
if [ -f "$CFG/common/opencode/opencode.json" ]; then
    jq '(.mcp // {}) |= with_entries(.value.headers? //= {} | .value.headers |= with_entries(.value = "REPLACE_ME"))' \
        "$CFG/common/opencode/opencode.json" > "$CFG/common/opencode/opencode.json.tmp" \
        && mv "$CFG/common/opencode/opencode.json.tmp" "$CFG/common/opencode/opencode.json" \
        && echo "    - opencode.json saved (MCP headers redacted)."
fi

# ~/.opencode (npm/ECC install root: skills, commands, tools, prompts...)
# bin/ and dist/ are build artifacts from `npm install`.
sync ~/.opencode "$CFG/common/opencode_home" --exclude=bin/ --exclude=dist/
echo "    - OpenCode home saved ($(ls "$CFG/common/opencode_home/skills" 2>/dev/null | wc -l) skills)."

# --- 4. SYSTEMD USER UNITS ---
sync ~/.config/systemd/user "$CFG/common/systemd" --exclude='*.wants/'
echo "    - systemd user units saved."

# --- 5. CUSTOM SCRIPTS (~/.local/bin, text only) ---
# The directory also holds ~200M of installed binaries (gh, uv, herdr...) and
# symlinks into other install roots. Only hand-written scripts belong here.
mkdir -p "$CFG/common/scripts"
rm -rf "$CFG/common/scripts"/*
for f in ~/.local/bin/*; do
    [ -f "$f" ] && [ ! -L "$f" ] && file -b "$f" | grep -qi 'text\|script' && cp "$f" "$CFG/common/scripts/"
done
sync ~/.local/bin/services "$CFG/common/scripts/services"
echo "    - Custom scripts saved ($(ls "$CFG/common/scripts" | wc -l) entries)."

# --- 6. EXTRA APP CONFIGS (hand-tuned) ---
echo "[+] Backing up extra app configs..."

[ -f ~/.gitconfig ] && cp ~/.gitconfig "$CFG/common/.gitconfig" && echo "    - .gitconfig saved."
[ -f ~/.config/mimeapps.list ] && cp ~/.config/mimeapps.list "$CFG/common/mimeapps.list" && echo "    - Default-app MIME associations saved."
sync ~/.config/btop      "$CFG/common/btop"      && echo "    - btop saved."
sync ~/.config/alacritty "$CFG/common/alacritty" && echo "    - Alacritty saved."
sync ~/.config/herdr     "$CFG/common/herdr" \
    --exclude='*.log' --exclude='*.sock' --exclude='release-notes.json' --exclude='.plugins.lock' \
    --exclude='session.json' \
    && echo "    - herdr config saved."
sync ~/.config/opendeck  "$CFG/common/opendeck" --exclude=plugins/ && echo "    - OpenDeck profiles saved."
[ -f ~/.codex/config.toml ] && mkdir -p "$CFG/common/codex" && cp ~/.codex/config.toml "$CFG/common/codex/config.toml" && echo "    - Codex config saved."

# VS Code: only the hand-edited files. The rest of User/ is machine state
# (globalStorage, workspaceStorage, History) and would be huge.
mkdir -p "$CFG/common/vscode/User/snippets"
for f in settings.json keybindings.json mcp.json; do
    [ -f ~/.config/Code/User/$f ] && cp ~/.config/Code/User/$f "$CFG/common/vscode/User/$f"
done
[ -d ~/.config/Code/User/snippets ] && cp ~/.config/Code/User/snippets/*.json "$CFG/common/vscode/User/snippets/" 2>/dev/null
echo "    - VS Code (settings, keybindings, mcp, snippets) saved."

# Deliberately NOT saved (machine-local secrets): ~/.config/rclone/rclone.conf
# (cloud credentials), ~/.config/gcloud, ~/.config/kdeconnect, ~/.codex/auth.json,
# browser profiles.

# --- 7. OS SPECIFIC ---
if [ -f /etc/arch-release ] || [ -f /etc/cachyos-release ]; then
    echo "[+] Arch/CachyOS Detected - Saving desktop specific files..."

    # hyprland.conf + source/*.conf are the dead .conf provider (hyprctl
    # systeminfo reports configProvider: lua). Only the Lua tree is live.
    sync ~/.config/hypr     "$CFG/arch/hypr" --exclude=source/ --exclude=hyprland.conf \
        && echo "    - Hyprland (Lua config) saved."
    sync ~/.config/noctalia "$CFG/arch/noctalia" && echo "    - Noctalia (config + plugins) saved."
    sync ~/.config/rofi     "$CFG/arch/rofi"     && echo "    - Rofi saved."
    sync ~/.config/dunst    "$CFG/arch/dunst"    && echo "    - Dunst saved."
    sync ~/.config/gtk-3.0  "$CFG/arch/gtk-3.0"  && echo "    - GTK config saved."
    sync ~/.config/uwsm     "$CFG/arch/uwsm"     && echo "    - UWSM env saved."

    if [ -d /usr/share/sddm/themes/custom ]; then
        mkdir -p "$CFG/arch/sddm"
        sudo cp -r /usr/share/sddm/themes/custom/* "$CFG/arch/sddm/" 2>/dev/null
        sudo chown -R "$USER:$USER" "$CFG/arch/sddm" 2>/dev/null
        echo "    - SDDM theme saved."
    fi
fi

echo "-------------------------------------------"
echo "Backup complete! Review 'git status' before pushing."
