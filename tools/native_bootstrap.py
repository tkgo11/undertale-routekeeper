#!/usr/bin/env python3
"""Freeze and review already acquired private captures; never launch or send input.

Local hashes detect drift, not fabricated provenance. An accountable human must
review the pixels, capture provenance and proposed action meanings separately.
"""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys

import native_gameplay as native
import screen_verify as s
import windows_e2e as e


def private(path):
    path = s.no_links(path)
    if not any(path.is_relative_to(s.ROOT / name) and path != s.ROOT / name
               for name in ('.research', 'private-evidence')):
        raise s.EvidenceError('Bootstrap output must be below ignored repository evidence directories')
    return path


def timestamp(value):
    try:
        value = datetime.fromisoformat(value.replace('Z', '+00:00'))
        if value.utcoffset() is None:
            raise ValueError('Timezone required')
        return value
    except (ValueError, AttributeError, TypeError) as error:
        raise s.EvidenceError('Invalid bootstrap timestamp') from error


def inspect(recipe_path, game_data):
    recipe_path = s.no_links(recipe_path)
    recipe = s.load_json(recipe_path)
    if recipe.get('schema') != 1 or recipe.get('case') not in ('original', 'patched'):
        raise s.EvidenceError('Unsupported bootstrap schema/case')
    for field in ('sourceProvenance', 'startingState'):
        if not isinstance(recipe.get(field), str) or not recipe[field].strip() or len(recipe[field]) > 2048:
            raise s.EvidenceError('Bounded operator provenance/starting-state account required')
    expected = e.lab.DATA_SHA if recipe['case'] == 'original' else e.profile()['PatchedSha256']
    if s.hash_file(game_data) != expected:
        raise s.EvidenceError('Exact game data identity required; no version-only matching')
    scenes = recipe.get('captures')
    if not isinstance(scenes, dict) or not 2 <= len(scenes) <= 80:
        raise s.EvidenceError('A bounded capture collection is required')
    frozen = {}; total = 0; identity = None
    for name, relative in scenes.items():
        s.token(name)
        file = s.child(recipe_path.parent, relative)
        metadata_raw = s.read(Path(str(file) + '.json'), s.MAX_JSON)
        metadata = s.decode_json(metadata_raw)
        image, raw = s.png(file, metadata.get('imageSha256'))
        s.capture_status(metadata, image)
        s.normalize(image, {'space': 'client-pixels'})
        if metadata['runnerSha256'] != e.lab.RUNNER_SHA:
            raise s.EvidenceError('Capture runner mismatch')
        if type(metadata.get('windowHandle')) is not int or metadata['windowHandle'] <= 0:
            raise s.EvidenceError('Actual HWND record required; a scene label is insufficient')
        if timestamp(metadata.get('processStartedUtc')) > timestamp(metadata['startedUtc']):
            raise s.EvidenceError('Capture predates process identity')
        current = (metadata['pid'], metadata['processStartedUtc'], metadata['windowHandle'])
        if identity is not None and identity != current:
            raise s.EvidenceError('Mixed process or window identities')
        identity = current
        total += len(raw) + len(metadata_raw)
        if total > s.MAX_FILE:
            raise s.EvidenceError('Capture collection exceeds 16MiB')
        frozen[name] = (raw, metadata_raw)
    plan = dict(schema=1, id=s.token(recipe.get('id')), version=s.token(recipe.get('version')),
                case=recipe['case'], runnerSha256=e.lab.RUNNER_SHA, dataSha256=expected,
                scope='non-destructive-ui', retries=0, scenes={}, steps=recipe.get('steps'))
    steps = plan['steps']
    if not isinstance(steps, list) or not 1 <= len(steps) <= 80:
        raise s.EvidenceError('Bounded proposed steps required')
    for step in steps:
        if not isinstance(step, dict) or step.get('scenario') not in ('startup', 'english', 'korean', 'settings', 'keyboard'):
            raise s.EvidenceError('Combat, Forced and ending plans remain refused')
        if recipe['case'] == 'original' and step['scenario'] in ('korean', 'settings'):
            raise s.EvidenceError('Original has no mod-only scenario')
        if step.get('before') not in scenes or step.get('after') not in scenes or step.get('action') not in ('checkpoint', *e.KEYS):
            raise s.EvidenceError('Unsupported proposed scene/action')
        for field, low, high in [('holdMs', 50, 500), ('timeoutMs', 100, 15000), ('maxFrames', 2, 100), ('stableFrames', 2, 8)]:
            if type(step.get(field)) is not int or not low <= step[field] <= high:
                raise s.EvidenceError('Invalid proposed bound ' + field)
        if step['stableFrames'] > step['maxFrames']:
            raise s.EvidenceError('Unattainable stable-frame bound')
        if step['action'] != 'checkpoint' and frozen[step['before']][0] == frozen[step['after']][0]:
            raise s.EvidenceError('Input requires distinct captured response')
    history = recipe.get('actionHistory')
    if not isinstance(history, list) or len(history) != len(steps):
        raise s.EvidenceError('Every proposed step needs a bounded recorded action history')
    previous_end = None
    for step, event in zip(steps, history):
        if (not isinstance(event, dict) or event.get('source') not in ('native-dispatch-record', 'operator-observation')
                or any(event.get(field) != step[field] for field in ('action', 'before', 'after', 'holdMs'))):
            raise s.EvidenceError('Action history disagrees with proposed navigation')
        start = timestamp(event.get('startedUtc')); end = timestamp(event.get('finishedUtc'))
        before = s.decode_json(frozen[step['before']][1]); after = s.decode_json(frozen[step['after']][1])
        if (not timestamp(before['finishedUtc']) <= start <= end <= timestamp(after['startedUtc'])
                or not 0 <= (end-start).total_seconds() <= 2
                or previous_end is not None and start < previous_end):
            raise s.EvidenceError('Action/capture history is stale, reordered or unbounded')
        previous_end = end
    return recipe, plan, frozen, identity


