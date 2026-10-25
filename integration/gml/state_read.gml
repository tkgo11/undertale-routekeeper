// Exact-build read-only adapter. Never touch original state before readiness.
var rk_ready, rk_name;
rk_ready = variable_global_exists("flag") && variable_global_exists("plot")
    && variable_global_exists("xp") && variable_global_exists("kills")
    && variable_global_exists("lv") && variable_global_exists("armor") && variable_global_exists("item");
global.rk_state_ready = rk_ready;
if (!rk_ready) {
    scr_routekeeper_init_facts();
    global.rk_history_refresh = 0; global.rk_history_room = -1;
    return 0;
}
// flag[512] is not an observed choice until the final dialogue commits it.
// While the scene is active, con=100/200 identifies the selected branch earlier.
global.rk_epilogue_choice = -1;
global.rk_epilogue_resolved = 0;
if (instance_exists(obj_outsideworld_event)) {
    if (obj_outsideworld_event.con >= 100) {
        global.rk_epilogue_choice = 1;
        if (obj_outsideworld_event.con >= 200) global.rk_epilogue_choice = 2;
        global.rk_epilogue_resolved = 1;
    }
} else if (string_pos("room_end_", room_get_name(room)) == 1) {
    global.rk_epilogue_choice = global.flag[512] + 1;
    global.rk_epilogue_resolved = 1;
}
global.rk_epilogue_matches = (global.rk_target_epilogue == 0 || global.rk_target_epilogue == global.rk_epilogue_choice);
// Optional, source-verified Neutral call modifiers.
global.rk_snowman_piece_carried = 0;
for (var rk_item_slot = 0; rk_item_slot < 8; rk_item_slot += 1) {
    if (global.item[rk_item_slot] == 16) global.rk_snowman_piece_carried = 1;
}
global.rk_save_exists = ossafe_file_exists("file0");
global.rk_equipped_armor = global.armor;
global.rk_healing_items_used = global.flag[260];
global.rk_experience = global.xp;
global.rk_level = global.lv;
global.rk_kills_total = global.kills;
global.rk_kills = global.kills;
global.rk_plot10 = round(global.plot * 10);
global.rk_toriel_alive = (global.flag[45] != 4);
global.rk_papyrus_alive = (global.flag[67] != 1);
global.rk_undyne_alive = (global.flag[350] != 1);
global.rk_mettaton_alive = (global.flag[425] != 1);
global.rk_toriel_resolved = (global.flag[45] >= 4);
global.rk_papyrus_resolved = (global.flag[67] == 1 || global.plot >= 101);
global.rk_undyne_resolved = (global.flag[350] == 1 || global.plot >= 122);
global.rk_mettaton_resolved = (global.flag[425] == 1 || global.plot >= 193);
global.rk_mettaton_defeated = global.rk_mettaton_resolved;
global.rk_water_opportunity_missed = (global.flag[350] == 2);
global.rk_water_opportunity_active = 0;
if (room == room_fire1 && instance_exists(obj_undynefall)) {
    global.rk_water_opportunity_active = (obj_undynefall.waterthing == 0);
}
global.rk_papyrus_friendship = (global.flag[88] >= 4);
global.rk_undyne_friendship = (global.flag[389] >= 3);
global.rk_alphys_friendship = (global.flag[493] >= 10);
global.rk_true_lab_completed = (global.flag[493] >= 12);
global.rk_barrier_broken = (global.flag[7] == 1);
global.rk_hard_mode = (global.flag[6] == 1);
global.rk_kills_ruins = global.flag[202];
global.rk_kills_snowdin = global.flag[203];
global.rk_kills_waterfall = global.flag[204];
global.rk_kills_hotland_core = global.flag[205];
global.rk_genocide_stage = scr_murderlv();
// Debug-only murder override does not establish a legitimate route.
if (global.flag[26] > 0) global.rk_genocide_stage = -1;
global.rk_murder_level = global.rk_genocide_stage;
global.rk_sans_defeated = (global.rk_genocide_stage == 16 && global.xp >= 99999);
global.rk_genocide_aborted = (global.flag[27] != 0);
global.rk_genocide_requirements_completed = (global.rk_genocide_stage >= 16 && global.flag[27] == 0);
global.rk_snowdrake_killed = (global.flag[57] == 2);
// A final multi-enemy encounter can still contain a live Snowdrake after the quota.
global.rk_snowdrake_lost = (global.flag[203] >= 16 && global.flag[57] != 2 && !instance_exists(obj_snowdrake));
global.rk_doggo_killed = (global.flag[52] == 1);
global.rk_dogi_killed = (global.flag[53] == 1);
global.rk_greater_dog_killed = (global.flag[54] == 1);
global.rk_lesser_dog_state = global.flag[55];
global.rk_shyren_killed = (global.flag[81] == 1);
global.rk_glad_dummy_killed = (global.flag[252] == 1);
global.rk_monster_kid_attacked = (global.flag[251] == 1);
global.rk_royal_guards_killed = (global.flag[402] == 1);
global.rk_muffet_killed = (global.flag[397] == 1);
global.rk_neutral_toriel_dead = (global.flag[45] == 4);
global.rk_neutral_papyrus_dead = (global.flag[67] == 1);
global.rk_neutral_undyne_dead = (global.flag[350] == 1);
global.rk_neutral_mettaton_dead = (global.flag[425] == 1);
global.rk_neutral_undyne_friendship = global.flag[389];
global.rk_neutral_alphys_friendship = global.flag[493];
// global.area is only a coarse legacy population index in this build. Use
// resource-name context for the current region; story deadlines use resolved facts.
if (!variable_global_exists("rk_area")) global.rk_area = -1;
rk_name = room_get_name(room);
// Main-room ranges include named exceptions such as room_fogroom. Prefixes below
// additionally cover later-appended rooms; the exact index map is validated.
if (room >= room_tundra1 && room < room_water1) global.rk_area = 1;
if (room >= room_water1 && room < room_fire1) global.rk_area = 2;
if (room >= room_fire1 && room < room_castle_front) global.rk_area = 3;
if (room >= room_castle_front && room <= room_castle_trueexit) global.rk_area = 4;
if (room >= room_area1 && room <= room_ruinsexit) global.rk_area = 0;
if (string_pos("room_tundra", rk_name) == 1) global.rk_area = 1;
if (string_pos("room_water", rk_name) == 1) global.rk_area = 2;
if (string_pos("room_fire", rk_name) == 1 || string_pos("room_core", rk_name) == 1) global.rk_area = 3;
if (string_pos("room_castle", rk_name) == 1 || string_pos("room_asg", rk_name) == 1
    || room == room_sanscorridor) global.rk_area = 4;
