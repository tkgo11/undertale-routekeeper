# Windows testing entry point and explicit experimental boundary

## Current E2E hardening continuation

See [e2e-hardening.md](e2e-hardening.md) for the corrected Work/report resolver,
optimization-independent prerequisites, native UI contract adapter and explicit
scenario/evidence matrix. Owner-authorized policy v2 extends implementation beyond
the earlier original-only probe; default legacy Run stays NO-GO. Cloud started no
Steam/game. Native Windows and real gameplay verification remain NOT_RUN; combat,
Forced and endings remain blocked without independent observers/authentication and
appropriate safe starting states. Historical original-only descriptions below are
superseded implementation boundaries, never evidence of native success.


This continuation implements trusted preparation, a bounded scenario scheduler,
window-targeted input, native non-game tests, existing capture/verifier integration,
local recovery coordination and private reports. It does **not** finish native
route/gameplay automation. No official runner or Steam was executed in Cloud.

There are two different policies:

- `run-current-account.ps1 -Action Run` remains unconditionally **NO-GO**.
- The owner separately authorized an opt-in, **original startup probe only**, after
  every hard native/integrity gate and fresh consent. Risk acceptance permits this
  experiment; it does not prove account isolation, native compatibility, or a
  successful original baseline. The patched game is not launched by this probe.

The complete proposed original → patched → gameplay flow remains **PARTIAL**.
The initial-room bootstrap, GameMaker input acceptance and independent gameplay
observers lack native evidence. Those gaps cannot be repaired with arbitrary
confirmations, injected saves, self-reported telemetry, or screenshot approval.

## Prerequisites and commands

The owner additionally authorized a connected-network exception on 2026-10-30.
For experimental Preflight/Smoke/UI modes or exact experimental recovery Work,
pass `-AllowConnectedNetwork` to test-windows.ps1. The operator must type a fresh
`ACCEPT CONNECTED NETWORK RISK <nonce>` phrase in that process. This permits
Internet connectivity or uncertain network observations without claiming offline
status. No adapter, firewall, Cloud or Steam account settings are changed.
Without the flag, the original physical-link/NLM offline checks still apply.

Cloud-disabled/Steam Offline preparation, closed-process boundaries, exact file
identity and all save/watchdog refusals remain mandatory. A separate fresh game
launch nonce is still required. The connection risk receipt is included in launch
consent, session journals, result reports and experimental recovery receipts.
Steam may communicate or synchronize account data now or later; local restoration
cannot undo RemoteStorage, achievements or permanent account history. Legacy Run
remains NO-GO; the flag does not apply to legacy recovery. Existing pending manual
recovery must finish before a new game trial. Policy v4 invalidates older seals.

The owner's later explicit request for autonomous testing without personal
controls permits policy-v5 documentary chat delegation for original startup only.
Use `-OwnerDelegatedOriginalProbe -ApprovalStatement <exact current owner request>`
with Smoke; other delegated modes are refused. Consent still records fresh
session/nonce/disclosure and separately records OWNER_CHAT_DELEGATION with the
statement. It never claims direct terminal input or independent authentication.
The same delegation can accompany the fixed original-copy manual recovery.
Patched execution, navigation plans/input, SAVE/RESET/endings and reference
approval remain outside this scope. Fresh preparation is required after v5.

`-NativeTestReceipt <private-folder>` may reuse a just-passed non-game receipt;
the existing validator checks it both before launch and in the coordinator.
This option adds no expiry guarantee. Omit it to run a new native self-test.
Execution paths are canonicalized before exact process comparison and journal
creation. Startup requires repeated observations of the same owned foreground
window; HWND observations alone are not pixel or navigation evidence. Failed
capture operands are private diagnostics and never replace an image receipt.

The external guardian tolerates Windows heartbeat read-sharing gaps only while
the existing stale deadline continues running. Its publisher retries sharing
violations for at most 250ms. Neither case counts as observed heartbeat progress.
Invalid sequence/link checks still stop the owned target. No journal recovery
rules or global transaction publication behavior change.

Use the repository root, ordinary current Windows account, 64-bit PowerShell5.1/7
on Windows10+, Python3.12+/Pillow11.3.0, the exact SDK in global.json, and the pinned
UndertaleModCli0.9.2.0. No administrator, new account, Sandbox or VM is required.
The ordinary authenticated Steam client/registration is required only for native
preflight/probe, not for offline Check/Prepare/DryRun/Report.

