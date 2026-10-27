# Verification evidence

Updated 2026-10-27 (KST). Local host Debian13 x64, SDK10.0.402, UndertaleModCli0.9.2.0.
PASS applies only to the stated scope. Historical QEMU/Wine attempts reached Steam
bootstrap without a game room; this continuation did not start Steam or the game.
Current pre-runtime audit:9,314 original-golden/ordered-event assertions and270 C#
checks (38/60/87/17/61/7). See [code-audit.md](code-audit.md) for current commands,
results and limits; the dated continuation sections below are historical snapshots.
Same-account GAME smoke is code-disabled NO-GO; no game was executed.
Current additional regressions, exact commands and evidence boundaries are in
[non-runtime-status.md](non-runtime-status.md); prior counts below are historical.

| Scope | Result | Command / evidence |
|---|---|---|
| Release build | PASS | `dotnet build RouteKeeper.slnx -c Release` (0 warnings/errors) |
| Core | PASS | `dotnet run --project tests/RouteKeeper.Core.Tests -c Release`: 38 checks; 6,000 evaluator and 1,600 EN/KR/spoiler objective/progress comparisons |
| Neutral | PASS | `dotnet run --project tests/RouteKeeper.Neutral.Tests -c Release`: 60 checks; 10,000 classifier, 19,000 target and 5,000 modifier comparisons |
| Decisions | PASS | `dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release`: 87 checks; 10,000 risk, 1,000 budget, 72 encounter/action, 200 item-escape and 80 ACT comparisons |
| History | PASS | `dotnet run --project tests/RouteKeeper.History.Tests -c Release`: 17 pure transition checks; no filesystem mutation |
| Installer/tool | PASS | `dotnet run --project tests/RouteKeeper.Tool.Tests -c Release`: 61 checks; backup/update/restore, refusal, recovery journal, discovery, executable headers, source-build gates |
| Saves | PASS | `dotnet run --project tests/RouteKeeper.Saves.Tests -c Release`: 7 synthetic checks; supplied saves previously read without byte changes |
| Generated source freshness | PASS | Core `--verify-native integration/gml`; Neutral `--verify-gml integration/gml`; Decisions `--verify-adapters integration/gml` |
| Font metadata | PASS | `python integration/generate_font.py --verify`; embedded glyph coverage/bounds; original font for English |
| Authentic generation/reload | PASS | `python tools/validate-authentic.py --input private-data/data.win --cli /path/to/UndertaleModCli`; original overwrite/modified input rejected |
| Authentic original preservation | PASS | 6,245 non-hook code resources identical; original texture payloads, embedded audio, font glyphs and room/sprite/sound counts unchanged |
| Independent builder | PASS | `RouteKeeper.Tool build SOURCE NEW_OUTPUT CLI ASSET_ROOT`; compiler receives a disposable copy; compile/verify succeeds; same output hash at tested snapshot |
| Executable header parser | PASS | Synthetic PE/ELF/Mach-O cases plus four official compiler executables; not game provenance |
| Version diff | PASS | `ROUTEKEEPER_COMPARE=ORIGINAL UndertaleModCli load CANDIDATE -s integration/compare.csx`; code/event signature diff only |
| Virtual display / alternative VM | PASS / BLOCKED | Xvfb and Mesa OpenGL4.6 context created; OpenGM built; authentic conversion stops at missing abc_123_a.ogg before mod gameplay |
| Official startup / UI / controls | BLOCKED | Official runner supplied; isolated SteamAPI_InitSafe/mainwindow bootstrap failure |
| Battles, transitions, warnings, Forced outcomes | NOT_RUN | Source policies/compilation tested; actual gameplay scenarios not executed |
| Actual saves/RESET/endings/history invariance | NOT_RUN | Static/pure/read-only tests do not establish runtime safety |
| Authentic installation / power loss | NOT_RUN | VerifiedPatch approval absent; synthetic transactions only |

