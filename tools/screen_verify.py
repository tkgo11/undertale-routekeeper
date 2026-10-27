#!/usr/bin/env python3
"""Private offline screen contracts and an append-only, scoped visual review queue.

No process launch, input dispatch, networking or native gameplay inference.
"""
import argparse
from contextvars import ContextVar
from datetime import datetime, timezone
import hashlib
import html
import io
import json
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile
import warnings
import zlib

from PIL import Image, ImageChops, ImageDraw, UnidentifiedImageError, __version__ as pillow_version

ROOT = Path(__file__).resolve().parents[1]
MAX_FILE = 16 * 1024 * 1024
MAX_PIXELS = 4096 * 4096
MAX_JSON = 1024 * 1024
MAX_RUN_BYTES = 128 * 1024 * 1024
WRITE_BUDGET = ContextVar('screen_write_budget', default=None)
VERDICTS = ('PASS', 'FAIL', 'NEEDS_REVIEW', 'BLOCKED', 'NOT_RUN', 'INVALID_EVIDENCE')
DECISIONS = ('accepted', 'defect', 'uncertain', 'invalid', 'recapture')
TOKEN = re.compile(r'[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}\Z')
HEX = re.compile(r'[0-9a-f]{64}\Z')
Image.MAX_IMAGE_PIXELS = MAX_PIXELS


class EvidenceError(ValueError):
    """Untrusted or invalid evidence; never a visual FAIL/PASS."""


def token(value):
    if not isinstance(value, str) or not TOKEN.fullmatch(value):
        raise EvidenceError('Invalid identifier')
    if value.split('.')[0].upper() in {'CON', 'PRN', 'AUX', 'NUL', *(f'COM{i}' for i in range(10)), *(f'LPT{i}' for i in range(10))}:
        raise EvidenceError('Reserved identifier')
    return value


def valid_sha(value):
    return isinstance(value, str) and HEX.fullmatch(value) is not None


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2, allow_nan=False) + '\n').encode('utf-8')


def no_links(path):
    if str(path).startswith(('\\\\', '//')):
        raise EvidenceError('Network/device evidence paths refused')
    path = Path(os.path.abspath(path))
    for part in (path, *path.parents):
        try:
            info = part.lstat()
        except FileNotFoundError:
            continue
        if stat.S_ISLNK(info.st_mode) or getattr(info, 'st_file_attributes', 0) & 1024:
            raise EvidenceError('Linked/reparse evidence path refused')
        if not stat.S_ISDIR(info.st_mode) and not stat.S_ISREG(info.st_mode):
            raise EvidenceError('Special evidence node refused')
        if stat.S_ISREG(info.st_mode) and info.st_nlink != 1:
            raise EvidenceError('Hardlinked evidence file refused')
    return path


def child(root, name):
    if not isinstance(name, str) or not name or '\\' in name or ':' in name:
        raise EvidenceError('Invalid relative evidence path')
    parts = name.split('/')
    if any(not x or x in ('.', '..') or x.endswith((' ', '.')) or any(ord(c) < 32 or c in '<>"|?*' for c in x) for x in parts):
        raise EvidenceError('Unsafe evidence path')
    for part in parts:
        if re.fullmatch(r'(CON|PRN|AUX|NUL|COM[0-9¹²³]|LPT[0-9¹²³])(?:\..*)?', part, re.I):
            raise EvidenceError('Reserved evidence path')
    return no_links(no_links(root).joinpath(*parts))


def read(path, limit=MAX_FILE):
    path = no_links(path)
    try:
        fd = os.open(path, os.O_RDONLY | getattr(os, 'O_NOFOLLOW', 0) | getattr(os, 'O_NONBLOCK', 0))
        with os.fdopen(fd, 'rb') as stream:
            info = os.fstat(stream.fileno())
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_size > limit:
                raise EvidenceError('Evidence file type/size refused')
            raw = stream.read(limit + 1)
            if len(raw) > limit:
                raise EvidenceError('Evidence exceeds limit')
            after = os.fstat(stream.fileno())
            if (info.st_size, info.st_mtime_ns, info.st_ino) != (after.st_size, after.st_mtime_ns, after.st_ino):
                raise EvidenceError('Evidence changed during read')
            return raw
    except OSError as error:
        raise EvidenceError('Evidence unavailable') from error



def hash_file(path, limit=1024*1024*1024):
    """Streaming identity for actual game files; image limits are separate."""
    path = no_links(path)
    try:
        fd = os.open(path, os.O_RDONLY | getattr(os, 'O_NOFOLLOW', 0) | getattr(os, 'O_NONBLOCK', 0))
        with os.fdopen(fd, 'rb') as stream:
            before = os.fstat(stream.fileno())
            if not stat.S_ISREG(before.st_mode) or before.st_nlink != 1 or before.st_size > limit:
                raise EvidenceError('Identity file type/size refused')
            total = 0
            hasher = hashlib.sha256()
            while True:
                block = stream.read(min(1024*1024, limit-total+1))
                if not block:
                    break
                total += len(block)
                if total > limit:
                    raise EvidenceError('Identity file exceeds bounded limit')
                hasher.update(block)
            after = os.fstat(stream.fileno())
            if (before.st_size,before.st_mtime_ns,before.st_ino) != (after.st_size,after.st_mtime_ns,after.st_ino) or total != before.st_size:
                raise EvidenceError('Identity file changed during hashing')
            return hasher.hexdigest()
    except OSError as error:
        raise EvidenceError('Identity file unavailable') from error

def decode_json(raw):
    def pairs(values):
        result = {}
        for key, value in values:
            if key in result:
                raise EvidenceError('Duplicate JSON key')
            result[key] = value
        return result
    try:
        result = json.loads(raw, object_pairs_hook=pairs,
                            parse_constant=lambda _: (_ for _ in ()).throw(EvidenceError('Nonfinite JSON')))
    except (UnicodeError, json.JSONDecodeError, RecursionError) as error:
        raise EvidenceError('Malformed JSON') from error
    if not isinstance(result, dict):
        raise EvidenceError('Expected JSON object')
    return result


def load_json(path):
    return decode_json(read(path, MAX_JSON))


def put(path, raw):
    """Publish a new immutable file; never replace prior evidence/decisions."""
    path = no_links(path)
    budget = WRITE_BUDGET.get()
    if len(raw) > MAX_RUN_BYTES:
        raise EvidenceError('Output exceeds bounded size')
    if budget is not None:
        budget[0] -= len(raw)
        budget[1] -= 1
        if min(budget) < 0:
            raise EvidenceError('Evidence output budget exceeded')
    if path.exists():
        raise EvidenceError('Refusing existing output')
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, 'O_NOFOLLOW', 0), 0o600)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(raw)
            stream.flush()
            os.fsync(stream.fileno())
    except BaseException:
        path.unlink(missing_ok=True)
        raise


