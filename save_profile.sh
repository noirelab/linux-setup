#!/bin/bash
# save_profile.sh - Backs up your CURRENT system config into this repo

# Get the directory where this script is located
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Saving configuration to $REPO_DIR..."

# Create base directories if they don't exist
mkdir -p "$REPO_DIR/configs/common/fish/functions"
mkdir -p "$REPO_DIR/configs/common/kitty"
mkdir -p "$REPO_DIR/configs/common/wallpapers"
mkdir -p "$REPO_DIR/configs/common/opencode/skills"
mkdir -p "$REPO_DIR/configs/common/opencode/plugins"
mkdir -p "$REPO_DIR/configs/common/scripts"
mkdir -p "$REPO_DIR/configs/arch/hypr"
mkdir -p "$REPO_DIR/configs/arch/waybar"
mkdir -p "$REPO_DIR/configs/arch/rofi"
mkdir -p "$REPO_DIR/configs/common/tmux"
mkdir -p "$REPO_DIR/configs/arch/dunst"
mkdir -p "$REPO_DIR/configs/arch/noctalia"

# --- 1. SAVE COMMON CONFIGS (Kitty, Fish, Starship) ---
echo "[+] Backing up Common Configs..."

# Backup Kitty
cp -r ~/.config/kitty/* "$REPO_DIR/configs/common/kitty/" 2>/dev/null

# Backup OpenCode
if [ -d ~/.config/opencode ]; then
    cp -r ~/.config/opencode/* "$REPO_DIR/configs/common/opencode/" 2>/dev/null
    echo "    - OpenCode configs saved."
fi

# Backup Starship
cp ~/.config/starship.toml "$REPO_DIR/configs/common/starship.toml"

# Backup Fish
if [ -f ~/.config/fish/config.fish ]; then
    cp ~/.config/fish/config.fish "$REPO_DIR/configs/common/fish/config.fish"
    echo "    - Fish config saved."
fi

if [ -d ~/.config/fish/functions ]; then
    cp -r ~/.config/fish/functions/* "$REPO_DIR/configs/common/fish/functions/" 2>/dev/null
    echo "    - Fish functions saved."
fi

if [ -f ~/.config/fish/fish_variables ]; then
    cp ~/.config/fish/fish_variables "$REPO_DIR/configs/common/fish/fish_variables"
    echo "    - Fish variables saved."
fi

# Backup .bashrc
if [ -f ~/.bashrc ]; then
    cp ~/.bashrc "$REPO_DIR/configs/common/.bashrc"
    echo "    - .bashrc saved."
fi

# Backup wallpapers
if [ -f ~/Pictures/wallpaper.jpg ]; then
    cp ~/Pictures/wallpaper.jpg "$REPO_DIR/configs/common/wallpapers/wallpaper.jpg"
    echo "    - Wallpaper saved."
fi

# Backup tmux
if [ -f ~/.tmux.conf ]; then
    cp ~/.tmux.conf "$REPO_DIR/configs/common/tmux/tmux.conf"
    echo "    - Tmux config saved."
fi

# --- 2. DETECT OS AND SAVE SPECIFIC CONFIGS ---
if [ -f /etc/arch-release ] || [ -f /etc/cachyos-release ]; then
    echo "[+] Arch/CachyOS Detected - Saving Hyprland specific files..."

    # Copy Hyprland folder
    if [ -d ~/.config/hypr ]; then
        cp -r ~/.config/hypr/* "$REPO_DIR/configs/arch/hypr/"
        echo "    - Hyprland folder saved."
    fi

    # Copy Waybar (since it matches your Starship palette)
    if [ -d ~/.config/waybar ]; then
        cp -r ~/.config/waybar/* "$REPO_DIR/configs/arch/waybar/"
        echo "    - Waybar folder saved."
    fi

    # Copy Rofi
    if [ -d ~/.config/rofi ]; then
        cp -r ~/.config/rofi/* "$REPO_DIR/configs/arch/rofi/"
        echo "    - Rofi folder saved."
    fi

    # Copy Dunst
    if [ -d ~/.config/dunst ]; then
        cp -r ~/.config/dunst/* "$REPO_DIR/configs/arch/dunst/"
        echo "    - Dunst folder saved."
    fi

    # Copy Noctalia
    if [ -d ~/.config/noctalia ]; then
        cp -r ~/.config/noctalia/* "$REPO_DIR/configs/arch/noctalia/"
        echo "    - Noctalia config saved."
    fi

    # Copy custom scripts (~/.local/bin)
    if [ -d ~/.local/bin ]; then
        cp -r ~/.local/bin/* "$REPO_DIR/configs/common/scripts/"
        echo "    - Custom scripts saved."
    fi

    echo "Arch/CachyOS specific configs saved."
fi

echo "-------------------------------------------"
echo "Backup complete! You can now git push."
