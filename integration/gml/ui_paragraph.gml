// Word-aware wrapping, bounded line count; also wraps Hangul without spaces.
var text, line, rest, count, n, space, take, width;
text = argument2; width = argument3; count = 0;
while (string_length(text) > 0 && count < argument4) {
    take = 0; space = 0;
    for (n = 1; n <= string_length(text); n += 1) {
        if (string_width(string_copy(text, 1, n)) > width) break;
        take = n;
        if (string_char_at(text, n) == " ") space = n;
    }
    if (take == 0) take = 1;
    if (take < string_length(text) && space > 0) take = space;
    line = string_copy(text, 1, take);
    rest = string_delete(text, 1, take);
    while (string_length(rest) > 0 && string_char_at(rest, 1) == " ") rest = string_delete(rest, 1, 1);
    if (count == argument4 - 1 && string_length(rest) > 0) line += "...";
    scr_routekeeper_ui_line(argument0, argument1 + count*18, line, width);
    text = rest; count += 1;
}
return count;
