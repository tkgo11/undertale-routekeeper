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

F10 opens settings. F5/F6 choose a row; F7/F9 change it. Row 2 chooses a Neutral
variant or a Pacifist epilogue. F11/F12 change mode/language; F8 acknowledges or
dismisses a warning. Gamepad input follows the authentic joystick/gamepad backend
and selects four buttons unused by the game's configurable confirm/cancel/menu
bindings. A controller with fewer than four unused buttons needs keyboard settings.
No movement, confirm, cancel or inventory binding is consumed by the settings UI.
Existing F-key handlers were inspected and are debug-only; debug mode is bypassed.
GUI coordinates target the ordinary 640x480 presentation; fullscreen/resize needs
runtime validation.

## Generation and verification

Core emits route_evaluate*, route_objective and fact_init. Neutral emits its
labels/classifier/condition mask/evaluator/protection. Decisions emits risk,
reserved-kill-budget and one-time encounter predicates. Do not hand-edit generated
files; AGENTS.md lists regeneration/freshness commands. Regenerate the font after
changing strings; `python integration/generate_font.py --verify` needs only stdlib.

UndertaleModCli 0.9.2.0 is a separate build-time compiler. `patch.csx` imports source
scripts and source-validated hooks; `verify.csx` reloads them, checks links and
localization, validates intended modifications, and compares all 6,250 non-hook
original code resources. Original texture payloads, embedded audio, font glyphs and
room/sprite/sound counts are also checked. None of this proves gameplay behavior.

See docs/state-bindings.md, docs/route-rules.md and docs/runtime-validation.md.
Remaining work includes uncovered interaction paths and friendship decisions,
individual greeting targets, complete authentic scenario coverage, platform
provenance and runtime-tested profiles. Forced is experimental and scoped.
