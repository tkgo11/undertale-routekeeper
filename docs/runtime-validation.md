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
| Current candidate (6a49b85c…) | NOT_RUN | Offline changes only; Wine was not retried without a new hypothesis |
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

## Native Windows without Sandbox (opt-in; execution NOT_RUN)

Windows Sandbox is **not required**. The script `tools/runtime/run-without-sandbox.ps1` runs on native Windows 11, including Home editions. To protect personal UNDERTALE saves, do not run it in a personal Windows user account. This is an operator-run workflow and **has not yet been executed on native Windows**; it must not be described as a passing runtime test.

### Preparation and isolation

Create two NEW, standard, non-administrator local Windows users, exactly named **RKTestOriginal** and **RKTestPatched**, respectively. Keep the main Windows account and its Steam/save folders untouched. Each test user needs a separate licensed Steam installation at `%LOCALAPPDATA%\RKTestSteam`, with UNDERTALE installed in that Steam library, and a private copy of the authorized ZIP and repository. The test script rejects the wrong username, administrator execution, the default machine-wide Steam directory, existing UNDERTALE saves and any preexisting app391540 Steam cache.

A separate Windows user is not a separate Steam entitlement. Use an independently licensed test Steam account if possible. If the same licensed account is used, Steam account-level/cloud history is a residual risk: disable Cloud globally and for UNDERTALE **before any game launch** in each fresh test account. Authenticate via the official Steam interface, prepare the exact build, select Steam **Go Offline**, restart Steam, and **manually disconnect every network adapter**. The harness checks that all adapters are down; it **never changes Windows networking**. Do not copy host `userdata`, personal saves, Steam login information, or cloud cache.

### Commands (run separately while signed into each new test account)

From the repository root, prepare a new private lab and compile the pinned patch inside the current test user's profile:

```powershell
python tools/runtime_lab.py prepare --zip "$env:USERPROFILE\private\runtime.zip" --work "$env:USERPROFILE\private\rk-lab"
RouteKeeper.Tool.exe build "$env:USERPROFILE\private\rk-lab\original\Undertale\data.win" "$env:USERPROFILE\private\candidate.win" "C:\tools\UndertaleModCli.exe" "C:\src\undertale-routekeeper"
python tools/runtime_lab.py verify --work "$env:USERPROFILE\private\rk-lab"
```

Replace tool/source paths with their actual locations. The candidate must match the SHA-256 pinned in `profiles/registry.json`. Never use patched data as the input.

In **RKTestOriginal**, after Steam setup, Cloud disablement, Offline Mode, and manual network disconnection:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/runtime/run-without-sandbox.ps1 -Lab "$env:USERPROFILE\private\rk-lab" -PatchedData "$env:USERPROFILE\private\candidate.win" -Case original -AttestSeparateWindowsAccount -AttestSteamOfflineAndCloudDisabled -Minutes 60
```

After the original exits, keep that account offline and close Steam. Switch to the **separate** RKTestPatched Windows account, repeat fresh Steam/lab preparation, and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/runtime/run-without-sandbox.ps1 -Lab "$env:USERPROFILE\private\rk-lab" -PatchedData "$env:USERPROFILE\private\candidate.win" -Case patched -AttestSeparateWindowsAccount -AttestSteamOfflineAndCloudDisabled -Minutes 120
```

The script stages only pinned game files, verifies their hashes, temporarily swaps the **test user's own** Steam-installed UNDERTALE directory with a uniquely marked copy, and restores the original registered test installation in a finally block. If restoration fails, it retains marked backups for manual recovery; never delete them blindly. It does not read or modify primary-account files, Steam caches or permanent saves. It records a private JSON report under `rk-lab\evidence\direct-windows`; status remains `NOT_RUN` for unreviewed observations or `BLOCKED` upon failure, not automatic `NATIVE_RUNTIME_PASS`.

