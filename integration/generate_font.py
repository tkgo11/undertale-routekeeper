#!/usr/bin/env python3
"""Build the small embedded UI atlas from an OFL-licensed Noto CJK font.
Development only; the game has no Python or external font dependency.
"""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw, ImageFont

parser = argparse.ArgumentParser()
parser.add_argument('--font', default='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc')
args = parser.parse_args()
root = Path(__file__).resolve().parent
text = ''.join(p.read_text() for p in (root / 'gml').glob('*.gml'))
chars = sorted(set(chr(i) for i in range(32, 127)) | {c for c in text if '\uac00' <= c <= '\ud7a3'})
font = ImageFont.truetype(args.font, 16, index=1)
cell, columns = 24, 32
image = Image.new('RGBA', (768, 192), (255, 255, 255, 0))
draw = ImageDraw.Draw(image)
rows = []
for n, char in enumerate(chars):
    x, y = n % columns * cell, n // columns * cell
    if y + cell > image.height:
        raise RuntimeError('Atlas overflow')
    draw.text((x, y), char, font=font, fill=(255,255,255,255), anchor='lt', stroke_width=0)
    rows.append(f'{ord(char)}\t{x}\t{y}\t{round(font.getlength(char))}')
image.save(root / 'assets' / 'ui-font.png')
(root / 'assets' / 'ui-font.tsv').write_text('\n'.join(rows) + '\n')
print(f'Generated {len(chars)} glyphs in {image.width}x{image.height} atlas')
