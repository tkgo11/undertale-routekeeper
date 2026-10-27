#!/usr/bin/env python3
"""Deterministic binary-alpha bitmap atlas. No host fonts, Pillow or rasterizer needed."""
from pathlib import Path
import argparse, gzip, hashlib, json, math, struct, zlib
from functools import lru_cache
ROOT = Path(__file__).resolve().parent

@lru_cache(maxsize=1)
def glyph_source():
    raw = gzip.decompress((ROOT / 'assets/font-source/routekeeper-korean.bdf.gz').read_bytes())
    meta = json.loads((ROOT / 'assets/font-source/provenance.json').read_text(encoding='utf-8'))
    if hashlib.sha256(raw).hexdigest() != meta['sha256']:
        raise ValueError('Pinned bitmap source checksum mismatch')
    result = {}
    for block in raw.decode().split('STARTCHAR ')[1:]:
        lines = block.splitlines(); fields = {s.split()[0]: s.split()[1:] for s in lines if s.split()}
        code = int(fields['ENCODING'][0]); advance = int(fields['DWIDTH'][0])
        w,h,dx,dy = map(int, fields['BBX']); start = lines.index('BITMAP')+1
        pixels = []
        for y, row in enumerate(lines[start:start+h]):
            bits = int(row,16); bits_width = len(row)*4
            for x in range(w):
                if bits & (1 << (bits_width-1-x)): pixels.append((x+dx, meta['baseline']-dy-h+y))
        offset = min([0]+[x for x,y in pixels])
        result[code] = (advance,[(x-offset,y) for x,y in pixels],offset)
    return result

def required_chars():
    text = ''.join(p.read_text(encoding='utf-8') for p in sorted((ROOT/'gml').glob('*.gml')))
    codes=sorted(set(range(32,127)) | {ord(c) for c in text if ord(c)>126 and c.isprintable()})
    if any(code>65535 for code in codes):raise ValueError('GameMaker1 font metadata requires BMP code points')
    return codes

def chunk(kind,data):
    return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)

def stored_deflate(data):
    """Canonical zlib stream, independent of host compression tuning/version."""
    compressed=bytearray(b'\x78\x01')
    for start in range(0,len(data),65535):
        block=data[start:start+65535];last=(start+len(block)==len(data))
        compressed+=bytes([int(last)])+struct.pack('<HH',len(block),65535-len(block))+block
    compressed+=struct.pack('>I',zlib.adler32(data)&0xffffffff)
    return bytes(compressed)

def generate():
    glyphs=glyph_source(); codes=required_chars(); cell=24; width=768
    height=1 << max(7,(math.ceil(len(codes)/32)*cell-1).bit_length())
    pixels=bytearray(width*height); rows=[]
    for n,code in enumerate(codes):
        if code not in glyphs: raise ValueError(f'Missing source U+{code:04X}')
        advance,ink,offset=glyphs[code]; x=n%32*cell; y=n//32*cell
        if not 0<=advance<=24: raise ValueError('Invalid advance')
        for dx,dy in ink:
            if not (0<=dx<24 and 0<=dy<18): raise ValueError(f'Clipped glyph U+{code:04X}: {dx},{dy}')
            pixels[(y+dy)*width+x+dx]=1
        rows.append(f'{code}\t{x}\t{y}\t{advance}\t{offset}')
    scan=bytearray()
    for y in range(height):
        scan.append(0)
        for x in range(0,width,8):
            scan.append(sum(pixels[y*width+x+i] << (7-i) for i in range(8)))
    # Canonical stored DEFLATE blocks avoid host zlib compression-version drift.
    compressed=stored_deflate(scan)
    png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,1,3,0,0,0))+chunk(b'PLTE',b'\0\0\0\xff\xff\xff')+chunk(b'tRNS',b'\0\xff')+chunk(b'IDAT',bytes(compressed))+chunk(b'IEND',b'')
    return {'ui-font.png':png,'ui-font.tsv':('\n'.join(rows)+'\n').encode(),'ui-font-size.txt':f'{width}\t{height}\n'.encode()},len(codes)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--verify',action='store_true');args=parser.parse_args()
    files,count=generate()
    for name,data in files.items():
        path=ROOT/'assets'/name
        if args.verify:
            if path.read_bytes()!=data: raise SystemExit('Stale deterministic font asset: '+name)
        else:path.write_bytes(data)
    print(f'PASS: {count} glyphs; binary alpha, baseline 14, 18px line; deterministic assets '+('verified' if args.verify else 'generated'))
