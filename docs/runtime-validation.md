# Authorized Windows runtime validation

## Exact input and privacy

The authenticated numeric Releases API was used for Draft release422659795,
asset674332045. No public tag URL or unauthenticated download was assumed.

- ZIP:132,054,497 bytes; SHA256
  `9c8fa123ede4bad7b39f70ddcd1a8fdfa397df89bb215b18b4635855df2f265d`.
- 221 entries /220 regular files,163,096,667 uncompressed bytes;212 external audio
  files, original runner, D3DX9_43.dll, steam_api.dll and appmanifest391540.
  A read-only audio-resource audit found212 corresponding external files. Four
  additional stream-flag sound entries lack external files but reference nonempty
  embedded buffers (IDs133..136); runner resolution/playback remains NOT_RUN,
  rather than declaring missing required media or modifying those resources.
- Runner:PE32/x86; SHA256
  `c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58`.
  PE File/ProductVersion1.0.8.0. Original intromenu code displays1.08 with
  platform-specific suffixes. Neither string alone identifies this build.
- Supplied manifest:app391540, build4279148, depot391541,
  depot manifest3413030246586915448. These are supplied manifest observations,
  not an independent Valve entitlement/depot authenticity check.
- Packaged data.win:62,921,978 bytes, bytecode16, SHA256
  `b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7`.
  Identical to the previously audited input; no different-data adapter was applied.

Full per-file hashes stay in the ignored lab's identity-private.json. Account
fields from the Steam manifest are not emitted. Original ZIP/extracted inputs and
all personal supplied saves are never executed/written in place. No personal save
or Steam credentials were mounted into a container. Tests use fresh Wine profiles.

## Actual execution results

| Scope | Classification | Observation |
|---|---|---|
| ZIP, identity, original preservation | OFFLINE_PASS | Pinned archive, safe extraction, all220 original file hashes verified |
| Official original runner | BLOCKED | QEMU-user/Wine/Xvfb reaches Steam initialization; SteamAPI_InitSafe fails, mainwindow creation fails, then illegal instruction004D1820 |
| Previously tested patched runner (40d67856…) | BLOCKED | Same failure before gameplay/controller evidence |
| Current candidate (9abd0729…) | NOT_RUN | Offline changes only; Wine was not retried without a new hypothesis |
| Windows native runner | NOT_RUN | Linux cloud is not native Windows; no authenticated Steam session is available |
| Mod initialization/settings/fonts/UI/input | NOT_RUN | No game window/room entered; offline previews do not substitute |
| Battle/ACT/items/MERCY/FLEE/Forced outcomes | NOT_RUN | No actual combat executed |
| SAVE/reload/RESET/endings/history | NOT_RUN | No personal save used or modified; source models are separate evidence |

No NATIVE_RUNTIME_PASS or COMPATIBILITY_RUNTIME_PASS is claimed. The official
executable was prioritized. No alternative game interpreter, Steam API replacement,
DRM patch, fake ownership or license bypass was used. The runner's own diagnostic
says Steam must be running; window/illegal-instruction failures are additionally
recorded, not attributed exclusively to one cause without further evidence.

Environment:Debian13 x86_64 cloud, Wine10.0~repack-6, QEMU-i38610.0.13, Xvfb,
software graphics in an isolated container. Native ELF32 Wine failed with Exec
format error; WoW64 attempts failed before game startup. QEMU plus the official
Wine preloader resolves the low PE image mapping conflict and reaches Steam init.
The source wine-smoke.sh reproduced both original/patched failures using a fresh
prepared lab. Logs/screenshots/results.json remain private, not PR/CI artifacts.

## Historical compatibility smoke (do not retry without a new hypothesis)

```sh
python tools/runtime_lab.py prepare --zip private-data/runtime-windows/runtime.zip --work .research/new-runtime-lab
# Build the candidate to a NEW path, then copy only into runs/patched/data.win.
dotnet run --project src/RouteKeeper.Tool -c Release -- build \
  .research/new-runtime-lab/original/Undertale/data.win .research/new-candidate.win \
  /path/to/UndertaleModCli .
cp .research/new-candidate.win .research/new-runtime-lab/runs/patched/data.win
python tools/runtime_lab.py verify --work .research/new-runtime-lab
docker build --secret id=proxy_ca,src="$CODEX_PROXY_CERT" -t routekeeper-runtime:local tools/runtime
docker run --rm --network none --user 1000:1000 \
  --mount type=bind,src=/absolute/private/new-runtime-lab,dst=/lab \
  --mount type=bind,src=/absolute/private/new-runtime-lab/original,dst=/lab/original,readonly \
  --mount type=bind,src=/absolute/repository/tools/runtime,dst=/harness,readonly \
  routekeeper-runtime:local sh /harness/wine-smoke.sh
```

Keep inherited proxy/CA settings during image construction. Game execution has
network disabled. The smoke script never turns a live process into a gameplay
PASS; results require scenario assertions and screenshot/log review.

