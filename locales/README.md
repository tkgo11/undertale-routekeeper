# Translating ROUTEKEEPER

This translates the mod's menus and guidance, **not UNDERTALE**. No game runner,
network service, runtime loader or original-game assets are needed for this workflow.
Use Python 3.12+, the pinned .NET SDK, and Pillow11.3.0 for previews.

## Add, translate, validate, build

```sh
python tools/localization.py add --locale es --name Español --font galmuri14
# Edit locales/es.json; source wording and context are in locales/templates/es.context.json.
python tools/localization.py validate --locale es
# When complete: set enabled=true and status="complete" for es in languages.json.
python tools/localization.py build
python tools/localization.py preview --locale es
python tools/localization.py coverage
python tools/localization.py build --verify
```

The example creates an **empty, disabled draft**, not an endorsed Spanish
translation. Supply accurate translations and verify layout/font coverage before
enabling. No gameplay rule, language enum, UI option count or font injection code
needs editing. The build compiles the same JSON into .NET embedded resources and
native GML dictionaries, regenerates objectives, UI glue and font atlases. Run this
build before generating a patch. Translation JSON is build input, not a file loaded
by the running game. Packaging includes the source catalogs for inspection.

Keep locale tags stable, lowercase and unique (`en`, `ko`, `es`, `ja`, `en-gb`).
Tags are bounded to63 characters; text values to2048.
The registry order is the menu order; enabled entries are limited to32. English
must be first; Korean, while enabled, remains second for old API compatibility.
Future settings store the **tag**, so reordering other entries does not change the
selected language. The legacy numeric INI values0/1 still mean English/Korean;
unknown tags, removed locales and invalid legacy numbers fall back to English.
Schema4 writes only routekeeper.ini, never vanilla saves/history. F12 cycles all
registered languages **inside settings**, retaining its previous scope. The language
picker uses the existing seven-row paging/navigation and each entry's own font.

## Dictionaries and context

`en.json` is canonical. Semantic IDs are stable API: do not rename an ID because
its English wording changes. `ko.json` is an independent dictionary. Every key has
translator context, spoiler guidance and named placeholders in `context.json`.
Minimal/detailed objectives have separate IDs selected by existing gameplay code;
translations cannot change severity, requirements, quantities or enforcement.
`{remaining}`, `{index}`, `{met}`, `{total}`, `{button}` and `{character}` are
named substitutions; preserve required names. Context may explicitly allow an
omission (the existing Korean generic encounter message omits `{character}`).
Literal double quotes are allowed: generation uses `chr(34)` concatenation because
GML1 does not accept JSON-style backslash quote escapes.
Plural grammar must work for all quantities; executable expressions/plural rules
are deliberately unsupported by this legacy-safe, data-only format.

Enabled locales must contain **every key and no empty/obsolete entries**. They
cannot silently fall back for incomplete translations. An explicit `fallback-en`
policy permits missing keys only when validating a disabled draft; coverage and
validation list the fallback keys. Empty values always fail. Unknown runtime locale
selections fall back to English independently of this translation completeness gate.

Save UTF-8/LF and NFC-normalized text. Duplicate JSON keys, controls, newlines,
literal backslashes, legacy `#` newline syntax, malformed braces/placeholders, non-BMP,
combining marks, bidi and known shaping-dependent scripts are refused. Composed
Hangul, supported CJK/kana and accented Latin **can** work with a covered licensed
bitmap font; UTF-8 by itself does not establish rendering support. Scripts outside the explicit scalar-script allowlist, including Indic, Thai,
Arabic, Hebrew and decomposed Hangul must remain disabled without separately
verified shaping/bidi work. No implicit missing-glyph boxes or truncation is allowed.

## Fonts

English retains the original `fnt_maintext`; only its lawful numeric advance
metadata is stored here. The original English atlas is **not distributed**.
Korean retains the Galmuri14-derived OFL pixel source, baseline14/line18 and binary
alpha. `fonts.json` registers permitted font inputs and their exact source/license
hashes. Existing Galmuri covers many additional BMP characters, but validation must
check the actual locale. Do not assume the font supports a language from its name.

For another bitmap source:

1. Obtain an accurately licensed BDF source and permission to redistribute it.
   Put a deterministic gzip in `locales/fonts/` or `integration/assets/` and retain
   its license/attribution. Never add an original-game or unlicensed font.
2. Register an ID in `fonts.json`: `kind=bdf`, unique `fnt_routekeeper...` resource,
   `source`, SHA256 of decompressed BDF, `license`, `licenseFile`, license SHA256,
   `reviewed=true` **after human license review**, provenance URL, displayName,
   baseline and lineHeight. Supported license identifiers are OFL-1.1/MIT/CC0-1.0;
   declaring one is not evidence of permission. Changes need normal code review.
3. Reference that font ID in the locale registry and run validation/build. Each
   used BDF font gets an automatically injected resource/page. No injection edits.

The conservative adapter accepts baseline>=1, lineHeight<=18, advance0..24,
24px cells, bounded16MiB BDF input, BMP glyph IDs and one atlas at most768x2048 per font. Out-of-cell ink,
missing glyphs, unlicensed inputs and invalid paths fail. Sorted code points and
stored DEFLATE make atlas bytes deterministic without host fonts/rasterizers.
Fonts are pixel-aligned and drawn nearest-neighbor at the existing2x GUI scale.
These are adapter bounds, **not** a claim of every runner's maximum texture size.
UndertaleModLib's `UndertaleFont.Glyph` serializes Character/X/Y/Width/Height as
ushort and Shift/Offset as short; lineHeight is an explicit wrapping policy rather
than a modern GM2 font metadata assumption. Original resources are append-only.

## Layout and review

Validation measures the actual registered font advances (original English metrics
for native English). Critical warnings must fit three264px lines without ellipsis;
objectives must fit four lines, navigation264px and left-column labels94px.
Language self-names fit the152px root-menu value; picker entries use their own font.
HUD summaries and long option values retain deliberate ellipsis; critical warning
text does not rely on clipping. Preview every warning and target, including longest
substitutions, before enabling a locale. Do not globally shrink text.

`preview` creates deterministic640x480 PNGs under ignored artifacts/. Its default
English outlines use the Galmuri proxy with exact native advances; this limitation
is written into evidence.json. `integration/ui/preview.py --native-font PRIVATE_DIR`
can inspect privately exported original outlines; never commit/publish those
resources or derived private evidence. Offline images are **not gameplay evidence**.

```sh
ROUTEKEEPER_LOCALE_E2E=1 python tools/test_localization.py
python integration/ui/test_ui.py
```

The end-to-end regression creates an English-only test locale in a disposable
source tree, executes add/build/verify and checks all rule-source hashes unchanged.
It does not advertise an inaccurate third translation. Native font rendering,
keyboard/gamepad event timing and actual locale changes remain NOT_RUN until
properly authorized runtime verification. Same-account Steam NO-GO remains intact.

Optional authentic extension compilation (existing authorized data only) is documented
in [localization-validation.md](../docs/localization-validation.md). This exercises
additional locales/fonts in a disposable copy without launching a game.

Follow-up validation rejects reserved Windows file/device components on every host,
requires literal boolean font review and exact integer legacy mappings, and checks
maintained literal text references against the canonical dictionary (comments and
generated files excluded; dynamic-key coverage/freshness remains a separate check).
ISO tags that are reserved Windows basenames need a distinct portable registered
tag; they are never silently renamed. Shared Core rule/locale views are read-only.
The disposable end-to-end regression executes the full preview/coverage workflow.