def intake(recipe_path, game_data, output):
    output = private(output)
    if output.exists():
        raise s.EvidenceError('Never reuse a bootstrap output')
    recipe, plan, frozen, identity = inspect(recipe_path, game_data)
    output.mkdir(parents=True, mode=0o700)
    (output / 'references').mkdir(mode=0o700)
    files = {}
    for name, (raw, metadata) in frozen.items():
        for suffix, contents in (('.png', raw), ('.png.json', metadata)):
            relative = 'references/' + name + suffix
            s.put(s.child(output, relative), contents)
            files[relative] = s.digest(contents)
        plan['scenes'][name] = dict(file='references/' + name + '.png', sha256=s.digest(raw),
                                   source='pending-capture-review', reviewer=None,
                                   scope='scene-navigation-only', space='client-pixels')
    # Retain exact operator action history/labels as claims. They are never input
    # acceptance evidence and cannot certify gameplay, Forced or loaded bytecode.
    s.put_json(output / 'recipe.json', recipe)
    files['recipe.json'] = s.hash_file(output / 'recipe.json')
    s.put_json(output / 'proposed-plan.json', plan)
    files['proposed-plan.json'] = s.hash_file(output / 'proposed-plan.json')
    manifest = dict(schema=1, kind='PRIVATE_CAPTURE_BOOTSTRAP', files=files, case=plan['case'],
                    dataSha256=plan['dataSha256'], runnerSha256=e.lab.RUNNER_SHA,
                    process=dict(pid=identity[0], startedUtc=identity[1], windowHandle=identity[2]),
                    result='NEEDS_REVIEW', captureProvenance='LOCAL_RECORDS_REQUIRE_HUMAN_REVIEW',
                    loadedBytecode='UNVERIFIED', gameplay='UNVERIFIED', overlayIsolation='UNPROVEN')
    s.put_json(output / 'bootstrap.json', manifest)
    s.put_json(output / 'bootstrap-integrity.json', dict(sha256=s.hash_file(output / 'bootstrap.json')))
    return manifest


def verified(root):
    root = private(root)
    manifest = s.load_json(root / 'bootstrap.json')
    if s.load_json(root / 'bootstrap-integrity.json').get('sha256') != s.hash_file(root / 'bootstrap.json'):
        raise s.EvidenceError('Bootstrap manifest changed')
    if manifest.get('kind') != 'PRIVATE_CAPTURE_BOOTSTRAP' or not isinstance(manifest.get('files'), dict):
        raise s.EvidenceError('Unknown bootstrap collection')
    for relative, expected in manifest['files'].items():
        if s.hash_file(s.child(root, relative)) != expected:
            raise s.EvidenceError('Frozen bootstrap evidence changed')
    proposal = s.load_json(root / 'proposed-plan.json')
    if any(ref.get('source') != 'pending-capture-review' or ref.get('reviewer') is not None
           for ref in proposal.get('scenes', {}).values()):
        raise s.EvidenceError('Unreviewed proposal must remain non-executable')
    return manifest


