var page, index, lang;
page = argument0; index = argument1; lang = global.rk_language;
if (page == 1) {
    if (index == 0) return scr_routekeeper_ui_catalog("pacifist",lang);
    if (index == 1) return scr_routekeeper_ui_catalog("soulless_pacifist",lang);
    if (index == 2) return scr_routekeeper_ui_catalog("genocide",lang);
    if (index == 3) return scr_routekeeper_ui_catalog("neutral",lang);
    return scr_routekeeper_ui_catalog("soulless_genocide",lang);
}
if (page == 8) return scr_routekeeper_greeting_label(index,lang);
if (page == 7) {
    if (global.rk_spoilers == 0 && index > 0) { return string_replace_all(scr_routekeeper_ui_catalog("type_number",lang),"{index}",string(index)); }
    return scr_routekeeper_neutral_label(index,lang);
}
if (page == 2) {
    if (global.rk_target_route == 3) {
        if (global.rk_spoilers == 0 && index > 0) { return string_replace_all(scr_routekeeper_ui_catalog("variant_number",lang),"{index}",string(index)); }
        return scr_routekeeper_neutral_label(index,lang);
    }
    if (index == 0) return scr_routekeeper_ui_catalog("either",lang);
    if (index == 1) return scr_routekeeper_ui_catalog("stay",lang);
    return scr_routekeeper_ui_catalog("leave",lang);
}
if (page == 3) {
    if (index == 0) return scr_routekeeper_ui_catalog("off",lang);
    if (index == 1) return scr_routekeeper_ui_catalog("passive",lang);
    if (index == 2) return scr_routekeeper_ui_catalog("active",lang);
    return scr_routekeeper_ui_catalog("forced",lang);
}
if (page == 4) { if (index == 0) return scr_routekeeper_ui_catalog("minimal",lang); return scr_routekeeper_ui_catalog("detailed",lang); }
return scr_routekeeper_locale_name(index);
