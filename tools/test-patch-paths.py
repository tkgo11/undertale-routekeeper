#!/usr/bin/env python3
"""Pinned authentic CLI path regressions with a genuine positive compile control."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PIN = 'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'

def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def invoke(cli, arguments, log, original=None):
    environment = dict(os.environ)
    if original is not None:
        environment['ROUTEKEEPER_ORIGINAL'] = str(original)
    with log.open('xb') as output:
        result = subprocess.run([cli, *arguments], cwd=ROOT, stdout=output,
                                stderr=subprocess.STDOUT, timeout=300, env=environment)
    if log.stat().st_size > 2 * 1024 * 1024:
        raise RuntimeError('Compiler diagnostics exceeded private review budget')
    return result.returncode, log.read_text(encoding='utf-8', errors='replace')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', required=True, type=Path)
    parser.add_argument('--cli', required=True)
    parser.add_argument('--case', choices=['all', 'scratch-file'], default='all')
    args = parser.parse_args()
    if digest(args.input) != PIN:
        raise ValueError('Uninspected input')
    private = ROOT / '.research'; private.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix='patch-path-audit-', dir=private))
    # Failures retain private compiler evidence; no diagnostics/source are echoed.
    control = work/'control'; control.mkdir()
    pristine = control/'original.win'; shutil.copyfile(args.input, pristine)
    candidate = control/'candidate.win'
    code, _ = invoke(args.cli, ['load', str(pristine), '-s', str(ROOT/'integration/patch.csx'), '-o', str(candidate)], control/'compile.log')
    profiles = json.loads((ROOT/'profiles/registry.json').read_text(encoding='utf-8'))
    matching = [p for p in profiles if p['OriginalSha256'] == PIN]
    if code != 0 or len(matching) != 1 or not candidate.is_file() or digest(candidate) != matching[0]['PatchedSha256']:
        raise RuntimeError('FAIL positive compile control; private evidence retained below .research')
    code, _ = invoke(args.cli, ['load', str(candidate), '-s', str(ROOT/'integration/verify.csx')], control/'verify.log', pristine)
    if code != 0 or digest(pristine) != PIN or digest(args.input) != PIN:
        raise RuntimeError('FAIL positive reload/preservation control; private evidence retained below .research')
    print('PASS genuine compile/reload/preservation control before negative path checks')
    cases = ['scratch-file'] if args.case == 'scratch-file' else ['scratch-file', 'scratch-link', 'dangling-output']
    for kind in cases:
        folder = work/kind; folder.mkdir()
        source = folder/'original.win'; shutil.copyfile(args.input, source)
        output = folder/'candidate.win'; scratch = Path(str(output)+'temp')
        if kind == 'scratch-file':
            scratch.write_bytes(b'PREEXISTING PRIVATE EVIDENCE')
            markers = ('Compiler scratch output must be new; existing evidence is retained.',)
        else:
            markers = ('Symbolic links are not accepted for patch generation paths.',)
            if kind == 'dangling-output':
                markers += ('Output must be a new file distinct from the pristine original.',)
            try:
                if kind == 'scratch-link': scratch.symlink_to(source)
                else: output.symlink_to(folder/'missing-target')
            except OSError:
                print('NOT_RUN native symlink privilege unavailable:', kind)
                continue
        code, diagnostic = invoke(args.cli, ['load', str(source), '-s', str(ROOT/'integration/patch.csx'), '-o', str(output)], folder/'cli.log')
        if code == 0 or not any(marker in diagnostic for marker in markers) or digest(source) != PIN or digest(args.input) != PIN:
            raise RuntimeError('FAIL missing intended path refusal or input changed; private evidence retained: '+kind)
        if kind == 'scratch-file' and scratch.read_bytes() != b'PREEXISTING PRIVATE EVIDENCE':
            raise RuntimeError('FAIL preexisting CLI scratch evidence was overwritten')
        if kind == 'scratch-link' and not scratch.is_symlink():
            raise RuntimeError('FAIL linked CLI scratch was replaced')
        if kind == 'dangling-output' and not output.is_symlink():
            raise RuntimeError('FAIL dangling output was replaced')
        if kind != 'dangling-output' and output.exists():
            raise RuntimeError('FAIL rejected path produced a candidate')
        print('PASS source-identified refusal before CLI output publication:', kind)
    shutil.rmtree(work)  # Only this successful disposable compiler fixture.
    print('PASS authentic path refusals; pristine input unchanged; gameplay NOT_RUN')

if __name__ == '__main__':
    main()
