# Test evidence

Date: 2026-10-24. Host: Debian 13 Linux x64. SDK 10.0.402, CLI 0.9.2.0.
PASS means only the scope stated in the row, not overall game compatibility.

| Check | Result | Evidence / limits |
|---|---|---|
| Release solution build | PASS | `dotnet build RouteKeeper.slnx -c Release`; zero warnings/errors |
| Core executable suite | PASS | `dotnet run --project tests/RouteKeeper.Core.Tests -c Release`: 29/29 |
| Shared evaluator parity | PASS | Included above: independent GML-subset interpreter executes generated control flow for 6,000 seeded snapshots across four route IDs. Not a GameMaker VM. |
| Generated source freshness | PASS | Core runner `--verify-gml integration/gml/route_evaluate.gml` |
| Tool executable suite | PASS | `dotnet run --project tests/RouteKeeper.Tool.Tests -c Release`: 24/24; identity, refusal, locking, backups, updates, recovery, restore, malformed inputs, discovery |
| Save preservation suite | PASS | `dotnet run --project tests/RouteKeeper.Saves.Tests -c Release`: 7/7 synthetic checks |
| Supplied saves read-only | PASS | Save runner `--authentic private-data`: file0/file8/file9 parse, inventory before/after identical; no positional mapping or RESET performed |
| Authentic data parsing | PASS | CLI info + tool inspect, exact hash recorded in compatibility.md |
| Actual GML patch generation | PASS | `UndertaleModCli load private-data/data.win -s integration/patch.csx -o .research/routekeeper-data.win` |
| Actual output reload/decompile | PASS | `ROUTEKEEPER_ORIGINAL=private-data/data.win UndertaleModCli load .research/routekeeper-data.win -s integration/verify.csx` |
| Original code preservation | PASS | All 6,271 non-hook original code resources have identical disassembly; four new code resources and one intentional startup-hook append |
| Font resource coverage | PASS | Added atlas/font contains all Hangul used by shipped native GUI; on-screen rendering NOT_RUN |
| Already-modified patch rejection | PASS | Reapplying to generated data exits 1 and creates no accepted output |
| Cross-platform CI/tool packaging | PASS | Windows x64, Linux x64, macOS ARM64/x64; [run 40087764774](https://github.com/tkgo11/undertale-routekeeper/actions/runs/40087764774), commit 7d6e187; synthetic only |
| Original overwrite refusal | PASS | Patch generation with original as output exits 1; original hash unchanged |
| Linux self-contained packaging | PASS | `dotnet publish src/RouteKeeper.Tool -c Release -r linux-x64 --self-contained true -p:PublishSingleFile=true -o artifacts/tool-linux-x64`; resulting executable inspects authentic data and discovers candidates |
| Native startup, visuals and controls | BLOCKED | No legitimate matching runner/executable was supplied or found; no GUI runtime launched |
| Room transitions, battles, cutscenes, save/reload | NOT_RUN | Requires matching runner and gameplay scenario harness |
| Pre-decision native warnings | NOT_RUN | Current native passive slice warns after observed EXP; no pre-decision hook installed |
| Forced route preservation | NOT_RUN | Deliberately unavailable; no verified intervention adapter |
| Complete endings/reset/history scenarios | NOT_RUN | Route coverage partial, no end-to-end ending tests |
| Power-loss recovery | NOT_RUN | Synthetic journal states tested; actual process/power interruption not injected |

Cross-platform CI execution and package results are recorded in PROGRESS.md with
the run URL. Merely configuring Actions is not a platform test result.
