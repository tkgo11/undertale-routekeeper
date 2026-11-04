"""Synthetic failure-injection tests for the authentic path harness, not game evidence."""
import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('path_harness', Path(__file__).with_name('test-patch-paths.py'))
harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)


class PathHarness(unittest.TestCase):
    def exercise(self, reject_all=False, wrong_reason=False):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve(); (root/'profiles').mkdir()
            source = root/'synthetic.win'; source.write_bytes(b'SYNTHETIC ORIGINAL ONLY')
            candidate = b'SYNTHETIC CANDIDATE ONLY'
            original_sha = hashlib.sha256(source.read_bytes()).hexdigest()
            (root/'profiles/registry.json').write_text(json.dumps([dict(OriginalSha256=original_sha, PatchedSha256=hashlib.sha256(candidate).hexdigest())]), encoding='utf-8', newline='\n')
            def compiler(arguments, **kwargs):
                if reject_all:
                    kwargs['stdout'].write(b'SYNTHETIC COMPILER PARSE FAILURE'); return subprocess.CompletedProcess(arguments, 1)
                path = Path(arguments[2])
                if path.parent.name == 'control':
                    if '-o' in arguments: Path(arguments[arguments.index('-o')+1]).write_bytes(candidate)
                    return subprocess.CompletedProcess(arguments, 0)
                message = 'SYNTHETIC UNRELATED SCRIPT FAILURE' if wrong_reason else 'Compiler scratch output must be new; existing evidence is retained.'
                kwargs['stdout'].write(message.encode('utf-8')); return subprocess.CompletedProcess(arguments, 1)
            captured = io.StringIO()
            with patch.object(harness, 'ROOT', root), patch.object(harness, 'PIN', original_sha), patch.object(harness.subprocess, 'run', compiler), patch.object(sys, 'argv', ['test-patch-paths.py', '--input', str(source), '--cli', 'SYNTHETIC', '--case', 'scratch-file']), contextlib.redirect_stdout(captured):
                harness.main()
            return captured.getvalue()

    def test_reject_all_compiler_is_not_a_refusal_pass(self):
        with self.assertRaisesRegex(RuntimeError, 'positive compile control'): self.exercise(reject_all=True)

    def test_unrelated_failure_is_not_the_expected_safety_refusal(self):
        with self.assertRaisesRegex(RuntimeError, 'missing intended path refusal'): self.exercise(wrong_reason=True)

    def test_explicitly_synthetic_control_then_expected_refusal(self):
        self.assertIn('PASS source-identified refusal', self.exercise())


if __name__ == '__main__':
    unittest.main()