def review(root, reviewer, request_id, decision, provenance_checked, actions_checked):
    manifest = verified(root)
    s.token(request_id)
    if not isinstance(reviewer, str) or not reviewer.strip() or len(reviewer) > 160:
        raise s.EvidenceError('Accountable human reviewer required')
    if decision not in ('accepted', 'uncertain', 'rejected'):
        raise s.EvidenceError('Unknown scoped review decision')
    if decision == 'accepted' and (not provenance_checked or not actions_checked):
        raise s.EvidenceError('Acceptance requires separate provenance and safe-action review')
    record = dict(schema=1, bootstrapSha256=s.hash_file(private(root) / 'bootstrap.json'),
                  reviewer=reviewer, reviewerType='human', requestId=request_id, decision=decision,
                  provenanceChecked=provenance_checked, nonDestructiveActionsChecked=actions_checked,
                  scope='scene-navigation-only', scenes=sorted(s.load_json(private(root) / 'proposed-plan.json')['scenes']),
                  reviewedUtc=datetime.now(timezone.utc).isoformat(), gameplay='UNVERIFIED')
    if manifest['gameplay'] != 'UNVERIFIED':
        raise s.EvidenceError('Bootstrap cannot certify gameplay')
    s.put_json(private(root) / ('review-' + request_id + '.json'), record)
    return record


def export(root, request_id, output):
    manifest = verified(root)
    root = private(root); output = private(output); s.token(request_id)
    record = s.load_json(root / ('review-' + request_id + '.json'))
    plan = s.load_json(root / 'proposed-plan.json')
    if (record.get('decision') != 'accepted' or record.get('reviewerType') != 'human'
            or record.get('bootstrapSha256') != s.hash_file(root / 'bootstrap.json')
            or record.get('scope') != 'scene-navigation-only'
            or record.get('provenanceChecked') is not True
            or record.get('nonDestructiveActionsChecked') is not True
            or record.get('scenes') != sorted(plan['scenes'])):
        raise s.EvidenceError('Exact capture collection needs accepted scoped review')
    if output.exists():
        raise s.EvidenceError('Never replace an existing exported plan')
    output.mkdir(parents=True, mode=0o700); (output / 'references').mkdir(mode=0o700)
    for ref in plan['scenes'].values():
        s.put(s.child(output, ref['file']), s.read(s.child(root, ref['file'])))
        ref['source'] = 'privately-authentic'
        ref['reviewer'] = record['reviewer']
    plan['reviewProvenance'] = dict(bootstrapSha256=record['bootstrapSha256'],
                                  reviewSha256=s.hash_file(root / ('review-' + request_id + '.json')),
                                  scope='scene-navigation-only', authenticity='ACCOUNTABLE_LOCAL_HUMAN_CLAIM')
    s.put_json(output / 'native-plan.json', plan)
    native.load_plan(output / 'native-plan.json', manifest['case'])
    return dict(result='PLAN_EXPORTED', plan=str(output / 'native-plan.json'), gameplay='UNVERIFIED',
                originalBaseline='NOT_RUN', loadedBytecode='UNVERIFIED')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    p = commands.add_parser('intake')
    p.add_argument('--recipe', type=Path, required=True); p.add_argument('--data', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    p = commands.add_parser('review')
    p.add_argument('--root', type=Path, required=True); p.add_argument('--reviewer', required=True)
    p.add_argument('--request-id', required=True); p.add_argument('--decision', choices=('accepted', 'uncertain', 'rejected'), required=True)
    p.add_argument('--provenance-checked', action='store_true'); p.add_argument('--non-destructive-actions-checked', action='store_true')
    p = commands.add_parser('export')
    p.add_argument('--root', type=Path, required=True); p.add_argument('--request-id', required=True)
    p.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == 'intake':
            result = intake(args.recipe, args.data, args.output)
        elif args.command == 'review':
            result = review(args.root, args.reviewer, args.request_id, args.decision,
                            args.provenance_checked, args.non_destructive_actions_checked)
        else:
            result = export(args.root, args.request_id, args.output)
        print(json.dumps(result, ensure_ascii=True)); return 0
    except (OSError, ValueError, TypeError, KeyError) as error:
        print(json.dumps(dict(result='BLOCKED', reason=str(error))), file=sys.stderr); return 2


if __name__ == '__main__':
    raise SystemExit(main())
