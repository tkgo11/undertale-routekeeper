// Generated from the same ObjectiveRules used by C#.
var rk_text, rk_unknown, rk_action, rk_blocked;
rk_text = scr_routekeeper_text("guidance.your_next_step_is_not_clear_yet",global.rk_language);
global.rk_objective_id = "unknown";
global.rk_progress_met = 0; global.rk_progress_total = 0;
rk_unknown = 0; rk_action = 0; rk_blocked = 0;
if (global.rk_target_route == 0) {
global.rk_progress_total = 15;
// requirement 0: world_erased
if (global.rk_world_erased >= 0 && global.rk_world_erased <= 1 && global.rk_world_erased == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_world_erased < 0 || global.rk_world_erased > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 1: hard_mode
if (global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1 && global.rk_hard_mode == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_hard_mode < 0 || global.rk_hard_mode > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 2: experience
if (global.rk_experience >= 0 && global.rk_experience <= 2147483647 && global.rk_experience == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_experience < 0 || global.rk_experience > 2147483647) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 3: kills_total
if (global.rk_kills_total >= 0 && global.rk_kills_total <= 2147483647 && global.rk_kills_total == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_kills_total < 0 || global.rk_kills_total > 2147483647) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 4: papyrus_alive
if (global.rk_papyrus_alive >= 0 && global.rk_papyrus_alive <= 1 && global.rk_papyrus_alive == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_papyrus_alive < 0 || global.rk_papyrus_alive > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 5: undyne_alive
if (global.rk_undyne_alive >= 0 && global.rk_undyne_alive <= 1 && global.rk_undyne_alive == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_undyne_alive < 0 || global.rk_undyne_alive > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 6: water_opportunity_missed
if (global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1 && global.rk_water_opportunity_missed == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_water_opportunity_missed < 0 || global.rk_water_opportunity_missed > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 7: papyrus_friendship
if (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_papyrus_friendship < 0 || global.rk_papyrus_friendship > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 8: undyne_friendship
if (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_undyne_friendship < 0 || global.rk_undyne_friendship > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 9: prior_neutral_completion
if (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_prior_neutral_completion < 0 || global.rk_prior_neutral_completion > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 10: alphys_friendship
if (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_alphys_friendship < 0 || global.rk_alphys_friendship > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 11: true_lab_completed
if (global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_true_lab_completed < 0 || global.rk_true_lab_completed > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 12: barrier_broken
if (global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_barrier_broken < 0 || global.rk_barrier_broken > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 13: epilogue_matches
if (global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1 && global.rk_epilogue_matches == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1 && global.rk_epilogue_resolved < 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_epilogue_resolved < 0 || global.rk_epilogue_resolved > 1) rk_unknown = 1;
else if (global.rk_epilogue_matches < 0 || global.rk_epilogue_matches > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 14: soul_sold
if (global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1 && global.rk_soul_sold == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_soul_sold < 0 || global.rk_soul_sold > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
if ((global.rk_world_erased >= 0 && global.rk_world_erased <= 1) && !(global.rk_world_erased == 0)) {
global.rk_objective_id = "world_erased";
rk_text = scr_routekeeper_text("guidance.the_world_is_erased_permanent_history_decisions_remain_yours",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.the_world_must_be_restored_before_continuing_some_choices",global.rk_language);
return rk_text;
}
if ((global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1) && !(global.rk_hard_mode == 0)) {
global.rk_objective_id = "hard_mode";
rk_text = scr_routekeeper_text("guidance.this_challenge_cannot_reach_the_selected_ending",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.hard_mode_ends_in_the_ruins_and_cannot_reach",global.rk_language);
return rk_text;
}
if ((global.rk_experience >= 0 && global.rk_experience <= 2147483647) && !(global.rk_experience == 0)) {
global.rk_objective_id = "experience";
rk_text = scr_routekeeper_text("guidance.avoid_gaining_exp",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.do_not_kill_enemies_or_gain_exp",global.rk_language);
return rk_text;
}
if ((global.rk_kills_total >= 0 && global.rk_kills_total <= 2147483647) && !(global.rk_kills_total == 0)) {
global.rk_objective_id = "kills_total";
rk_text = scr_routekeeper_text("guidance.keep_everyone_safe",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.do_not_kill_any_monsters_the_letter_event_checks",global.rk_language);
return rk_text;
}
if ((global.rk_papyrus_alive >= 0 && global.rk_papyrus_alive <= 1) && !(global.rk_papyrus_alive == 1)) {
global.rk_objective_id = "papyrus_alive";
rk_text = scr_routekeeper_text("guidance.keep_your_new_friends_safe",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.spare_papyrus",global.rk_language);
return rk_text;
}
if ((global.rk_undyne_alive >= 0 && global.rk_undyne_alive <= 1) && !(global.rk_undyne_alive == 1)) {
global.rk_objective_id = "undyne_alive";
rk_text = scr_routekeeper_text("guidance.keep_your_new_friends_safe",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.spare_undyne",global.rk_language);
return rk_text;
}
if ((global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1) && !(global.rk_water_opportunity_missed == 0)) {
global.rk_objective_id = "water_opportunity_missed";
rk_text = scr_routekeeper_text("guidance.help_anyone_who_needs_immediate_aid",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.give_undyne_water_when_she_collapses_in_hotland",global.rk_language);
return rk_text;
}
if ((global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1) && !(global.rk_epilogue_matches == 1) && (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1) && global.rk_epilogue_resolved >= 1) {
global.rk_objective_id = "epilogue_matches";
rk_text = scr_routekeeper_text("guidance.the_final_choice_differs_from_your_selected_outcome",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.keep_the_selected_stay_or_leave_epilogue_choice_existing",global.rk_language);
return rk_text;
}
if ((global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1) && !(global.rk_soul_sold == 0)) {
global.rk_objective_id = "soul_sold";
rk_text = scr_routekeeper_text("guidance.existing_permanent_history_does_not_match_this_ending",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.an_earlier_soul_sale_determines_this_ending_reset_does",global.rk_language);
return rk_text;
}
if ((global.rk_water_opportunity_active >= 0 && global.rk_water_opportunity_active <= 1 && global.rk_water_opportunity_active == 1)) {
global.rk_objective_id = "water_opportunity_missed";
rk_text = scr_routekeeper_text("guidance.help_the_collapsed_person_before_leaving",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.take_water_from_the_cooler_and_give_it_to",global.rk_language);
return rk_text;
}
if ((global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 0) && (global.rk_papyrus_hangout_available >= 0 && global.rk_papyrus_hangout_available <= 1 && global.rk_papyrus_hangout_available == 1)) {
global.rk_objective_id = "papyrus_friendship";
rk_text = scr_routekeeper_text("guidance.visit_your_new_friend_s_home",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.go_to_papyrus_s_house_and_finish_his_date",global.rk_language);
return rk_text;
}
if ((global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 0) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_hangout_available >= 0 && global.rk_undyne_hangout_available <= 1 && global.rk_undyne_hangout_available == 1)) {
global.rk_objective_id = "undyne_friendship";
rk_text = scr_routekeeper_text("guidance.meet_your_friends_at_their_home",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.meet_papyrus_outside_undyne_s_house_and_finish_her",global.rk_language);
return rk_text;
}
if ((global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 0) && (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1 && global.rk_mettaton_defeated == 1)) {
global.rk_objective_id = "prior_neutral_completion";
rk_text = scr_routekeeper_text("guidance.finish_the_journey_then_continue_from_your_save",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.defeat_asgore_and_omega_flowey_then_reload_your_save",global.rk_language);
return rk_text;
}
if ((global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 0) && (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_date_available >= 0 && global.rk_alphys_date_available <= 1 && global.rk_alphys_date_available == 1)) {
global.rk_objective_id = "alphys_friendship";
rk_text = scr_routekeeper_text("guidance.deliver_your_friend_s_message",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.get_undyne_s_letter_deliver_it_to_alphys_and",global.rk_language);
return rk_text;
}
if ((global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) && (global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 0) && (global.rk_true_lab_available >= 0 && global.rk_true_lab_available <= 1 && global.rk_true_lab_available == 1)) {
global.rk_objective_id = "true_lab_completed";
rk_text = scr_routekeeper_text("guidance.explore_the_path_your_friends_opened",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.enter_the_bathroom_in_alphys_s_lab_and_complete",global.rk_language);
return rk_text;
}
if ((global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) && (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1 && global.rk_epilogue_resolved == 1) && (global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1 && global.rk_epilogue_matches == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1)) {
global.rk_objective_id = "ending_complete";
rk_text = scr_routekeeper_text("guidance.your_selected_path_is_complete",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.the_barrier_is_open_and_your_final_choice_matches",global.rk_language);
return rk_text;
}
if ((global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1)) {
global.rk_objective_id = "epilogue";
rk_text = scr_routekeeper_text("guidance.finish_your_farewells_and_choose_your_future",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.speak_with_your_friends_leave_the_underground_then_keep",global.rk_language);
return rk_text;
}
if ((global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 1) && (global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 0) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) && (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1)) {
global.rk_objective_id = "barrier";
rk_text = scr_routekeeper_text("guidance.return_to_the_barrier_and_help_your_friends",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.return_to_the_barrier_and_complete_the_asriel_encounter",global.rk_language);
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 0)) {
global.rk_objective_id = "travel_ruins";
rk_text = scr_routekeeper_text("guidance.explore_the_ruins_without_gaining_exp",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.spare_toriel_and_continue_out_of_the_ruins_without",global.rk_language);
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 1)) {
global.rk_objective_id = "travel_snowdin";
rk_text = scr_routekeeper_text("guidance.continue_through_the_forest_and_make_a_friend",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.spare_papyrus_then_visit_his_house_for_a_date",global.rk_language);
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 2)) {
global.rk_objective_id = "travel_waterfall";
rk_text = scr_routekeeper_text("guidance.continue_through_the_caverns_and_help_those_in_need",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.flee_from_undyne_to_hotland_then_give_her_water",global.rk_language);
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area >= 3)) {
global.rk_objective_id = "travel_hotland";
rk_text = scr_routekeeper_text("guidance.continue_toward_the_castle_without_gaining_exp",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.spare_mettaton_ex_and_continue_toward_asgore_without_gaining",global.rk_language);
return rk_text;
}
}
if (global.rk_target_route == 1) {
global.rk_progress_total = 15;
// requirement 0: world_erased
if (global.rk_world_erased >= 0 && global.rk_world_erased <= 1 && global.rk_world_erased == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_world_erased < 0 || global.rk_world_erased > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 1: hard_mode
if (global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1 && global.rk_hard_mode == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_hard_mode < 0 || global.rk_hard_mode > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 2: experience
if (global.rk_experience >= 0 && global.rk_experience <= 2147483647 && global.rk_experience == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_experience < 0 || global.rk_experience > 2147483647) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 3: kills_total
if (global.rk_kills_total >= 0 && global.rk_kills_total <= 2147483647 && global.rk_kills_total == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_kills_total < 0 || global.rk_kills_total > 2147483647) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 4: papyrus_alive
if (global.rk_papyrus_alive >= 0 && global.rk_papyrus_alive <= 1 && global.rk_papyrus_alive == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_papyrus_alive < 0 || global.rk_papyrus_alive > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 5: undyne_alive
if (global.rk_undyne_alive >= 0 && global.rk_undyne_alive <= 1 && global.rk_undyne_alive == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_undyne_alive < 0 || global.rk_undyne_alive > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 6: water_opportunity_missed
if (global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1 && global.rk_water_opportunity_missed == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_water_opportunity_missed < 0 || global.rk_water_opportunity_missed > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 7: papyrus_friendship
if (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_papyrus_friendship < 0 || global.rk_papyrus_friendship > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 8: undyne_friendship
if (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_undyne_friendship < 0 || global.rk_undyne_friendship > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 9: prior_neutral_completion
if (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_prior_neutral_completion < 0 || global.rk_prior_neutral_completion > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 10: alphys_friendship
if (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_alphys_friendship < 0 || global.rk_alphys_friendship > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 11: true_lab_completed
if (global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_true_lab_completed < 0 || global.rk_true_lab_completed > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 12: barrier_broken
if (global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_barrier_broken < 0 || global.rk_barrier_broken > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 13: epilogue_matches
if (global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1 && global.rk_epilogue_matches == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1 && global.rk_epilogue_resolved < 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_epilogue_resolved < 0 || global.rk_epilogue_resolved > 1) rk_unknown = 1;
else if (global.rk_epilogue_matches < 0 || global.rk_epilogue_matches > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 14: soul_sold
if (global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1 && global.rk_soul_sold == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_soul_sold < 0 || global.rk_soul_sold > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
if ((global.rk_world_erased >= 0 && global.rk_world_erased <= 1) && !(global.rk_world_erased == 0)) {
global.rk_objective_id = "world_erased";
rk_text = scr_routekeeper_text("guidance.the_world_is_erased_permanent_history_decisions_remain_yours",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.the_world_must_be_restored_before_continuing_some_choices",global.rk_language);
return rk_text;
}
if ((global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1) && !(global.rk_hard_mode == 0)) {
global.rk_objective_id = "hard_mode";
rk_text = scr_routekeeper_text("guidance.this_challenge_cannot_reach_the_selected_ending",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.hard_mode_ends_in_the_ruins_and_cannot_reach",global.rk_language);
return rk_text;
}
if ((global.rk_experience >= 0 && global.rk_experience <= 2147483647) && !(global.rk_experience == 0)) {
global.rk_objective_id = "experience";
rk_text = scr_routekeeper_text("guidance.avoid_gaining_exp",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.do_not_kill_enemies_or_gain_exp",global.rk_language);
return rk_text;
}
if ((global.rk_kills_total >= 0 && global.rk_kills_total <= 2147483647) && !(global.rk_kills_total == 0)) {
global.rk_objective_id = "kills_total";
rk_text = scr_routekeeper_text("guidance.keep_everyone_safe",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.do_not_kill_any_monsters_the_letter_event_checks",global.rk_language);
return rk_text;
}
if ((global.rk_papyrus_alive >= 0 && global.rk_papyrus_alive <= 1) && !(global.rk_papyrus_alive == 1)) {
global.rk_objective_id = "papyrus_alive";
rk_text = scr_routekeeper_text("guidance.keep_your_new_friends_safe",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.spare_papyrus",global.rk_language);
return rk_text;
}
if ((global.rk_undyne_alive >= 0 && global.rk_undyne_alive <= 1) && !(global.rk_undyne_alive == 1)) {
global.rk_objective_id = "undyne_alive";
rk_text = scr_routekeeper_text("guidance.keep_your_new_friends_safe",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.spare_undyne",global.rk_language);
return rk_text;
}
if ((global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1) && !(global.rk_water_opportunity_missed == 0)) {
global.rk_objective_id = "water_opportunity_missed";
rk_text = scr_routekeeper_text("guidance.help_anyone_who_needs_immediate_aid",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.give_undyne_water_when_she_collapses_in_hotland",global.rk_language);
return rk_text;
}
if ((global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1) && !(global.rk_epilogue_matches == 1) && (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1) && global.rk_epilogue_resolved >= 1) {
global.rk_objective_id = "epilogue_matches";
rk_text = scr_routekeeper_text("guidance.the_final_choice_differs_from_your_selected_outcome",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.keep_the_selected_stay_or_leave_epilogue_choice_existing",global.rk_language);
return rk_text;
}
if ((global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1) && !(global.rk_soul_sold == 1)) {
global.rk_objective_id = "soul_sold";
rk_text = scr_routekeeper_text("guidance.existing_permanent_history_does_not_match_this_ending",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.an_earlier_soul_sale_determines_this_ending_reset_does",global.rk_language);
return rk_text;
}
if ((global.rk_water_opportunity_active >= 0 && global.rk_water_opportunity_active <= 1 && global.rk_water_opportunity_active == 1)) {
global.rk_objective_id = "water_opportunity_missed";
rk_text = scr_routekeeper_text("guidance.help_the_collapsed_person_before_leaving",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.take_water_from_the_cooler_and_give_it_to",global.rk_language);
return rk_text;
}
if ((global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 0) && (global.rk_papyrus_hangout_available >= 0 && global.rk_papyrus_hangout_available <= 1 && global.rk_papyrus_hangout_available == 1)) {
global.rk_objective_id = "papyrus_friendship";
rk_text = scr_routekeeper_text("guidance.visit_your_new_friend_s_home",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.go_to_papyrus_s_house_and_finish_his_date",global.rk_language);
return rk_text;
}
if ((global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 0) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_hangout_available >= 0 && global.rk_undyne_hangout_available <= 1 && global.rk_undyne_hangout_available == 1)) {
global.rk_objective_id = "undyne_friendship";
rk_text = scr_routekeeper_text("guidance.meet_your_friends_at_their_home",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.meet_papyrus_outside_undyne_s_house_and_finish_her",global.rk_language);
return rk_text;
}
if ((global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 0) && (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1 && global.rk_mettaton_defeated == 1)) {
global.rk_objective_id = "prior_neutral_completion";
rk_text = scr_routekeeper_text("guidance.finish_the_journey_then_continue_from_your_save",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.defeat_asgore_and_omega_flowey_then_reload_your_save",global.rk_language);
return rk_text;
}
if ((global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 0) && (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_date_available >= 0 && global.rk_alphys_date_available <= 1 && global.rk_alphys_date_available == 1)) {
global.rk_objective_id = "alphys_friendship";
rk_text = scr_routekeeper_text("guidance.deliver_your_friend_s_message",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.get_undyne_s_letter_deliver_it_to_alphys_and",global.rk_language);
return rk_text;
}
if ((global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) && (global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 0) && (global.rk_true_lab_available >= 0 && global.rk_true_lab_available <= 1 && global.rk_true_lab_available == 1)) {
global.rk_objective_id = "true_lab_completed";
rk_text = scr_routekeeper_text("guidance.explore_the_path_your_friends_opened",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.enter_the_bathroom_in_alphys_s_lab_and_complete",global.rk_language);
return rk_text;
}
if ((global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) && (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1 && global.rk_epilogue_resolved == 1) && (global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1 && global.rk_epilogue_matches == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1)) {
global.rk_objective_id = "ending_complete";
rk_text = scr_routekeeper_text("guidance.your_selected_path_is_complete",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.the_barrier_is_open_and_your_final_choice_matches",global.rk_language);
return rk_text;
}
if ((global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1)) {
global.rk_objective_id = "epilogue";
rk_text = scr_routekeeper_text("guidance.finish_your_farewells_and_choose_your_future",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.speak_with_your_friends_leave_the_underground_then_keep",global.rk_language);
return rk_text;
}
if ((global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 1) && (global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 0) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) && (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1)) {
global.rk_objective_id = "barrier";
rk_text = scr_routekeeper_text("guidance.return_to_the_barrier_and_help_your_friends",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.return_to_the_barrier_and_complete_the_asriel_encounter",global.rk_language);
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 0)) {
global.rk_objective_id = "travel_ruins";
rk_text = scr_routekeeper_text("guidance.explore_the_ruins_without_gaining_exp",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.spare_toriel_and_continue_out_of_the_ruins_without",global.rk_language);
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 1)) {
global.rk_objective_id = "travel_snowdin";
rk_text = scr_routekeeper_text("guidance.continue_through_the_forest_and_make_a_friend",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.spare_papyrus_then_visit_his_house_for_a_date",global.rk_language);
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 2)) {
global.rk_objective_id = "travel_waterfall";
rk_text = scr_routekeeper_text("guidance.continue_through_the_caverns_and_help_those_in_need",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.flee_from_undyne_to_hotland_then_give_her_water",global.rk_language);
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area >= 3)) {
global.rk_objective_id = "travel_hotland";
rk_text = scr_routekeeper_text("guidance.continue_toward_the_castle_without_gaining_exp",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.spare_mettaton_ex_and_continue_toward_asgore_without_gaining",global.rk_language);
return rk_text;
}
}
if (global.rk_target_route == 2) {
global.rk_progress_total = 11;
// requirement 0: world_erased
if (global.rk_world_erased >= 0 && global.rk_world_erased <= 1 && global.rk_world_erased == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_world_erased < 0 || global.rk_world_erased > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 1: hard_mode
if (global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1 && global.rk_hard_mode == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_hard_mode < 0 || global.rk_hard_mode > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 2: genocide_aborted
if (global.rk_genocide_aborted >= 0 && global.rk_genocide_aborted <= 1 && global.rk_genocide_aborted == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_genocide_aborted < 0 || global.rk_genocide_aborted > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 3: snowdrake_lost
if (global.rk_snowdrake_lost >= 0 && global.rk_snowdrake_lost <= 1 && global.rk_snowdrake_lost == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_snowdrake_lost < 0 || global.rk_snowdrake_lost > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 4: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 2) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_toriel_resolved >= 0 && global.rk_toriel_resolved <= 1 && global.rk_toriel_resolved < 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_toriel_resolved < 0 || global.rk_toriel_resolved > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 5: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 8) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_papyrus_resolved >= 0 && global.rk_papyrus_resolved <= 1 && global.rk_papyrus_resolved < 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_papyrus_resolved < 0 || global.rk_papyrus_resolved > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 6: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 12) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_undyne_resolved >= 0 && global.rk_undyne_resolved <= 1 && global.rk_undyne_resolved < 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_undyne_resolved < 0 || global.rk_undyne_resolved > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 7: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 16) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1 && global.rk_mettaton_defeated < 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_mettaton_defeated < 0 || global.rk_mettaton_defeated > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 8: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 16) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; }
// requirement 9: sans_defeated
if (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_sans_defeated < 0 || global.rk_sans_defeated > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 10: soul_sold
if (global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1 && global.rk_soul_sold == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_soul_sold < 0 || global.rk_soul_sold > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
global.rk_progress_met = 0; if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) global.rk_progress_met = global.rk_genocide_stage; if (global.rk_sans_defeated == 1) global.rk_progress_met = global.rk_progress_met + 1; global.rk_progress_total = 17;
if ((global.rk_world_erased >= 0 && global.rk_world_erased <= 1) && !(global.rk_world_erased == 0)) {
global.rk_objective_id = "world_erased";
rk_text = scr_routekeeper_text("guidance.the_world_is_erased_permanent_history_decisions_remain_yours",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.the_world_must_be_restored_before_continuing_some_choices",global.rk_language);
return rk_text;
}
if ((global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1) && !(global.rk_hard_mode == 0)) {
global.rk_objective_id = "hard_mode";
rk_text = scr_routekeeper_text("guidance.this_challenge_cannot_reach_the_selected_ending",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.hard_mode_cannot_reach_a_genocide_ending",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_aborted >= 0 && global.rk_genocide_aborted <= 1) && !(global.rk_genocide_aborted == 0)) {
global.rk_objective_id = "genocide_aborted";
rk_text = scr_routekeeper_text("guidance.a_required_encounter_was_missed",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.a_required_enemy_was_spared_or_a_required_encounter",global.rk_language);
return rk_text;
}
if ((global.rk_snowdrake_lost >= 0 && global.rk_snowdrake_lost <= 1) && !(global.rk_snowdrake_lost == 0)) {
global.rk_objective_id = "snowdrake_lost";
rk_text = scr_routekeeper_text("guidance.a_required_enemy_can_no_longer_be_found",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.snowdrake_must_be_killed_before_no_further_encounters_or",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 2) && (global.rk_toriel_resolved >= 0 && global.rk_toriel_resolved <= 1) && global.rk_toriel_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = scr_routekeeper_text("guidance.the_first_region_s_requirements_were_missed",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.complete_the_ruins_kill_quota_and_kill_toriel_before",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 8) && (global.rk_papyrus_resolved >= 0 && global.rk_papyrus_resolved <= 1) && global.rk_papyrus_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = scr_routekeeper_text("guidance.the_forest_s_requirements_were_missed",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.complete_snowdin_s_quota_and_unique_encounters_before_killing",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 12) && (global.rk_undyne_resolved >= 0 && global.rk_undyne_resolved <= 1) && global.rk_undyne_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = scr_routekeeper_text("guidance.the_cavern_s_requirements_were_missed",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.complete_waterfall_s_quota_shyren_and_glad_dummy_then",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 16) && (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1) && global.rk_mettaton_defeated >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = scr_routekeeper_text("guidance.the_final_region_s_requirements_were_missed",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.complete_hotland_core_s_quota_and_required_encounters_before",global.rk_language);
return rk_text;
}
if ((global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1) && !(global.rk_soul_sold == 0)) {
global.rk_objective_id = "soul_sold";
rk_text = scr_routekeeper_text("guidance.existing_permanent_history_does_not_match_this_ending",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.an_earlier_soul_sale_determines_this_ending_reset_does",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 0) && (global.rk_kills_ruins >= 0 && global.rk_kills_ruins <= 2147483647 && global.rk_kills_ruins <= 19)) {
global.rk_objective_id = "quota_ruins";
rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_before_moving_on",global.rk_language), "{remaining}", string(max(0, 20 - global.rk_kills_ruins)));
if (global.rk_spoilers == 1) rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_in_the_ruins_before_leaving",global.rk_language), "{remaining}", string(max(0, 20 - global.rk_kills_ruins)));
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 1)) {
global.rk_objective_id = "toriel";
rk_text = scr_routekeeper_text("guidance.complete_the_region_s_final_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_toriel_then_enter_snowdin",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 2)) {
global.rk_objective_id = "doggo";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_doggo_do_not_spare_required_enemies",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 3)) {
global.rk_objective_id = "dog_pair";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_dogamy_and_dogaressa",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 4)) {
global.rk_objective_id = "greater_dog";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_greater_dog_kill_lesser_dog_if_encountered",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 5)) {
global.rk_objective_id = "snowdrake";
rk_text = scr_routekeeper_text("guidance.find_the_missing_required_enemy_before_exhausting_the_area",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_snowdrake_before_the_snowdin_encounter_quota_is_exhausted",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 6) && (global.rk_kills_snowdin >= 0 && global.rk_kills_snowdin <= 2147483647 && global.rk_kills_snowdin <= 15)) {
global.rk_objective_id = "quota_snowdin";
rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_before_moving_on",global.rk_language), "{remaining}", string(max(0, 16 - global.rk_kills_snowdin)));
if (global.rk_spoilers == 1) rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_in_snowdin_before_papyrus",global.rk_language), "{remaining}", string(max(0, 16 - global.rk_kills_snowdin)));
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 7)) {
global.rk_objective_id = "papyrus";
rk_text = scr_routekeeper_text("guidance.complete_the_region_s_final_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_papyrus_after_completing_the_snowdin_quota",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 8)) {
global.rk_objective_id = "shyren";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_shyren",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 9)) {
global.rk_objective_id = "glad_dummy";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_glad_dummy",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 10) && (global.rk_kills_waterfall >= 0 && global.rk_kills_waterfall <= 2147483647 && global.rk_kills_waterfall <= 17)) {
global.rk_objective_id = "quota_waterfall";
rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_before_moving_on",global.rk_language), "{remaining}", string(max(0, 18 - global.rk_kills_waterfall)));
if (global.rk_spoilers == 1) rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_in_waterfall_before_undyne",global.rk_language), "{remaining}", string(max(0, 18 - global.rk_kills_waterfall)));
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 11)) {
global.rk_objective_id = "undyne";
rk_text = scr_routekeeper_text("guidance.complete_the_region_s_decisive_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.attack_monster_kid_then_defeat_undyne_the_undying",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 12)) {
global.rk_objective_id = "royal_guards";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_the_royal_guards",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 13)) {
global.rk_objective_id = "muffet";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_muffet",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 14) && (global.rk_kills_hotland_core >= 0 && global.rk_kills_hotland_core <= 2147483647 && global.rk_kills_hotland_core <= 39)) {
global.rk_objective_id = "quota_hotland_core";
rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_before_moving_on",global.rk_language), "{remaining}", string(max(0, 40 - global.rk_kills_hotland_core)));
if (global.rk_spoilers == 1) rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_in_hotland_core_before_mettaton",global.rk_language), "{remaining}", string(max(0, 40 - global.rk_kills_hotland_core)));
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 15)) {
global.rk_objective_id = "mettaton_neo";
rk_text = scr_routekeeper_text("guidance.complete_the_region_s_final_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_mettaton_neo_after_exhausting_the_hotland_core_quota",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 16) && (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 0)) {
global.rk_objective_id = "genocide_final";
rk_text = scr_routekeeper_text("guidance.continue_to_the_final_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.defeat_sans_then_continue_toward_the_throne_room",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 16) && (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 1)) {
global.rk_objective_id = "genocide_throne";
rk_text = scr_routekeeper_text("guidance.continue_to_the_throne_room_and_choose_your_future",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.continue_through_the_throne_room_some_choices_outlast_a",global.rk_language);
return rk_text;
}
}
if (global.rk_target_route == 4) {
global.rk_progress_total = 11;
// requirement 0: world_erased
if (global.rk_world_erased >= 0 && global.rk_world_erased <= 1 && global.rk_world_erased == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_world_erased < 0 || global.rk_world_erased > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 1: hard_mode
if (global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1 && global.rk_hard_mode == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_hard_mode < 0 || global.rk_hard_mode > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 2: genocide_aborted
if (global.rk_genocide_aborted >= 0 && global.rk_genocide_aborted <= 1 && global.rk_genocide_aborted == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_genocide_aborted < 0 || global.rk_genocide_aborted > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 3: snowdrake_lost
if (global.rk_snowdrake_lost >= 0 && global.rk_snowdrake_lost <= 1 && global.rk_snowdrake_lost == 0) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_snowdrake_lost < 0 || global.rk_snowdrake_lost > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 4: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 2) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_toriel_resolved >= 0 && global.rk_toriel_resolved <= 1 && global.rk_toriel_resolved < 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_toriel_resolved < 0 || global.rk_toriel_resolved > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 5: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 8) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_papyrus_resolved >= 0 && global.rk_papyrus_resolved <= 1 && global.rk_papyrus_resolved < 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_papyrus_resolved < 0 || global.rk_papyrus_resolved > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 6: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 12) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_undyne_resolved >= 0 && global.rk_undyne_resolved <= 1 && global.rk_undyne_resolved < 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_undyne_resolved < 0 || global.rk_undyne_resolved > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 7: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 16) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1 && global.rk_mettaton_defeated < 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_mettaton_defeated < 0 || global.rk_mettaton_defeated > 1) rk_unknown = 1;
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
// requirement 8: genocide_stage
if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage >= 16) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_genocide_stage < 0 || global.rk_genocide_stage > 16) rk_unknown = 1;
else { rk_action = 1; }
// requirement 9: sans_defeated
if (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_sans_defeated < 0 || global.rk_sans_defeated > 1) rk_unknown = 1;
else { rk_action = 1; }
// requirement 10: soul_sold
if (global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1 && global.rk_soul_sold == 1) { global.rk_progress_met = global.rk_progress_met + 1; }
else if (global.rk_soul_sold < 0 || global.rk_soul_sold > 1) rk_unknown = 1;
else { rk_action = 1; rk_blocked = 1; }
global.rk_progress_met = 0; if (global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) global.rk_progress_met = global.rk_genocide_stage; if (global.rk_sans_defeated == 1) global.rk_progress_met = global.rk_progress_met + 1; global.rk_progress_total = 17;
if ((global.rk_world_erased >= 0 && global.rk_world_erased <= 1) && !(global.rk_world_erased == 0)) {
global.rk_objective_id = "world_erased";
rk_text = scr_routekeeper_text("guidance.the_world_is_erased_permanent_history_decisions_remain_yours",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.the_world_must_be_restored_before_continuing_some_choices",global.rk_language);
return rk_text;
}
if ((global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1) && !(global.rk_hard_mode == 0)) {
global.rk_objective_id = "hard_mode";
rk_text = scr_routekeeper_text("guidance.this_challenge_cannot_reach_the_selected_ending",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.hard_mode_cannot_reach_a_genocide_ending",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_aborted >= 0 && global.rk_genocide_aborted <= 1) && !(global.rk_genocide_aborted == 0)) {
global.rk_objective_id = "genocide_aborted";
rk_text = scr_routekeeper_text("guidance.a_required_encounter_was_missed",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.a_required_enemy_was_spared_or_a_required_encounter",global.rk_language);
return rk_text;
}
if ((global.rk_snowdrake_lost >= 0 && global.rk_snowdrake_lost <= 1) && !(global.rk_snowdrake_lost == 0)) {
global.rk_objective_id = "snowdrake_lost";
rk_text = scr_routekeeper_text("guidance.a_required_enemy_can_no_longer_be_found",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.snowdrake_must_be_killed_before_no_further_encounters_or",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 2) && (global.rk_toriel_resolved >= 0 && global.rk_toriel_resolved <= 1) && global.rk_toriel_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = scr_routekeeper_text("guidance.the_first_region_s_requirements_were_missed",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.complete_the_ruins_kill_quota_and_kill_toriel_before",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 8) && (global.rk_papyrus_resolved >= 0 && global.rk_papyrus_resolved <= 1) && global.rk_papyrus_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = scr_routekeeper_text("guidance.the_forest_s_requirements_were_missed",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.complete_snowdin_s_quota_and_unique_encounters_before_killing",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 12) && (global.rk_undyne_resolved >= 0 && global.rk_undyne_resolved <= 1) && global.rk_undyne_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = scr_routekeeper_text("guidance.the_cavern_s_requirements_were_missed",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.complete_waterfall_s_quota_shyren_and_glad_dummy_then",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 16) && (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1) && global.rk_mettaton_defeated >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = scr_routekeeper_text("guidance.the_final_region_s_requirements_were_missed",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.complete_hotland_core_s_quota_and_required_encounters_before",global.rk_language);
return rk_text;
}
if ((global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1) && !(global.rk_soul_sold == 1)) {
global.rk_objective_id = "soul_sold";
rk_text = scr_routekeeper_text("guidance.existing_permanent_history_does_not_match_this_ending",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.an_earlier_soul_sale_determines_this_ending_reset_does",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 0) && (global.rk_kills_ruins >= 0 && global.rk_kills_ruins <= 2147483647 && global.rk_kills_ruins <= 19)) {
global.rk_objective_id = "quota_ruins";
rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_before_moving_on",global.rk_language), "{remaining}", string(max(0, 20 - global.rk_kills_ruins)));
if (global.rk_spoilers == 1) rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_in_the_ruins_before_leaving",global.rk_language), "{remaining}", string(max(0, 20 - global.rk_kills_ruins)));
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 1)) {
global.rk_objective_id = "toriel";
rk_text = scr_routekeeper_text("guidance.complete_the_region_s_final_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_toriel_then_enter_snowdin",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 2)) {
global.rk_objective_id = "doggo";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_doggo_do_not_spare_required_enemies",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 3)) {
global.rk_objective_id = "dog_pair";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_dogamy_and_dogaressa",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 4)) {
global.rk_objective_id = "greater_dog";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_greater_dog_kill_lesser_dog_if_encountered",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 5)) {
global.rk_objective_id = "snowdrake";
rk_text = scr_routekeeper_text("guidance.find_the_missing_required_enemy_before_exhausting_the_area",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_snowdrake_before_the_snowdin_encounter_quota_is_exhausted",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 6) && (global.rk_kills_snowdin >= 0 && global.rk_kills_snowdin <= 2147483647 && global.rk_kills_snowdin <= 15)) {
global.rk_objective_id = "quota_snowdin";
rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_before_moving_on",global.rk_language), "{remaining}", string(max(0, 16 - global.rk_kills_snowdin)));
if (global.rk_spoilers == 1) rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_in_snowdin_before_papyrus",global.rk_language), "{remaining}", string(max(0, 16 - global.rk_kills_snowdin)));
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 7)) {
global.rk_objective_id = "papyrus";
rk_text = scr_routekeeper_text("guidance.complete_the_region_s_final_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_papyrus_after_completing_the_snowdin_quota",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 8)) {
global.rk_objective_id = "shyren";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_shyren",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 9)) {
global.rk_objective_id = "glad_dummy";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_glad_dummy",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 10) && (global.rk_kills_waterfall >= 0 && global.rk_kills_waterfall <= 2147483647 && global.rk_kills_waterfall <= 17)) {
global.rk_objective_id = "quota_waterfall";
rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_before_moving_on",global.rk_language), "{remaining}", string(max(0, 18 - global.rk_kills_waterfall)));
if (global.rk_spoilers == 1) rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_in_waterfall_before_undyne",global.rk_language), "{remaining}", string(max(0, 18 - global.rk_kills_waterfall)));
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 11)) {
global.rk_objective_id = "undyne";
rk_text = scr_routekeeper_text("guidance.complete_the_region_s_decisive_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.attack_monster_kid_then_defeat_undyne_the_undying",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 12)) {
global.rk_objective_id = "royal_guards";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_the_royal_guards",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 13)) {
global.rk_objective_id = "muffet";
rk_text = scr_routekeeper_text("guidance.complete_the_next_required_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_muffet",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 14) && (global.rk_kills_hotland_core >= 0 && global.rk_kills_hotland_core <= 2147483647 && global.rk_kills_hotland_core <= 39)) {
global.rk_objective_id = "quota_hotland_core";
rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_before_moving_on",global.rk_language), "{remaining}", string(max(0, 40 - global.rk_kills_hotland_core)));
if (global.rk_spoilers == 1) rk_text = string_replace_all(scr_routekeeper_text("guidance.defeat_remaining_more_enemies_in_hotland_core_before_mettaton",global.rk_language), "{remaining}", string(max(0, 40 - global.rk_kills_hotland_core)));
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 15)) {
global.rk_objective_id = "mettaton_neo";
rk_text = scr_routekeeper_text("guidance.complete_the_region_s_final_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.kill_mettaton_neo_after_exhausting_the_hotland_core_quota",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 16) && (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 0)) {
global.rk_objective_id = "genocide_final";
rk_text = scr_routekeeper_text("guidance.continue_to_the_final_encounter",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.defeat_sans_then_continue_toward_the_throne_room",global.rk_language);
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 16) && (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 1)) {
global.rk_objective_id = "genocide_throne";
rk_text = scr_routekeeper_text("guidance.continue_to_the_throne_room_and_choose_your_future",global.rk_language);
if (global.rk_spoilers == 1) rk_text = scr_routekeeper_text("guidance.continue_through_the_throne_room_some_choices_outlast_a",global.rk_language);
return rk_text;
}
}
return rk_text;
