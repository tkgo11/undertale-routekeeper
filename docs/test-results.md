# Verification evidence

Updated 2026-10-24. Local host Debian13 x64, SDK10.0.402, UndertaleModCli0.9.2.0.
PASS applies only to the stated scope. No official game runner has executed.

| Scope | Result | Command / evidence |
|---|---|---|
| Release build | PASS | `dotnet build RouteKeeper.slnx -c Release` (0 warnings/errors) |
| Core | PASS | `dotnet run --project tests/RouteKeeper.Core.Tests -c Release`: 36 checks; 6,000 evaluator and 1,600 EN/KR/spoiler objective/progress comparisons |
| Neutral | PASS | `dotnet run --project tests/RouteKeeper.Neutral.Tests -c Release`: 54 checks; 10,000 classifier, 19,000 target and 5,000 modifier comparisons |
| Decisions | PASS | `dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release`: 47 checks; 10,000 risk, 1,000 budget, 62 encounter/action and 200 item-escape comparisons |
| History | PASS | `dotnet run --project tests/RouteKeeper.History.Tests -c Release`: 17 pure transition checks; no filesystem mutation |
| Installer/tool | PASS | `dotnet run --project tests/RouteKeeper.Tool.Tests -c Release`: 41 checks; backup/update/restore, refusal, recovery journal, discovery, executable headers, source-build gates |
| Saves | PASS | `dotnet run --project tests/RouteKeeper.Saves.Tests -c Release`: 7 synthetic checks; supplied saves previously read without byte changes |
| Generated source freshness | PASS | Core `--verify-native integration/gml`; Neutral `--verify-gml integration/gml`; Decisions `--verify-adapters integration/gml` |
| Font metadata | PASS | `python integration/generate_font.py --verify`; embedded glyph coverage/bounds; original font for English |
| Authentic generation/reload | PASS | `python tools/validate-authentic.py --input private-data/data.win --cli /path/to/UndertaleModCli`; original overwrite/modified input rejected |
| Authentic original preservation | PASS | 6,250 non-hook code resources identical; original texture payloads, embedded audio, font glyphs and room/sprite/sound counts unchanged |
| Independent builder | PASS | `RouteKeeper.Tool build SOURCE NEW_OUTPUT CLI ASSET_ROOT`; compiler receives a disposable copy; compile/verify succeeds; same output hash at tested snapshot |
| Executable header parser | PASS | Synthetic PE/ELF/Mach-O cases plus four official compiler executables; not game provenance |
| Version diff | PASS | `ROUTEKEEPER_COMPARE=ORIGINAL UndertaleModCli load CANDIDATE -s integration/compare.csx`; code/event signature diff only |
| Virtual display / alternative VM | PASS / BLOCKED | Xvfb and Mesa OpenGL4.6 context created; OpenGM built; authentic conversion stops at missing abc_123_a.ogg before mod gameplay |
| Official startup / UI / controls | BLOCKED | No matching legitimate game runner/full media/Steam manifest |
| Battles, transitions, warnings, Forced outcomes | NOT_RUN | Source policies/compilation tested; actual gameplay scenarios not executed |
| Actual saves/RESET/endings/history invariance | NOT_RUN | Static/pure/read-only tests do not establish runtime safety |
| Authentic installation / power loss | NOT_RUN | VerifiedPatch approval absent; synthetic transactions only |

Actions run [40114230381](https://github.com/tkgo11/undertale-routekeeper/actions/runs/40114230381) at 113d922 passed all eight jobs (four synthetic/package and four private authentic structural). Later source changes require their own CI result. Expanded cross-platform runs are tracked on PR #1. The earlier foundation run
40087764774 is not substituted for new commits. No private data/source is uploaded
as an ordinary Actions artifact. Outputs and compiler diagnostics stay ignored.

Latest commit 806bafd: local 202 checks, generated-source checks, authentic builder
and packaged Linux builder PASS. Actions PR run
[40116263118](https://github.com/tkgo11/undertale-routekeeper/actions/runs/40116263118)
is FAIL: all four synthetic jobs have no step records; their log endpoint returns
HTTP404 BlobNotFound. One failed-job retry was requested; no successful execution
evidence was returned. The precise service-side cause is unavailable, so billing,
permissions and code failures are not asserted. Authentic jobs are skipped on PR
events by design; later push-run status must be checked separately.
