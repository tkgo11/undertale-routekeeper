// Only mod-owned globals/settings are written. Actual gameplay state remains with verified hooks.
scr_routekeeper_read_state();
global.rk_neutral_projection = scr_routekeeper_neutral_classify();
global.rk_neutral_modifiers = scr_routekeeper_neutral_modifiers();
rk_status = scr_routekeeper_evaluate();
// An advisory panel must disappear once another action starts a timed battle turn.
if (global.rk_warning_pending && instance_exists(obj_battlecontroller)
    && variable_global_exists("mnfight") && variable_global_exists("myfight")) {
    if (global.mnfight != 0 || global.myfight != 0) { global.rk_warning_pending = 0; global.rk_warning_ack = 0; }
}
if (global.rk_warning_pending && global.rk_warning_code == 2 && global.rk_water_opportunity_active == 0) {
    global.rk_warning_pending = 0; global.rk_warning_ack = 0;
}
if (global.rk_warning_pending && rk_status != 3) rk_status = 2;
var signature;
signature = string(global.rk_target_route) + ":" + string(global.rk_target_neutral) + ":" + string(rk_status) + ":" + global.rk_objective_id;
if (signature != rk_previous_signature) {
    rk_dismissed = 0;
    rk_previous_signature = signature;
}
// Ordinary HUD/settings are restricted to free overworld control.
rk_safe = 0;
if (instance_exists(obj_mainchara) && !instance_exists(obj_battlecontroller)
    && !instance_exists(obj_heart) && variable_global_exists("interact")
    && variable_global_exists("debug")) {
    if (global.interact == 0 && obj_mainchara.cutscene == 0 && global.debug == 0) {
        if (!variable_global_exists("savedata_async_id") || global.savedata_async_id < 0) rk_safe = 1;
    }
}
if (!rk_safe || global.rk_warning_pending) rk_menu = 0;

// Match the authentic runner's input backend. Use four buttons excluded from
// the player's configurable confirm/cancel/menu bindings; never consume directions.
var count, backend, device, j, code, pad_signature, held;
count = 0; backend = 0; device = -1;
if (instance_exists(obj_time) && variable_global_exists("osflavor")
    && variable_global_exists("button0") && variable_global_exists("button1")
    && variable_global_exists("button2")) {
    if (obj_time.j_ch > 0) {
        device = obj_time.j_ch;
        if (global.osflavor >= 4) {
            backend = 2;
            device -= 1;
            rk_pad_candidate[0] = gp_shoulderl;
            rk_pad_candidate[1] = gp_shoulderr;
            rk_pad_candidate[2] = gp_stickl;
            rk_pad_candidate[3] = gp_stickr;
            rk_pad_candidate[4] = gp_shoulderlb;
            rk_pad_candidate[5] = gp_shoulderrb;
            rk_pad_candidate[6] = gp_select;
            rk_pad_candidate[7] = gp_start;
            for (j = 0; j < 8 && count < 4; j += 1) {
                code = rk_pad_candidate[j];
                if (code != global.button0 && code != global.button1 && code != global.button2) {
                    rk_pad_button[count] = code;
                    if (j == 0) rk_pad_label[count] = "L1";
                    if (j == 1) rk_pad_label[count] = "R1";
                    if (j == 2) rk_pad_label[count] = "L3";
                    if (j == 3) rk_pad_label[count] = "R3";
                    if (j == 4) rk_pad_label[count] = "L2";
                    if (j == 5) rk_pad_label[count] = "R2";
                    if (j == 6) rk_pad_label[count] = "Select";
                    if (j == 7) rk_pad_label[count] = "Start";
                    count += 1;
                }
            }
        } else {
            backend = 1;
            for (j = 1; j <= joystick_buttons(device) && count < 4; j += 1) {
                if (j != global.button0 && j != global.button1 && j != global.button2) {
                    rk_pad_button[count] = j;
                    rk_pad_label[count] = "B" + string(j);
                    count += 1;
                }
            }
        }
    }
}
if (backend == 2 && !gamepad_is_connected(device)) count = 0;
rk_pad_ready = count == 4;
pad_signature = string(backend) + ":" + string(device);
for (j = 0; j < 4; j += 1) pad_signature += ":" + string(rk_pad_button[j]);
for (j = 0; j < 4; j += 1) {
    held = 0;
    if (rk_pad_ready) {
        if (backend == 1) held = joystick_check_button(device, rk_pad_button[j]);
        if (backend == 2 && gamepad_is_connected(device)) held = gamepad_button_check(device, rk_pad_button[j]);
    }
    rk_pad_pressed[j] = held && !rk_pad_previous[j] && pad_signature == rk_pad_signature;
    rk_pad_previous[j] = held;
}
rk_pad_signature = pad_signature;
rk_pad_device = device;
rk_pad_backend = backend;

