# Windows environment and native non-game continuation — 2026-10-29 KST

This continuation starts at remote/local `ce5b52b39398a1c11a5b88e92a8609fe00804c57`.
The source commit containing this document identifies the delivered changes. No
gameplay, compatibility promotion, Steam account restoration, merge or release is
implied by the native non-game results. Private reports retain the tested tree and
each command/exit code; earlier entries below other status documents are historical.

## Environment and repeat entry

Windows 11 Home build26300 x64, interactive unelevated session, NTFS C:/D:,
2880x1800 Intel display, actual native DPI192 (200%), PowerShell7.6.9 and
Windows PowerShell5.1.26100.9711. The existing Python3.12.9 venv and Pillow11.3.0
were reused. Installed privately: .NET SDK10.0.403 under `.research/dotnet`,
pyflakes3.4.0 in `.research/test-venv`, checksum-pinned official
UndertaleModCli0.9.2.0 under `.research/utmt-windows`, and upstream xdelta3.2.2 under
`.research/xdelta`. The SDK resolver and Check accept10.0.403 under unchanged
global.json latestPatch; the system9.0 SDK was retained. No global PATH, Python,
monitor scaling, security settings or Steam configuration was changed.

From this checkout, run the eligible suite with one command:

```powershell
pwsh -NoProfile -File tools/runtime/test-all.ps1
```

The wrapper selects only session-local SDK/venv paths. The suite retains private
JSON/HTML/logs under `.research/windows-suite/NEW_ID`, propagates failures, blocks
stale C# binaries after a failed build, bounds child time/output, and removes an
inherited PYTHONOPTIMIZE from test children. It never launches Steam/game or reads
personal save contents. Available pinned private assets enable structural checks;
missing assets are not gameplay approval. `-SkipDesktop` deliberately omits GUI
tests and is never equivalent to a desktop run. A timeout terminates the direct
owned test child; descendant closure is explicitly unverified on that path.

## Confirmed repair versus unreproduced history

- Original golden derivation failed on real Windows even though parsed values
  matched exactly. Windows Path ordering folds case; Linux ordering does not.
  Explicit ordinal resource-name ordering now reproduces the unchanged golden
  bytes. All115 original hashes and27 dispatch links were independently checked.
- Enabling the contributor localization E2E reproduced a second Windows failure:
  bare `python` child commands selected the base Conda interpreter before PATH,
  losing the venv's Pillow. All contributor Python children now use the current
  `sys.executable` absolute path. The complete37-case contributor workflow passed
  without a global package install. Its initial failure remains in private logs.
- The combined PS7-to-Python-to-PS5.1 path inherited PS7 module directories and
  reproduced Security module/type-data conflicts, hiding Get-FileHash/Get-Acl.
  Each shell child now rebuilds its own default PSModulePath from a private
  environment copy. Actual PS5.1 Security imports and native filesystem/E2E tests
  passed without changing machine or user module settings.
- Killing the guardian during stop-receipt publication exposed a test that only
  accepted the exited-process refusal. The actual input gate already refused the
  interrupted receipt. The fixture now verifies the exact guardian refusal reaches
  the input gate and separately reproduces empty interrupted stop evidence.
- Historical PS5.1 missing C# source under `C:\WINDOWS\TEMP` did not reproduce
  with the current user's TEMP. A controlled invalid child TEMP fails; an owned
  private child TEMP compiles and returns42. No security control was changed.
- Historical final cleanup Access Denied did not reproduce. The synthetic E2E
  test now seals its owned token/content inventory only after success, refuses
  unknown/changed/link/hardlink/locked fixtures, validates before deletion, and
  preserves the original assertion error and forensic workspace on failure.
- The apparent black native screenshot preview was not a capture defect: decoded
  pixels contain the exact576x6 white fixture bar. New mutation tests refuse black,
  shifted, obstructed, stale-hash and incomplete receipts. Native WinForms pixels
  remain in client coordinates; GameMaker logical normalization is unchanged.

## Implemented capabilities and boundaries