## Same-account side-by-side native smoke (experimental; NOT_RUN)

No new Windows account, Sandbox, VM or administrator is required. Use unelevated
Windows PowerShell5.1 or PowerShell7. **Native behavior has not been executed.**
Synthetic filesystem passes do not validate Windows APIs/SDK/permissions. The
registered Steam installation is read only; Program Files write permission is not
needed. Other registered Steam libraries are read/validated through libraryfolders.
Only the checksum-pinned supplied runner/data/media are copied into a private run.
An unknown personal installed build is fingerprinted, not patched or approved.

**Account risk:** a restored local folder is NOT Steam account-level restoration.
Cloud-off/Offline Mode/unchanged observed caches do not prove SDK/server isolation.
Known local permanent files or preexisting app391540 cache FILES refuse Run. Do not
clear personal caches/history to bypass this gate. Opaque metadata cannot be proven
safe here. Smoke is limited to startup/UI/settings/keyboard/early normal battles,
warnings and nonlethal Forced refusal. No SAVE, RESET, TRUE RESET, Genocide ERASE,
Soulless or ending scenarios. The unmodified runner cannot enforce this restriction;
the operator must stop before those actions. Autosaves may still be written in the
trial folder, which is why snapshot/restore and cache checks are necessary.

### Prepare and preflight (same ordinary account)

Keep Cloud disabled both globally and for UNDERTALE. Authenticate owned UNDERTALE
in the legitimate Steam client, select Go Offline/restart once, then EXIT Steam
and its helpers. Prepare all tools/dependencies/inputs before disconnecting.
Use the already provided private ZIP; no new game files or credentials are requested.
The pinned official UndertaleModCli version is0.9.2.0; source/tool SDK is.NET10.

```powershell
# In a fresh powershell.exe -NoProfile (5.1) or pwsh -NoProfile session, repo root:
$rkLab = "$env:USERPROFILE\private\rk-lab"
$rkCandidate = "$env:USERPROFILE\private\candidate.win"
python tools/runtime_lab.py prepare --zip "$env:USERPROFILE\private\runtime.zip" --work $rkLab
dotnet run --project src/RouteKeeper.Tool -c Release -- build "$rkLab\original\Undertale\data.win" $rkCandidate "C:\tools\UndertaleModCli.exe" .
python tools/runtime_lab.py verify --work $rkLab
$rkPaths = @{Lab=$rkLab; PatchedData=$rkCandidate; SteamExe="C:\Program Files (x86)\Steam\steam.exe"; GameInstall="C:\Program Files (x86)\Steam\steamapps\common\Undertale"}
& .\tools\runtime\run-current-account.ps1 @rkPaths -Action Preflight
```

Replace only the genuine client/library paths. Preflight is read only and can run
before disconnecting so Windows can validate the Valve signature/chain. It does
not establish ownership/SDK readiness; the official runner will test that. Do not
disable signature/OS policy checks if they fail. Case-sensitive mutable paths,
hardlinks, reparse points, unsupported file streams/inspection and unavailable
ordinary-user permissions fail closed. These Windows API gates are NOT_RUN.

### Execute original, then patched

Manually disconnect Wi-Fi/Ethernet/VPN/adapters. The tool never changes networking
or elevates. Keep Cloud off and the network disconnected through recovery/reboots.
Steam/game/helpers must be completely exited before each Run/Recover/Archive.

```powershell
& .\tools\runtime\run-current-account.ps1 @rkPaths -Action Run -Case original -AcceptSteamAccountRisk -CloudDisabledAndOffline -Minutes 10
```

The tool independently hashes a snapshot of `%LOCALAPPDATA%\UNDERTALE`, durably
journals a same-volume quarantine, atomically publishes an allowlisted side copy,
starts the legitimate Steam client offline, then directly starts that official EXE
with its own working directory. No app-id shim, SDK injection or registered-install
swap is used. A quick exit/redirect is BLOCKED; do not fall back to replacing the
registered game. Steam PID/restarts and adapter state are checked during observation.
A process/window/zero exit code never becomes gameplay PASS automatically.

Patched smoke controls: open settings with F10 only in safe overworld context;
use the game's configured directions/confirm/cancel, or F5/F6/F7/F9 direction
shortcuts. Select English/Korean and inspect every submenu, bounded HUD and warning;
F8 acknowledges a warning (or the selected unused gamepad button). Set target True
Pacifist, then compare Off/Passive/Active/Forced on an early EXP-producing FIGHT:
acknowledge/retry only if safe, and leave ACT/MERCY usable. Do not actually kill an
enemy to test a warning or consume an item you need. Check closing menus does not
also confirm a vanilla action, HP/EXP/inventory remain coherent, and only mod
settings persist on the optional second launch. These are expected observations,
not evidence that the behavior has run. Physical gamepad needs a separate result.

From a SECOND unelevated PowerShell, record observations (original: startup,
English, keyboard and ordinary battle; patched: all eight protocol scenarios):

