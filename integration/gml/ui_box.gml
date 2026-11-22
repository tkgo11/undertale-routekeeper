// Logical coordinates match the original dialoguer's 3px solid border.
var s, x0, y0;
s = global.rk_ui_scale;
x0 = global.rk_ui_origin_x; y0 = global.rk_ui_origin_y;
draw_set_color(c_white);
draw_rectangle(round(x0+argument0*s), round(y0+argument1*s), round(x0+argument2*s)-1, round(y0+argument3*s)-1, false);
draw_set_color(c_black);
draw_rectangle(round(x0+(argument0+3)*s), round(y0+(argument1+3)*s), round(x0+(argument2-3)*s)-1, round(y0+(argument3-3)*s)-1, false);
draw_set_color(c_white);
