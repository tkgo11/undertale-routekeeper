# Non-runtime delivery status — 2026-10-27 KST

New offline screen/review tooling: [screen-verification.md](screen-verification.md).
Existing-frame verification, synthetic fixtures and private deferred review are
available without game execution. Native captures, Win32 APIs and gameplay remain
NOT_RUN; same-account NO-GO and InspectedOnly are unchanged. Historical counts below
are not results for this new infrastructure.

Current continuation and superseding results:
[offline-audit-2026-10-27.md](offline-audit-2026-10-27.md).
The matrix/counts in this earlier baseline below predate the localization refactor
and current audit; preserve them as dated evidence, not current operator instructions.
No game/Steam launch or compatibility approval is authorized.


Starting remote HEAD: bf552d788cbf89c4ee79af6a9e5fbd030f85413e.
Current source is the commit containing this report; obtain its exact SHA with
`git log -1 --format=%H`. PR1 stays OPEN/READY. No merge/release/profile promotion.

COMPLETE means implemented and backed by the stated source/offline evidence.
It NEVER means that the game works. PARTIAL identifies a remaining evidence or
implementation boundary; UNKNOWN is insufficient proof, NOT_RUN is excluded
runtime/native-platform behavior, BLOCKED is an external dependency/access limit.

## Product/evidence matrix

| Area | Status | Evidence and remaining boundary |
|---|---|---|
| Route selector/objectives/progress,18 Neutral targets/8 goals, Pacifist/Genocide/Soulless | COMPLETE for declared rules | Existing engine/native tables, independent original conditional fixtures and normalized bindings revalidated. Does not prove every actual path. |
| Ordered reachability | PARTIAL / UNKNOWN | Source-supported bounded witnesses retained; Neutral6/goal8 unknown. Full closure of zero-EXP cross-instance death/reward/return paths remains unproved. No speculative expansion. |
| Off/Active/Passive/warning acknowledgement/replay | COMPLETE at source/model level | Existing implementation and independent boundary/transaction tests; real frame dispatch/input remains NOT_RUN. |
| Scoped Forced interception | PARTIAL | Verified pre-action adapters retained, unsupported actions advisory. Original state/history not repaired. No universal guarantee or invented automatic victory. |
| Native UI, EN/KR, Galmuri14, keyboard/pad binding conflict logic | COMPLETE at source/preview level | Layout preserved;20 UI groups,381 deterministic glyphs,686 emitted UI comparisons. Physical rendering/input/frame order NOT_RUN. |
| Patch generation and preservation | COMPLETE offline | Authentic compile/serialize/reload,127 signatures/27 dispatch links/115 golden source hashes;6245 nonhook codes, media payloads and declared legacy metadata compared. New CLI scratch/link guards. |
| Installer/update/restore | PARTIAL | Existing strict approval/backup/journal synthetic regressions pass. Hostile TOCTOU is not solved; Windows metadata/power loss NOT_RUN. Actual install remains refused. |
| Standalone4 RID / G3M | COMPLETE offline | Self-contained single-file publish, packaged candidate rebuild, actual synthetic xdelta roundtrip/current upstream parser. Foreign OS execution and authentic G3M install NOT_RUN/BLOCKED. |
| Current-account launch safety | COMPLETE refusal / BLOCKED launch | Run unconditionally fails before touching profile/files/processes; Preflight/recovery retained. No proven same-account Steam isolation; NO-GO. |
| Audit inventory/generator/workflow consistency | COMPLETE for recorded tree |173 paths; explicit full review required for digest refresh, missing/extra/duplicate/drift regression tests; LF text checkout and commit-pinned Actions. |
| Project-wide public distribution license | PARTIAL | No repository-wide own-source license declared; third-party notices verified separately. Rights-holder decision needed before public distribution; no license assigned or package published. |
| qlty95 findings / hosted Actions | BLOCKED | Details redirect to login; success is not triage. Billing blocked; no rerun or configuration/policy changes. |
| Native Windows/macOS/Linux game/Steam/API | NOT_RUN | Explicitly excluded. No game executable, Steam launch, Wine gameplay or personal save/installation write. |

## New demonstrated defects and improvements

- **HIGH CLI scratch collision:** exact CLI03c7048 writes OUTPUT+"temp" with
  Create then renames with overwrite. Existing direct patch checked only OUTPUT.
  Authentic disposable-copy reproduction accepted an existing scratch file.
  patch.csx now refuses existing/link/reparse scratch and dangling output; all3
  source-path regressions pass. Original hash remains unchanged.
