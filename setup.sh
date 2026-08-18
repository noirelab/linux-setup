#!/bin/bash

# --- COLORS & VARS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DISTRO=""

# --- HELPER FUNCTIONS ---

confirm() {
    while true; do
        read -p "$(echo -e ${YELLOW}"$1 (y/n): "${NC})" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        # DEBUG: Uncomment the next line if it still fails to see what your system reports
        # echo "DEBUG: ID=$ID, ID_LIKE=$ID_LIKE"

        # Added explicit check for "cachyos"
        if [[ "$ID" == "arch" || "$ID" == "cachyos" || "$ID_LIKE" == *"arch"* ]]; then
            DISTRO="arch"
        elif [[ "$ID" == "debian" || "$ID" == "linuxmint" || "$ID_LIKE" == *"debian"* || "$ID_LIKE" == *"ubuntu"* ]]; then
            DISTRO="debian"
        fi
    fi

    if [ -z "$DISTRO" ]; then
        echo -e "${RED}Error: Unsupported OS. Detected ID: $ID${NC}"
        exit 1
    fi
    echo -e "${BLUE}=== Detected OS: $DISTRO ($ID) ===${NC}"
}

install_aur() {
    # Arch Helper Function
    if command -v paru &> /dev/null; then
        paru -S --noconfirm "$1"
    elif command -v yay &> /dev/null; then
        yay -S --noconfirm "$1"
    else
        echo -e "${YELLOW}No AUR helper found. Installing yay...${NC}"
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
        yay -S --noconfirm "$1"
    fi
}

# --- SHORTCUT HELPER (DEBIAN/MINT ONLY) ---
set_gnome_shortcut() {
    local name="$1"
    local command="$2"
    local binding="$3"
    local index="$4"

    if gsettings list-schemas | grep -q "org.cinnamon.desktop.keybindings"; then
        SCHEMA="org.cinnamon.desktop.keybindings.custom-keybinding"
        PATH_PREFIX="/org/cinnamon/desktop/keybindings/custom-keybindings/custom${index}/"
    else
        SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
        PATH_PREFIX="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${index}/"
    fi

    gsettings set "$SCHEMA:$PATH_PREFIX" name "$name"
    gsettings set "$SCHEMA:$PATH_PREFIX" command "$command"
    gsettings set "$SCHEMA:$PATH_PREFIX" binding "['$binding']"
    echo "    -> Set '$name' to '$binding'"
}

update_shortcut_list() {
    local count="$1"
    local list_string="["
    for ((i=0; i<count; i++)); do
        if [ "$i" -gt 0 ]; then list_string+=", "; fi
        if gsettings list-schemas | grep -q "org.cinnamon.desktop.keybindings"; then
             list_string+="'custom${i}'"
        else
             list_string+="'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${i}/'"
        fi
    done
    list_string+="]"

    if gsettings list-schemas | grep -q "org.cinnamon.desktop.keybindings"; then
        gsettings set org.cinnamon.desktop.keybindings custom-list "$list_string"
    else
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$list_string"
    fi
}

# ==============================================================================
# --- MAIN LOGIC ---
# ==============================================================================

detect_os

# --- 1. SYSTEM UPDATE & TOOLS ---
if confirm "Update System & Install Build Tools?"; then
    echo -e "${GREEN}[+] Updating System...${NC}"
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -Syu --noconfirm
        sudo pacman -S --needed --noconfirm base-devel git wget curl
        sudo pacman -S --needed --noconfirm grim slurp wl-clipboard brightnessctl playerctl
    else
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y curl wget git build-essential
    fi
fi

if confirm "Install gaming packages and optimizations?"; then
    echo -e "${GREEN}[+] Installing Gaming Packages...${NC}"
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S cachyos-gaming-meta cachyos-gaming-applications
    else
        sudo apt install -y steam lutris mangohud
    fi
fi