Run the actual UI, input, battles, Forced warnings, saving/reloading and ending scenarios from the checklist below. Repeat only the **same** variant under the same test Windows account for settings/save persistence. Do not move an original-run save into the patched-run account or vice versa.

The direct harness does not use Sandbox or virtualization, does not bypass Steam licensing, does not accept credentials, and does not disable isolation checks. Native APIs/Steam launch and the exact source-modified game remain NOT_RUN until physically executed by the operator. Reconnect networking only after closing Steam/the game and retiring these test profiles. Steam/account-level history remains a risk even with different Windows users; a disposable VM/Sandbox offers stronger isolation.

## Windows-native Sandbox operator workflow (execution NOT_RUN)

Requires Windows11 Pro/Enterprise Sandbox, Python, the source tool build and the
pinned official UndertaleModCli. Use only the already authorized private ZIP. This
procedure never asks for Steam credentials in chat or maps host Steam/save folders.

1. On the host, prepare a NEW private lab and structurally compile a NEW candidate:

   ```powershell
   python tools/runtime_lab.py prepare --zip C:\private\runtime.zip --work C:\private\rk-lab
   RouteKeeper.Tool.exe build C:\private\rk-lab\original\Undertale\data.win C:\private\candidate.win C:\tools\UndertaleModCli.exe C:\src\undertale-routekeeper
   powershell -NoProfile -File tools/runtime/launch-windows-sandbox.ps1 -Lab C:\private\rk-lab -PatchedData C:\private\candidate.win -EnableSteamSetupNetworking
   ```

   The launcher checks the exact runner/data/candidate and pinned full inventory.
   It stages only allowlisted game files and harness scripts. Only sandbox-input
   is mapped read-only; a new empty evidence folder is mapped separately writable.
   The host's original tree, supplied account manifest, other lab files and prior
   evidence are excluded. Existing payloads refuse reuse. No installer approval
   or VerifiedPatch override is added.

2. Inside the fresh Sandbox only, set up the official licensed Steam client and
   disable Steam Cloud globally **before** registering/installing owned UNDERTALE
   in its default library, without starting it. Also disable the game Cloud option
   in Properties. If a cache was already downloaded, start a fresh VM and disable
   Cloud earlier; do not delete server records or reuse personal cached files. Use Steam > Go Offline and restart
   the client in Offline Mode. Open PowerShell **as Administrator** inside the VM.
   Never copy/map host Steam userdata, credentials or personal saves. The automatic
   initial harness deliberately records BLOCKED until setup is attested.

3. Run the original in the first fresh VM. Close that Sandbox while still offline.
   Reopen the same host routekeeper.wsb for a **new VM**, repeat offline Steam setup,
   and run the patch there:

   ```powershell
   & C:\RoutekeeperInput\inside-sandbox.ps1 -Case original -OfflineReady -Interactive -Minutes 30
   # In a NEW Sandbox after repeating step2 (not in the original case VM):
   & C:\RoutekeeperInput\inside-sandbox.ps1 -Case patched -OfflineReady -Interactive -Minutes 60
   ```

   OfflineReady is an operator attestation, not programmatic entitlement proof.
   The harness requires the expected Steam process, disconnects VM adapters before
   launch, refuses initial saves and any app391540 Cloud/cache files, verifies
   registration and hashes, and uses Steam -applaunch391540. A missing offline
   entitlement is BLOCKED; no Steam API replacement or ownership bypass is used.
   The registered VM installation is moved aside, never deleted; only this run's
   marked disposable copy is removed and the VM original restored in finally.
   A lost marker/reparse point fails closed and preserves directories for review.

   A VM session accepts only one Case. Steam SDK cached files can repopulate
   permanent history even after local saves are swapped, so case switching refuses.
   Repeat the SAME Case within its own VM for reload/settings persistence. Only
   RKTEST saves created by that session are eligible. Install-directory routekeeper.ini is also retained per
   case in case this runner resolves it there. No personal history is imported.

