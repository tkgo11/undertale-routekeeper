// Clip before drawing; never spill across the border. Width is logical pixels.
var text, limit, s, previous_font;
previous_font = draw_get_font();
// The caller selects each locale font explicitly, including self-names.
text = argument2; limit = argument3; s = global.rk_ui_scale;
if (string_width(text) > limit) {
    while (string_length(text) > 0 && string_width(text + "...") > limit) text = string_copy(text, 1, string_length(text)-1);
    text += "...";
}
draw_text_transformed(argument0*s, argument1*s, text, s, s, 0);
draw_set_font(previous_font);
