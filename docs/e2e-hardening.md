# Windows E2E hardening and execution boundary

This document supersedes the original-startup-only *implementation* boundary in
older progress entries. The default legacy Run is still NO-GO. Owner-authorized
policy experimental-e2e-v2 permits reviewed non-destructive UI plans through a
separate real adapter. It does not approve account isolation, combat, endings,
compatibility, or a new native test result. Cloud never starts Steam or UNDERTALE.

## Three independent evidence levels

- IMPLEMENTATION_COMPLETE means executable code and integration for a stated scope.
- WINDOWS_NATIVE_VERIFIED requires actual native Windows API/filesystem/UI evidence.
- GAMEPLAY_E2E_VERIFIED additionally requires exact original/patched executions,
  independently observed accepted inputs/transitions, mandatory assertions and recovery.

Neither workstream is certified universally complete. The new UI adapter is
implemented and offline-tested; complete authentic scene traces and independent
combat observers are missing. Native non-game changes have not executed here.
Passing mocks, process launch, screenshot approval or source compilation cannot
advance these levels. A locally editable receipt is not remote attestation.

## Confirmed defects and regressions

| Finding | Cause and correction | Evidence/remaining boundary |
|---|---|---|
| Report routing | Report used public Work while DryRun stored execution/ and probe stored active-session/. Resolve exactly one supported result; support direct paths and original-baseline fallback; write HTML beside evidence. | Public/direct layouts, partial/ambiguous layouts, links, result/report seal corruption tests. No newest-directory heuristic. |
| Optimization bypass | Python assert vanished with -O/PYTHONOPTIMIZE. Explicit version/module/PNG checks and structured CLI output now fail closed; SDK output must be one pinned value. | Invalid Python/Pillow/type inputs execute with both optimization forms. |
| Underlying native result drift | A complete-report seal alone did not revalidate result.json/result-integrity.json. Both and the embedded observation now must agree. | Mutate the underlying seal while retaining the valid report; reporting refuses. |
| Ignored preflight/recovery exit | Nested legacy script exit was not checked before continuing. Clear/check LASTEXITCODE at every retained call. | Source/control-flow inspection; synthetic entrypoint regressions. Actual failing Windows preflight NOT_RUN. |
| Recycled process release | Finally checked only numeric HWND owner. Refresh and recheck process start/path/hash before key-up. | Controlled start-identity mutation after key-down rejects release to reused PID. Same-process HWND recycling remains a Win32 uncertainty. |
| Lost capture evidence | Sidecar publication failure deleted an already published PNG. Retain the orphan; missing metadata is invalid evidence. | Source/AST audit. Actual Windows filesystem publication fault NOT_RUN. |
| Descendant recovery bypass | A detected child only affected in-memory shutdown logic. Persist an unverified-descendants flag, and refuse automatic recovery/cleanup. Journal Pending/Observed launch boundaries before/after Start-Process; incomplete launch refuses recovery. | Synthetic persistent-refusal test. Native CIM and process-crash boundaries NOT_RUN. |

Recovery still reuses current-account-state.ps1. It does not copy, restore or delete
Steam caches/history. The shared Prepared -> QuarantinePending -> Running ->
Restoring -> Restored phases remain; errors retain the last committed phase rather
than inventing an Interrupted phase that the common reader cannot validate.
Prepared/snapshot/quarantine failure, archive/return/completion gaps, terminal
idempotency and unknown later files have the existing disposable failure tests.
The full cross-product of permissions, disk exhaustion, reparse/ADS/hardlinks,
case sensitivity, locked files and actual NTFS crash ordering is **not proven**.
Preserve ambiguous trees; recovery failure never authorizes cleanup.

## Real adapter, not FakeAdapter

`native-gameplay.ps1` invokes actual Windows input/capture and the shared
`Invoke-RkGameSession` coordinator. That coordinator launches the official runner
with the disposable game directory as WorkingDirectory. Both original and patched
copies use exact file inventories. A process redirected into the registered game
fails identity checks. The registered installation is never a patch destination.
Disk/copy identity does not independently prove which bytecode the runner loaded;
no read-only loader/internal-memory observer is implemented.

