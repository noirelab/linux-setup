# Firefox as default browser (links from opencode / CLI)

**Symptom:** clicking a link in the opencode TUI or in CLI tools opened another
browser (Zen/Brave) instead of Firefox.

## Root cause

Two independent things were broken on CachyOS + Hyprland:

1. **MIME hijack** — Zen was installed with `pacman -S zen-browser-bin` (Aug 2026)
   and registered itself as the default handler for `x-scheme-handler/http(s)`.
   Browsers do this on first run / after updates.
2. **`$BROWSER` missing from the session env** — `~/.config/uwsm/env` contains
   `export BROWSER=firefox`, but the Hyprland session is started by
   `start-hyprland` (not UWSM), so that file is never sourced and no process in
   the session inherits `BROWSER`.

`xdg-open` falls back to the MIME default, which is what made links land in the
wrong browser. Tools that honor `$BROWSER` had no override either.

## Fix

| Where | Change |
|---|---|
| `~/.config/fish/conf.d/browser.fish` | `set -gx BROWSER firefox` — every new fish shell (and opencode/CLIs started from it) |
| `~/.config/hypr/config/environment.lua` | `hl.env("BROWSER", "firefox")` — Hyprland-launched apps; gets exported to systemd/dbus by the autostart chain |
| MIME defaults | `xdg-settings set default-web-browser firefox.desktop` |
| MIME defaults | `xdg-mime default firefox.desktop x-scheme-handler/http x-scheme-handler/https x-scheme-handler/chrome text/html application/xhtml+xml` |
| Current session (no relogin) | `systemctl --user set-environment BROWSER=firefox` |
| Current session (no relogin) | `dbus-update-activation-environment --systemd BROWSER=firefox` |

Both config files are versioned in this repo:

```
configs/common/fish/conf.d/browser.fish
configs/arch/hypr/config/environment.lua
```

## Verification

```bash
xdg-settings get default-web-browser            # firefox.desktop
xdg-mime query default x-scheme-handler/https   # firefox.desktop
fish -c 'echo $BROWSER'                         # firefox
xdg-open https://example.com                    # opens a tab in the running Firefox
```

Live check on Hyprland: snapshot windows, open a URL, snapshot again — the
existing Firefox window title changes and no `zen-bin` / `brave` / `chromium`
process spawns:

```bash
hyprctl clients -j | jq -r '.[] | "\(.address) \(.class) \(.title)"' | sort > /tmp/before
xdg-open https://example.com
sleep 3
hyprctl clients -j | jq -r '.[] | "\(.address) \(.class) \(.title)"' | sort > /tmp/after
diff /tmp/before /tmp/after
```

## Why opencode itself needs no config

The opencode binary on Linux shells out to `xdg-open` for external URLs (the
bundled `open` implementation only honors `$BROWSER` on WSL). So fixing the MIME
default is enough for opencode, VS Code/Electron, kitty hyperlinks, and any tool
that goes through `xdg-open`; `$BROWSER` is the belt-and-suspenders override for
tools that read it directly (Python `webbrowser`, etc.).

## If it breaks again

A browser update can re-register itself as default. Re-assert:

```bash
xdg-settings set default-web-browser firefox.desktop
```

Keeping `$BROWSER=firefox` in the fish conf and the Hyprland env protects the
tools that consult the variable, but `xdg-open` still follows the MIME default —
so re-run the command above whenever another browser is installed or updated.
