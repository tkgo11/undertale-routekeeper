# Localization implementation and offline evidence

Follow-up: [offline-audit-2026-10-27.md](offline-audit-2026-10-27.md) adds strict
legacy/permission types, Windows-portable names, missing literal-reference checks,
immutable shared metadata and faithful title/progress previews. The current36-test
workflow includes add/translate/validate/build/preview/coverage/verify. Original237
en/ko strings,393 glyphs and candidate4457dbf4 are unchanged. Earlier totals below
record the original refactor, not the current expanded audit.


2026-10-27; starting/fetched branch HEAD05695725a76ad019402eba66d119e21640733899.
Scope: ROUTEKEEPER's own UI/guidance; original game translation is excluded.
Contributor instructions and font provenance: [locales/README.md](../locales/README.md).
Earlier test/candidate totals in chronological documents are historical.

| Capability | Status | Evidence / limitation |
|---|---|---|
| Canonical IDs, en/ko migration | COMPLETE |237 keys each; pre-refactor own-mod wording fixture plus quota message; no intentional wording changes |
| Rule/text separation | COMPLETE | Rule constructors contain semantic keys, no translated prose; same JSON embedded in Core and emitted into native dictionaries |
| Additional language workflow | COMPLETE | Disposable add/translate/enable/build/freshness test; rule-source hashes unchanged; accurate English clone used only as a test |
| Registry-driven native menu | COMPLETE | Count, names, tag lookup, font selection generated; seven-row paging1/2/3/5/10/19/32 entries; F12 cycles inside settings |
| Settings migration | COMPLETE | Old0=en/1=ko; schema4 persists tags; removed/invalid tags fall back to en; writes only mod INI |
| Dynamic bitmap fonts | COMPLETE | Licensed source/permission/digests; per-font manifest and injection;393-glyph Galmuri subset; added-font synthetic and authentic extension checks |
| Placeholder / Unicode / layout gates | COMPLETE | Strict enabled completeness; duplicate/obsolete/empty keys, controls/escapes, NFC, BMP, scalar-script allowlist, glyphs/metrics, warnings and menus checked |
| Deterministic offline previews | COMPLETE |21 raster/layout groups; original English metrics, optionally private original outlines; default English outlines are an explicitly labeled Galmuri proxy |
| Authentic patch compilation/preservation | COMPLETE | Official CLI0.9.2.0, bytecode16; independently generated twice with same candidate hash; all6,245 non-hook originals unchanged; original resources/metadata retained |
| In-game rendering/input/switch timing | NOT_RUN | No game/Steam launch; Windows/macOS/Linux runner behavior is not established |
| General shaping/bidi/non-BMP | UNKNOWN / disabled | No verified renderer; unsupported code points refuse enablement rather than missing boxes |
| Additional real translations | NOT_RUN | No extra language is advertised; templates start disabled and empty |
| Installation/compatibility approval | BLOCKED | InspectedOnly, no new native evidence; same-account Steam Run remains NO-GO |
| Hosted CI / qlty issue details | BLOCKED | Existing billing/login restrictions; no hosted rerun or access bypass |

COMPLETE here means source-backed offline implementation only. It does not mean
actual gameplay works or that every language/runner is supported. Ending rules,
interception policies, UI geometry and Galmuri outlines are preserved. The bounded
Neutral6/goal8 uncertainty and Steam account-history problem are unchanged.

## Reproduction

Use the SDK pinned by global.json and Python3.12/Pillow11.3.0/pyflakes3.4.0.

```sh
python tools/localization.py build
python tools/localization.py build --verify
ROUTEKEEPER_LOCALE_E2E=1 python tools/test_localization.py
python integration/ui/test_ui.py
python tools/localization.py preview --locale en
python tools/localization.py preview --locale ko
python -m pyflakes integration tools
```

