# Offline continuation audit — 2026-10-27 UTC

Starting remote/PR HEAD:06acf3ded1ce360ed8fa0bd632e5bb5ec434622e.
Final source is the commit containing this report (`git log -1 --format=%H`).
PR1 remains OPEN/READY. No game/Steam/Wine/VM launch, personal file mutation,
release, merge or compatibility promotion. Same-account Run remains NO-GO.

## Findings and fixes

| ID / classification / severity | Affected source | Evidence and correction | Verification |
|---|---|---|---|
| A21 Confirmed defect / MEDIUM | tools/localization.py | Python equality admitted legacyValue=true/null/1.0 and truthy reviewed="false". This could pass validation but fail .NET loading or misrepresent review permission. Require reserved integer mappings and literal boolean font permission. Non-object catalogs fail clearly. | OFFLINE_PASS; pre-fix10 negative subcases failed; existing en0/ko1 unchanged |
| A22 Confirmed defect / LOW | tools/localization.py | Reserved locale tags/font IDs such as con and aux passed Linux validation but cannot be normal Windows filenames. Reject reserved/aliased font path components on every host. Existing enabled metadata is unchanged. | OFFLINE_PASS; failing portable-name regressions before fix; no native Windows claim |
| A23 Confirmed defect / MEDIUM | tools/localization.py | Removing a UI key from all dictionaries/context silently passed despite native references. Check maintained literal references against canonical IDs, excluding comments/generated files; freshness separately checks generated source. | OFFLINE_PASS; independent missing-native-reference and comment controls. This bounded lexical scan is not full C#/GML analysis of dynamic keys |
| A24 Confirmed defect / LOW | integration/ui/preview.py | The preview hardcoded ROUTEKEEPER and7/17 while native GML uses translated title/progress templates. A changed template produced a mismatched preview. Use catalog text/substitutions. | OFFLINE_PASS; pre-fix raster-model assertion failed; en/ko wording/pixels preserved |
| A25 Confirmed defect / MEDIUM | ModBuilder.cs, G3MPackage.cs, SourceInstaller.cs | Synthetic source builder and actual synthetic xdelta export wrote through linked output ancestors. Reuse installer component/link checks before inspection/work and before publication. Source installation also refuses linked paths before invoking tools. | OFFLINE_PASS; both pre-fix operations accepted aliases; new regressions reject without output. Ordinary link refusal, not hostile TOCTOU protection |
| A26 Confirmed defect / MEDIUM | Core rule/locale models, GreetingPolicy.cs | Public IReadOnlyList/Dictionary views exposed mutable arrays/dictionaries. Callers could alter language index/goal compatibility/rule predicates/item classification. Copy constructor arrays and publish read-only views; model flags are read-only. Dispose locale resource streams after parsing. | OFFLINE_PASS; Core/Decisions mutation regressions failed before fix. All emitted GML remains identical |
| A27 Confirmed static overflow / MEDIUM | Reachability.cs, GenocideTransitionModel.cs | count+settled used unchecked int arithmetic before a potentially huge event loop;1+int.MaxValue wraps. Widen quota addition to long before comparison; regional C# decision projection also returns a wide value instead of wrapping negative. | OFFLINE_PASS; int.MaxValue attempts reject before effects; a separate large regional projection assertion failed before its fix. Pre-fix unbounded loop execution intentionally NOT_RUN to avoid resource exhaustion |
| A28 Credible concurrent-input risk, hardened / MEDIUM | SaveInventory.cs | A pre-read FileInfo length did not bound File.ReadAllText if input grew. Bound bytes actually consumed to1MiB+1 before decoding; retain existing BOM/newline semantics and caller stream ownership. | OFFLINE_PASS; exact limit and underreported-length stream. Not a native filesystem race/power-loss test |
| A29 Confirmed defect / MEDIUM | SaveInventory.cs | Uppercase SYSTEM_INFORMATION_963 was omitted from the protected-history inventory. Conservatively classify known/history names without case sensitivity, preserve original names, and detect deletion. No game history flags are inferred or rewritten. | OFFLINE_PASS; pre-fix classification failed; disposable files only |
| A30 Confirmed defect / MEDIUM | tools/runtime_lab.py | Verification ignored an additional DLL; prepare trusted the earlier archive inspection after the archive changed. Verify the exact extracted file set and every hash before making run copies; reject unlisted/special/link nodes during later verification. | OFFLINE_PASS; both pre-fix negative controls failed; synthetic swap cleaned its owned stage; authentic220-file inventory passes |

