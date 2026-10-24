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

Noto font copyright/license is in `integration/assets/FONT-LICENSE.txt`.
.NET runtime license/notices are in `licenses/dotnet/`. Official compiler licensing
is GPLv3; this package does not redistribute that compiler. Do not publish a
candidate game data file, pristine backup, save, or private diagnostic source dump.
