"""Independent Windows owned-process guardian; never restores saves or stops Steam.

Retained process handles bind termination to the checked kernel process object,
not a PID lookup. Heartbeats are liveness hints, not account isolation proof.
"""
import argparse
import ctypes
from ctypes import wintypes
import hashlib
import json
import os
from pathlib import Path
import stat
import time

DOTNET_EPOCH = 504911232000000000


class ProcessEntry(ctypes.Structure):
    _fields_ = [('size', wintypes.DWORD), ('usage', wintypes.DWORD), ('pid', wintypes.DWORD),
                ('heap', ctypes.c_size_t), ('module', wintypes.DWORD), ('threads', wintypes.DWORD),
                ('parent', wintypes.DWORD), ('priority', wintypes.LONG), ('flags', wintypes.DWORD),
                ('name', wintypes.WCHAR * 260)]


def descendants(parent_pid, known):
    """Best-effort native census. Unknown descendants are recorded, never killed."""
    api = ctypes.WinDLL('kernel32', use_last_error=True)
    api.CreateToolhelp32Snapshot.argtypes = [wintypes.DWORD, wintypes.DWORD]
    api.CreateToolhelp32Snapshot.restype = wintypes.HANDLE
    api.Process32FirstW.argtypes = [wintypes.HANDLE, ctypes.POINTER(ProcessEntry)]
    api.Process32NextW.argtypes = [wintypes.HANDLE, ctypes.POINTER(ProcessEntry)]
    api.CloseHandle.argtypes = [wintypes.HANDLE]
    snapshot = api.CreateToolhelp32Snapshot(2, 0)
    if snapshot == wintypes.HANDLE(-1).value:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        entry = ProcessEntry()
        entry.size = ctypes.sizeof(entry)
        rows = []
        more = api.Process32FirstW(snapshot, ctypes.byref(entry))
        while more:
            rows.append((entry.pid, entry.parent))
            if len(rows) > 20000:
                raise ValueError('Process census budget exceeded')
            more = api.Process32NextW(snapshot, ctypes.byref(entry))
        if ctypes.get_last_error() != 18:
            raise ctypes.WinError(ctypes.get_last_error())
        result = set(known)
        changed = True
        while changed:
            changed = False
            for pid, parent in rows:
                if pid != parent_pid and (parent == parent_pid or parent in result) and pid not in result:
                    result.add(pid)
                    changed = True
        return result
    finally:
        api.CloseHandle(snapshot)


def safe_path(path, allow_hardlinks=False):
    path = Path(os.path.abspath(path))
    for part in reversed((path, *path.parents)):
        try:
            info = part.lstat()
        except FileNotFoundError:
            continue
        if stat.S_ISLNK(info.st_mode) or getattr(info, 'st_file_attributes', 0) & 0x400:
            raise ValueError('Linked watchdog path refused')
        if stat.S_ISREG(info.st_mode) and info.st_nlink != 1 and not allow_hardlinks:
            raise ValueError('Hardlinked watchdog file refused')
    return path


