// Observe only verified XP binding; unknown facts stay -1.
if (variable_global_exists("xp")) global.rk_experience = global.xp;
rk_status = scr_routekeeper_evaluate();
if (rk_status != rk_previous) {
    rk_dismissed = 0;
    rk_warning = (rk_status == 2 || rk_status == 3);
    rk_previous = rk_status;
}
// Conservative visibility/input gate. No pause or vanilla input interception.
rk_safe = 0;
if (instance_exists(obj_mainchara) && !instance_exists(obj_battlecontroller)
    && !instance_exists(obj_heart) && variable_global_exists("interact")
    && variable_global_exists("debug")) {
    if (global.interact == 0 && obj_mainchara.cutscene == 0 && global.debug == 0) rk_safe = 1;
}
if (!rk_safe) { rk_menu = 0; exit; }
// F10: settings. F11: mode, F12: language, F8: dismiss warning.
if (keyboard_check_pressed(121)) rk_menu = 1 - rk_menu;
if (keyboard_check_pressed(119)) { rk_dismissed = 1; rk_warning = 0; }
if (rk_menu) {
    var changed;
    changed = 0;
    if (keyboard_check_pressed(122)) { rk_mode = (rk_mode + 1) mod 3; changed = 1; }
    if (keyboard_check_pressed(123)) { rk_language = 1 - rk_language; changed = 1; }
    if (changed) {
        ini_open("routekeeper.ini");
        ini_write_real("Guidance", "mode", rk_mode);
        ini_write_real("Guidance", "language", rk_language);
        ini_close();
    }
}