def put_json(path, data):
    raw = canonical(data)
    if len(raw) > MAX_JSON:
        raise EvidenceError('JSON output exceeds size limit')
    put(path, raw)


def png_bytes(image):
    # Pillow convert/copy can retain ICC/EXIF/text metadata. Never carry these
    # into normalized/exported images; original bytes stay privately sealed.
    image = image.copy()
    image.info.clear()
    out = io.BytesIO()
    image.save(out, format='PNG', optimize=False, compress_level=9)
    return out.getvalue()


def png(path, expected_hash):
    return decode_png(read(path), expected_hash)


def decode_png(raw, expected_hash):
    if not valid_sha(expected_hash):
        raise EvidenceError('Missing evidence SHA-256')
    if digest(raw) != expected_hash:
        raise EvidenceError('Evidence hash mismatch')
    try:
        with warnings.catch_warnings():
            warnings.simplefilter('error', Image.DecompressionBombWarning)
            with Image.open(io.BytesIO(raw)) as source:
                if source.format != 'PNG' or source.width * source.height > MAX_PIXELS or getattr(source, 'n_frames', 1) != 1:
                    raise EvidenceError('Unsupported image format/dimensions/animation')
                source.verify()
            with Image.open(io.BytesIO(raw)) as source:
                source.load()
                image = source.convert('RGBA')
                if image.getchannel('A').getextrema() != (255, 255):
                    raise EvidenceError('Transparent/incomplete capture')
                return image.convert('RGB'), raw
    except (UnidentifiedImageError, OSError, SyntaxError, ValueError, Image.DecompressionBombError, Image.DecompressionBombWarning) as error:
        raise EvidenceError('Invalid PNG evidence') from error


def rectangle(value, size):
    if not isinstance(value, list) or len(value) != 4 or any(type(x) is not int for x in value):
        raise EvidenceError('Expected integer rectangle')
    x, y, right, bottom = value
    if not (0 <= x < right <= size[0] and 0 <= y < bottom <= size[1]):
        raise EvidenceError('Rectangle outside image')
    return tuple(value)


def normalize(image, geometry=None):
    """Only lossless integer expansion; optional explicit verified black bars."""
    geometry = geometry or {}
    if not isinstance(geometry, dict):
        raise EvidenceError('Invalid geometry metadata')
    crop = geometry.get('content')
    if crop is not None:
        if geometry.get('cropVerified') is not True:
            raise EvidenceError('Unverified crop')
        box = rectangle(crop, image.size)
        # Do not auto-detect/crop meaningful discrepancies. All excluded pixels
        # must be black, and the explicit rectangle remains in evidence metadata.
        outside = image.copy()
        ImageDraw.Draw(outside).rectangle((box[0], box[1], box[2]-1, box[3]-1), fill='black')
        if outside.getbbox():
            raise EvidenceError('Nonblack excluded letterbox pixels')
        image = image.crop(box)
    width, height = image.size
    if width % 320 or height % 240 or width // 320 != height // 240 or not 1 <= width // 320 <= 8:
        raise EvidenceError('Unsupported aspect ratio/noninteger scaling')
    scale = width // 320
    logical = image.resize((320, 240), Image.Resampling.NEAREST)
    if logical.resize(image.size, Image.Resampling.NEAREST).tobytes() != image.tobytes():
        raise EvidenceError('Pixels are not uniform integer-scaled blocks')
    return logical, {'scale': scale, 'content': crop, 'logical': [320, 240]}


def compare(actual, expected, regions=None, ignore=None, tolerance=0):
    if actual.size != expected.size:
        raise EvidenceError('Comparison geometry mismatch')
    if type(tolerance) is not int or not 0 <= tolerance <= 255:
        raise EvidenceError('Invalid per-channel tolerance')
    mask = Image.new('L', actual.size, 0 if regions else 255)
    drawing = ImageDraw.Draw(mask)
    for value in regions or []:
        x, y, right, bottom = rectangle(value, actual.size)
        drawing.rectangle((x, y, right-1, bottom-1), fill=255)
    for item in ignore or []:
        if not isinstance(item, dict) or not isinstance(item.get('reason'), str) or not item['reason'].strip():
            raise EvidenceError('Ignored region needs explanation')
        x, y, right, bottom = rectangle(item.get('rect'), actual.size)
        drawing.rectangle((x, y, right-1, bottom-1), fill=0)
    count = mask.histogram()[255]
    if not count:
        raise EvidenceError('Empty comparison mask')
    raw = ImageChops.difference(actual, expected)
    changed = Image.new('L', actual.size)
    values = []
    total = 0
    for difference, included in zip(raw.getdata(), mask.getdata()):
        total += sum(difference) if included else 0
        values.append(255 if included and max(difference) > tolerance else 0)
    changed.putdata(values)
    different = changed.histogram()[255]
    overlay = actual.copy()
    overlay.paste((255, 0, 255), mask=changed)
    return dict(pixels=count, changed=different, ratio=different/count,
                meanAbsoluteChannelDifference=total/(count*3), bbox=changed.getbbox(), tolerance=tolerance), overlay


def structure(image, features):
    """Independent explicit pixel contracts, not generalized screen recognition."""
    results = []
    if not isinstance(features, list) or not features or len(features) > 128:
        raise EvidenceError('Invalid structural feature list')
    for feature in features:
        name = token(feature['id'])
        color = feature.get('color')
        if not isinstance(color, list) or len(color) != 3 or any(type(c) is not int or not 0 <= c <= 255 for c in color):
            raise EvidenceError('Invalid feature color')
        box = rectangle(feature['rect'], image.size)
        region = image.crop(box)
        kind = feature.get('kind')
        if kind == 'solid':
            matches = all(p == tuple(color) for p in region.getdata())
        elif kind == 'heart':
            rows = ['01100110', '11111111', '11111111', '01111110', '00111100', '00011000']
            if region.size != (8, 6):
                raise EvidenceError('Invalid heart geometry')
            # Require both foreground and absence of that color in the holes.
            matches = all((region.getpixel((x, y)) == tuple(color)) == (bit == '1') for y, row in enumerate(rows) for x, bit in enumerate(row))
        else:
            raise EvidenceError('Unsupported structural method')
        results.append({'id': name, 'matches': matches})
    return results


