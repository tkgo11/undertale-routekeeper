# Source-backed technical reference

Reviewed 2026-10-27 (KST), exact input b718f822 / bytecode16 only.
This index reconciles the existing route rules, binding manifest, independent
goldens and platform limitations; it does not duplicate copyrighted game code.

Evidence levels: **SOURCE** directly inspected original code; **CORROBORATED**
independent documentation; **MODEL** bounded interpretation; **HYPOTHESIS**
unproved claim excluded from guarantees; **RUNTIME** requires the official engine.
Exact resource SHA and domains are in profiles/bindings.json and original-endings.json.

| Mechanic | Original source and maintained implementation | Evidence and limit |
|---|---|---|
| All18 Neutral variants and8 optional goals | obj_mainend Create/Step; NeutralCatalog/NeutralGoals/GreetingPolicy; route-rules.md and ending-audit.md | SOURCE selector/overwrite/slot priority; MODEL reachability. All matching conditions need not be the actual spoken slot. |
| Pacifist/prior ending/letter/date/water/return | obj_lettercall Create, scr_load, date/door hooks, finalintro; bindings/StoryEligibility/Objectives | SOURCE ordered eligibility and irreversible entry points; RUNTIME movement/battle/finale. |
| Genocide population and abandonment | scr_murderlv, scr_steps, scr_monsterdefeat, battler Create, mainchara Step; GenocideTransitionModel | SOURCE20/16/18/40, unique enemies and boss deadlines, delayed settlement. MODEL bounded path; RUNTIME encounter availability/combat. |
| Total kills, EXP, LOVE | scr_monsterdefeat, boss resolution events, scr_levelup, battlecontroller win/room return | SOURCE total includes relevant boss kills; Leaderless20 total is16 non-boss with four bosses dead. Pending kills/EXP cannot be treated as already settled. |
| RESET/TRUE RESET/Soulless | namingscreen reset, intromenu/credits_short, truechara/endmyroom/the_end_really/gameshake/nothingness, SCR_GAMESTART | SOURCE local history and INI branches; MODEL pure previews; RUNTIME Steam reconciliation. See steam-safety.md. |
| So Sorry | artclass_sign Step/Alarm, sosorry Create/Step/Alarm6/Alarm10/Destroy, setup reward | SOURCE date-gated one-time encounter and1EXP; MODEL eleven-hit LV1 witness. Movement/victory/timing are assumptions. |
| Glyde | encounterer_glyde Create/Step, glydeb Step/Destroy, scr_monstersetup | SOURCE encounter suppression/special flag and actor reward; not a generic repeatable0EXP kill source. |
| Jerry | encounterer_jerry Create/Step, jerry Step/Destroy, setup | SOURCE seeded Snowdin/backtracking constraints and1EXP; MODEL witness does not prove arbitrary encounter availability. |
| Snowdrake | snowdrake Step/Destroy, battlegroup, scr_murderlv | SOURCE last opportunity and ACT; same-battle pending regional kills included before SPARE/FLEE/ACT. |
| Dogi / Lesser Dog | mandog/womandog and lesserdoge events, scr_murderlv | SOURCE required Dogi chain; Lesser Dog is conditional on encountering it, not an invented unconditional quota. |
| Shyren | shyren Step, battlecontroller ACT dispatch | SOURCE final Hum transition precedes scripted outcome; bounded pre-action refusal, not post-hoc state repair. |
| Muffet | scr_itemuseb cases7/10, spiderb Other16/Step | SOURCE Spider Donut/Cider scripted escape before item/HP/writer mutations; no universal interception of all external scripts. |
| Mettaton quiz/second/third/bombs | battlegroup/setup actor mapping, mettatonb_quiz/second/third own events/empty monster parent | SOURCE pinned zero-EXP forms and individual death/event branches. HYPOTHESIS that they provide a repeatable0EXP kill is unproved. |
| Mettaton EX | mettatonex Step/Alarm6 and battlecontroller | SOURCE mnfight1/talked0; turns>=19 requires10000, turns<19 requires12000. Threshold changes with TURN, not limb count. Original attack/Alarm scheduling retained; MODEL refusal/ack ordering; RUNTIME softlocks/balance. |
| NEO / late abandonment | mettaton_neo Step and scr_murderlv | SOURCE ordered late route overwrite; do not replace with ordinary EX resolution. |
| Items/armor/healing/keepsake | scr_itemuseb, scr_armoreq, scr_recoitem, SCR_TEXT226/227, nicesnowman, scr_storagecheck | SOURCE consumption/equipment/healing effects, request exhaustion and both storage ranges. KeepsakeGuidance distinguishes acquisition/space/storage/retrieval/loss; never inserts inventory. |
| Input/settings/lifecycle/UI | obj_time Create/Step, mainchara Step gate, new controller Create/Step/Draw64 | SOURCE actual joystick/gamepad backend, configurable vanilla buttons, safe overworld context; MODEL conflicting input/edges/navigation; RUNTIME hardware/frame order. Own INI closes promptly. Galmuri14/OFL and native English metrics retained. |

