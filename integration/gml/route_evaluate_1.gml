// Generated from RouteCatalog; do not edit.
// 0 ON_TRACK, 1 ACTION_REQUIRED, 2 AT_RISK, 3 BLOCKED, 4 UNKNOWN.
var rk_unknown, rk_action, rk_blocked;
rk_unknown = 0; rk_action = 0; rk_blocked = 0;
// requirement 0: world_erased
if (global.rk_world_erased >= 0 && global.rk_world_erased <= 1 && global.rk_world_erased == 0) { }
else if (global.rk_world_erased < 0 || global.rk_world_erased > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 1: hard_mode
if (global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1 && global.rk_hard_mode == 0) { }
else if (global.rk_hard_mode < 0 || global.rk_hard_mode > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 2: experience
if (global.rk_experience >= 0 && global.rk_experience <= 2147483647 && global.rk_experience == 0) { }
else if (global.rk_experience < 0 || global.rk_experience > 2147483647) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 3: kills_total
if (global.rk_kills_total >= 0 && global.rk_kills_total <= 2147483647 && global.rk_kills_total == 0) { }
else if (global.rk_kills_total < 0 || global.rk_kills_total > 2147483647) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 4: papyrus_alive
if (global.rk_papyrus_alive >= 0 && global.rk_papyrus_alive <= 1 && global.rk_papyrus_alive == 1) { }
else if (global.rk_papyrus_alive < 0 || global.rk_papyrus_alive > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 5: undyne_alive
if (global.rk_undyne_alive >= 0 && global.rk_undyne_alive <= 1 && global.rk_undyne_alive == 1) { }
else if (global.rk_undyne_alive < 0 || global.rk_undyne_alive > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 6: water_opportunity_missed
if (global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1 && global.rk_water_opportunity_missed == 0) { }
else if (global.rk_water_opportunity_missed < 0 || global.rk_water_opportunity_missed > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 7: papyrus_friendship
if (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) { }
else if (global.rk_papyrus_friendship < 0 || global.rk_papyrus_friendship > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 8: undyne_friendship
if (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) { }
else if (global.rk_undyne_friendship < 0 || global.rk_undyne_friendship > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 9: prior_neutral_completion
if (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1) { }
else if (global.rk_prior_neutral_completion < 0 || global.rk_prior_neutral_completion > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 10: alphys_friendship
if (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) { }
else if (global.rk_alphys_friendship < 0 || global.rk_alphys_friendship > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 11: true_lab_completed
if (global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 1) { }
else if (global.rk_true_lab_completed < 0 || global.rk_true_lab_completed > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 12: barrier_broken
if (global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) { }
else if (global.rk_barrier_broken < 0 || global.rk_barrier_broken > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 13: epilogue_matches
if (global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1 && global.rk_epilogue_matches == 1) { }
else if (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1 && global.rk_epilogue_resolved < 1) { }
else if (global.rk_epilogue_resolved < 0 || global.rk_epilogue_resolved > 1) rk_unknown = 1;
else if (global.rk_epilogue_matches < 0 || global.rk_epilogue_matches > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 14: soul_sold
if (global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1 && global.rk_soul_sold == 1) { }
else if (global.rk_soul_sold < 0 || global.rk_soul_sold > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
if (rk_blocked) return 3;
if (rk_unknown) return 4;
if (rk_action) return 1;
return 0;
