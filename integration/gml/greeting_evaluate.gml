// Generated from NeutralGoals; 0 on track,1 action,3 blocked,4 unknown.
var gg_blocked, gg_unknown, gg_action, gg_met;
gg_blocked = 0; gg_unknown = 0; gg_action = 0;
global.rk_greeting_text = scr_routekeeper_text("guidance.the_call_condition_is_not_clear_yet",global.rk_language); global.rk_greeting_status = 0;
if (global.rk_target_greeting == 1) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead == 0))) { } else if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 0))) { } else if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead == 0))) { } else if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1 && global.rk_water_opportunity_missed == 0))) { } else if (((global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1 && global.rk_water_opportunity_missed != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.help_the_fallen_warrior_before_leaving",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills == 0))) { } else if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.do_not_defeat_any_monsters",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_friendship >= 0 && global.rk_neutral_undyne_friendship <= 2147483647 && global.rk_neutral_undyne_friendship >= 4))) { } else if (((global.rk_neutral_undyne_friendship >= 0 && global.rk_neutral_undyne_friendship <= 2147483647 && global.rk_neutral_undyne_friendship < 4))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.finish_the_warrior_s_friendship",global.rk_language); }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_alphys_friendship >= 0 && global.rk_neutral_alphys_friendship <= 2147483647 && global.rk_neutral_alphys_friendship >= 10))) { } else if (((global.rk_neutral_alphys_friendship >= 0 && global.rk_neutral_alphys_friendship <= 2147483647 && global.rk_neutral_alphys_friendship < 10))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.finish_the_letter_and_date_but_do_not_enter",global.rk_language); }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 2) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 6 && global.rk_target_neutral != 7) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead == 0))) { } else if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 0))) { } else if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead == 0))) { } else if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills >= 10)) || ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 1)) || ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 1))) { } else if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills < 10)) && ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 1)) && ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 1))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.reach_the_chosen_exile_outcome",global.rk_language); }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 3) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 6 && global.rk_target_neutral != 7) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_murder_level >= 0 && global.rk_murder_level <= 16 && global.rk_murder_level <= 11))) { } else if (((global.rk_murder_level >= 0 && global.rk_murder_level <= 16 && global.rk_murder_level > 11))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_earlier_regional_route",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead == 0))) { } else if (((global.rk_neutral_toriel_dead >= 0 && global.rk_neutral_toriel_dead <= 1 && global.rk_neutral_toriel_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 0))) { } else if (((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead == 1))) { } else if (((global.rk_neutral_mettaton_dead >= 0 && global.rk_neutral_mettaton_dead <= 1 && global.rk_neutral_mettaton_dead != 1))) {
if ((global.rk_mettaton_resolved == 1) && gg_blocked == 0 || (global.rk_mettaton_resolved == 1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.defeat_the_robot_before_the_last_battle",global.rk_language); }
if (global.rk_mettaton_resolved == 1) gg_blocked = 1; else gg_action = 1;
if (global.rk_mettaton_resolved < 0) gg_unknown = 1;
} else gg_unknown = 1;
if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills >= 10)) || ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 1)) || ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead == 1))) { } else if (((global.rk_kills >= 0 && global.rk_kills <= 2147483647 && global.rk_kills < 10)) && ((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 1)) && ((global.rk_neutral_undyne_dead >= 0 && global.rk_neutral_undyne_dead <= 1 && global.rk_neutral_undyne_dead != 1))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.reach_the_chosen_exile_outcome",global.rk_language); }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 4) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_snowman_piece_carried >= 0 && global.rk_snowman_piece_carried <= 1 && global.rk_snowman_piece_carried == 1))) { } else if (((global.rk_snowman_piece_carried >= 0 && global.rk_snowman_piece_carried <= 1 && global.rk_snowman_piece_carried != 1))) {
if ((0) && gg_blocked == 0 || (0) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.carry_a_snowy_keepsake_in_your_inventory_for_the",global.rk_language); }
if (0) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_keepsake_recoverable >= 0 && global.rk_keepsake_recoverable <= 1 && global.rk_keepsake_recoverable == 1))) { } else if (((global.rk_keepsake_recoverable >= 0 && global.rk_keepsake_recoverable <= 1 && global.rk_keepsake_recoverable != 1))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.no_carried_stored_or_obtainable_keepsake_remains_in_this",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 5) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_save_exists >= 0 && global.rk_save_exists <= 1 && global.rk_save_exists == 0))) { } else if (((global.rk_save_exists >= 0 && global.rk_save_exists <= 1 && global.rk_save_exists != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.continue_without_writing_a_save",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 6) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor == 4))) { } else if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor != 4))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_your_starting_armor_equipped",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 7) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 3 && global.rk_target_neutral != 4 && global.rk_target_neutral != 5 && global.rk_target_neutral != 6 && global.rk_target_neutral != 8 && global.rk_target_neutral != 10 && global.rk_target_neutral != 12 && global.rk_target_neutral != 14) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used == 0))) { } else if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.avoid_healing_items_even_at_full_hp",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 8) {
if (global.rk_target_neutral != 0 && global.rk_target_neutral != 1 && global.rk_target_neutral != 2 && global.rk_target_neutral != 4 && global.rk_target_neutral != 6) { gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.choose_a_compatible_ending_type_for_this_call_condition",global.rk_language); }
if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead == 0))) { } else if (((global.rk_neutral_papyrus_dead >= 0 && global.rk_neutral_papyrus_dead <= 1 && global.rk_neutral_papyrus_dead != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_the_required_characters_alive",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used == 0))) { } else if (((global.rk_healing_items_used >= 0 && global.rk_healing_items_used <= 2147483647 && global.rk_healing_items_used != 0))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.avoid_healing_items_even_at_full_hp",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_level >= 0 && global.rk_level <= 2147483647 && global.rk_level == 1))) { } else if (((global.rk_level >= 0 && global.rk_level <= 2147483647 && global.rk_level != 1))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_lv_1_until_the_call",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor == 4))) { } else if (((global.rk_equipped_armor >= 0 && global.rk_equipped_armor <= 2147483647 && global.rk_equipped_armor != 4))) {
if ((1) && gg_blocked == 0 || (1) == 0 && gg_blocked == 0 && gg_action == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.keep_your_starting_armor_equipped",global.rk_language); }
if (1) gg_blocked = 1; else gg_action = 1;
} else gg_unknown = 1;
}
if (global.rk_target_greeting == 8 && global.rk_target_neutral == 6 && gg_blocked == 0) { gg_unknown = 1; global.rk_greeting_text = scr_routekeeper_text("guidance.this_call_condition_may_not_be_attainable_with_this",global.rk_language); }
// Generated source-backed keepsake acquisition/retrieval objectives.
if (global.rk_target_greeting == 4 && global.rk_snowman_piece_carried == 0 && gg_blocked == 0) {
if (global.rk_snowman_piece_available == 1) { global.rk_greeting_text = scr_routekeeper_text("guidance.return_to_the_snow_figure_in_the_forest_and",global.rk_language); }
if (global.rk_snowman_piece_stored == 1) { global.rk_greeting_text = scr_routekeeper_text("guidance.retrieve_the_snowy_keepsake_from_a_storage_box",global.rk_language); }
if ((global.rk_snowman_piece_stored == 1 || global.rk_snowman_piece_available == 1) && global.rk_inventory_space == 0) { global.rk_greeting_text = scr_routekeeper_text("guidance.make_room_in_your_inventory_for_the_keepsake",global.rk_language); }
}
if (gg_action) global.rk_greeting_status = 1;
if (gg_unknown) global.rk_greeting_status = 4;
if (gg_blocked) global.rk_greeting_status = 3;
return global.rk_greeting_status;
