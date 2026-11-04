"""Portable failure-injection contracts; all process/Win32 observations are mocked."""
import importlib.util
import json
from pathlib import Path
import tempfile
import types
import unittest
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location('guardian_contract', Path(__file__).parent / 'runtime/watchdog.py')
guardian = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guardian)


class GuardianFailures(unittest.TestCase):
    def test_only_explicit_human_kind_can_extend_absolute_deadline(self):
        for fields in ({'maximumSeconds': 301}, {'maximumSeconds': 7200, 'sessionKind': 'AUTOMATED'},
                       {'maximumSeconds': True, 'sessionKind': 'HUMAN_BETA'},
                       {'maximumSeconds': 59, 'sessionKind': 'HUMAN_BETA'},
                       {'maximumSeconds': 7201, 'sessionKind': 'HUMAN_BETA'},
                       {'maximumSeconds': 300.0, 'sessionKind': 'HUMAN_BETA'}):
            with self.subTest(fields=fields), tempfile.TemporaryDirectory() as temporary:
                path = Path(temporary).resolve() / 'config.json'
                path.write_text(json.dumps(dict(timeoutSeconds=1, **fields)), encoding='utf-8', newline='\n')
                with patch.object(guardian, 'Process') as process, self.assertRaisesRegex(ValueError, 'scoped absolute'):
                    guardian.run(path)
                process.assert_not_called()

    def exercise(self, fail_receipt=None, controller_alive=False, changed_target=False, linked_abort=False):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            identities = {1: dict(path='SYNTHETIC-CONTROLLER', ticks=1, sha256='a' * 64),
                          2: dict(path='SYNTHETIC-TARGET', ticks=2, sha256='b' * 64)}
            config = dict(timeoutSeconds=1, controller=dict(pid=1, **identities[1]), target=dict(pid=2, **identities[2]))
            path = root / 'config.json'; path.write_text(json.dumps(config), encoding='utf-8', newline='\n')
            events = []; state = dict(alive=True, target_reads=0)
            class Process:
                def __init__(self, pid, terminate=False): self.pid = pid
                def identity(self):
                    if self.pid == 2:
                        state['target_reads'] += 1
                        if changed_target and state['target_reads'] > 1: return dict(identities[2], ticks=999)
                    return identities[self.pid]
                def alive(self): return controller_alive if self.pid == 1 else state['alive']
                def stop(self): events.append('stop-target'); state['alive'] = False
                def close(self): events.append('close-' + str(self.pid))
            def publish(target, value):
                events.append(target.name)
                if target.name == fail_receipt: raise OSError('SYNTHETIC RECEIPT WRITE FAILURE')
            if linked_abort:
                (root / 'abort.request').symlink_to(root / 'unrelated')
            user = types.SimpleNamespace(GetAsyncKeyState=Mock(return_value=0))
            with patch.object(guardian, 'Process', Process), patch.object(guardian, 'publish', publish), patch.object(guardian, 'descendants', return_value=set()), patch.object(guardian.ctypes, 'WinDLL', return_value=user, create=True):
                with self.assertRaises((OSError, ValueError)):
                    guardian.run(path)
            return events, state

    def test_failed_stop_receipt_does_not_skip_owned_termination(self):
        events, state = self.exercise('stop.json')
        self.assertIn('stop-target', events); self.assertFalse(state['alive'])
        self.assertNotIn('result.json', events)

    def test_failed_result_receipt_still_closes_already_stopped_target(self):
        events, state = self.exercise('result.json')
        self.assertEqual(events.count('stop-target'), 1); self.assertFalse(state['alive'])

    def test_unarmed_failure_never_authorizes_termination(self):
        events, state = self.exercise('ready.json')
        self.assertNotIn('stop-target', events); self.assertTrue(state['alive'])

    def test_failed_log_cannot_terminate_changed_target_identity(self):
        events, state = self.exercise('stop.json', changed_target=True)
        self.assertNotIn('stop-target', events); self.assertTrue(state['alive'])

    @unittest.skipIf(__import__('os').name == 'nt', 'Portable symlink fixture; real Windows guard covered separately')
    def test_linked_abort_observer_failure_stops_only_the_verified_target(self):
        events, state = self.exercise(controller_alive=True, linked_abort=True)
        self.assertEqual(events.count('stop-target'), 1); self.assertFalse(state['alive'])


if __name__ == '__main__':
    unittest.main()