4. With the game closed, capture VM-only filesystem checkpoints. Prefer the actual
   in-game LOAD for validation. Restore additionally requires Steam fully exited
   and an empty app391540 cache, otherwise it deliberately refuses:

   ```powershell
   & C:\RoutekeeperInput\checkpoint-saves.ps1 -Name ruins-before
   & C:\RoutekeeperInput\checkpoint-saves.ps1 -Name ruins-before -Restore
   # While the game runs, invoke this and focus the game within three seconds:
   & C:\RoutekeeperInput\capture-game.ps1 -Case patched -Label korean-menu -DelaySeconds 3
   ```

   A filesystem checkpoint is not a VM/Steam memory snapshot. Restore never
   rewrites Steam caches; it retains the previous local save/history folder and
   refuses a local-only rewind that cached history could undo. Native validation
   of even the supported empty-cache restore remains NOT_RUN. Do not describe
   restored/edited test states
   as a legitimate full playthrough. Create ending/history fixtures through
   recorded disposable gameplay in a fresh VM per history scenario; never import
   a personal permanent-history file.

| Operator scenario | Required assertions; initial result NOT_RUN |
|---|---|
| Original then patched startup | Actual title/room, room transitions, clean exit; capture exact runner/data hashes |
| UI/settings | English/Korean, approved pixel geometry, HUD/menu/warning clipping, language/mode/target/spoiler persistence after restart |
| Controls | Confirm/cancel/menu close, held keys, simultaneous input, warning acknowledge and one matching replay; gamepad only if actually forwarded |
| Modes and actions | Off untouched; Passive/Active dismissible; Forced scoped; FIGHT/ACT/items/MERCY/FLEE; no inventory/HP/EXP side effects from refusal |
| Pending EXP | Two-enemy LV1 encounter: first kill's unbanked EXP affects second action; acknowledge/decline/switch modes; win/FLEE banks once |
| Automatic events | EX below/at each rating/turn threshold, repeated qualification/Alarm/writer completion/attack wrap, both controller orders; no trapped required FIGHT |
| Reload/deadlines | Same-room reload revokes warning acknowledgement; water departure and friendship order; SAVE and reload; RESET and TRUE RESET only on these VM saves |
| Endings | Representative Neutral, Pacifist, Genocide and Soulless playthroughs; record history provenance and actual final playback; optional calendar-gated Art Club separately |

Private reports/screenshots go to the separate evidence mapping. Captures require
the marked game in the foreground and crop its client area; the Steam/desktop
window is excluded. Capture failure is NOT_RUN, not gameplay failure or PASS. Interactive runs
wait for game exit or the declared time limit; short smoke runs observe20 seconds.
A process/window/screenshot never automatically becomes NATIVE_RUNTIME_PASS; the
harness writes NOT_RUN pending scenario assertions. Record observations and failed
assertions alongside each run ID. It does not change the compatibility registry.

All scripts pass offline AST/guard tests under official PowerShell7.6.8 on Linux;
the host allowlist staging/XML mapping was executed with Sandbox dispatch mocked.
Windows API behavior, Steam readiness and actual Sandbox execution remain NOT_RUN.
If Sandbox exposes a mapped root as a reparse point, guards deliberately refuse
it until that mapping is reviewed; do not disable isolation checks to proceed.
Sandbox may not forward a hardware gamepad. Mark that test NOT_RUN and validate
later in a separately reviewed disposable Windows VM with controller passthrough.
Native macOS/Linux still require their own exact-build inputs and native runs.

## Cleanup

Stop/remove only task-owned runtime containers. Remove task-owned tool images and
failed temporary Wine prefixes after preserving useful private evidence. Delete
new-runtime-lab, new-candidate.win and private screenshots/logs when no longer
needed; the marker identifies task-owned disposable storage. Keep the VM offline after all tests; close Sandbox to
discard its Steam session and VM files before any network reconnection. Keep the verified supplied ZIP/pristine
inputs until intentionally removed. Follow private-data.md for Release/LFS/cloud
cleanup; deleting local files does not promise deletion from backups or Git history.
