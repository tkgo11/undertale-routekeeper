# Verification evidence

Updated 2026-10-25. Local host Debian13 x64, SDK10.0.402, UndertaleModCli0.9.2.0.
PASS applies only to the stated scope. No official game runner has executed.

| Scope | Result | Command / evidence |
|---|---|---|
| Release build | PASS | `dotnet build RouteKeeper.slnx -c Release` (0 warnings/errors) |
| Core | PASS | `dotnet run --project tests/RouteKeeper.Core.Tests -c Release`: 36 checks; 6,000 evaluator and 1,600 EN/KR/spoiler objective/progress comparisons |
| Neutral | PASS | `dotnet run --project tests/RouteKeeper.Neutral.Tests -c Release`: 54 checks; 10,000 classifier, 19,000 target and 5,000 modifier comparisons |
| Decisions | PASS | `dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release`: 56 checks; 10,000 risk, 1,000 budget, 72 encounter/action, 200 item-escape and 80 ACT comparisons |
| History | PASS | `dotnet run --project tests/RouteKeeper.History.Tests -c Release`: 17 pure transition checks; no filesystem mutation |
| Installer/tool | PASS | `dotnet run --project tests/RouteKeeper.Tool.Tests -c Release`: 47 checks; backup/update/restore, refusal, recovery journal, discovery, executable headers, source-build gates |
| Saves | PASS | `dotnet run --project tests/RouteKeeper.Saves.Tests -c Release`: 7 synthetic checks; supplied saves previously read without byte changes |
| Generated source freshness | PASS | Core `--verify-native integration/gml`; Neutral `--verify-gml integration/gml`; Decisions `--verify-adapters integration/gml` |
| Font metadata | PASS | `python integration/generate_font.py --verify`; embedded glyph coverage/bounds; original font for English |
| Authentic generation/reload | PASS | `python tools/validate-authentic.py --input private-data/data.win --cli /path/to/UndertaleModCli`; original overwrite/modified input rejected |
| Authentic original preservation | PASS | 6,248 non-hook code resources identical; original texture payloads, embedded audio, font glyphs and room/sprite/sound counts unchanged |
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

## Current UI/font/guard/package expansion

- PASS: 217 C# checks (Core36/Neutral54/Decisions56/History17/Tool47/Saves7).
- PASS: 13 offline UI/font groups with Pillow11.3.0; all warning states/languages,
  root/paged navigation, objective fit, counter clipping, binary alpha, baseline,
  source hash, overhang metadata and deterministic font generation.
- PASS: 664 additional emitted-GML navigation/localization cases. Combined declared
  C#/source policy/status/objective comparisons: 53,616. This is not the game VM.
- PASS: actual G3M3.4.3 parser at pinned upstream commit accepts the generated config;
  real xdelta3.0.11 synthetic encode/decode, hash pins, deterministic ZIP, unverified
  profile/location/hash refusals and cleanup. No authentic G3M install/export.
- PASS: authentic GML compile/serialize/reload through the independent builder;
  52 binding/UI source signatures, observed native English advance/height metrics,
  all 6,248 non-hook originals and original resource payloads preserved.
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
OFFLINE_PREVIEW/gameplay NOT_RUN. No runner, startup, hardware input, battle,
save/reload or actual ending has been executed. Additional game inputs were neither
requested nor obtained in this continuation.
