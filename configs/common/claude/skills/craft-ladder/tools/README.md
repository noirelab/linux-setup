# Reading a .fig directly

Used to build `reference/evidence.md`. No Figma account, no Penpot import,
no network.

```bash
python3 extract2.py "file.fig"   # per-frame tokens: palette, type, radii, gaps, shadows, text
python3 motion.py  "file.fig"    # prototype transitions: trigger, easing, duration, node deltas
```

Needs `zstandard` (`pip install zstandard`); `zlib` and `struct` are stdlib.

`kiwi.py` is the container and schema decoder. `extract2.py` reports tokens
per top-level frame rather than per file, which is what makes before/after
frame pairs legible: those pairs usually carry identical text and differ only
in color, weight and depth.
