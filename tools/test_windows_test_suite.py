"""Exercise real disposable suite children; never start Steam/game."""
import os
import base64
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import windows_test_suite as suite


class RunnerTests(unittest.TestCase):
    def run_child(self, code):
        with tempfile.TemporaryDirectory() as folder:
            return suite.run_one('fixture', [sys.executable, '-c', code], Path(folder), dict(os.environ))

    def test_nonzero_exit_is_failure(self):
        result = self.run_child('raise SystemExit(7)')
        self.assertEqual(result['result'], 'FAIL')
        self.assertEqual(result['exitCode'], 7)

    def test_compact_refusal_is_blocked(self):
        result = self.run_child('print(\'{"result":"BLOCKED"}\');raise SystemExit(2)')
        self.assertEqual(result['result'], 'BLOCKED')

    def test_fast_final_output_cannot_pass_budget(self):
        with patch.object(suite, 'MAX_LOG_BYTES', 512):
            result = self.run_child('print("X"*2048)')
        self.assertEqual(result['result'], 'FAIL')
        self.assertIn('budget', result['error'])

    def test_timeout_is_failure_not_success(self):
        with patch.object(suite, 'COMMAND_TIMEOUT', .2):
            result = self.run_child('import time;time.sleep(30)')
        self.assertEqual(result['result'], 'FAIL')
        self.assertEqual(result['descendantClosure'], 'UNVERIFIED_ON_TIMEOUT')

    def test_unittest_skip_is_preserved(self):
        result = self.run_child('print("Ran 3 tests in 0.1s\\nOK (skipped=1)")')
        self.assertEqual(result['unittestCases'], 3)
        self.assertEqual(result['skipped'], 1)

    def test_shell_module_path_reset_is_case_insensitive_and_local(self):
        environment = {'PSModulePath': 'foreign-edition-one',
                       'PSMODULEPATH': 'foreign-edition-two', 'KEEP_THIS': 'value'}
        for shell in ('powershell', 'pwsh', 'C:\\Windows\\powershell.EXE'):
            with self.subTest(shell=shell), tempfile.TemporaryDirectory() as folder:
                with patch.object(suite.subprocess, 'Popen') as popen:
                    popen.return_value.poll.return_value = 0
                    popen.return_value.wait.return_value = 0
                    result = suite.run_one('fixture', [shell, '-NoProfile'],
                                           Path(folder), environment)
                self.assertEqual(popen.call_args.kwargs['env'], {'KEEP_THIS': 'value'})
                self.assertEqual(result['shellModulePath'], 'REBUILT_BY_CHILD')
        self.assertEqual(environment['PSModulePath'], 'foreign-edition-one')
        self.assertEqual(environment['PSMODULEPATH'], 'foreign-edition-two')

    def test_python_child_keeps_non_shell_environment(self):
        with tempfile.TemporaryDirectory() as folder:
            environment = dict(os.environ, PSMODULEPATH='non-shell-fixture')
            result = suite.run_one('fixture', [sys.executable, '-c',
                                   'import os;print(os.environ["PSMODULEPATH"])'],
                                   Path(folder), environment)
            self.assertEqual(result['result'], 'PASS')
            self.assertEqual(result['shellModulePath'], 'INHERITED')
            self.assertEqual(Path(result['log']).read_text(encoding='utf-8').strip(),
                             'non-shell-fixture')

    @unittest.skipUnless(os.name == 'nt' and shutil.which('powershell') and shutil.which('pwsh'),
                         'Actual Windows PowerShell5.1/7 module isolation')
    def test_native_ps51_imports_own_security_with_ps7_parent_path(self):
        ps7_home = subprocess.check_output(['pwsh', '-NoProfile', '-Command', '$PSHOME'],
                                          text=True).strip()
        legacy_home = Path(os.environ['WINDIR']) / 'System32/WindowsPowerShell/v1.0'
        environment = dict(os.environ, PSMODULEPATH=os.pathsep.join(
            [str(Path(ps7_home) / 'Modules'), str(legacy_home / 'Modules')]))
        command = ('$ErrorActionPreference="Stop"; '
                   'Import-Module Microsoft.PowerShell.Security -ErrorAction Stop; '
                   'Get-Command Get-FileHash,Get-Acl -ErrorAction Stop | Out-Null; '
                   'Write-Output "SECURITY_IMPORT_PASS"')
        encoded = base64.b64encode(command.encode('utf-16-le')).decode('ascii')
        with tempfile.TemporaryDirectory() as folder:
            result = suite.run_one('fixture', ['powershell', '-NoProfile', '-NonInteractive',
                                   '-EncodedCommand', encoded], Path(folder), environment)
            self.assertEqual(result['result'], 'PASS', Path(result['log']).read_bytes())
            self.assertIn(b'SECURITY_IMPORT_PASS', Path(result['log']).read_bytes())


if __name__ == '__main__':
    unittest.main()
