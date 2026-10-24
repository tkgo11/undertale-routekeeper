#!/usr/bin/env python3
"""Compile and reload privately supplied game data without uploading game assets.

This is structural integration testing, never a gameplay compatibility claim.
Requires the exact authentic input and separately installed UndertaleModCli 0.9.2.0.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

ORIGINAL_SHA256 = 'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'
ROOT = Path(__file__).resolve().parents[1]

def digest(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True)
    parser.add_argument('--cli', required=True)
    parser.add_argument('--builder', type=Path, help='Exercise the independent .NET builder DLL')
    parser.add_argument('--work', type=Path, default=ROOT / '.research' / 'validation')
    args = parser.parse_args()
    original = args.input.resolve(strict=True)
    if digest(original) != ORIGINAL_SHA256:
        raise SystemExit('FAIL: input hash is not the inspected authentic build')
    version = subprocess.run([args.cli, '--version'], text=True, capture_output=True, check=True).stdout.strip()
    if not version.startswith('0.9.2.0'):
        raise SystemExit('FAIL: UndertaleModCli version differs from pinned API')
    args.work.mkdir(parents=True, exist_ok=True)
    # The work directory must be ignored; no ordinary CI artifact includes it.
    report = {'kind': 'STRUCTURAL_ONLY', 'runtime': 'NOT_RUN', 'cliVersion': version, 'checks': []}
    with tempfile.TemporaryDirectory(prefix='authentic-', dir=args.work.resolve()) as temporary:
        stage = Path(temporary)
        output = stage / 'routekeeper-data.win'
        environment = dict(os.environ, ROUTEKEEPER_ORIGINAL=str(original))
        def invoke(label: str, parameters: list[str], success: bool = True, command: list[str] | None = None) -> None:
            result = subprocess.run(command if command is not None else [args.cli, *parameters], cwd=ROOT, env=environment, capture_output=True, text=True)
            (args.work / (label + '.log')).write_text(result.stdout + result.stderr, encoding='utf-8')
            if (result.returncode == 0) != success:
                # Do not print potentially proprietary compiler/decompiler diagnostics to CI.
                raise RuntimeError(f'{label}: unexpected CLI exit {result.returncode}; inspect private work logs')
            if digest(original) != ORIGINAL_SHA256:
                raise RuntimeError('Original data changed during validation')
            report['checks'].append({'name': label, 'result': 'PASS'})
            print('PASS:', label)
        if args.builder:
            invoke('standalone-build-serialize-and-verify', [], command=['dotnet', str(args.builder.resolve(strict=True)), 'build', str(original), str(output), args.cli, str(ROOT)])
        else:
            invoke('compile-and-serialize', ['load', str(original), '-s', 'integration/patch.csx', '-o', str(output)])
        if not output.is_file():
            raise RuntimeError('Compiler did not produce output')
        if not args.builder:
            invoke('reload-and-original-code-preservation', ['load', str(output), '-s', 'integration/verify.csx'])
        rejected = stage / 'rejected.win'
        invoke('modified-input-rejection', ['load', str(output), '-s', 'integration/patch.csx', '-o', str(rejected)], False)
        if rejected.exists():
            raise RuntimeError('Rejected input still produced output')
        # Use a disposable pristine copy to test overwrite refusal independently.
        copied_original = stage / 'pristine.win'
        copied_original.write_bytes(original.read_bytes())
        invoke('original-overwrite-rejection', ['load', str(copied_original), '-s', 'integration/patch.csx', '-o', str(copied_original), '-f'], False)
        if digest(copied_original) != ORIGINAL_SHA256:
            raise RuntimeError('Overwrite refusal failed')
        report['outputSha256'] = digest(output)
        report['originalUnchanged'] = True
    (args.work / 'summary.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print('PASS: output SHA-256', report['outputSha256'])
    print('PASS: authentic structural validation; gameplay NOT_RUN')

if __name__ == '__main__':
    main()
