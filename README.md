# ROUTEKEEPER

Private development of native UNDERTALE route guidance. The implementation now
includes five ending families, 18 specific Neutral targets plus Any, Pacifist
Stay/Leave variants, live state bindings, objectives/progress, bilingual settings
and scoped pre-decision protections. **Runtime-unverified; not release-ready.**

Game data compiles with a persistent GML controller, original-style EN/KR UI and
Off/Passive/Active/Forced modes. It uses the original runner without a runtime
loader. The current authentic profile is diagnostic-only, so installation is
refused until legitimate gameplay scenarios establish support. Forced is scoped;
it does not guarantee every ending or rewrite EXP, survival or permanent history.

## Build and verify

Install the SDK pinned in global.json. Executable test runners use `dotnet run`:

```sh
dotnet build RouteKeeper.slnx -c Release
dotnet run --project tests/RouteKeeper.Core.Tests -c Release
dotnet run --project tests/RouteKeeper.Neutral.Tests -c Release
dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release
dotnet run --project tests/RouteKeeper.History.Tests -c Release
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

See [progress](docs/PROGRESS.md), [test evidence](docs/test-results.md),
[route rules](docs/route-rules.md), [state/hook evidence](docs/state-bindings.md),
[compatibility](docs/compatibility.md), [runtime needs](docs/runtime-validation.md),
and [private input cleanup](docs/private-data.md). Repository privacy and data
exposure must be audited before any public release. No game binaries, substantial
original resources or personal saves belong in commits or ordinary CI artifacts.
