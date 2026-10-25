# Native integration evidence

Inspected on 2026-10-24. No substantial upstream implementation or copyrighted decompiled game code is distributed here.

## Upstream implementation inspected

- [UndertaleModTool](https://github.com/UnderminersTeam/UndertaleModTool), revision `f43e12c445c37d50dc6244caa12ccab232983f3f`: `UndertaleModLib/Compiler/CodeImportGroup.cs`, `Models/UndertaleFont.cs`, `Models/UndertaleTexturePageItem.cs`, `Util/GMImage.cs`, CLI script execution in `UndertaleModCli/Program.cs`; shipped `ShowRoomName.csx`, `UndertaleDebugToggler.csx`, `ImportGML.csx`, `ExportAllCode.csx`. Current library targets net10.0, version 0.9.2.0, GPLv3. We invoke the separately installed tool; our `.csx` scripts use its API.
- [Undertale Mod Menu](https://github.com/ryuya0229/undertale-mod-menu), revision `60c49c3981863087b1b68bc59e3c0cdfd8be8213`: `src/Patcher/ModInjector.cs` and `gml/obj_modmenu_step.gml`. Reviewed controller startup creation, persistent object/event binding, battle/overworld menu gates, native font glyph injection. ROUTEKEEPER code is independently written, with no cheat logic or copied implementation.
- [UndertaleL10n](https://github.com/kamarkiewicz/UndertaleL10n), revision `b5bdf8461d6ba6c84800bed6fd14b2b17a876c3a`: `scripts/source_info.csx`, `check_fonts.csx`, and patch/script layout. Reviewed exact binary hashing and font glyph completeness workflow. No translation assets copied.
- GameMaker Studio 1 documentation mirror confirms [`draw_get_font`](https://docs.gamebar.me/gmsDocs/source/_build/3_scripting/4_gml_reference/drawing/text/draw_get_font.html), [`draw_get_halign`](https://docs.gamebar.me/gmsDocs/source/_build/3_scripting/4_gml_reference/drawing/text/draw_get_halign.html), and [`draw_get_valign`](https://docs.gamebar.me/gmsDocs/source/_build/3_scripting/4_gml_reference/drawing/text/draw_get_valign.html). These unused-by-vanilla builtin function entries must be added via `EnsureDefined` before compiling our GUI.

## Supplied authentic data inspection

Private release `dev-game-data` provides `data.win`, `file0`, `file8`, `file9`, and `undertale.ini`. Local files and all research/decompilation outputs remain ignored. The data file is 62,921,978 bytes, SHA-256 `b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7`, historical MD5 `5903fc5cb042a728d4ad8ee9e949c6eb` (computed observation, not upstream provenance). GameMaker bytecode 16, non-YYC, non-GMS2; 6,272 code resources and 336 rooms.

The uploaded filename does not establish OS or architecture. At the initial inspection no runner/manifest/build metadata was supplied; the
2026-10-25 authorized runtime continuation now records them in runtime-validation.md. Nominal internal version cannot identify Steam build. This is an analyzed exact hash, **not a runtime-supported Steam profile**.

Read-only decompilation verified `obj_time` is persistent and its Create event can spawn our persistent controller. `scr_load` binds the saved XP value to **`global.xp`**, not `global.exp`; this was the initial slice; the current adapter also binds the separately signature-verified predicates in profiles/bindings.json. `obj_mainchara` initializes `cutscene` to zero; `global.interact` controls ordinary world interaction. `obj_battlecontroller` and `obj_heart` are present. Existing F10-F12 player key handlers are guarded by debug mode. We disable our UI in debug mode rather than altering vanilla debug events.

Verification checks the exact startup-hook decompilation SHA-256 `2c96d9edfaab627915a0b7d8c05eb5c57353225602c52f772e36bb50730aba88`, in addition to the whole-file hash. The signature is specific to the pinned decompiler tool. It detects tool drift, not only binary drift.

The expanded binding manifest now records the inspected friendship, event-order, ending, quota and history predicates. See state-bindings.md and profiles/bindings.json for current evidence. No save mutation is authorized by observation.

## Limits and immediate next evidence

When later authorized matching inputs are available, test startup and controller lifetime, text rendering, draw-state restoration, hotkeys, settings persistence, safe UI gating, room transitions, battle timing and save/reload. Bind the next normalized prerequisite only after inspecting its exact game implementation and writing a scenario test. Keep `StructuralPatchTested` profiles rejected by the installer until these tests establish supported behavior.

The pre-consumption battle-item adapter classifies Spider Donut (7) and Spider Cider (10) as a potential Muffet resolution. Pinned scr_itemuseb and spider user/step events establish the path to the abandonment flag. It reuses the generated Spare policy before writer, item, HP or turn changes; ordinary items and non-Muffet encounters remain available. Last-live Snowdrake remains recoverable after population exhaustion and is protected from Spare/Flee; the final random kill is refused only while fleeing remains available. Runtime behavior remains NOT_RUN.

## Call-goal continuation evidence (2026-10-25)

Existing authentic scripts inspected: scr_itemuseb, scr_armoreq, scr_recoitem,
scr_levelup, scr_save/scr_saveprocess, SCR_GAMESTART, obj_overworldcontroller Draw,
Snowdrake Step, instant-noodle Step, Lab1 door Alarm2, finalelevatorpanel Draw,
labelevator_a Step and lab power switch. Source SHA/markers are pinned in bindings.
No original implementation is copied into distributed source. Lab room metadata
confirms fire_labelevator242 -> truelab_elevatorinside243 -> truelab_elevator244;
interception happens at the recoverable Lab1 door. The final power switch sets
flag49312, so intercepting only there would be too late. Generated predicates,
transaction tests and authentic item-case extraction verify the independent parts.
Mettaton EX rating completion was inspected but is not yet a protected adapter:
its automatic turn boundary needs coherent pre-input prediction, not scene freezing.
