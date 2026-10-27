# ROUTEKEEPER engineering

Use C#/.NET 10 and native GameMaker GML. SDK is pinned in global.json.
Reports to the user are Korean; code and technical documentation are English.

## Commands

- `dotnet build RouteKeeper.slnx -c Release`
- `dotnet run --project tests/RouteKeeper.Core.Tests -c Release`
- `dotnet run --project tests/RouteKeeper.Tool.Tests -c Release`
- `dotnet run --project tests/RouteKeeper.Saves.Tests -c Release`
- See integration/ and docs/integration-research.md for UndertaleModCli scripts.

## Architecture and safety

Core owns normalized state, declarative rules and policies. Version adapters own
actual game variable mapping. Unknown inputs must remain unknown. Forced mode
must refuse unsupported interventions. Never silently modify permanent history.
Tool owns exact build identification and transactional installation/restoration.
No display-version-only matching; unknown builds are diagnostic-only.

Private game data and decompilation stay in ignored private-data/ and .research/.
Do not log personal save contents, commit proprietary resources, or upload game
binaries to CI. Keep the repository private. Do not commit generated patched data.
Structural compilation is not runtime verification. Every result must distinguish
PASS, FAIL, NOT_RUN and BLOCKED. Update docs/PROGRESS.md and docs/test-results.md.
Review risky save, Forced and installation changes before merging.

## Expanded native implementation

- `dotnet run --project tests/RouteKeeper.Neutral.Tests -c Release`
- `dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release`
- `dotnet run --project tests/RouteKeeper.History.Tests -c Release`
- `dotnet run --project tests/RouteKeeper.Core.Tests -- --emit-native integration/gml`
- `dotnet run --project tests/RouteKeeper.Neutral.Tests -- --emit-gml integration/gml`
- `dotnet run --project tests/RouteKeeper.Decisions.Tests -- --emit-gml integration/gml/decision_risk.gml`
- `dotnet run --project tests/RouteKeeper.Decisions.Tests -- --emit-adapters integration/gml`
- `dotnet run --project tests/RouteKeeper.Decisions.Tests -- --verify-adapters integration/gml`
- `python integration/generate_font.py --verify` (regenerate after changing strings)
- `python tools/validate-authentic.py --input private-data/data.win --cli /path/to/UndertaleModCli`

Do not hand-edit generated evaluators/objectives/Neutral policies. Core owns route
and objective tables; Decisions owns intervention predicates; the native adapter
owns exact variable bindings. `bindings.csx` validates pinned source evidence;
`hooks.csx` verifies unique anchors before pre-effect insertions. Keep each new
hook in the preservation allowlist through `RoutekeeperHooks.Names`. Compile and
reload an authentic output after changes. Current Forced adapters are experimental
source-validated refusals; original runner evidence is still required for release.
Private structural CI downloads only data.win, captures diagnostics privately,
removes working copies and never uploads proprietary artifacts. Do not enable it
in a public repository or a fork.

## Independent ending audit

- `dotnet run --project tests/RouteKeeper.Audit.Tests -c Release`
- `python tools/audit-endings.py --source .research/all-code --output tests/golden/original-endings.json --verify`
- Golden expected results come from original conditional slices, not Core tables
  or generated GML. Keep original GML private; only numeric facts/source hashes and
  slot-origin categories are distributable. A conditional-slice oracle is not a VM.
- Never change a golden value merely to make shared C#/GML parity pass.

## Pixel UI and optional packaging

- `python integration/ui/generate.py --verify` / omit `--verify` to regenerate.
- `python integration/ui/test_ui.py` (Pillow11.3.0).
- `dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release -- --verify-ui integration`.
- `python integration/ui/preview.py --output artifacts/ui-preview`.
- Font generation is stdlib-only, pinned OFL BDF, binary alpha and fixed baseline.
- Never commit/export the original English atlas outside ignored .research.
- G3M export requires VerifiedPatch and verified GameDataRelativePath; no override.

## Private runtime lab

