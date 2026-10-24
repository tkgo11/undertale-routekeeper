# Experimental native integration

This is a real GameMaker bytecode patch, not an external overlay. It adds four code resources, a persistent controller object, a font and a separate atlas. Steam's original runner can read the generated data file in principle; no runtime loader is introduced. **No runner or gameplay test has occurred. Do not install this experimental output into a working Steam installation.** The installer deliberately rejects its profile until runtime verification.

Requires UndertaleModCli / UndertaleModLib **0.9.2.0** and .NET 10. The C# scripts use the upstream `CodeImportGroup`, `GlobalDecompileContext`, `UndertaleGameObject`, and `GMImage` APIs. Run from the repository root:

```sh
# Regenerate shared declarative evaluator (no authentic game required):
dotnet run --project tests/RouteKeeper.Core.Tests -- --emit-gml integration/gml/route_evaluate.gml
# Explicit experimental output in ignored research storage only:
UndertaleModCli load private-data/data.win -s integration/patch.csx -o .research/routekeeper-data.win
ROUTEKEEPER_ORIGINAL=private-data/data.win UndertaleModCli load .research/routekeeper-data.win -s integration/verify.csx
```

`patch.csx` requires an explicit new destination file, rejects existing destinations (even with `-f`) and symbolic link paths, and rejects any input whose SHA-256, bytecode, resource counts, startup hook signature, or XP binding differs. Do not pass an output path equal to the source. Use the safe installer only for profiles later approved with runtime evidence. Regeneration never writes to save files or permanent history.

## Current behavior

The selected route is fixed to an **incomplete True Pacifist slice**. `global.xp` is read into the shared normalized evaluator. All other prerequisites, including permanent history, remain `-1` (unknown). Missing bindings cannot produce an on-track guarantee. The controller recalculates every step; the conservative GUI/input gate allows only free overworld control with a main player, no battle controller or soul, no cutscene and debug disabled. These gates are structurally verified, but require runtime validation across rooms and story events.

Default Passive mode is quiet until a blocked status is observed. Active displays a small spoiler-minimal hint. F10 shows a non-pausing settings panel; F11 cycles Off/Active/Passive, F12 toggles English/Korean, F8 dismisses a warning. No default movement, confirm or cancel keys are consumed. Existing F10-F12 handlers on the inspected build are debug-only, and our panel is disabled in debug mode. Gamepad settings controls are not implemented. Forced is unavailable, and no decision is intercepted yet. A warning after EXP gain is **not** a pre-decision warning.

Settings use a separate `routekeeper.ini` file; no `file0`, `file8`, `file9`, `undertale.ini` or `system_information_*` file is modified. INI access is synchronous, outside vanilla save functions, in controller Create or safe overworld Step. Runtime tests must still check simultaneous game save behavior.

The embedded font atlas contains ASCII and every Hangul character in the shipped GUI source. It is generated from Noto Sans CJK under SIL OFL 1.1; see `assets/FONT-LICENSE.txt`. The game uses the embedded resource, with no installed font dependency. Regenerate after changing UI strings:

```sh
python3 -m pip install Pillow
python3 integration/generate_font.py --font /path/to/NotoSansCJK-Regular.ttc
```

`verify.csx` reloads the generated output and checks linked code, observed XP, shared evaluator invocation, conservative gates and Hangul glyph coverage. With `ROUTEKEEPER_ORIGINAL`, it also compares disassembly of all 6,271 unmodified original code resources. This proves bytecode compilation/serialization/decompilation, not gameplay behavior or compatibility with a particular Steam build.