// Re-read history on room changes and at most once per 60 steps. Every read
// finishes before returning to the event loop; no vanilla save function is hooked.
if (!variable_global_exists("rk_history_refresh")) {
    global.rk_history_refresh = 0;
    global.rk_history_room = -1;
    global.rk_prior_neutral_completion = -1;
    global.rk_prior_pacifist_completion = -1;
    global.rk_soul_sold = -1;
    global.rk_world_erased = -1;
    global.rk_true_reset_available = -1;
}
global.rk_history_refresh -= 1;
if ((global.rk_history_refresh <= 0 || global.rk_history_room != room)
    && variable_global_exists("interact") && global.interact == 0
    && !instance_exists(obj_battlecontroller) && !instance_exists(OBJ_WRITER)
    && (!variable_global_exists("savedata_async_id") || global.savedata_async_id < 0)) {
    global.rk_history_refresh = 60;
    global.rk_history_room = room;
    if (variable_global_exists("osflavor") && global.osflavor <= 2) {
        global.rk_prior_neutral_completion = 0;
        global.rk_prior_pacifist_completion = 0;
        global.rk_true_reset_available = 0;
        if (ossafe_file_exists("undertale.ini")) {
            ini_open("undertale.ini");
            global.rk_prior_neutral_completion = (ini_read_real("General", "Won", 0) > 0);
            global.rk_prior_pacifist_completion = (ini_read_real("EndF", "EndF", 0) > 0);
            global.rk_true_reset_available = global.rk_prior_pacifist_completion;
            ini_close();
        }
        global.rk_soul_sold = ossafe_file_exists("system_information_963");
        global.rk_world_erased = (ossafe_file_exists("system_information_962") && !global.rk_soul_sold);
    }
}
// Availability is distinct from completion and character survival.
global.rk_papyrus_hangout_available = (global.rk_papyrus_resolved && global.rk_papyrus_alive
    && global.flag[88] < 4);
global.rk_undyne_hangout_available = (global.plot >= 122 && global.flag[354] == 2
    && global.flag[67] != 1 && global.flag[88] >= 4 && global.flag[350] == 0
    && global.flag[389] < 3 && global.kills == 0);
global.rk_alphys_date_available = (global.rk_prior_neutral_completion == 1
    && global.flag[389] >= 3 && global.kills == 0 && global.plot > 198 && global.flag[493] < 10);
global.rk_true_lab_available = (global.flag[493] >= 10 && global.flag[493] < 12);
return global.rk_state_ready;
