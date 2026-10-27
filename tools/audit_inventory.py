#!/usr/bin/env python3
"""Verify complete audit coverage; refresh only explicitly reviewed changed paths."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'docs/audit-coverage.json'


def tracked(root):
    return set(subprocess.check_output(['git', 'ls-files', '-z'], cwd=root).decode().split('\0')) - {''}


def facts(root, path):
    file = root / path
    if file.is_symlink():
        raise ValueError('Tracked links require a separate audit; refused: ' + path)
    raw = file.read_bytes()
    binary = b'\0' in raw or file.suffix in {'.gz', '.png'}
    return dict(bytes=len(raw), lines=None if binary else len(raw.splitlines()), sha256=hashlib.sha256(raw).hexdigest())


def reconcile(root, manifest, reviewed=None):
    paths = tracked(root)
    rows = manifest['files']
    existing = {r['path']: r for r in rows}
    if len(existing) != len(rows):
        raise ValueError('Duplicate audit path')
    # Check set membership before reading any path supplied by the JSON.
    stale = set(existing) ^ paths
    changes = set(stale)
    for path in paths & set(existing):
        if path != MANIFEST and any(existing[path].get(k) != v for k, v in facts(root, path).items()):
            changes.add(path)
    if reviewed is None:
        if changes:
            raise ValueError('Audit coverage/hash drift: ' + ', '.join(sorted(changes)))
        if manifest['files_count'] != len(paths) or manifest['coverage_counts'] != dict(Counter(r['method'] for r in rows)):
            raise ValueError('Audit totals do not match records')
        if any(r['inspection'] != 'COMPLETE' for r in rows):
            raise ValueError('Incomplete audit record')
        return manifest
    if changes - reviewed:
        raise ValueError('Explicit full review required before refresh: ' + ', '.join(sorted(changes - reviewed)))
    if reviewed - paths - set(existing):
        raise ValueError('Unknown reviewed path')
    output = []
    for path in sorted(paths):
        row = dict(existing[path]) if path in existing else dict(
            path=path, inspection='COMPLETE', method='MANUAL_FULL_TEXT', verification='PASS',
            verified_scope='Entire newly maintained source/reference inspected; scoped offline regressions. See docs/non-runtime-status.md.',
            limitations='Not native runtime, compatibility approval, or a claim that every gameplay path is proven.', findings=[])
        if path != MANIFEST:
            row.update(facts(root, path))
        if path in reviewed:
            row['reviewed_against_head'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root).decode().strip()
        output.append(row)
    result = dict(manifest, files=output, files_count=len(output),
                  coverage_counts=dict(Counter(r['method'] for r in output)), audit_date='2026-10-27')
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--refresh', action='store_true')
    p.add_argument('--reviewed', nargs='*', default=[])
    a = p.parse_args()
    file = ROOT / MANIFEST
    if file.is_symlink():
        raise ValueError('Linked inventory refused')
    current = json.loads(file.read_text(encoding='utf-8'))
    result = reconcile(ROOT, current, set(a.reviewed) if a.refresh else None)
    if a.refresh:
        # A refreshed digest is an inspection record, never a test or approval.
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=file.parent, prefix='.audit-', suffix='.tmp', delete=False) as out:
            temp = Path(out.name)
            json.dump(result, out, ensure_ascii=False, indent=2)
            out.write('\n')
        try:
            temp.replace(file)
        finally:
            temp.unlink(missing_ok=True)
    print('PASS audit inventory: exact tracked set and content hashes; files=' + str(result['files_count']))


if __name__ == '__main__':
    main()
