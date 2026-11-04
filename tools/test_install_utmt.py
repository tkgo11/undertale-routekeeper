"""Disposable compiler-install path contracts; no download or compiler execution."""
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
import zipfile

spec = importlib.util.spec_from_file_location('installer', Path(__file__).with_name('install-utmt.py'))
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallPaths(unittest.TestCase):
    def exercise(self, destination, entry='UndertaleModCli', wrong_hash=False):
        with tempfile.TemporaryDirectory() as temporary:
            archive = Path(temporary) / 'synthetic.zip'
            with zipfile.ZipFile(archive, 'w') as zipped: zipped.writestr(entry, 'SYNTHETIC COMPILER FIXTURE; NEVER EXECUTED')
            raw = archive.read_bytes(); calls = []
            expected = '0' * 64 if wrong_hash else hashlib.sha256(raw).hexdigest()
            def command(arguments, **kwargs):
                calls.append(arguments)
                if arguments[0] == 'gh': (Path(arguments[-1]) / 'synthetic.zip').write_bytes(raw)
                return subprocess.CompletedProcess(arguments, 0)
            with patch.object(installer.platform, 'system', return_value='Linux'), patch.object(installer.platform, 'machine', return_value='x86_64'), patch.dict(installer.ASSETS, {('Linux', 'x86_64'): ('synthetic.zip', expected)}), patch.object(installer.subprocess, 'run', command), patch.object(sys, 'argv', ['install-utmt.py', '--directory', str(destination)]), contextlib.redirect_stdout(io.StringIO()):
                installer.main()
            return calls

    def test_regular_new_destination(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve(); calls = self.exercise(root / 'tool')
            self.assertEqual(len(calls), 2); self.assertTrue((root / 'tool/UndertaleModCli').is_file())

    @unittest.skipIf(__import__('os').name == 'nt', 'Portable symlink permission fixture')
    def test_linked_ancestor_refuses_before_any_download_or_write(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve(); outside = root / 'outside'; outside.mkdir()
            alias = root / 'alias'; alias.symlink_to(outside, target_is_directory=True)
            with self.assertRaises(ValueError): self.exercise(alias / 'tool')
            self.assertEqual(list(outside.iterdir()), [])

    def test_archive_traversal_refuses_new_output(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            with self.assertRaises((ValueError, SystemExit)): self.exercise(root / 'tool', '../escape')
            self.assertFalse((root / 'escape').exists()); self.assertFalse((root / 'tool').exists())

    def test_wrong_checksum_refuses_extraction(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            with self.assertRaises(SystemExit): self.exercise(root / 'tool', wrong_hash=True)
            self.assertFalse((root / 'tool').exists())


if __name__ == '__main__':
    unittest.main()