- **HIGH structural validator overwrite/privacy:** preexisting summary.json
  symlink could overwrite a synthetic input AFTER the old original hash check.
  Outside-private and ancestor-linked work paths also passed. Five regressions
  now pass: real .research boundary, fresh per-run logs, exclusive writes,
  lexical link guards, repeated-run preservation, oversized version refusal.
- **HIGH unenforced NO-GO:** document-only refusal still reached environment/
  launch logic. Run now throws before helpers/OS/files, despite original/patched/
  risk/Cloud flags. Two entrypoint regressions pass; recovery was not removed.
- **MEDIUM child output/version:** compiler/xdelta text was accumulated without
  bound. Both pipes now drain concurrently/cancellably with bounded memory;
  only the8192-char version prefix is retained. Boundary tests plus noisy
  subprocess exercise both pipes. Versions like0.9.2.01/0.9.2.0evil fail; optional
  pinned release build metadata remains accepted.
- **LOW G3M aliases:** a failing regression exposed newline-suffixed hashes/paths
  and Windows reserved/trailing-dot/space components. Whole-string anchors and
  portable names fix these cases; valid macOS resource paths remain accepted.
- **HIGH metadata verification gap:** a sound Volume-only mutation passed the old
  payload/count checks. Original sound settings, legacy sprite geometry/texture
  references/collision masks, font/kerning properties, texture rectangles, legacy room/view/instance/tile
  fields and original object/event/action linkage are now
  compared. An unmodified positive control plus7 independent in-memory metadata
  mutations verify acceptance/refusal without serializing corrupt assets.
- **Cross-platform source encoding:** CP1252 default reads failed on the Hangul
  UI catalog. Every tracked Path text read/write now specifies UTF-8; writes also
  force LF. A non-UTF8 locale simulation and whole-tree AST policy pass without
  changing generated GML/atlas bytes or the approved UI.
- **Bounded FORM inspection:** duplicate names and excessive chunk tables were
  accepted by the shallow diagnostic parser. Synthetic fixtures reproduced both
  refusals missing. It now enforces unique chunk IDs and a1024-chunk diagnostic
  cap, reusing one64KiB buffer; actual input/output identities are unchanged.
- Action refs were independently resolved to commit IDs and pinned. New tests
  preserve the exact private upstream/nonfork gate and prohibit private artifact
  uploads. LF checkout protects generated source and inventory hashes on Windows.
- Full-file inventory now has a tracked verifier/refresher with explicit reviewed
  paths; it does not silently bless changed or missing code.
- Corrected an older audit's misleading EX "limbs12000" shorthand: original
  threshold is12000 before turn19,10000 from turn19. Implementation already used
  turns, so no gameplay/GML rule change was needed.

New issue details are A13..A20 in code-audit.md. A01..A03 fixes were retained and
retested. A04..A10 native/history/race/model/privacy/qlty limits remain open.
Third-party executable/profile trust is explicit; tools are not an adversarial
process/filesystem sandbox. Existing-path guards are not race-free capabilities.

## Research reconciliation

[technical-reference.md](technical-reference.md) maps every requested mechanic to
actual original resources, maintained rules and evidence levels. Fresh official
GameMaker, legacy mirror, Valve and wiki read-only references corroborate the
source; actual source wins over simplified prose. Exact CLI03c7048 and its
Underanalyzer4ff50a8 implementations were inspected. No upstream implementation,
game decompilation or native English atlas was added to Git.

[steam-safety.md](steam-safety.md) records startup962/963 handling and Valve's
FileDelete/FileExists/Cloud contracts. No supported legitimate same-user/app
throwaway namespace or guaranteed deletion-queue rollback was established.
Cloud-off/local snapshots cannot grant GO. Reopening Run needs new independently
reviewed evidence, not operator consent flags or modified vanilla history logic.

## Executed local commands

Environment: Linux x64, SDK10.0.402, CLI0.9.2.0+03c7048, PowerShell7.6.8,
Pillow11.3.0. All diagnostic/proprietary outputs are ignored/private.

