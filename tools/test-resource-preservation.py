#!/usr/bin/env python3
"""Mutation-test authentic metadata guards in memory; no game or asset publication."""
import argparse
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input', required=True, type=Path)
    p.add_argument('--candidate', required=True, type=Path)
    p.add_argument('--cli', required=True)
    p.add_argument('--case', choices=['all', 'sound'], default='all')
    a = p.parse_args()
    original_hash = digest(a.input)
    candidate_hash = digest(a.candidate)
    if original_hash != 'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7':
        raise ValueError('Uninspected input')
    cases = {'sound': ('Data.Sounds[0].Volume += 0.125f;', 'original sound metadata'),
             'room': ('Data.Rooms[0].Width ^= 1u;', 'original room metadata'),
             'object': ('Data.GameObjects[0].Solid = !Data.GameObjects[0].Solid;', 'original object metadata'),
             'font': ('Data.Fonts[0].AntiAliasing = (byte)(Data.Fonts[0].AntiAliasing ^ 1);', 'original font metadata'),
             'kerning': ('Data.Fonts[0].Glyphs[0].Kerning.Add(new UndertaleModLib.Models.UndertaleFont.Glyph.GlyphKerning { Character=32, ShiftModifier=1 });', 'Original font glyph changed'),
             'sprite': ('Data.Sprites[0].Width ^= 1u;', 'original sprite metadata'),
             'texture': ('Data.TexturePageItems[0].TargetWidth = (ushort)(Data.TexturePageItems[0].TargetWidth ^ 1);', 'original texture-page metadata')}
    with tempfile.TemporaryDirectory(prefix='resource-mutation-', dir=ROOT / '.research') as tmp:
        folder = Path(tmp)
        env = dict(os.environ, ROUTEKEEPER_ORIGINAL=str(a.input.resolve()))
        with (folder / 'positive-control.log').open('x') as log:
            positive = subprocess.run([a.cli, 'load', str(a.candidate.resolve()), '-s', str(ROOT / 'integration/verify.csx')],
                                      cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=300)
        if positive.returncode != 0:
            raise RuntimeError('Unmodified candidate failed the positive preservation control')
        print('PASS unmodified candidate positive preservation control')
        for kind in (cases if a.case == 'all' else [a.case]):
            code, marker = cases[kind]
            mutator = folder / (kind + '.csx'); mutator.write_text('EnsureDataLoaded();\n' + code + '\n', encoding='utf-8', newline='\n')
            log_path = folder / (kind + '.log')
            with log_path.open('x') as log:
                result = subprocess.run([a.cli, 'load', str(a.candidate.resolve()), '-s', str(mutator), '-s', str(ROOT / 'integration/verify.csx')],
                                        cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=300)
            if result.returncode == 0 or marker not in log_path.read_text(encoding='utf-8'):
                raise RuntimeError('FAIL resource metadata corruption was not specifically rejected: ' + kind)
            if digest(a.input) != original_hash or digest(a.candidate) != candidate_hash:
                raise RuntimeError('Input/candidate changed during read-only metadata test')
            print('PASS independent in-memory corruption refused:', kind)
    print('PASS authentic metadata mutation guards; no runner or asset write')


if __name__ == '__main__':
    main()
