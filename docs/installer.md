# ROUTEKEEPER tool and native source package

Experimental. No current authentic profile permits installing into a live game.
The package contains original ROUTEKEEPER GML/scripts, a font subset licensed under
SIL OFL, diagnostic profiles and the independent .NET tool. It contains no game
binaries or personal saves. The game uses native GML and needs no runtime loader.

Use the matching legitimate Steam game files. Install the separately distributed
[official UndertaleModCli 0.9.2.0](https://github.com/UnderminersTeam/UndertaleModTool/releases/tag/0.9.2.0)
for your host, preserving its upstream license and notices. This is a build-time
compiler, not a game launcher or runtime mod loader.

```sh
RouteKeeper.Tool discover
RouteKeeper.Tool inspect /path/to/data.win
RouteKeeper.Tool inspect-runner /path/to/UNDERTALE.exe
RouteKeeper.Tool build /path/to/data.win /private/new-candidate.win /path/to/UndertaleModCli
RouteKeeper.Tool install-source /path/to/data.win /path/to/UndertaleModCli PLATFORM ARCH
RouteKeeper.Tool restore /path/to/data.win
```

On Windows use `RouteKeeper.Tool.exe` and `UndertaleModCli.exe`. Quote paths with
spaces. Published packages contain their own .NET runtime. If running from source,
append the repository root as the last argument to `build` / `install-source`.

`build` reads an exact recognized input, compiles from a disposable copy, validates
scripts/resources and every non-hook original code resource, and writes a **new**
candidate. It never replaces the game file. Candidate generation is structural
testing, not approval of gameplay compatibility.

`install-source` first requires a uniquely verified platform/architecture profile;
then it builds and uses the transactional installer. Diagnostic profiles are
rejected before any compiler or installation operation. All current authentic
profiles are diagnostic, so this command intentionally refuses installation.
Updates retain the hash-verified pristine backup. `restore` retains the backup
and journal for recovery. Saves and permanent history are not installer inputs.

Executable headers report architecture and format only. ELF SysV does not prove
Linux, Mach-O does not prove a particular Apple OS, and none proves that a file
is UNDERTALE or matches the supplied game data. Steam metadata and runtime tests
remain separate compatibility evidence.

Galmuri-derived font copyright/license is in `integration/assets/FONT-LICENSE.txt`.
.NET runtime license/notices are in `licenses/dotnet/`. Official compiler licensing
is GPLv3; this package does not redistribute that compiler. Do not publish a
candidate game data file, pristine backup, save, or private diagnostic source dump.

## Optional G3M export

`g3m-package ORIGINAL CANDIDATE XDELTA3 NEW_ZIP PLATFORM ARCH [ASSET_ROOT]` generates
a mod_config2.0.0 ZIP for the inspected G3M3.4.3 format. It requires an approved
exact profile, approved candidate hash and a verified `GameDataRelativePath` in
that profile. No authentic profile currently qualifies; this is intentionally
refused before invoking external tools. A separately installed xdelta3 is needed
only for packaging. It is not bundled and is not a game runtime dependency.

The package contains a VCDIFF delta, never a replacement game binary. Its operation
pins both the delta's source_hash and the pristine target_hash. The target is a
validated path below ${game_path}; ${game_data_path} alone is rejected by the actual
upstream parser. The builder encodes/decodes disposable copies and checks the exact
candidate hash before creating a deterministic new ZIP. It never installs through
G3M automatically. G3M manages its own transactions; older G3M formats are not
claimed compatible. No public package is released by this command.

Source contract: y114git/G3M commit87ece8a61e55b6208b374bc6ea15f795b565c61c,
utils/mod/config.py, services/mod_operation_executor.py and
workers/modpack_create_worker.py. The actual parser and synthetic real-xdelta
roundtrip were exercised locally. No upstream implementation was copied.
