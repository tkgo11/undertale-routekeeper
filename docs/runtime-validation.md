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
| Official patched runner | BLOCKED | Same failure with the compiled candidate, before gameplay/controller evidence |
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

## Reproduce compatibility smoke

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

## Windows-native harness (NOT_RUN)

Use Windows11 Pro/Enterprise with Windows Sandbox enabled. Prepare a new lab with
runtime_lab.py and a structurally verified candidate, then:

```powershell
powershell -NoProfile -File tools/runtime/launch-windows-sandbox.ps1 `
  -Lab C:\private\new-runtime-lab -PatchedData C:\private\new-candidate.win `
  -EnableSteamSetupNetworking
```

The first automatic script records BLOCKED if Steam is absent. Inside that fresh
VM only, set up the official Steam client with legitimate ownership and register
or install UNDERTALE from authorized inputs. Do not launch it yet. Do not map host
Steam userdata, credentials or save folders. Rerun C:\RoutekeeperLab\inside-sandbox.ps1
as Administrator inside the VM once Steam is ready. It disconnects VM networking before game launch,
refuses existing local saves or Steam Cloud cache, checks the exact runner and
candidate, switches disposable library copies and launches through Steam
-applaunch391540. It captures private observations and clean-close behavior.

The input lab is mapped read-only into Sandbox; only a separate evidence mapping
is writable. Both scripts passed AST parsing under official PowerShell7.6.8 on Linux, and
the initial normal-account refusal was exercised. Windows API/isolation/runtime
behavior has NOT been executed here. It deliberately records NOT_RUN
pending review/scenario assertions, never promotes a profile, and cannot supply
Steam authentication. A Steam session alone is not proof of entitlement or safe
Cloud state. Any failed isolation check stops the harness.

After startup is genuinely available, use a fresh RKTEST playthrough and first
SAVE as the reproducible base. Complete the scenario matrix:original/patch startup,
rooms/exit; settings persistence and EN/KR; keyboard/pad isolation; Off/Passive/
Active/Forced; FIGHT/ACT/item/MERCY/FLEE; acknowledgement and scripted EX boundary;
SAVE/reload and resets; representative endings with explicit permanent-history
fixtures in the disposable VM. Never reuse a personal save as a mutable fixture.
Keep synthetic snapshot tests distinct from full legitimate playthroughs.

## Cleanup

Stop/remove only task-owned runtime containers. Remove task-owned tool images and
failed temporary Wine prefixes after preserving useful private evidence. Delete
new-runtime-lab, new-candidate.win and private screenshots/logs when no longer
needed; the marker identifies task-owned disposable storage. Close Sandbox to
discard its Steam session and VM files. Keep the verified supplied ZIP/pristine
inputs until intentionally removed. Follow private-data.md for Release/LFS/cloud
cleanup; deleting local files does not promise deletion from backups or Git history.
