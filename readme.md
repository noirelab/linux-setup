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
| **Kitty** | GPU-accelerated terminal, MesloLGS Nerd Font, Ayu color scheme, 90% opacity |
| **Starship** | Nord-themed prompt with git, language versions, conda env, docker context |
| **Fish** | Modern shell with eza/bat/rg aliases, conda integration, auto-ls |
| **Bash** | 680+ line custom `.bashrc` — zoxide, eza, bat, rg, fzf, trash-cli, 80+ aliases, archive helpers, Docker clean, auto-startx |
| **Tmux** | Prefix `Ctrl-b`, `\|`/`-` splits, vi copy mode, mouse, 10k history |
| **Nerd Fonts** | FiraCode + JetBrains Mono (Arch via pacman, Debian downloaded manually) |
| **OpenCode** | AI assistant CLI — installed via `curl` + config deployed from repo |
| **OpenCode SEO** | 25 SEO sub-skills — site audits, technical SEO, schema, content (E-E-A-T), GEO/AI search, backlinks, local SEO, maps, e-commerce, Google APIs, SPA-aware rendering |
| **Wallpapers** | Deployed to `~/.config/wallpapers/` |

### Desktop Environment (Arch/CachyOS)

| Component | Details |
|---|---|
| **Hyprland** | Dwindle layout, 7px gaps, 86%/70% active/inactive opacity, blur, shadow, smooth animations |
| **Waybar** | Custom CPU/GPU widgets, taskbar, clock, workspace indicators, Catppuccin theme |
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
    │   ├── starship.toml
    │   ├── fish/         # config.fish + functions/
    │   ├── kitty/        # kitty.conf + theme
    │   ├── tmux/         # tmux.conf
    │   ├── opencode/     # AI assistant config + skills
    │   └── wallpapers/
    ├── arch/             # Hyprland ecosystem
    │   ├── hypr/         # hyprland.conf + source/ (modular: keybinds, animations, monitors, etc.)
    │   ├── waybar/       # config.jsonc + style.css + scripts/ (CPU, GPU, window)
    │   ├── rofi/         # config.rasi
    │   └── dunst/
    └── mint/             # Linux Mint
        └── opacify_windows.sh
```

## Keyboard Shortcuts

### Hyprland (Arch/CachyOS)

| Binding | Action |
|---|---|
| `Super+Return` | Terminal (Kitty) |
| `Super+W` | Firefox |
| `Super+V` | VS Code |
| `Super+S` | Spotify |
| `Super+/` | Discord |
| `Super+G` | Gemini |
| `Super+R` | App launcher (Rofi) |
| `Super+E` | File manager (Nemo) |
| `Ctrl+Shift+Esc` | System monitor (btop) |
| `Super+Shift+S` | Area screenshot (grim+slurp) |
| `Super+C` | Kill window |
| `Super+F` | Fullscreen |
| `Super+P` | Toggle pseudo-tiling |
| `Super+M` | Minimize (special workspace) |
| `Super+N` | Show minimized |
| `Super+L` | Lock screen |
| `Super+0-9` | Switch workspace |
| `Super+Shift+0-9` | Move window to workspace |
| `Super+Arrows` | Move focus |
| `Super+Shift+Arrows` | Move window |
| `Alt+Tab` | Window switcher (hyprshell) |

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
3. Terminal & Shell (Kitty, Starship, Nerd Fonts, Fish, OpenCode, Tmux)
4. Applications (Firefox, Discord, VS Code, Spotify, Nemo)
5. OpenCode AI assistant
6. OpenCode SEO Skills (25 SEO sub-skills with Python runtime)
7. Dev tools (Docker + NVIDIA toolkit, Miniconda3)
8. Desktop config (Hyprland+Waybar+Rofi+Dunst or GNOME/Cinnamon shortcuts)
9. Hyprlock + Hypridle (Arch only)
10. .bashrc

### `save_profile.sh`

Copies your current live configs back into the repo for version control:

| Source | Destination |
|---|---|
| `~/.config/kitty/*` | `configs/common/kitty/` |
| `~/.config/opencode/*` | `configs/common/opencode/` |
| `~/.config/starship.toml` | `configs/common/starship.toml` |
| `~/.config/fish/config.fish` | `configs/common/fish/` |
| `~/.config/fish/functions/` | `configs/common/fish/functions/` |
| `~/.config/fish/fish_variables` | `configs/common/fish/` |
| `~/.bashrc` | `configs/common/.bashrc` |
| `~/.tmux.conf` | `configs/common/tmux/` |
| `~/Pictures/wallpaper.jpg` | `configs/common/wallpapers/` |
| `~/.config/hypr/*` | `configs/arch/hypr/` (Arch only) |
| `~/.config/waybar/*` | `configs/arch/waybar/` (Arch only) |
| `~/.config/rofi/*` | `configs/arch/rofi/` (Arch only) |
| `~/.config/dunst/*` | `configs/arch/dunst/` (Arch only) |

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
2. **Tweak your configs**: Customize kitty, hyprland, waybar, etc. on the live system
3. **Save back**: Run `save_profile.sh` → `git commit && git push`
4. **Replicate**: Pull on another machine, run `setup.sh` again

## Notes

- **Hyprland config is modular** — split into `source/exec.conf`, `source/keybinds.conf`, `source/monitors.conf`, etc. Edit individual files.
- **NVIDIA GPU** — Waybar GPU script uses `nvidia-smi`, and Hyprlock disables blur to prevent NVIDIA flickering.
- **Keyboard layout** — Set to Brazilian (`kb_layout = br`) in Hyprland. Edit `configs/arch/hypr/source/keybinds.conf` to change.
- **User paths** — Some configs reference `/home/noirelab/`. Adjust if your username differs.
- **Waybar custom scripts** — `cpu.sh`, `gpu.sh`, and `window.sh` need `chmod +x` (handled by setup script).
- **AUR helper** — `setup.sh` prefers `paru`, falls back to `yay`, or installs `yay` from source if neither exists.
- **Conda** — installed to `~/miniconda3`, initializes in both bash and fish.
- **Docker** — You'll need to log out/in after first install for `docker` group membership.
