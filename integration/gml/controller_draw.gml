if (!rk_safe) exit;
if (rk_mode == 0 && !rk_menu) exit;
if (rk_mode == 2 && !rk_warning && !rk_menu) exit;
if (rk_mode == 2 && rk_dismissed && !rk_menu) exit;
var old_color, old_alpha, old_font, old_halign, old_valign, title, message, mode_text;
old_color = draw_get_color();
old_alpha = draw_get_alpha();
old_font = draw_get_font();
old_halign = draw_get_halign();
old_valign = draw_get_valign();
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_black);
draw_rectangle(4, 4, 635, 68 + rk_menu * 38, false);
draw_set_color(c_white);
draw_rectangle(4, 4, 635, 68 + rk_menu * 38, true);
draw_set_font(fnt_routekeeper);
title = "ROUTEKEEPER: True Pacifist [experimental] F10: settings";
message = "Avoid EXP. Other requirements are not yet verified.";
if (rk_status == 3 && !rk_dismissed) message = "This route is blocked in the current run. F8: dismiss";
if (rk_language == 1) {
    title = "ROUTEKEEPER: 진정한 불살 [실험 기능] F10: 설정";
    message = "EXP를 얻지 마세요. 나머지 조건은 아직 확인되지 않았습니다.";
    if (rk_status == 3 && !rk_dismissed) message = "이번 회차에서 경로가 막혔습니다. F8: 경고 닫기";
}
draw_text(12, 10, title);
draw_text(12, 32, message);
if (rk_menu) {
    mode_text = "Off";
    if (rk_mode == 1) mode_text = "Active";
    if (rk_mode == 2) mode_text = "Passive";
    draw_text(12, 56, "F10: settings | F11: " + mode_text + " | F12: English / 한국어");
    if (rk_language == 0) draw_text(12, 78, "Forced is unavailable. Gameplay continues while settings are visible.");
    else draw_text(12, 78, "강제 모드는 준비 중입니다. 설정 화면에서도 게임은 계속됩니다.");
}
draw_set_font(old_font);
draw_set_color(old_color);
draw_set_alpha(old_alpha);
draw_set_halign(old_halign);
draw_set_valign(old_valign);
