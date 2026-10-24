// Generated from RouteCatalog; do not edit.
// Status: 0 ON_TRACK, 1 ACTION_REQUIRED, 2 AT_RISK, 3 BLOCKED, 4 UNKNOWN.
var rk_unknown, rk_action, rk_blocked;
rk_unknown = 0; rk_action = 0; rk_blocked = 0;
// global.rk_experience
if (global.rk_experience < 0) rk_unknown = 1;
else if (global.rk_experience != 0) { rk_action = 1; rk_blocked = 1; }
// global.rk_papyrus_alive
if (global.rk_papyrus_alive < 0 || global.rk_papyrus_alive > 1) rk_unknown = 1;
else if (global.rk_papyrus_alive != 1) { rk_action = 1; rk_blocked = 1; }
// global.rk_undyne_alive
if (global.rk_undyne_alive < 0 || global.rk_undyne_alive > 1) rk_unknown = 1;
else if (global.rk_undyne_alive != 1) { rk_action = 1; rk_blocked = 1; }
// global.rk_water_opportunity_missed
if (global.rk_water_opportunity_missed < 0 || global.rk_water_opportunity_missed > 1) rk_unknown = 1;
else if (global.rk_water_opportunity_missed != 0) { rk_action = 1; rk_blocked = 1; }
// global.rk_papyrus_friendship
if (global.rk_papyrus_friendship < 0 || global.rk_papyrus_friendship > 1) rk_unknown = 1;
else if (global.rk_papyrus_friendship != 1) { rk_action = 1; }
// global.rk_undyne_friendship
if (global.rk_undyne_friendship < 0 || global.rk_undyne_friendship > 1) rk_unknown = 1;
else if (global.rk_undyne_friendship != 1) { rk_action = 1; }
// global.rk_prior_neutral_completion
if (global.rk_prior_neutral_completion < 0 || global.rk_prior_neutral_completion > 1) rk_unknown = 1;
else if (global.rk_prior_neutral_completion != 1) { rk_action = 1; }
// global.rk_alphys_friendship
if (global.rk_alphys_friendship < 0 || global.rk_alphys_friendship > 1) rk_unknown = 1;
else if (global.rk_alphys_friendship != 1) { rk_action = 1; }
// global.rk_true_lab_completed
if (global.rk_true_lab_completed < 0 || global.rk_true_lab_completed > 1) rk_unknown = 1;
else if (global.rk_true_lab_completed != 1) { rk_action = 1; }
// global.rk_soul_sold
if (global.rk_soul_sold < 0 || global.rk_soul_sold > 1) rk_unknown = 1;
else if (global.rk_soul_sold != 0) { rk_action = 1; rk_blocked = 1; }
if (rk_blocked) return 3;
if (rk_unknown) return 4;
if (rk_action) return 1;
return 4; // Partial coverage never claims full reachability.