- `python tools/test_runtime_lab.py`
- `python tools/runtime_lab.py prepare --zip PRIVATE_ZIP --work NEW_IGNORED_LAB`
- `python tools/runtime_lab.py verify --work IGNORED_LAB`
- `dotnet run --project src/RouteKeeper.Tool -c Release -- analyze-reachability`
- Read docs/runtime-validation.md before Wine/Sandbox execution. Never mount host
  Steam userdata or personal saves. Steam auth failures are BLOCKED, not runtime
  PASS. Do not bypass Steam or promote InspectedOnly from compatibility-layer tests.
- The reachability command returns source-bounded witnesses; RNG, movement and
  combat victory are assumptions, not executed gameplay or complete path proofs.

- `pwsh -NoProfile -File tools/runtime/test-sandbox.ps1` checks ASTs/filesystem
  guards and compiles capture interop without Windows API calls. Optional Lab and
  PatchedData parameters test private host staging with Sandbox dispatch MOCKED.
- Newest candidate4457dbf4 has NOT executed. Prior40d67856 Wine failure is not a
  runtime result for later candidates. Read the latest dated progress section.

## Current-account native smoke (experimental, Windows NOT_RUN)

Legacy default command: tools/runtime/run-current-account.ps1. Run is code-disabled
(NO-GO), even with operator risk flags; see docs/steam-safety.md. No new OS user,
Sandbox, VM or elevation is required for Preflight/synthetic checks. The retained
experimental launch design uses a pinned side-by-side official runner;
the registered Steam installation is READ ONLY, even in Program Files/other libraries.
Read docs/runtime-validation.md for exact preparation/recovery/evidence commands.
Never introduce a registered-install swap fallback or fake Steam SDK ownership.

Cloud must be disabled globally/per game before testing, Steam authenticated then
prepared offline and exited, and adapters manually disconnected. Known permanent
history or preexisting app391540 cache FILES block Run: never delete personal data
just to pass a gate. SDK/server/opaque account metadata remain UNPROVEN regardless
of local restoration. No SAVE, RESET, TRUE RESET, Genocide/Soulless/ending testing.
The original runner cannot enforce these operator restrictions programmatically.

Current-account filesystem helpers have synthetic failure/recovery tests:
`pwsh -NoProfile -File tools/runtime/test-current-account.ps1`.
PowerShell5.1-compatible syntax is maintained, but actual Windows5.1/7 API,
permissions, SDK readiness, side-copy launch and capture remain NOT_RUN.
Program Files write access is unnecessary. Unsupported permission/case-sensitive/
linked/stream/network checks fail closed; do not suggest elevation or disable guards.

Atomic journals and independently verified snapshots protect LOCAL save content.
Recovery waits for Steam, steamwebhelper and UNDERTALE to exit; no Steam cache is
rewound. Changed caches/registered files block comparison/archive/cleanup. Legacy
schema1 swap sessions are refused, not automatically trusted or rerouted.

PR1 is OPEN and READY, never convert it to Draft. Do not merge/release/promote
InspectedOnly or retry billing-blocked CI. Refresh paginated reviews/threads/checks
before push, after push and immediately before final reporting; validate new/edited
findings against the actual HEAD. Private review evidence lives in .research/.
Older dedicated-user/Sandbox scripts are historical alternatives, not requirements
or validated infrastructure, and do not prove Steam account isolation.

## Pre-runtime code freeze (2026-10-26)

Read docs/code-audit.md and docs/audit-coverage.json before resuming. Same-account
GAME smoke is NO-GO pending source-backed Steam startup-history safety and native
filesystem/API validation. Do not run the official game during this audit. Existing
operator Run examples are experimental procedures, not permission or approval.

- `UndertaleModCli load private-data/data.win -s tools/audit-hooks.csx` verifies all
  27 original dispatch links and every golden source hash without running the game.
- `python tools/test-preview-export.py --input private-data/data.win --cli /path/to/UndertaleModCli`
  exercises new-output/private-path/link refusal on disposable authentic copies.
- Installer ancestor checks are best-effort revalidation, not hostile TOCTOU
  protection; never claim race-free path handling or proven NTFS power-loss recovery.
- Reconcile every tracked path and content hash with the audit inventory after
  source changes. Its COMPLETE means inspection coverage, not runtime approval.

## Non-runtime continuation (2026-10-27 KST)

Current evidence is docs/non-runtime-status.md; older totals are historical.
Never launch Steam/game or use the retained legacy launchers to bypass NO-GO.

