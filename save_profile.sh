#!/bin/bash
# save_profile.sh - Backs up your CURRENT system config into this repo

# Get the directory where this script is located
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Saving configuration to $REPO_DIR..."

# Create base directories if they don't exist
mkdir -p "$REPO_DIR/configs/common/fish"
mkdir -p "$REPO_DIR/configs/common/kitty"
mkdir -p "$REPO_DIR/configs/common/opencode/skills"
mkdir -p "$REPO_DIR/configs/common/opencode/plugins"
mkdir -p "$REPO_DIR/configs/arch/hypr"
mkdir -p "$REPO_DIR/configs/arch/waybar"

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

# Backup Fish (Replacing .bashrc)
if [ -f ~/.config/fish/config.fish ]; then
    cp ~/.config/fish/config.fish "$REPO_DIR/configs/common/fish/config.fish"
    echo "    - Fish config saved."
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

    echo "Arch/CachyOS specific configs saved."
fi

echo "-------------------------------------------"
echo "Backup complete! You can now git push."
