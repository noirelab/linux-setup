# Linux Setup

Cross-distro bootstrap for fresh Linux installs — interactive script that sets up your terminal, desktop, apps, and dev tools. Maintains config parity between machines via a backup script.

## Quick Start

**From a pen drive (fresh install, no internet cloning needed):**

```bash
# Copy repo to pen drive, then on the new machine:
cd /path/to/mint-setup
chmod +x setup.sh
./setup.sh
```

**After setup, back up your changes:**

```bash
./save_profile.sh   # copies live configs back into the repo
git add -A && git commit -m "update configs"
```

## Supported Systems

| OS | Desktop | Details |
|---|---|---|
| **CachyOS / Arch Linux** | Hyprland | Waybar, Rofi, Dunst, Hyprlock, Hypridle |
| **Linux Mint** | Cinnamon | Keyboard shortcuts, window opacity daemon |
| **Ubuntu / Debian** | GNOME | Same tools as Mint, GNOME keybindings |

OS detection is automatic — the script installs the right packages and deploys the right configs.

## What Gets Installed

The installer walks you through each section with y/n prompts.

### Terminal & Shell

| Component | Details |
|---|---|
| **Kitty** | GPU-accelerated terminal, Nerd Font, Noctalia theme (`themes/noctalia.conf`) |
| **Fish** | Modern shell with eza/bat/rg aliases, conda integration, auto-ls |
| **Bash** | 680+ line custom `.bashrc` — zoxide, eza, bat, rg, fzf, trash-cli, 80+ aliases, archive helpers, Docker clean, auto-startx |
| **Prompt** | `fish-pure-prompt` (Starship removed) |
| **Tmux** | Prefix `Ctrl-b`, `\|`/`-` splits, vi copy mode, mouse, 10k history |
| **Nerd Fonts** | FiraCode + JetBrains Mono (Arch via pacman, Debian downloaded manually) |
| **OpenCode** | AI assistant CLI — installed via `curl` + config deployed from repo |
| **OpenCode SEO** | 25 SEO sub-skills — site audits, technical SEO, schema, content (E-E-A-T), GEO/AI search, backlinks, local SEO, maps, e-commerce, Google APIs, SPA-aware rendering |
| **Claude Code** | CLI installed via `curl`, then 205 skills, hooks, agents, commands and `settings.json` restored from the repo |
| **Claude plugins** | 9 plugins re-installed from their marketplaces (claude-mem, ponytail, caveman, figma, stripe, vercel, 21st, ui-ux-pro-max, rust-analyzer-lsp) |
| **Wallpaper** | Single source of truth: `configs/common/wallpapers/wallpaper.jpg` → `~/Pictures/wallpaper.jpg`, used by `awww` (desktop), Hyprlock and SDDM |

### Desktop Environment (Arch/CachyOS)

| Component | Details |
|---|---|
| **Hyprland** | Dwindle layout, 7px gaps, 86%/70% active/inactive opacity, blur, shadow, smooth animations |
| **Noctalia** | Current bar/shell — launcher, clock, capsule groups, plus the local `claude-usage` plugin (session / week / DeepSeek widgets) |
| **awww** | Wallpaper daemon (`awww-daemon.service`), started from Hyprland autostart |
| **Rofi** | App launcher with Catppuccin Mocha theme, JetBrains Mono font |
| **Dunst** | Notification daemon |
| **Hyprlock** | Lock screen with clock, blurred wallpaper, password input — NVIDIA-safe |
| **Hypridle** | Dim (2.5min) → Lock (5min) → DPMS off (5.5min) |
| **Media** | PipeWire audio, grim+slurp screenshots, brightnessctl, playerctl |

### Desktop Environment (Mint/GNOME)

| Component | Details |
|---|---|
| **Keybindings** | 9 custom shortcuts via gsettings (Cinnamon + GNOME compatible) |
| **Opacity** | Window transparency daemon (93% unfocused, 100% focused) |

