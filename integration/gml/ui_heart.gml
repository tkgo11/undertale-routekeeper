// Mod-owned 8x7 pixel cursor; no external sprite/font dependency.
var x0, y0, s, row, col, mask, left, top, right, bottom;
s = global.rk_ui_scale;
x0 = global.rk_ui_origin_x + argument0*s; y0 = global.rk_ui_origin_y + argument1*s;
draw_set_color(c_red);
for (row = 0; row < 7; row += 1) {
    mask = "01100110";
    if (row == 1 || row == 2) mask = "11111111";
    if (row == 3) mask = "01111110";
    if (row == 4) mask = "00111100";
    if (row == 5) mask = "00011000";
    if (row == 6) mask = "00000000";
    for (col = 0; col < 8; col += 1) {
        if (string_char_at(mask,col+1) != "1") continue;
        left = round(x0+col*s); top = round(y0+row*s);
        right = round(x0+(col+1)*s); bottom = round(y0+(row+1)*s);
        if (right > left && bottom > top) draw_rectangle(left,top,right-1,bottom-1,false);
    }
}
draw_set_color(c_white);