- `python tools/test_private_validation.py` uses synthetic inputs/mocked compiler.
- `python tools/test-patch-paths.py --input private-data/data.win --cli /path/to/UndertaleModCli`
  verifies exact CLI output/scratch refusal on disposable authentic copies.
- `python tools/test_audit_inventory.py` / `python tools/audit_inventory.py`.
- Refresh audit digests only AFTER full review of each changed/new file:
  `python tools/audit_inventory.py --refresh --reviewed PATH [PATH ...]`.
  Stage new sources first; missing/extra/unreviewed paths refuse refresh. A digest
  refresh is not test evidence or approval. Review tests and update status docs.
- Private validator work is constrained below repository .research; every run
  creates WORK/run-*/summary.json/logs and preserves earlier evidence. Never upload.
- Default text checkout is LF; binary font inputs remain binary. Source changes
  need fresh authentic compilation and four-RID packaging when affected.

The private structural validator now includes an accepted unmodified candidate
control and7 in-memory metadata corruption/refusal cases. Do not replace this with
payload/count parity or let compiler/script parse failures masquerade as rejection.
Metadata guards are typed and bytecode16 legacy-specific, including original
room/object/event/action fields. Do not claim arbitrary reflection, GMS2 schema
coverage, runtime behavior or a formal equality proof.

All maintained Python Path text IO specifies UTF-8; writes specify LF.
`python tools/test_source_encoding.py` simulates a non-UTF8 locale and checks the
tracked AST policy. Preserve this even on UTF-8 Linux; native Windows is NOT_RUN.

Optional local Python lint: install pyflakes3.4.0 alongside Pillow11.3.0, then
`python -m pyflakes integration tools`. CI pins both; do not rerun hosted jobs.

## Data-only mod localization

- `python tools/localization.py build` validates locales/fonts and regenerates all
  native dictionaries/objectives/UI/font assets. Do not hand-edit text_*.gml.
- `python tools/localization.py build --verify` checks generated freshness.
- `ROUTEKEEPER_LOCALE_E2E=1 python tools/test_localization.py` tests the disposable
  add/translate/build workflow without editing gameplay rules.
- Canonical text/context/registry live in locales/. See locales/README.md for limits,
  licenses, placeholders and strict enabled-locale completeness. Locale changes
  require fresh authentic offline compilation and candidate evidence; never runtime
  approval. Preserve legacy language0=en/1=ko and tag-based future INI settings.

## Offline screen evidence and scoped review

- `python tools/test_screen_verify.py` (Pillow11.3.0; no game/Steam/API calls).
- `python tools/screen_verify.py demo --output private-evidence/NEW_DEMO` exercises
  real private evidence, reports and review; see docs/screen-verification.md.
- Native CopyFromScreen remains overlay-ambiguous; the sidecar is observation,
  never gameplay proof. Proxy English cannot certify original glyph pixels.
- Visual acceptance never upgrades internal-state assertions, NO-GO or profiles.
- Preserve immutable run/review files; improved evidence belongs in a new run.
  Exports require explicit private-pixel confirmation and never perform uploads.


## Explicit Windows E2E experiment (later owner authorization)

Read docs/windows-e2e.md before changing execution policy. The owner separately
accepted Steam account risk for an opt-in original-startup probe after native
non-game validation, exact identity, hard preflight, fresh consent and verified
backups. Default run-current-account Run remains NO-GO, and Cloud must never launch
Steam/game. Do not confuse permission for a probe with account isolation, a passed
baseline, native compatibility or approval to run patched/progression scenarios.

- `python tools/test_windows_e2e.py` and `pwsh -NoProfile -File tools/runtime/test-e2e.ps1`.
- `tools/runtime/test-windows.ps1` is the single operator entry. Smoke is original
  startup observation only; no unrecognized-state input or automatic patched run.
- Reuse existing transactions. New experimental recovery requires a post-trial
  fence before moving any existing trial content; unknown changes fail closed.
- Targeted HWND messages are not physical input or verified GameMaker actions.
- Capture-only review never becomes PASS. Preserve all private evidence and never
  promote InspectedOnly from receipts, consent or non-game tests.