### Applications

| App | Arch | Debian/Mint |
|---|---|---|
| Firefox | pacman | apt |
| Discord | pacman | .deb download |
| VS Code | AUR (yay/paru) | Microsoft repo |
| Spotify | AUR (yay/paru) | Spotify repo |
| Nemo | pacman | apt |
| btop | included with hyprland (Arch) or gnome shortcuts (Mint) | apt |

### Dev Tools

| Tool | Details |
|---|---|
| **Docker** | Docker CE + NVIDIA Container Toolkit (GPU passthrough configured) |
| **Miniconda3** | Installed to `~/miniconda3`, init for both bash and fish |

### Gaming

| Arch/CachyOS | Debian/Mint |
|---|---|
| `cachyos-gaming-meta`, `cachyos-gaming-applications` | `steam`, `lutris`, `mangohud` |

## Directory Structure

```
mint-setup/
├── setup.sh              # Interactive installer
├── save_profile.sh       # Back up live configs into the repo
└── configs/
    ├── common/           # Shared across all distros
    │   ├── .bashrc
    │   ├── fish/         # config.fish + functions/ + conf.d/ + fish_variables
    │   ├── kitty/        # kitty.conf + theme
    │   ├── tmux/         # tmux.conf
    │   ├── claude/       # Claude Code: CLAUDE.md, settings.json, hooks/, agents/,
    │   │                 #   commands/, skills/ (205), plugins/ (manifests only),
    │   │                 #   external-skills.json (gstack pin)
    │   ├── opencode/     # ~/.config/opencode — config, agents, plugins, commands, skills
    │   ├── opencode_home/# ~/.opencode — npm/ECC install root (skills, tools, prompts)
    │   ├── systemd/      # ~/.config/systemd/user units (chico, awww-daemon, ydotool)
    │   ├── scripts/      # hand-written ~/.local/bin scripts (binaries excluded)
    │   └── wallpapers/
    ├── arch/             # Hyprland ecosystem
    │   ├── hypr/         # hyprland.lua + config/*.lua (the live Lua provider)
    │   ├── noctalia/     # config.toml + plugins/claude-usage/
    │   ├── rofi/         # config.rasi
    │   ├── dunst/
    │   └── sddm/
    └── mint/             # Linux Mint
        └── opacify_windows.sh
```

## Keyboard Shortcuts

### Hyprland (Arch/CachyOS)

Defined in `configs/arch/hypr/config/binds.lua`. `noct` = `noctalia msg`.
Workspaces are **per monitor** (`NUM_WPM = 3`), monitors are `HDMI-A-1`
(portrait, rotated 90°) and `DP-1` (primary).

**Apps**

