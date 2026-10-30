#!/usr/bin/env python3
"""Deterministic binary-alpha bitmap atlas. No host fonts, Pillow or rasterizer needed."""
from pathlib import Path
import argparse
import gzip
import hashlib
import io
import json
import math
import os
import stat
import struct
import tempfile
import zlib
from functools import lru_cache
ROOT = Path(__file__).resolve().parent
FONT_METADATA_PATH = ROOT.parent / 'locales/fonts.json'

def valid_glyph_metadata(code, advance, width, height, dx, dy, seen):
    """Preserve exact BDF metadata limits with auditable, independent checks."""
    if code in seen:
        return False
    if not 0 <= code <= 65535:
        return False
    if not 0 <= advance <= 64:
        return False
    if not 0 <= width <= 64:
        return False
    if not 0 <= height <= 64:
        return False
    if abs(dx) > 64 or abs(dy) > 64:
        return False
    return True


@lru_cache(maxsize=32)
def glyph_source(font_id="galmuri14"):
    meta = json.loads((FONT_METADATA_PATH).read_text(encoding='utf-8'))[font_id]
    source=ROOT.parent/meta['source']
    if source.stat().st_size > 16 * 1024 * 1024:
        raise ValueError('Compressed bitmap source exceeds 16MiB')
    with gzip.GzipFile(fileobj=io.BytesIO(source.read_bytes())) as stream:
        raw = stream.read(16 * 1024 * 1024 + 1)
    if len(raw) > 16 * 1024 * 1024:
        raise ValueError('Bitmap source exceeds 16MiB')
    if hashlib.sha256(raw).hexdigest() != meta['sha256']:
        raise ValueError('Pinned bitmap source checksum mismatch')
    result = {}
    for block in raw.decode().split('STARTCHAR ')[1:]:
        lines = block.splitlines(); fields = {s.split()[0]: s.split()[1:] for s in lines if s.split()}
        code = int(fields['ENCODING'][0]); advance = int(fields['DWIDTH'][0])
        w,h,dx,dy = map(int, fields['BBX']); start = lines.index('BITMAP')+1
        if code==-1:continue
        if not valid_glyph_metadata(code, advance, w, h, dx, dy, result):
            raise ValueError('Unsupported bitmap source glyph metadata')
        pixels = []
        for y, row in enumerate(lines[start:start+h]):
            if len(row)>16 or len(row)*4<w:raise ValueError('Malformed bitmap row')
            bits = int(row,16); bits_width = len(row)*4
            for x in range(w):
                if bits & (1 << (bits_width-1-x)): pixels.append((x+dx, meta['baseline']-dy-h+y))
        offset = min([0]+[x for x,y in pixels])
        result[code] = (advance,[(x-offset,y) for x,y in pixels],offset)
    return result

def locale_registry():
    return [language for language in json.loads((ROOT.parent/'locales/languages.json').read_text(encoding='utf-8'))['languages'] if language['enabled']]

@lru_cache(maxsize=128)
def native_advance(code):
    return json.loads((ROOT/'ui/english-metrics.json').read_text(encoding='utf-8'))['metrics'][str(code)]['advance']

def required_chars(font_id="galmuri14"):
    text = ''
    for locale in locale_registry():
        if locale['font'] == font_id:
            text += locale['name'] + ''.join(json.loads((ROOT.parent/'locales'/ (locale['tag']+'.json')).read_text(encoding='utf-8')).values())
    codes=sorted(set(range(32,127)) | {ord(c) for c in text if c.isprintable()})
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

def generate(font_id="galmuri14"):
    glyphs=glyph_source(font_id); codes=required_chars(font_id); cell=24; width=768
    line_height=json.loads((FONT_METADATA_PATH).read_text(encoding='utf-8'))[font_id]['lineHeight']
    height=1 << max(7,(math.ceil(len(codes)/32)*cell-1).bit_length())
    if height>2048: raise ValueError("Atlas exceeds verified 2048px bound; split-font support is unverified")
    pixels=bytearray(width*height); rows=[]
    for n,code in enumerate(codes):
        if code not in glyphs: raise ValueError(f'Missing source U+{code:04X}')
        advance,ink,offset=glyphs[code]; x=n%32*cell; y=n//32*cell
        if not 0<=advance<=24: raise ValueError('Invalid advance')
        for dx,dy in ink:
            if not (0<=dx<24 and 0<=dy<line_height): raise ValueError(f'Clipped glyph U+{code:04X}: {dx},{dy}')
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

def publish(path,data,verify=False):
    # Best-effort ancestor revalidation; not hostile concurrent-path protection.
    for component in (path,*path.parents):
        if component.is_symlink() or (component.exists() and getattr(component.lstat(),'st_file_attributes',0)&stat.FILE_ATTRIBUTE_REPARSE_POINT):
            raise ValueError('Linked generated output refused: '+str(path))
    if verify:
        if not path.exists() or path.read_bytes()!=data:raise ValueError('Stale generated asset '+str(path))
        return
    path.parent.mkdir(parents=True,exist_ok=True)
    fd,name=tempfile.mkstemp(prefix='.rk-generation-',dir=path.parent)
    try:
        with os.fdopen(fd,'wb') as stream:
            stream.write(data);stream.flush();os.fsync(stream.fileno())
        os.replace(name,path)
    finally:
        if os.path.exists(name):os.unlink(name)

def build_fonts(verify=False):
    metadata=json.loads((FONT_METADATA_PATH).read_text(encoding='utf-8'))
    used=sorted({l['font'] for l in locale_registry() if metadata[l['font']]['kind']!='native'})
    manifest=[]; outputs={}
    for font_id in used:
        files,count=generate(font_id)
        folder='fonts/'+font_id+'/'
        for name,data in files.items():outputs[folder+name]=data
        entry=dict(id=font_id,**metadata[font_id],glyphCount=count,atlas=folder+'ui-font.png',glyphs=folder+'ui-font.tsv')
        manifest.append(entry)
        # Legacy deterministic inspection interface; injection uses the manifest.
        if font_id=='galmuri14':outputs.update(files)
    outputs['fonts/manifest.json']=(json.dumps(manifest,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode('utf-8')
    for name,data in outputs.items():
        path=ROOT/'assets'/name
        publish(path,data,verify)
    return len(manifest)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--verify',action='store_true');args=parser.parse_args()
    count=build_fonts(args.verify)
    print(f'PASS: {count} registered bitmap fonts; deterministic assets '+('verified' if args.verify else 'generated'))