```powershell
.\tools\runtime\test-windows.ps1 -Mode Check
.\tools\runtime\test-windows.ps1 -Mode DryRun
# Prepare defaults to the already supplied repository private ZIP if present.
# Use the PHYSICAL executable path, not a CLI symlink/shim:
.\tools\runtime\test-windows.ps1 -Mode Prepare -Work "$env:LOCALAPPDATA\RoutekeeperE2E\prepared" -Cli "C:\Tools\UndertaleModCli.exe"
.\tools\runtime\test-windows.ps1 -Mode Preflight -Work "$env:LOCALAPPDATA\RoutekeeperE2E\prepared"
.\tools\runtime\test-windows.ps1 -Mode NativeTest
```

The example CLI path must be an actually installed pinned CLI; no binary is
obtained from an untrusted source. Archive/Builder can be specified explicitly.
Check fails when dependencies differ. Prepare builds the existing source tool if
its default DLL is absent, inspects the authenticated/hash-pinned ZIP with
runtime_lab, compiles through the existing .NET builder (including serialization,
reload and preservation), checks the exact profile's candidate SHA and revalidates
all original/test-copy files before sealing prepared.json. Failures retain an
unsealed private lab; that lab cannot launch. Existing outputs are never reused.

Default Work paths are printed. Windows uses the private LocalAppData/RoutekeeperE2E
namespace; Linux offline runs use ignored private-evidence/windows-e2e. For reports
and recovery, pass the printed path explicitly. No session is guessed.
Steam client discovery reads HKCU; game-directory hints reuse the C# discovery.
Multiple/missing candidates require genuine SteamExe/GameInstall paths. Every hint
still passes the existing signature, library registration, path and exact-copy gates.
No registered installation is patched, swapped or used as a staging destination.

Linux/offline equivalents (actually exercised without a game):

```sh
python tools/windows_e2e.py dry-run --output private-evidence/new-e2e
python tools/windows_e2e.py report --run private-evidence/new-e2e --output private-evidence/new-e2e/report-copy.html
python tools/test_windows_e2e.py
pwsh -NoProfile -File tools/runtime/test-e2e.ps1
```

Use a new output path each time. The PowerShell DryRun additionally performs a
real snapshot/quarantine/restore transaction on **synthetic files only**, through
current-account-state.ps1. Python does not implement a second save backup system.
Its recovery event is explicitly a simulated boundary; the PS receipt separately
states that actual synthetic filesystem bytes were restored. Neither is native
Windows/Steam evidence. Missing/changed seals and journal-chain gaps refuse reports.

## Mode matrix

| Mode | Implemented behavior | Native/game boundary |
|---|---|---|
| Check | Python/Pillow/SDK and platform diagnostics | Starts no Steam/game |
| Prepare | Existing archive validator + source builder + exact copies + seals | Offline only; InspectedOnly unchanged |
| Preflight | Prepared identity, existing Steam/save/cache/NTFS guards, offline adapters, closed processes, storage | Read-only game/save/cache inspection, no launch |
| DryRun | Two explicit synthetic cases, finite state transitions, inputs/captures/verifier/review/report; real synthetic save transaction via PS | All fake process/Steam observations labeled; no game subprocess |
| NativeTest | Harmless owned WinForms window, key down/up, focus-loss/abort refusal, hardlink/ADS/junction negative fixtures, private capture, white-bar/black-field check and local recovery | Code/AST compiled; actual Windows execution NOT_RUN |
| Smoke | Native gates + NativeTest + fresh consent + original-only startup observation + owned stop + fenced local recovery + private capture-only review | Original bootstrap not proven; never automatically launches patched game |
| Resume / Recover | Verified recovery only, **never stale input replay**; requires explicit Work for new sessions | Refuses unknown trial changes and live processes |
| Report | Sealed JSON, journal, private HTML and per-scenario visual report links | Process exit/screenshot/review is not gameplay PASS |
| Cleanup | Existing recovery first; only unchanged owned game copy removed; snapshots, trial data, receipts and evidence retained | Changed caches/install/copy or ambiguous local state refuses |

Old fixed-path sessions remain recoverable by the original recovery command.
Supplying a wrong new Work never silently selects that old session instead.

## Consent and experimental startup probe

`experimental-policy.json` is the shared disclosure/policy source. A new session
nonce is displayed with the actual history/Cloud limitations. The operator must
manually type `AUTHORIZE EXPERIMENTAL SESSION NONCE`. There is no accept-all flag,
credential input, background consent, identity waiver or profile promotion.
The local receipt records session, nonce, policy/disclosure hash and time, without
credentials/account identifiers. The probe verifies current/fresh policy binding.