def aggregate(results):
    if any(x['result'] == 'FAIL' for x in results):
        return 'FAIL'
    values = [x['result'] for x in results if x.get('mandatory', True)]
    if not values:
        return 'NOT_RUN'
    for state in ('FAIL', 'INVALID_EVIDENCE', 'BLOCKED', 'NEEDS_REVIEW', 'NOT_RUN'):
        if state in values:
            return state
    return 'PASS'


def result(identifier, scope, verdict, reason, **details):
    return dict(id=token(identifier), scope=scope, result=verdict, reason=reason,
                independent=False, **details)


def deterministic(assertion, root):
    identifier = token(assertion['id'])
    kind = assertion.get('kind')
    try:
        if kind == 'file-sha256':
            expected = assertion['expected']
            if not valid_sha(expected):
                raise EvidenceError('Invalid expected hash')
            actual = hash_file(child(root, assertion['file']))
            row = result(identifier, 'file-integrity', 'PASS' if actual == expected else 'FAIL',
                         'File bytes compared; no gameplay or remote-history claim', expected=expected,
                         actual=actual, evidenceSource=assertion['file'], evidenceSha256=actual)
            row['independent'] = True
            return row
        if kind == 'configuration':
            raw = read(child(root, assertion['file']), MAX_JSON)
            if digest(raw) != assertion['sha256']:
                raise EvidenceError('Configuration observation hash mismatch')
            data = decode_json(raw)
            key = assertion['key']
            if key not in data:
                raise EvidenceError('Configuration key missing')
            actual = data[key]
            expected = assertion['expected']
            row = result(identifier, 'configuration', 'PASS' if type(actual) is type(expected) and actual == expected else 'FAIL',
                         'Persisted configuration only; not in-game application', expected=expected, actual=actual,
                         evidenceSource=assertion['file'], evidenceSha256=digest(raw))
            row['independent'] = True
            return row
        if kind in ('unobservable', 'blocked', 'not-run'):
            return result(identifier, 'gameplay', {'unobservable':'NEEDS_REVIEW', 'blocked':'BLOCKED', 'not-run':'NOT_RUN'}[kind],
                          'No implemented independent gameplay observer' if kind == 'unobservable' else 'Required precondition not established')
        return result(identifier, 'observation', 'NEEDS_REVIEW', 'Unsupported observer; caller claims and input dispatch cannot prove game actions')
    except (EvidenceError, KeyError, TypeError, ValueError):
        return result(identifier, 'observation', 'INVALID_EVIDENCE', 'Missing, malformed or mismatched deterministic evidence')


def capture_status(metadata, image):
    """Validate capture records; CopyFromScreen never proves overlay isolation."""
    required = ('schema', 'method', 'imageSha256', 'clientSize', 'foregroundBefore', 'foregroundAfter',
                'ownerPid', 'pid', 'runnerSha256', 'expectedRunnerSha256', 'startedUtc', 'finishedUtc', 'dpi')
    if not isinstance(metadata, dict) or any(k not in metadata for k in required):
        raise EvidenceError('Missing capture metadata')
    if type(metadata['schema']) is not int or metadata['schema'] != 1 or not isinstance(metadata['clientSize'], list) or any(type(x) is not int for x in metadata['clientSize']) or metadata['clientSize'] != list(image.size):
        raise EvidenceError('Mismatched capture dimensions/schema')
    if metadata['foregroundBefore'] is not True or metadata['foregroundAfter'] is not True or type(metadata['pid']) is not int or metadata['pid'] <= 0 or type(metadata['ownerPid']) is not int or metadata['ownerPid'] != metadata['pid']:
        raise EvidenceError('Focus/window ownership not established')
    if not valid_sha(metadata['imageSha256']) or not valid_sha(metadata['runnerSha256']) or metadata['runnerSha256'] != metadata['expectedRunnerSha256']:
        raise EvidenceError('Unverified executable identity')
    try:
        start = datetime.fromisoformat(metadata['startedUtc'].replace('Z', '+00:00'))
        end = datetime.fromisoformat(metadata['finishedUtc'].replace('Z', '+00:00'))
        if start.utcoffset() is None or end.utcoffset() is None or not 0 <= (end-start).total_seconds() <= 10:
            raise ValueError('Invalid capture order')
    except (ValueError, AttributeError, TypeError) as error:
        raise EvidenceError('Invalid capture timestamps') from error
    if metadata['method'] != 'CopyFromScreen' or type(metadata['dpi']) is not int or metadata['dpi'] <= 0:
        raise EvidenceError('Unsupported capture method/DPI')
    return 'NEEDS_REVIEW', 'CopyFromScreen overlay/focus races remain unproven; review pixels privately'


def temporal(frames, expected, timeout_ms, stable_frames):
    if type(timeout_ms) is not int or not 1 <= timeout_ms <= 60000 or type(stable_frames) is not int or not 2 <= stable_frames <= 32:
        raise EvidenceError('Invalid temporal bounds')
    if not 2 <= len(frames) <= 64:
        raise EvidenceError('Expected bounded frame sequence')
    prior = -1
    for timestamp, _ in frames:
        if type(timestamp) is not int or timestamp <= prior or timestamp < 0:
            raise EvidenceError('Nonmonotonic frame timestamps')
        prior = timestamp
    stable = 0
    for timestamp, image in frames:
        if timestamp > timeout_ms:
            return 'NEEDS_REVIEW', 'Visual stabilization timeout'
        stable = stable+1 if image.tobytes() == expected.tobytes() else 0
    if stable >= stable_frames:
        return 'PASS', 'Defined visual stabilization observed; not scheduler/game-action proof'
    return 'NEEDS_REVIEW', 'Animation instability or stabilization timeout'


def reference_provenance(meta):
    required = ('source', 'generatorVersion', 'sourceHashes', 'locale', 'font', 'scene', 'kind')
    if not isinstance(meta, dict) or any(k not in meta for k in required):
        raise EvidenceError('Missing reference provenance')
    if meta['kind'] not in ('synthetic', 'proxy', 'private-authentic', 'independently-reviewed'):
        raise EvidenceError('Unsupported reference authority')
    for field in ('locale', 'font', 'scene'):
        token(meta[field])
    if not isinstance(meta['sourceHashes'], dict) or not meta['sourceHashes'] or any(not valid_sha(v) for v in meta['sourceHashes'].values()):
        raise EvidenceError('Invalid reference source hashes')
    return meta



def store_capture_record(assertion,root,actual,folder):
    capture_path=child(root,assertion['capture']);raw=read(capture_path,MAX_JSON)
    if digest(raw)!=assertion['captureSha256']:raise EvidenceError('Capture sidecar hash mismatch')
    metadata=decode_json(raw)
    if metadata.get('imageSha256')!=assertion['actualSha256']:raise EvidenceError('Capture metadata/frame hash mismatch')
    state,reason=capture_status(metadata,actual)
    put_json(folder/'capture-private.json',metadata)
    return state,reason