## Runtime ordering is not a static guarantee

[Official event ordering](https://manual.gamemaker.io/monthly/en/The_Asset_Editors/Object_Properties/Event_Order.htm)
explicitly does not guarantee instance order within one event. Its modern list is
not proof about this GMS1 runner. The
[legacy event documentation mirror](https://docs.gamebar.me/gmsDocs/source/_build/2_interface/1_editors/events/index.html)
corroborates event categories. Source hooks retain actual event/subtype/owner links;
models exercise both relevant controller/enemy orders. No fixed Step order,
Alarm-to-Draw universal timeline or collision scheduling guarantee is inferred.

[Parent objects](https://manual.gamemaker.io/monthly/en/The_Asset_Editors/Object_Properties/Parent_Objects.htm)
explain inheritance; authentic parent/event metadata controls this adapter.
[gamepad_button_check](https://manual.gamemaker.io/monthly/en/GameMaker_Language/GML_Reference/Game_Input/GamePad_Input/gamepad_button_check.htm)
is continuous state, not a pressed edge: controller_step tracks previous states,
device/signature changes and excludes configured vanilla buttons.
[ini_open](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/File_Handling/Ini_Files/ini_open.htm)
allows only one active INI; mod settings are brief own-file operations.
Actual Draw/font/filtering/input isolation is RUNTIME, despite offline previews.

## Tool implementation provenance

Installed CLI reports0.9.2.0+03c7048438347799e0717b6e57a9358d000472e0.
Read the exact [pinned Program.cs](https://github.com/UnderminersTeam/UndertaleModTool/blob/03c7048438347799e0717b6e57a9358d000472e0/UndertaleModCli/Program.cs):
SaveDataFile opens outputPath+"temp" with Create, then overwrites by rename.
Both output and scratch must therefore be new/link-free; regression uses disposable
authentic copies. ModBuilder additionally compiles inside its own disposable workspace
and publishes without overwrite. This closes existing-path cases, not hostile TOCTOU.

[CodeImportGroup](https://github.com/UnderminersTeam/UndertaleModTool/blob/03c7048438347799e0717b6e57a9358d000472e0/UndertaleModLib/Compiler/CodeImportGroup.cs)
queues operations and throws on failed imports. Its code and the CLI file match the
previous f43e12c inspected snapshot. The pinned Underanalyzer submodule is
[4ff50a8](https://github.com/UnderminersTeam/Underanalyzer/tree/4ff50a866b4c1a7acee8cebe6a56d6a48709b453).
Compiler/Nodes/SimpleVariableNode.cs resolves explicitly declared locals before
instance scope, with separate argument handling; LocalVarDeclNode and FunctionScope
supply the scope. Fresh authentic compile/reload is the API compatibility evidence,
not execution of a simulated GML interpreter. GPL upstream implementation is not copied.

## Corroboration and contradiction policy

Fresh read-only access succeeded to
[Neutral](https://undertale.wiki/w/Neutral_Route),
[Pacifist](https://undertale.wiki/w/True_Pacifist_Route) and
[Genocide](https://undertale.wiki/w/Genocide_Route) references.
They corroborate route terminology, not exact variable names/event anchors.
Original code wins where descriptions simplify kill totals, deadlines, optional
encounters, greetings or precedence. Conditional snapshots do not prove reachability.

Neutral type6/goal8 stays UNKNOWN: the missing proof is closure of every reachable
zero-EXP actor death/cross-instance dispatch, reward settlement and return path
while satisfying high-kill Exile plus LV1/Bandage/no-healing. Ordinary reward minima,
Jerry/So Sorry1EXP and own-event armored/bomb evidence are insufficient. No further
speculative transitions or invented impossibility/availability claims were added.