Before an authorized native experiment, legitimately authenticate owned UNDERTALE,
prepare Steam Offline Mode, disable Cloud globally/per game, exit Steam/helpers,
and disconnect physical network connections manually (disconnect Wi-Fi/unplug
Ethernet). Virtual adapters may remain enabled. The shared gate requires explicit
disconnected/disabled/not-present hardware links and no Windows NLM Internet
connectivity; missing/ambiguous observations refuse execution. It makes no external
probe or network setting change and does not prove account isolation.
The tool never performs those configuration
changes. Cloud-off is not an account-history sandbox. Existing local permanent
history or app391540 cache files still block; never delete them to pass.

Only after **NativeTest and all non-game preflight** may this be considered:

```powershell
# Experimental original startup ONLY, not a complete smoke/gameplay pass:
.\tools\runtime\test-windows.ps1 -Mode Smoke -Work "$env:LOCALAPPDATA\RoutekeeperE2E\prepared"
```

A new Smoke work directory can be prepared automatically when Archive/Cli are
available. Signature, exact original runner/data/candidate, registered library,
NTFS/link/stream/case/permissions, closed processes, offline adapters, storage,
known-history/cache and existing-session guards are not waived by consent.
Unknown builds, updates, redirects or missing ordinary-user permissions refuse.
No elevation, ownership shim, Steam emulator, app-ID substitution or original
Steam API edit is used.

The probe creates independently hashed backups using the existing transaction,
starts only the verified Steam client in offline mode, then the exact original
side-copy runner. It bounds client/window waits, observes exact PID/path/start
identity and game children, captures only a foreground owned client rectangle,
then requests owned game termination and legitimate client shutdown. It sends **no
gameplay keys** into an unrecognized title/room. A visible window or zero exit is
not an original-baseline PASS. Patched execution and the other native scenarios
remain NOT_RUN/BLOCKED. Login/authentication failure does not trigger fake input
or a registered-install fallback.

**This source path has not run on Windows.** The operator authorization does not
certify its OS/Steam behavior. Native non-game validation must precede any probe;
refusal is a result to preserve, not a suggestion to weaken a guard.

## Scenario state machine

`e2e-scenarios.json` reuses the eight existing IDs. Every step specifies its required
scene, whitelisted action and bounded hold. There are finite steps, no exploratory
retry, and a global monotonic watchdog. Original baseline variants exclude all
mod-only menus; simulation never pretends original UNDERTALE has ROUTEKEEPER UI.
Fake encounter setup emits an explicit SYNTHETIC_ENCOUNTER_FIXTURE event and never
injects a real save or modifies a real game's state. Unrecognized states stop.

| Scenario | Offline executable coverage | Native current status |
|---|---|---|
| startup | Explicit synthetic title/room transition, failure/redirect boundary | Original process/window capture probe only; title-to-room behavior unverified |
| english | Synthetic owned UI/proxy constraints, original baseline variant | Actual font/UI not verified; proxy never authoritative |
| korean | F12-model language transition and pixel reference | Fresh recognized overworld/menu/input path unavailable |
| settings | Close/reopen model; no save/history mutation | Actual mod INI persistence observer not implemented/exercised |
| keyboard | Original movement model and mod cursor up/down model | Window messages verified only by future harmless native test; game acceptance unverified |
| battle | Explicit synthetic encounter fixture | No verified fresh encounter path; ACT/MERCY/FLEE not automated live |
| warnings | Synthetic warning/ack transition and evidence | Required live encounter and one-action replay observer unavailable |
| forced | Unobservable side-effect assertion retained even after visual approval | No independent live HP/EXP/inventory observer; no correctness PASS |

The complete NativeAdapter for progression and patched scenarios is intentionally
not enabled: a source-backed starting-state/bootstrap and a GameMaker input trace
are missing. This is an implementation/evidence gap, not proof those scenarios
are impossible. Do not advertise a fully automated native ending test system.

## Input, capture and stop behavior

`input-window.ps1` targets the original HWND with WM_KEYDOWN/UP and bounded holds.
It verifies current process path/hash/start, HWND ownership, foreground, Pause and
an abort tombstone before/through a hold. Releases target the original window,
never global keyboard state; a recycled HWND owner is refused. It uses no global
hooks, SendInput, controller emulator or input into Steam authentication UI.
Dispatch receipts distinguish requested/observed hold time from actual game action.

[PostMessage](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-postmessagew)
queues asynchronously; success does not prove message processing or hardware
keyboard state. [SendInput](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput)
is not HWND-targeted and has UIPI/state restrictions. It is not silently substituted.
The authorized runner imports GetAsyncKeyState/GetKeyState/raw-input/message APIs;
that read-only import observation does **not** prove which path implements the GML
keyboard functions. Native GameMaker acceptance of targeted messages is UNKNOWN.