class Process:
    def __init__(self, pid, terminate=False):
        if os.name != 'nt':
            raise OSError('Watchdog requires native Windows')
        self.api = ctypes.WinDLL('kernel32', use_last_error=True)
        self.api.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
        self.api.OpenProcess.restype = wintypes.HANDLE
        self.api.CloseHandle.argtypes = [wintypes.HANDLE]
        self.api.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
        self.api.WaitForSingleObject.restype = wintypes.DWORD
        self.api.QueryFullProcessImageNameW.argtypes = [wintypes.HANDLE, wintypes.DWORD, wintypes.LPWSTR, ctypes.POINTER(wintypes.DWORD)]
        self.api.GetProcessTimes.argtypes = [wintypes.HANDLE, *([ctypes.POINTER(wintypes.FILETIME)] * 4)]
        self.api.TerminateProcess.argtypes = [wintypes.HANDLE, wintypes.UINT]
        self.handle = self.api.OpenProcess(0x1000 | 0x100000 | (1 if terminate else 0), False, pid)
        if not self.handle:
            raise ctypes.WinError(ctypes.get_last_error())

    def identity(self):
        size = wintypes.DWORD(32768)
        buffer = ctypes.create_unicode_buffer(size.value)
        if not self.api.QueryFullProcessImageNameW(self.handle, 0, buffer, ctypes.byref(size)):
            raise ctypes.WinError(ctypes.get_last_error())
        times = [wintypes.FILETIME() for _ in range(4)]
        if not self.api.GetProcessTimes(self.handle, *(ctypes.byref(value) for value in times)):
            raise ctypes.WinError(ctypes.get_last_error())
        created = (times[0].dwHighDateTime << 32) | times[0].dwLowDateTime
        # Windows system executables legitimately have WinSxS hardlinks. This
        # read-only hash never mutates them; control/evidence files stay single-link.
        path = safe_path(buffer.value, allow_hardlinks=True)
        return {'path': str(path), 'ticks': created + DOTNET_EPOCH,
                'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}

    def alive(self):
        result = self.api.WaitForSingleObject(self.handle, 0)
        if result not in (0, 258):
            raise OSError('Cannot determine owned process liveness')
        return result == 258

    def stop(self):
        if self.alive() and not self.api.TerminateProcess(self.handle, 197):
            raise ctypes.WinError(ctypes.get_last_error())
        if self.api.WaitForSingleObject(self.handle, 5000) != 0:
            raise TimeoutError('Owned process termination did not complete')

    def close(self):
        if self.handle:
            self.api.CloseHandle(self.handle)
            self.handle = None


def matches(actual, expected):
    return (os.path.normcase(actual['path']) == os.path.normcase(expected['path'])
            and actual['ticks'] == expected['ticks']
            and actual['sha256'] == expected['sha256'])


def publish(path, value):
    path = safe_path(path)
    with path.open('x', encoding='utf-8', newline='\n') as output:
        json.dump(value, output, sort_keys=True)
        output.flush()
        os.fsync(output.fileno())


def run(config_path):
    config_path = safe_path(config_path)
    config = json.loads(config_path.read_text(encoding='utf-8'))
    root = safe_path(config_path.parent)
    timeout = config['timeoutSeconds']
    if type(timeout) not in (int, float) or not 1 <= timeout <= 30:
        raise ValueError('Invalid heartbeat timeout')
    if config['controller']['pid'] == config['target']['pid']:
        raise ValueError('Controller cannot be termination target')
    controller = Process(config['controller']['pid'])
    target = None
    try:
        target = Process(config['target']['pid'], terminate=True)
        if not matches(controller.identity(), config['controller']) or not matches(target.identity(), config['target']):
            raise ValueError('Process identity mismatch; no termination authorized')
        publish(root / 'ready.json', {'schema': 1, 'pid': os.getpid(), 'target': config['target'], 'startedUtc': time.time()})
        last_heartbeat = time.monotonic()
        started = last_heartbeat
        sequence = -1
        observed_descendants = set()
        user = ctypes.WinDLL('user32', use_last_error=True)
        user.GetAsyncKeyState.argtypes = [ctypes.c_int]
        user.GetAsyncKeyState.restype = ctypes.c_short
        while target.alive():
            reason = None
            heartbeat_error = None
            try:
                observed_descendants = descendants(config['target']['pid'], observed_descendants)
                if observed_descendants:
                    reason = 'unexpected-descendant'
            except (OSError, ValueError):
                reason = 'descendant-census-unverified'
            if not controller.alive():
                reason = 'controller-exited'
            elif user.GetAsyncKeyState(19) & 0x8000:
                reason = 'pause-emergency-stop'
            elif time.monotonic() - started >= 300:
                reason = 'absolute-session-timeout'
            elif safe_path(root / 'abort.request').exists():
                reason = 'emergency-stop'
            elif safe_path(root / 'disarm.request').exists():
                # Disarm is accepted only once the owned process has actually exited.
                reason = 'premature-disarm'
            elif not reason:
                try:
                    heartbeat = json.loads(safe_path(root / 'heartbeat.json').read_text(encoding='utf-8'))
                    current = heartbeat['sequence']
                    if type(current) is not int or current < sequence:
                        raise ValueError('Invalid heartbeat sequence')
                    if current > sequence:
                        sequence = current
                        last_heartbeat = time.monotonic()
                except (FileNotFoundError, json.JSONDecodeError):
                    pass  # A bounded atomic-publication gap cannot extend the deadline.
                except (OSError, KeyError, TypeError, ValueError) as error:
                    # ReplaceFile can briefly make the published path unreadable
                    # on Windows. No observed progress means no deadline extension.
                    # CPython's text open can expose EACCES without winerror.
                    sharing_gap = (os.name == 'nt' and isinstance(error, PermissionError)
                                   and (getattr(error, 'winerror', None) in (5, 32)
                                        or (getattr(error, 'winerror', None) is None and error.errno == 13)))
                    if not sharing_gap:
                        reason = 'invalid-heartbeat'
                        heartbeat_error = {'type': type(error).__name__, 'message': str(error),
                                           'errno': getattr(error, 'errno', None),
                                           'winerror': getattr(error, 'winerror', None)}
                if time.monotonic() - last_heartbeat >= timeout:
                    reason = 'stale-heartbeat'
            if reason:
                detail = {'heartbeatError': heartbeat_error} if heartbeat_error else {}
                publish(root / 'stop.json', {'schema': 1, 'reason': reason, 'utc': time.time(),
                                             'recovery': 'NOT_ATTEMPTED', **detail})
                # Revalidate file identity and retained process identity immediately before kill.
                if not matches(target.identity(), config['target']):
                    raise ValueError('Target changed; preserve ambiguous process')
                target.stop()
                publish(root / 'result.json', {'schema': 1, 'result': 'OWNED_PROCESS_STOPPED', 'reason': reason,
                                              'descendants': sorted(observed_descendants),
                                              'descendantPolicy': 'PRESERVED_NOT_TERMINATED',
                                              'saveRecovery': 'NOT_ATTEMPTED', **detail})
                return
            time.sleep(0.1)
        # Include a final census after natural target exit. A child retains its
        # creator PID even when the creator has exited; it must fence restoration.
        observed_descendants = descendants(config['target']['pid'], observed_descendants)
        verdict = 'UNKNOWN_DESCENDANTS_PRESERVED' if observed_descendants else 'OWNED_PROCESS_EXITED'
        publish(root / 'result.json', {'schema': 1, 'result': verdict, 'descendants': sorted(observed_descendants),
                                      'descendantPolicy': 'PRESERVED_NOT_TERMINATED', 'saveRecovery': 'NOT_ATTEMPTED'})
    finally:
        controller.close()
        if target:
            target.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, required=True)
    args = parser.parse_args()
    try:
        run(args.config)
    except Exception as error:
        # A failed observer must never silently authorize more controller input.
        try:
            publish(args.config.parent / 'failure.json', {'schema': 1, 'result': 'REFUSED', 'error': str(error),
                                                        'saveRecovery': 'NOT_ATTEMPTED'})
        except (OSError, ValueError):
            pass
        raise


if __name__ == '__main__':
    main()