def visual(assertion, root, kind, folder):
    identifier = token(assertion['id'])
    row = result(identifier, 'visual', 'NEEDS_REVIEW', 'Insufficient visual evidence', expected='Defined visual contract', actual=None)
    try:
        actual_path = child(root, assertion['actual'])
        # Preserve bounded rejected bytes privately for diagnosis, even when PNG
        # decoding/hash validation fails. Exports never include this opaque file.
        actual_raw = read(actual_path)
        put(folder/'submitted-actual.bin', actual_raw)
        actual, actual_raw = decode_png(actual_raw, assertion['actualSha256'])
        put(folder/'actual.png', actual_raw)
        if assertion.get('method')=='capture-only':
            if kind=='native-import':store_capture_record(assertion,root,actual,folder)
            try:
                normalized,geometry=normalize(actual,assertion.get('geometry'))
                put(folder/'normalized.png',png_bytes(normalized));row['geometry']=geometry
            except EvidenceError as error:
                # Original-game scenes may contain sub-grid pixels. A bounded,
                # valid raw capture is still reviewable, never forcibly resized.
                row['geometry']={'normalized':False,'reason':str(error),'rawSize':list(actual.size)}
            row.update(result='NEEDS_REVIEW',reason='No authoritative reference; capture-only observation cannot establish expected rendering or game state',
                       method='capture-only',reviewableAsPass=False,actualSha256=assertion['actualSha256'],evidenceSource=assertion['actual'],
                       question='Inspect only visible pixels; no expected reference exists. Do not infer the intended screen, gameplay or Steam history.')
            return row
        normalized,geometry=normalize(actual,assertion.get('geometry'))
        put(folder/'normalized.png',png_bytes(normalized));row['geometry']=geometry
        ref = assertion['reference']
        provenance = reference_provenance(ref['provenance'])
        expected, expected_raw = png(child(root, ref['file']), ref['sha256'])
        expected, _ = normalize(expected, ref.get('geometry'))
        put(folder/'expected.png', expected_raw)
        method = assertion.get('method', 'exact')
        # Tolerance must be calibrated/versioned; no invented probability score.
        policy = assertion.get('policy', {})
        if method not in ('exact', 'bounded-difference', 'structure', 'temporal'):
            row['reason'] = 'Unsupported comparison method'
        else:
            tolerance = 0
            if method == 'bounded-difference':
                token(policy['version'])
                calibration_raw = read(child(root, policy['calibration']), MAX_JSON)
                calibration = decode_json(calibration_raw)
                put(folder/'calibration-private.json', calibration_raw)
                if digest(calibration_raw) != policy['calibrationSha256'] or calibration.get('scenario') != assertion['scenario'] or calibration.get('version') != policy['version']:
                    raise EvidenceError('Calibration identity mismatch')
                # Require measured positive/negative score separation, not probability.
                positives, negatives = [], []
                samples = calibration['samples']
                if not isinstance(samples, list) or not 2 <= len(samples) <= 16:
                    raise EvidenceError('Calibration requires bounded positive/negative fixtures')
                tolerance = policy.get('channelTolerance', 0)
                for sample_index, sample in enumerate(samples):
                    sample_image, sample_raw = png(child(root, sample['file']), sample['sha256'])
                    put(folder/f'calibration-{sample_index:02}.png', sample_raw)
                    sample_image, _ = normalize(sample_image, sample.get('geometry'))
                    score, _ = compare(sample_image, expected, assertion.get('regions'), assertion.get('ignore'), tolerance)
                    if sample.get('classification') not in ('positive', 'negative'):
                        raise EvidenceError('Invalid calibration fixture classification')
                    (positives if sample['classification'] == 'positive' else negatives).append(score['ratio'])
                row['calibration'] = dict(positiveRatios=positives, negativeRatios=negatives, sha256=digest(calibration_raw), version=policy['version'])
                threshold = policy['maxRatio']
                if not positives or not negatives or any(type(v) not in (int, float) or not 0 <= v <= 1 for v in positives+negatives+[threshold]) or not max(positives) <= threshold < min(negatives):
                    raise EvidenceError('Uncalibrated/overlapping threshold')
                tolerance = policy.get('channelTolerance', 0)
            metrics, overlay = compare(normalized, expected, assertion.get('regions'), assertion.get('ignore'), tolerance)
            row.update(metrics=metrics, method=method, policy=policy, reference=provenance)
            put(folder/'diff.png', png_bytes(overlay))
            side = Image.new('RGB', (960, 240))
            for x, image in ((0, expected), (320, normalized), (640, overlay)):
                side.paste(image, (x, 0))
            put(folder/'comparison.png', png_bytes(side))
            match = metrics['changed'] == 0
            if method == 'bounded-difference':
                match = metrics['ratio'] <= policy['maxRatio']
            if method == 'structure':
                row['features'] = structure(normalized, assertion['features'])
                match = all(x['matches'] for x in row['features'])
            if method == 'temporal':
                sequence = assertion['frames']
                if not isinstance(sequence, list) or len(sequence) > 64:
                    raise EvidenceError('Frame sequence exceeds bounds')
                frames = []
                frame_records = []
                for index, frame in enumerate(sequence):
                    image, raw = png(child(root, frame['file']), frame['sha256'])
                    frame_image, _ = normalize(image, frame.get('geometry'))
                    put(folder/f'frame-{index:02}.png', raw)
                    if kind == 'native-import':
                        frame_capture = child(root, frame['capture'])
                        frame_capture_raw = read(frame_capture, MAX_JSON)
                        if digest(frame_capture_raw) != frame['captureSha256']:
                            raise EvidenceError('Sequence capture sidecar hash mismatch')
                        frame_metadata = decode_json(frame_capture_raw)
                        if frame_metadata['imageSha256'] != frame['sha256']:
                            raise EvidenceError('Sequence frame hash mismatch')
                        capture_status(frame_metadata, image)
                        frame_records.append(frame_metadata)
                        put_json(folder/f'frame-{index:02}-capture-private.json', frame_metadata)
                    frames.append((frame['elapsedMs'], frame_image))
                if kind == 'native-import':
                    first = frame_records[0] if frame_records else None
                    previous_end = None
                    for index, item in enumerate(frame_records):
                        start = datetime.fromisoformat(item['startedUtc'].replace('Z', '+00:00'))
                        end = datetime.fromisoformat(item['finishedUtc'].replace('Z', '+00:00'))
                        if previous_end is not None and start <= previous_end:
                            raise EvidenceError('Duplicate/overlapping native captures')
                        if any(item[k] != first[k] for k in ('pid', 'runnerSha256', 'clientSize', 'dpi')):
                            raise EvidenceError('Sequence process/geometry changed')
                        baseline = datetime.fromisoformat(first['startedUtc'].replace('Z', '+00:00'))
                        if abs((start-baseline).total_seconds()*1000-sequence[index]['elapsedMs']) > 1:
                            raise EvidenceError('Sequence elapsed time contradicts capture receipts')
                        previous_end = end
                state, reason = temporal(frames, expected, assertion['timeoutMs'], assertion['stableFrames'])
                match = state == 'PASS'
                row['timing'] = [{ 'elapsedMs': f['elapsedMs'], 'sha256': f['sha256']} for f in sequence]
                row['reason'] = reason
            row['result'] = 'PASS' if match else 'NEEDS_REVIEW'
            if method != 'temporal':
                row['reason'] = 'Defined visual contract satisfied; no gameplay inference' if match else 'Unexpected layout, glyph, cursor or screen difference; inspect comparison'
            row['actual'] = metrics
        if (provenance['kind'] == 'proxy' or (provenance['font'] == 'native-en' and provenance['kind'] not in ('private-authentic', 'independently-reviewed'))) and row['result'] == 'PASS':
            row.update(result='NEEDS_REVIEW', reason='Proxy font/reference cannot establish authoritative native glyph rendering')
        if kind == 'native-import':
            state,reason=store_capture_record(assertion,root,actual,folder)
            row.update(result=state,reason=reason)
        row['actualSha256'] = assertion['actualSha256']
        row['evidenceSource'] = assertion['actual']
        row['ignoredRegions'] = assertion.get('ignore', [])
        row['comparedRegions'] = assertion.get('regions', [])
        row['expectedCondition'] = 'Versioned visual contract only'
    except (EvidenceError, KeyError, TypeError, ValueError, OverflowError) as error:
        row.update(result='INVALID_EVIDENCE', reason=str(error) if isinstance(error, EvidenceError) else 'Malformed/incomplete visual contract')
    row['question'] = 'Judge only visible rendering, clipping, glyphs and cursor geometry. Do not infer gameplay, internal state or Steam history.'
    return row


