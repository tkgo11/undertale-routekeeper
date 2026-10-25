# Route rules and dependency model

The executable model now implements the inspected ordinary ending families and
Neutral call decision tree. `CompleteCoverage` describes these declared rules;
it does not approve an adapter, intervention, Steam build or gameplay scenario.
All native gameplay verification remains NOT_RUN. The exact source signatures and
binding expressions are in profiles/bindings.json and integration/hooks.csx.

## Pacifist and Soulless Pacifist

Requirements are no EXP and no kills, Papyrus/Undyne survival, the water opportunity
not missed, Papyrus/Undyne/Alphys friendships, prior Omega Flowey completion,
True Lab completion, barrier completion, and the selected existing SOUL history.
A restored world and ordinary mode are required. Stay/Leave can be selected as an
epilogue variant; it becomes invalidated only after an incompatible choice commits.
The mod never creates, removes or sells a SOUL or clears permanent history.

Verified inputs include XP/kill count, flags 67/350 for survival, 88/389/493 for
friendship/story progression, flag 7 for the barrier, General.Won for the earlier
Flowey prerequisite, and system_information_963 for sold-SOUL history. Exact
predicates and qualified domains are in the source, not inferred from flag names.
The final choice is observed from the outside-world scene and flag 512 only once
that choice is actually committed; its initial zero is not mistaken for Stay.

Objectives respect availability and dependencies: help a collapsed character now,
visit a currently available friendship event, complete the earlier ending before
the letter/date, explore the True Lab, return to the barrier, finish farewells,
then observe the selected epilogue. Minimal text omits unnecessary names/events.

## Genocide and Soulless Genocide

`scr_murderlv` supplies the verified ordered 0..16 encounter chain. It combines
regional populations (flags 202..205), Toriel, Doggo, Dogamy/Dogaressa, Greater Dog,
Snowdrake, Papyrus, Shyren, Glad Dummy, Monster Kid/Undying, Royal Guards, Muffet
and Mettaton NEO. Flag 27 separately records abandonment, including Lesser Dog.
Debug murder overrides remain UNKNOWN rather than legitimate progress.

Quotas are 20 Ruins, 16 Snowdin, 18 Waterfall and 40 Hotland/CORE. Toriel can be
the twentieth Ruins kill. Missing Snowdrake once Snowdin is exhausted is blocked
before Papyrus. Resolved-boss guards distinguish future prerequisites from missed
deadlines. The final Sans event sets current-run XP to 99999; the adapter qualifies
this observation with murder stage 16 instead of treating persistent Sans.SK as a
current-run win. Objectives and progress advance beyond Sans toward the throne.

## Neutral taxonomy

The original obj_mainend Create selector, Step subbranches and optional greetings
produce these selectable targets. ID 0 means any ordinary Neutral outcome.

| IDs | Family / variant |
|---|---|
| 1 | Family |
| 2–5 | Betrayed: friendship history × Mettaton survival |
| 6–9 | Exiled: Undyne survival × Papyrus survival |
| 10–11 | Undyne: Papyrus survival |
| 12–13 | Mettaton: Papyrus survival |
| 14 | Papyrus |
| 15 | Dog: only the four required bosses killed |
| 16–17 | Leaderless: below 20 / at least 20 kills |
| 18 | Alphys: late Genocide abandonment |

The classifier also implements eight optional call conditions: Alphys cameo,
Mettaton's two Exiled survival variants, carried Snowman Piece, no file0 SAVE,
Bandage, no healing items, and the composite LV1/no-healing/Bandage greeting.
Several conditions overwrite shared dialogue slots; a condition mask is not a
claim that all matching lines play. C# and native generated classifiers agree.
These eight conditions are selectable additional goals (or No extra goal), separate
from the 19 Neutral types. They are positive conditions, not exclusive dialogue
line guarantees: another matched condition can overwrite a shared call slot.
NeutralGoals owns compatible parent types, OR prerequisites, irreversible
requirements and the Mettaton resolution deadline; generated GML uses the same
table. LV1 goals reject types requiring a dead major boss. Late Genocide overrides
the robot-defeated Exile condition. Missing a carried keepsake is recoverable; an
existing file0 SAVE, prior healing-item use and loss of starting armor are not.
No promise is made that every condition remains attainable in arbitrary saves.

Reachability checks expected boss outcomes with encounter-resolution guards,
kill minima/maxima, friendship dependencies and the late-Genocide override.
True Lab commitment, full Genocide commitment, Hard Mode and an erased world do
not masquerade as ordinary Neutral reachability. The normally unreachable/debug
fallback is excluded from selectable targets. A projection is not proof that the
ending has actually played.

## Reset and history

HistoryTransitions is a pure preview of the inspected naming-screen branch.
Ordinary RESET preserves the relevant INI memories. TRUE RESET replaces ordinary
INI state, retains explicit backup/unlock keys, and loses the playable Won
prerequisite. Neither reset branch removes system_information_* or file8. A new
random fun value is explicitly unspecified. This code has no save-writing API.

## Shared execution and limits

Core emits status, objectives, progress and unknown defaults into native GML;
Neutral emits its target table/classifier/protection rules; Decisions emits
pre-action risk and reserved-kill-budget policies. Independent source interpreters
exercise status/text/progress semantics, not a real GameMaker VM. Exact authentic
compilation/reload and preservation tests are separate evidence.

Sources: authentic scripts named in profiles/bindings.json; upstream implementation
inspection in integration-research.md; https://undertale.wiki/w/True_Pacifist_Route
and https://undertale.wiki/w/Genocide_Route. No complete original source/dialogue
is committed. No release-readiness or universal Forced guarantee is claimed.

## Optional call-goal choice policies

- No SAVE: intercept the normal filechoice0 confirmation before sound/writer;
  never stop scr_saveprocess/file8/file9 midway or delete an existing SAVE.
- No healing: scr_recoitem marks flag260 even at full HP. All 32 main-switch
  healing item cases (including delayed Instant Noodles) are classified. Scripted
  recovery that does not set this flag is not falsely treated as item use.
- Starting armor: SCR_GAMESTART starts with armor4. scr_armoreq accepts nine
  other item IDs; using item4 heals, it does not re-equip the starting Bandage.
  Refuse those armor switches while the optional armor goal is viable.
- Keepsake: warn before using/discarding the last carried item16; multiple copies
  and non-destructive storage remain available. Acquisition/retrieval is an objective.
- LV1: scr_levelup enters LV2 at XP10. Shared prediction also accounts for bosses
  awarding EXP directly, even when the battle reward array is zero.
- Friend's call: preserve all four bosses and zero kills; complete Undyne4 and
  Alphys10, then avoid hidden-lab commitment. The earlier Lab1 elevator door is
  guarded once flag493>=11, before the final one-way descent; do not trap the
  player at the later power-switch scene.

The exact item classifiers are independently extracted from the authentic
scr_itemuseb switch during structural verification. Existing source signatures
and unique insertion anchors reject drift. Snowdrake's potentially escaping ACT
is protected only in its last live quota encounter; repeatable ACT remains usable.
The Stick's last-Dogi resolution also passes through the required-encounter guard.
Shared WarningSession binds one non-forced acknowledgement to code/context/mode;
room/reset/target changes invalidate it. Forced refusals remain experimental and
never mutate original battle flags, EXP, friendship, saves or permanent history.