The capture helper now exposes a common owned-window function for both the harmless
native test window and its existing UNDERTALE wrapper. NativeTest uses synthetic
geometry, not copyrighted game art. CopyFromScreen overlays/focus/handle races
remain unproven; no guaranteed window-only privacy or race-free identity is claimed.

Press **Pause**, or create `active-session/abort.request` in the printed Work, to
stop the probe. Unknown children, focus/capture failure, timeout or unexpected
state stops further automation. The bounded probe stops only its owned game
identity, requests shutdown only of its observed client, never kills arbitrary
processes/helpers, and waits for closure. Failure to stop/verify closure blocks
restoration and preserves all copies. Hard power loss cannot guarantee automatic
termination/recovery; do not claim a process simulator proves it.

## Recovery and privacy

```powershell
# Exit game/Steam/helpers and stay offline before recovery:
.\tools\runtime\test-windows.ps1 -Mode Recover -Work "PRINTED_PREPARED_WORK"
.\tools\runtime\test-windows.ps1 -Mode Resume -Work "PRINTED_PREPARED_WORK"
.\tools\runtime\test-windows.ps1 -Mode Cleanup -Work "PRINTED_PREPARED_WORK"
# Resume means recovery only, not replaying automation.
```

An immutable game-stop boundary records presence/digest immediately after the owned
game exits, before waiting for client shutdown. A later post-trial fence may be
committed only after all processes stop and the local data still matches. Changes
during shutdown, including a known trial disappearing, are not absorbed as trusted
trial data. Existing
trial content must still match that fence before recovery moves it. Missing fence,
unknown changes, corrupt journal/snapshot or later personal gameplay refuses
recovery. An absent destination may be restored only from the already independently
verified original snapshot/presence metadata. Restoration is idempotent once proven;
ambiguous content is retained for manual review. A shared exclusive experiment lock
prevents cooperative Run/Recover/Cleanup races. These checks are not hostile-parent
TOCTOU elimination, arbitrary-writer isolation or proven NTFS power-loss durability.

Local restoration cannot undo Steam-side history/deletion queues. The entire trial
folder, including any newly written local history, is preserved as evidence; no
individual history file is erased or fabricated. Cache/install changes block cleanup
and comparison. No Cloud reconnect or cache rewind occurs. Private snapshots can
contain personal data: do not upload them. NativeTest output is restricted to the
private LocalAppData namespace with current-user/SYSTEM ACLs; real Windows ACL/API
behavior remains NOT_RUN here.

Reports/evidence live in Work/execution (DryRun) or Work/active-session (probe).
The latter contains result.json/integrity, complete-report.html/json, visual-review,
screen-review and original PNG/sidecar, plus existing snapshot/protected/trial and
transaction journals. All are private. Use screen_verify review-list/review/report/
review-export on the reported visual run. Explicit `capture-only` preserves a valid
unrecognized frame without inventing an expected reference; it can NEVER be reviewed
into PASS. Sub-grid original pixels remain raw instead of being distorted to320x240.
Missing authoritative reference and gameplay state remain unresolved.

## Actual offline evidence and remaining gaps

Executed: Python orchestration16 tests, screen verifier51 tests, PS simulated input/
AST/transaction/fence tests, existing shared recovery regressions, source/build/
generator/font/localization checks. Private logs are below .research/windows-e2e.
No Steam/game/native Win32 function was invoked by Cloud tests. Real ZIP preparation
and authentic compile evidence are separately recorded in test-results.md; compilation
is not gameplay. Reports distinguish synthetic execution from native observation.

Still NOT_RUN: Windows5.1/7, Win32/NTFS/ACL/DPI/desktop/message/capture tests, the
experimental probe, actual Steam ownership startup, original/patched gameplay,
fonts/physical input, battles and endings. Full native scenario execution remains
PARTIAL/BLOCKED pending verified bootstrap/input and independent observation.
InspectedOnly, installation refusal, no merge/release and private-asset rules remain.

## Interrupted recovery and portable fixture validation

A journal at Restoring is not a completed recovery. The wrapper validates the
archived trial against its committed fence and the independent original snapshot
before resuming the shared transaction. It also recognizes an already returned
original when the final completion fence was interrupted. Changed archives or an
unknown new save target stop recovery without moving that target. Synthetic tests
inject both failures; actual NTFS power-loss behavior remains NOT_RUN.

Prepared seals include runtime_lab.py and screen_verify.py as well as native
helpers: changing those shared components requires a fresh preparation, never
editing an old receipt. On archive validation failure, only unpublished owned
single-link files have read-only bits cleared for cleanup; a cleanup failure keeps
the original validation exception and preserves the unsealed private lab.
