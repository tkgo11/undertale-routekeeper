#!/usr/bin/env python3
"""Read only an explicitly selected private file0 snapshot, never live game state.

Mappings are pinned to original save/load sources, independent of ROUTEKEEPER's
route decisions. A matching hash is integrity evidence, not save authenticity.
"""
import argparse
from decimal import Decimal, InvalidOperation
import json
from pathlib import Path
import re
import sys

import runtime_lab as lab
import screen_verify as s

SOURCES = {
    'gml_Script_scr_load.gml': '869541a6a50f630969ff9c01ea4a88b38e9c7dbab7e50f4a81b86c7d8cb7fe56',
    'gml_Script_scr_saveprocess.gml': 'ee143c6ef7113b6c481ea9380204d6a1c771901140cfcc3bcad1c59f4225993f',
    'gml_Script_scr_levelup.gml': 'b875fb5f7e84dd2b8306816b9d9350c7249dc8c22d49943f5bedc97790a8445e',
}
THRESHOLDS = (10, 30, 70, 120, 200, 300, 500, 800, 1200, 1700, 2500,
              3500, 5000, 7000, 10000, 15000, 25000, 50000, 99999)
FLAGS = (27, 45, 52, 53, 54, 55, 57, 67, 81, 88, 94, 202, 203, 204, 205,
         251, 252, 350, 360, 361, 362, 363, 364, 389, 397, 402, 425, 493, 511)
REAL = re.compile(r'[+-]?[0-9]+(?:\.[0-9]+)?\Z')


def private_snapshot(path):
    path = s.no_links(path)
    if not any(path.is_relative_to(s.ROOT / name) and path != s.ROOT / name
               for name in ('.research', 'private-evidence')):
        raise s.EvidenceError('Only repository-private disposable snapshots; never personal live saves')
    if path.name != 'file0':
        raise s.EvidenceError('This exact positional contract supports file0 only')
    return path


def source_contract(original, sources):
    if s.hash_file(original) != lab.DATA_SHA:
        raise s.EvidenceError('Unsupported original data identity')
    actual = {name: s.hash_file(s.child(sources, name)) for name in SOURCES}
    if actual != SOURCES:
        raise s.EvidenceError('Original save/load/level source changed; positional mapping refused')
    return actual


def parse_snapshot(raw):
    if len(raw) > s.MAX_JSON:
        raise s.EvidenceError('Snapshot exceeds 1MiB bound')
    try:
        text = raw.decode('utf-8-sig')
    except UnicodeError as error:
        raise s.EvidenceError('Unsupported snapshot encoding') from error
    if '\0' in text:
        raise s.EvidenceError('Binary snapshot refused')
    text = text.replace('\r\n', '\n')
    if '\r' in text:
        raise s.EvidenceError('Unsupported snapshot newline')
    lines = text.split('\n')
    if lines[-1] == '':
        lines.pop()
    if len(lines) != 549 or not 1 <= len(lines[0]) <= 64:
        raise s.EvidenceError('Exact 549-line save layout required')
    numbers = {}
    for index, line in enumerate(lines[1:], 1):
        value = line.strip()
        if len(value) > 64 or not REAL.fullmatch(value):
            raise s.EvidenceError('Invalid bounded numeric save field')
        try:
            number = Decimal(value)
        except InvalidOperation as error:
            raise s.EvidenceError('Invalid real save field') from error
        if not number.is_finite() or abs(number) > 2 ** 53:
            raise s.EvidenceError('Unsupported numeric save range')
        numbers[index] = number

    def integer(index, minimum, maximum):
        value = numbers[index]
        if value != value.to_integral_value() or not minimum <= value <= maximum:
            raise s.EvidenceError('Unsupported integral saved-state domain')
        return int(value)

    level = integer(1, 1, 20)
    experience = integer(9, 0, 99999)
    kills = integer(11, 0, 2147483647)
    room = integer(547, 0, 2147483647)
    if level != 1 + sum(experience >= threshold for threshold in THRESHOLDS):
        raise s.EvidenceError('LV/EXP outside source-bounded normal-progression domain')
    if numbers[2] <= 0 or numbers[548] < 0:
        raise s.EvidenceError('Unsupported saved HP capacity/time')
    return dict(level=level, experience=experience, kills=kills,
                maxHp=str(numbers[2]), plot=str(numbers[542]), room=room,
                time=str(numbers[548]), flags={str(i): str(numbers[30+i]) for i in FLAGS})


def observe(snapshot, expected_sha256, original, sources):
    snapshot = private_snapshot(snapshot)
    if not s.valid_sha(expected_sha256):
        raise s.EvidenceError('Independent expected snapshot digest required')
    pins = source_contract(original, sources)
    raw = s.read(snapshot, s.MAX_JSON)
    if s.digest(raw) != expected_sha256:
        raise s.EvidenceError('Snapshot changed from expected digest')
    values = parse_snapshot(raw)
    return dict(schema=1, kind='READ_ONLY_SAVED_STATE', result='SAVED_STATE_OBSERVED',
                snapshotSha256=expected_sha256, originalSha256=lab.DATA_SHA, sourceSha256=pins,
                scope='EXACT_BUILD_OFFLINE_FILE0_SNAPSHOT', values=values,
                independence='ORIGINAL_SERIALIZATION_NOT_ROUTEKEEPER_DECISIONS',
                snapshotAuthenticity='UNVERIFIED', liveState='UNVERIFIED', gameplay='UNVERIFIED',
                currentHp='UNAVAILABLE_NOT_SERIALIZED', enemyHp='UNAVAILABLE', encounter='UNAVAILABLE',
                flag512='UNAVAILABLE_NOT_SERIALIZED', loadResetFlags=[94, 360, 361, 362, 363, 364],
                forcedSideEffects='UNVERIFIED', routeEnding='UNVERIFIED')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', type=Path, required=True)
    parser.add_argument('--expected-sha256', required=True)
    parser.add_argument('--original', type=Path, required=True)
    parser.add_argument('--sources', type=Path, required=True)
    args = parser.parse_args()
    try:
        print(json.dumps(observe(args.snapshot, args.expected_sha256, args.original, args.sources), ensure_ascii=True))
        return 0
    except (OSError, ValueError, TypeError, KeyError) as error:
        print(json.dumps(dict(result='BLOCKED', reason=str(error))), file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
