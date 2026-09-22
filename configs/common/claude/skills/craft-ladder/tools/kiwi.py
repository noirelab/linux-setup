"""Minimal kiwi decoder, enough to read Figma .fig canvas payloads."""
import struct, zlib, zstandard

PRIM = {-1: 'bool', -2: 'byte', -3: 'int', -4: 'uint', -5: 'float',
        -6: 'string', -7: 'int64', -8: 'uint64'}
KINDS = ['ENUM', 'STRUCT', 'MESSAGE']


class BB:
    def __init__(self, data):
        self.d = data
        self.i = 0

    def byte(self):
        b = self.d[self.i]
        self.i += 1
        return b

    def varuint(self):
        v = 0
        shift = 0
        while True:
            b = self.byte()
            v |= (b & 127) << shift
            shift += 7
            if not (b & 128):
                return v

    def varint(self):
        v = self.varuint()
        return (v >> 1) ^ -(v & 1)

    def varuint64(self):
        v = 0
        shift = 0
        while True:
            b = self.byte()
            v |= (b & 127) << shift
            shift += 7
            if not (b & 128) or shift >= 63:
                return v

    def varint64(self):
        v = self.varuint64()
        return (v >> 1) ^ -(v & 1)

    def float(self):
        if self.d[self.i] == 0:
            self.i += 1
            return 0.0
        bits = struct.unpack_from('<I', self.d, self.i)[0]
        self.i += 4
        # kiwi rotates the exponent to the end on write; undo it
        bits = ((bits << 23) | (bits >> 9)) & 0xFFFFFFFF
        return struct.unpack('<f', struct.pack('<I', bits))[0]

    def string(self):
        end = self.d.index(0, self.i)
        s = self.d[self.i:end].decode('utf-8', 'replace')
        self.i = end + 1
        return s


def parse_schema(data):
    bb = BB(data)
    defs = []
    for _ in range(bb.varuint()):
        name = bb.string()
        kind = KINDS[bb.byte()]
        fields = []
        for _ in range(bb.varuint()):
            fname = bb.string()
            ftype = bb.varint()
            is_array = bool(bb.byte() & 1)
            value = bb.varuint()
            fields.append({'name': fname, 'type': None if kind == 'ENUM' else ftype,
                           'array': is_array, 'value': value})
        defs.append({'name': name, 'kind': kind, 'fields': fields})
    return defs


class Schema:
    def __init__(self, defs):
        self.defs = defs
        self.by_name = {d['name']: i for i, d in enumerate(defs)}

    def read_value(self, bb, t):
        if t < 0:
            p = PRIM[t]
            if p == 'bool':
                return bb.byte() != 0
            if p == 'byte':
                return bb.byte()
            if p == 'int':
                return bb.varint()
            if p == 'uint':
                return bb.varuint()
            if p == 'float':
                return bb.float()
            if p == 'string':
                return bb.string()
            if p == 'int64':
                return bb.varint64()
            if p == 'uint64':
                return bb.varuint64()
            raise ValueError(p)
        return self.read_def(bb, t)

    def read_def(self, bb, idx):
        d = self.defs[idx]
        kind = d['kind']
        if kind == 'ENUM':
            v = bb.varuint()
            for f in d['fields']:
                if f['value'] == v:
                    return f['name']
            return v
        out = {}
        if kind == 'STRUCT':
            for f in d['fields']:
                out[f['name']] = self.read_field(bb, f)
            return out
        while True:
            fid = bb.varuint()
            if fid == 0:
                return out
            f = next((x for x in d['fields'] if x['value'] == fid), None)
            if f is None:
                raise ValueError('unknown field id %d in %s' % (fid, d['name']))
            out[f['name']] = self.read_field(bb, f)

    def read_field(self, bb, f):
        if f['array']:
            return [self.read_value(bb, f['type']) for _ in range(bb.varuint())]
        return self.read_value(bb, f['type'])


def load(path):
    d = open(path, 'rb').read()
    assert d[:8] == b'fig-kiwi', d[:8]
    off = 12
    n = struct.unpack_from('<I', d, off)[0]; off += 4
    schema_raw = zlib.decompressobj(-15).decompress(d[off:off + n]); off += n
    n2 = struct.unpack_from('<I', d, off)[0]; off += 4
    blob = d[off:off + n2]
    if blob[:4] == b'\x28\xb5\x2f\xfd':
        payload = zstandard.ZstdDecompressor().decompress(blob, max_output_size=512 * 1024 * 1024)
    else:
        payload = zlib.decompressobj(-15).decompress(blob)
    schema = Schema(parse_schema(schema_raw))
    root = schema.by_name.get('Message', 0)
    return schema, schema.read_def(BB(payload), root)
