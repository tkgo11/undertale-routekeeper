// Logical coordinates match the original dialoguer's 3px solid border.
var s;
s = global.rk_ui_scale;
draw_set_color(c_white);
draw_rectangle(argument0*s, argument1*s, argument2*s-1, argument3*s-1, false);
draw_set_color(c_black);
draw_rectangle((argument0+3)*s, (argument1+3)*s, (argument2-3)*s-1, (argument3-3)*s-1, false);
draw_set_color(c_white);
