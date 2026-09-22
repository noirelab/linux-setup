"""Prototype transitions plus, for SMART_ANIMATE, what actually moved between
the two frames (matched by node name)."""
import sys, os, zipfile, tempfile, collections
import kiwi


def key(g):
    return (g['sessionID'], g['localID'])


def load(path):
    with zipfile.ZipFile(path) as z:
        with tempfile.NamedTemporaryFile(suffix='.fig', delete=False) as tf:
            tf.write(z.read('canvas.fig'))
            tmp = tf.name
    try:
        return kiwi.load(tmp)[1]['nodeChanges']
    finally:
        os.unlink(tmp)


def main(path):
    nodes = load(path)
    by, kids = {}, collections.defaultdict(list)
    for n in nodes:
        if 'guid' not in n:
            continue
        by[key(n['guid'])] = n
        pi = n.get('parentIndex')
        if pi:
            kids[key(pi['guid'])].append(key(n['guid']))

    def label(k):
        n = by.get(k)
        return n.get('name', '?') if n else '?(%s)' % (k,)

    def flat(k, pre='', out=None, d=0):
        out = out if out is not None else {}
        n = by.get(k)
        if n is None or d > 14:
            return out
        nm = pre + '/' + n.get('name', '?')
        t = n.get('transform') or {}
        sz = n.get('size') or {}
        out.setdefault(nm, []).append({
            'x': round(t.get('m02', 0), 1), 'y': round(t.get('m12', 0), 1),
            'w': round(sz.get('x', 0), 1), 'h': round(sz.get('y', 0), 1),
            'o': round(n.get('opacity', 1), 3),
            'r': round((n.get('cornerRadius') or 0), 1),
            'rot': round(t.get('m01', 0), 3),
            'sx': round(t.get('m00', 1), 3),
        })
        for c in kids.get(k, []):
            flat(c, nm, out, d + 1)
        return out

    print('# motion: %s' % os.path.basename(path))
    seen = set()
    for k, n in by.items():
        for it in (n.get('prototypeInteractions') or []):
            if it.get('isDeleted'):
                continue
            ev = it.get('event') or {}
            for a in (it.get('actions') or []):
                tgt = a.get('transitionNodeID')
                src = label(k)
                dst = label(key(tgt)) if tgt else '(none)'
                line = '%s -> %s | %s%s | %s %.2fs %s %s' % (
                    src, dst, ev.get('interactionType'),
                    (' %gs' % ev['transitionTimeout']) if ev.get('transitionTimeout') else '',
                    a.get('transitionType'), a.get('transitionDuration', 0) or 0,
                    a.get('easingType'),
                    a.get('easingFunction') or '')
                if line in seen:
                    continue
                seen.add(line)
                print('\n## ' + line)
                if a.get('transitionType') != 'SMART_ANIMATE' or not tgt:
                    continue
                A, B = flat(k), flat(key(tgt))
                deltas = []
                for nm in A:
                    if nm not in B or len(A[nm]) != 1 or len(B[nm]) != 1:
                        continue
                    a0, b0 = A[nm][0], B[nm][0]
                    d = {p: (a0[p], b0[p]) for p in a0 if a0[p] != b0[p]}
                    if d:
                        deltas.append((nm.split('/', 2)[-1], d))
                only_a = [nm.split('/', 2)[-1] for nm in A if nm not in B]
                only_b = [nm.split('/', 2)[-1] for nm in B if nm not in A]
                for nm, d in deltas[:22]:
                    print('   %s: %s' % (nm, ', '.join(
                        '%s %g->%g' % (p, v[0], v[1]) for p, v in d.items())))
                if only_a:
                    print('   leaves: %s' % ', '.join(only_a[:8]))
                if only_b:
                    print('   enters: %s' % ', '.join(only_b[:8]))


if __name__ == '__main__':
    main(sys.argv[1])
