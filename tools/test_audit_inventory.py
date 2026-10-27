"""Synthetic content drift tests; no repository creation or game access."""
import copy
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import audit_inventory as audit


class Inventory(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'source.txt').write_text('REVIEWED SYNTHETIC ONLY', encoding='utf-8', newline='\n')
        self.paths = {'source.txt', audit.MANIFEST}
        self.row = dict(path='source.txt', method='MANUAL_FULL_TEXT', inspection='COMPLETE', verification='PASS', **audit.facts(self.root, 'source.txt'))
        self.manifest = dict(files=[self.row, dict(path=audit.MANIFEST, method='SELF_MANIFEST_FULL_SET_CHECK', inspection='COMPLETE')],
                             files_count=2, coverage_counts={'MANUAL_FULL_TEXT': 1, 'SELF_MANIFEST_FULL_SET_CHECK': 1})

    def check(self, manifest=None, reviewed=None):
        with patch.object(audit, 'tracked', return_value=self.paths), patch.object(audit.subprocess, 'check_output', return_value=b'baseline-head\n'):
            return audit.reconcile(self.root, manifest or self.manifest, reviewed)

    def test_complete_set_and_content(self):
        self.assertEqual(self.check(), self.manifest)

    def test_unreviewed_changes_cannot_be_blessed_by_refresh(self):
        (self.root / 'source.txt').write_text('CHANGED', encoding='utf-8', newline='\n')
        with self.assertRaises(ValueError): self.check()
        with self.assertRaises(ValueError): self.check(reviewed=set())
        fresh = self.check(reviewed={'source.txt'})
        self.check(fresh)
        self.assertNotEqual(fresh['files'][1]['sha256'], self.row['sha256'])

    def test_missing_extra_duplicate_and_incomplete_records_refused(self):
        for change in ['missing', 'extra', 'duplicate', 'incomplete']:
            m = copy.deepcopy(self.manifest)
            if change == 'missing': m['files'].pop()
            if change == 'extra': m['files'].append(dict(path='../not-a-tracked-file'))
            if change == 'duplicate': m['files'].append(dict(self.row))
            if change == 'incomplete': m['files'][0]['inspection'] = 'NOT_REVIEWED'
            with self.subTest(change=change), self.assertRaises(ValueError): self.check(m)


if __name__ == '__main__':
    unittest.main()
