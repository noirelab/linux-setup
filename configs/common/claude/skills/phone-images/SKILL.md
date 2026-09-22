---
name: phone-images
description: "Use whenever you need to show the user an image (screenshot, generated photo, mockup, PNG/JPG output) and they are working over SSH from their phone, possibly away from home on Tailscale, where inline Read-tool image rendering may not display. Also use when the user explicitly asks to see something \"no celular\" or \"fora de casa\". Serves images through a small gallery page on the machine's Tailscale IP instead."
---

# Phone image gallery (Tailscale)

The user SSHes into this machine from their phone, sometimes away from home,
reachable over Tailscale. Their terminal client may not support inline image
rendering (Kitty/iTerm2 graphics protocol), so the Read tool's normal inline
display does not reliably reach them — confirmed live, they said "cadê" /
"eu quero ver" when that happened. The fix is a tiny gallery server bound
only to the Tailscale interface, already built at `~/claude-images/serve.py`.

## Every time you need to show an image

1. Make sure the server is up:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" http://$(tailscale ip -4):8765/
   ```
   If that is not `200`, start it:
   ```bash
   cd ~/claude-images && nohup python3 serve.py > /tmp/claude-images-server.log 2>&1 & disown
   ```
2. Copy every image you want them to see into `~/claude-images/<project>/`,
   one subfolder per project or topic (e.g. `~/claude-images/carousel-fix/`),
   any filename inside it (`.png`/`.jpg`/`.jpeg`/`.gif`/`.webp`). The
   gallery groups sections by that subfolder name, newest project first,
   images in chronological order within it, with arrows in the lightbox to
   move between a project's own images. Reuse the same subfolder across a
   session's follow-up screenshots for the same piece of work, rather than
   inventing a new one each time. A file dropped directly in
   `~/claude-images/` with no subfolder still shows, grouped under
   "sem projeto" as a fallback — never the first choice.
3. Tell the user: **http://\<tailscale-ip\>:8765/** — get the real IP with
   `tailscale ip -4` each time rather than assuming it never changes. One
   link covers everything currently in the folder; you do not need to give
   a per-file URL. The page auto-refreshes every few seconds, so dropping
   more files into an existing project folder later (mid-conversation) just
   makes them appear in that section, no need to re-send the link.

## Notes

- Bind is the Tailscale IP only, never `0.0.0.0` — reachable from their
  tailnet, not the LAN or the open internet. Never change this without the
  user asking.
- The server is not a systemd service; it dies on reboot. If the health
  check in step 1 fails, just restart it per step 1, do not investigate
  further unless it keeps failing.
- The folder accumulates images across sessions since nothing deletes
  them. Do not clean it up unprompted; if it gets large enough to matter,
  ask the user first.
- If they are on the same LAN/at home, a plain `http://127.0.0.1:<port>/`
  link to whatever dev server is already running (e.g. this repo's Next
  dev server) still works and is simpler when that applies — this skill's
  gallery is specifically for "not on the same network."
