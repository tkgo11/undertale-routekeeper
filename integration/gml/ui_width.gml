// Same source-derived glyph advance used by rendering and bounded wrapping.
var text, width, i;
text = argument0; width = 0;
for (i = 1; i <= string_length(text); i += 1) {
    width += scr_routekeeper_ui_glyph(ord(string_char_at(text,i)),global.rk_ui_font);
}
return width;
