# Independent ending accuracy audit

2026-10-25; exact authorized input b718f822…81c7, bytecode16. Nominal release/Steam
provenance is unknown. No runner execution or runtime-supported profile exists.

| Family | Original conditions / evidence | Independent coverage | Corrections / limits |
|---|---|---|---|
| Neutral18 variants | mainend Create q0..7 overrides; Step friendship389, kills10, Papyrus/Undyne/Mettaton survival, late murder>=12+Mettaton dead | 1,728 original-derived selector/slot snapshots, all18 labels and q branches | Robot Exile remarks require Undyne alive; selected-target decision API and reserved kill budget fixed. Counterfactual rows are tagged as selector inputs, not reachable runs. |
| Neutral greetings | mainend Step con1 sequential writes: keepsake, no SAVE, armor4, no healing260, LV1 composite, then q7 prefix; con6 Alphys493>=10; con21 robot remarks | All opening boolean combinations; condition masks and final slot origins separately checked | Removed invented stage guard; condition satisfaction does not guarantee an exclusive spoken line. |
| Leaderless / Dog | mainend Create q6 at kills4; Step con61 high remark at kills>=20 | Totals4/5/18/19/20/21/24, equivalent non-boss15/16/17 boundary | No subtract-four occurs in code. global.kills includes bosses. High branch at20 total means16 other kills with all four bosses dead. |
| True Pacifist | lettercall Create: Won>=1,389>=3,kills0,plot>198,493<8; finalintro:493>=12 and murder<16; outsideworld epilogue512; Hard Mode separate | 216 letter gate cases,25 final-intro cases; existing EXP/kill/friendship/water/epilogue tests | The letter gate checks kills, not EXP. Zero EXP remains the supported clean-run route constraint. Tests do not establish every late optional-encounter path. |
| Genocide | original scr_murderlv ordered prefix20/Toriel/Doggo/Dogi/GreaterDog/Snowdrake16/Papyrus/Shyren/GladDummy18/Undying/RoyalGuards/Muffet40/NEO+aborted0 | 53 original mutation/boundary cases; all returned stages and final-deadline rejections | Lesser Dog is not an unconditional prefix requirement; its spared/fled event sets aborted27 if encountered. Optional encounters must not be invented as unconditional quotas. Debug26 override excluded from legitimate binding. |
| Soulless / permanent history | endmyroom/the_end_really and truechara test963; gameshake writes962; nothingness restores through963; GAMESTART Steam reconciliation | Four permanent-file combinations, both epilogues/source bindings, reset preservation tests | 963 takes precedence in normalized erased-world state. No mod mutation or automatic Erase/Do Not selection. Second-Genocide dialogue is a history variant, not runtime completion evidence. |
| Hard Mode | namingscreen calls original scr_hardmodename and sets flag6; normal endings reject it | Existing Core/Neutral rejection tests and authentic source binding | Separate challenge, not a normal ending; no runtime claim. |
| RESET / TRUE RESET / prior ending | namingscreen reset branch, intromenu EndF>0, credits_short increments General.Won | 81 original-derived TRUE RESET INI write sets; ordinary reset / file8 /962/963 preservation | TRUE RESET replaces ordinary INI, copies nonzero s_key/Won/CP/CH into explicit backup keys, removes playable Won, randomizes fun. Preview scope is naming reset; later Steam synchronization is not simulated. |

## Kill accounting and deadlines

Toriel Alarm10 sets killed1; Destroy calls scr_monsterdefeat, whose killed branch
increments total. Papyrus/Undyne/EX/NEO have explicit total increments. battler
Create snapshots total into flag201; mainchara's inbattle return adds the delta to
flag[flag200]; scr_steps selects202..205. Thus regional settlement is delayed until
return, not an immediate separate non-boss counter. Toriel can contribute the last
Ruins quota kill; Snowdin/Waterfall/Hotland gates must be considered at their own
pre-entry checks. Asgore/Flowey scripted history is not blindly added as four-boss
Neutral capacity. Original phone code compares its actual total directly.

## Automatic Mettaton outcome

