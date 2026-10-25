// Native 320x240 pixel layout, drawn at 2x without changing the game's GUI size.
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
var lang, message, row, index, label, value, selected, first, count, pixel_y, key;
lang = global.rk_language;
if (pending) {
    scr_routekeeper_ui_box(global.rk_ui_warning_left,global.rk_ui_warning_top,global.rk_ui_warning_right,global.rk_ui_warning_bottom);
    message = scr_routekeeper_ui_catalog("warn_" + string(global.rk_warning_code),lang);
    scr_routekeeper_ui_paragraph(global.rk_ui_warning_x,global.rk_ui_warning_y,"* " + message,global.rk_ui_warning_width,global.rk_ui_warning_lines);
    if (global.rk_warning_enforced) key = "close_warning"; else key = "retry_warning";
    message = scr_routekeeper_ui_catalog(key,lang);
    if (rk_pad_ready) {
        if (global.rk_warning_enforced) key = "pad_close_warning"; else key = "pad_retry_warning";
        message = rk_pad_label[0] + ": " + scr_routekeeper_ui_catalog(key,lang);
    }
    scr_routekeeper_ui_line(global.rk_ui_warning_x,global.rk_ui_warning_footer,message,264);
} else if (rk_menu) {
    scr_routekeeper_ui_box(global.rk_ui_menu_left,global.rk_ui_menu_top,global.rk_ui_menu_right,global.rk_ui_menu_bottom);
    scr_routekeeper_ui_line(28,24,"ROUTEKEEPER",264);
    if (rk_menu_page == 6) {
        scr_routekeeper_ui_line(28,48,scr_routekeeper_ui_option(1,global.rk_target_route),264);
        value = string(global.rk_progress_met) + " / " + string(global.rk_progress_total);
        scr_routekeeper_ui_line(28,70,scr_routekeeper_ui_catalog("journal",lang) + "   " + value,264);
        message = global.rk_objective_text;
        if (message == "") message = scr_routekeeper_ui_catalog("no_objective",lang);
        pixel_y = 100;
        if (global.rk_target_route == 3 && global.rk_target_greeting > 0) {
            scr_routekeeper_ui_line(28,88,scr_routekeeper_ui_catalog("call_goal",lang) + ": " + scr_routekeeper_greeting_label(global.rk_target_greeting,lang),264);
            pixel_y = 112;
        }
        scr_routekeeper_ui_paragraph(28,pixel_y,"* " + message,264,4);
    } else if (rk_menu_page == 2 && global.rk_target_route == 3) {
        for (row = 0; row < 3; row += 1) {
            key = "back"; value = "";
            if (row == 0) { key = "ending_type"; value = scr_routekeeper_ui_option(7,global.rk_target_neutral); }
            if (row == 1) { key = "call_goal"; value = scr_routekeeper_ui_option(8,global.rk_target_greeting); }
            pixel_y = global.rk_ui_row_y + row*global.rk_ui_row_height;
            draw_set_color(c_white);
            if (row == rk_choice) { scr_routekeeper_ui_heart(27,pixel_y+4); draw_set_color(c_yellow); }
            scr_routekeeper_ui_line(global.rk_ui_row_x,pixel_y,scr_routekeeper_ui_catalog(key,lang),94);
            scr_routekeeper_ui_line(global.rk_ui_value_x,pixel_y,value,152);
        }
    } else if (rk_menu_page == 0) {
        for (row = 0; row < 7; row += 1) {
            key = "back"; value = "";
            if (row == 0) { key = "goal"; value = scr_routekeeper_ui_option(1,global.rk_target_route); }
            if (row == 1) { key = "epilogue"; if (global.rk_target_route == 3) key = "ending_type"; index = global.rk_target_epilogue; if (global.rk_target_route == 3) index = global.rk_target_neutral; value = scr_routekeeper_ui_option(2,index); if (global.rk_target_route == 3) value = scr_routekeeper_ui_option(7,index); }
            if (row == 2) { key = "guidance"; value = scr_routekeeper_ui_option(3,global.rk_mode); }
            if (row == 3) { key = "spoilers"; value = scr_routekeeper_ui_option(4,global.rk_spoilers); }
            if (row == 4) { key = "language"; value = scr_routekeeper_ui_option(5,global.rk_language); }
            if (row == 5) key = "journal";
            pixel_y = global.rk_ui_row_y + row*global.rk_ui_row_height;
            draw_set_color(c_white);
            if (row == rk_menu_row) { scr_routekeeper_ui_heart(27,pixel_y+4); draw_set_color(c_yellow); }
            scr_routekeeper_ui_line(global.rk_ui_row_x,pixel_y,scr_routekeeper_ui_catalog(key,lang),94);
            if (row == 1 && (global.rk_target_route == 2 || global.rk_target_route == 4)) value = "-";
            scr_routekeeper_ui_line(global.rk_ui_value_x,pixel_y,value,152);
        }
    } else {
        count = 2;
        if (rk_menu_page == 1) count = 5;
        if (rk_menu_page == 2) count = 3;
        if (rk_menu_page == 7) count = 19;
        if (rk_menu_page == 8) count = 9;
        if (rk_menu_page == 3) count = 4;
        first = (rk_choice div global.rk_ui_visible_rows)*global.rk_ui_visible_rows;
        for (row = 0; row < global.rk_ui_visible_rows; row += 1) {
            index = first + row;
            if (index < count) {
                pixel_y = global.rk_ui_row_y + row*global.rk_ui_row_height;
                draw_set_color(c_white);
                if (index == rk_choice) { scr_routekeeper_ui_heart(27,pixel_y+4); draw_set_color(c_yellow); }
                scr_routekeeper_ui_line(global.rk_ui_row_x,pixel_y,scr_routekeeper_ui_option(rk_menu_page,index),252);
            }
        }
    }
    draw_set_color(c_white);
    key = "navigation";
    if (rk_pad_ready) key = "pad_navigation";
    scr_routekeeper_ui_line(28,global.rk_ui_footer_y,scr_routekeeper_ui_catalog(key,lang),264);
} else {
    // A single objective line and a small progress mark. Details live in Progress.
    scr_routekeeper_ui_box(16,global.rk_ui_hud_top,304,global.rk_ui_hud_bottom);
    message = global.rk_objective_text;
    if (message == "") message = scr_routekeeper_ui_catalog("no_objective",lang);
    if (warning && rk_status == 3) message = scr_routekeeper_ui_catalog("blocked",lang);
    scr_routekeeper_ui_line(global.rk_ui_hud_x,global.rk_ui_hud_y,"* " + message,global.rk_ui_hud_width);
    value = string(global.rk_progress_met) + "/" + string(global.rk_progress_total);
    scr_routekeeper_ui_line(global.rk_ui_hud_progress_x,global.rk_ui_hud_y,value,global.rk_ui_hud_progress_width);
}
draw_set_font(old_font); draw_set_color(old_color); draw_set_alpha(old_alpha);
draw_set_halign(old_halign); draw_set_valign(old_valign);
