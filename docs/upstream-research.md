# Upstream inspection

Inspected on 2026-10-24. Clones and decompiled game code are private, ignored inputs.
No upstream game assets or complete third-party implementation were vendored.

| Source | Revision | Implementation inspected | Consequence |
|---|---|---|---|
| UndertaleL10n | b5bdf84 | scripts/build_data.csx, scripts/check_fonts.csx | Glyph coverage requires real atlas + glyph metadata; translated strings alone do not provide Hangul rendering. No license file was found at the repository root; no code/assets copied. |
| Undertale Mod Menu | 60c49c3 | src/Patcher/ModInjector.cs, gml/obj_modmenu_draw_gui.gml | Native object events and restoring draw state matter; Japanese font coverage does not establish Korean coverage. |
| Undertale BioMod | 6af30ab | BioMod.csx | CodeImportGroup/event hooks and obj_time lifecycle corroborated; GPL-3.0-only implementation not copied. Permanent-history existence must be handled separately from ordinary saves. |
| G3M | 9565411 | src/utils/mod/version_package.py, src/models/game_modes.py | Current packaging uses mod_config.json, root files and optional mod_versions archives. Optional support deferred until install/runtime validation. GPL-3.0 project not copied. |

UndertaleModTool/UndertaleModLib API and exact revision evidence are recorded in
integration-research.md. Installed CLI is 0.9.2.0; installed SDK is .NET 10.0.402.
The implementation uses independently written code and invokes the CLI externally.
Redistribution of the upstream CLI must preserve its license/dependency notices.

Initial Python urllib requests returned HTTP 403. Ordinary curl requests then
successfully fetched undertale.wiki route/SAVE articles, official GameMaker
`ini_open` documentation and SteamDB depot metadata. No access restriction was
bypassed. Official documentation confirms that only one INI can be open at once;
mod settings must close their own INI promptly and avoid disrupting game saves.
SteamDB reports public build 4279148 and depots 391541 (Windows), 391542 (macOS),
391544 (Linux). This does not establish which depot produced the uploaded file:
no appmanifest, depot manifest, executable or user version metadata was supplied.
The uploaded file's build/depot provenance remains unknown.

Primary URLs:
- https://github.com/UnderminersTeam/UndertaleModTool
- https://github.com/kamarkiewicz/UndertaleL10n
- https://github.com/ryuya0229/undertale-mod-menu
- https://github.com/BioTomateDE/UndertaleBioMod
- https://github.com/y114git/G3M
- https://undertale.wiki/w/True_Pacifist_Route
- https://undertale.wiki/w/Genocide_Route
- https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/File_Handling/Ini_Files/ini_open.htm
- https://steamdb.info/app/391540/depots/