The localization suite has30 focused tests, including a source-only disposable
contributor build. It compares migration wording to a pre-refactor snapshot,
validates generated dictionary literals directly, and separately checks policy/fact
independence. Shared C#/GML lookup parity is **not** proof of ending correctness.
Existing independent original-ending golden/ordered-event suite remains unchanged.
The C# `--verify-locales` command also compares route status, requirements, reasons,
show/dismiss/enforcement policy and unchanged facts across compiled locales.

```sh
dotnet build RouteKeeper.slnx -c Release
# Run each tests/RouteKeeper.{Core,Neutral,Decisions,Tool,Saves,History,Audit}.Tests
# project with dotnet run --project PATH -c Release --no-build.
dotnet run --project tests/RouteKeeper.Core.Tests -c Release --no-build -- --verify-locales
dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release --no-build -- --verify-ui integration
python tools/audit-endings.py --source .research/all-code --output tests/golden/original-endings.json --verify
UndertaleModCli load private-data/data.win -s tools/audit-hooks.csx
python tools/validate-authentic.py --input private-data/data.win --cli /PRIVATE/UndertaleModCli
```

Local results:0 build warnings/errors;271 standard C# checks and9,314 independent
source-golden/ordered-model assertions;696 emitted UI navigation/localization
comparisons;30 localization tests including real contributor SDK build;21 UI groups;
archive9/workflow2/private-validator5/encoding2;101 PowerShell synthetic checks.
Four self-contained tool packages were built for win-x64/linux-x64/osx-x64/osx-arm64;
foreign executables were not run. Actual xdelta3 deterministic ZIP roundtrip and the
current upstream G3M parser accepted a synthetic package; InspectedOnly export
remains refused. No proprietary package was published.

For the optional authentic **extension** regression, set these private local paths
alongside ROUTEKEEPER_LOCALE_E2E=1 before running test_localization.py:
`ROUTEKEEPER_LOCALE_AUTHENTIC=/PRIVATE/data.win` and
`ROUTEKEEPER_LOCALE_CLI=/PRIVATE/UndertaleModCli`.
It creates four test locales/two font resources in a disposable source copy,
compiles/serializes/reloads with the official compiler, verifies original resource
preservation and original hash, and deletes its private candidate with the test
temporary directory. These are accurate en/ko clones, not supported new translations.
Compiler diagnostics stay private; never upload this test's authentic logs.

## Candidate identity and boundaries

Original SHA256:
`b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7`
(62,921,978 bytes). Windows x86 runner/Steam metadata remain as recorded in
compatibility.md; no official game process was launched.

Final237-key candidate SHA256:
`4457dbf421230c596df0d2c27754e8e94293c03c8e1106c6c1b07b9552f2c96c`
(63,195,750 bytes). Both direct CLI and .NET source builder produced this hash;
private reload validated all intended hooks and resource preservation, and the
accepted-control/seven negative metadata mutations still passed. The registry
records the new hash with **InspectedOnly**. No receipt or offline result grants
installation rights. The extra-locale test candidate is temporary and is not this
profile or an approved build.

Generated files are sorted UTF-8/LF. Bitmap atlases use deterministic stored DEFLATE
and no host fonts. Font source/license hashes and glyph bounds are verified.
Catalog/atlas publication refuses linked ancestors and replaces individual outputs
atomically; it is best-effort path revalidation, not a hostile-TOCTOU or whole-build
power-loss guarantee. An interrupted build must pass build --verify before use.

No original English atlas, game binary, patched full game, decompiled game source,
private screenshots, personal saves or credentials are committed. Native rendering,
controller hardware, save/load and all actual endings remain NOT_RUN. PR1 stays
OPEN/READY; no merge, release, profile promotion or account-safety approval.

Confirmed extension-build defect fixed: JSON-style escaped double quotes were
rejected by the authentic GML1 compiler (`text_2`, unrecognized token). Locale
generation now emits literal quote fragments joined by builtin chr(34). Independent
expression assertions and the authentic four-locale/two-font regression cover it.

Additional validator regressions refuse long ending/call-goal menu options, HUD
progress templates and controller footers; bounded tag/text/BDF input prevents
unbounded translation/font work. These checks do not resize approved UI geometry.
