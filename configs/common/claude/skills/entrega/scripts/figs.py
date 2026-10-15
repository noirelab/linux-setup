"""Gera figuras (código e fluxos) como PNG via Chromium headless.

uso: python figs.py spec.json   -> spec = [{"out":..., "kind":"code"|"flow", ...}]
"""
import html
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from pygments import highlight
from pygments.formatters import HtmlFormatter
from pygments.lexers import get_lexer_by_name

BASE_CSS = """
body{margin:0;padding:24px;background:#fff;font-family:Arial,sans-serif;display:inline-block}
.code{background:#f6f8fa;border:1px solid #e1e4e8;border-radius:8px;overflow:hidden;width:max-content;min-width:640px}
.code .head{padding:10px 16px;border-bottom:1px solid #e1e4e8;color:#57606a;font:13px 'DejaVu Sans Mono',monospace}
.code pre{margin:0;padding:12px 18px 14px 0;font:15px/1.5 'DejaVu Sans Mono',monospace}
.code .ln{display:inline-block;width:42px;text-align:right;padding-right:16px;color:#8c959f;user-select:none}
.flow{display:flex;align-items:center;gap:0;font-size:17px}
.col{display:flex;flex-direction:column;gap:14px;align-items:center}
.box{border:2px solid;border-radius:10px;padding:14px 20px;text-align:center;min-width:120px;background:#fff}
.box small{display:block;color:#57606a;font-size:13px;margin-top:4px}
.arrow{width:56px;text-align:center;color:#57606a;font-size:26px}
.label{font-size:13px;color:#57606a;display:block}
.blue{border-color:#4a7fd4;background:#eef4ff}.green{border-color:#3f9a5c;background:#eefaf1}
.orange{border-color:#d9822b;background:#fff5ea}.purple{border-color:#8a63d2;background:#f5f0ff}
.term{background:#1e1e1e;color:#d4d4d4;border-radius:8px;padding:16px 20px;font:14px/1.45 "DejaVu Sans Mono",monospace;white-space:pre;width:max-content}.term b{color:#8ae68a}
.gray{border-color:#8c959f;background:#f6f8fa}.red{border-color:#cf4a4a;background:#fff0f0}
"""


def code_html(spec):
    lexer = get_lexer_by_name(spec["lang"])
    fmt = HtmlFormatter(nowrap=True, style="default", noclasses=True)
    lines = highlight(spec["code"].strip("\n"), lexer, fmt).rstrip("\n").split("\n")
    body = "\n".join(f'<span class="ln">{i}</span>{l}' for i, l in enumerate(lines, 1))
    return f'<div class="code"><div class="head">{html.escape(spec["title"])}</div><pre>{body}</pre></div>'


def box(b):
    sub = f"<small>{html.escape(b['sub'])}</small>" if b.get("sub") else ""
    return f'<div class="box {b.get("color", "blue")}">{html.escape(b["text"])}{sub}</div>'


def flow_html(spec):
    parts = []
    for i, step in enumerate(spec["steps"]):
        if i:
            label = spec.get("labels", [""] * 99)[i - 1]
            parts.append(f'<div class="arrow"><span class="label">{html.escape(label)}</span>→</div>')
        items = step if isinstance(step, list) else [step]
        parts.append('<div class="col">' + "".join(box(b) for b in items) + "</div>")
    return '<div class="flow">' + "".join(parts) + "</div>"


def render(spec):
    if spec["kind"] == "term":
        inner = '<div class="term"><b>' + html.escape(spec["cmd"]) + "</b>\n" + html.escape(spec["text"]) + "</div>"
    else:
        inner = code_html(spec) if spec["kind"] == "code" else flow_html(spec)
    page = f"<html><head><meta charset='utf-8'><style>{BASE_CSS}</style></head><body>{inner}</body></html>"
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "f.html"
        raw = Path(tmp) / "raw.png"
        src.write_text(page, encoding="utf-8")
        subprocess.run(
            ["chromium", "--headless", "--no-sandbox", "--hide-scrollbars",
             "--force-device-scale-factor=2", "--window-size=1400,1400",
             f"--screenshot={raw}", src.as_uri()],
            check=True, capture_output=True,
        )
        subprocess.run(["magick", raw, "-trim", "-bordercolor", "white", "-border", "24", spec["out"]], check=True)
    print(spec["out"])


if __name__ == "__main__":
    for s in json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")):
        render(s)