Original EX Step uses mnfight1/talked0: turns<19 needs12000, turns>=19 needs10000.
Qualification enters con90 before dialogue destruction/creation and talked update;
otherwise alarm6 schedules the original attack and increments turns. The hook
intercepts this exact boundary. Passive/Active wait for matching acknowledgement;
Forced locally clears qualification and takes the unchanged attack branch. It
never rewrites ratings/HP/EXP/death/history. Warning lifetime explicitly preserves
this waiting boundary, with tests for both controller/enemy Step orders. Runtime
alarm/Draw interactions and fight balance remain NOT_RUN.

## Snowman Piece

SCR_TEXT226/227 allow first normal piece and one replacement (state56=0/1), checking
inventory/storage; state2 is exhausted without a remaining piece. Genocide Alarm0
allows three requests using253; Step2 commits the increment. Storagecheck scans
both11-entry ranges300..310 and312..322. Guidance distinguishes retrieve, make room,
acquire and exhausted. Existing item use/drop protections remain pre-effect.

## Evidence discipline

`tools/audit-endings.py` imports no Core rules. It executes a restricted original
numeric conditional/assignment slice and records hashes, synthetic inputs,
selection numbers and slot-origin categories. It exports no original dialogue,
media or personal saves. `--verify` rejects any source/fixture drift; bindings.csx
compares the pinned evidence to authentic data during patch validation. Audit
assertions and shared-source parity tests serve different purposes. This is not a
GameMaker VM, path explorer or proof of every reachable event combination.

Remaining independent work: full EXP/kill encounter-path feasibility for compound
goals (including LV1 with an Exile kill minimum), more optional post-friendship
encounters, alarm/Draw/
collision interactions and scripted outcomes outside the audited EX boundary.
Runtime-only uncertainty: startup, real controller input, battle timing, saves,
RESET/cloud effects and actual final playback. Keep InspectedOnly; PR1 remains Ready for source review only.

## Ordered witnesses and runtime continuation

The new source-bounded transition executor adds pre-boss encounters, actual Loox7/
Vulkin70 and boss EXP, level thresholds, post-battle regional settlement, water
deadline, friendship ordering, inventory storage/retrieval and prior Neutral
reload. Original-derived XP/encounter-suppression fixtures validate those bounds.
All18 concrete Neutral types have witnesses in this abstraction; not every room,
RNG, optional encounter or combat victory has been proven. Source-model results
are explicitly named ReachableInSourceModel, never NATIVE_RUNTIME_PASS.

NEO at39 Hotland kills sets aborted27 before settlement; its own kill later brings
the counter to40 and stage15, while aborted27 prevents16. The late Neutral witness
uses that event order. Repeated EX qualification uses original turn25->20 attack
wrap with100-cycle models, not an invented monotonically increasing turn count.

Types4/6 with compound LV1 remain UNKNOWN pending optional zero-EXP/path analysis.
Only their uncertain level protection becomes advisory in Forced; known boss
constraints remain enforceable. No global impossibility is inferred from assuming
all kills award positive EXP. Windows runtime bootstrap is now BLOCKED by the
isolated Steam API/window failures; real interaction/endings remain NOT_RUN.

## Optional-encounter and scheduler continuation

**OFFLINE_PASS only; no new runtime execution.** The entry script for Art Club
is Step, not the legacy Alarm0 weekday predicate. Step accepts October10 at hour8
or20, rejects murder>=12, outcome281=1/2 and flags7/8. The authentic room list places
walkandbranch159 before sorry160, containing the sign; the music-fade doors inherit
A/B next/previous-room behavior. Native event links, A/B inheritance and the two rooms' doorway/sign instances are
checked against the original data during patch validation. mainchara Other10 calls
scr_interact, which sets myinteract; this path does not dispatch the bound but
unscheduled Alarm0. Movement and dodging are not executed here.

