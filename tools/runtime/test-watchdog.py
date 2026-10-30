"""Native Windows guardian tests using owned harmless Python sleeper processes."""
import importlib.util
import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import unittest
import uuid

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('watchdog', HERE / 'watchdog.py')
watchdog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(watchdog)
EVIDENCE = HERE.parents[1] / '.research/windows-20261029-watchdog'
EXE = str(Path(sys._base_executable).with_name('pythonw.exe'))  # No launcher/console-host descendants.


@unittest.skipUnless(os.name == 'nt', 'Actual Windows process API test')
class WatchdogTests(unittest.TestCase):
    def setUp(self):
        self.root = EVIDENCE / uuid.uuid4().hex
        self.root.mkdir(parents=True)
        self.children = []
        self.retained = []
        self.logs = []
        self.controller = self.sleeper()
        self.target = self.sleeper()
        self.unrelated = self.sleeper()
        self.config = {'schema': 1, 'timeoutSeconds': 1,
                       'controller': self.identity(self.controller), 'target': self.identity(self.target)}
        self.guardian = None

    def sleeper(self):
        child = subprocess.Popen([EXE, '-c', 'import time;time.sleep(90)'], creationflags=subprocess.CREATE_NO_WINDOW)
        self.children.append(child)
        return child

    def identity(self, child):
        process = watchdog.Process(child.pid)
        try:
            return {'pid': child.pid, **process.identity()}
        finally:
            process.close()

    def start(self, ready=True):
        (self.root / 'config.json').write_text(json.dumps(self.config), encoding='utf-8', newline='\n')
        self.heartbeat(0)
        log = (self.root / 'stderr.log').open('wb')
        self.logs.append(log)
        self.guardian = subprocess.Popen([EXE, str(HERE / 'watchdog.py'), '--config', str(self.root / 'config.json')],
                                         stdout=subprocess.DEVNULL, stderr=log, creationflags=subprocess.CREATE_NO_WINDOW)
        self.children.append(self.guardian)
        if ready:
            self.wait_file('ready.json')

    def heartbeat(self, sequence):
        new = self.root / 'heartbeat.new'
        new.write_text(json.dumps({'sequence': sequence}), encoding='utf-8', newline='\n')
        os.replace(new, self.root / 'heartbeat.json')

    def wait_file(self, name):
        until = time.monotonic() + 12
        while not (self.root / name).exists():
            if time.monotonic() >= until:
                self.fail('Missing watchdog evidence: ' + name)
            time.sleep(.05)
        return json.loads((self.root / name).read_text(encoding='utf-8'))

    def tearDown(self):
        for process in self.children:
            if process.poll() is None:
                process.kill()
            process.wait(timeout=10)
        for process in self.retained:
            try:
                process.stop()
            finally:
                process.close()
        for output in self.logs:
            output.close()
        # Keep owned fixtures/logs as private reproducible evidence, never delete arbitrary trees.

    def stopped(self, reason):
        self.guardian.wait(timeout=12)
        self.assertEqual(self.guardian.returncode, 0)
        self.assertEqual(self.wait_file('result.json')['reason'], reason)
        self.target.wait(timeout=5)
        self.assertIsNone(self.unrelated.poll())

    def test_stale_heartbeat_stops_only_owned_target(self):
        self.start()
        self.stopped('stale-heartbeat')

    def test_controller_death_stops_owned_target(self):
        self.config['timeoutSeconds'] = 10
        self.start()
        self.controller.kill()
        self.controller.wait(timeout=5)
        self.stopped('controller-exited')

    def test_abort_file_stops_owned_target(self):
        self.start()
        (self.root / 'abort.request').write_text('{}', encoding='utf-8', newline='\n')
        self.stopped('emergency-stop')

    def test_heartbeat_extends_only_while_progressing(self):
        self.start()
        for sequence in range(1, 8):
            self.heartbeat(sequence)
            time.sleep(.2)
            self.assertIsNone(self.target.poll())
        self.stopped('stale-heartbeat')

    def test_normal_target_exit_receipt(self):
        self.start()
        self.target.terminate()
        self.target.wait(timeout=5)
        self.guardian.wait(timeout=10)
        self.assertEqual(self.wait_file('result.json')['result'], 'OWNED_PROCESS_EXITED')
        self.assertIsNone(self.unrelated.poll())

    def test_start_time_mismatch_refuses_termination(self):
        self.config['target']['ticks'] += 1
        self.start(ready=False)
        self.guardian.wait(timeout=10)
        self.assertNotEqual(self.guardian.returncode, 0)
        self.assertEqual(self.wait_file('failure.json')['result'], 'REFUSED')
        self.assertIsNone(self.target.poll())

    def test_runner_hash_mismatch_refuses_termination(self):
        self.config['target']['sha256'] = '0' * 64
        self.start(ready=False)
        self.guardian.wait(timeout=10)
        self.assertNotEqual(self.guardian.returncode, 0)
        self.assertIsNone(self.target.poll())

    def test_controller_identity_mismatch_refuses(self):
        self.config['controller']['ticks'] += 1
        self.start(ready=False)
        self.guardian.wait(timeout=10)
        self.assertNotEqual(self.guardian.returncode, 0)
        self.assertIsNone(self.target.poll())

    def test_premature_disarm_cannot_leave_target_running(self):
        self.start()
        (self.root / 'disarm.request').write_text('{}', encoding='utf-8', newline='\n')
        self.stopped('premature-disarm')

    def test_hardlinked_control_file_refused(self):
        source = self.root / 'source.json'
        source.write_text('{}', encoding='utf-8', newline='\n')
        destination = self.root / 'linked.json'
        os.link(source, destination)
        with self.assertRaisesRegex(ValueError, 'Hardlinked'):
            watchdog.safe_path(destination)

    def test_unchanged_sequence_cannot_extend_deadline(self):
        self.start()
        for _ in range(15):
            self.heartbeat(0)
            time.sleep(.1)
        self.stopped('stale-heartbeat')

    def test_invalid_heartbeat_stops_owned_target(self):
        self.start()
        self.heartbeat('fabricated')
        self.stopped('invalid-heartbeat')
        stop = self.wait_file('stop.json')
        receipt = self.wait_file('result.json')
        self.assertEqual(stop['heartbeatError'], receipt['heartbeatError'])
        self.assertEqual(receipt['heartbeatError']['type'], 'ValueError')
        self.assertEqual(receipt['heartbeatError']['message'], 'Invalid heartbeat sequence')

    def test_hardlinked_heartbeat_stops_with_specific_diagnostic(self):
        self.config['timeoutSeconds'] = 10
        self.start()
        # The replacement is valid JSON but has an unsafe filesystem identity.
        # Diagnostics must distinguish this from a fabricated sequence without
        # relaxing the owned-target stop or unrelated-process boundary.
        source = self.root / 'heartbeat-source.json'
        source.write_text('{"sequence": 1}', encoding='utf-8', newline='\n')
        linked = self.root / 'heartbeat.linked'
        os.link(source, linked)
        os.replace(linked, self.root / 'heartbeat.json')
        self.stopped('invalid-heartbeat')
        stop = self.wait_file('stop.json')
        receipt = self.wait_file('result.json')
        self.assertEqual(stop['heartbeatError'], receipt['heartbeatError'])
        self.assertEqual(receipt['heartbeatError']['type'], 'ValueError')
        self.assertEqual(receipt['heartbeatError']['message'], 'Hardlinked watchdog file refused')
        self.assertIsNone(receipt['heartbeatError']['winerror'])

    def lock_heartbeat(self):
        api = ctypes.WinDLL('kernel32', use_last_error=True)
        api.CreateFileW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                                   wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE]
        api.CreateFileW.restype = wintypes.HANDLE
        api.CloseHandle.argtypes = [wintypes.HANDLE]
        handle = api.CreateFileW(str(self.root / 'heartbeat.json'), 0x80000000, 0, None, 3, 0, None)
        if handle == wintypes.HANDLE(-1).value:
            raise ctypes.WinError(ctypes.get_last_error())
        return api, handle

    def test_short_windows_sharing_gap_does_not_fabricate_progress(self):
        self.start()
        api, handle = self.lock_heartbeat()
        try:
            time.sleep(.3)
            self.assertIsNone(self.target.poll())
        finally:
            api.CloseHandle(handle)
        self.heartbeat(1)
        time.sleep(.3)
        self.assertIsNone(self.target.poll())
        self.stopped('stale-heartbeat')

    def test_windows_sharing_gap_cannot_extend_stale_deadline(self):
        self.start()
        api, handle = self.lock_heartbeat()
        try:
            self.stopped('stale-heartbeat')
        finally:
            api.CloseHandle(handle)

    def test_wrong_path_refuses_termination(self):
        self.config['target']['path'] = str(self.root / 'other.exe')
        self.start(ready=False)
        self.guardian.wait(timeout=10)
        self.assertNotEqual(self.guardian.returncode, 0)
        self.assertIsNone(self.target.poll())

    def test_controller_cannot_be_termination_target(self):
        self.config['target'] = self.config['controller']
        self.start(ready=False)
        self.guardian.wait(timeout=10)
        self.assertNotEqual(self.guardian.returncode, 0)
        self.assertIsNone(self.controller.poll())

    def test_unknown_descendant_is_preserved(self):
        fixture = self.root / 'fixture.py'
        fixture.write_text('import json, pathlib, subprocess, sys, time\n'
                           'p=subprocess.Popen([sys.executable,"-c","import time;time.sleep(90)"])\n'
                           'pathlib.Path(sys.argv[1]).write_text(json.dumps({"pid":p.pid}),encoding="utf-8")\n'
                           'time.sleep(90)\n', encoding='utf-8', newline='\n')
        self.target = subprocess.Popen([EXE, str(fixture), str(self.root / 'child.json')],
                                        creationflags=subprocess.CREATE_NO_WINDOW)
        self.children.append(self.target)
        child = watchdog.Process(self.wait_file('child.json')['pid'], terminate=True)
        self.retained.append(child)
        self.config['target'] = self.identity(self.target)
        self.start()
        self.stopped('unexpected-descendant')
        self.assertTrue(child.alive())

    def test_natural_target_exit_with_unknown_child_blocks_recovery(self):
        fixture = self.root / 'natural-parent.py'
        fixture.write_text('import json, os, pathlib, subprocess, sys, time\n'
                           'root=pathlib.Path(sys.argv[1])\n'
                           'while not (root/"exit.request").exists():time.sleep(.01)\n'
                           'p=subprocess.Popen([sys.executable,"-c","import time;time.sleep(90)"])\n'
                           '(root/"child.json").write_text(json.dumps({"pid":p.pid}),encoding="utf-8")\n'
                           'os._exit(0)\n', encoding='utf-8', newline='\n')
        self.target = subprocess.Popen([EXE, str(fixture), str(self.root)],
                                        creationflags=subprocess.CREATE_NO_WINDOW)
        self.children.append(self.target)
        self.config['target'] = self.identity(self.target)
        self.start()
        (self.root / 'exit.request').write_text('{}', encoding='utf-8', newline='\n')
        child_pid = self.wait_file('child.json')['pid']
        child = watchdog.Process(child_pid, terminate=True)
        self.retained.append(child)
        self.guardian.wait(timeout=10)
        receipt = self.wait_file('result.json')
        self.assertNotEqual(receipt['result'], 'OWNED_PROCESS_EXITED')
        self.assertIn(child_pid, receipt['descendants'])
        self.assertTrue(child.alive())

    def test_actual_parent_crash_leaves_guardian_running_to_stop_target(self):
        fixture = self.root / 'controller.py'
        fixture.write_text(
            'import json, os, pathlib, subprocess, sys, time\n'
            'sys.path.insert(0,sys.argv[1])\nimport watchdog\n'
            'root=pathlib.Path(sys.argv[2])\n'
            'target=subprocess.Popen([sys.executable,"-c","import time;time.sleep(90)"])\n'
            'def identity(pid):\n p=watchdog.Process(pid)\n try:return {"pid":pid,**p.identity()}\n finally:p.close()\n'
            'config={"schema":1,"timeoutSeconds":10,"controller":identity(os.getpid()),"target":identity(target.pid)}\n'
            '(root/"config.json").write_text(json.dumps(config),encoding="utf-8")\n'
            'guardian=subprocess.Popen([sys.executable,str(pathlib.Path(sys.argv[1])/"watchdog.py"),"--config",str(root/"config.json")])\n'
            '(root/"family.json").write_text(json.dumps({"target":target.pid,"guardian":guardian.pid}),encoding="utf-8")\n'
            'time.sleep(90)\n', encoding='utf-8', newline='\n')
        parent = subprocess.Popen([EXE, str(fixture), str(HERE), str(self.root)],
                                   creationflags=subprocess.CREATE_NO_WINDOW)
        self.children.append(parent)
        family = self.wait_file('family.json')
        target = watchdog.Process(family['target'], terminate=True)
        guardian = watchdog.Process(family['guardian'], terminate=True)
        self.retained.extend([target, guardian])
        self.wait_file('ready.json')
        parent.kill()
        parent.wait(timeout=5)
        self.assertEqual(self.wait_file('result.json')['reason'], 'controller-exited')
        self.assertFalse(target.alive())
        self.assertIsNone(self.unrelated.poll())


if __name__ == '__main__':
    program = unittest.main(verbosity=2, exit=False)
    result = program.result
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    summary = EVIDENCE / ('suite-' + uuid.uuid4().hex + '.json')
    summary.write_text(json.dumps({'schema': 1, 'kind': 'HARMLESS_NATIVE_WATCHDOG',
                                  'tests': result.testsRun, 'fail': len(result.failures),
                                  'errors': len(result.errors), 'skipped': len(result.skipped),
                                  'gameExecuted': False}), encoding='utf-8', newline='\n')
    print('Private native watchdog summary: ' + str(summary))
    sys.exit(0 if result.wasSuccessful() else 1)
