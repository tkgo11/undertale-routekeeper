"""Disposable synthetic bootstrap tests; never authentic game evidence."""
import copy
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image

import native_bootstrap as b
import native_gameplay as n
import screen_verify as s


class Bootstrap(unittest.TestCase):
    def setUp(self):
        base = s.ROOT / '.research/windows-20261029-bootstrap'
        base.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix='synthetic-', dir=base)
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.data = self.root / 'data.win'
        s.put(self.data, b'SYNTHETIC_NOT_GAME_DATA')
        patched = patch.object(b.e.lab, 'DATA_SHA', s.hash_file(self.data))
        patched.start(); self.addCleanup(patched.stop)
        self.recipe = dict(schema=1, id='synthetic-test', version='v1', case='original',
                           captures={'before': 'before.png', 'after': 'after.png'},
                           sourceProvenance='SYNTHETIC_TEST_NOT_NATIVE', startingState='SYNTHETIC_TEST_NOT_GAMEPLAY',
                           actionHistory=[dict(source='operator-observation', before='before', after='after',
                                               action='confirm', holdMs=50, startedUtc='2026-01-01T00:00:01.1Z',
                                               finishedUtc='2026-01-01T00:00:01.2Z')],
                           steps=[dict(scenario='startup', before='before', after='after', action='confirm',
                                       holdMs=50, timeoutMs=1000, maxFrames=5, stableFrames=2)])
        for name, color in [('before', 'black'), ('after', 'white')]:
            file = self.root / (name + '.png')
            s.put(file, s.png_bytes(Image.new('RGB', (640, 480), color)))
            s.put_json(Path(str(file) + '.json'), dict(schema=1, method='CopyFromScreen',
                       imageSha256=s.hash_file(file), clientSize=[640, 480], foregroundBefore=True,
                       foregroundAfter=True, pid=42, ownerPid=42, windowHandle=1234,
                       runnerSha256=b.e.lab.RUNNER_SHA, expectedRunnerSha256=b.e.lab.RUNNER_SHA,
                       processStartedUtc='2026-01-01T00:00:00Z',
                       startedUtc='2026-01-01T00:00:0' + ('1' if name == 'before' else '2') + 'Z',
                       finishedUtc='2026-01-01T00:00:0' + ('1' if name == 'before' else '2') + '.001Z', dpi=192))
        self.path = self.root / 'recipe.json'
        self.save()
        self.output = self.root / 'intake'

    def save(self):
        self.path.write_bytes(s.canonical(self.recipe))

    def intake(self):
        return b.intake(self.path, self.data, self.output)

    def accepted(self):
        self.intake()
        return b.review(self.output, 'synthetic-human-claim', 'r1', 'accepted', True, True)

    def test_valid_flow_preserves_native_pixels_and_never_certifies_gameplay(self):
        manifest = self.intake()
        self.assertEqual(manifest['result'], 'NEEDS_REVIEW')
        with self.assertRaises(b.e.StopRun):
            n.load_plan(self.output / 'proposed-plan.json', 'original')
        b.review(self.output, 'synthetic-human-claim', 'r1', 'accepted', True, True)
        result = b.export(self.output, 'r1', self.root / 'export')
        self.assertEqual(result['gameplay'], 'UNVERIFIED')
        plan = n.load_plan(self.root / 'export/native-plan.json', 'original')
        self.assertEqual(plan['scenes']['before']['space'], 'client-pixels')
        self.assertEqual(s.read(self.root / 'before.png'), s.read(self.root / 'export/references/before.png'))

    def test_missing_window_identity_and_changed_process_refused(self):
        sidecar = self.root / 'after.png.json'
        original = s.load_json(sidecar)
        for changes in ({'windowHandle': None}, {'pid': 99, 'ownerPid': 99}, {'windowHandle': 5432},
                        {'processStartedUtc': '2026-01-01T00:00:02Z'}):
            altered = dict(original, **changes)
            sidecar.write_bytes(s.canonical(altered))
            with self.assertRaises(s.EvidenceError):
                b.inspect(self.path, self.data)

    def test_exact_data_runner_and_screenshot_hashes_required(self):
        self.data.write_bytes(b'WRONG')
        with self.assertRaisesRegex(s.EvidenceError, 'data identity'):
            b.inspect(self.path, self.data)
        self.data.write_bytes(b'SYNTHETIC_NOT_GAME_DATA')
        sidecar = self.root / 'after.png.json'
        original = s.load_json(sidecar)
        for changes in ({'runnerSha256': 'a' * 64, 'expectedRunnerSha256': 'a' * 64},
                        {'imageSha256': 'b' * 64}):
            sidecar.write_bytes(s.canonical(dict(original, **changes)))
            with self.assertRaises(s.EvidenceError):
                b.inspect(self.path, self.data)

    def test_unsafe_actions_scenarios_paths_and_budgets_refused(self):
        original = copy.deepcopy(self.recipe)
        for mutation in [lambda r: r['steps'][0].update(action='save'),
                         lambda r: r['steps'][0].update(scenario='forced'),
                         lambda r: r['steps'][0].update(maxFrames=True),
                         lambda r: r['steps'][0].update(holdMs=501),
                         lambda r: r['captures'].update(before='../outside.png'),
                         lambda r: r['steps'][0].update(stableFrames=8)]:
            self.recipe = copy.deepcopy(original); mutation(self.recipe); self.save()
            with self.assertRaises(s.EvidenceError):
                b.inspect(self.path, self.data)

    def test_scope_provenance_and_actions_review_required(self):
        self.intake()
        for provenance, actions in [(False, True), (True, False), (False, False)]:
            with self.assertRaisesRegex(s.EvidenceError, 'separate provenance'):
                b.review(self.output, 'human', 'r1', 'accepted', provenance, actions)
        b.review(self.output, 'human', 'r1', 'uncertain', True, True)
        with self.assertRaises(s.EvidenceError):
            b.export(self.output, 'r1', self.root / 'export')

    def test_review_immutable_and_output_never_overwritten(self):
        self.accepted()
        with self.assertRaises(s.EvidenceError):
            b.review(self.output, 'human', 'r1', 'accepted', True, True)
        b.export(self.output, 'r1', self.root / 'export')
        with self.assertRaises(s.EvidenceError):
            b.export(self.output, 'r1', self.root / 'export')
        with self.assertRaises(s.EvidenceError):
            self.intake()

    def test_mutated_capture_recipe_plan_and_manifest_refused_after_review(self):
        self.accepted()
        for relative in ['references/before.png', 'references/after.png.json', 'recipe.json',
                         'proposed-plan.json', 'bootstrap.json']:
            path = self.output / relative
            original = path.read_bytes(); path.write_bytes(b'MUTATED')
            with self.assertRaises(s.EvidenceError):
                b.export(self.output, 'r1', self.root / 'export')
            path.write_bytes(original)

    def test_public_output_and_duplicate_pixels_refused(self):
        with self.assertRaises(s.EvidenceError):
            b.private(s.ROOT / 'outputs/public')
        before = self.root / 'before.png'; after = self.root / 'after.png'
        after.write_bytes(before.read_bytes())
        metadata = s.load_json(self.root / 'after.png.json')
        metadata['imageSha256'] = s.hash_file(after)
        (self.root / 'after.png.json').write_bytes(s.canonical(metadata))
        with self.assertRaisesRegex(s.EvidenceError, 'distinct'):
            b.inspect(self.path, self.data)

    def test_old_sidecars_cannot_gain_a_fabricated_hwnd(self):
        path = self.root / 'before.png.json'
        metadata = s.load_json(path); del metadata['windowHandle']
        path.write_bytes(s.canonical(metadata))
        with self.assertRaisesRegex(s.EvidenceError, 'Actual HWND'):
            self.intake()
        self.assertFalse(self.output.exists())

    def test_missing_reordered_falsified_history_and_starting_state_refused(self):
        original = copy.deepcopy(self.recipe)
        for mutation in [lambda r: r.update(actionHistory=[]), lambda r: r.update(startingState=''),
                         lambda r: r['actionHistory'][0].update(action='left'),
                         lambda r: r['actionHistory'][0].update(startedUtc='2026-01-01T00:00:03Z'),
                         lambda r: r['actionHistory'][0].update(source='proof-from-scene-label')]:
            self.recipe = copy.deepcopy(original); mutation(self.recipe); self.save()
            with self.assertRaises(s.EvidenceError):
                b.inspect(self.path, self.data)


if __name__ == '__main__':
    unittest.main()