```sh
dotnet build RouteKeeper.slnx -c Release
for suite in Core Neutral Decisions History Tool Saves Audit; do
  dotnet run --project tests/RouteKeeper.$suite.Tests -c Release --no-build
done
dotnet run --project tests/RouteKeeper.Core.Tests -c Release --no-build -- --verify-native integration/gml
dotnet run --project tests/RouteKeeper.Neutral.Tests -c Release --no-build -- --verify-gml integration/gml
dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release --no-build -- --verify-adapters integration/gml
dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release --no-build -- --verify-ui integration
python tools/test_private_validation.py
python tools/test_audit_inventory.py
python tools/test_source_encoding.py
python tools/test_workflow_safety.py
python tools/test_runtime_lab.py
python integration/ui/test_ui.py
python integration/ui/generate.py --verify
python integration/generate_font.py --verify
python tools/audit-endings.py --source .research/all-code --output tests/golden/original-endings.json --verify
python -m compileall -q integration tools
PYTHONPATH=.research/lint-deps python -m pyflakes integration tools # pyflakes3.4.0
pwsh -NoProfile -File tools/runtime/test-sandbox.ps1
UndertaleModCli load private-data/data.win -s tools/audit-hooks.csx
python tools/test-patch-paths.py --input private-data/data.win --cli /path/to/UndertaleModCli
python tools/test-preview-export.py --input private-data/data.win --cli /path/to/UndertaleModCli
# Metadata mutation guards also run automatically inside validate-authentic.py.
python tools/validate-authentic.py --input private-data/data.win --cli /path/to/UndertaleModCli \
  --builder src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll --work .research/20261027/authentic
for rid in linux-x64 win-x64 osx-x64 osx-arm64; do
  dotnet publish src/RouteKeeper.Tool -c Release -r "$rid" --self-contained true \
    -p:PublishSingleFile=true -o "artifacts/20261027-$rid"
done
PYTHONPATH=.research/g3m-deps python tools/test-g3m.py \
  --tool artifacts/20261027-linux-x64/RouteKeeper.Tool \
  --xdelta .research/xdelta/runtime/usr/bin/xdelta3 --upstream .research/G3M-current
python tools/audit_inventory.py
```

Results: build0 warnings/errors; six suites271 checks (38/60/87/17/62/7) and
9314 original-golden/bounded-event assertions; private validator5, inventory3,
workflow2 (including8 gate contexts), encoding2, archive9 and UI20 unittest groups;101
current-account synthetic checks plus AST/interop/legacy helper checks.
Pyflakes3.4.0 reports no findings after unused imports were removed and the UI
page test was strengthened to assert every visible option in order.
These counts describe executed cases, not proof of completeness. The metadata
mutation suite separately rejects7 corruptions after an accepted positive control.
Preservation checks use an explicit bytecode16 legacy policy: original objects/
event/action links, room/view/background/instance/tile fields, listed media metadata/
payloads, font glyphs/kerning and code disassembly. They are not a general GMS2
schema comparison or a formal proof of every behavior of the engine.

Authentic and published Linux builders both produce63,169,638 bytes,
SHA256 `9abd0729f08497f8185ac9540eb514f3a466d41a4a2fcc5f005d484d8fa7ad4d`.
Original62,921,978 bytes remains
`b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7`.
No hash/profile promotion was needed. Existing ZIP/runner identities remain in
runtime-validation.md; no new download or execution was required.
Private structural logs now reside in WORK/run-*/; only disposable compiler inputs
are automatically removed. Do not upload private logs or full patched outputs.

## Remaining work and operator boundary

- **Codex/source UNKNOWN:** closed graph proof for Neutral6/goal8. Current original
  own-event/parent/kill-site/reward evidence is insufficient for a global result;
  do not keep adding speculative transitions or call it impossible.
- **External BLOCKED:** authorized qlty project issue detail/export (rule/path/line/
  fingerprint/severity/commit) is needed to triage95 findings. Existing GitHub
  statuses/check runs do not contain that report. Hosted CI requires external
  billing availability; no retries/settings changes were made.
- **Rights-holder decision:** project-wide source license is not declared. Existing
  third-party/font/runtime notices do not select it. Confirm this before public
  distribution; private validation is not a public license grant.
- **Native non-game NOT_RUN:** operator may run the synthetic PS5.1/7 commands in
  steam-safety.md; actual Win32 API/NTFS metadata/failure behavior needs disposable
  native validation. None is a license to start Steam/the game.
- **Game/SDK NOT_RUN:** account-level startup safety evidence must precede any
  source review reopening Run. After that, separate original-first, manual
  expected/actual smoke and broader battles/events/endings/platform tests are needed.
- macOS/Linux actual runner/data profiles and native execution remain unavailable.
  No additional game files or credentials are requested in this task.

The implementation is more complete and the known demonstrated offline defects
are fixed; universal non-runtime correctness or full release-candidate readiness
is NOT declared. Unclosed proofs, native filesystem behavior and service findings
are deliberately visible. Compatibility approval, merge and release remain NO-GO.
