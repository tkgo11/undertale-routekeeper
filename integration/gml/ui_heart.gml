// Mod-owned 8x7 pixel cursor; no external sprite/font dependency.
var pixel_x, pixel_y, s, row, col, mask;
pixel_x = argument0; pixel_y = argument1; s = global.rk_ui_scale;
draw_set_color(c_red);
for (row = 0; row < 7; row += 1) {
    mask = "01100110";
    if (row == 1 || row == 2) mask = "11111111";
    if (row == 3) mask = "01111110";
    if (row == 4) mask = "00111100";
    if (row == 5) mask = "00011000";
    if (row == 6) mask = "00000000";
    for (col = 0; col < 8; col += 1) if (string_char_at(mask,col+1) == "1") draw_rectangle((pixel_x+col)*s,(pixel_y+row)*s,(pixel_x+col+1)*s-1,(pixel_y+row+1)*s-1,false);
}
draw_set_color(c_white);