def contracts():
    return load_json(ROOT/'tools/runtime/screen-contracts.json')['scenarios']


def verify(manifest_path, output):
    manifest_path = no_links(manifest_path)
    manifest_raw = read(manifest_path, MAX_JSON)
    manifest = decode_json(manifest_raw)
    if type(manifest.get('schema')) is not int or manifest.get('schema') != 1 or manifest.get('kind') not in ('synthetic', 'native-import'):
        raise EvidenceError('Unsupported manifest schema/kind')
    run_id = token(manifest['runId'])
    assertions = manifest.get('assertions')
    if not isinstance(assertions, list) or not 1 <= len(assertions) <= 256:
        raise EvidenceError('Expected 1..256 assertions')
    if any(not isinstance(a, dict) or type(a.get('mandatory', True)) is not bool for a in assertions):
        raise EvidenceError('Expected assertion objects')
    ids = [token(a['id']) for a in assertions]
    if len(ids) != len(set(ids)):
        raise EvidenceError('Duplicate assertion ID')
    scenario_map = contracts()
    reserved = {identifier: scenario for scenario, contract in scenario_map.items() for identifier in contract['requiredAssertions']}
    safety_ids = {scenario+'-safety' for scenario in scenario_map}
    for a in assertions:
        if a.get('scenario') not in scenario_map:
            raise EvidenceError('Unknown smoke scenario')
        if a['id'] in safety_ids or (a['id'] in reserved and reserved[a['id']] != a['scenario']):
            raise EvidenceError('Reserved scenario assertion identity/safety scope mismatch')
    output = no_links(output)
    if output.exists():
        raise EvidenceError('Run output must be new')
    output.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    no_links(output.parent)
    stage = Path(tempfile.mkdtemp(prefix='.screen-', dir=output.parent))
    budget = WRITE_BUDGET.set([MAX_RUN_BYTES, 4096])
    try:
        (stage/'review').mkdir(mode=0o700)
        (stage/'decisions').mkdir(mode=0o700)
        rows = []
        seen = {}
        # Deterministic observations run first, regardless of caller ordering.
        ordered = [a for a in assertions if a.get('kind') != 'visual'] + [a for a in assertions if a.get('kind') == 'visual']
        for a in ordered:
            if a.get('kind') == 'visual':
                # Equivalent contract+actual evidence groups deterministically;
                # all assertion identities remain recorded, no frames discarded.
                key = digest(canonical({k:v for k,v in a.items() if k != 'id'}))
                review_id = 'r-'+key[:24]
                if key in seen:
                    row = dict(seen[key], id=a['id'])
                else:
                    folder = stage/'review'/review_id
                    folder.mkdir(mode=0o700)
                    row = visual(a, manifest_path.parent, manifest['kind'], folder)
                    row['reviewId'] = review_id
                    put_json(folder/'metadata.json', row)
                    seen[key] = row
            else:
                row = deterministic(a, manifest_path.parent)
            row.update(scenario=a['scenario'], mandatory=a.get('mandatory', True) is not False)
            rows.append(row)
        # A supplied subset never silently completes an entire scenario.
        for scenario in sorted({a['scenario'] for a in assertions}):
            required = scenario_map[scenario]['requiredAssertions']
            for a in assertions:
                if a['scenario'] == scenario and a['id'] in required:
                    if a.get('kind') != required[a['id']] or a.get('mandatory', True) is not True:
                        raise EvidenceError('Required assertion kind/mandatory scope mismatch')
            supplied = {a['id'] for a in rows if a['scenario'] == scenario}
            for identifier in required:
                if identifier not in supplied:
                    rows.append(dict(result(identifier, 'gameplay' if identifier.endswith('behavior') else 'precondition', 'NOT_RUN', 'Required scenario evidence not supplied'), scenario=scenario, mandatory=True))
            if manifest['kind'] == 'native-import':
                rows.append(dict(result(scenario+'-safety', 'precondition', 'BLOCKED', 'No same-account isolation/safety approval; default Run remains NO-GO. Experimental consent is not an account-safety assertion'), scenario=scenario, mandatory=True))
        inventories = {}
        for file in sorted(stage.rglob('*')):
            if file.is_file():
                inventories[file.relative_to(stage).as_posix()] = digest(read(file))
        # Original manifest stays private; exports never copy its free-form fields.
        identities = manifest.get('identities', {})
        if not isinstance(identities, dict) or set(identities) - {'sourceSha256', 'candidateSha256', 'runnerSha256', 'generatedSha256'} or any(not valid_sha(v) for v in identities.values()):
            raise EvidenceError('Invalid build identity hashes')
        record = dict(schema=1, runId=run_id, kind=manifest['kind'], manifestSha256=digest(manifest_raw), identities=identities,
                      contractsSha256=digest(read(ROOT/'tools/runtime/screen-contracts.json')),
                      assertions=rows, evidence=inventories, limitations=['Offline visual contracts do not prove game behavior or Steam account isolation.'])
        put_json(stage/'manifest-private.json', manifest)
        record['evidence']['manifest-private.json'] = digest(read(stage/'manifest-private.json'))
        put_json(stage/'summary.json', record)
        # Seal summary separately. Neither hashes nor local review files establish
        # authenticity against an attacker who can rewrite the entire run directory.
        put(stage/'summary.sha256', (digest(read(stage/'summary.json'))+'\n').encode())
        no_links(output)
        if output.exists():
            raise EvidenceError('Output appeared concurrently')
        stage.rename(output)
        return summarize(output)
    except BaseException:
        if stage.exists():
            shutil.rmtree(stage)
        raise
    finally:
        WRITE_BUDGET.reset(budget)


