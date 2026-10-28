"""Independent disposable saved-state fixtures; no live game or personal saves."""
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import save_observer as observer
import screen_verify as s


class SaveObserver(unittest.TestCase):
    def setUp(self):
        root = s.ROOT / '.research/windows-20261029-observer-tests'
        root.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix='synthetic-', dir=root)
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.lines = ['SYNTHETIC'] + ['0.000000'] * 548
        self.lines[1] = '1.000000'; self.lines[2] = '20.000000'
        self.lines[30+202] = '7.000000'
        self.lines[542] = '16.500000'
        self.lines[547] = '12.000000'; self.lines[548] = '12345.000000'
        self.file = self.root / 'file0'
        self.file.write_bytes(self.raw())

    def raw(self, newline='\n'):
        return (newline.join(self.lines) + newline).encode('utf-8')

    def test_source_derived_positions_and_no_current_hp_claim(self):
        result = observer.parse_snapshot(self.raw())
        self.assertEqual(result['level'], 1); self.assertEqual(result['experience'], 0)
        self.assertEqual(result['kills'], 0); self.assertEqual(result['maxHp'], '20.000000')
        self.assertEqual(result['flags']['202'], '7.000000')
        self.assertEqual(result['plot'], '16.500000'); self.assertEqual(result['room'], 12)
        self.assertNotIn('currentHp', result)

    def test_crlf_bom_and_no_final_newline_are_supported(self):
        expected = observer.parse_snapshot(self.raw())
        self.assertEqual(observer.parse_snapshot(self.raw('\r\n')), expected)
        self.assertEqual(observer.parse_snapshot(b'\xef\xbb\xbf' + self.raw()), expected)
        self.assertEqual(observer.parse_snapshot(self.raw()[:-1]), expected)

    def test_all_original_level_threshold_boundaries(self):
        for level, threshold in enumerate(observer.THRESHOLDS, 2):
            self.lines[1] = str(level); self.lines[9] = str(threshold)
            self.assertEqual(observer.parse_snapshot(self.raw())['level'], level)
            self.lines[1] = str(level-1); self.lines[9] = str(threshold-1)
            self.assertEqual(observer.parse_snapshot(self.raw())['level'], level-1)

    def test_partial_unknown_extra_binary_and_bad_newline_refused(self):
        for raw in (b'partial', self.raw() + b'UNEXPECTED\n', self.raw().replace(b'SYNTHETIC', b'bad\0name'),
                    self.raw().replace(b'\n', b'\r'), self.raw().replace(b'20.000000', b'NaN'), b'x' * (s.MAX_JSON+1)):
            with self.assertRaises(s.EvidenceError):
                observer.parse_snapshot(raw)

    def test_falsified_inconsistent_or_outside_supported_domain_refused(self):
        for index, value in [(1, '20'), (9, '10'), (9, '-1'), (9, '100000'),
                             (11, '-1'), (1, '1.5'), (2, '0'), (548, '-1'),
                             (40, '1e9999'), (40, '9' * 65)]:
            before = self.lines[index]; self.lines[index] = value
            with self.assertRaises(s.EvidenceError):
                observer.parse_snapshot(self.raw())
            self.lines[index] = before

    def test_modified_snapshot_and_missing_digest_refused(self):
        expected = s.hash_file(self.file)
        with patch.object(observer, 'source_contract', return_value=observer.SOURCES):
            self.file.write_bytes(self.raw() + b'changed')
            with self.assertRaisesRegex(s.EvidenceError, 'expected digest'):
                observer.observe(self.file, expected, self.root / 'unused', self.root)
            with self.assertRaisesRegex(s.EvidenceError, 'expected snapshot'):
                observer.observe(self.file, None, self.root / 'unused', self.root)

    def test_observation_never_certifies_gameplay_or_authenticity(self):
        with patch.object(observer, 'source_contract', return_value=observer.SOURCES):
            result = observer.observe(self.file, s.hash_file(self.file), self.root / 'unused', self.root)
        self.assertEqual(result['liveState'], 'UNVERIFIED')
        self.assertEqual(result['snapshotAuthenticity'], 'UNVERIFIED')
        self.assertEqual(result['forcedSideEffects'], 'UNVERIFIED')
        self.assertEqual(result['currentHp'], 'UNAVAILABLE_NOT_SERIALIZED')
        self.assertEqual(result['loadResetFlags'], [94, 360, 361, 362, 363, 364])

    def test_changed_source_and_wrong_original_refused(self):
        with patch.object(s, 'hash_file', return_value='0' * 64):
            with self.assertRaisesRegex(s.EvidenceError, 'original data'):
                observer.source_contract(self.file, self.root)
        hashes = iter([observer.lab.DATA_SHA, *['0' * 64 for _ in observer.SOURCES]])
        with patch.object(s, 'hash_file', side_effect=lambda _: next(hashes)):
            with self.assertRaisesRegex(s.EvidenceError, 'source changed'):
                observer.source_contract(self.file, self.root)

    def test_live_or_non_file0_path_refused(self):
        with self.assertRaises(s.EvidenceError):
            observer.private_snapshot(s.ROOT / 'private-data/personal/file0')
        with self.assertRaises(s.EvidenceError):
            observer.private_snapshot(self.root / 'file9')


if __name__ == '__main__':
    unittest.main()