| Binding | Action |
|---|---|
| `Super+Return` | Terminal (Kitty) |
| `Super+E` | File manager (Nemo) |
| `Super+T` | Text editor (gnome-text-editor) |
| `Super+C` | Calculator (gnome-calculator) |
| `Super+W` | Firefox |
| `Super+S` | Spotify |
| `Super+/` | Discord |
| `Super+G` | Gemini |
| `Super+\` | Trigger chico (POST to `chico-trigger.sock`) |
| `Ctrl+Shift+Esc` | btop in Kitty |

**Noctalia shell**

| Binding | Action |
|---|---|
| `Super+Space` | Launcher |
| `Super+.` | Emoji picker |
| `Super+Tab` | Window switcher |
| `Super+V` | Clipboard history |
| `Super+A` | Notifications |
| `Super+X` | Control center |
| `Super+Z` | Settings |
| `Super+Shift+W` | Wallpaper panel |
| `Super+L` | Lock session |
| `Super+Alt+C` | Session panel (logout/reboot/poweroff) |
| `Print` / `Super+Print` | Region / fullscreen screenshot |
| Volume, mic, media, brightness keys | Routed through Noctalia |

**Windows**

| Binding | Action |
|---|---|
| `Super+Q` | Close window |
| `Super+F` | Fullscreen |
| `Super+D` | Maximize (fullscreen mode 1) |
| `Super+Alt+Space` | Toggle floating |
| `Super+J` | Toggle split direction |
| `Super+P` | Color picker (hyprpicker) |
| `Super+Esc` | `hyprctl kill` (click a window to force-kill) |
| `Super+Arrows` | Move focus |
| `Super+Shift+Arrows` | Move window |
| `Super+LMB / RMB` | Drag / resize window |
| `Alt+Tab` | Cycle to next window |
| `Super+M` | Minimize (silent → `special:minimized`) |
| `Super+N` | Show minimized |
| `Super+Shift+N` | Pull window to current workspace |
| `Super+Shift+S` | Move window to scratchpad (`special`) |

**Monitors & workspaces**

| Binding | Action |
|---|---|
| `Super+1/2/3` | Focus monitor 1/2/3 |
| `Super+Shift+1/2/3` | Move window to monitor 1/2/3 |
| `Super+Ctrl+1..3` | Focus workspace N of the current monitor |
| `Super+Tab+1..3` | Focus workspace N (absolute) |
| `Super+Ctrl+Shift+1..3` | Move window to workspace N of the current monitor |
| `Super+Ctrl+Left/Right` | Previous / next workspace on this monitor |
| `Super+Ctrl+Down` | First empty workspace on this monitor |
| `Super+Ctrl+Shift+Left/Right` | Move window to previous / next workspace |
| `Super+Scroll` | Cycle workspaces on this monitor |
| `Super+Shift+Scroll` | Move window to previous / next monitor |

### GNOME / Cinnamon (Mint/Debian)

| Binding | Action |
|---|---|
| `Super+Return` | Terminal (Kitty) |
| `Super+W` | Firefox |
| `Super+V` | VS Code |
| `Super+S` | Spotify |
| `Super+/` | Discord |
| `Super+G` | Gemini |
| `Ctrl+Shift+Esc` | System monitor (btop) |
| `Super+Shift+S` | Area screenshot |
| `Super+M` | Minimize window |

## Scripts

### `setup.sh`

Interactive installer. Detects your OS and offers each section:

1. System update + build tools
2. Gaming packages
3. Terminal & Shell (Kitty, Nerd Fonts, Fish, OpenCode, Tmux)
4. Applications (Firefox, Discord, VS Code, Spotify, Nemo)
5. OpenCode AI assistant
6. OpenCode SEO Skills (25 SEO sub-skills with Python runtime)
7. Claude Code (skills, hooks, agents, commands, settings + plugin restore, optional gstack clone)
8. Dev tools (Docker + NVIDIA toolkit, Miniconda3)
9. Desktop config (Hyprland+Noctalia+Rofi+Dunst or GNOME/Cinnamon shortcuts)
10. systemd user units (Arch only)
11. Hyprlock + Hypridle (Arch only)
12. .bashrc

### `save_profile.sh`

Copies your current live configs back into the repo for version control:

Uses `rsync -a --delete` with a shared exclude list, so deletions on the live
system propagate into the repo and no build output is ever vendored.

| Source | Destination |
|---|---|
| `~/.config/kitty/` | `configs/common/kitty/` |
| `~/.config/fish/` | `configs/common/fish/` (config, functions, conf.d, variables) |
| `~/.bashrc` | `configs/common/.bashrc` |
| `~/.tmux.conf` | `configs/common/tmux/` |
| `~/.claude/{CLAUDE.md,settings.json}` | `configs/common/claude/` |
| `~/.claude/{hooks,agents,commands,skills}/` | `configs/common/claude/` |
| `~/.claude/plugins/*.json` | `configs/common/claude/plugins/` (manifests only) |
| `~/.config/opencode/` | `configs/common/opencode/` (MCP headers redacted) |
| `~/.opencode/` | `configs/common/opencode_home/` |
| `~/.config/systemd/user/*.service` | `configs/common/systemd/` |
| `~/.local/bin/` (text scripts only) | `configs/common/scripts/` |
| `~/Pictures/wallpaper.jpg` | `configs/common/wallpapers/` |
| `~/.config/hypr/` | `configs/arch/hypr/` (Arch only) |
| `~/.config/noctalia/` | `configs/arch/noctalia/` (Arch only) |
| `~/.config/{rofi,dunst}/` | `configs/arch/*/` (Arch only) |
| `/usr/share/sddm/themes/custom/` | `configs/arch/sddm/` (Arch only) |

**Never saved:** `node_modules/`, `.venv/`, `ms-playwright/`, `__pycache__/`,
`.git/`, `~/.claude/settings.local.json`, the Claude plugin cache, and the
`gstack` / `seo` skills. Those are reinstalled, not versioned.

## Workflow

```
┌──────────────┐     setup.sh      ┌──────────────┐
│   Repo/Git   │ ─────────────────>│  Fresh System │
│  (pen drive) │                   │  (CachyOS)   │
└──────────────┘                   └──────────────┘
       ^                                  │
       │        save_profile.sh           │
       └──────────────────────────────────┘
              (update repo from live)
