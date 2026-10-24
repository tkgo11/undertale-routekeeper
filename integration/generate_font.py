#!/usr/bin/env python3
"""Generate or verify the embedded, OFL-licensed native UI font atlas.

Verification needs only Python's standard library. Generation additionally needs
Pillow and a legitimate local Noto Sans CJK font. The game needs neither.
"""
from pathlib import Path
import argparse
import math
import struct

parser = argparse.ArgumentParser()
parser.add_argument('--font', default='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc')
parser.add_argument('--verify', action='store_true', help='Check committed glyph coverage and bounds without Pillow')
args = parser.parse_args()
root = Path(__file__).resolve().parent
text = ''.join(path.read_text(encoding='utf-8') for path in sorted((root / 'gml').glob('*.gml')))
chars = sorted(set(chr(i) for i in range(32, 127)) | {c for c in text if ord(c) > 126 and c.isprintable()})
if any(ord(c) > 65535 for c in chars):
    raise SystemExit('GameMaker Studio 1 glyph metadata requires BMP code points')

if args.verify:
    png = (root / 'assets' / 'ui-font.png').read_bytes()
    if png[:8] != b'\x89PNG\r\n\x1a\n':
        raise SystemExit('Invalid PNG signature')
    width, height = struct.unpack('>II', png[16:24])
    rows = [tuple(map(int, row.split('\t'))) for row in (root / 'assets' / 'ui-font.tsv').read_text().splitlines()]
    glyphs = {row[0] for row in rows}
    missing = {ord(c) for c in chars} - glyphs
    if missing:
        raise SystemExit('Missing UI glyphs: ' + ','.join(f'U+{c:04X}' for c in sorted(missing)))
    if len(glyphs) != len(rows) or [r[0] for r in rows] != sorted(glyphs):
        raise SystemExit('Glyph codes must be unique and sorted')
    for code, x, y, advance in rows:
        if not (0 <= x <= width - 24 and 0 <= y <= height - 24 and 0 <= advance <= 24):
            raise SystemExit(f'Glyph U+{code:04X} exceeds atlas bounds or cell advance')
    print(f'PASS: {len(chars)} required characters covered by {len(rows)} glyphs; {width}x{height} atlas metadata valid')
    raise SystemExit(0)

from PIL import Image, ImageDraw, ImageFont

font = ImageFont.truetype(args.font, 16, index=1)
cell, columns = 24, 32
width = columns * cell
needed_height = math.ceil(len(chars) / columns) * cell
height = 1 << max(7, (needed_height - 1).bit_length())
image = Image.new('RGBA', (width, height), (255, 255, 255, 0))
draw = ImageDraw.Draw(image)
rows = []
for n, char in enumerate(chars):
    x, y = n % columns * cell, n // columns * cell
    draw.text((x, y), char, font=font, fill=(255, 255, 255, 255), anchor='lt', stroke_width=0)
    advance = round(font.getlength(char))
    if advance > cell:
        raise SystemExit(f'Glyph U+{ord(char):04X} exceeds cell width')
    rows.append(f'{ord(char)}\t{x}\t{y}\t{advance}')
image.save(root / 'assets' / 'ui-font.png')
(root / 'assets' / 'ui-font.tsv').write_text('\n'.join(rows) + '\n', encoding='utf-8')
(root / 'assets' / 'ui-font-size.txt').write_text(f'{width}\t{height}\n', encoding='ascii')
print(f'Generated {len(chars)} glyphs in {width}x{height} atlas')
