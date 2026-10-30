# Independent Windows safety watchdog

The experimental coordinator arms `tools/runtime/watchdog.py` in a separate hidden
Python process after the exact owned runner is launched, before window observation
or inputs. PowerShell publishes advancing heartbeat sequences before scene work;
every input ownership check also refuses a dead or stopped guardian. A heartbeat
does not establish that GameMaker accepted a message.

The helper resolves the base interpreter's `pythonw.exe` and starts it with
`ProcessStartInfo.UseShellExecute=false` and `CreateNoWindow=true`. This avoids
the Windows venv launcher and console-host child processes; missing Pythonw fails
closed. The guardian opens and retains Windows process handles for controller and target.
It verifies executable path, process creation ticks and SHA-256 against the supplied
identity before arming and rechecks the target before termination. Termination uses
the retained handle, never a new PID lookup or a process name. A recycled PID cannot
redirect that handle. A failed initial identity check refuses termination.

Controller exit, a heartbeat stale for 30 seconds, the Pause key, an emergency-stop
file, invalid heartbeat sequence, unexpected descendant, unverifiable descendant
census, premature disarm or an absolute five-minute limit
stops the exact target with a bounded five-second wait. The guardian never sends
keyboard messages, terminates Steam, kills a process tree, rewinds account history
or restores saves. Unknown descendants remain untouched. Files below the private
session's `watchdog/` directory record ready, stop, failure and closure receipts.
Native Toolhelp snapshots inspect descendant relationships each poll and once more
after natural target exit. Any observed descendants stay untouched and invalidate
normal closure, including a child whose parent has already exited. The coordinator
propagates its abort file to the guardian. A guardian stop/failure
or missing closure receipt blocks automatic recovery even after a later restart.
Personal snapshots, trial state and unknown descendants remain for review.

This is bounded protection after successful arming, not a system service, job object,
account sandbox, hostile-writer protection or a power-loss guarantee. A controller
crash between process launch and successful guardian arming remains a gap; the
Pending launch journal refuses guessed recovery. A dead guardian cannot stop a
simultaneously stalled controller; a resumed controller refuses further inputs.
An inaccessible or changed target identity is preserved rather than guessing which
process to terminate. The guardian cannot release a GameMaker-internal held key
after its controller dies; terminating the exact process is its safety action.
Process snapshots are best effort: unobserved short-lived descendant chains are
not universally excluded, and recycled creator PIDs may conservatively refuse a
session. A clean census is not arbitrary-process or hostile-writer isolation.
No real-game claim follows from these fixtures.

## Native disposable verification

Use the project venv on PATH and run:

```powershell
python tools/runtime/test-watchdog.py
pwsh -NoProfile -File tools/runtime/test-watchdog.ps1
powershell -NoProfile -File tools/runtime/test-watchdog.ps1
```

The Python tests launch only owned console-free Pythonw sleepers. They verify an
actual parent crash while its guardian child remains alive, controller death,
stale/repeated/invalid heartbeats, emergency abort, normal closure, wrong creation
time/path/hash/controller identity, premature disarm, hardlink refusal and preservation
of a real unknown descendant and unrelated process. A natural parent exit leaving
a live unknown child also refuses normal recovery. The PowerShell tests exercise
the real helper/guardian handshake and heartbeat, input refusal after guardian death,
and shared recovery refusal for incomplete/intervening guardian receipts. Private
fixture logs remain under `.research/windows-20261029-watchdog/`.
