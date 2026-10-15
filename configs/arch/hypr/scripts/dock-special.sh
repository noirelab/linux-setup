#!/usr/bin/env bash
# Noctalia's smart_auto_hide ignores windows on special workspaces, so the dock
# stays over the SUPER+N shelf. Hide it while any special workspace is open.
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" |
while IFS= read -r line; do
    case $line in
        activespecial\>\>,*) noctalia msg dock-show >/dev/null ;;
        activespecial\>\>*)  noctalia msg dock-hide >/dev/null ;;
    esac
done
