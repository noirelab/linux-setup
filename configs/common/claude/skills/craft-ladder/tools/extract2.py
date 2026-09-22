"""Per-top-level-frame digest: the before/after pairs in these files differ
visually, not textually, so tokens have to be reported per frame to see the delta."""
import sys, os, zipfile, tempfile, collections, json
import kiwi


def hexa(c):
    h = '#%02X%02X%02X' % tuple(min(255, max(0, round(c[k] * 255))) for k in 'rgb')
    a = c.get('a', 1.0)
    return h if a > 0.995 else '%s@%.2f' % (h, a)


def key(g):
    return (g['sessionID'], g['localID'])


def paint(p):
    t = p.get('type', '')
    if t == 'SOLID':
        return hexa(p['color'])
    if t.startswith('GRADIENT'):
        return '%s(%s)' % (t.replace('GRADIENT_', 'grad-').lower(),
                           '>'.join(hexa(s['color']) for s in p.get('stops', [])[:4]))
    if t == 'IMAGE':
        return 'image'
    return t.lower()


class Frame:
    def __init__(self, name, w, h):
        self.name, self.w, self.h = name, w, h
        self.bg = None
        self.fills = collections.Counter()
        self.strokes = collections.Counter()
        self.shadows = collections.Counter()
        self.blurs = collections.Counter()
        self.type = collections.Counter()
        self.radii = collections.Counter()
        self.gaps = collections.Counter()
        self.pads = collections.Counter()
        self.sw = collections.Counter()
        self.text = []
        self.seen = set()
        self.count = 0


def collect(fr, n):
    fr.count += 1
    for p in (n.get('fillPaints') or []):
        if p.get('visible', True):
            fr.fills[paint(p)] += 1
    for p in (n.get('strokePaints') or []):
        if p.get('visible', True):
            fr.strokes[paint(p)] += 1
    for e in (n.get('effects') or []):
        if not e.get('visible', True):
            continue
        t = e.get('type', '')
        if 'SHADOW' in t:
            o = e.get('offset') or {}
            fr.shadows['%s %g/%g blur%g spread%g %s' % (
                'drop' if t == 'DROP_SHADOW' else 'inner', o.get('x', 0), o.get('y', 0),
                e.get('radius', 0), e.get('spread', 0), hexa(e['color']))] += 1
        else:
            fr.blurs['%s %g' % (t.lower(), e.get('radius', 0))] += 1
    fn = n.get('fontName')
    if fn:
        fr.type['%s %s %gpx' % (fn.get('family'), fn.get('style'),
                                round(n.get('fontSize', 0), 1))] += 1
    for f in ('cornerRadius', 'rectangleTopLeftCornerRadius'):
        if n.get(f):
            fr.radii[round(n[f], 1)] += 1
    if n.get('stackSpacing') is not None:
        fr.gaps[round(n['stackSpacing'], 1)] += 1
    for f in ('stackHorizontalPadding', 'stackVerticalPadding',
              'stackPaddingRight', 'stackPaddingBottom'):
        if n.get(f):
            fr.pads[round(n[f], 1)] += 1
    if n.get('strokeWeight') and (n.get('strokePaints') or []):
        fr.sw[round(n['strokeWeight'], 2)] += 1
    if n.get('type') == 'TEXT':
        ch = ((n.get('textData') or {}).get('characters') or '').strip()
        if len(ch) < 2:
            return
        k = (ch, round(n.get('fontSize', 0)))
        if k in fr.seen:
            return
        fr.seen.add(k)
        fr.text.append('[%dpx] %s' % (k[1], ch.replace('\n', ' / ')[:400]))


def top(c, n=14):
    return ', '.join('%s x%d' % (k, v) for k, v in c.most_common(n))


def digest(path):
    with zipfile.ZipFile(path) as z:
        with tempfile.NamedTemporaryFile(suffix='.fig', delete=False) as tf:
            tf.write(z.read('canvas.fig'))
            tmp = tf.name
        meta = json.loads(z.read('meta.json'))
    try:
        _, msg = kiwi.load(tmp)
    finally:
        os.unlink(tmp)

    by, kids = {}, collections.defaultdict(list)
    for n in msg['nodeChanges']:
        if 'guid' not in n:
            continue
        by[key(n['guid'])] = n
        pi = n.get('parentIndex')
        if pi:
            kids[key(pi['guid'])].append((pi.get('position', ''), key(n['guid'])))
    for k in kids:
        kids[k].sort()

    L = ['# %s' % meta.get('file_name', os.path.basename(path))]

    def subtree(k, fr):
        collect(fr, by[k])
        for _, c in kids.get(k, []):
            subtree(c, fr)

    for _, pk in sorted(kids.get((0, 0), [])):
        page = by.get(pk)
        if not page or page.get('type') != 'CANVAS':
            continue
        if page.get('name') == 'Internal Only Canvas':
            continue
        L.append('\n## page: %s' % page.get('name'))
        for _, fk in kids.get(pk, []):
            n = by[fk]
            sz = n.get('size') or {}
            fr = Frame(n.get('name', '?'), round(sz.get('x', 0)), round(sz.get('y', 0)))
            fp = n.get('fillPaints') or []
            fr.bg = paint(fp[0]) if fp else None
            subtree(fk, fr)
            L.append('\n### %s  [%dx%d, %d nodes]' % (fr.name, fr.w, fr.h, fr.count))
            if fr.bg:
                L.append('bg: %s' % fr.bg)
            L.append('fills: %s' % top(fr.fills, 16))
            if fr.strokes:
                L.append('strokes: %s | weights %s' % (top(fr.strokes, 8), top(fr.sw, 6)))
            if fr.shadows:
                L.append('shadows: %s' % top(fr.shadows, 8))
            if fr.blurs:
                L.append('blurs: %s' % top(fr.blurs, 4))
            L.append('type: %s' % top(fr.type, 14))
            if fr.radii:
                L.append('radii: %s' % top(fr.radii, 10))
            if fr.gaps or fr.pads:
                L.append('gaps: %s | pad: %s' % (top(fr.gaps, 10), top(fr.pads, 10)))
            if fr.text:
                L.append('text: ' + ' | '.join(fr.text))
    return '\n'.join(L)


if __name__ == '__main__':
    print(digest(sys.argv[1]))
