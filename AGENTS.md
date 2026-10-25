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
- Newest candidate6a49b85c has NOT executed. Prior40d67856 Wine failure is not a
  runtime result for later candidates. Read the latest dated progress section.
