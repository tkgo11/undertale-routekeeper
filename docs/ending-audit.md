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
RESET/cloud effects and actual final playback. Keep InspectedOnly and Draft.

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