// Deferred hooks own the event and its replay. UI only acknowledges a warning.
// No confirm/cancel key is stolen from an active battle or dialogue.
if (global.rk_warning_pending) {
    if (keyboard_check_pressed(119) || rk_pad_pressed[0]) {
        global.rk_warning_ack = 1;
        global.rk_warning_pending = 0;
    }
    exit;
}
if (!rk_safe) exit;
if (keyboard_check_pressed(121) || rk_pad_pressed[0]) rk_menu = 1 - rk_menu;
if (keyboard_check_pressed(119)) rk_dismissed = 1;
if (!rk_menu) exit;

var changed, delta;
changed = 0; delta = 0;
if (keyboard_check_pressed(116)) rk_menu_row = (rk_menu_row + 4) mod 5;
if (keyboard_check_pressed(117) || rk_pad_pressed[1]) rk_menu_row = (rk_menu_row + 1) mod 5;
if (keyboard_check_pressed(118) || rk_pad_pressed[2]) delta = -1;
if (keyboard_check_pressed(120) || rk_pad_pressed[3]) delta = 1;
// Retain direct mode/language hotkeys for keyboard users.
if (keyboard_check_pressed(122)) { global.rk_mode = (global.rk_mode + 1) mod 4; changed = 1; }
if (keyboard_check_pressed(123)) { global.rk_language = 1 - global.rk_language; changed = 1; }
if (delta != 0) {
    if (rk_menu_row == 0) global.rk_target_route = (global.rk_target_route + delta + 5) mod 5;
    if (rk_menu_row == 1 && global.rk_target_route == 3) global.rk_target_neutral = (global.rk_target_neutral + delta + 19) mod 19;
    if (rk_menu_row == 1 && (global.rk_target_route == 0 || global.rk_target_route == 1)) global.rk_target_epilogue = (global.rk_target_epilogue + delta + 3) mod 3;
    if (rk_menu_row == 2) global.rk_mode = (global.rk_mode + delta + 4) mod 4;
    if (rk_menu_row == 3) global.rk_spoilers = 1 - global.rk_spoilers;
    if (rk_menu_row == 4) global.rk_language = 1 - global.rk_language;
    changed = 1;
}
if (changed) {
    rk_dismissed = 0;
    global.rk_warning_ack = 0;
    ini_open("routekeeper.ini");
    ini_write_real("Guidance", "schema", 2);
    ini_write_real("Guidance", "target_route", global.rk_target_route);
    ini_write_real("Guidance", "target_epilogue", global.rk_target_epilogue);
    ini_write_real("Guidance", "target_neutral", global.rk_target_neutral);
    ini_write_real("Guidance", "mode", global.rk_mode);
    ini_write_real("Guidance", "spoilers", global.rk_spoilers);
    ini_write_real("Guidance", "language", global.rk_language);
    ini_close();
    scr_routekeeper_read_state();
    rk_status = scr_routekeeper_evaluate();
}