Actions run [40114230381](https://github.com/tkgo11/undertale-routekeeper/actions/runs/40114230381) at 113d922 passed all eight jobs (four synthetic/package and four private authentic structural). Later source changes require their own CI result. Expanded cross-platform runs are tracked on PR #1. The earlier foundation run
40087764774 is not substituted for new commits. No private data/source is uploaded
as an ordinary Actions artifact. Outputs and compiler diagnostics stay ignored.

## Historical UI/font/guard/package expansion

- PASS: 249 C# checks (Core38/Neutral60/Decisions80/History17/Tool47/Saves7).
- PASS: 17 offline UI/font groups with Pillow11.3.0; all warning states/languages,
  root/paged navigation, objective fit, counter clipping, binary alpha, baseline,
  source hash, overhang metadata and deterministic font generation.
- PASS: 686 additional emitted-GML navigation/localization cases. These are source-subset interpreters, not the game VM.
- PASS: actual G3M3.4.3 parser at pinned upstream commit accepts the generated config;
  real xdelta3.0.11 synthetic encode/decode, hash pins, deterministic ZIP, unverified
  profile/location/hash refusals and cleanup. No authentic G3M install/export.
- PASS: authentic GML compile/serialize/reload through the independent builder;
  74 binding/UI source signatures, observed native English advance/height metrics,
  all 6,246 non-hook originals and original resource payloads preserved.
- PASS: source/tool self-contained publish for linux-x64, win-x64, osx-arm64,
  osx-x64 on the local Linux host. Non-Linux executables were not executed.

CI diagnosis is now conclusive: GitHub check annotations for jobs120938565845 and
120938566054 state that jobs were not started because recent account payments
failed or the spending limit needs increasing. This explains empty steps/404 logs
on runs40116263118/40116432436. Hosted CI is BLOCKED by account billing, not evidence
of passing or failing repository code. No billing settings were changed or public
repository workaround used. New CI adds UI/font/source checks and a Linux synthetic
delta roundtrip; it still requires an eligible hosted runner.

Offline previews use real layout/current font assets; native English outlines are
privately exported from the supplied exact input. evidence.json marks them
OFFLINE_PREVIEW/gameplay NOT_RUN. At that historical snapshot no runner/startup/hardware input/battle/save/reload
or actual ending had executed. The later authorized Windows continuation below
supersedes the input/runtime availability statement.

Previous continuation candidate SHA-256 (superseded below):
901795bfaba57ca8c7a2c411c62c8baecf24d39d5bd9867e3ca12270fb4501c2
(63,122,022 bytes). The committed-source standalone Linux package built exactly
this hash and passed the G3M synthetic roundtrip with the actual current parser.
All four final tool executables have headers matching their target CPU; foreign
execution remains NOT_RUN. Previously inspected hosted runs40151265027 (PR) /40151261704 (push)
at5e6f8c6 have zero executed steps and the same billing/spending-limit annotation.

Preview PNGs now use the same canonical stored-DEFLATE writer as the font atlas,
with a deterministic sorted palette. The offline renderer reads the actual baked
atlas/TSV (and validated private native English glyphs), not a second rasterization.
Byte reproducibility and decoded pixel equality are tested. Gameplay objectives
no longer expose implementation assurances/file names; lasting RESET consequences
remain explained in player-facing terms. A Core regression covers this copy.

## Selectable call-goals and event-order continuation

- PASS: Release build, 249 C# checks, 17 Python UI groups; 684 emitted UI cases.
- PASS: 6,000 call-goal snapshots compare standalone status/EN/KR objectives plus
  integrated Neutral status; the prior 19,000 target / 5,000 modifier cases remain.
- PASS: 12,000 call-action decisions, 20,000 sequential warning FSM events,
  1,200 item classifier cases, 2,376 EXP/LV boundary cases, eight Snowdrake ACT
  cases, explicit one-use/cross-room/mode/target acknowledgements and both possible
  modal controller/player Step orders. Models/source contracts are offline only.
- PASS: generated Core/Neutral/Decisions/UI freshness and deterministic font assets;
  371 glyphs, binary alpha, unchanged approved baseline/cell style. All 19 warning
  messages and nine call-goal labels fit EN/KR offline screens.
- PASS: independent builder compiles/serializes/reloads the authentic original;
  source-pinned hooks, all 6,246 non-hook original code and original resource
  payloads remain preserved. Actual item-effect switch extraction matches every
  healing/armor classifier ID. Modified input/original overwrite are rejected.
  Candidate SHA256 `d3f841da5ec70a027def6071dedaba29a17b4a1db719bea0f17b643d94a45676`;
  size63,164,902. Registry remains InspectedOnly. The final standalone Linux
  package independently built the identical hash using its packaged sources.
- PASS: all four self-contained tool publishes on this Linux host; non-Linux
  executables were not run. Real synthetic G3M encode/decode/parser test rerun.
- BLOCKED: hosted Actions billing (no retries or billing changes this continuation).
- NOT_RUN: official runner, real event/input ordering, warnings/Forced outcomes,
  save/reload and actual ending playback. No new game inputs requested/downloaded.

Commands: AGENTS.md build/six suites, each generator freshness check,
`PYTHONPATH=.research/ui-deps python integration/ui/test_ui.py`,
`python tools/validate-authentic.py --input private-data/data.win --cli /path/to/UndertaleModCli --builder src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll`,
`dotnet publish src/RouteKeeper.Tool -c Release -r RID --self-contained true -p:PublishSingleFile=true`,
and `tools/test-g3m.py --tool TOOL --xdelta XDELTA --upstream PINNED_CHECKOUT`.
Private logs/candidates/native English previews stay ignored in .research/artifacts.

## Independent ending audit continuation

- PASS: build (0 warnings/errors), existing six suites249 checks plus Audit suite
  7,915 original-derived assertions. These expectations are not emitted by Core.
- PASS: original source slices generate1,728 Neutral selection/slot cases,
  53 sequential murder-stage boundary cases,24 EX rating cases,216 letter-gate
  cases,480 Snowman acquisition cases,25 final-intro cases and81 TRUE RESET
  INI write-set cases. Neutral inputs include counterfactual snapshots; this is
  selector coverage, not proof of reaching those snapshots through gameplay.
- PASS: explicit total/non-boss19/20/21 boundaries, Neutral decision effects,
  reserved boss-kill budgets, water/friendship deadlines and both controller/enemy
  event orders at the rating boundary. Existing randomized parity tests remain.
- PASS: all generated source freshness checks;17 offline UI groups, all20 warning
  states EN/KR;686 emitted UI cases. Pixel geometry/font family unchanged.
- PASS: authentic independent build/compile/serialize/reload,74 pinned source
  signatures,6,246 untouched original code resources and original media preserved;
  modified input and original overwrite rejected. Candidate SHA256
  `d0b470d6c2b3cc8e7748405f320d455e9847bd438b0fba172d23251f7b37d64d` (63,168,102 bytes).
- PASS: synthetic G3M parser/xdelta roundtrip; all four local publishes. The final
  Linux package independently builds the same candidate hash from packaged sources.
  Foreign OS execution remains NOT_RUN.
- BLOCKED: hosted billing; no hosted retries or billing modifications.
- NOT_RUN: official game execution, alarm/Draw/input ordering, battle balance,
  actual endings and file/history invariance under real saves/RESET. The new EX
  Forced adapter is experimental and requires gameplay regression before support.

Run `dotnet run --project tests/RouteKeeper.Audit.Tests -c Release` and the private
`tools/audit-endings.py ... --verify` command in AGENTS.md. Source hash evidence is
checked against authentic data by bindings.csx. Original source remains ignored.

## Authorized Windows runtime continuation

- OFFLINE_PASS: release422659795/asset674332045 ZIP size132054497 and pinned SHA256;
  safe inventory/extraction,220 per-file hashes, paired data unchanged; PE32/x86,
  runner version1.0.8.0, original menu1.08, supplied build4279148/depot391541.
- BLOCKED: original and final-patched official runner under QEMU-i38610.0.13,
  Wine10.0/Xvfb, network-off isolated containers. Both log SteamAPI_InitSafe failure,
  mainwindow creation failure and illegal instruction004D1820. No Steam API/DRM
  alteration or license bypass. Private screenshots/logs retained, no public upload.
- NOT_RUN: native Windows, mod initialization/UI/fonts/input/battles/modes,
  actual save/reload/resets/endings, hardware gamepad and audio playback.
- OFFLINE_PASS: Release build zero warnings/errors; Core38/Neutral60/Decisions82/
  History17/Tool55/Saves7 =259 checks; Audit8,564 original-golden/event-model
  assertions, including 100-cycle rating/Alarm/User11/attack-wrap scenarios.
- OFFLINE_PASS: archive6 groups; UI18 groups; generated Core/Neutral/Decisions/UI
  freshness, deterministic font coverage and source golden regeneration.
- OFFLINE_PASS:88 source signatures, authentic compile/serialize/reload,
  all6,246 untouched original code and media preserved; overwrite/modified input
  rejection. Current candidate `40d6785666582fff49ba3e481076a174f1722bb6bad365b8bdf13ccfafbf787b`,63,168,998 bytes.
- OFFLINE_PASS: four self-contained publishes; synthetic G3M/xdelta/parser roundtrip.
  No foreign executable was run. Known Windows profile stays InspectedOnly.
- OFFLINE_PASS: both Sandbox scripts parse under official PowerShell7.6.8; initial
  normal-account refusal tested on Linux. Windows calls/isolation are NOT_RUN.
- NOT_RUN: Windows Sandbox harness execution. Input lab read-only, evidence
  mapping writable, licensed Steam setup required, no automatic runtime PASS.
- BLOCKED: hosted Actions billing; no hosted reruns/settings changes.

Source-model CLI matrix:74 bounded witnesses/95 contradictions/2 UNKNOWN settings
(out of171 including Any). These are conditional source paths, not native victory,
RNG or complete movement proofs. Eighteen concrete Neutral variants have bounded
witnesses; compound LV1/Betrayed and LV1/high-kill Exile remain unproved. The unknown
level constraint is advisory in Forced, avoiding a potential trap.

Audio inventory finds212 external files and four additional stream-flag resources
with nonempty embedded references. Their external/embedded resolution is NOT_RUN;
UTMT permits arbitrary embedded references for stream entries, so presence alone
is not claimed to resolve them. No additional files were requested or assumed missing.
See runtime-validation.md for reproducible commands, exact identities and cleanup.


## Optional encounters / scheduler / Windows harness continuation

- OFFLINE_PASS: Release build0 warnings/errors; Core38/Neutral60/Decisions84/
  History17/Tool55/Saves7 =261 checks. Audit9,282 original-derived golden and ordered
  model assertions. Existing golden sections were unchanged; added Art Club576,
  repeated settlement108 and So Sorry11 Step/Alarm projections.
- OFFLINE_PASS: scoped LV1 enforcement for the proven type4 witness; pending EXP
  threshold1000 cases; same-room reload invalidation/current-state guard linkage;
  backtracking regional settlement and wrong-region/water deadline regressions.
- OFFLINE_PASS: UI19 groups,686 emitted navigation/localization cases, generated
  Core/Neutral/Decisions/UI freshness,381-glyph deterministic font verification.
  Approved pixel layout/Galmuri14 unchanged.
- OFFLINE_PASS:118 original source signatures plus actual event dispatch,
  inheritance and room-instance chain checks; authentic compile/serialize/reload,
  original overwrite/modified input refusal;6,245 non-hook originals and original
  media retained. Candidate6a49b85ce707596257e98e7ae6470e32a968ef666e127bb87701498c3a7d0beb,
  size63,169,126 bytes. InspectedOnly; current-candidate execution NOT_RUN.
- OFFLINE_PASS: archive7 groups including pinned full-inventory tamper rejection;
  all220 original files rehashed. PowerShell AST/guard tests, capture interop
  compilation without Windows API invocation, partial-copy rollback, duplicate cleanup/nested install/lost-marker refusal,
  pure same-case/cross-case/changed-client session checks,
  and private host staging/XML mapping with Sandbox dispatch MOCKED. No Steam/game/Sandbox execution occurred.
- OFFLINE_PASS: four self-contained tool publishes and real synthetic G3M parser/
  xdelta roundtrip. Foreign package execution NOT_RUN; Linux package builds the
  same authentic candidate independently from its packaged sources.
- BLOCKED: previously recorded official original/40d67856 Wine Steam bootstrap;
  not repeated. This is not a runtime result for the newer candidate. Hosted CI
  remains billing-blocked, no hosted reruns or billing changes.
- NOT_RUN: actual Windows Sandbox/Steam offline readiness, game startup/UI/controls,
  battle/Alarm/Draw/collision/save timing, combat preservation and final playback;
  native macOS/Linux and hardware controller tests.

Commands: AGENTS.md build/seven suites/generator checks,
`pwsh -NoProfile -File tools/runtime/test-sandbox.ps1`,
`python tools/test_runtime_lab.py`, authenticated-input structural validator and
four RID publish commands. Private logs are .research/continuation-*.log; source
fixture verification does not require or upload any runtime output. See the new
operator workflow in runtime-validation.md.

## Direct Windows (no Sandbox) harness — source-only addition

- `tools/runtime/run-without-sandbox.ps1`: added for separate Windows local test
  users, with exact original/patch/Steam identity checks and marked restoration.
- `tools/runtime/test-sandbox.ps1`: AST loop includes the direct runner; static
  regression assertions now cover dedicated account names, two attestations,
  no automated host adapter shutdown, hash/inventory gates, original restore,
  fresh saves/Steam Cloud cache checks, recovery preservation and no automatic
  NATIVE_RUNTIME_PASS. These assertions are **committed but NOT_RUN in this
  response** (GitHub connector changes only; no local PowerShell execution).
- Windows native Steam/game APIs and the new runner: **NOT_RUN**.
- PR review state: **Ready for review**; no merge or release.

## Current-account Windows smoke harness — new, NOT_RUN

- New `tools/runtime/run-current-account.ps1` supports opt-in native Windows
  early-game smoke using the **same existing Windows account**, without
  Windows Sandbox or secondary Windows accounts.
- Preflight; explicit same-account/Cloud-off consent; manual network-disconnect
  check; exact runner/data/candidate/ZIP inventory identity; independent local
  save backup/hash; unique quarantine; marked original-game restoration;
  interrupted-session recovery and completed-session archival are implemented.
- The existing `tools/runtime/test-sandbox.ps1` contains additional static
  checks and its AST loop includes all `*.ps1`, including the new script.
  These tests are **committed but NOT_RUN** in this response. They are
  source assertions, not evidence of actual Windows APIs or game startup.
- Real Windows/Steam launch, original/patch comparison and any gameplay:
  **NOT_RUN**. Steam Cloud/cache and persistent account history cannot be
  certified safe from this smoke workflow. Do not promote InspectedOnly.

## Review and same-account side-copy continuation (2026-10-26)

All following PASS labels are OFFLINE_PASS, not Windows execution:

| Verification | Actual result / boundary |
|---|---|
| Release and seven executable suites | 0 warnings/errors; Core38, Neutral60, Decisions87, History17, Tool55, Saves7; Audit9291 |
| Source/golden freshness | Core verify-native, Neutral verify-gml, Decisions verify-adapters/verify-ui, original audit verify all pass; UI686 emitted comparisons |
| UI/font | 20 Pillow groups;381 Galmuri14 glyphs, deterministic atlas/layout unchanged |
| Current-account protocol | PowerShell7.6.8 on Linux parses ALL scripts, compiles interop declarations and runs67 real temporary-filesystem checks; NOT Windows APIs/Steam/PowerShell5.1 |
| Recovery failure injection | Before/after quarantine and restore rename gaps, previous/truncated journal, absent/empty/Unicode saves, missing protected copy fallback, corruption/identity refusal, identical-content trial quarantine, mid-copy failure, stale original comparison and locks |
| Workflow gate | Actual authentic job expression tested over8 upstream/private/fork contexts; no hosted dispatch |
| Archive | 7 safety groups; ZIP verification preserves exact220-file supplied inventory |
| Authentic compile/serialize/reload |127 pinned original signatures plus parent/empty-event constraints;27 intended hooks;6,245 non-hook originals and original texture/audio/font payloads preserved |
| Candidate refusal | Modified input and original overwrite rejected; pristine data unchanged |
| Packaging | Four self-contained RIDs built on Linux; foreign executable execution NOT_RUN |
| G3M | Real xdelta encode/decode and pinned upstream parser accept synthetic package; authentic export remains forbidden |

Current candidate: 9abd0729f08497f8185ac9540eb514f3a466d41a4a2fcc5f005d484d8fa7ad4d (63,169,638 bytes).
Private evidence: .research/final-*.log, final-authentic/summary.json and review-current/
ledger.json with live review IDs/timestamps/commit/context/result. Original data,
runner, saves, reports, screenshots and patched binaries are excluded from commits.

Snowdrake regression includes Snowdin15 plus one unbanked mixed-encounter kill,
SPARE/FLEE/ACT and wrong-region/stale-baseline cases. Original standard-win returns
now have8 source-derived order cases; scripts that assign total kills are enumerated
independently. Empty monster parent and Mettaton form inheritance are asserted,
without claiming that every scripted zero-EXP exit is closed.

NOT_RUN: native Windows PowerShell5.1/7, file handles/ACLs/capture, Steam Offline
readiness, side-copy official runner launch, original/patched smoke, actual input/
controller/Warning/Forced/HP/inventory behavior. No NATIVE_RUNTIME_PASS or new
COMPATIBILITY_RUNTIME_PASS. Prior Wine failure was not repeated. Same-account
smoke deliberately forbids SAVE/RESET/ending/permanent-history tests, even after
local restoration; opaque SDK/server account state is UNPROVEN.

BLOCKED: hosted CI budget (no reruns); qlty success status with95-blocking-issue
text and login-gated details remains unreconciled, not a code PASS. Windows/macOS/
Linux gameplay evidence and full type6/goal8 path proof remain unavailable.

## Stale-recovery follow-up (2026-10-26)

- Reproduced FAIL at7b8cb3e: later legitimate saves were accepted as trial during
  recovery of an already Restored session. Private resume-repro.log records the
  failing independent regression; no actual personal saves were used.
- OFFLINE_PASS: completed and uncommitted-quarantine recovery refuses later save
  changes (present/absent originals), preserving their independently hashed content.
  Terminal journal corruption with unchanged/later personal states and corrupt
  completion fences are covered. Missing/string original-presence metadata refuses
  recovery.99 total PowerShell
  helper/filesystem/process-record checks run on PowerShell7/Linux; ALL harness
  ASTs and capture interop declarations compile. Native Windows/PS5.1 NOT_RUN.
- OFFLINE_PASS:9 Python archive/path groups, including linked lab ancestors and
  modeled NTFS reparse attributes; actual NTFS junction APIs remain NOT_RUN.
- OFFLINE_PASS: Release0 warnings/errors;264 C# checks and9,314 original-derived
  audit assertions. Encounter bindings/EXP/DEF/own-event paths for three Mettaton
  forms and seven bomb groups come directly from original scripts, not route tables.
- OFFLINE_PASS: generated Core/Neutral/decision/UI freshness;20 UI groups,381
  deterministic glyphs and686 emitted navigation/localization cases. UI unchanged.
- OFFLINE_PASS: authentic validator, four publishes, Linux packaged-source rebuild
  (identical9abd0729 candidate) and synthetic G3M/xdelta parser checks are recorded in .research/resume-* private logs. No runtime
  classification is inferred from any of these checks.
- NOT_RUN: official original/patched Windows execution, Steam offline readiness,
  NTFS crash behavior, hardware input and gameplay. Same-account save/history/endings
  scenarios remain prohibited; source-bounded type6/goal8 remains UNKNOWN.
- BLOCKED: hosted Actions budget (no dispatch), current qlty success status with95
  blocking issues and detail redirect to login (freshly checked this run). No formal
  approval, VerifiedPatch promotion, merge, release or proprietary artifact upload.

The optional private host-stage mock initially refused an already populated old
lab, as designed. A fresh-lab run then exposed a test-only relative-vs-absolute
mapping comparison; both test inputs now resolve before invoking the launcher.
The final fresh-lab run is recorded in resume-host-staging-final.log; no Sandbox/Steam/game execution occurred. Original inventory remained intact.
