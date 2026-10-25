// Source-validated pre-action adapter. No vanilla state or save writes.
// action: 1 fight,2 spare-all,3 flee,4 door departure,5 enter boss encounter.
if (!variable_global_exists("rk_mode") || !variable_global_exists("rk_target_route")) return 0;
if (global.rk_mode == 0) return 0;
// An impossible target must not trap a mandatory battle. Re-evaluation exposes
// BLOCKED; unsupported outcomes are never repaired with game/history writes.
if (instance_exists(obj_routekeeper)) {
    if (obj_routekeeper.rk_status == 3) {
        global.rk_warning_pending = 0; global.rk_warning_ack = 0;
        return 0;
    }
}
if (!variable_global_exists("flag")) return 0;
if (global.flag[26] > 0) return 0;
if (variable_global_exists("debug") && global.debug != 0) return 0;
var family, action, slot, enemy, target, xp_risk, required, water_pending;
var neutral_outcome, kill_cap, risk, context, first_slot, last_slot, candidate, enforceable, reserved_kills, epilogue_mismatch, regional_missing, friendship_pending, snowdrake_opportunity;
family = -1;
if (global.rk_target_route == 0 || global.rk_target_route == 1) family = 0;
if (global.rk_target_route == 2 || global.rk_target_route == 4) family = 1;
if (global.rk_target_route == 3) family = 2;
if (family < 0) return 0;
// An already abandoned route cannot be repaired by refusing unrelated actions.
if (family == 1 && global.flag[27] != 0) return 0;
if (family == 1 && global.flag[203] >= 16 && global.flag[57] != 2 && !instance_exists(obj_snowdrake)) return 0;
action = argument0; slot = argument1;
enemy = 0; target = -1; xp_risk = 0; required = 0;
water_pending = 0; neutral_outcome = 0; kill_cap = 0; risk = 0; epilogue_mismatch = 0; regional_missing = 0; friendship_pending = 0; snowdrake_opportunity = 0;
if (family == 2 && variable_global_exists("rk_neutral_friendship_min")) {
    if (global.rk_neutral_friendship_min > 0 && global.flag[389] < global.rk_neutral_friendship_min && global.kills == 0)
        friendship_pending = 1;
}
if (action == 7 && family == 2) friendship_pending = ((global.rk_target_neutral == 2 || global.rk_target_neutral == 3) && global.flag[389] == 0);
if (action >= 1 && action <= 3) {
    first_slot = slot; last_slot = slot;
    if ((action == 2 || action == 3) && slot == -1) { first_slot = 0; last_slot = 2; }
    // Aggregate the entire Spare command before acknowledging it once. Otherwise
    // two protected enemies would alternate warnings forever.
    for (candidate = first_slot; candidate <= last_slot; candidate += 1) {
        if (candidate >= 0 && candidate <= 2 && global.monster[candidate] != 0) {
            target = global.monsterinstance[candidate];
            if (instance_exists(target)) {
                enemy = scr_routekeeper_decision_enemy(target);
                xp_risk = (global.xpreward[candidate] > 0);
                if ((enemy >= 1 && enemy <= 5) || enemy == 7) xp_risk = 1;
                required = scr_routekeeper_decision_required(enemy, action, global.flag[203], global.flag[57] == 2);
                if (family == 2) neutral_outcome = scr_routekeeper_neutral_protect(enemy);
                if (family == 2 && variable_global_exists("rk_neutral_kill_cap")) {
                    reserved_kills = 0;
                    if (global.rk_neutral_keep_toriel == 0 && global.flag[45] != 4) reserved_kills += 1;
                    if (global.rk_neutral_keep_papyrus == 0 && global.flag[67] != 1) reserved_kills += 1;
                    if (global.rk_neutral_keep_undyne == 0 && global.flag[350] != 1) reserved_kills += 1;
                    if (global.rk_neutral_keep_mettaton == 0 && global.flag[425] != 1) reserved_kills += 1;
                    kill_cap = scr_routekeeper_decision_budget(global.kills, global.rk_neutral_kill_cap, reserved_kills, neutral_outcome == -1);
                }
                // Refuse only recoverable random fights; a live Snowdrake in the
                // same encounter can still satisfy the requirement after quota.
                if (family == 1 && action == 1 && enemy == 0 && global.mercy > 0
                    && global.flag[203] == 15 && global.flag[57] != 2 && !instance_exists(obj_snowdrake)) snowdrake_opportunity = 1;
                risk = scr_routekeeper_decision_risk(family, action, enemy, xp_risk,
                    global.flag[202], global.flag[203], global.flag[204], global.flag[205],
                    0, neutral_outcome, kill_cap, required, 0, 0, friendship_pending, snowdrake_opportunity);
                if (risk != 0) break;
            }
        }
    }
} else {
    if (action == 4 && room == room_fire1 && instance_exists(obj_undynefall)) {
        water_pending = (obj_undynefall.waterthing == 0);
    }
    if (action == 5 && family == 1) {
        enemy = slot;
        if (enemy == 2) regional_missing = (scr_murderlv() < 7);
        if (enemy == 8) regional_missing = (scr_murderlv() < 11);
        if (enemy == 7) regional_missing = (scr_murderlv() < 15);
    }
    if (action == 6 && family == 0 && global.rk_target_epilogue > 0) epilogue_mismatch = (global.rk_target_epilogue - 1 != slot);
    risk = scr_routekeeper_decision_risk(family, action, enemy, xp_risk,
        global.flag[202], global.flag[203], global.flag[204], global.flag[205],
        water_pending, neutral_outcome, kill_cap, required, epilogue_mismatch, regional_missing, friendship_pending, 0);
}
if (risk == 0) { global.rk_warning_pending = 0; global.rk_warning_ack = 0; return 0; }
context = string(global.rk_target_route) + ":" + string(global.rk_target_neutral)
    + ":" + string(global.rk_target_epilogue) + ":" + string(action) + ":" + string(room) + ":" + string(target) + ":" + string(slot);
if (!variable_global_exists("rk_decision_context")) global.rk_decision_context = "";
enforceable = !(risk == 3 && action == 1);
if ((global.rk_mode != 3 || !enforceable) && global.rk_warning_ack == 1
    && global.rk_warning_code == risk && global.rk_decision_context == context) {
    global.rk_warning_ack = 0;
    global.rk_warning_pending = 0;
    return 0;
}
global.rk_decision_context = context;
global.rk_warning_code = risk;
global.rk_warning_room = room;
global.rk_warning_enforced = (global.rk_mode == 3 && enforceable);
global.rk_warning_ack = 0;
global.rk_warning_pending = 1;
return 1;
