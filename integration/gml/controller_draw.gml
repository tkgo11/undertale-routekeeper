// A native Draw GUI event; preserve all draw state touched by ROUTEKEEPER.
var pending, warning, show_hud;
pending = global.rk_warning_pending;
warning = (rk_status == 2 || rk_status == 3) && !rk_dismissed;
show_hud = rk_safe && global.rk_mode != 0 && (global.rk_mode != 1 || warning);
if (!pending && !rk_menu && !show_hud) exit;
var old_color, old_alpha, old_font, old_halign, old_valign;
old_color = draw_get_color(); old_alpha = draw_get_alpha(); old_font = draw_get_font();
old_halign = draw_get_halign(); old_valign = draw_get_valign();
draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
draw_set_font(fnt_maintext);
if (global.rk_language == 1) draw_set_font(fnt_routekeeper);
var title, message, mode_text, status_text, spoiler_text, route_text, subtype_text;
var rk_ui_x, rk_ui_y, box_bottom, row, label, value, text_color, width;
rk_ui_x = 12; rk_ui_y = 10; width = 600;
route_text = "True Pacifist";
if (global.rk_target_route == 1) route_text = "Soulless Pacifist";
if (global.rk_target_route == 2) route_text = "Genocide";
if (global.rk_target_route == 3) route_text = "Neutral";
if (global.rk_target_route == 4) route_text = "Soulless Genocide";
mode_text = "Off";
if (global.rk_mode == 1) mode_text = "Passive";
if (global.rk_mode == 2) mode_text = "Active";
if (global.rk_mode == 3) mode_text = "Forced";
status_text = "ON TRACK";
if (rk_status == 1) status_text = "ACTION REQUIRED";
if (rk_status == 2) status_text = "AT RISK";
if (rk_status == 3) status_text = "BLOCKED";
if (rk_status == 4) status_text = "UNKNOWN";
spoiler_text = "Minimal";
if (global.rk_spoilers == 1) spoiler_text = "Detailed";
if (global.rk_language == 1) {
    route_text = "진정한 불살";
    if (global.rk_target_route == 1) route_text = "영혼 없는 불살";
    if (global.rk_target_route == 2) route_text = "몰살";
    if (global.rk_target_route == 3) route_text = "뉴트럴";
    if (global.rk_target_route == 4) route_text = "영혼 없는 몰살";
    mode_text = "끄기";
    if (global.rk_mode == 1) mode_text = "수동 안내";
    if (global.rk_mode == 2) mode_text = "적극 안내";
    if (global.rk_mode == 3) mode_text = "강제";
    status_text = "진행 가능";
    if (rk_status == 1) status_text = "행동 필요";
    if (rk_status == 2) status_text = "위험";
    if (rk_status == 3) status_text = "막힘";
    if (rk_status == 4) status_text = "미확인";
    spoiler_text = "최소";
    if (global.rk_spoilers == 1) spoiler_text = "상세";
}
subtype_text = scr_routekeeper_neutral_label(global.rk_target_neutral, global.rk_language);
if (global.rk_spoilers == 0 && global.rk_target_neutral > 0) {
    subtype_text = "Variant " + string(global.rk_target_neutral);
    if (global.rk_language == 1) subtype_text = "변형 " + string(global.rk_target_neutral);
}

