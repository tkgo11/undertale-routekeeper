# ROUTEKEEPER

Private development of native UNDERTALE route guidance. **Experimental, incomplete,
and not approved for installation into a live Steam game.** No game binaries or
personal saves are distributed by this source tree.

The current vertical slice compiles a persistent native GML controller, an
English/Korean HUD and settings into one inspected, authentic game data file.
Only EXP observation is currently bound to verified vanilla state. Other facts
remain unknown. No complete ending guarantee or Forced intervention is available.
A compiled patch is not evidence that gameplay works.

## Build and test

Install the SDK pinned in `global.json`, then:

```sh
dotnet build RouteKeeper.slnx -c Release
dotnet run --project tests/RouteKeeper.Core.Tests -c Release
dotnet run --project tests/RouteKeeper.Tool.Tests -c Release
dotnet run --project tests/RouteKeeper.Saves.Tests -c Release
dotnet run --project tests/RouteKeeper.Core.Tests -c Release -- --verify-gml integration/gml/route_evaluate.gml
```

Tests are dependency-free executable runners with nonzero failure exit codes.
They are intentionally invoked with `dotnet run`, not `dotnet test`.

## Inspect game data safely

```sh
dotnet run --project src/RouteKeeper.Tool -- discover
dotnet run --project src/RouteKeeper.Tool -- inspect /path/to/data.win
dotnet run --project src/RouteKeeper.Tool -- diff /path/to/original /path/to/candidate
```

Discovery reads conventional Steam library locations and appmanifest hints. It
never approves a build based on filenames, display version or Steam metadata
alone. `diff` compares FORM chunks; script-level semantic comparison is pending.
The compatibility registry requires exact hashes, sizes, bytecode, structural
signatures, platform/architecture and one explicitly verified patch profile.
Current authentic profiles are diagnostic-only, so production installation fails
closed. Do not change their status to bypass this requirement.

## Development patch generation

See [integration research](docs/integration-research.md) for the pinned
UndertaleModCli release, commands and actual-bytecode verification evidence.
Game data and generated patched files belong only in ignored private directories.
The development script accepts one exact original hash and adds native GML;
Steam would launch the game normally after a future verified installation.
No external runtime mod loader is introduced.

## Installer foundation

```sh
dotnet run --project src/RouteKeeper.Tool -- install TARGET CANDIDATE profiles/registry.json PLATFORM ARCH
dotnet run --project src/RouteKeeper.Tool -- restore TARGET
dotnet publish src/RouteKeeper.Tool -c Release -r linux-x64 --self-contained true -p:PublishSingleFile=true -o artifacts/tool
```

`install` consumes a separately generated candidate, verifies it against an
approved output hash, retains a verified pristine backup, and records a recovery
journal beside the target. It refuses external modifications and corrupt backups.
`restore` retains the original backup and journal to permit verification/recovery.
Only the data file is modified; saves and permanent history are untouched.
No current authentic profile authorizes installation. Installer crash recovery is
synthetically tested; real power loss and live-game installation remain untested.

GitHub Actions builds/tests on Windows, Linux, Apple Silicon macOS and Intel
macOS, then packages self-contained installer tools. CI does not download private
game inputs and never uploads game data.

See [progress](docs/PROGRESS.md), [test evidence](docs/test-results.md),
[compatibility](docs/compatibility.md), [route rules](docs/route-rules.md), and
[private data/cleanup](docs/private-data.md). Preserve repository privacy until a
proprietary-data audit authorizes publication.
