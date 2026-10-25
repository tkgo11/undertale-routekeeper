# Verification evidence

Updated 2026-10-25. Local host Debian13 x64, SDK10.0.402, UndertaleModCli0.9.2.0.
PASS applies only to the stated scope. No official game runner has executed.

| Scope | Result | Command / evidence |
|---|---|---|
| Release build | PASS | `dotnet build RouteKeeper.slnx -c Release` (0 warnings/errors) |
| Core | PASS | `dotnet run --project tests/RouteKeeper.Core.Tests -c Release`: 38 checks; 6,000 evaluator and 1,600 EN/KR/spoiler objective/progress comparisons |
| Neutral | PASS | `dotnet run --project tests/RouteKeeper.Neutral.Tests -c Release`: 60 checks; 10,000 classifier, 19,000 target and 5,000 modifier comparisons |
| Decisions | PASS | `dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release`: 79 checks; 10,000 risk, 1,000 budget, 72 encounter/action, 200 item-escape and 80 ACT comparisons |
| History | PASS | `dotnet run --project tests/RouteKeeper.History.Tests -c Release`: 17 pure transition checks; no filesystem mutation |
| Installer/tool | PASS | `dotnet run --project tests/RouteKeeper.Tool.Tests -c Release`: 47 checks; backup/update/restore, refusal, recovery journal, discovery, executable headers, source-build gates |
| Saves | PASS | `dotnet run --project tests/RouteKeeper.Saves.Tests -c Release`: 7 synthetic checks; supplied saves previously read without byte changes |
| Generated source freshness | PASS | Core `--verify-native integration/gml`; Neutral `--verify-gml integration/gml`; Decisions `--verify-adapters integration/gml` |
| Font metadata | PASS | `python integration/generate_font.py --verify`; embedded glyph coverage/bounds; original font for English |
| Authentic generation/reload | PASS | `python tools/validate-authentic.py --input private-data/data.win --cli /path/to/UndertaleModCli`; original overwrite/modified input rejected |
| Authentic original preservation | PASS | 6,247 non-hook code resources identical; original texture payloads, embedded audio, font glyphs and room/sprite/sound counts unchanged |
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

- PASS: 248 C# checks (Core38/Neutral60/Decisions79/History17/Tool47/Saves7).
- PASS: 17 offline UI/font groups with Pillow11.3.0; all warning states/languages,
  root/paged navigation, objective fit, counter clipping, binary alpha, baseline,
  source hash, overhang metadata and deterministic font generation.
- PASS: 684 additional emitted-GML navigation/localization cases. These are source-subset interpreters, not the game VM.
- PASS: actual G3M3.4.3 parser at pinned upstream commit accepts the generated config;
  real xdelta3.0.11 synthetic encode/decode, hash pins, deterministic ZIP, unverified
  profile/location/hash refusals and cleanup. No authentic G3M install/export.
- PASS: authentic GML compile/serialize/reload through the independent builder;
  62 binding/UI source signatures, observed native English advance/height metrics,
  all 6,247 non-hook originals and original resource payloads preserved.
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

- PASS: Release build, 248 C# checks, 17 Python UI groups; 684 emitted UI cases.
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
  source-pinned hooks, all 6,247 non-hook original code and original resource
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
