#!/usr/bin/env python3
"""Certify reviewed live acquisition only; never claim exported-plan replay or launch.

Local records and delegated pixel review are accountable claims, not independently
 authenticated identity, internal-state observation or Steam account isolation.
"""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys

from PIL import ImageChops
import native_bootstrap as bootstrap
import native_gameplay as native
import screen_verify as s
import windows_e2e as e

KIND = 'LIVE_REVIEWED_ACQUISITION_BASELINE'
CERTIFICATE = 'live-baseline-review.json'
ROLES = {'startup': ('startup', ('confirm', 'enter')), 'english': ('english', ('enter', 'confirm')),
         'left': ('keyboard', ('left',)), 'right': ('keyboard', ('right',))}


def require(value, message):
    if not value:
        raise e.StopRun(message)


def text(value, minimum=10):
    return isinstance(value, str) and minimum <= len(value.strip()) <= 2048


def ticks(value):
    value = bootstrap.timestamp(value).astimezone(timezone.utc)
    delta = value - datetime(1, 1, 1, tzinfo=timezone.utc)
    # Python truncates the seventh fractional digit; compare at microsecond precision.
    return (delta.days * 86400 + delta.seconds) * 10000000 + delta.microseconds * 10


def inspect_chain(root):
    root = bootstrap.private(root)
    files = {}; capture_bytes = 0
    def load(relative):
        path = s.child(root, relative)
        raw = s.read(path, s.MAX_JSON)
        files[relative] = s.digest(raw)
        return s.decode_json(raw)
    result = load('result.json')
    require(load('result-integrity.json').get('sha256') == files['result.json'], 'Acquisition result seal mismatch')
    require(result.get('kind') == 'EXPERIMENTAL_NATIVE_ACQUISITION' and result.get('case') == 'original'
            and result.get('schema') == 1 and result.get('processObserved') is True
            and result.get('result') == 'NEEDS_REVIEW' and result.get('gameplay') == 'UNVERIFIED', 'Original live acquisition required')
    require(result.get('originalSha256') == e.lab.DATA_SHA and result.get('runnerSha256') == e.lab.RUNNER_SHA
            and result.get('candidateSha256') == e.profile()['PatchedSha256'], 'Acquisition exact build mismatch')
    e.check_pins(result.get('harness'))
    require(result.get('localRecovery') == 'CONTENT_TREE_VERIFIED' and result.get('localPhase') == 'Restored'
            and result.get('cleanupErrors') == [] and all(result.get(k) is True for k in ('copyStable', 'cacheStable', 'registeredStable')),
            'Verified clean acquisition recovery required')
    status = load('acquisition-status.json')
    require(status == result.get('acquisition') and status.get('kind') == 'AGENT_DELEGATED_CAPTURE_ACQUISITION'
            and status.get('case') == 'original' and status.get('result') == 'STOPPED_BY_REVIEWED_REQUEST'
            and status.get('inputsAccepted') == 'UNPROVEN', 'Clean reviewed acquisition stop required')
    rows = status.get('steps')
    require(isinstance(rows, list) and 4 <= len(rows) <= 39 and status.get('nextSequence') == len(rows) + 1,
            'Bounded contiguous acquisition required')
    session = load('session.json'); restored = load('restored.json'); launch = load('game-launch.json')
    consent = load('consent.json'); window = load('window-observed.json')
    approval = consent.get('approval', {})
    require(approval.get('method') == 'OWNER_CHAT_UI_DELEGATION' and approval.get('reviewMethod') == 'AGENT_DELEGATED'
            and approval.get('scope') == 'non-destructive-ui-and-original-copy-recovery'
            and text(approval.get('statement'), 30) and consent.get('session') == session.get('consentSession')
            and consent.get('scope') == 'non-destructive-smoke' and consent.get('policy') == e.POLICY_VERSION
            and consent.get('disclosureSha256') == s.digest(e.DISCLOSURE.encode()), 'Exact delegated session consent required')
    network = consent.get('network', {})
    require(consent.get('credentialsStored') is False and consent.get('accountIsolation') == 'UNPROVEN'
            and result.get('network') == network and network.get('mode') in ('OFFLINE_REQUIRED', 'CONNECTED_RISK_ACCEPTED')
            and network.get('accountHistory') == 'NOT_RESTORED', 'Consent/network scope changed')
    if network['mode'] == 'CONNECTED_RISK_ACCEPTED':
        require(network.get('disclosure') == e.POLICY.get('connectedNetworkDisclosure')
                and network.get('approval', {}).get('statement') == approval['statement'], 'Connected-network risk approval mismatch')
    require(session.get('root') == str(root) and session.get('case') == 'original' and session.get('phase') == 'Restored'
            and launch.get('stage') == 'Observed' and launch.get('id') == session.get('id')
            and launch.get('owner') == session.get('owner'), 'Session/launch ownership mismatch')
    require(all(restored.get(k) == session.get(k) for k in ('id', 'owner', 'originalPresent', 'originalDigest'))
            and restored.get('schema') == 2 and type(session.get('originalPresent')) is bool,
            'Recovery completion fence mismatch')
    identity = (status.get('pid'), status.get('startedTicks'), status.get('windowHandle'))
    require(all(type(x) is int and x > 0 for x in identity) and launch.get('pid') == identity[0]
            and launch.get('startedTicks') == identity[1] and result.get('windowObservation') == window
            and window.get('pid') == identity[0] and window.get('ownerPid') == identity[0]
            and window.get('startedTicks') == identity[1] and window.get('windowHandle') == identity[2]
            and window.get('foreground') == identity[2], 'Native process/window identity mismatch')
    watchdog = load('watchdog/result.json')
    require(watchdog.get('result') == 'OWNED_PROCESS_EXITED' and watchdog.get('descendants') == []
            and not any((root/'watchdog'/name).exists() for name in ('stop.json', 'failure.json')),
            'Watchdog intervention or unknown process closure')
    def tree(relative):
        directory = s.child(root, relative); require(directory.is_dir(), 'Recovery tree missing')
        lines = []; total = 0
        for path in directory.rglob('*'):
            path = s.no_links(path); name = path.relative_to(directory).as_posix()
            if path.is_dir(): lines.append('D\t' + name + '\n')
            else:
                raw = s.read(path); total += len(raw)
                require(total <= s.MAX_RUN_BYTES, 'Recovery tree exceeds budget')
                sha = s.digest(raw); files[path.relative_to(root).as_posix()] = sha
                lines.append('F\t' + name + '\t' + str(len(raw)) + '\t' + sha + '\n')
        return s.digest(''.join(sorted(lines)).encode())
    require(not (root/'protected-save').exists(), 'Protected original not returned')
    if session['originalPresent']:
        require(tree('snapshot') == session.get('originalDigest'), 'Original snapshot digest mismatch')
    boundary = load('game-stop-boundary.json'); fence = load('trial-fence.json')
    require(boundary == fence and boundary.get('schema') == 1 and boundary.get('id') == session.get('id')
            and boundary.get('owner') == session.get('owner') and type(boundary.get('present')) is bool,
            'Stop/recovery trial fence mismatch')
    if boundary['present']:
        require(tree('trial-save') == boundary.get('digest'), 'Archived trial digest mismatch')
    else:
        require(boundary.get('digest') == '' and not (root/'trial-save').exists(), 'Unexpected archived trial')
    captures = {}; geometry = None
    def capture(name):
        nonlocal geometry, capture_bytes
        if name in captures: return captures[name]
        path = s.child(root, name); meta = load(name + '.json')
        image, raw = s.png(path, meta.get('imageSha256')); s.capture_status(meta, image)
        s.normalize(image, {'space': 'client-pixels'})
        capture_bytes += len(raw)
        require(capture_bytes <= s.MAX_RUN_BYTES, 'Capture collection exceeds budget')
        files[name] = s.digest(raw)
        current = (tuple(meta['clientSize']), meta['dpi'])
        require(meta.get('runnerSha256') == e.lab.RUNNER_SHA and meta.get('pid') == identity[0]
                and meta.get('windowHandle') == identity[2] and ticks(meta.get('processStartedUtc')) // 10 == identity[1] // 10,
                'Capture provenance differs from actual owned process')
        require(bootstrap.timestamp(meta['processStartedUtc']) <= bootstrap.timestamp(meta['startedUtc']), 'Capture predates process')
        require(geometry is None or current == geometry, 'Capture geometry/DPI changed')
        geometry = current; captures[name] = (meta, image); return captures[name]
    previous = 'original.png'; capture(previous); inputs = []; requests = []
    for sequence, row in enumerate(rows, 1):
        request_name = f'acquisition-request-{sequence:03}.json'; request = load(request_name); requests.append(request_name)
        after = f'acquisition-{sequence:03}.png'
        require(row.get('sequence') == sequence and row.get('before') == previous and row.get('after') == after
                and row.get('reviewSha256') == files[request_name] and row.get('response') == 'UNREVIEWED_NOT_PASS', 'Acquisition chain discontinuity')
        before_meta, _ = capture(previous); after_meta, _ = capture(after)
        action = request.get('action'); dispatch = row.get('dispatch')
        require(request.get('schema') == 1 and request.get('sequence') == sequence
                and request.get('captureSha256') == files[previous] and request.get('reviewMethod') == 'AGENT_DELEGATED'
                and text(request.get('reviewStatement')) and action in ('capture', *e.KEYS), 'Capture-bound pre-input review mismatch')
        reviewed = bootstrap.timestamp(request.get('recordedUtc'))
        require(bootstrap.timestamp(before_meta['finishedUtc']) <= reviewed <= bootstrap.timestamp(after_meta['startedUtc']), 'Review/capture ordering mismatch')
        if action == 'capture':
            require(dispatch is None, 'Capture-only request unexpectedly dispatched input')
            acted = bootstrap.timestamp(after_meta['startedUtc'])
        else:
            inputs.append(sequence)
            intent = load(f'input-intent-{sequence}.json'); recorded = load(f'input-dispatch-{sequence}.json')
            require(dispatch == recorded and isinstance(dispatch, dict), 'Acquisition dispatch record changed')
            native.validate_dispatch_kind(dispatch, action)
            start = bootstrap.timestamp(dispatch.get('startedUtc')); end = bootstrap.timestamp(dispatch.get('finishedUtc'))
            require(type(request.get('holdMs')) is int and 50 <= request['holdMs'] <= 500
                    and dispatch.get('requestedHeldMs') == request['holdMs'] and dispatch.get('gameAction') == 'UNPROVEN'
                    and 0 <= (end-start).total_seconds() <= 2 and type(dispatch.get('heldMs')) is int and 0 <= dispatch['heldMs'] <= 2000
                    and intent.get('key') == action and intent.get('reviewSha256') == files[request_name]
                    and intent.get('state') == 'ATTEMPTED_NOT_ACKNOWLEDGED'
                    and reviewed <= bootstrap.timestamp(intent.get('startedUtc')) <= start <= end <= bootstrap.timestamp(after_meta['startedUtc']),
                    'Intent/input/capture timing or bounded action mismatch')
            acted = start
        require(0 <= (acted-reviewed).total_seconds() <= 30, 'Pre-input review expired')
        previous = after
    stop_sequence = len(rows) + 1; stop_name = f'acquisition-request-{stop_sequence:03}.json'; stop = load(stop_name); requests.append(stop_name)
    require(stop.get('schema') == 1 and stop.get('sequence') == stop_sequence and stop.get('action') == 'stop'
            and stop.get('reviewMethod') == 'AGENT_DELEGATED' and text(stop.get('reviewStatement'))
            and stop.get('captureSha256') == files[previous] and status.get('capture') == previous
            and status.get('captureSha256') == files[previous], 'Missing final capture-bound reviewed stop')
    require(0 <= (bootstrap.timestamp(stop.get('recordedUtc'))-bootstrap.timestamp(captures[previous][0]['finishedUtc'])).total_seconds() <= 30,
            'Stop review predates latest frame or is stale')
    require((bootstrap.timestamp(stop['recordedUtc'])-bootstrap.timestamp(captures['original.png'][0]['startedUtc'])).total_seconds() <= 240,
            'Acquisition time budget exceeded')
    require(result.get('inputAttempts') == len(inputs) == result.get('inputsDispatched'), 'Incomplete input attempt chain')
    patterns = [('acquisition-request-*.json', set(requests)), ('acquisition-*.png', set(captures)-{'original.png'}),
                ('input-intent-*.json', {f'input-intent-{x}.json' for x in inputs}),
                ('input-dispatch-*.json', {f'input-dispatch-{x}.json' for x in inputs})]
    for pattern, expected in patterns:
        require({x.name for x in root.glob(pattern)} == expected, 'Unexpected acquisition files after stop')
    e.check_pins(result['harness'])
    return dict(root=root, result=result, files=files, rows=rows, captures=captures, stop=stop,
                delegationStatement=approval['statement'], chainSha256=s.digest(s.canonical(files)))


