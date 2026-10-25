// Only mod-owned globals/settings are written. Actual gameplay state remains with verified hooks.
rk_menu_fence = rk_menu;
scr_routekeeper_read_state();
global.rk_neutral_projection = scr_routekeeper_neutral_classify();
global.rk_neutral_modifiers = scr_routekeeper_neutral_modifiers();
rk_status = scr_routekeeper_evaluate();
if ((global.rk_warning_pending || global.rk_warning_ack) && (!global.rk_state_ready || global.rk_warning_room != room)) {
    scr_routekeeper_warning_session(3, 0, "", 0);
}
// An advisory panel must disappear once another action starts a timed battle turn.
if ((global.rk_warning_pending || global.rk_warning_ack) && instance_exists(obj_battlecontroller)
    && variable_global_exists("mnfight") && variable_global_exists("myfight")) {
    if (global.mnfight != 0 || global.myfight != 0) { scr_routekeeper_warning_session(3, 0, "", 0); }
}
if (global.rk_warning_pending && global.rk_warning_code == 2 && global.rk_water_opportunity_active == 0) {
    scr_routekeeper_warning_session(3, 0, "", 0);
}
if (global.rk_warning_pending && rk_status != 3) rk_status = 2;
var signature;
signature = string(global.rk_target_route) + ":" + string(global.rk_target_neutral) + ":" + string(global.rk_target_greeting) + ":" + string(rk_status) + ":" + global.rk_objective_id;
if (signature != rk_previous_signature) {
    rk_dismissed = 0;
    rk_previous_signature = signature;
}
// Ordinary HUD/settings are restricted to free overworld control.
rk_safe = 0;
if (global.rk_state_ready && instance_exists(obj_mainchara) && !instance_exists(obj_battlecontroller)
    && !instance_exists(obj_heart) && variable_global_exists("interact")
    && variable_global_exists("debug")) {
    if (global.interact == 0 && obj_mainchara.cutscene == 0 && global.debug == 0) {
        if (!variable_global_exists("savedata_async_id") || global.savedata_async_id < 0) rk_safe = 1;
    }
}
if (!rk_safe || global.rk_warning_pending) rk_menu = 0;

// Match the authentic runner's input backend. Use four buttons excluded from
// the player's configurable confirm/cancel/menu bindings. One unused button is
// enough to open/acknowledge; native directions and confirm/cancel navigate.
var count, backend, device, j, code, pad_signature, held;
count = 0; backend = 0; device = -1;
for (j = 0; j < 4; j += 1) { rk_pad_button[j] = -1; rk_pad_label[j] = ""; }
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
rk_pad_ready = count > 0;
pad_signature = string(backend) + ":" + string(device);
for (j = 0; j < 4; j += 1) pad_signature += ":" + string(rk_pad_button[j]);
for (j = 0; j < 4; j += 1) {
    held = 0;
    if (rk_pad_ready && j < count) {
        if (backend == 1) held = joystick_check_button(device, rk_pad_button[j]);
        if (backend == 2 && gamepad_is_connected(device)) held = gamepad_button_check(device, rk_pad_button[j]);
    }
    rk_pad_pressed[j] = held && !rk_pad_previous[j] && pad_signature == rk_pad_signature;
    rk_pad_previous[j] = held;
}
rk_pad_signature = pad_signature;
rk_pad_device = device;
rk_pad_backend = backend;

