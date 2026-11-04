// Generated dynamic route dispatcher; do not edit.
var rk_result;
rk_result = 4;
if (global.rk_target_route == 3) return scr_routekeeper_neutral_evaluate();
if (global.rk_target_route == 0) rk_result = scr_routekeeper_evaluate_0();
if (global.rk_target_route == 1) rk_result = scr_routekeeper_evaluate_1();
if (global.rk_target_route == 2) rk_result = scr_routekeeper_evaluate_2();
if (global.rk_target_route == 4) rk_result = scr_routekeeper_evaluate_4();
global.rk_objective_text = scr_routekeeper_objective();
return rk_result;