Every supplied plan is validated and frozen with its private reference pixels
before quarantine/launch. A step declares scenario, before/after scenes, action,
holdMs, timeoutMs, maxFrames, stableFrames. Retries are zero. The adapter accepts
only whitelisted bounded keys, exact before/after private scenes, and repeated
stable matches. Input requires a distinct expected pixel response. Unknown scenes
are polled without exploratory keys, then stop. Global timeout/frame/byte budgets
and bounded Python observer pipes apply. Input intents and dispatch receipts are
separate; dispatch never claims action acceptance. Finalization independently
checks process identity, frame order, timing, stable-frame uniqueness and pixels.

The existing screen verifier stores expected/actual/normalized/diff/comparison
images, raw sidecars, immutable review histories and offline HTML. A timed-out
pending frame also enters the review queue. Overlay contamination remains
UNPROVEN. Font provenance defaults to unverified-native-font; no English proxy is
an authoritative native font reference. AI/human acceptance is visual only.

A settings step may observe the read-only trial routekeeper.ini Guidance section
for schema/mode/locale/language/spoilers/target_* values. This is file persistence,
not proof of applied gameplay or persistence across a process restart. HP, enemy
HP, EXP, LV, kills, action side effects and vanilla flags have no live independent
observer. Combat, warning-replay and Forced plans are refused before launch.

## Private plan format and provenance

Use UTF-8 JSON with schema=1, id/version tokens, case=original or patched,
runnerSha256, exact dataSha256, scope=non-destructive-ui, retries=0, scenes and steps.
Each scene has file=references/NAME.png, sha256, source=privately-authentic,
reviewer, scope=scene-navigation-only, and optionally locale/font identity. Images
are logical320x240 PNG by default, <=16MiB in total. A scene may explicitly set
space=client-pixels to compare320x240 integer-multiple native client images without
resampling, including genuine sub-grid pixels. Both actual/reference sizes must
agree; client-space cropping is refused. Default logical normalization is unchanged.
Reference images are decoded one at a time; only pixel fingerprints are retained. Source/reviewer fields are accountable
local claims, not proof the pixels came from native Windows. Independently review
and retain the actual capture source; do not use offline proxies as originals.

Steps support startup/english/korean/settings/keyboard, before/after scene IDs,
action=checkpoint or a whitelisted key, holdMs50..500, timeoutMs100..15000,
maxFrames2..100, stableFrames2..8. Optional setting={section:"Guidance",key:...,expected:"..."}
uses the supported mod-only keys. Original plans cannot declare mod-only settings
or Korean. Combat/ending/SAVE/RESET injection is not supported. A reviewer must
also establish that the actual proposed confirmations are non-destructive; a JSON
scope label cannot establish the meaning of arbitrary game pixels.

No authentic baseline plan is bundled: no approved native title-to-room trace was
available. Do not relabel the synthetic test fixtures as authentic references.
Validate a real private plan with:

```powershell
python tools/native_gameplay.py validate --plan "$env:LOCALAPPDATA\RoutekeeperE2E\contracts\original.json" --case original
```

## Operator entry point

No new OS account, VM, Sandbox or admin is required. Python/Pillow/pinned SDK/CLI
and legitimate already-authenticated Steam are prerequisites. Cloud-off, offline
Steam preparation and physical network disconnection remain operator prerequisites, not
automated changes or proof of RemoteStorage isolation. Existing app-cache/history
files still block; never delete them to get past a gate. Virtual adapters need not
be disabled. The shared guard checks classified hardware-link states and Windows
NLM Internet connectivity, and refuses unknown classifications/query failures.
Local-only virtual links are permitted; this observation is not account isolation.

Safe, executable now without Steam/game:

```powershell
.\tools\runtime\test-windows.ps1 -Mode Check
.\tools\runtime\test-windows.ps1 -Mode DryRun
.\tools\runtime\test-windows.ps1 -Mode Report -Work "PATH_PRINTED_BY_DRYRUN"
.\tools\runtime\test-windows.ps1 -Mode NativeTest
```

NativeTest uses only a harmless owned window and disposable files. It adds actual
minimized-capture refusal, exclusive locks and interrupted synthetic restoration
to the prior key/focus/abort/hardlink/ADS/junction/capture tests. It records OS and
PowerShell versions. These added native checks are NOT_RUN in Cloud.

Conditional real execution (paths must refer to real reviewed private contracts,
not example fixtures; these commands were **not executed**):

