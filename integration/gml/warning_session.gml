// Generated warning transaction; args command,code,context,enforceable.
if (argument0 == 3 || (argument0 == 1 && (global.rk_mode == 0 || argument1 == 0))) {
    global.rk_warning_pending = 0; global.rk_warning_ack = 0;
    global.rk_warning_mode = 1; global.rk_warning_code = 0; global.rk_decision_context = ""; global.rk_warning_enforced = 0;
    return 0;
}
if (argument0 == 2) {
    if (global.rk_warning_pending) { global.rk_warning_pending = 0; global.rk_warning_ack = 1; }
    return 0;
}
if (argument0 != 1) return 0;
var enforced;
enforced = (global.rk_mode == 3 && argument3);
if (!enforced && global.rk_warning_ack == 1 && global.rk_warning_code == argument1 && global.rk_decision_context == argument2 && global.rk_warning_mode == global.rk_mode) {
    global.rk_warning_pending = 0; global.rk_warning_ack = 0; global.rk_warning_enforced = 0;
    return 0;
}
global.rk_warning_mode = global.rk_mode; global.rk_decision_context = argument2; global.rk_warning_code = argument1;
global.rk_warning_enforced = enforced; global.rk_warning_ack = 0; global.rk_warning_pending = 1;
return 1;
