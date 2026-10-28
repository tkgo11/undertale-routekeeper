#!/usr/bin/env python3
"""Repeat eligible offline/native non-game checks and retain every exit code privately.

This entry never launches the official game, changes Steam, or reads personal saves.
Private authentic compilation is reported separately and requires its pinned inputs.
"""
import argparse
from datetime import datetime, timezone
import html
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import uuid

import runtime_lab

ROOT = Path(__file__).resolve().parents[1]
MAX_LOG_BYTES = 32 * 1024 * 1024
COMMAND_TIMEOUT = 900


def commands(skip_desktop=False, private_output=None):
    py = sys.executable
    result = [('build', ['dotnet', 'build', 'RouteKeeper.slnx', '-c', 'Release'])]
    for name in ('Core', 'Tool', 'Saves', 'Neutral', 'Decisions', 'History', 'Audit'):
        result.append(('csharp-' + name, ['dotnet', 'run', '--project',
                       'tests/RouteKeeper.' + name + '.Tests', '-c', 'Release', '--no-build']))
    for name, option, target in (
        ('Core', '--verify-gml', 'integration/gml/route_evaluate.gml'),
        ('Neutral', '--verify-gml', 'integration/gml'),
        ('Decisions', '--verify-adapters', 'integration/gml'),
        ('Decisions', '--verify-ui', 'integration')):
        result.append((name + option, ['dotnet', 'run', '--project',
                       'tests/RouteKeeper.' + name + '.Tests', '-c', 'Release', '--no-build',
                       '--', option, target]))
    tests = ['tools/test_windows_e2e.py', 'tools/test_native_gameplay.py',
             'tools/test_screen_verify.py', 'tools/test_runtime_lab.py',
             'tools/test_localization.py', 'tools/test_private_validation.py',
             'tools/test_audit_inventory.py', 'tools/test_workflow_safety.py',
             'tools/test_source_encoding.py', 'integration/ui/test_ui.py']
    # All maintained new unit suites are explicit, never discovered from private data.
    for optional in ('tools/test_native_bootstrap.py', 'tools/runtime/test-watchdog.py',
                     'tools/test_native_capture_contract.py', 'tools/test_save_observer.py',
                     'tools/test_audit_source_order.py', 'tools/test_windows_test_suite.py'):
        if (ROOT / optional).is_file():
            tests.append(optional)
    result.extend((Path(path).stem, [py, path]) for path in tests)
    for path in ('tools/localization.py', 'integration/ui/generate.py', 'integration/generate_font.py'):
        result.append((Path(path).stem + '-verify', [py, path, *(['build'] if 'localization' in path else []), '--verify']))
    result.extend([('pyflakes', [py, '-m', 'pyflakes', 'integration', 'tools']),
                   ('audit-inventory', [py, 'tools/audit_inventory.py'])])
    for shell in ('pwsh', 'powershell'):
        for script in ('test-current-account', 'test-native-filesystem', 'test-e2e', 'test-sandbox', 'test-workspace-cleanup', 'test-addtype-temp', 'test-watchdog'):
            path = 'tools/runtime/' + script + '.ps1'
            if (ROOT / path).is_file():
                result.append((shell + '-' + script, [shell, '-NoProfile', '-File', path]))
    for mode in ('Check', 'DryRun', *(() if skip_desktop else ('NativeTest',))):
        result.append(('windows-' + mode, ['pwsh', '-NoProfile', '-File',
                       'tools/runtime/test-windows.ps1', '-Mode', mode]))
    if not skip_desktop:
        result.append(('windows-NativeTest-PS51', ['powershell', '-NoProfile', '-File',
                       'tools/runtime/test-windows.ps1', '-Mode', 'NativeTest']))
    xdelta = ROOT / '.research/xdelta/xdelta3-3.2.2-windows-x86_64/xdelta3.exe'
    if xdelta.is_file():
        result.append(('g3m-roundtrip', [py, 'tools/test-g3m.py', '--tool',
                       str(ROOT / 'src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll'),
                       '--xdelta', str(xdelta)]))
    for rid in ('win-x64', 'linux-x64', 'osx-x64', 'osx-arm64'):
        if private_output:
            result.append(('publish-' + rid, ['dotnet', 'publish', 'src/RouteKeeper.Tool', '-c',
                           'Release', '-r', rid, '--self-contained', 'true', '-p:PublishSingleFile=true',
                           '-o', str(private_output / 'publish' / rid)]))
    cli = ROOT / '.research/utmt-windows/UndertaleModCli.exe'
    data = ROOT / 'private-data/data.win'
    if cli.is_file() and data.is_file() and private_output:
        result.append(('private-authentic', [py, 'tools/validate-authentic.py', '--input', str(data),
                       '--cli', str(cli), '--builder',
                       'src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll',
                       '--work', str(private_output / 'authentic')]))
        result.append(('private-original-hooks', [str(cli), 'load', str(data), '-s', 'tools/audit-hooks.csx']))
        for tool in ('test-patch-paths.py', 'test-preview-export.py'):
            result.append(('private-' + tool[:-3], [py, 'tools/' + tool, '--input', str(data), '--cli', str(cli)]))
        if (ROOT / '.research/all-code').is_dir():
            result.append(('private-original-golden', [py, 'tools/audit-endings.py', '--source',
                           '.research/all-code', '--output', 'tests/golden/original-endings.json', '--verify']))
        archive = ROOT / 'private-data/runtime-windows/runtime.zip'
        if archive.is_file():
            result.append(('private-prepare', [py, 'tools/windows_e2e.py', 'prepare', '--archive', str(archive),
                           '--output', str(private_output / 'prepared'), '--cli', str(cli), '--builder',
                           'src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll']))
            result.append(('private-verify-prepared', [py, 'tools/windows_e2e.py', 'verify-prepared',
                           '--work', str(private_output / 'prepared')]))
    return result