def validate(root, review_path, plan_path, bootstrap_root):
    chain = inspect_chain(root); root = chain['root']
    review_path = bootstrap.private(review_path); plan_path = bootstrap.private(plan_path); bootstrap_root = bootstrap.private(bootstrap_root)
    review = s.load_json(review_path); plan = native.load_plan(plan_path, 'original'); manifest = bootstrap.verified(bootstrap_root)
    require(review.get('schema') == 1 and review.get('kind') == 'LIVE_ACQUISITION_PIXEL_REVIEW'
            and review.get('method') == 'AGENT_DELEGATED' and review.get('reviewerType') == 'agent'
            and text(review.get('reviewer'), 1) and review.get('delegationStatement') == chain['delegationStatement']
            and review.get('decision') == 'accepted' and review.get('provenanceChecked') is True
            and review.get('nonDestructiveActionsChecked') is True and review.get('pixelsReviewed') is True
            and review.get('resultSha256') == chain['files']['result.json'] and review.get('chainSha256') == chain['chainSha256']
            and review.get('planSha256') == s.hash_file(plan_path), 'Explicit exact-chain post-pixel review required')
    require(bootstrap.timestamp(review.get('reviewedUtc')) >= bootstrap.timestamp(chain['stop']['recordedUtc']), 'Post-review predates live stop')
    provenance = plan.get('reviewProvenance', {})
    require(provenance.get('method') == 'AGENT_DELEGATED' and provenance.get('reviewerType') == 'agent'
            and provenance.get('authenticity') == 'OWNER_DELEGATED_AGENT_LOCAL_CLAIM'
            and provenance.get('bootstrapSha256') == s.hash_file(bootstrap_root/'bootstrap.json'), 'Exported delegated bootstrap link required')
    matching = [p for p in bootstrap_root.glob('review-*.json') if s.hash_file(p) == provenance.get('reviewSha256')]
    require(len(matching) == 1, 'Exact bootstrap review missing')
    br = s.load_json(matching[0]); proposal = s.load_json(bootstrap_root/'proposed-plan.json')
    require(br.get('method') == 'AGENT_DELEGATED' and br.get('reviewerType') == 'agent' and br.get('decision') == 'accepted'
            and br.get('delegationStatement') == chain['delegationStatement'] and br.get('provenanceChecked') is True
            and br.get('nonDestructiveActionsChecked') is True and br.get('bootstrapSha256') == provenance['bootstrapSha256']
            and br.get('scenes') == sorted(proposal['scenes']) and plan['steps'] == proposal['steps']
            and set(plan['scenes']) == set(proposal['scenes']) and manifest.get('case') == 'original'
            and manifest.get('process') == dict(pid=chain['result']['acquisition']['pid'], startedUtc=chain['captures']['original.png'][0]['processStartedUtc'],
                                                windowHandle=chain['result']['acquisition']['windowHandle']), 'Bootstrap review/export ownership mismatch')
    frozen = dict(chain['files'])
    for name, ref in plan['scenes'].items():
        require(ref.get('sha256') == proposal['scenes'][name].get('sha256')
                and ref.get('file') == proposal['scenes'][name].get('file')
                and ref.get('reviewer') == br.get('reviewer') and ref.get('source') == 'privately-authentic'
                and manifest['files'].get(ref['file']) == ref['sha256']
                and s.hash_file(s.child(bootstrap_root, ref['file'])) == ref['sha256']
                and any(meta['imageSha256'] == ref['sha256']
                        and s.hash_file(s.child(bootstrap_root, ref['file']+'.json')) == chain['files'][capture_name+'.json']
                        for capture_name, (meta, _) in chain['captures'].items()),
                'Exported reference differs from reviewed original acquisition')
    roles = review.get('behaviors'); require(isinstance(roles, dict) and set(roles) == set(ROLES), 'Four scoped reviewed behaviors required')
    used = set()
    for role, (scenario, actions) in ROLES.items():
        item = roles[role]; sequence = item.get('sequence')
        require(type(sequence) is int and 1 <= sequence <= len(chain['rows']) and sequence not in used, 'Distinct reviewed behavior sequence required')
        used.add(sequence); row = chain['rows'][sequence-1]; dispatch = row.get('dispatch') or {}
        before_meta, before = chain['captures'][row['before']]; after_meta, after = chain['captures'][row['after']]
        require(item.get('decision') == 'accepted' and item.get('pixelsReviewed') is True and item.get('provenanceReviewed') is True
                and text(item.get('interpretation'), 20) and dispatch.get('key') in actions
                and item.get('beforeSha256') == before_meta['imageSha256'] and item.get('afterSha256') == after_meta['imageSha256']
                and before.tobytes() != after.tobytes(), 'Independent post-action pixel meaning review required')
        before_scene = item.get('beforeScene'); after_scene = item.get('afterScene')
        require(before_scene in plan['scenes'] and after_scene in plan['scenes']
                and plan['scenes'][before_scene]['sha256'] == before_meta['imageSha256']
                and plan['scenes'][after_scene]['sha256'] == after_meta['imageSha256']
                and any(step['scenario'] == scenario and step['action'] == dispatch['key'] and step['before'] == before_scene
                        and step['after'] == after_scene and step['holdMs'] == dispatch['requestedHeldMs'] for step in plan['steps']), 'Reviewed behavior/exported-plan reference mismatch')
        if role in ('left', 'right'):
            stable = item.get('stableSequence')
            require(type(stable) is int and sequence < stable <= len(chain['rows']) and all(chain['rows'][x-1]['dispatch'] is None for x in range(sequence+1, stable+1)),
                    'Movement requires a later input-free stability capture')
            stable_row = chain['rows'][stable-1]; stable_meta, stable_image = chain['captures'][stable_row['after']]
            require(item.get('stableSha256') == stable_meta['imageSha256'] and item.get('sameRoom') is True
                    and item.get('backgroundUnchanged') is True and text(item.get('positionEvidence'), 20), 'Movement room/position/stability review required')
            boxes = [item.get('beforeActor'), item.get('afterActor')]
            require(all(isinstance(box, list) and len(box) == 4 and all(type(v) is int for v in box)
                        and 0 <= box[0] < box[2] <= before.width and 0 <= box[1] < box[3] <= before.height for box in boxes), 'Reviewed actor rectangles required')
            a, b = boxes; require(a[2]-a[0] == b[2]-b[0] and a[3]-a[1] == b[3]-b[1]
                                 and a[1] == b[1] and ((b[0] < a[0]) if role == 'left' else (b[0] > a[0])), 'Actor displacement contradicts movement')
            # Position claims must be corroborated by pixels, with the same static room
            # outside both actor rectangles and a settled matching response afterward.
            diff = ImageChops.difference(before.convert('RGB'), after.convert('RGB'))
            for box in boxes: diff.paste((0, 0, 0), box)
            require(all((box[2]-box[0])*(box[3]-box[1]) <= before.width*before.height//8 for box in boxes)
                    and diff.getbbox() is None, 'Room background contradicts bounded actor movement review')
            color = item.get('actorColor')
            require(isinstance(color, list) and len(color) == 3 and all(type(v) is int and 0 <= v <= 255 for v in color),
                    'Reviewed independent actor color required')
            def marker(image, box):
                rgb = image.convert('RGB'); pixels = rgb.load()
                points = [(x, y) for y in range(image.height) for x in range(image.width)
                          if pixels[x, y] == tuple(color)]
                require(3 <= len(points) <= image.width*image.height//32 and all(box[0] <= x < box[2] and box[1] <= y < box[3] for x, y in points),
                        'Independent actor-color pixels absent, ambiguous or outside reviewed rectangle')
                return ((min(x for x, y in points)+max(x for x, y in points))/2,
                        (min(y for x, y in points)+max(y for x, y in points))/2)
            before_position = marker(before, a); after_position = marker(after, b); stable_position = marker(stable_image, b)
            require(((after_position[0] < before_position[0]) if role == 'left' else (after_position[0] > before_position[0]))
                    and abs(after_position[1]-before_position[1]) <= 2
                    and all(abs(x-y) <= 2 for x, y in zip(after_position, stable_position)),
                    'Independent actor-color displacement/stability contradicts reviewed movement')
    for path in [review_path, plan_path, bootstrap_root/'bootstrap.json', bootstrap_root/'bootstrap-integrity.json',
                 bootstrap_root/'proposed-plan.json', matching[0]]:
        frozen[str(path)] = s.hash_file(path)
    for ref in plan['scenes'].values(): frozen[str(s.child(plan_path.parent, ref['file']))] = ref['sha256']
    for relative, expected in chain['files'].items():
        require(s.hash_file(s.child(root, relative)) == expected, 'Acquisition changed during baseline validation')
    e.check_pins(chain['result']['harness'])
    return dict(schema=1, kind=KIND, root=str(root), review=str(review_path), plan=str(plan_path), bootstrap=str(bootstrap_root),
                chainSha256=chain['chainSha256'], files=frozen, harness=chain['result']['harness'],
                result='SCOPED_LIVE_NAVIGATION_BASELINE_ACCEPTED', behaviors=sorted(ROLES), method='AGENT_DELEGATED',
                exportedPlanReplayed=False, gameplay='UNVERIFIED', internalState='UNVERIFIED', accountIsolation='UNPROVEN')


def certify(root, review, plan, frozen_bootstrap):
    certificate = validate(root, review, plan, frozen_bootstrap)
    path = bootstrap.private(root)/CERTIFICATE
    require(not path.exists(), 'Never replace a live baseline certificate')
    s.put_json(path, certificate)
    return certificate


def verify(path, harness):
    path = bootstrap.private(path)
    if path.is_dir(): path = path/CERTIFICATE
    record = s.load_json(path)
    require(record.get('kind') == KIND and path.parent == Path(record.get('root', '')), 'Unknown live baseline certificate')
    fresh = validate(path.parent, record['review'], record['plan'], record['bootstrap'])
    require(record == fresh and fresh['harness'] == harness, 'Live baseline evidence or exact harness changed')
    return fresh


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('inspect', 'certify'))
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--review', type=Path); parser.add_argument('--plan', type=Path); parser.add_argument('--bootstrap', type=Path)
    args = parser.parse_args()
    try:
        if args.command == 'inspect':
            chain = inspect_chain(args.root)
            result = dict(chainSha256=chain['chainSha256'], resultSha256=chain['files']['result.json'], status='NEEDS_EXPLICIT_POST_PIXEL_REVIEW')
        else:
            require(all((args.review, args.plan, args.bootstrap)), 'Review/plan/bootstrap required')
            result = certify(args.root, args.review, args.plan, args.bootstrap)
        print(json.dumps(result, ensure_ascii=True)); return 0
    except (OSError, ValueError, TypeError, KeyError) as error:
        print(json.dumps(dict(result='BLOCKED', reason=str(error))), file=sys.stderr); return 2


if __name__ == '__main__':
    raise SystemExit(main())
