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
// requirement 2: genocide_aborted
if (global.rk_genocide_aborted >= 0 && global.rk_genocide_aborted <= 1 && global.rk_genocide_aborted == 0) { }
else if (global.rk_genocide_aborted < 0 || global.rk_genocide_aborted > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 3: snowdrake_lost
if (global.rk_snowdrake_lost >= 0 && global.rk_snowdrake_lost <= 1 && global.rk_snowdrake_lost == 0) { }
else if (global.rk_snowdrake_lost < 0 || global.rk_snowdrake_lost > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 4: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 2) { }
else if (global.rk_toriel_resolved >= 0 && global.rk_toriel_resolved <= 1 && global.rk_toriel_resolved < 1) { }
else if (global.rk_toriel_resolved < 0 || global.rk_toriel_resolved > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 5: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 8) { }
else if (global.rk_papyrus_resolved >= 0 && global.rk_papyrus_resolved <= 1 && global.rk_papyrus_resolved < 1) { }
else if (global.rk_papyrus_resolved < 0 || global.rk_papyrus_resolved > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 6: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 12) { }
else if (global.rk_undyne_resolved >= 0 && global.rk_undyne_resolved <= 1 && global.rk_undyne_resolved < 1) { }
else if (global.rk_undyne_resolved < 0 || global.rk_undyne_resolved > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 7: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 16) { }
else if (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1 && global.rk_mettaton_defeated < 1) { }
else if (global.rk_mettaton_defeated < 0 || global.rk_mettaton_defeated > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 8: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 16) { }
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; }
// requirement 9: sans_defeated
if (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 1) { }
else if (global.rk_sans_defeated < 0 || global.rk_sans_defeated > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 10: soul_sold
if (global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1 && global.rk_soul_sold == 0) { }
else if (global.rk_soul_sold < 0 || global.rk_soul_sold > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
if (rk_blocked) return 3;
if (rk_unknown) return 4;
if (rk_action) return 1;
return 0;
