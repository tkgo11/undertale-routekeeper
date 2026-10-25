// Persistent native UI. All save/history observations are read-only.
rk_menu = 0;
rk_menu_fence = 0;
rk_menu_row = 0;
rk_menu_page = 0;
rk_choice = 0;
rk_direction_up = 0; rk_direction_down = 0;
rk_direction_left = 0; rk_direction_right = 0;
scr_routekeeper_ui_layout();
rk_dismissed = 0;
rk_previous_signature = "";
rk_safe = 0;
rk_status = 4;
rk_pad_ready = 0;
rk_pad_signature = "";
rk_pad_device = -1;
rk_pad_backend = 0;
for (var i = 0; i < 4; i += 1) {
    rk_pad_button[i] = -1;
    rk_pad_previous[i] = 0;
    rk_pad_pressed[i] = 0;
    rk_pad_label[i] = "";
}
ini_open("routekeeper.ini");
var schema, saved_mode;
schema = ini_read_real("Guidance", "schema", 1);
saved_mode = ini_read_real("Guidance", "mode", 2);
// Schema 1 used 1=Active,2=Passive; schema 2 matches Core's enum.
if (schema < 2) {
    if (saved_mode == 1) saved_mode = 2;
    else if (saved_mode == 2) saved_mode = 1;
}
if (saved_mode != 0 && saved_mode != 1 && saved_mode != 2 && saved_mode != 3) saved_mode = 1;
global.rk_mode = saved_mode;
global.rk_target_route = ini_read_real("Guidance", "target_route", 0);
if (global.rk_target_route != floor(global.rk_target_route) || global.rk_target_route < 0 || global.rk_target_route > 4) global.rk_target_route = 0;
global.rk_target_epilogue = ini_read_real("Guidance", "target_epilogue", 0);
if (global.rk_target_epilogue != floor(global.rk_target_epilogue) || global.rk_target_epilogue < 0 || global.rk_target_epilogue > 2) global.rk_target_epilogue = 0;
global.rk_target_greeting = ini_read_real("Guidance", "target_greeting", 0);
if (global.rk_target_greeting != floor(global.rk_target_greeting) || global.rk_target_greeting < 0 || global.rk_target_greeting > 8) global.rk_target_greeting = 0;
global.rk_target_neutral = ini_read_real("Guidance", "target_neutral", 0);
if (global.rk_target_neutral != floor(global.rk_target_neutral) || global.rk_target_neutral < 0 || global.rk_target_neutral > 18) global.rk_target_neutral = 0;
global.rk_language = ini_read_real("Guidance", "language", 0);
if (global.rk_language != 0 && global.rk_language != 1) global.rk_language = 0;
global.rk_spoilers = ini_read_real("Guidance", "spoilers", 0);
if (global.rk_spoilers != 0 && global.rk_spoilers != 1) global.rk_spoilers = 0;
ini_close();
global.rk_decision_context = "";
global.rk_greeting_status = 0;
global.rk_greeting_text = "";
global.rk_warning_mode = 1;
global.rk_warning_code = 0;
global.rk_warning_room = -1;
global.rk_warning_enforced = 0;
global.rk_warning_text = "";
global.rk_warning_pending = 0;
global.rk_warning_ack = 0;
global.rk_objective_text = "";
global.rk_objective_id = "";
global.rk_neutral_projection = -1;
global.rk_neutral_modifiers = 0;
global.rk_progress_met = 0;
global.rk_progress_total = 0;
scr_routekeeper_init_facts();