[Watchdog](watchdog.md) adds an independent process, exact retained process handles,
heartbeats, controller-crash/abort/timeout handling and descendant-preserving recovery
fences. Real Windows harmless-process tests cover these paths; launch-to-arm,
simultaneous controller/guardian failure and unobserved transient descendant chains
remain limitations.

[Capture bootstrap](native-bootstrap.md) freezes existing native pixels, identities,
action histories and proposed plans. A human must separately review provenance and
safe action meanings before export. No authentic navigation captures were invented
or acquired. The bootstrap is not a new authorization path.

[Save observer](save-observer.md) independently maps saved LV/EXP/kills/maxHP/flags/
plot/room/time to three exact original source hashes. Only disposable snapshots are
accepted. Current HP is not serialized, and live enemy HP/encounters/loaded bytecode/
Forced side effects remain UNVERIFIED. Plausible fabricated snapshots cannot be
authenticated by a locally supplied hash alone.

## Authentic inputs and game boundary

The licensed Steam installation is `D:\SteamLibrary\steamapps\common\Undertale`.
Its original data and runner match the supported exact hashes. The existing private
release archive was downloaded through the authenticated numeric asset API and
matched its pinned ZIP hash. Private original/patched copies are separate from the
registered installation. Authentic structural compilation reproduces candidate
`4457dbf421230c596df0d2c27754e8e94293c03c8e1106c6c1b07b9552f2c96c`.
This is compilation/serialization/reload/preservation evidence, not runtime proof.

Steam was already running; it was not started, stopped or reconfigured by this
continuation. Original/patched official runners were not launched. Fresh session
consent, offline/Cloud/network prerequisites, cache/history guards and authentic
reviewed navigation plans remain mandatory. Startup itself may affect permanent
Steam history; local restoration cannot undo RemoteStorage/account history.
No personal save was used as a disposable fixture, backed up, restored or changed.
Synthetic interrupted local save recovery is a separate verified scope.

Neutral6 and call-goal8 remain UNKNOWN. Battle/Forced/ending execution remains
BLOCKED without independent live observers, safe authentic starting states and
the applicable separate high-risk authorization. The profile stays InspectedOnly.

## Evidence

The corrected full run completed63 commands:63 PASS,0 FAIL,0 BLOCKED. This includes
274 standard C# checks (39 Core,58 Tool,11 Saves,60 Neutral,89 Decisions,17 History)
and9317 separately counted source/model assertions. Python discovered223 tests:
221 passed,0 failed,2 platform-specific skips (non-Windows refusal and POSIX
special-node fixture). The37-case localization workflow also compiled four locales
and two registered fonts against authentic original data; gameplay remained NOT_RUN.

Both PS7 and PS5.1 passed69 E2E success records,101 current-account protocol checks,
9 actual NTFS checks,15 owned-cleanup checks,3 compiler-TEMP checks and12 guardian
integration assertions. The independent Python guardian suite passed17 real Windows
harmless-process cases. Each shell produced a fresh verified native GUI receipt at
640x480 client pixels/DPI192, including actual down40/up40 receipt and interrupted
synthetic recovery. Other DPI96/120/144 cases were synthetic; scaling was not changed.

All four RID publishes, synthetic xdelta packaging, authentic compile/reload/resource
mutation rejection,115 original-source hashes/27 links, unchanged original golden,
new private preparation and its independent seal verification passed. A fresh
read-only Preflight then returned BLOCKED because Steam was running, before launch
or any personal-save transaction. The initial combined run's54 PASS/7 FAIL/2 BLOCKED
remain preserved and are not erased by the successful corrected run.

The corrected final combined run is privately retained at
`.research/windows-20261029/verified-suite/`; the earlier `final-suite/` retains the
reproduced contributor failure before its repair. Environment, blocked focus attempt,
authentic compiler diagnostics and review snapshots are beside that directory.
The final comprehensive JSON and offline HTML are private, never GitHub artifacts.
Fresh post-push CI and review status must be read before final delivery; a green
Qlty status does not establish that its inaccessible issue list has been resolved.