Private reproductions/results are below ignored `.research/offline-audit/`.
They contain authorized original-source/compiler diagnostics and must not be uploaded.
No original game code/dialogue/media is included in this report.

## Phase disposition

| Phase | Status | Evidence / remaining boundary |
|---|---|---|
|0 synchronization/baseline | COMPLETE | Fetched actual remote/PR, reconciled tracking ref; clean06acf3d baseline; build0 warnings/errors, prior tests passed |
|1 live reviews | COMPLETE for fetched snapshots | All paginated reviews/inline/issue/thread/status/check data retrieved at start, after implementation, before/after push and final report; no permanent-monitoring claim |
|2 localization | COMPLETE offline | All237 en/ko records/context, migration fixture, immutable lookup, strict metadata/glyph/layout gates; full add→translate→validate→build→preview→coverage→verify in disposable source copy; four locales/two fonts compile with authentic data |
|3 repository audit | COMPLETE recorded coverage; bounded assurance | Every tracked blob reconciled to audit inventory; previous full inspections retained for unchanged blobs, changed sources inspected fully. Directed checks covered Core/Decisions/History/Saves/Tool, handwritten native dispatch/UI, Python/PS/workflows and docs. Not a fresh manual rereading claim for every unchanged fixture/license byte or proof of every branch |
|4 Forced/gameplay | PARTIAL, source/model backed | Existing pre-effect FIGHT/ACT/MERCY/FLEE/item/SAVE/water/friendship/EX adapters rechecked against pinned originals and independent goldens. No demonstrated new gameplay-rule defect justified changing hooks. Unsupported interventions remain advisory; actual state/timing preservation NOT_RUN |
|5 Neutral6/goal8 | UNKNOWN | Own-event/parent/reward observations do not close external actor writes, damage, collection and scripted return paths; no speculative witness/impossibility added |
|6 scheduler | PARTIAL | Existing source-derived Step/Alarm/Draw/Collision/load/warning-order models and both controller/enemy orders rerun; mutable model state/overflow guarded. Models do not establish native scheduler dispatch or HP/inventory preservation |
|7 filesystem/recovery | COMPLETE scoped offline fixes; native gaps | Alias/publication, exact archive inventory, read bounds/history classification and synthetic PS recovery tested; hostile directory races and native Windows ACL/ADS/NTFS behavior remain NOT_RUN |
|8 validation/packaging | COMPLETE available offline checks | See commands/results below; original data preserved; foreign OS executables not run |
|9 Actions/qlty | BLOCKED |13 checks' annotations retrieved: jobs not started because Actions budget prevents use. qlty success still reports92 blocking issues; direct read-only target redirects to Login - Qlty. No issue list, rerun, credentials/session scrape or billing changes |
|10 docs/provenance | COMPLETE | This register, progress/test/code-audit/status/ending/localization/security references reconciled; older dated results remain historical |
|11 commit/PR | COMPLETE only after recorded push | Existing branch/PR only; exact final HEAD, cleanliness and final review state are in the session report |

COMPLETE above means the declared offline scope, not product completion, native
compatibility, review approval or release readiness. The per-file inventory records
methods and hashes; carry-forward inspection is explicit rather than sampling
presented as a new complete manual audit.

## Source observations and limits

The independent original audit was rederived:1728 Neutral selector/slot fixtures,
53 murder-stage cases,24 EX ratings boundaries, all115 golden source hashes and27
object/script/event dispatch links. Source binding127 signatures remains intact.
The authentic EX death branch awards800EXP; the existing bounded model's800 was
confirmed rather than changed from memory/wiki assumptions. Quiz/second Create
initialize takedamage0 and their hurt branches differ from third Destroy; these
own-event facts do not establish closure of external writes or a reachable0EXP kill.
No phone-selection snapshot or shared C#/GML parity is a proof of reachability.

New portability guards follow Microsoft's
[Win32 naming contract](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file):
reserved device basenames apply even with extensions, and trailing dot/space and
reserved filename punctuation are unsupported. A reserved ISO tag needs a distinct
portable registered tag; it is not silently renamed. Font licensing remains a
reviewed provenance/permission declaration, not automated legal approval.

Native Steam startup source/API evidence in steam-safety.md is unchanged. Cloud-off,
offline mode/local snapshots do not prove same-account RemoteStorage isolation.
Run remains disabled before helpers/process/filesystem access. Existing recovery
and Preflight remain available; no operator action is required by this task.

## Reproducible checks and actual results

Linux x64: pinned SDK10.0.402, CLI0.9.2.0+03c7048, pwsh7.6.8,
Python3.12/Pillow11.3.0/pyflakes3.4.0; xdelta3 and existing upstream G3M checkout.
All original data/saves below private-data and private diagnostics below .research.

