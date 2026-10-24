# Exact-build observation and pre-action adapters

Input SHA-256: b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7.
The adapter is specific to this input and pinned UndertaleModCli 0.9.2.0.
`bindings.csx` checks 46 original code-resource signatures and 34 manifest
expressions. `state_read.gml` also supplies aliases, availability/context and
optional Neutral call observations. It rejects vanilla-global assignments and
save-writing APIs. Actual runner behavior is not yet verified.

| Observation | Authentic source contract |
|---|---|
| EXP/LV/kills/plot | global.xp/global.lv/global.kills; plot ×10 for exact decimal milestones |
| Current area | verified room names/ranges, retained across battle rooms |
| Major survival/resolution | flags 45,67,350,425 plus verified plot deadlines |
| Water | flag350==2 means missed; obj_undynefall.waterthing identifies pending aid |
| Friendship/True Lab | flags88,389,493 and source-checked availability predicates |
| Regional populations | flags202,203,204,205 |
| Required encounters | flags52,53,54,55,57,81,251,252,350,397,402 |
| Genocide progress/abandonment | scr_murderlv plus flag27; debug override26 excluded |
| Current-run Sans completion | stage16 and XP>=99999; original death event explicitly sets XP |
| Earlier ending / reset menu | General.Won / EndF.EndF; backup keys are not playable Won |
| Permanent history | desktop ossafe_file_exists(962/963), read-only |
| Epilogue | final outside-world scene branch and committed flag512 |
| Call modifiers | inventory16, file0 existence, armor4, healing count260, LV |

History reads happen only in safe, non-battle/non-dialogue frames with no pending
save-data operation. They refresh on room changes or after 60 steps. Each INI is
closed synchronously. Mod settings use routekeeper.ini; no original save or history
file is written by an observation adapter.

Pre-action hooks verify complete source hashes and unique anchors. They guard
battle FIGHT/SPARE/FLEE before action-state effects, relevant doors before transition
locks, four regional boss entrances before cutscenes, and the final epilogue
chooser before choice/alarm effects. Muffet's Spider Donut/Cider escape reuses
the Spare policy before any item consumption, healing or turn mutation. Forced refuses only supported risks. Active
and Passive require acknowledgement then permit one retry. Off bypasses hooks.
Multi-enemy Spare is aggregated once; kill budgets reserve future required bosses.

Collision refusals retain the player's previous position so a blocked cutscene
cannot be bypassed by walking through its trigger. The inspected trigger placements
are in room_basement4, room_fogroom, room_water20 and room_fire_core_metttest.
A quota discovered inside an already active battle is advisory, even in Forced,
to avoid an inescapable battle. Abandoned routes are not repaired by trapping play.

No EXP rollback, fake survival flag, fabricated friendship, save rewrite or
permanent-history transformation is implemented. Uncovered scripted deaths, some
friendship-specific Neutral decisions and every alternative interaction path still
need further adapters and actual scenario tests. The current installer refuses
this runtime-unverified profile.
