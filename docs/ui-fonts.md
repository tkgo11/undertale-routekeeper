# Native UI and font evidence

The layout uses the inspected `obj_dialoguer` border (logical x16..304, 3px solid
white with a black interior), settings-menu yellow selection, and the original
`fnt_maintext` English font. A mod-owned pixel heart marks the selected row.
Geometry/localization live in integration/ui/catalog.json and generate native GML.
The ordinary HUD is one line (28/240 screen height). Full objectives/progress and
paged ending choices are in submenus. Developer verification text is absent from
normal screens. F10/unbound pad button opens; native arrows/confirm/cancel navigate.
The source-pinned player Step gate holds movement and interaction while open.
Warnings own only the deferred decision; no global pause or save mutation is used.

## Korean source selection

- [Minio-KR translation](https://github.com/Minio-KR/undertale-kr-translation)
  explicitly identifies itself as a Team Waldo port. Its maintext CSV declares
  8bitoperator JVE, size12, anti-aliasing0; all 11,172 Hangul records have
  width14/height16/advance14. These metadata were inspected read-only. The repository
  has no clear font redistribution license, so none of its atlas images are bundled.
- [Undertale-Fonts-Extra](https://github.com/XiaoAkatsukiCN/Undertale-Fonts-Extra)
  includes Dotumche and derivative fonts, but its author disclaims ownership and
  restricts commercial use. This is insufficient permission for our redistribution;
  no assets were copied. Available primary evidence does not establish the exact
  original Team Waldo font-family/licensing history. We do not invent attribution
  or treat Microsoft-installed fonts as freely redistributable.
- [Galmuri](https://github.com/quiple/galmuri), commit
  71e1cacf1437a11220307120e63e30bc275312d4, is explicitly SIL OFL1.1. Galmuri14
  provides a 14px Hangul bitmap with 15px advance, closer to the translation's
  inspected metrics than Galmuri11's smaller cells. The derived atlas is named
  Routekeeper Korean Pixel; original copyright and full license accompany it.

The previous Noto Sans CJK atlas was antialiased, rasterizer-dependent and aligned
individual glyphs by their upper ink edge. The new pipeline reads pinned BDF bits:
no host font/Pillow/rasterizer during generation, binary alpha, common baseline14,
18px line cells and explicit left-overhang offsets. Cells retain sufficient padding.
A one-bit PNG with canonical stored DEFLATE blocks avoids zlib-version compression
drift; glyph order, source hash, metrics and bytes are checked on every platform.
Native font anti-aliasing is disabled. Actual renderer filtering still needs runtime
validation. The complete unchanged compressed OFL source permits adding glyphs
offline; glyphs absent from that source fail generation rather than silently tofu.

## Reproducible offline checks

```sh
python integration/ui/generate.py --verify
python integration/generate_font.py --verify
python integration/ui/test_ui.py
dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release -- --verify-ui integration
python integration/ui/preview.py --output artifacts/ui-preview
```

Pillow11.3.0 is pinned in CI for previews/tests; generation/verification is stdlib.
The preview default substitutes licensed outlines for English while using observed
native advance metrics. For actual native English outlines, privately export from
the already supplied exact input (never commit/upload the atlas):

```sh
ROUTEKEEPER_PREVIEW_FONT=/absolute/repo/.research/ui-native-font UndertaleModCli load private-data/data.win -s integration/export-preview-font.csx
python integration/ui/preview.py --output artifacts/ui-preview --native-font .research/ui-native-font
```

The exporter is read-only and restricts output to .research. Preview evidence.json
labels OFFLINE_PREVIEW/gameplay NOT_RUN and records layout/font hashes. Tests cover
both languages, every warning/acknowledgement state, cursor wrap/paging, complete
objective fit, bounded clipping, full progress counters, glyph baseline/coverage,
binary pixels and deterministic font bytes. A separate source interpreter compares
664 generated navigation/localization cases. None executes the GameMaker runner;
fullscreen/window scaling, actual event ordering and controller hardware remain
runtime scenarios.