```sh
dotnet build RouteKeeper.slnx -c Release
for suite in Core Neutral Decisions History Tool Saves Audit; do
  dotnet run --project tests/RouteKeeper.$suite.Tests -c Release --no-build
done
python tools/localization.py build
python tools/localization.py build --verify
ROUTEKEEPER_LOCALE_E2E=1 python tools/test_localization.py
# Optional authentic extension: set ROUTEKEEPER_LOCALE_AUTHENTIC and
# ROUTEKEEPER_LOCALE_CLI to the existing PRIVATE absolute input/compiler paths.
python integration/ui/test_ui.py
python integration/ui/preview.py --output artifacts/offline-audit-ui
python tools/test_runtime_lab.py
python tools/runtime_lab.py verify --work .research/runtime-prepared
python tools/test_private_validation.py
python tools/test_workflow_safety.py
python tools/test_source_encoding.py
python tools/test_audit_inventory.py
python -m pyflakes integration tools
python tools/audit-endings.py --source .research/all-code --output tests/golden/original-endings.json --verify
UndertaleModCli load private-data/data.win -s tools/audit-hooks.csx
python tools/validate-authentic.py --input private-data/data.win --cli /PRIVATE/UndertaleModCli --builder src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll --work .research/offline-audit/authentic
python tools/test-patch-paths.py --input private-data/data.win --cli /PRIVATE/UndertaleModCli
python tools/test-preview-export.py --input private-data/data.win --cli /PRIVATE/UndertaleModCli
pwsh -NoProfile -File tools/runtime/test-current-account.ps1
pwsh -NoProfile -File tools/runtime/test-sandbox.ps1
# Publish: dotnet publish src/RouteKeeper.Tool -c Release -r RID
# --self-contained true -p:PublishSingleFile=true -o artifacts/offline-audit-RID
python tools/test-g3m.py --tool artifacts/offline-audit-linux-x64/RouteKeeper.Tool --xdelta /PRIVATE/xdelta3 --upstream .research/G3M-current
python tools/audit_inventory.py
```

OFFLINE_PASS: build0 warnings/errors;279 standard C# checks (39/60/89/17/63/11),
9317 independent golden/bounded-model assertions;36 locale tests including full SDK
contributor workflow/authentic four-locale/two-font extension;22 UI groups;
696 emitted UI comparisons;393 deterministic glyphs; archive12, private validator5,
workflow2, encoding2, inventory3;101 current-account synthetic failure/recovery checks.
Existing authorized saves:3 line files/4 recognized entries read-only, hashes unchanged;
positional field interpretation is NOT_RUN. No personal save is modified.
Four RID packages: win-x64/linux-x64/osx-x64/osx-arm64; actual synthetic xdelta/G3M
parser/roundtrip and unverified refusal pass. Native foreign-platform execution is NOT_RUN.

Authentic compile/serialize/reload and full declared original resource/metadata
preservation pass, including6245 non-hook code resources and the accepted control/
7 negative metadata mutations. Unsafe overwrite/scratch/modified inputs refuse.
Original b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7
(62,921,978 bytes). Candidate remains4457dbf421230c596df0d2c27754e8e94293c03c8e1106c6c1b07b9552f2c96c
(63,195,750 bytes). No generated GML, font pixels, translation wording, gameplay
hook or exact-build profile change was necessary. InspectedOnly remains unchanged.

## Remaining work

- UNKNOWN source proof: close every relevant zero-EXP actor/external dispatch,
  collection/return/backtracking path for Neutral6/goal8. Current finite observations
  are insufficient; no new independent verified transition was found.
- NOT_RUN native Windows non-game API/PS5.1/7/NTFS/ACL/ADS/link/case/power-loss and
  game rendering/input/scheduler/battles/endings; native macOS/Linux exact builds.
  The current environment cannot supply those platform/runtime observations.
- BLOCKED service/rights: authorized qlty detail/export, hosted budget availability,
  project-wide public distribution license selection by the rights holder, and a
  legitimate source-backed same-account Steam history safety argument.
- Credible risks remain: hostile TOCTOU, real power-loss durability, private capture
  overlays and independent compiler/profile trust. Guards/tests are scoped and
  must not be presented as a hostile filesystem/process sandbox or account rollback.

No remaining demonstrated defect in this pass is intentionally left unfixed.
This does not imply that every independently discoverable future defect is absent.
Compatibility approval, merge, game smoke and release remain NO-GO.
