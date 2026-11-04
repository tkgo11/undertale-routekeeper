"""Disposable synthetic tests for private compiler workspaces; no game/CLI launched."""
import contextlib
import hashlib
import importlib.util
import io
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('validation', Path(__file__).with_name('validate-authentic.py'))
validation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validation)


class PrivateValidation(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.source = self.root / 'synthetic.win'
        self.source.write_bytes(b'SYNTHETIC ORIGINAL ONLY')
        self.original_hash = hashlib.sha256(self.source.read_bytes()).hexdigest()
        self.work = self.root / '.research' / 'validation'
        self.calls = []
        self.version = '0.9.2.0+synthetic\n'

    def invoke(self, work=None):
        args = ['validate-authentic.py', '--input', str(self.source), '--cli', 'synthetic-compiler', '--work', str(work or self.work)]
        with patch.object(validation, 'ROOT', self.root), patch.object(validation, 'ORIGINAL_SHA256', self.original_hash), patch.object(sys, 'argv', args), patch.object(validation.subprocess, 'run', self.compiler), contextlib.redirect_stdout(io.StringIO()):
            validation.main()

    def compiler(self, cmd, **kwargs):
        self.calls.append(cmd)
        code = 0
        if cmd[1] == '--version':
            text = self.version
        else:
            text = 'PRIVATE DIAGNOSTIC MUST NOT REACH ORDINARY OUTPUT\n'
            if '-o' in cmd:
                source = Path(cmd[2]); output = Path(cmd[cmd.index('-o') + 1])
                if source == output or source.name == 'routekeeper-data.win':
                    code = 1
                else:
                    output.write_bytes(b'SYNTHETIC PATCH ONLY')
        if hasattr(kwargs.get('stdout'), 'write'):
            kwargs['stdout'].write(text)
        return subprocess.CompletedProcess(cmd, code, text, '')

    def test_system_temp_alias_only_canonicalizes_owned_fixture(self):
        physical = self.root / 'physical-temp'; physical.mkdir()
        alias = self.root / 'temp-alias'
        try:
            alias.symlink_to(physical, target_is_directory=True)
        except OSError:
            self.skipTest('Native symlink privilege unavailable')
        probe = PrivateValidation('test_repeated_runs_preserve_private_evidence')
        try:
            with patch.object(tempfile, 'tempdir', str(alias)):
                probe.setUp()
            self.assertEqual(probe.root, probe.root.resolve())
            probe.test_repeated_runs_preserve_private_evidence()
        finally:
            probe.doCleanups()

    def test_outside_private_root_refused_before_compiler(self):
        outside = self.root / 'artifacts' / 'must-not-create'
        with self.assertRaises((ValueError, SystemExit)):
            self.invoke(outside)
        self.assertFalse(self.calls)
        self.assertFalse(outside.exists())

    def test_linked_old_summary_cannot_overwrite_input(self):
        self.work.mkdir(parents=True)
        link = self.work / 'summary.json'
        try:
            link.symlink_to(self.source)
        except OSError:
            self.skipTest('Native symlink privilege unavailable')
        self.invoke()
        self.assertEqual(hashlib.sha256(self.source.read_bytes()).hexdigest(), self.original_hash)
        self.assertTrue(link.is_symlink())
        self.assertEqual(len(list(self.work.glob('run-*/summary.json'))), 1)

    def test_linked_work_ancestor_refused_before_compiler(self):
        self.work.parent.mkdir(parents=True)
        target = self.root / 'other'; target.mkdir()
        try:
            self.work.symlink_to(target, target_is_directory=True)
        except OSError:
            self.skipTest('Native symlink privilege unavailable')
        with self.assertRaises((ValueError, SystemExit)):
            self.invoke()
        self.assertFalse(self.calls)
        self.assertEqual(list(target.iterdir()), [])

    def test_repeated_runs_preserve_private_evidence(self):
        self.invoke(); self.invoke()
        reports = list(self.work.glob('run-*/summary.json'))
        self.assertEqual(len(reports), 2)
        self.assertEqual(hashlib.sha256(self.source.read_bytes()).hexdigest(), self.original_hash)
        self.assertEqual(list(self.work.glob('run-*/authentic-*')), [])

    def test_version_limit_precedes_whitespace_trimming(self):
        self.version = '0.9.2.0' + ' ' * 10000
        with self.assertRaises(SystemExit):
            self.invoke()
        self.assertEqual(len(self.calls), 1)


if __name__ == '__main__':
    unittest.main()
