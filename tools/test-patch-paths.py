#!/usr/bin/env python3
"""Pinned authentic CLI path regressions on disposable copies; never launch a game."""
import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PIN = 'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'

def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', required=True, type=Path)
    parser.add_argument('--cli', required=True)
    parser.add_argument('--case', choices=['all', 'scratch-file'], default='all')
    args = parser.parse_args()
    if digest(args.input) != PIN:
        raise ValueError('Uninspected input')
    private = ROOT / '.research'; private.mkdir(exist_ok=True)
    cases = ['scratch-file'] if args.case == 'scratch-file' else ['scratch-file', 'scratch-link', 'dangling-output']
    with tempfile.TemporaryDirectory(prefix='patch-path-audit-', dir=private) as tmp:
        for kind in cases:
            folder = Path(tmp) / kind; folder.mkdir()
            source = folder / 'original.win'; shutil.copyfile(args.input, source)
            output = folder / 'candidate.win'; scratch = Path(str(output) + 'temp')
            if kind == 'scratch-file':
                scratch.write_bytes(b'PREEXISTING PRIVATE EVIDENCE')
            else:
                try:
                    if kind == 'scratch-link': scratch.symlink_to(source)
                    else: output.symlink_to(folder / 'missing-target')
                except OSError:
                    print('NOT_RUN native symlink privilege unavailable:', kind)
                    continue
            with (folder / 'cli.log').open('x') as log:
                result = subprocess.run([args.cli, 'load', str(source), '-s', str(ROOT / 'integration/patch.csx'), '-o', str(output)],
                                        cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=300)
            if result.returncode == 0 or digest(source) != PIN or digest(args.input) != PIN:
                raise RuntimeError('FAIL unsafe output accepted or disposable/pristine input changed: ' + kind)
            if kind == 'scratch-file' and scratch.read_bytes() != b'PREEXISTING PRIVATE EVIDENCE':
                raise RuntimeError('FAIL preexisting CLI scratch evidence was overwritten')
            if kind == 'scratch-link' and not scratch.is_symlink():
                raise RuntimeError('FAIL linked CLI scratch was replaced')
            if kind == 'dangling-output' and not output.is_symlink():
                raise RuntimeError('FAIL dangling output was replaced')
            print('PASS refusal before CLI output publication:', kind)
    print('PASS authentic path refusals; pristine input unchanged; gameplay NOT_RUN')

if __name__ == '__main__':
    main()
