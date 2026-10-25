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

## Native Windows testing without Sandbox

- Optional operator-run harness: `tools/runtime/run-without-sandbox.ps1`. See
  `docs/runtime-validation.md` for exact account, Cloud and offline requirements.
- Requires distinct standard local users RKTestOriginal / RKTestPatched, a dedicated
  per-user Steam installation, original/patched exact hashes, fresh test saves,
  manual Steam Offline Mode and **all adapters disconnected**. Never run this
  harness under the primary Windows account or with personal Steam saves.
- Run `pwsh -NoProfile -File tools/runtime/test-sandbox.ps1` for cross-platform
  AST and static safeguards. This does not execute any Windows or game APIs.
- Steam/cloud history remains a residual risk; native test results stay
  NOT_RUN until operator-observed. Keep InspectedOnly pending actual review.
- PR #1 is Ready for review, not approved for merge/release; no unverified
  native compatibility or Forced completeness claims.

## Current Windows account smoke without Sandbox or new users

The **opt-in** native Windows smoke command is
`tools/runtime/run-current-account.ps1` (`Preflight` / `Run` / `Recover` /
`Archive`). It uses the existing non-elevated Windows user only, and does
**not** require Windows Sandbox or additional Windows users. Follow the first
Windows instructions in `docs/runtime-validation.md`.

The tool verifies the exact Steam runner, pristine game data, candidate
and ZIP inventory; requires explicit risk acknowledgment, Cloud disabled,
Steam Offline Mode and manually disconnected network adapters. It snapshots
and hashes existing local UNDERTALE saves, quarantines them for each smoke,
uses uniquely marked temporary game installs, restores after Steam has fully
exited and retains recovery metadata. Steam account-level history/cache
is **not** isolated or rolled back by this approach. Never test SAVE,
RESET/TRUE RESET, Genocide ERASE, Soulless or ending completion with it.
For those, require a genuinely isolated environment or explicit separate
review of the irreversible risks. Never imply Steam Cloud/server state
is guaranteed safe solely from local-file restoration.

Only source/static checks are available for the new harness as of this commit.
Its native Windows/Steam/game behavior remains NOT_RUN; InspectedOnly is
unchanged. The former two-local-user harness remains available for users
seeking stronger isolation.
