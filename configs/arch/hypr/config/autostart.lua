-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    -- chico needs WAYLAND_DISPLAY in the systemd user env, so chain it after the import
    hl.exec_cmd("bash -c 'dbus-update-activation-environment --systemd --all && systemctl --user start chico.service'")
    -- opendeck starts hidden to tray (--hide); same env import chain as chico
    hl.exec_cmd("bash -c 'dbus-update-activation-environment --systemd --all && systemctl --user start opendeck.service'")
    -- elephant feeds walker (SUPER+Space); graphical-session.target never activates here
    hl.exec_cmd("bash -c 'dbus-update-activation-environment --systemd --all && systemctl --user start elephant.service'")
    -- spotify opens on special:minimized (window rule), toggle with SUPER+N
    hl.exec_cmd("spotify")
    hl.exec_cmd("systemctl --user start awww-daemon.service")
    hl.exec_cmd("awww img " .. os.getenv("HOME") .. "/Pictures/wallpaper.jpg --outputs DP-1,HDMI-A-1")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("xhost +SI:localuser:root")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/dock-special.sh")
end)