if (pending) {
    // Hooks defer their own original action; this panel does not pause the runner.
    title = "ROUTEKEEPER | " + status_text;
    message = "This action can change your selected ending.";
    if (global.rk_language == 1) message = "이 행동은 선택한 엔딩을 바꿀 수 있습니다.";
    if (global.rk_language == 0) {
        if (global.rk_warning_code == 1) message = "This attack can defeat an enemy and break your route.";
        if (global.rk_warning_code == 2) message = "Give water before leaving this room.";
        if (global.rk_warning_code == 3) message = "Meet the regional kill quota before this boss.";
        if (global.rk_warning_code == 4) message = "This encounter must be defeated for your target.";
        if (global.rk_warning_code == 5) message = "Your selected ending requires this character to survive.";
        if (global.rk_warning_code == 6) message = "Your selected ending requires defeating this character.";
        if (global.rk_warning_code == 7) message = "More kills can change your selected ending.";
        if (global.rk_warning_code == 8) message = "Finish the required regional encounters before proceeding.";
        if (global.rk_warning_code == 9) message = "This final choice differs from your selected epilogue.";
        if (global.rk_warning_code == 10) message = "Build the required friendship before gaining EXP.";
        if (global.rk_warning_code == 11) message = "Flee and find the missing required enemy before using the final quota slot.";
    } else {
        if (global.rk_warning_code == 1) message = "이 공격으로 적을 쓰러뜨리면 경로가 막힐 수 있습니다.";
        if (global.rk_warning_code == 2) message = "이 방을 떠나기 전에 물을 건네세요.";
        if (global.rk_warning_code == 3) message = "이 보스와 싸우기 전에 지역 처치 수를 채우세요.";
        if (global.rk_warning_code == 4) message = "선택한 경로에서는 이 상대를 쓰러뜨려야 합니다.";
        if (global.rk_warning_code == 5) message = "선택한 엔딩을 위해 이 인물을 살려야 합니다.";
        if (global.rk_warning_code == 6) message = "선택한 엔딩을 위해 이 인물을 쓰러뜨려야 합니다.";
        if (global.rk_warning_code == 7) message = "더 죽이면 선택한 엔딩이 달라질 수 있습니다.";
        if (global.rk_warning_code == 8) message = "진행하기 전에 지역의 필수 조우를 마치세요.";
        if (global.rk_warning_code == 9) message = "이 마지막 선택은 목표한 결말과 다릅니다.";
        if (global.rk_warning_code == 10) message = "EXP를 얻기 전에 필요한 우정을 쌓으세요.";
        if (global.rk_warning_code == 11) message = "도망친 뒤 마지막 처치 수를 채우기 전에 남은 필수 적을 찾으세요.";
    }
    draw_set_color(c_black); draw_rectangle(4, 4, 635, 130, false);
    draw_set_color(c_white); draw_rectangle(4, 4, 635, 130, true);
    draw_text(rk_ui_x, rk_ui_y, title);
    draw_text_ext(rk_ui_x, rk_ui_y + 24, message, 20, width);
    if (global.rk_language == 0) {
        if (global.rk_warning_enforced) draw_text(rk_ui_x, 102, "Protected action refused. F8: close warning");
        else draw_text(rk_ui_x, 102, "F8: acknowledge, then repeat the action to continue");
    } else {
        if (global.rk_warning_enforced) draw_text(rk_ui_x, 102, "보호 대상 행동을 막았습니다. F8: 경고 닫기");
        else draw_text(rk_ui_x, 102, "F8: 확인한 뒤 같은 행동을 다시 하면 계속합니다.");
    }
} else if (rk_menu) {
    // No pause/menu-state writes to vanilla. Modifier-free F keys and unbound pad
    // buttons avoid movement, confirm, cancel and inventory controls.
    draw_set_color(c_black); draw_rectangle(4, 4, 635, 356, false);
    draw_set_color(c_white); draw_rectangle(4, 4, 635, 356, true);
    draw_text(rk_ui_x, rk_ui_y, "ROUTEKEEPER | " + route_text);
    for (row = 0; row < 5; row += 1) {
        if (row == 0) { label = "Target"; value = route_text; }
        if (row == 1) {
            label = "Neutral ending"; value = subtype_text;
            if (global.rk_target_route != 3) {
                label = "Epilogue"; value = "Either";
                if (global.rk_target_epilogue == 1) value = "Stay";
                if (global.rk_target_epilogue == 2) value = "Leave";
                if (global.rk_language == 1) {
                    value = "모두";
                    if (global.rk_target_epilogue == 1) value = "함께 살기";
                    if (global.rk_target_epilogue == 2) value = "떠나기";
                }
            }
        }
        if (row == 2) { label = "Guidance"; value = mode_text; }
        if (row == 3) { label = "Spoilers"; value = spoiler_text; }
        if (row == 4) { label = "Language"; value = "English"; if (global.rk_language == 1) value = "한국어"; }
        if (global.rk_language == 1) {
            if (row == 0) label = "목표";
            if (row == 1) { label = "뉴트럴 엔딩"; if (global.rk_target_route != 3) label = "마지막 선택"; }
            if (row == 2) label = "안내 방식";
            if (row == 3) label = "스포일러";
            if (row == 4) label = "언어";
        }
        text_color = c_white;
        if (row == 1 && (global.rk_target_route == 2 || global.rk_target_route == 4)) text_color = c_gray;
        draw_set_color(text_color);
        if (row == rk_menu_row) draw_text(rk_ui_x, 42 + row * 26, "> ");
        draw_text(rk_ui_x + 24, 42 + row * 26, label + ": " + value);
    }
    draw_set_color(c_white);
    if (global.rk_language == 0) {
        draw_text(rk_ui_x, 184, "F5/F6: row | F7/F9: change | F10: close");
        draw_text(rk_ui_x, 206, "F11: guidance | F12: language | settings save immediately");
        draw_text(rk_ui_x, 250, "Gameplay continues. Menu closes during dialogue or battle.");
        draw_text(rk_ui_x, 274, "Forced protects supported actions only; gameplay tests pending.");
        draw_text(rk_ui_x, 296, "Permanent history is never created, deleted or rewritten.");
    } else {
        draw_text(rk_ui_x, 184, "F5/F6: 항목 | F7/F9: 변경 | F10: 닫기");
        draw_text(rk_ui_x, 206, "F11: 안내 방식 | F12: 언어 | 변경 즉시 저장");
        draw_text(rk_ui_x, 250, "게임은 계속되며 대화나 전투 중에는 설정을 닫습니다.");
        draw_text(rk_ui_x, 274, "강제 모드는 지원된 행동만 보호합니다. 실게임 검증은 아직입니다.");
        draw_text(rk_ui_x, 296, "영구 기록을 만들거나 지우거나 고치지 않습니다.");
    }
    if (rk_pad_ready) {
        message = "Pad: " + rk_pad_label[0] + " menu, " + rk_pad_label[1] + " row, " + rk_pad_label[2] + "/" + rk_pad_label[3] + " change";
        if (global.rk_language == 1) message = "패드: " + rk_pad_label[0] + " 설정, " + rk_pad_label[1] + " 항목, " + rk_pad_label[2] + "/" + rk_pad_label[3] + " 변경";
    } else {
        message = "Pad settings require four unused buttons. Keyboard remains available.";
        if (global.rk_language == 1) message = "미사용 패드 버튼 네 개가 필요합니다. 키보드는 사용할 수 있습니다.";
    }
    draw_text_ext(rk_ui_x, 228, message, 18, width);
} else {
    message = global.rk_objective_text;
    if (message == "") {
        message = "No currently available action is known.";
        if (global.rk_language == 1) message = "현재 가능한 다음 행동이 확인되지 않았습니다.";
    }
    if (warning) {
        if (rk_status == 3) {
            message = "Your selected ending is blocked in this run. F8: dismiss";
            if (global.rk_language == 1) message = "이번 회차에서 선택한 엔딩이 막혔습니다. F8: 경고 닫기";
        }
    }
    box_bottom = 62 + string_height_ext(message, 20, width);
    box_bottom = min(box_bottom, 190);
    draw_set_color(c_black); draw_rectangle(4, 4, 635, box_bottom, false);
    draw_set_color(c_white); draw_rectangle(4, 4, 635, box_bottom, true);
    title = "ROUTEKEEPER | " + route_text + " | " + status_text;
    draw_text(rk_ui_x, rk_ui_y, title);
    draw_text_ext(rk_ui_x, rk_ui_y + 24, message, 20, width);
    message = string(global.rk_progress_met) + "/" + string(global.rk_progress_total);
    if (global.rk_language == 0) message = "Requirements: " + message + " | F10: settings";
    else message = "조건: " + message + " | F10: 설정";
    draw_text(rk_ui_x, box_bottom - 24, message);
}
draw_set_font(old_font); draw_set_color(old_color); draw_set_alpha(old_alpha);
draw_set_halign(old_halign); draw_set_valign(old_valign);
