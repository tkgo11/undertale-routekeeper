# ROUTEKEEPER

Private development of native UNDERTALE route guidance. The implementation now
includes five ending families, 18 specific Neutral targets plus Any, Pacifist
Stay/Leave variants, live state bindings, objectives/progress, bilingual settings
and scoped pre-decision protections. The pixel UI now uses native-style submenus,
a compact HUD and a licensed Korean bitmap font. **Runtime-unverified; not release-ready.** Default same-account Run is code-disabled
(NO-GO), including the original runner; read-only Preflight remains available.

Game data compiles with a persistent GML controller, original-style EN/KR UI and
Off/Passive/Active/Forced modes. It uses the original runner without a runtime
loader. The current authentic profile is diagnostic-only, so installation is
refused until legitimate gameplay scenarios establish support. Forced is scoped;
it does not guarantee every ending or rewrite EXP, survival or permanent history.

Offline screen contracts and deferred human/AI visual review are available without
launching the game: [screen verification guide](docs/screen-verification.md).
Visual approval never proves gameplay correctness or removes the startup NO-GO.

Windows testing uses one [documented entry point](docs/windows-e2e.md) for offline
preparation, synthetic DryRun and native non-game validation. A separately consented
original startup probe remains runtime-unverified; full patched/gameplay automation
is blocked by missing baseline/input evidence. Default Run stays NO-GO.

## Build and verify

Install the SDK pinned in global.json. Executable test runners use `dotnet run`:

```sh
dotnet build RouteKeeper.slnx -c Release
dotnet run --project tests/RouteKeeper.Core.Tests -c Release
dotnet run --project tests/RouteKeeper.Neutral.Tests -c Release
dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release
dotnet run --project tests/RouteKeeper.History.Tests -c Release
dotnet run --project tests/RouteKeeper.Audit.Tests -c Release
dotnet run --project tests/RouteKeeper.Tool.Tests -c Release
dotnet run --project tests/RouteKeeper.Saves.Tests -c Release
python integration/generate_font.py --verify
```

AGENTS.md lists generated-source freshness/regeneration commands. The private
structural harness compiles the supplied authentic data, reloads it, checks the
intended hook footprint and preserves original code/assets. It is not gameplay.

## Standalone source builder and installer

```sh
dotnet run --project src/RouteKeeper.Tool -- discover
dotnet run --project src/RouteKeeper.Tool -- inspect DATA
dotnet run --project src/RouteKeeper.Tool -- inspect-runner EXECUTABLE
dotnet run --project src/RouteKeeper.Tool -- build DATA NEW_OUTPUT CLI .
dotnet publish src/RouteKeeper.Tool -c Release -r linux-x64 --self-contained true -p:PublishSingleFile=true -o artifacts/tool
```

Published packages include native source/assets/profiles and runtime notices, with
no game data. [Installer instructions](docs/installer.md) explain build/install/
restore and the separately installed official compiler. Candidate generation uses
a disposable original copy. Actual installation requires a runtime-verified exact
profile and retains a pristine backup/journal. No current authentic profile has
that approval. Existing unknown modifications are not patched automatically.

Optional exact-hash G3M2.0.0 packaging is implemented; authentic export remains
gated on runtime-verified profiles. [UI/font evidence and offline previews](docs/ui-fonts.md).

See [progress](docs/PROGRESS.md), [test evidence](docs/test-results.md),
[route rules](docs/route-rules.md), [state/hook evidence](docs/state-bindings.md),
[compatibility](docs/compatibility.md), [runtime needs](docs/runtime-validation.md),
[Steam safety](docs/steam-safety.md), [technical reference](docs/technical-reference.md),
[latest offline audit/status](docs/offline-audit-2026-10-27.md),
[historical non-runtime baseline](docs/non-runtime-status.md),
and [private input cleanup](docs/private-data.md). Repository privacy and data
exposure must be audited before any public release. No game binaries, substantial
original resources or personal saves belong in commits or ordinary CI artifacts.

The supplied Windows runtime/manifest is now hash-identified. Historical original and40d67856 patched
official-runner attempts under Wine/QEMU were BLOCKED at Steam initialization;
the current4457dbf4 candidate has no runner execution evidence;
no gameplay PASS is claimed. See [runtime validation](docs/runtime-validation.md)
for isolated commands, evidence and the Windows-native harness.
`RouteKeeper.Tool analyze-reachability` reports bounded source witnesses and explicit
unknowns; it is not a runtime compatibility or full reachability proof.

## Mod translations

ROUTEKEEPER UI/guidance uses the data-only [locale contributor guide](locales/README.md).
Add a disabled template with `python tools/localization.py add --locale es --name Español`,
translate/register it, then run `python tools/localization.py build`. English/Korean
remain the validated enabled locales; legacy settings migrate to stable tags.
This does not translate the original game or establish native runtime compatibility.