# --- 2. TERMINAL & SHELL (Common) ---
if confirm "Install Kitty & Nerd Fonts?"; then
    echo -e "${GREEN}[+] Installing Terminal Essentials...${NC}"

    # Install Packages
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm kitty ttf-firacode-nerd ttf-jetbrains-mono-nerd
    else
        sudo apt install -y kitty
        # Fonts manual install for Debian
        mkdir -p ~/.local/share/fonts
        if [ ! -f ~/.local/share/fonts/FiraCodeNerdFont-Regular.ttf ]; then
            wget -qO /tmp/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip
            unzip -o /tmp/FiraCode.zip -d ~/.local/share/fonts
            fc-cache -fv
        fi
    fi

    # Configs (Shared)
    echo -e "${GREEN}[+] Deploying Kitty Config...${NC}"
    mkdir -p ~/.config/kitty
    cp -r "$SCRIPT_DIR/configs/common/kitty/"* ~/.config/kitty/ 2>/dev/null

    # Deploy OpenCode (~/.config/opencode + ~/.opencode)
    if [ -d "$SCRIPT_DIR/configs/common/opencode" ]; then
        mkdir -p ~/.config/opencode
        cp -r "$SCRIPT_DIR/configs/common/opencode/"* ~/.config/opencode/ 2>/dev/null
        echo "    - OpenCode config deployed."
        if grep -q "REPLACE_ME" ~/.config/opencode/opencode.json 2>/dev/null; then
            echo -e "${YELLOW}    ! opencode.json has redacted MCP headers. Fill in REPLACE_ME with your API keys.${NC}"
        fi
    fi

    if [ -d "$SCRIPT_DIR/configs/common/opencode_home" ]; then
        mkdir -p ~/.opencode
        cp -r "$SCRIPT_DIR/configs/common/opencode_home/"* ~/.opencode/ 2>/dev/null
        echo "    - OpenCode home deployed ($(ls "$SCRIPT_DIR/configs/common/opencode_home/skills" 2>/dev/null | wc -l) skills)."
        if [ -f ~/.opencode/package.json ] && command -v npm &> /dev/null; then
            (cd ~/.opencode && npm install --silent) && echo "    - OpenCode home deps installed."
        fi
    fi

    # Deploy Fish (config, functions, conf.d, variables)
    if [ -d "$SCRIPT_DIR/configs/common/fish" ]; then
        mkdir -p ~/.config/fish
        cp -r "$SCRIPT_DIR/configs/common/fish/"* ~/.config/fish/ 2>/dev/null
        echo "    - Fish config, functions and conf.d deployed."
    fi

    # Deploy custom scripts (~/.local/bin)
    if [ -d "$SCRIPT_DIR/configs/common/scripts" ]; then
        mkdir -p ~/.local/bin
        cp -r "$SCRIPT_DIR/configs/common/scripts/"* ~/.local/bin/ 2>/dev/null
        chmod +x ~/.local/bin/* 2>/dev/null
        echo "    - Custom scripts deployed."
    fi

    # Deploy wallpaper (awww, Hyprlock and SDDM all read ~/Pictures/wallpaper.jpg)
    if [ -f "$SCRIPT_DIR/configs/common/wallpapers/wallpaper.jpg" ]; then
        mkdir -p ~/Pictures
        cp "$SCRIPT_DIR/configs/common/wallpapers/wallpaper.jpg" ~/Pictures/wallpaper.jpg
        echo "    - Wallpaper deployed to ~/Pictures/wallpaper.jpg"
    fi

    # Deploy tmux
    if [ -f "$SCRIPT_DIR/configs/common/tmux/tmux.conf" ]; then
        cp "$SCRIPT_DIR/configs/common/tmux/tmux.conf" ~/.tmux.conf
        echo "    - Tmux config deployed."
    fi
fi

# --- 2.5 TERMINAL TOOLS (Tmux) ---
if confirm "Install Tmux?"; then
    echo -e "${GREEN}[+] Installing Tmux...${NC}"
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm tmux
    else
        sudo apt install -y tmux
    fi

    if [ -f "$SCRIPT_DIR/configs/common/tmux/tmux.conf" ]; then
        cp "$SCRIPT_DIR/configs/common/tmux/tmux.conf" ~/.tmux.conf
        echo "    - Tmux config deployed."
    fi
fi

# --- 3. APPLICATIONS ---
if confirm "Install Applications (Code, Spotify, Discord, Firefox)?"; then
    echo -e "${GREEN}[+] Installing Apps...${NC}"

    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm firefox discord nemo
        install_aur "visual-studio-code-bin"
        install_aur "spotify"
    else
        # Debian/Ubuntu Logic
        sudo apt install -y firefox nemo

        # VS Code Repo
        if ! command -v code &> /dev/null; then
             wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
             sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
             sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
             rm packages.microsoft.gpg
             sudo apt update && sudo apt install -y code
        fi

        # Spotify Repo
        if ! command -v spotify &> /dev/null; then
             curl -sS https://download.spotify.com/debian/pubkey_6224F9NNa.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
             echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
             sudo apt update && sudo apt install -y spotify-client
        fi

        # Discord
        if ! command -v discord &> /dev/null; then
            wget -O /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
            sudo dpkg -i /tmp/discord.deb
            sudo apt install -f -y
        fi
    fi
fi

# --- 3.5 OPENCODE ---
if confirm "Install OpenCode (AI Assistant)?"; then
    echo -e "${GREEN}[+] Installing OpenCode...${NC}"
    curl -fsSL https://opencode.ai/install | bash
fi

# --- 3.6 OPENCODE SEO SKILLS ---
if confirm "Install OpenCode SEO Skills (25 skills, python3 required)?"; then
    echo -e "${GREEN}[+] Installing OpenCode SEO Skills...${NC}"
    if [ -f "$SCRIPT_DIR/install-opencode-seo.sh" ]; then
        bash "$SCRIPT_DIR/install-opencode-seo.sh"
    else
        echo -e "${YELLOW}Warning: install-opencode-seo.sh not found. Skipping.${NC}"
    fi
fi

# --- 3.7 CLAUDE CODE ---
if confirm "Install/restore Claude Code config (skills, plugins, hooks)?"; then
    echo -e "${GREEN}[+] Restoring Claude Code...${NC}"
    CLAUDE_SRC="$SCRIPT_DIR/configs/common/claude"

    if ! command -v claude &> /dev/null; then
        echo -e "${YELLOW}Claude Code not found. Installing...${NC}"
        curl -fsSL https://claude.ai/install.sh | bash
    fi

    mkdir -p ~/.claude/skills ~/.claude/hooks

    [ -f "$CLAUDE_SRC/CLAUDE.md" ]     && cp "$CLAUDE_SRC/CLAUDE.md" ~/.claude/CLAUDE.md
    [ -f "$CLAUDE_SRC/settings.json" ] && cp "$CLAUDE_SRC/settings.json" ~/.claude/settings.json
    for d in hooks agents commands skills; do
        [ -d "$CLAUDE_SRC/$d" ] && mkdir -p ~/.claude/$d && cp -r "$CLAUDE_SRC/$d/"* ~/.claude/$d/ 2>/dev/null
    done
    chmod +x ~/.claude/hooks/* 2>/dev/null
    echo "    - Skills, hooks, agents, commands and settings deployed."

    # Plugins: re-add marketplaces, then reinstall each plugin from its manifest.
    if command -v jq &> /dev/null && [ -f "$CLAUDE_SRC/plugins/known_marketplaces.json" ]; then
        jq -r 'to_entries[] | select(.value.source.source == "github") | .value.source.repo' \
            "$CLAUDE_SRC/plugins/known_marketplaces.json" | while read -r repo; do
            claude plugin marketplace add "$repo" 2>/dev/null && echo "    - marketplace: $repo"
        done

        jq -r '.plugins | keys[]' "$CLAUDE_SRC/plugins/installed_plugins.json" 2>/dev/null | while read -r plugin; do
            claude plugin install "$plugin" 2>/dev/null && echo "    - plugin: $plugin"
        done
    else
        echo -e "${YELLOW}    ! jq missing or no plugin manifest. Skipping plugin restore.${NC}"
    fi

    # gstack lives in its own git repo (too large to vendor here).
    GSTACK_JSON="$CLAUDE_SRC/external-skills.json"
    if [ -f "$GSTACK_JSON" ] && [ ! -d ~/.claude/skills/gstack ] && command -v jq &> /dev/null; then
        if confirm "  Clone gstack skill (~1.6G after install)?"; then
            git clone "$(jq -r .gstack.repo "$GSTACK_JSON")" ~/.claude/skills/gstack
            git -C ~/.claude/skills/gstack checkout "$(jq -r .gstack.commit "$GSTACK_JSON")" 2>/dev/null
            command -v bun &> /dev/null && (cd ~/.claude/skills/gstack && bun install)
            echo "    - gstack cloned. Run /gstack-upgrade later to move to latest."
        fi
    fi
fi

# --- 4. DEV TOOLS (Docker, Nvidia, Conda) ---
if confirm "Install Dev Tools (Docker, Nvidia Toolkit, Miniconda)?"; then

    # Docker
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm docker docker-compose nvidia-container-toolkit
        sudo systemctl enable --now docker.service
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
        sudo usermod -aG docker $USER
    else
        # Simple Ubuntu Docker install
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin nvidia-container-toolkit
        sudo usermod -aG docker $USER
    fi

    # Miniconda (Shared)
    if [ ! -d ~/miniconda3 ]; then
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3_install.sh
        bash ~/miniconda3_install.sh -b -u -p ~/miniconda3
        rm ~/miniconda3_install.sh
        ~/miniconda3/bin/conda init bash
        # Also init fish if it's installed
        if command -v fish &> /dev/null; then
            ~/miniconda3/bin/conda init fish
        fi
    fi
fi

# --- 5. CONFIGURATION & SHORTCUTS (The Split Logic) ---
echo -e "${BLUE}=== Configuring Desktop Environment ===${NC}"

if [ "$DISTRO" == "arch" ]; then
    # --- ARCH / HYPRLAND PATH ---
    if confirm "Deploy Hyprland & Noctalia Configs?"; then
        echo -e "${GREEN}[+] Copying Arch Configs...${NC}"

        # Install Hyprland Basics if missing
        sudo pacman -S --noconfirm hyprland rofi dunst polkit-kde-agent hyprlock hypridle hyprpicker
        sudo pacman -S --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber nvtop btop wl-clipboard ydotool

        # Noctalia is the current bar/shell (Waybar is kept only as a fallback)
        install_aur "noctalia"
        install_aur "awww"

        # Copy Configs
        mkdir -p ~/.config/hypr ~/.config/noctalia ~/.config/rofi ~/.config/dunst
        cp -r "$SCRIPT_DIR/configs/arch/hypr/"*     ~/.config/hypr/ 2>/dev/null
        cp -r "$SCRIPT_DIR/configs/arch/noctalia/"* ~/.config/noctalia/ 2>/dev/null
        cp -r "$SCRIPT_DIR/configs/arch/rofi/"*     ~/.config/rofi/ 2>/dev/null
        cp -r "$SCRIPT_DIR/configs/arch/dunst/"*    ~/.config/dunst/ 2>/dev/null

        echo "    - Hyprland + Noctalia configs deployed."
        echo "      Keybinds: ~/.config/hypr/config/binds.lua"
        echo "      Noctalia bar + plugins: ~/.config/noctalia/"
    fi

    # systemd user units (chico, awww-daemon, ydotool) referenced by hypr autostart
    if [ -d "$SCRIPT_DIR/configs/common/systemd" ]; then
        if confirm "Deploy systemd user units?"; then
            mkdir -p ~/.config/systemd/user
            cp "$SCRIPT_DIR/configs/common/systemd/"*.service ~/.config/systemd/user/ 2>/dev/null
            systemctl --user daemon-reload
            echo "    - systemd user units deployed. Enable with: systemctl --user enable --now <unit>"
        fi
    fi

else
    # --- DEBIAN / MINT PATH ---
    if confirm "Configure GNOME/Cinnamon Shortcuts?"; then
        echo -e "${GREEN}[+] Setting up Keybindings...${NC}"
        sudo apt install -y wmctrl xdotool gnome-screenshot btop

        set_gnome_shortcut "Terminal" "kitty --start-as fullscreen" "<Super>Return" 0
        set_gnome_shortcut "Discord" "discord" "<Super>slash" 1
        set_gnome_shortcut "VS Code" "code" "<Super>v" 2
        set_gnome_shortcut "Gemini" "xdg-open https://gemini.google.com" "<Super>g" 3
        set_gnome_shortcut "Firefox" "firefox" "<Super>w" 4
        set_gnome_shortcut "Spotify" "spotify" "<Super>s" 5
        set_gnome_shortcut "btop" "kitty --start-as fullscreen -e btop" "<Ctrl><Shift>Escape" 6
        set_gnome_shortcut "Screenshot" "gnome-screenshot -a" "<Super><Shift>s" 7
        set_gnome_shortcut "Minimize" "xdotool getactivewindow windowminimize" "<Super>m" 11

        update_shortcut_list 12
        echo "Shortcuts registered!"

        # Install Mint specific scripts if they exist
        if [ -f "$SCRIPT_DIR/configs/mint/opacify_windows.sh" ]; then
             cp "$SCRIPT_DIR/configs/mint/opacify_windows.sh" ~/.local/bin/
             chmod +x ~/.local/bin/opacify_windows.sh
        fi
    fi
fi


install_hyprlock() {
    echo ":: Setting up Lock Screen (Hyprlock & Hypridle)..."

    # 1. Install Packages (Arch only)
    if [ "$DISTRO" == "arch" ]; then
        sudo pacman -S --noconfirm hyprlock hypridle
    fi

    # 2. Ensure Wallpaper is in the right place for the User
    # We copy the setup wallpaper to the user's Pictures folder so config finds it
    WALLPAPER_SRC="$SCRIPT_DIR/configs/common/wallpapers/wallpaper.jpg"
    DEST_DIR="$HOME/Pictures"
    mkdir -p "$DEST_DIR"

    if [ -f "$WALLPAPER_SRC" ]; then
        cp "$WALLPAPER_SRC" "$DEST_DIR/wallpaper.jpg"
        echo ":: Wallpaper copied to $DEST_DIR/wallpaper.jpg"
    else
        echo -e "${YELLOW}WARNING: Wallpaper not found at $WALLPAPER_SRC${NC}"
        echo -e "${YELLOW}Add a wallpaper.jpg to configs/common/wallpapers/ or update hyprlock.conf path${NC}"
    fi

    # 3. Skip hyprlock.conf generation - using custom config from repo
    echo ":: Using custom hyprlock.conf from repo (already copied)"

    # 4. Write hypridle.conf (Triggers)
    echo ":: Generating ~/.config/hypr/hypridle.conf..."
    cat > "$HOME/.config/hypr/hypridle.conf" <<EOF
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = pidof hyprlock || hyprlock
    after_sleep_cmd = hyprctl dispatch dpms on
    ignore_dbus_inhibit = false
}

listener {
    timeout = 120
    on-timeout = brightnessctl -s set 10
    on-resume = brightnessctl -r
}

listener {
    timeout = 300
    on-timeout = pidof hyprlock || hyprlock
}

listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
EOF

    # 5. Hypridle is already in autostart via hyprland.conf + exec.conf
    echo ":: Hypridle & Hyprlock setup complete."
}

# --- 6. DOTFILES (Bashrc) ---
if confirm "Install .bashrc?"; then
    # Backup existing .bashrc if it exists
    if [ -f ~/.bashrc ]; then
        cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d-%H%M%S)
        echo "Existing .bashrc backed up"
    fi
    cp "$SCRIPT_DIR/configs/common/.bashrc" ~/.bashrc
    echo "Bashrc updated."
fi

# --- 7. SDDM THEME (Arch Only) ---
if [ "$DISTRO" == "arch" ]; then
    if confirm "Install Custom SDDM Theme?"; then
        echo -e "${GREEN}[+] Installing SDDM theme...${NC}"
        sudo pacman -S --noconfirm sddm

        # Create theme directory
        sudo mkdir -p /usr/share/sddm/themes/custom

        # Copy theme files
        sudo cp "$SCRIPT_DIR/configs/arch/sddm/Main.qml" /usr/share/sddm/themes/custom/
        sudo cp "$SCRIPT_DIR/configs/arch/sddm/theme.conf" /usr/share/sddm/themes/custom/
        sudo cp "$SCRIPT_DIR/configs/arch/sddm/metadata.desktop" /usr/share/sddm/themes/custom/

        # Copy wallpaper so sddm user can read it
        if [ -f "$HOME/Pictures/wallpaper.jpg" ]; then
            sudo cp "$HOME/Pictures/wallpaper.jpg" /usr/share/sddm/themes/custom/wallpaper.jpg
        elif [ -f "$SCRIPT_DIR/configs/common/wallpapers/wallpaper.jpg" ]; then
            sudo cp "$SCRIPT_DIR/configs/common/wallpapers/wallpaper.jpg" /usr/share/sddm/themes/custom/wallpaper.jpg
        fi

        # Configure SDDM to use the custom theme
        echo '[Autologin]
Session=hyprland

[Theme]
Current=custom' | sudo tee /etc/sddm.conf

        sudo systemctl enable sddm
        echo "SDDM theme installed with your wallpaper! Reboot to see it."
    fi
fi

# --- 8. HYPRLOCK (Arch Only) ---
if [ "$DISTRO" == "arch" ]; then
    if confirm "Install Hyprlock & Hypridle?"; then
        install_hyprlock
    fi
fi

echo ""
echo -e "${BLUE}=== Setup Complete ===${NC}"
echo "Please restart your computer/session."