def open_run(run):
    run = no_links(run)
    raw = read(run/'summary.json', MAX_JSON)
    if read(run/'summary.sha256', 128).decode('ascii').strip() != digest(raw):
        raise EvidenceError('Run summary integrity mismatch')
    data = decode_json(raw)
    found = set()
    for index, path in enumerate(Path(run).rglob('*')):
        if index > 10000:
            raise EvidenceError('Run tree exceeds bounds')
        no_links(path)
        if path.is_file():
            relative = path.relative_to(run).as_posix()
            if relative not in ('summary.json', 'summary.sha256', '.review-lock') and not relative.startswith('decisions/'):
                found.add(relative)
    if found != set(data['evidence']):
        raise EvidenceError('Unexpected or missing evidence files')
    for name, expected in data['evidence'].items():
        if digest(read(child(run, name))) != expected:
            raise EvidenceError('Stored evidence changed')
    return data


def decisions(run, data):
    directory = no_links(Path(run)/'decisions')
    records = []
    prior = None
    for file in sorted(directory.iterdir()):
        if file.name != f'{len(records)+1:06}.json':
            raise EvidenceError('Unexpected review record')
        raw = read(file, MAX_JSON)
        record = decode_json(raw)
        if record['sequence'] != len(records)+1 or record['previous'] != prior or record['summarySha256'] != digest(read(Path(run)/'summary.json')):
            raise EvidenceError('Review history chain mismatch')
        if record['reviewId'] not in {x.get('reviewId') for x in data['assertions']} or record['decision'] not in DECISIONS or record['reviewerType'] not in ('human', 'ai'):
            raise EvidenceError('Invalid decision scope/provenance')
        records.append(record)
        prior = digest(raw)
    return records


def summarize(run):
    data = open_run(run)
    history = decisions(run, data)
    rows = []
    for source in data['assertions']:
        row = dict(source, automaticResult=source['result'], automaticReason=source['reason'])
        matching = [r for r in history if r['reviewId'] == row.get('reviewId')]
        if matching and row['scope'] == 'visual' and row['result'] in ('PASS', 'NEEDS_REVIEW'):
            latest = matching[-1]
            row['reviewDecision'] = latest['decision']
            row['result'] = {'accepted':('PASS' if row.get('reviewableAsPass', True) else 'NEEDS_REVIEW'), 'defect':'FAIL', 'uncertain':'NEEDS_REVIEW', 'invalid':'INVALID_EVIDENCE', 'recapture':'NEEDS_REVIEW'}[latest['decision']]
            row['reason'] = 'Scoped reviewer judgment; automatic verdict retained'
            row['independent'] = False
        rows.append(row)
    return dict(runId=data['runId'], kind=data['kind'], result=aggregate(rows), assertions=rows,
                scenarios={s:aggregate([r for r in rows if r['scenario'] == s]) for s in sorted({r['scenario'] for r in rows})},
                decisions=len(history), nativeGameplay='NOT_RUN')


def record_review(run, review_id, decision, reviewer_type, reviewer, request_id, supersedes=None):
    token(review_id); token(reviewer); token(request_id)
    if supersedes is not None:
        token(supersedes)
    if decision not in DECISIONS or reviewer_type not in ('human', 'ai'):
        raise EvidenceError('Unsupported review conclusion/provenance')
    run = no_links(run)
    # Exclusive lock; stale locks require explicit private investigation/removal.
    lock = run/'.review-lock'
    put(lock, b'Exclusive review writer\n')
    try:
        data = open_run(run)
        history = decisions(run, data)
        for old in history:
            if old['requestId'] == request_id:
                if (old['reviewId'], old['decision'], old['reviewerType'], old['reviewer'], old['supersedes']) != (review_id, decision, reviewer_type, reviewer, supersedes):
                    raise EvidenceError('Request ID conflict')
                return summarize(run)
        targets = [r for r in data['assertions'] if r.get('reviewId') == review_id]
        if not targets or any(r['scope'] != 'visual' or r['result'] in ('INVALID_EVIDENCE', 'BLOCKED', 'FAIL', 'NOT_RUN') for r in targets):
            raise EvidenceError('Review cannot override invalid, failed or nonvisual evidence; recapture into a new run')
        prior = [r for r in history if r['reviewId'] == review_id]
        if (prior and supersedes != prior[-1]['requestId']) or (not prior and supersedes is not None):
            raise EvidenceError('Existing decision needs explicit --supersedes request ID')
        previous = digest(read(run/'decisions'/f'{len(history):06}.json')) if history else None
        row = dict(sequence=len(history)+1, previous=previous, reviewId=review_id, decision=decision,
                   reviewerType=reviewer_type, reviewer=reviewer, requestId=request_id,
                   supersedes=supersedes, recordedUtc=datetime.now(timezone.utc).isoformat(),
                   summarySha256=digest(read(run/'summary.json')))
        put_json(run/'decisions'/f'{len(history)+1:06}.json', row)
        return summarize(run)
    finally:
        lock.unlink()