```

1. **Initial setup**: Copy repo → run `setup.sh` on new machine
2. **Tweak your configs**: Customize kitty, hyprland, noctalia, etc. on the live system
3. **Save back**: Run `save_profile.sh` → `git commit && git push`
4. **Replicate**: Pull on another machine, run `setup.sh` again

## Notes

- **Hyprland uses the Lua config provider** — `hyprctl systeminfo` reports `configProvider: lua`, so `hyprland.lua` + `config/*.lua` is what actually runs. The old `hyprland.conf` + `source/*.conf` tree was dead (it still launched `waybar` and `swww`) and is no longer versioned.
- **NVIDIA GPU** — Hyprlock disables blur to prevent NVIDIA flickering; `AQ_DRM_NO_ATOMIC` and `WLR_NO_HARDWARE_CURSORS` are set in the Hyprland environment.
- **Keyboard layout** — Set to Brazilian (`kb_layout = br`) in Hyprland. Edit `configs/arch/hypr/config/inputs.lua` to change.
- **User paths** — Some configs reference `/home/noirelab/`. Adjust if your username differs.
- **Noctalia replaced Waybar** — the bar/shell in use is Noctalia. The old Waybar config and its `cpu.sh` / `gpu.sh` / `window.sh` scripts are no longer versioned.
- **Noctalia `claude-usage` plugin** — hand-written Luau widgets in `configs/arch/noctalia/plugins/claude-usage/` (session, week, DeepSeek). Not on any registry, so this repo is its only backup.
- **Secrets are redacted** — `save_profile.sh` rewrites every MCP header value in `opencode.json` to `REPLACE_ME`. Fill them back in after running `setup.sh`. `~/.claude/settings.local.json` is never copied.
- **Large skills are pinned, not vendored** — `gstack` is cloned from `github.com/garrytan/gstack` at the commit recorded in `configs/common/claude/external-skills.json`; the SEO skill comes from `install-opencode-seo.sh`.
- **Claude plugins** — restored with `claude plugin marketplace add` + `claude plugin install`, driven by the two manifest JSONs. The ~770M plugin cache is re-downloaded, not stored.
- **chico** — `Super+\` POSTs to `/run/user/1000/chico-trigger.sock`; `chico.service` is started from the Hyprland autostart chain (needs `WAYLAND_DISPLAY` in the systemd user env first).
- **AUR helper** — `setup.sh` prefers `paru`, falls back to `yay`, or installs `yay` from source if neither exists.
- **Conda** — installed to `~/miniconda3`, initializes in both bash and fish.
- **Docker** — You'll need to log out/in after first install for `docker` group membership.