| Compound goal | Source/event evidence | Current verdict |
|---|---|---|
| Befriended betrayal + LV1/no healing/Bandage (type4/goal8) | Complete water/Papyrus/Undyne friendship at0 kills, visit Art Club before the letter/lab transition, defeat So Sorry for1EXP/1kill, spare the other bosses | ReachableInSourceModel, conditional on calendar/access/victory; native gameplay NOT_RUN |
| High-kill Exile + the same goal (type6/goal8) | Jerry gives1EXP; seed Snowdin before plot100, kill Jerry and FLEE with Bandage, backtrack while regional count>0. Nine Jerry plus So Sorry gives10 kills/10EXP and LV2 | UNKNOWN globally; the known cheap-kill subset fails. Do not extrapolate to every zero-EXP/scripted-return path |

The So Sorry witness includes battle timing: original hurt Step changes HP,
Alarm6 advances hitplot only on HP change and peaceful myplot only without one.
LV1 AT10/Stick0 against DEF-6 has a perfect-hit range35..40. Eleven35-damage hits
never naturally exhaust1100HP: hitplot10 forces HP0 on the next hit, then Alarm6
sets death phase1 at hitplot11. Writer/Step/Alarm10 completion reaches killed1
before Destroy invokes the ordinary reward collector. Repeated damage keeps
myplot0, so a guessed fixed peaceful-turn deadline is not used. Eleven numeric
Step/Alarm projections are original-derived goldens, not a GameMaker execution.

No zero-EXP shortcut is assumed: Dummy and Doodlebug do not increment kills;
Napstablook's -1 setup reward is not collected by a killed1 branch. Glad Dummy's
custom Destroy increments kills without collecting its setup reward200, but its
trigger requires murder>=9 (including Toriel's death), contradicting type6.
Asgore's extra kill in endflowey occurs AFTER mainend's phone selector. Royal Guard
confession makes MERCY available rather than automatically ending the battle;
Muffet's timed telegram also leaves a mercy/attack choice, so no blanket ACT or
turn-progression refusal was added. Existing verified MERCY/item guards remain.

Remaining type6 proof obligation: close all kill/reward paths, especially zero-EXP
Mettaton forms/inherited effects and mixed-battle scripted room returns (such as
Woshbody's locked story battle). Literal setup rewards alone cannot prove a kill
contributes EXP or that its death branch is reachable. No global impossibility is
claimed. Personal saves, debug-only transitions and manual save edits are excluded.

Corrected defects:
- LV1 protection now includes xpreward[3], already earned but not banked until
  battle win/FLEE. A second kill can cross XP10 even while global.xp is still0.
- scr_load clears warnings/acknowledgements and mod menu/history cache before
  restoring game state, including reload into the identical room/context.
- Each decision refreshes observations/evaluation rather than trusting the prior
  controller Step, preventing stale BLOCKED state from bypassing a new protection.
- The bounded model now settles backtracking kills into the visited region,
  rejects resolving a boss/advancing from another region, and expires water on
  departure. A one-time Jerry unlock cannot replay during backtracking.

108 repeated settlement golden inputs execute original won/inbattle guards;
repeated battle Step and overworld return cannot bank the same rewards/counters
twice in this numeric projection. Cross-phase warning/reload cases, current-state
source contracts and100-cycle EX regressions supplement it. Actual Step/Alarm/
Draw/Collision ordering, HP/inventory preservation and input timing remain NOT_RUN.

## Review-directed source closure (2026-10-26)

The Snowdrake review exposed a genuine snapshot/event-order mismatch: settled
flag203 can be15 while global.kills already includes another enemy killed in the
same encounter. The battler captures flag201 as the pre-battle total, and overworld
settlement adds the delta only after return. Guard/ACT now use that region-qualified
projection before SPARE/FLEE; stale negative deltas fail safely. This is shared
predicate parity PLUS independent original settlement golden evidence, not a VM.

The standard battlecontroller Other10 exit calls postbattle collection before
room_goto only for won1; eight source-derived numeric cases now assert this order.
The audit enumerates11 genuine global.kills write-site resources (equality tests
excluded), pins zero-EXP Mettaton form and Woshbody/heart/bomb scripts and validates
that the shared monster parent has no inherited event callbacks. These facts close
specific standard-return/inheritance assumptions, not all compound-goal paths.
Type6/goal8 remains UNKNOWN. No new reachability/automatic-intervention guarantee
is asserted without remaining scripted path closure and genuine runtime evidence.
