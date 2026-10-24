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