```powershell
& .\tools\runtime\run-current-account.ps1 -Action Observe -Scenario startup -Outcome PASS -Actual "Observed title and fresh room; transitions and clean exit checked."
# Focus the GAME within three seconds for optional foreground client-area capture:
& .\tools\runtime\run-current-account.ps1 -Action Observe -Scenario korean -Outcome NOT_RUN -Actual "Capture for manual typography review" -Capture
```

Fields are expected/actual/status/method=OPERATOR_REPORTED; these are operator
assertions, not automated approval. The scenario definitions are smoke-scenarios.json.
Reports, images, trial saves and independent snapshots stay privately under
`%LOCALAPPDATA%\RoutekeeperSmoke\active`; the parent ACL is restricted to the
owner/SYSTEM. Do not upload it to PR/CI. Capture/ACL/native APIs remain NOT_RUN.

Close the game, then EXIT Steam fully when the final prompt appears. The script
waits for Steam/webhelpers/game to stop before restoring local content. It checks
the local tree, registered installation fingerprint and observed app/account Cloud
cache fingerprints. A changed cache blocks comparison/archive/cleanup; no cache is
rewound and no account-safe result is inferred. If any gate blocks, stop, retain
all evidence and keep Cloud disabled; do not delete caches to force the next case.

Record concrete PASS observations for original startup, English, keyboard and ordinary battle.
A patched trial refuses to start without these archived original observations and
identical runtime-tool tree, Steam client, registered install, local-save and observed
cache baselines. Operator reports remain assertions, not automated gameplay approval.
Only when local restoration AND observed baseline checks succeed:

```powershell
& .\tools\runtime\run-current-account.ps1 -Action Archive
& .\tools\runtime\run-current-account.ps1 @rkPaths -Action Run -Case patched -AcceptSteamAccountRisk -CloudDisabledAndOffline -RestartForSettings -Minutes 10
```

RestartForSettings launches the same patched trial twice (keep Steam open between
them), allowing actual mod settings persistence to be inspected. Personal saves
remain quarantined until both finish. Original/patched episodes use fresh trial
folders; this is NOT proven independent Steam history. Repeat ordinary controls,
ACT/MERCY/FLEE, warning acknowledgement and Pacifist EXP refusal while retaining a
nonlethal action. Do not use this protocol for ending or permanent-history testing.
Hardware gamepad requires its own real observation; synthetic input parity is not
hardware evidence. Native macOS/Linux still need separate exact builds/runners.

### Interrupted sessions, recovery and cleanup

```powershell
# Stay offline; EXIT Steam/webhelpers/game completely first.
& .\tools\runtime\run-current-account.ps1 -Action Recover
Get-Content "$env:LOCALAPPDATA\RoutekeeperSmoke\active\recovery.json" -Raw -Encoding UTF8
# Optional INSTEAD OF Archive: remove only own game/trial/partial copies and archive.
& .\tools\runtime\run-current-account.ps1 -Action Cleanup
```

Exclusive session locks prevent concurrent runs/recovery; observation has its own
lock and cannot block on the live game loop. Atomic flushed JSON/previous revision
and presence+digest checks cover partial staging, rename/journal gaps, repeated
recovery, missing quarantine with verified snapshot fallback and detected corruption.
Uncertain identity or corrupt snapshots fail closed and preserve all copies.
Actual Windows NTFS power-cut/process behavior is NOT_RUN. Content/tree verification
does not claim ACL/timestamp, Steam cache, Cloud/server or account-history rollback.
Archive retains everything; Cleanup retains snapshots/reports and removes only
owned game/trial/partial copies. It never deletes Steam userdata or the pristine ZIP.
If Steam restarts/network reconnects after a power failure, account guarantees still
do not exist even when local recovery succeeds. Do not reconnect Cloud before review.

**Legacy schema1 swap sessions:** if `%LOCALAPPDATA%\RoutekeeperCurrentSession`
exists, this tool refuses every new action. Keep Steam/network off and preserve
that directory, its independently verified snapshot and the registered-install
backup. Do not rerun the old unvalidated swap script, guess paths from a damaged
JSON, delete backups or elevate merely to get the new smoke working. A partially
swapped legacy installation needs separate manual recovery review using exact
original hashes and the actual filesystem state; automatic recovery is deliberately
BLOCKED. The new protocol never writes/renames a registered library to fix it.

The older dedicated-user/Sandbox scripts are historical alternatives, not this
workflow's requirements or validated infrastructure. They also do not prove Steam
account-level isolation. Keep PR1 Ready/open, InspectedOnly, and merge/release blocked.

## Cleanup

Use the current-account Cleanup command above only after successful recovery and
baseline verification. It archives private snapshots/reports and removes only its
owned game/trial/partial staging copies. Keep the supplied ZIP/pristine inputs
until intentionally removed; never use cleanup to delete account caches/history.
For old cloud Wine containers/prefixes, remove only task-owned storage after
preserving useful private evidence. Follow private-data.md for Release/LFS/cloud
cleanup; local removal does not promise deletion from backups or Git history.
