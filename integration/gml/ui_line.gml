// Draw exact authenticated atlas glyphs without touching global font/alignment.
// Width, offset and source rectangles come from patch-time font metadata.
var text, limit, s, i, character, advance, pixel_x;
text = argument2; limit = argument3; s = global.rk_ui_scale;
if (scr_routekeeper_ui_width(text) > limit) {
    while (string_length(text) > 0 && scr_routekeeper_ui_width(text + "...") > limit) text = string_copy(text, 1, string_length(text)-1);
    text += "...";
}
pixel_x = argument0;
for (i = 1; i <= string_length(text); i += 1) {
    character = ord(string_char_at(text,i));
    advance = scr_routekeeper_ui_glyph(character,global.rk_ui_font);
    if (global.rk_glyph_sprite >= 0 && global.rk_glyph_width > 0 && global.rk_glyph_height > 0) {
        draw_sprite_part_ext(global.rk_glyph_sprite,0,global.rk_glyph_x,global.rk_glyph_y,
            global.rk_glyph_width,global.rk_glyph_height,(pixel_x+global.rk_glyph_offset)*s,
            argument1*s,s,s,draw_get_color(),draw_get_alpha());
    }
    pixel_x += advance;
}