```powershell
.\tools\runtime\test-windows.ps1 -Mode FullE2E -Work "$env:LOCALAPPDATA\RoutekeeperE2E\new-run" -Archive ".\private-data\runtime-windows\runtime.zip" -Cli "C:\Tools\UndertaleModCli.exe" -OriginalPlan "$env:LOCALAPPDATA\RoutekeeperE2E\contracts\original.json" -PatchedPlan "$env:LOCALAPPDATA\RoutekeeperE2E\contracts\patched.json"
```

FullE2E performs genuine preparation/native gates/consent and original planned
execution, then stops for uncertain original visual evidence. It does not launch
the patched game until the exact original navigation captures have accepted scoped
reviews, required startup/English/left-right movement evidence, unchanged harness,
client/install/cache and verified local baseline. A later explicit FullE2E call
can reuse the verified original-baseline session and request fresh consent.
OriginalBaseline and PatchedSmoke also accept -NativePlan; PatchedSmoke requires
-Baseline pointing to the original session directory. These are UI experiments,
not a claim of complete gameplay automation or automatic approval of a baseline.

Recover/Resume only recover; they never replay stale keys. Report accepts the
same public Work or a direct run directory, and refuses conflicting current runs.
Original evidence stays at Work/original-baseline; patched evidence at
Work/active-session. Recover chooses an interrupted original only if no patched
session exists; two nonterminal sessions refuse guessed recovery. Cleanup retains
snapshots/reviews and requires verified recovery/unchanged owned files.

## Current coverage

| Scenario | Implemented | Offline verified | Windows native verified | Real game executed | Independent behavior verified | Result |
|---|---|---|---|---|---|---|
| startup | Real scene/input path; private bootstrap required | Synthetic contracts/timing | NOT_RUN | NOT_RUN | NOT_RUN | BLOCKED: authentic reviewed navigation trace |
| english | Exact private pixel/reference path | Synthetic pixel mutations | NOT_RUN | NOT_RUN | NOT_RUN | BLOCKED: authoritative native references |
| korean | Same adapter, no language-specific rules | Synthetic glyph/layout engine | NOT_RUN | NOT_RUN | NOT_RUN | BLOCKED: recognized live menu/font evidence |
| settings | Real input + read-only mod INI observer | Parser/contract tests | NOT_RUN | NOT_RUN | NOT_RUN | PARTIAL: restart/application evidence absent |
| keyboard | Bounded real HWND adapter + transitions | Ownership/timing mutations | NOT_RUN | NOT_RUN | NOT_RUN | PARTIAL: GameMaker acceptance untested |
| battle | Independent observer requirement enforced | Unsafe-plan rejection | NOT_RUN | NOT_RUN | NOT_RUN | BLOCKED: safe encounter + HP/EXP observers |
| warnings | Capture/review framework; live combat refused | Missing-observer rejection | NOT_RUN | NOT_RUN | NOT_RUN | BLOCKED: encounter/ack/replay observations |
| forced | Screenshot-only certification refused | Cannot certify from pixels | NOT_RUN | NOT_RUN | NOT_RUN | BLOCKED: independent absence-of-side-effects proof |
| Pacifist/Neutral/Genocide/Soulless | Existing route engine, not native route execution | Existing golden/bounded tests | NOT_RUN | NOT_RUN | NOT_RUN | BLOCKED: separate high-risk scope/native evidence |

Neutral6/call8 remains UNKNOWN. No new ending/reachability claim is made.

## Reproduction and external checks

Run the commands in AGENTS plus tools/test_native_gameplay.py and the extended
PowerShell test-e2e.ps1. Tests mutate pixels/build IDs/proxy provenance/paths/PIDs/
timestamps/stabilization/journals/reports; accepted images cannot certify unknown
internal gameplay. Logs stay below ignored .research/e2e-hardening. Screenshots,
references, trial files and account-local evidence never enter Git or uploads.

At the starting4de0922 HEAD, hosted synthetic checks were successful. Current
Qlty status still reported success with92 blocking issues; read-only issue access
redirected to login. Its real issue list is BLOCKED, not disproven by local lint.
No hosted job was manually rerun or billing/security setting changed. Post-push
status must be read fresh; automated summaries are not formal approval.

## Actual offline verification for this continuation

