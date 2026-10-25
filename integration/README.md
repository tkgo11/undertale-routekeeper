# Native ROUTEKEEPER integration

This modifies authentic GameMaker bytecode; it is not an external overlay. The
original game runner would launch modified data normally. **No official-runner
scenario has been executed and no live installation is approved.**

The exact uploaded input is pinned by SHA-256, structure, original hook hashes
and state-binding evidence. Development generation accepts a new separate output
only. Unknown inputs, existing outputs, source overwrites and symlink paths are
rejected. Prefer the standalone tool's `build` command: it gives the compiler a
disposable original copy and never passes it the user's only pristine file.

```sh
RouteKeeper.Tool build SOURCE NEW_OUTPUT /path/to/UndertaleModCli ASSET_ROOT
# Or the private developer harness from the repository root:
python tools/validate-authentic.py --input private-data/data.win --cli /path/to/UndertaleModCli
# Read-only resource-level comparison:
ROUTEKEEPER_COMPARE=private-data/data.win UndertaleModCli load CANDIDATE -s integration/compare.csx
```

## Behavior implemented

- Persistent controller and original English font / embedded Korean font UI.
- Five route families, 19 Neutral selections, Stay/Leave epilogue selection,
  Off/Passive/Active/Forced, spoilers, English/Korean, immediate settings persistence.
- Shared generated status/objective/progress rules and complete declared regional
  encounter chain. Live plot, survival, friendships, populations, availability,
  earlier-ending/history and optional call-condition observations.
- Pre-effect FIGHT/SPARE/FLEE, water-departure, four boss-entry and epilogue hooks.
  Passive/Active acknowledgement permits one retry. Scoped Forced refusals do not
  roll back EXP, resurrect characters, fabricate flags or change permanent history.
- Finite Neutral kill budgets reserve required future bosses. Friendship targets
  protect the first kill and water opportunity. Repeatable Snowdrake is distinguished
  from one-time encounter abandonment. Already broken/debug routes are not trapped.
- Battle warnings clear when a timed action starts. Ordinary HUD/settings remain
  hidden in battles/cutscenes/dialogue and during pending save-data operations.

F10 or an unused pad button opens settings. Native directions and confirm/cancel
navigate the root menu and paged choice lists. F5/F6 and F7/F9 remain optional
keyboard navigation; F11/F12 retain mode/language shortcuts; F8 acknowledges warnings. Existing joystick/gamepad backends
and configured confirm/cancel buttons are respected. Player movement/interaction
is gated before its Step effects while settings are open. The compact objective
HUD uses 28 logical pixels; full text is in Progress. Warnings use solid original
borders and bounded paragraphs. See docs/ui-fonts.md for source dimensions,
OFL bitmap typography and reproducible offline previews. Fullscreen/resize and
actual input ordering still require runtime validation.

## Generation and verification

Core emits route_evaluate*, route_objective and fact_init. Neutral emits its
labels/classifier/condition mask/evaluator/protection. Decisions emits risk,
reserved-kill-budget one-time encounter and item/ACT predicates. Do not hand-edit generated
files; AGENTS.md lists regeneration/freshness commands. Regenerate the font after
changing strings; `python integration/generate_font.py --verify` needs only stdlib.

UndertaleModCli 0.9.2.0 is a separate build-time compiler. `patch.csx` imports source
scripts and source-validated hooks; `verify.csx` reloads them, checks links and
localization, validates intended modifications, and compares all 6,248 non-hook
original code resources. Original texture payloads, embedded audio, font glyphs and
room/sprite/sound counts are also checked. None of this proves gameplay behavior.

See docs/state-bindings.md, docs/route-rules.md and docs/runtime-validation.md.
Remaining work includes uncovered interaction paths and friendship decisions,
individual greeting targets, complete authentic scenario coverage, platform
provenance and runtime-tested profiles. Forced is experimental and scoped.