def report(run, output):
    data = summarize(run)
    parts = ['<!doctype html><meta charset="utf-8"><title>ROUTEKEEPER private visual review</title>',
             '<style>body{background:#111;color:#eee;font:16px monospace}img{max-width:100%;image-rendering:pixelated}pre{white-space:pre-wrap}</style>',
             '<h1>Private visual review — gameplay NOT_RUN</h1>', '<pre>'+html.escape(json.dumps(data, ensure_ascii=False, indent=2))+'</pre>']
    for identifier in sorted({r.get('reviewId') for r in data['assertions']} - {None}):
        parts.append('<h2>'+html.escape(identifier)+'</h2>')
        for name in ('comparison.png', 'actual.png'):
            path = Path(run)/'review'/identifier/name
            if path.exists():
                # Self-contained report: no external URL, script, or live API.
                import base64
                parts.append('<img alt="expected / actual / changed pixels" src="data:image/png;base64,'+base64.b64encode(read(path)).decode('ascii')+'">')
                break
    put(output, '\n'.join(parts).encode('utf-8'))


def export_review(run, output, confirm_private_images=False):
    if not confirm_private_images:
        raise EvidenceError('Explicit --confirm-private-images required; images may reveal private pixels')
    data = summarize(run)
    original = open_run(run)
    output = no_links(output)
    if output.exists():
        raise EvidenceError('Export must be a new directory')
    output.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    stage = Path(tempfile.mkdtemp(prefix='.screen-export-', dir=output.parent))
    try:
        cases = []
        for review_id in sorted({r.get('reviewId') for r in data['assertions']} - {None}):
            rows = [r for r in data['assertions'] if r.get('reviewId') == review_id]
            folder = stage/review_id
            folder.mkdir(mode=0o700)
            files = {}
            for name in ('expected.png', 'actual.png', 'normalized.png', 'diff.png', 'comparison.png'):
                source = Path(run)/'review'/review_id/name
                if source.exists():
                    raw = read(source)
                    # Reencode pixels only, removing PNG ancillary/private metadata.
                    image, _ = png(source, digest(raw))
                    raw = png_bytes(image)
                    put(folder/name, raw)
                    files[name] = digest(raw)
            cases.append(dict(reviewId=review_id, scenarios=sorted({r['scenario'] for r in rows}),
                              assertionIds=[r['id'] for r in rows], files=files,
                              metrics=[r.get('metrics') for r in rows],
                              references=[{k:r.get('reference', {}).get(k) for k in ('kind','locale','font','scene')} for r in rows],
                              comparisonScope=[dict(method=r.get('method'), regions=r.get('comparedRegions', []),
                                                    ignoredRects=[x['rect'] for x in r.get('ignoredRegions', [])],
                                                    exclusionReason='Explicit contract exclusions; private free-form explanations are not exported.',
                                                    thresholdVersion=r.get('calibration', {}).get('version'),
                                                    maxRatio=r.get('policy', {}).get('maxRatio') if r.get('method') == 'bounded-difference' else 0,
                                                    channelTolerance=r.get('metrics', {}).get('tolerance'),
                                                    frameTiming=r.get('timing', [])) for r in rows],
                              referenceSourceHashes=[sorted(r.get('reference', {}).get('sourceHashes', {}).values()) for r in rows],
                              automaticResults=[r['automaticResult'] for r in rows],
                              automaticReasons=[r['automaticReason'] for r in rows],
                              question='Judge visible clipping, missing glyphs, layout and cursor only. Do not infer internal game state, event timing or Steam history.',
                              limitations=['Pixels are not automatically redacted. Inspect before external sharing.', 'Proxy references are not authoritative native English glyph evidence.']))
        put_json(stage/'packet.json', dict(schema=1, cases=cases, identities=original.get('identities', {}), nativeGameplay='NOT_RUN', uploadPerformed=False))
        no_links(output)
        if output.exists():
            raise EvidenceError('Export output appeared concurrently')
        stage.rename(output)
    except BaseException:
        if stage.exists():
            shutil.rmtree(stage)
        raise


def generate_reference(output, locale='ko', scene='menu', selection=0):
    """Reuse owned preview geometry and licensed bitmap assets; never game art."""
    sys.path.insert(0, str(ROOT/'integration/ui'))
    from preview import Renderer, localization
    locales = localization.enabled()
    index = next((i for i, row in enumerate(locales) if row['tag'] == locale), None)
    if index is None:
        raise EvidenceError('Locale not enabled')
    if type(selection) is not int or not 0 <= selection < (len(locales) if scene == 'languages' else 7):
        raise EvidenceError('Selection outside scene')
    renderer = Renderer(index)
    if scene == 'menu': renderer.menu(selection)
    elif scene == 'languages': renderer.languages(selection)
    elif scene == 'warning': renderer.warning(11, True)
    elif scene == 'hud': renderer.hud(renderer.text('no_objective'))
    else: raise EvidenceError('Unsupported reference scene')
    # The picker can draw fonts from every enabled locale. Bind the complete
    # maintained preview recipe, including native advances and fallback catalog,
    # rather than merely the currently selected atlas.
    sources = {'tools/screen_verify.py', 'tools/localization.py', 'integration/ui/preview.py',
               'integration/ui/generate.py', 'integration/ui/catalog.json', 'integration/ui/english-metrics.json',
               'locales/languages.json', 'locales/fonts.json', 'locales/en.json',
               'integration/assets/ui-font.png', 'integration/assets/ui-font.tsv'}
    fonts = localization.font_sources()
    for language in locales:
        sources.add(f'locales/{language["tag"]}.json')
        if fonts[language['font']]['kind'] != 'native':
            sources.update(f'integration/assets/fonts/{language["font"]}/ui-font.{suffix}' for suffix in ('png','tsv'))
    source_hashes = {p:digest(read(ROOT/p)) for p in sorted(sources)}
    output = no_links(output)
    if output.exists():
        raise EvidenceError('Reference output must be new')
    output.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix='.screen-ref-', dir=output.parent))
    try:
        put(stage/'reference.png', png_bytes(renderer.image.convert('RGB')))
        font = renderer.locale['font']
        put_json(stage/'reference.json', dict(file='reference.png', sha256=digest(read(stage/'reference.png')),
                  provenance=dict(source='ROUTEKEEPER offline Renderer', generatorVersion='screen-v1', sourceHashes=source_hashes,
                                  runtimeVersions=dict(python=sys.version.split()[0], pillow=pillow_version, zlib=zlib.ZLIB_RUNTIME_VERSION),
                                  locale=locale, font=font, scene=scene, parameters={'selection':selection},
                                  kind='proxy' if renderer.font['kind'] == 'native' else 'synthetic',
                                  limitations=['Shared-source agreement is not independent behavioral evidence.'],
                                  glyphRuns=[dict(x=x,y=y,width=w,height=h,text=text) for x,y,w,h,text in renderer.runs],
                                  metrics=dict(lineHeight=renderer.line_height, usedCodepoints=sorted({ord(c) for *_,text in renderer.runs for c in text})))))
        no_links(output)
        if output.exists():
            raise EvidenceError('Reference output appeared concurrently')
        stage.rename(output)
    except BaseException:
        if stage.exists():
            shutil.rmtree(stage)
        raise