Starting remote HEAD4de09223acf2550b6a766f41c092ff47e60c3263. Source changes are
identified by the commits containing this document; use git rev-parse HEAD for the
final delivery HEAD. Release build0 warnings/errors;279 standard C# checks and9317
source-derived/bounded assertions passed. E2E21, native-contract11, screen51,
archive14, locale37 (including contributor E2E), UI22, private-validator6,
workflow2, encoding2 and inventory3 passed. PowerShell controlled-response/
filesystem tests cover the new refusal paths; they are not native Win32 calls.
Real Python children exercised argument quoting, timeout, output-budget and exit
failure handling. The default Check passed with PYTHONOPTIMIZE=1.

Authenticated ZIP preparation at806377a successfully compiled/serialized/reloaded
and preserved original resources, verified both220-file copies and sealed exact
harness identity. Subsequent source changes intentionally invalidate that seal;
the final evidence entry in test-results.md identifies the fresh replacement.
Original data SHA256 b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7;
expected candidate4457dbf421230c596df0d2c27754e8e94293c03c8e1106c6c1b07b9552f2c96c,
size63,195,750; profile remains InspectedOnly. No game process was launched.

The actual single-entry DryRun and subsequent Report using the *same public Work*
completed at private-evidence/e2e-hardening-current. Reports remain NEEDS_REVIEW,
nativeGameplay NOT_RUN; the PS receipt separately verifies synthetic local save
bytes. This is not Steam account restoration or native game acceptance.

## Remaining verification and implementation gaps

- No out-of-process guardian currently guarantees release/owned-game termination
  after the controller host is forcibly killed. Finally blocks cannot survive that
  event. Recovery records refuse unknown states, but this is not prevention proof.
- Full NTFS power-loss durability, PS5.1/7 native API behavior, DPI125/150,
  multi-monitor/fullscreen/focus races and same-process HWND reuse need actual native
  tests. Client-space comparisons preserve pixels; they do not establish capture
  ownership against overlays or authenticate a claimed private reference.
- Authentic title/bootstrap/movement captures and checked non-destructive action
  traces are unavailable here. FullE2E therefore has no bundled executable genuine
  gameplay plan; it refuses missing plans instead of sending guessed confirmations.
- Read-only loaded-bytecode identity and HP/enemyHP/EXP/LV/kill/vanilla-flag observers
  are not implemented. Combat, Forced, save/load and high-risk endings remain blocked.
- No complete proof of Neutral6/call8 is supplied. Qlty issue details require an
  authorized report/session not available here; local lint is not a replacement.

These limitations keep both broad workstreams PARTIAL. They must not be hidden by
calling a parameterized scene adapter a fully verified game automation system.

## 2026-10-28 native non-game filesystem CI expansion

Before any operator game execution, native Windows filesystem guards must be
validated independently of Steam, the GUI desktop, and personal saves. The new
`tools/runtime/test-native-filesystem.ps1` uses a fresh disposable directory
beneath the process TEMP root. It exercises the **actual native Windows APIs**
for hardlinks, named streams, junctions, exclusive locks, and local save
transactions. It checks interruption during the Restoring phase, repeated
restoration, and refusal to overwrite an unexpected later edit. It does **not**
run Steam, UNDERTALE, the WinForms GUI test, or read personal save files.

CI invokes this script separately in Windows PowerShell 5.1 and PowerShell 7.
A passing job proves only the listed **filesystem-only** checks on the Windows
runner, never desktop input/capture, GameMaker behavior, account isolation, or
native gameplay. A failing test preserves the synthetic TEMP directory for
inspection; a passing test removes only its own unlinked disposable directory.

The `Check` entry point now implements `global.json`'s `latestPatch` policy:
10.0.402 may roll forward to newer 10.0.4xx patch releases, but not backward,
to a new SDK feature band, or to another major/minor. The pure policy has
positive and negative tests in `tools/runtime/test-e2e.ps1`. Missing or
unsupported policies fail closed; this does not change the required game build.

Remaining mandatory boundaries are unchanged: the user's desktop-native GUI
self-test has not run, a reviewed authentic original navigation contract is
not bundled, Steam account restoration is unproven, and battle/Forced/ending
observers remain unavailable. Do not interpret the new CI job as approval to
run original or patched gameplay.