def run_one(name, command, output, environment):
    started = time.monotonic()
    log = output / (name + '.log')
    error = None
    code = None
    child_environment = dict(environment)
    shell = str(command[0]).replace('\\', '/').rsplit('/', 1)[-1].casefold()
    isolated_shell = shell in ('powershell', 'powershell.exe', 'pwsh', 'pwsh.exe')
    if isolated_shell:
        # PS7 -> Python -> PS5.1 bypasses PowerShell's native-child path repair.
        # Let each child rebuild its version's default module paths instead of
        # loading another edition's Security/Utility assemblies. Never mutate
        # the controller environment or machine/user settings.
        child_environment = {key: value for key, value in child_environment.items()
                             if key.casefold() != 'psmodulepath'}
    with log.open('xb') as stream:
        try:
            process = subprocess.Popen(command, cwd=ROOT, env=child_environment,
                                       stdout=stream, stderr=subprocess.STDOUT)
            try:
                while process.poll() is None:
                    if time.monotonic() - started > COMMAND_TIMEOUT or log.stat().st_size > MAX_LOG_BYTES:
                        error = 'Owned test exceeded time/output budget; terminated; evidence retained'
                        process.kill()
                        break
                    time.sleep(.1)
                code = process.wait(timeout=15)
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=15)
        except (OSError, subprocess.SubprocessError) as exc:
            error = str(exc)
    if log.stat().st_size > MAX_LOG_BYTES:
        error = 'Owned test exceeded output budget; private log retained'
    with log.open('rb') as stream:
        raw = stream.read(MAX_LOG_BYTES).decode('utf-8', errors='replace')
    totals = [int(value) for value in re.findall(r'Ran (\d+) tests? in ', raw)]
    skipped = sum(int(value) for value in re.findall(r'skipped=(\d+)', raw))
    blocked = code != 0 and re.search(r'"result"\s*:\s*"BLOCKED"', raw)
    return dict(name=name, command=command, exitCode=code,
                result='PASS' if code == 0 and not error else ('BLOCKED' if blocked else 'FAIL'),
                seconds=round(time.monotonic() - started, 2), log=str(log),
                unittestCases=sum(totals), skipped=skipped, error=error,
                shellModulePath='REBUILT_BY_CHILD' if isolated_shell else 'INHERITED',
                descendantClosure='UNVERIFIED_ON_TIMEOUT' if error else 'NOT_ASSERTED')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--skip-desktop', action='store_true')
    args = parser.parse_args()
    base = ROOT / '.research/windows-suite'
    output = runtime_lab.assert_no_links(args.output or base / uuid.uuid4().hex)
    if not output.is_relative_to(ROOT / '.research'):
        parser.error('Suite output must remain under ignored repository .research')
    output.mkdir(parents=True, exist_ok=False)
    env = dict(os.environ, ROUTEKEEPER_LOCALE_E2E='1')
    # Tests using assertions must not inherit an optimization bypass. Individual
    # negative tests still explicitly create optimized children where required.
    env.pop('PYTHONOPTIMIZE', None)
    original = ROOT / 'private-data/data.win'
    compiler = ROOT / '.research/utmt-windows/UndertaleModCli.exe'
    if original.is_file() and compiler.is_file():
        env['ROUTEKEEPER_LOCALE_AUTHENTIC'] = str(original)
        env['ROUTEKEEPER_LOCALE_CLI'] = str(compiler)
    results = []
    for name, command in commands(args.skip_desktop, output):
        print('RUN ' + name, flush=True)
        depends_on_build = command[0] == 'dotnet' and name != 'build' or name in ('g3m-roundtrip', 'private-authentic', 'private-prepare')
        failed_preparation = name == 'private-verify-prepared' and results[-1]['result'] != 'PASS'
        if depends_on_build and results[0]['result'] != 'PASS' or failed_preparation:
            item = dict(name=name, command=command, exitCode=None, result='BLOCKED', seconds=0,
                        log=None, unittestCases=0, skipped=0,
                        error=('Private preparation failed; no seal verification attempted' if failed_preparation else
                               'Fresh Release build failed; stale binaries were not executed'))
        else:
            item = run_one(name, command, output, env)
        results.append(item)
        print(item['result'] + ' ' + name + ' exit=' + str(item['exitCode']), flush=True)
        (output / 'commands.json').write_text(json.dumps(results, indent=2) + '\n', encoding='utf-8', newline='\n')
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode('ascii').strip()
    dirty = subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT).decode('utf-8')
    counts = {key: sum(item['result'] == key for item in results) for key in ('PASS', 'FAIL', 'BLOCKED')}
    report = dict(schema=1, createdUtc=datetime.now(timezone.utc).isoformat(), repositoryHead=head,
                  trackedWorktreeStatus=dirty, python=sys.version, interpreter=sys.executable,
                  counts=counts, commands=results, desktopOmitted=args.skip_desktop,
                  nativeGameplay='NOT_RUN', steamAccountState='UNVERIFIED',
                  personalSaves='NOT_TOUCHED', qualification='Command totals are not gameplay assertions; skipped cases remain skipped.')
    (output / 'report.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8', newline='\n')
    rows = ''.join('<tr><td>' + html.escape(item['name']) + '</td><td>' + item['result'] +
                   '</td><td>' + str(item['exitCode']) + '</td><td><code>' +
                   html.escape(subprocess.list2cmdline(item['command'])) + '</code></td><td><a href="' +
                   html.escape(Path(item['log']).name if item['log'] else '#') + '">log</a></td></tr>' for item in results)
    page = '<!doctype html><html lang="en"><meta charset="utf-8"><title>Windows non-game suite</title>'
    page += '<style>body{font:16px system-ui;margin:2rem}td,th{padding:.5rem;text-align:left;border-bottom:1px solid #ccc}code{font-size:12px}</style>'
    page += '<h1>Windows non-game suite</h1><p>HEAD ' + head + '</p><p>' + html.escape(str(counts)) + '</p>'
    page += '<p>Actual game NOT_RUN. Personal saves NOT_TOUCHED. Steam account state UNVERIFIED.</p>'
    page += '<table><tr><th>Check<th>Result<th>Exit<th>Command<th>Evidence</tr>' + rows + '</table></html>'
    (output / 'report.html').write_text(page, encoding='utf-8', newline='\n')
    print('PRIVATE_REPORT ' + str(output / 'report.json'))
    return 1 if counts['FAIL'] or counts['BLOCKED'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