def prepare_import(capture, reference, scenario, output):
    """Bind existing private capture and reference, without launching anything."""
    if scenario not in contracts():
        raise EvidenceError('Unknown scenario')
    capture = no_links(capture)
    raw = read(capture)
    sidecar = no_links(str(capture)+'.json')
    metadata = load_json(sidecar)
    image, _ = png(capture, metadata['imageSha256'])
    capture_status(metadata, image)
    ref = load_json(no_links(reference)/'reference.json')
    reference_provenance(ref['provenance'])
    expected_path = child(reference, ref['file'])
    _, expected_raw = png(expected_path, ref['sha256'])
    output = no_links(output)
    if output.exists():
        raise EvidenceError('Import directory must be new')
    output.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    stage = Path(tempfile.mkdtemp(prefix='.screen-import-', dir=output.parent))
    try:
        put(stage/'actual.png', raw)
        put_json(stage/'capture.json', metadata)
        put(stage/'expected.png', expected_raw)
        ref['file'] = 'expected.png'
        assertion = dict(id=scenario+'-visual', scenario=scenario, kind='visual', actual='actual.png',
                         actualSha256=digest(raw), capture='capture.json', captureSha256=digest(read(stage/'capture.json')),
                         reference=ref, method='exact')
        put_json(stage/'input.json', dict(schema=1, kind='native-import', runId='import-'+digest(raw)[:20], assertions=[assertion]))
        no_links(output)
        if output.exists():
            raise EvidenceError('Import directory appeared concurrently')
        stage.rename(output)
    except BaseException:
        if stage.exists():
            shutil.rmtree(stage)
        raise


def demo(output):
    """Complete owned synthetic fixture, usable by the real CLI/review workflow."""
    output = no_links(output)
    if output.exists():
        raise EvidenceError('Demo directory must be new')
    output.mkdir(mode=0o700, parents=True)
    generate_reference(output/'reference', 'ko', 'menu', 2)
    ref = load_json(output/'reference/reference.json')
    image, _ = png(output/'reference/reference.png', ref['sha256'])
    image.putpixel((100, 100), (255, 0, 255))
    put(output/'actual.png', png_bytes(image))
    ref['file'] = 'reference/reference.png'
    put(output/'synthetic-candidate.txt', b'Owned synthetic integrity fixture; not a game binary.\n')
    assertions = [dict(id='korean-visual', scenario='korean', kind='visual', method='exact', actual='actual.png', actualSha256=digest(read(output/'actual.png')), reference=ref),
                  dict(id='candidate-integrity', scenario='korean', kind='file-sha256', file='synthetic-candidate.txt', expected=digest(read(output/'synthetic-candidate.txt'))),
                  dict(id='korean-font', scenario='korean', kind='unobservable')]
    put_json(output/'input.json',dict(schema=1,kind='synthetic',runId='owned-demo',assertions=assertions))
    return verify(output/'input.json',output/'run')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('demo'); p.add_argument('--output', type=Path, required=True)
    p = sub.add_parser('prepare-import'); p.add_argument('--capture', type=Path, required=True); p.add_argument('--reference', type=Path, required=True); p.add_argument('--scenario', choices=tuple(contracts()), required=True); p.add_argument('--output', type=Path, required=True)
    p = sub.add_parser('verify'); p.add_argument('--manifest', type=Path, required=True); p.add_argument('--output', type=Path, required=True); p.add_argument('--require-pass', action='store_true')
    for name in ('review-list', 'summary'):
        p = sub.add_parser(name); p.add_argument('--run', type=Path, required=True)
    p = sub.add_parser('report'); p.add_argument('--run', type=Path, required=True); p.add_argument('--output', type=Path, required=True)
    p = sub.add_parser('review-export'); p.add_argument('--run', type=Path, required=True); p.add_argument('--output', type=Path, required=True); p.add_argument('--confirm-private-images', action='store_true')
    p = sub.add_parser('review'); p.add_argument('--run', type=Path, required=True); p.add_argument('--case', required=True); p.add_argument('--decision', choices=DECISIONS, required=True); p.add_argument('--reviewer-type', choices=('human','ai'), required=True); p.add_argument('--reviewer', required=True); p.add_argument('--request-id', required=True); p.add_argument('--supersedes')
    p = sub.add_parser('reference'); p.add_argument('--output', type=Path, required=True); p.add_argument('--locale', default='ko'); p.add_argument('--scene', choices=('menu','languages','warning','hud'), default='menu'); p.add_argument('--selection', type=int, default=0)
    args = parser.parse_args()
    try:
        if args.command == 'demo': data = demo(args.output)
        elif args.command == 'prepare-import': prepare_import(args.capture, args.reference, args.scenario, args.output); data = {'import':'prepared-private','gameplay':'NOT_RUN'}
        elif args.command == 'verify': data = verify(args.manifest, args.output)
        elif args.command in ('summary', 'review-list'):
            data = summarize(args.run)
            if args.command == 'review-list':
                pending = [r for r in data['assertions'] if r['result'] in ('NEEDS_REVIEW','INVALID_EVIDENCE')]
                groups = {}
                for row in pending:
                    groups.setdefault(row['scenario']+' / '+row['reason'], []).append({'id':row['id'], 'reviewId':row.get('reviewId'), 'result':row['result']})
                data = {'cases':pending, 'groups':groups, 'nativeGameplay':'NOT_RUN'}
        elif args.command == 'report': report(args.run, args.output); data = {'report':'written-private'}
        elif args.command == 'review-export': export_review(args.run, args.output, args.confirm_private_images); data = {'export':'written-locally', 'uploaded':False}
        elif args.command == 'review': data = record_review(args.run, args.case, args.decision, args.reviewer_type, args.reviewer, args.request_id, args.supersedes)
        else: generate_reference(args.output, args.locale, args.scene, args.selection); data = {'reference':'written', 'nativeGameplay':'NOT_RUN'}
        print(json.dumps(data, ensure_ascii=False, sort_keys=True, indent=2))
        return 1 if getattr(args, 'require_pass', False) and data.get('result') != 'PASS' else 0
    except (EvidenceError, OSError, KeyError, TypeError, ValueError) as error:
        print(json.dumps({'result':'INVALID_EVIDENCE','reason':str(error)}), file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