// Direction edges follow obj_time's verified keyboard/pad backend.
var up, down, left, right, accept, cancel, held_up, held_down, held_left, held_right;
held_up = 0; held_down = 0; held_left = 0; held_right = 0;
if (instance_exists(obj_time)) {
    held_up = obj_time.up; held_down = obj_time.down;
    held_left = obj_time.left; held_right = obj_time.right;
}
up = (held_up && !rk_direction_up) || keyboard_check_pressed(116);
down = (held_down && !rk_direction_down) || keyboard_check_pressed(117) || rk_pad_pressed[1];
left = (held_left && !rk_direction_left) || keyboard_check_pressed(118) || rk_pad_pressed[2];
right = (held_right && !rk_direction_right) || keyboard_check_pressed(120) || rk_pad_pressed[3];
rk_direction_up = held_up; rk_direction_down = held_down;
rk_direction_left = held_left; rk_direction_right = held_right;
// Deferred hooks own the event and its replay. UI only acknowledges a warning.
// No confirm/cancel key is stolen from an active battle or dialogue.
if (global.rk_warning_pending) {
    if (keyboard_check_pressed(119) || rk_pad_pressed[0]) {
        scr_routekeeper_warning_session(2, 0, "", 0);
    }
    exit;
}
if (!rk_safe) exit;
if (keyboard_check_pressed(121) || rk_pad_pressed[0]) {
    rk_menu = 1 - rk_menu; rk_menu_page = 0;
    control_clear(0); control_clear(1); control_clear(2);
    // Finish this frame before accepting a button that opened the menu.
    exit;
}
if (keyboard_check_pressed(119)) rk_dismissed = 1;
if (!rk_menu) exit;
accept = control_check_pressed(0);
cancel = control_check_pressed(1) || control_check_pressed(2);
// Own confirm/cancel only while this menu is open. Closing/choosing Back must
// not leak the same press to a later player Step or open the original inventory.
control_clear(0); control_clear(1); control_clear(2);
var changed, delta, options, old_page;
changed = 0; delta = 0;
if (up) delta = -1;
if (down) delta = 1;
if (cancel) {
    if (rk_menu_page == 0) rk_menu = 0;
    if (rk_menu_page == 7 || rk_menu_page == 8) { rk_choice = rk_menu_page - 7; rk_menu_page = 2; }
    else rk_menu_page = 0;
    exit;
}
// Retain the original optional mode/language shortcuts inside settings only.
if (keyboard_check_pressed(122)) { global.rk_mode = (global.rk_mode + 1) mod 4; changed = 1; }
if (keyboard_check_pressed(123)) { global.rk_language = 1 - global.rk_language; changed = 1; }
old_page = rk_menu_page;
if (rk_menu_page == 0) {
    rk_menu_row = scr_routekeeper_ui_nav(rk_menu_row,delta,7);
    if (accept || left || right) {
        if (rk_menu_row == 6) rk_menu = 0;
        else if (!(rk_menu_row == 1 && (global.rk_target_route == 2 || global.rk_target_route == 4))) {
            rk_menu_page = rk_menu_row + 1;
            if (rk_menu_page == 1) rk_choice = global.rk_target_route;
            if (rk_menu_page == 2) { rk_choice = global.rk_target_epilogue; if (global.rk_target_route == 3) rk_choice = 0; }
            if (rk_menu_page == 3) rk_choice = global.rk_mode;
            if (rk_menu_page == 4) rk_choice = global.rk_spoilers;
            if (rk_menu_page == 5) rk_choice = global.rk_language;
        }
    }
} else if (rk_menu_page == 6) {
    if (accept || left) rk_menu_page = 0;
} else {
    options = 2;
    if (rk_menu_page == 1) options = 5;
    if (rk_menu_page == 2) options = 3;
    if (rk_menu_page == 7) options = 19;
    if (rk_menu_page == 8) options = 9;
    if (rk_menu_page == 3) options = 4;
    rk_choice = scr_routekeeper_ui_nav(rk_choice,delta,options);
    if (left) { if (old_page == 7 || old_page == 8) { rk_choice = old_page - 7; rk_menu_page = 2; } else rk_menu_page = 0; }
    if ((accept || right) && !left) {
        if (old_page == 2 && global.rk_target_route == 3) {
            if (rk_choice == 0) { rk_menu_page = 7; rk_choice = global.rk_target_neutral; }
            else if (rk_choice == 1) { rk_menu_page = 8; rk_choice = global.rk_target_greeting; }
            else rk_menu_page = 0;
        } else {
        if (old_page == 1) global.rk_target_route = rk_choice;
        if (old_page == 7) global.rk_target_neutral = rk_choice;
        if (old_page == 8) global.rk_target_greeting = rk_choice;
        if (old_page == 2 && global.rk_target_route != 3) global.rk_target_epilogue = rk_choice;
        if (old_page == 3) global.rk_mode = rk_choice;
        if (old_page == 4) global.rk_spoilers = rk_choice;
        if (old_page == 5) global.rk_language = rk_choice;
        changed = 1; rk_menu_page = 0;
        if (old_page == 7 || old_page == 8) { rk_menu_page = 2; rk_choice = old_page - 7; }
        }
    }
}
if (changed) {
    rk_dismissed = 0;
    scr_routekeeper_warning_session(3, 0, "", 0);
    ini_open("routekeeper.ini");
    ini_write_real("Guidance", "schema", 3);
    ini_write_real("Guidance", "target_greeting", global.rk_target_greeting);
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
