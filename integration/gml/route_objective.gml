// Generated from the same ObjectiveRules used by C#.
var rk_text, rk_unknown, rk_action, rk_blocked;
rk_text = "No next action can be verified yet.";
if (global.rk_language == 1) rk_text = "아직 다음 행동을 확인할 수 없습니다.";
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
rk_text = "The world is erased. Permanent-history decisions remain yours.";
if (global.rk_spoilers == 1) rk_text = "The game world must already be restored. ROUTEKEEPER never sells your SOUL or rewrites system_information files.";
if (global.rk_language == 1) {
 rk_text = "세계가 지워졌습니다. 영구 기록에 관한 결정은 직접 해야 합니다.";
 if (global.rk_spoilers == 1) rk_text = "세계가 복원되어 있어야 합니다. ROUTEKEEPER는 영혼을 팔거나 영구 기록 파일을 고치지 않습니다.";
}
return rk_text;
}
if ((global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1) && !(global.rk_hard_mode == 0)) {
global.rk_objective_id = "hard_mode";
rk_text = "This challenge cannot reach the selected ending.";
if (global.rk_spoilers == 1) rk_text = "Hard Mode ends in the Ruins and cannot reach a normal ending.";
if (global.rk_language == 1) {
 rk_text = "이 도전에서는 선택한 엔딩에 도달할 수 없습니다.";
 if (global.rk_spoilers == 1) rk_text = "하드 모드는 폐허에서 끝나므로 일반 엔딩에 도달할 수 없습니다.";
}
return rk_text;
}
if ((global.rk_experience >= 0 && global.rk_experience <= 2147483647) && !(global.rk_experience == 0)) {
global.rk_objective_id = "experience";
rk_text = "Avoid gaining EXP.";
if (global.rk_spoilers == 1) rk_text = "Do not kill enemies or gain EXP.";
if (global.rk_language == 1) {
 rk_text = "EXP 획득을 피하세요.";
 if (global.rk_spoilers == 1) rk_text = "적을 죽이거나 EXP를 얻지 마세요.";
}
return rk_text;
}
if ((global.rk_kills_total >= 0 && global.rk_kills_total <= 2147483647) && !(global.rk_kills_total == 0)) {
global.rk_objective_id = "kills_total";
rk_text = "Keep everyone safe.";
if (global.rk_spoilers == 1) rk_text = "Do not kill any monsters; the letter event checks the kill count separately from EXP.";
if (global.rk_language == 1) {
 rk_text = "모두를 지켜 주세요.";
 if (global.rk_spoilers == 1) rk_text = "아무 몬스터도 죽이지 마세요. 편지 이벤트는 EXP와 별도로 처치 수를 확인합니다.";
}
return rk_text;
}
if ((global.rk_papyrus_alive >= 0 && global.rk_papyrus_alive <= 1) && !(global.rk_papyrus_alive == 1)) {
global.rk_objective_id = "papyrus_alive";
rk_text = "Keep your new friends safe.";
if (global.rk_spoilers == 1) rk_text = "Spare Papyrus.";
if (global.rk_language == 1) {
 rk_text = "새 친구들을 지켜 주세요.";
 if (global.rk_spoilers == 1) rk_text = "파피루스를 살려 주세요.";
}
return rk_text;
}
if ((global.rk_undyne_alive >= 0 && global.rk_undyne_alive <= 1) && !(global.rk_undyne_alive == 1)) {
global.rk_objective_id = "undyne_alive";
rk_text = "Keep your new friends safe.";
if (global.rk_spoilers == 1) rk_text = "Spare Undyne.";
if (global.rk_language == 1) {
 rk_text = "새 친구들을 지켜 주세요.";
 if (global.rk_spoilers == 1) rk_text = "언다인을 살려 주세요.";
}
return rk_text;
}
if ((global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1) && !(global.rk_water_opportunity_missed == 0)) {
global.rk_objective_id = "water_opportunity_missed";
rk_text = "Help anyone who needs immediate aid.";
if (global.rk_spoilers == 1) rk_text = "Give Undyne water when she collapses in Hotland.";
if (global.rk_language == 1) {
 rk_text = "즉시 도움이 필요한 상대를 도와주세요.";
 if (global.rk_spoilers == 1) rk_text = "핫랜드에서 쓰러진 언다인에게 물을 주세요.";
}
return rk_text;
}
if ((global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1) && !(global.rk_epilogue_matches == 1) && (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1) && global.rk_epilogue_resolved >= 1) {
global.rk_objective_id = "epilogue_matches";
rk_text = "The final choice differs from your selected outcome.";
if (global.rk_spoilers == 1) rk_text = "Keep the selected Stay or Leave epilogue choice; existing SOUL history determines its normal or altered form.";
if (global.rk_language == 1) {
 rk_text = "마지막 선택이 목표한 결과와 다릅니다.";
 if (global.rk_spoilers == 1) rk_text = "함께 살기 또는 떠나기 선택을 지켜 주세요. 기존 영혼 기록에 따라 일반 또는 변형 결말이 됩니다.";
}
return rk_text;
}
if ((global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1) && !(global.rk_soul_sold == 0)) {
global.rk_objective_id = "soul_sold";
rk_text = "Existing permanent history does not match this ending.";
if (global.rk_spoilers == 1) rk_text = "This outcome requires the selected existing sold-soul history. ROUTEKEEPER never creates or deletes permanent history.";
if (global.rk_language == 1) {
 rk_text = "기존 영구 기록이 이 엔딩과 맞지 않습니다.";
 if (global.rk_spoilers == 1) rk_text = "이 결과에는 선택한 영혼 판매 기록이 필요합니다. ROUTEKEEPER는 영구 기록을 만들거나 지우지 않습니다.";
}
return rk_text;
}
if ((global.rk_water_opportunity_active >= 0 && global.rk_water_opportunity_active <= 1 && global.rk_water_opportunity_active == 1)) {
global.rk_objective_id = "water_opportunity_missed";
rk_text = "Help the collapsed person before leaving.";
if (global.rk_spoilers == 1) rk_text = "Take water from the cooler and give it to Undyne before leaving.";
if (global.rk_language == 1) {
 rk_text = "떠나기 전에 쓰러진 상대를 도와주세요.";
 if (global.rk_spoilers == 1) rk_text = "떠나기 전에 정수기의 물을 언다인에게 주세요.";
}
return rk_text;
}
if ((global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 0) && (global.rk_papyrus_hangout_available >= 0 && global.rk_papyrus_hangout_available <= 1 && global.rk_papyrus_hangout_available == 1)) {
global.rk_objective_id = "papyrus_friendship";
rk_text = "Visit your new friend's home.";
if (global.rk_spoilers == 1) rk_text = "Go to Papyrus's house and finish his date or hangout.";
if (global.rk_language == 1) {
 rk_text = "새 친구의 집을 방문하세요.";
 if (global.rk_spoilers == 1) rk_text = "파피루스의 집에서 데이트 또는 어울리기를 마치세요.";
}
return rk_text;
}
if ((global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 0) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_hangout_available >= 0 && global.rk_undyne_hangout_available <= 1 && global.rk_undyne_hangout_available == 1)) {
global.rk_objective_id = "undyne_friendship";
rk_text = "Meet your friends at their home.";
if (global.rk_spoilers == 1) rk_text = "Meet Papyrus outside Undyne's house and finish her hangout.";
if (global.rk_language == 1) {
 rk_text = "친구의 집에서 함께 시간을 보내세요.";
 if (global.rk_spoilers == 1) rk_text = "언다인의 집 앞에서 파피루스를 만나 어울리기를 마치세요.";
}
return rk_text;
}
if ((global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 0) && (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1 && global.rk_mettaton_defeated == 1)) {
global.rk_objective_id = "prior_neutral_completion";
rk_text = "Finish the journey, then continue from your SAVE.";
if (global.rk_spoilers == 1) rk_text = "Defeat Asgore and Omega Flowey, then reload your SAVE.";
if (global.rk_language == 1) {
 rk_text = "여정을 마친 뒤 SAVE에서 계속하세요.";
 if (global.rk_spoilers == 1) rk_text = "아스고어와 오메가 플라위를 물리친 뒤 SAVE를 불러오세요.";
}
return rk_text;
}
if ((global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 0) && (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_date_available >= 0 && global.rk_alphys_date_available <= 1 && global.rk_alphys_date_available == 1)) {
global.rk_objective_id = "alphys_friendship";
rk_text = "Deliver your friend's message.";
if (global.rk_spoilers == 1) rk_text = "Get Undyne's letter, deliver it to Alphys, and finish the date.";
if (global.rk_language == 1) {
 rk_text = "친구의 편지를 전해 주세요.";
 if (global.rk_spoilers == 1) rk_text = "언다인의 편지를 알피스에게 전하고 데이트를 마치세요.";
}
return rk_text;
}
if ((global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) && (global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 0) && (global.rk_true_lab_available >= 0 && global.rk_true_lab_available <= 1 && global.rk_true_lab_available == 1)) {
global.rk_objective_id = "true_lab_completed";
rk_text = "Explore the path your friends opened.";
if (global.rk_spoilers == 1) rk_text = "Enter the bathroom in Alphys's lab and complete the True Lab.";
if (global.rk_language == 1) {
 rk_text = "친구들이 열어 준 길을 탐험하세요.";
 if (global.rk_spoilers == 1) rk_text = "알피스의 연구실 화장실로 들어가 진실의 연구소를 완료하세요.";
}
return rk_text;
}
if ((global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) && (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1 && global.rk_epilogue_resolved == 1) && (global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1 && global.rk_epilogue_matches == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1)) {
global.rk_objective_id = "ending_complete";
rk_text = "Your selected path is complete. Permanent history remains unchanged by the mod.";
if (global.rk_spoilers == 1) rk_text = "The observed barrier and epilogue outcomes match your selected route.";
if (global.rk_language == 1) {
 rk_text = "선택한 경로를 마쳤습니다. 모드는 영구 기록을 바꾸지 않았습니다.";
 if (global.rk_spoilers == 1) rk_text = "확인된 결계와 마지막 선택이 목표 경로와 맞습니다.";
}
return rk_text;
}
if ((global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1)) {
global.rk_objective_id = "epilogue";
rk_text = "Finish your farewells and choose your future.";
if (global.rk_spoilers == 1) rk_text = "Speak with your friends, leave the Underground, then keep your selected Stay/Leave choice.";
if (global.rk_language == 1) {
 rk_text = "친구들에게 인사하고 앞날을 선택하세요.";
 if (global.rk_spoilers == 1) rk_text = "친구들과 이야기한 뒤 지하를 떠나 함께 살기 또는 떠나기 선택을 지키세요.";
}
return rk_text;
}
if ((global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 1) && (global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 0) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) && (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1)) {
global.rk_objective_id = "barrier";
rk_text = "Return to the barrier and help your friends.";
if (global.rk_spoilers == 1) rk_text = "Return to the barrier and complete the Asriel encounter without RESET.";
if (global.rk_language == 1) {
 rk_text = "결계로 돌아가 친구들을 도와주세요.";
 if (global.rk_spoilers == 1) rk_text = "결계로 돌아가 리셋하지 않고 아스리엘 조우를 완료하세요.";
}
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 0)) {
global.rk_objective_id = "travel_ruins";
rk_text = "Explore the Ruins without gaining EXP.";
if (global.rk_spoilers == 1) rk_text = "Spare Toriel and continue out of the Ruins without gaining EXP.";
if (global.rk_language == 1) {
 rk_text = "EXP를 얻지 않고 폐허를 탐험하세요.";
 if (global.rk_spoilers == 1) rk_text = "토리엘을 살리고 EXP를 얻지 않은 채 폐허를 나가세요.";
}
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 1)) {
global.rk_objective_id = "travel_snowdin";
rk_text = "Continue through the forest and make a friend.";
if (global.rk_spoilers == 1) rk_text = "Spare Papyrus, then visit his house for a date or hangout.";
if (global.rk_language == 1) {
 rk_text = "숲을 지나며 새 친구를 만드세요.";
 if (global.rk_spoilers == 1) rk_text = "파피루스를 살린 뒤 집을 방문해 데이트 또는 어울리기를 하세요.";
}
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 2)) {
global.rk_objective_id = "travel_waterfall";
rk_text = "Continue through the caverns and help those in need.";
if (global.rk_spoilers == 1) rk_text = "Flee from Undyne to Hotland, then give her water when she collapses.";
if (global.rk_language == 1) {
 rk_text = "동굴을 지나며 도움이 필요한 상대를 도와주세요.";
 if (global.rk_spoilers == 1) rk_text = "언다인에게서 핫랜드까지 도망친 뒤 쓰러진 언다인에게 물을 주세요.";
}
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area >= 3)) {
global.rk_objective_id = "travel_hotland";
rk_text = "Continue toward the castle without gaining EXP.";
if (global.rk_spoilers == 1) rk_text = "Spare Mettaton EX and continue toward Asgore without gaining EXP.";
if (global.rk_language == 1) {
 rk_text = "EXP를 얻지 않고 성을 향해 계속 가세요.";
 if (global.rk_spoilers == 1) rk_text = "메타톤 EX를 살리고 EXP를 얻지 않은 채 아스고어에게 가세요.";
}
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
rk_text = "The world is erased. Permanent-history decisions remain yours.";
if (global.rk_spoilers == 1) rk_text = "The game world must already be restored. ROUTEKEEPER never sells your SOUL or rewrites system_information files.";
if (global.rk_language == 1) {
 rk_text = "세계가 지워졌습니다. 영구 기록에 관한 결정은 직접 해야 합니다.";
 if (global.rk_spoilers == 1) rk_text = "세계가 복원되어 있어야 합니다. ROUTEKEEPER는 영혼을 팔거나 영구 기록 파일을 고치지 않습니다.";
}
return rk_text;
}
if ((global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1) && !(global.rk_hard_mode == 0)) {
global.rk_objective_id = "hard_mode";
rk_text = "This challenge cannot reach the selected ending.";
if (global.rk_spoilers == 1) rk_text = "Hard Mode ends in the Ruins and cannot reach a normal ending.";
if (global.rk_language == 1) {
 rk_text = "이 도전에서는 선택한 엔딩에 도달할 수 없습니다.";
 if (global.rk_spoilers == 1) rk_text = "하드 모드는 폐허에서 끝나므로 일반 엔딩에 도달할 수 없습니다.";
}
return rk_text;
}
if ((global.rk_experience >= 0 && global.rk_experience <= 2147483647) && !(global.rk_experience == 0)) {
global.rk_objective_id = "experience";
rk_text = "Avoid gaining EXP.";
if (global.rk_spoilers == 1) rk_text = "Do not kill enemies or gain EXP.";
if (global.rk_language == 1) {
 rk_text = "EXP 획득을 피하세요.";
 if (global.rk_spoilers == 1) rk_text = "적을 죽이거나 EXP를 얻지 마세요.";
}
return rk_text;
}
if ((global.rk_kills_total >= 0 && global.rk_kills_total <= 2147483647) && !(global.rk_kills_total == 0)) {
global.rk_objective_id = "kills_total";
rk_text = "Keep everyone safe.";
if (global.rk_spoilers == 1) rk_text = "Do not kill any monsters; the letter event checks the kill count separately from EXP.";
if (global.rk_language == 1) {
 rk_text = "모두를 지켜 주세요.";
 if (global.rk_spoilers == 1) rk_text = "아무 몬스터도 죽이지 마세요. 편지 이벤트는 EXP와 별도로 처치 수를 확인합니다.";
}
return rk_text;
}
if ((global.rk_papyrus_alive >= 0 && global.rk_papyrus_alive <= 1) && !(global.rk_papyrus_alive == 1)) {
global.rk_objective_id = "papyrus_alive";
rk_text = "Keep your new friends safe.";
if (global.rk_spoilers == 1) rk_text = "Spare Papyrus.";
if (global.rk_language == 1) {
 rk_text = "새 친구들을 지켜 주세요.";
 if (global.rk_spoilers == 1) rk_text = "파피루스를 살려 주세요.";
}
return rk_text;
}
if ((global.rk_undyne_alive >= 0 && global.rk_undyne_alive <= 1) && !(global.rk_undyne_alive == 1)) {
global.rk_objective_id = "undyne_alive";
rk_text = "Keep your new friends safe.";
if (global.rk_spoilers == 1) rk_text = "Spare Undyne.";
if (global.rk_language == 1) {
 rk_text = "새 친구들을 지켜 주세요.";
 if (global.rk_spoilers == 1) rk_text = "언다인을 살려 주세요.";
}
return rk_text;
}
if ((global.rk_water_opportunity_missed >= 0 && global.rk_water_opportunity_missed <= 1) && !(global.rk_water_opportunity_missed == 0)) {
global.rk_objective_id = "water_opportunity_missed";
rk_text = "Help anyone who needs immediate aid.";
if (global.rk_spoilers == 1) rk_text = "Give Undyne water when she collapses in Hotland.";
if (global.rk_language == 1) {
 rk_text = "즉시 도움이 필요한 상대를 도와주세요.";
 if (global.rk_spoilers == 1) rk_text = "핫랜드에서 쓰러진 언다인에게 물을 주세요.";
}
return rk_text;
}
if ((global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1) && !(global.rk_epilogue_matches == 1) && (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1) && global.rk_epilogue_resolved >= 1) {
global.rk_objective_id = "epilogue_matches";
rk_text = "The final choice differs from your selected outcome.";
if (global.rk_spoilers == 1) rk_text = "Keep the selected Stay or Leave epilogue choice; existing SOUL history determines its normal or altered form.";
if (global.rk_language == 1) {
 rk_text = "마지막 선택이 목표한 결과와 다릅니다.";
 if (global.rk_spoilers == 1) rk_text = "함께 살기 또는 떠나기 선택을 지켜 주세요. 기존 영혼 기록에 따라 일반 또는 변형 결말이 됩니다.";
}
return rk_text;
}
if ((global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1) && !(global.rk_soul_sold == 1)) {
global.rk_objective_id = "soul_sold";
rk_text = "Existing permanent history does not match this ending.";
if (global.rk_spoilers == 1) rk_text = "This outcome requires the selected existing sold-soul history. ROUTEKEEPER never creates or deletes permanent history.";
if (global.rk_language == 1) {
 rk_text = "기존 영구 기록이 이 엔딩과 맞지 않습니다.";
 if (global.rk_spoilers == 1) rk_text = "이 결과에는 선택한 영혼 판매 기록이 필요합니다. ROUTEKEEPER는 영구 기록을 만들거나 지우지 않습니다.";
}
return rk_text;
}
if ((global.rk_water_opportunity_active >= 0 && global.rk_water_opportunity_active <= 1 && global.rk_water_opportunity_active == 1)) {
global.rk_objective_id = "water_opportunity_missed";
rk_text = "Help the collapsed person before leaving.";
if (global.rk_spoilers == 1) rk_text = "Take water from the cooler and give it to Undyne before leaving.";
if (global.rk_language == 1) {
 rk_text = "떠나기 전에 쓰러진 상대를 도와주세요.";
 if (global.rk_spoilers == 1) rk_text = "떠나기 전에 정수기의 물을 언다인에게 주세요.";
}
return rk_text;
}
if ((global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 0) && (global.rk_papyrus_hangout_available >= 0 && global.rk_papyrus_hangout_available <= 1 && global.rk_papyrus_hangout_available == 1)) {
global.rk_objective_id = "papyrus_friendship";
rk_text = "Visit your new friend's home.";
if (global.rk_spoilers == 1) rk_text = "Go to Papyrus's house and finish his date or hangout.";
if (global.rk_language == 1) {
 rk_text = "새 친구의 집을 방문하세요.";
 if (global.rk_spoilers == 1) rk_text = "파피루스의 집에서 데이트 또는 어울리기를 마치세요.";
}
return rk_text;
}
if ((global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 0) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_hangout_available >= 0 && global.rk_undyne_hangout_available <= 1 && global.rk_undyne_hangout_available == 1)) {
global.rk_objective_id = "undyne_friendship";
rk_text = "Meet your friends at their home.";
if (global.rk_spoilers == 1) rk_text = "Meet Papyrus outside Undyne's house and finish her hangout.";
if (global.rk_language == 1) {
 rk_text = "친구의 집에서 함께 시간을 보내세요.";
 if (global.rk_spoilers == 1) rk_text = "언다인의 집 앞에서 파피루스를 만나 어울리기를 마치세요.";
}
return rk_text;
}
if ((global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 0) && (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1 && global.rk_mettaton_defeated == 1)) {
global.rk_objective_id = "prior_neutral_completion";
rk_text = "Finish the journey, then continue from your SAVE.";
if (global.rk_spoilers == 1) rk_text = "Defeat Asgore and Omega Flowey, then reload your SAVE.";
if (global.rk_language == 1) {
 rk_text = "여정을 마친 뒤 SAVE에서 계속하세요.";
 if (global.rk_spoilers == 1) rk_text = "아스고어와 오메가 플라위를 물리친 뒤 SAVE를 불러오세요.";
}
return rk_text;
}
if ((global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 0) && (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_date_available >= 0 && global.rk_alphys_date_available <= 1 && global.rk_alphys_date_available == 1)) {
global.rk_objective_id = "alphys_friendship";
rk_text = "Deliver your friend's message.";
if (global.rk_spoilers == 1) rk_text = "Get Undyne's letter, deliver it to Alphys, and finish the date.";
if (global.rk_language == 1) {
 rk_text = "친구의 편지를 전해 주세요.";
 if (global.rk_spoilers == 1) rk_text = "언다인의 편지를 알피스에게 전하고 데이트를 마치세요.";
}
return rk_text;
}
if ((global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) && (global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 0) && (global.rk_true_lab_available >= 0 && global.rk_true_lab_available <= 1 && global.rk_true_lab_available == 1)) {
global.rk_objective_id = "true_lab_completed";
rk_text = "Explore the path your friends opened.";
if (global.rk_spoilers == 1) rk_text = "Enter the bathroom in Alphys's lab and complete the True Lab.";
if (global.rk_language == 1) {
 rk_text = "친구들이 열어 준 길을 탐험하세요.";
 if (global.rk_spoilers == 1) rk_text = "알피스의 연구실 화장실로 들어가 진실의 연구소를 완료하세요.";
}
return rk_text;
}
if ((global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) && (global.rk_epilogue_resolved >= 0 && global.rk_epilogue_resolved <= 1 && global.rk_epilogue_resolved == 1) && (global.rk_epilogue_matches >= 0 && global.rk_epilogue_matches <= 1 && global.rk_epilogue_matches == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1)) {
global.rk_objective_id = "ending_complete";
rk_text = "Your selected path is complete. Permanent history remains unchanged by the mod.";
if (global.rk_spoilers == 1) rk_text = "The observed barrier and epilogue outcomes match your selected route.";
if (global.rk_language == 1) {
 rk_text = "선택한 경로를 마쳤습니다. 모드는 영구 기록을 바꾸지 않았습니다.";
 if (global.rk_spoilers == 1) rk_text = "확인된 결계와 마지막 선택이 목표 경로와 맞습니다.";
}
return rk_text;
}
if ((global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 1) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1)) {
global.rk_objective_id = "epilogue";
rk_text = "Finish your farewells and choose your future.";
if (global.rk_spoilers == 1) rk_text = "Speak with your friends, leave the Underground, then keep your selected Stay/Leave choice.";
if (global.rk_language == 1) {
 rk_text = "친구들에게 인사하고 앞날을 선택하세요.";
 if (global.rk_spoilers == 1) rk_text = "친구들과 이야기한 뒤 지하를 떠나 함께 살기 또는 떠나기 선택을 지키세요.";
}
return rk_text;
}
if ((global.rk_true_lab_completed >= 0 && global.rk_true_lab_completed <= 1 && global.rk_true_lab_completed == 1) && (global.rk_barrier_broken >= 0 && global.rk_barrier_broken <= 1 && global.rk_barrier_broken == 0) && (global.rk_papyrus_friendship >= 0 && global.rk_papyrus_friendship <= 1 && global.rk_papyrus_friendship == 1) && (global.rk_undyne_friendship >= 0 && global.rk_undyne_friendship <= 1 && global.rk_undyne_friendship == 1) && (global.rk_alphys_friendship >= 0 && global.rk_alphys_friendship <= 1 && global.rk_alphys_friendship == 1) && (global.rk_prior_neutral_completion >= 0 && global.rk_prior_neutral_completion <= 1 && global.rk_prior_neutral_completion == 1)) {
global.rk_objective_id = "barrier";
rk_text = "Return to the barrier and help your friends.";
if (global.rk_spoilers == 1) rk_text = "Return to the barrier and complete the Asriel encounter without RESET.";
if (global.rk_language == 1) {
 rk_text = "결계로 돌아가 친구들을 도와주세요.";
 if (global.rk_spoilers == 1) rk_text = "결계로 돌아가 리셋하지 않고 아스리엘 조우를 완료하세요.";
}
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 0)) {
global.rk_objective_id = "travel_ruins";
rk_text = "Explore the Ruins without gaining EXP.";
if (global.rk_spoilers == 1) rk_text = "Spare Toriel and continue out of the Ruins without gaining EXP.";
if (global.rk_language == 1) {
 rk_text = "EXP를 얻지 않고 폐허를 탐험하세요.";
 if (global.rk_spoilers == 1) rk_text = "토리엘을 살리고 EXP를 얻지 않은 채 폐허를 나가세요.";
}
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 1)) {
global.rk_objective_id = "travel_snowdin";
rk_text = "Continue through the forest and make a friend.";
if (global.rk_spoilers == 1) rk_text = "Spare Papyrus, then visit his house for a date or hangout.";
if (global.rk_language == 1) {
 rk_text = "숲을 지나며 새 친구를 만드세요.";
 if (global.rk_spoilers == 1) rk_text = "파피루스를 살린 뒤 집을 방문해 데이트 또는 어울리기를 하세요.";
}
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area == 2)) {
global.rk_objective_id = "travel_waterfall";
rk_text = "Continue through the caverns and help those in need.";
if (global.rk_spoilers == 1) rk_text = "Flee from Undyne to Hotland, then give her water when she collapses.";
if (global.rk_language == 1) {
 rk_text = "동굴을 지나며 도움이 필요한 상대를 도와주세요.";
 if (global.rk_spoilers == 1) rk_text = "언다인에게서 핫랜드까지 도망친 뒤 쓰러진 언다인에게 물을 주세요.";
}
return rk_text;
}
if ((global.rk_area >= 0 && global.rk_area <= 4 && global.rk_area >= 3)) {
global.rk_objective_id = "travel_hotland";
rk_text = "Continue toward the castle without gaining EXP.";
if (global.rk_spoilers == 1) rk_text = "Spare Mettaton EX and continue toward Asgore without gaining EXP.";
if (global.rk_language == 1) {
 rk_text = "EXP를 얻지 않고 성을 향해 계속 가세요.";
 if (global.rk_spoilers == 1) rk_text = "메타톤 EX를 살리고 EXP를 얻지 않은 채 아스고어에게 가세요.";
}
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
rk_text = "The world is erased. Permanent-history decisions remain yours.";
if (global.rk_spoilers == 1) rk_text = "The game world must already be restored. ROUTEKEEPER never sells your SOUL or rewrites system_information files.";
if (global.rk_language == 1) {
 rk_text = "세계가 지워졌습니다. 영구 기록에 관한 결정은 직접 해야 합니다.";
 if (global.rk_spoilers == 1) rk_text = "세계가 복원되어 있어야 합니다. ROUTEKEEPER는 영혼을 팔거나 영구 기록 파일을 고치지 않습니다.";
}
return rk_text;
}
if ((global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1) && !(global.rk_hard_mode == 0)) {
global.rk_objective_id = "hard_mode";
rk_text = "This challenge cannot reach the selected ending.";
if (global.rk_spoilers == 1) rk_text = "Hard Mode cannot reach a Genocide ending.";
if (global.rk_language == 1) {
 rk_text = "이 도전에서는 선택한 엔딩에 도달할 수 없습니다.";
 if (global.rk_spoilers == 1) rk_text = "하드 모드에서는 몰살 엔딩에 도달할 수 없습니다.";
}
return rk_text;
}
if ((global.rk_genocide_aborted >= 0 && global.rk_genocide_aborted <= 1) && !(global.rk_genocide_aborted == 0)) {
global.rk_objective_id = "genocide_aborted";
rk_text = "A required encounter was missed.";
if (global.rk_spoilers == 1) rk_text = "A required enemy was spared or another Genocide abandonment flag was set.";
if (global.rk_language == 1) {
 rk_text = "필수 조우를 놓쳤습니다.";
 if (global.rk_spoilers == 1) rk_text = "필수 적을 살렸거나 몰살 중단 플래그가 설정되었습니다.";
}
return rk_text;
}
if ((global.rk_snowdrake_lost >= 0 && global.rk_snowdrake_lost <= 1) && !(global.rk_snowdrake_lost == 0)) {
global.rk_objective_id = "snowdrake_lost";
rk_text = "A required enemy can no longer be found.";
if (global.rk_spoilers == 1) rk_text = "Snowdrake must be killed before no further encounters or live Snowdrake remain.";
if (global.rk_language == 1) {
 rk_text = "필수 적을 더는 찾을 수 없습니다.";
 if (global.rk_spoilers == 1) rk_text = "새 조우나 살아 있는 스노우드레이크가 남아 있을 때 처치해야 합니다.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 2) && (global.rk_toriel_resolved >= 0 && global.rk_toriel_resolved <= 1) && global.rk_toriel_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = "The first region's requirements were missed.";
if (global.rk_spoilers == 1) rk_text = "Complete the Ruins kill quota and kill Toriel before leaving the Ruins.";
if (global.rk_language == 1) {
 rk_text = "첫 지역의 조건을 놓쳤습니다.";
 if (global.rk_spoilers == 1) rk_text = "폐허를 떠나기 전에 지역 처치 수를 채우고 토리엘을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 8) && (global.rk_papyrus_resolved >= 0 && global.rk_papyrus_resolved <= 1) && global.rk_papyrus_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = "The forest's requirements were missed.";
if (global.rk_spoilers == 1) rk_text = "Complete Snowdin's quota and unique encounters before killing Papyrus.";
if (global.rk_language == 1) {
 rk_text = "숲 지역의 조건을 놓쳤습니다.";
 if (global.rk_spoilers == 1) rk_text = "파피루스를 처치하기 전에 스노우딘의 처치 수와 필수 조우를 완료하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 12) && (global.rk_undyne_resolved >= 0 && global.rk_undyne_resolved <= 1) && global.rk_undyne_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = "The cavern's requirements were missed.";
if (global.rk_spoilers == 1) rk_text = "Complete Waterfall's quota, Shyren and Glad Dummy, then defeat Undyne the Undying.";
if (global.rk_language == 1) {
 rk_text = "동굴 지역의 조건을 놓쳤습니다.";
 if (global.rk_spoilers == 1) rk_text = "워터폴의 처치 수와 샤이렌, 글래드 더미를 완료한 뒤 불사의 언다인을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 16) && (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1) && global.rk_mettaton_defeated >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = "The final region's requirements were missed.";
if (global.rk_spoilers == 1) rk_text = "Complete Hotland/CORE's quota and required encounters before defeating Mettaton NEO.";
if (global.rk_language == 1) {
 rk_text = "마지막 지역의 조건을 놓쳤습니다.";
 if (global.rk_spoilers == 1) rk_text = "메타톤 NEO를 처치하기 전에 핫랜드와 코어의 처치 수와 필수 조우를 완료하세요.";
}
return rk_text;
}
if ((global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1) && !(global.rk_soul_sold == 0)) {
global.rk_objective_id = "soul_sold";
rk_text = "Existing permanent history does not match this ending.";
if (global.rk_spoilers == 1) rk_text = "This outcome requires the selected existing sold-soul history. ROUTEKEEPER never creates or deletes permanent history.";
if (global.rk_language == 1) {
 rk_text = "기존 영구 기록이 이 엔딩과 맞지 않습니다.";
 if (global.rk_spoilers == 1) rk_text = "이 결과에는 선택한 영혼 판매 기록이 필요합니다. ROUTEKEEPER는 영구 기록을 만들거나 지우지 않습니다.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 0) && (global.rk_kills_ruins >= 0 && global.rk_kills_ruins <= 2147483647 && global.rk_kills_ruins <= 19)) {
global.rk_objective_id = "quota_ruins";
rk_text = "Defeat " + string(max(0, 20 - global.rk_kills_ruins)) + " more enemies before moving on.";
if (global.rk_spoilers == 1) rk_text = "Defeat " + string(max(0, 20 - global.rk_kills_ruins)) + " more enemies in the Ruins before leaving.";
if (global.rk_language == 1) {
 rk_text = "다음으로 가기 전에 적 " + string(max(0, 20 - global.rk_kills_ruins)) + "명을 더 처치하세요.";
 if (global.rk_spoilers == 1) rk_text = "폐허를 떠나기 전에 적 " + string(max(0, 20 - global.rk_kills_ruins)) + "명을 더 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 1)) {
global.rk_objective_id = "toriel";
rk_text = "Complete the region's final encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Toriel, then enter Snowdin.";
if (global.rk_language == 1) {
 rk_text = "지역의 마지막 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "토리엘을 처치한 뒤 스노우딘으로 가세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 2)) {
global.rk_objective_id = "doggo";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Doggo; do not spare required enemies.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "도고를 처치하세요. 필수 적을 살려 주지 마세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 3)) {
global.rk_objective_id = "dog_pair";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Dogamy and Dogaressa.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "도가미와 도가레사를 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 4)) {
global.rk_objective_id = "greater_dog";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Greater Dog; kill Lesser Dog if encountered.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "그레이터 도그를 처치하세요. 레서 도그와 조우했다면 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 5)) {
global.rk_objective_id = "snowdrake";
rk_text = "Find the missing required enemy before exhausting the area.";
if (global.rk_spoilers == 1) rk_text = "Kill Snowdrake before the Snowdin encounter quota is exhausted.";
if (global.rk_language == 1) {
 rk_text = "지역의 적이 사라지기 전에 필수 적을 찾으세요.";
 if (global.rk_spoilers == 1) rk_text = "스노우딘 조우 수가 소진되기 전에 스노우드레이크를 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 6) && (global.rk_kills_snowdin >= 0 && global.rk_kills_snowdin <= 2147483647 && global.rk_kills_snowdin <= 15)) {
global.rk_objective_id = "quota_snowdin";
rk_text = "Defeat " + string(max(0, 16 - global.rk_kills_snowdin)) + " more enemies before moving on.";
if (global.rk_spoilers == 1) rk_text = "Defeat " + string(max(0, 16 - global.rk_kills_snowdin)) + " more enemies in Snowdin before Papyrus.";
if (global.rk_language == 1) {
 rk_text = "다음으로 가기 전에 적 " + string(max(0, 16 - global.rk_kills_snowdin)) + "명을 더 처치하세요.";
 if (global.rk_spoilers == 1) rk_text = "파피루스를 만나기 전에 스노우딘의 적 " + string(max(0, 16 - global.rk_kills_snowdin)) + "명을 더 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 7)) {
global.rk_objective_id = "papyrus";
rk_text = "Complete the region's final encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Papyrus after completing the Snowdin quota.";
if (global.rk_language == 1) {
 rk_text = "지역의 마지막 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "스노우딘의 처치 수를 채운 뒤 파피루스를 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 8)) {
global.rk_objective_id = "shyren";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Shyren.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "샤이렌을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 9)) {
global.rk_objective_id = "glad_dummy";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Glad Dummy.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "글래드 더미를 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 10) && (global.rk_kills_waterfall >= 0 && global.rk_kills_waterfall <= 2147483647 && global.rk_kills_waterfall <= 17)) {
global.rk_objective_id = "quota_waterfall";
rk_text = "Defeat " + string(max(0, 18 - global.rk_kills_waterfall)) + " more enemies before moving on.";
if (global.rk_spoilers == 1) rk_text = "Defeat " + string(max(0, 18 - global.rk_kills_waterfall)) + " more enemies in Waterfall before Undyne.";
if (global.rk_language == 1) {
 rk_text = "다음으로 가기 전에 적 " + string(max(0, 18 - global.rk_kills_waterfall)) + "명을 더 처치하세요.";
 if (global.rk_spoilers == 1) rk_text = "언다인을 만나기 전에 워터폴의 적 " + string(max(0, 18 - global.rk_kills_waterfall)) + "명을 더 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 11)) {
global.rk_objective_id = "undyne";
rk_text = "Complete the region's decisive encounter.";
if (global.rk_spoilers == 1) rk_text = "Attack Monster Kid, then defeat Undyne the Undying.";
if (global.rk_language == 1) {
 rk_text = "지역의 결정적인 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "몬스터 키드를 공격한 뒤 불사의 언다인을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 12)) {
global.rk_objective_id = "royal_guards";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill the Royal Guards.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "왕실 근위병을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 13)) {
global.rk_objective_id = "muffet";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Muffet.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "머펫을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 14) && (global.rk_kills_hotland_core >= 0 && global.rk_kills_hotland_core <= 2147483647 && global.rk_kills_hotland_core <= 39)) {
global.rk_objective_id = "quota_hotland_core";
rk_text = "Defeat " + string(max(0, 40 - global.rk_kills_hotland_core)) + " more enemies before moving on.";
if (global.rk_spoilers == 1) rk_text = "Defeat " + string(max(0, 40 - global.rk_kills_hotland_core)) + " more enemies in Hotland/CORE before Mettaton NEO.";
if (global.rk_language == 1) {
 rk_text = "다음으로 가기 전에 적 " + string(max(0, 40 - global.rk_kills_hotland_core)) + "명을 더 처치하세요.";
 if (global.rk_spoilers == 1) rk_text = "메타톤 NEO를 만나기 전에 핫랜드와 코어의 적 " + string(max(0, 40 - global.rk_kills_hotland_core)) + "명을 더 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 15)) {
global.rk_objective_id = "mettaton_neo";
rk_text = "Complete the region's final encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Mettaton NEO after exhausting the Hotland/CORE quota.";
if (global.rk_language == 1) {
 rk_text = "지역의 마지막 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "핫랜드와 코어의 처치 수를 채운 뒤 메타톤 NEO를 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 16) && (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 0)) {
global.rk_objective_id = "genocide_final";
rk_text = "Continue to the final encounter. Permanent history will not be changed by the mod.";
if (global.rk_spoilers == 1) rk_text = "Defeat Sans and continue. Any permanent-history decision remains yours.";
if (global.rk_language == 1) {
 rk_text = "마지막 조우로 가세요. 모드는 영구 기록을 바꾸지 않습니다.";
 if (global.rk_spoilers == 1) rk_text = "샌즈를 물리치고 계속하세요. 영구 기록에 관한 결정은 직접 해야 합니다.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 16) && (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 1)) {
global.rk_objective_id = "genocide_throne";
rk_text = "Continue to the throne room. The final permanent-history decision remains yours.";
if (global.rk_spoilers == 1) rk_text = "Sans is defeated. Continue through the throne room and make the final choice yourself.";
if (global.rk_language == 1) {
 rk_text = "왕좌의 방으로 계속 가세요. 영구 기록에 관한 마지막 결정은 직접 하세요.";
 if (global.rk_spoilers == 1) rk_text = "샌즈를 물리쳤습니다. 왕좌의 방을 지나 마지막 선택을 직접 하세요.";
}
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
rk_text = "The world is erased. Permanent-history decisions remain yours.";
if (global.rk_spoilers == 1) rk_text = "The game world must already be restored. ROUTEKEEPER never sells your SOUL or rewrites system_information files.";
if (global.rk_language == 1) {
 rk_text = "세계가 지워졌습니다. 영구 기록에 관한 결정은 직접 해야 합니다.";
 if (global.rk_spoilers == 1) rk_text = "세계가 복원되어 있어야 합니다. ROUTEKEEPER는 영혼을 팔거나 영구 기록 파일을 고치지 않습니다.";
}
return rk_text;
}
if ((global.rk_hard_mode >= 0 && global.rk_hard_mode <= 1) && !(global.rk_hard_mode == 0)) {
global.rk_objective_id = "hard_mode";
rk_text = "This challenge cannot reach the selected ending.";
if (global.rk_spoilers == 1) rk_text = "Hard Mode cannot reach a Genocide ending.";
if (global.rk_language == 1) {
 rk_text = "이 도전에서는 선택한 엔딩에 도달할 수 없습니다.";
 if (global.rk_spoilers == 1) rk_text = "하드 모드에서는 몰살 엔딩에 도달할 수 없습니다.";
}
return rk_text;
}
if ((global.rk_genocide_aborted >= 0 && global.rk_genocide_aborted <= 1) && !(global.rk_genocide_aborted == 0)) {
global.rk_objective_id = "genocide_aborted";
rk_text = "A required encounter was missed.";
if (global.rk_spoilers == 1) rk_text = "A required enemy was spared or another Genocide abandonment flag was set.";
if (global.rk_language == 1) {
 rk_text = "필수 조우를 놓쳤습니다.";
 if (global.rk_spoilers == 1) rk_text = "필수 적을 살렸거나 몰살 중단 플래그가 설정되었습니다.";
}
return rk_text;
}
if ((global.rk_snowdrake_lost >= 0 && global.rk_snowdrake_lost <= 1) && !(global.rk_snowdrake_lost == 0)) {
global.rk_objective_id = "snowdrake_lost";
rk_text = "A required enemy can no longer be found.";
if (global.rk_spoilers == 1) rk_text = "Snowdrake must be killed before no further encounters or live Snowdrake remain.";
if (global.rk_language == 1) {
 rk_text = "필수 적을 더는 찾을 수 없습니다.";
 if (global.rk_spoilers == 1) rk_text = "새 조우나 살아 있는 스노우드레이크가 남아 있을 때 처치해야 합니다.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 2) && (global.rk_toriel_resolved >= 0 && global.rk_toriel_resolved <= 1) && global.rk_toriel_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = "The first region's requirements were missed.";
if (global.rk_spoilers == 1) rk_text = "Complete the Ruins kill quota and kill Toriel before leaving the Ruins.";
if (global.rk_language == 1) {
 rk_text = "첫 지역의 조건을 놓쳤습니다.";
 if (global.rk_spoilers == 1) rk_text = "폐허를 떠나기 전에 지역 처치 수를 채우고 토리엘을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 8) && (global.rk_papyrus_resolved >= 0 && global.rk_papyrus_resolved <= 1) && global.rk_papyrus_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = "The forest's requirements were missed.";
if (global.rk_spoilers == 1) rk_text = "Complete Snowdin's quota and unique encounters before killing Papyrus.";
if (global.rk_language == 1) {
 rk_text = "숲 지역의 조건을 놓쳤습니다.";
 if (global.rk_spoilers == 1) rk_text = "파피루스를 처치하기 전에 스노우딘의 처치 수와 필수 조우를 완료하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 12) && (global.rk_undyne_resolved >= 0 && global.rk_undyne_resolved <= 1) && global.rk_undyne_resolved >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = "The cavern's requirements were missed.";
if (global.rk_spoilers == 1) rk_text = "Complete Waterfall's quota, Shyren and Glad Dummy, then defeat Undyne the Undying.";
if (global.rk_language == 1) {
 rk_text = "동굴 지역의 조건을 놓쳤습니다.";
 if (global.rk_spoilers == 1) rk_text = "워터폴의 처치 수와 샤이렌, 글래드 더미를 완료한 뒤 불사의 언다인을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16) && !(global.rk_genocide_stage >= 16) && (global.rk_mettaton_defeated >= 0 && global.rk_mettaton_defeated <= 1) && global.rk_mettaton_defeated >= 1) {
global.rk_objective_id = "genocide_stage";
rk_text = "The final region's requirements were missed.";
if (global.rk_spoilers == 1) rk_text = "Complete Hotland/CORE's quota and required encounters before defeating Mettaton NEO.";
if (global.rk_language == 1) {
 rk_text = "마지막 지역의 조건을 놓쳤습니다.";
 if (global.rk_spoilers == 1) rk_text = "메타톤 NEO를 처치하기 전에 핫랜드와 코어의 처치 수와 필수 조우를 완료하세요.";
}
return rk_text;
}
if ((global.rk_soul_sold >= 0 && global.rk_soul_sold <= 1) && !(global.rk_soul_sold == 1)) {
global.rk_objective_id = "soul_sold";
rk_text = "Existing permanent history does not match this ending.";
if (global.rk_spoilers == 1) rk_text = "This outcome requires the selected existing sold-soul history. ROUTEKEEPER never creates or deletes permanent history.";
if (global.rk_language == 1) {
 rk_text = "기존 영구 기록이 이 엔딩과 맞지 않습니다.";
 if (global.rk_spoilers == 1) rk_text = "이 결과에는 선택한 영혼 판매 기록이 필요합니다. ROUTEKEEPER는 영구 기록을 만들거나 지우지 않습니다.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 0) && (global.rk_kills_ruins >= 0 && global.rk_kills_ruins <= 2147483647 && global.rk_kills_ruins <= 19)) {
global.rk_objective_id = "quota_ruins";
rk_text = "Defeat " + string(max(0, 20 - global.rk_kills_ruins)) + " more enemies before moving on.";
if (global.rk_spoilers == 1) rk_text = "Defeat " + string(max(0, 20 - global.rk_kills_ruins)) + " more enemies in the Ruins before leaving.";
if (global.rk_language == 1) {
 rk_text = "다음으로 가기 전에 적 " + string(max(0, 20 - global.rk_kills_ruins)) + "명을 더 처치하세요.";
 if (global.rk_spoilers == 1) rk_text = "폐허를 떠나기 전에 적 " + string(max(0, 20 - global.rk_kills_ruins)) + "명을 더 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 1)) {
global.rk_objective_id = "toriel";
rk_text = "Complete the region's final encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Toriel, then enter Snowdin.";
if (global.rk_language == 1) {
 rk_text = "지역의 마지막 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "토리엘을 처치한 뒤 스노우딘으로 가세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 2)) {
global.rk_objective_id = "doggo";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Doggo; do not spare required enemies.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "도고를 처치하세요. 필수 적을 살려 주지 마세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 3)) {
global.rk_objective_id = "dog_pair";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Dogamy and Dogaressa.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "도가미와 도가레사를 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 4)) {
global.rk_objective_id = "greater_dog";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Greater Dog; kill Lesser Dog if encountered.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "그레이터 도그를 처치하세요. 레서 도그와 조우했다면 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 5)) {
global.rk_objective_id = "snowdrake";
rk_text = "Find the missing required enemy before exhausting the area.";
if (global.rk_spoilers == 1) rk_text = "Kill Snowdrake before the Snowdin encounter quota is exhausted.";
if (global.rk_language == 1) {
 rk_text = "지역의 적이 사라지기 전에 필수 적을 찾으세요.";
 if (global.rk_spoilers == 1) rk_text = "스노우딘 조우 수가 소진되기 전에 스노우드레이크를 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 6) && (global.rk_kills_snowdin >= 0 && global.rk_kills_snowdin <= 2147483647 && global.rk_kills_snowdin <= 15)) {
global.rk_objective_id = "quota_snowdin";
rk_text = "Defeat " + string(max(0, 16 - global.rk_kills_snowdin)) + " more enemies before moving on.";
if (global.rk_spoilers == 1) rk_text = "Defeat " + string(max(0, 16 - global.rk_kills_snowdin)) + " more enemies in Snowdin before Papyrus.";
if (global.rk_language == 1) {
 rk_text = "다음으로 가기 전에 적 " + string(max(0, 16 - global.rk_kills_snowdin)) + "명을 더 처치하세요.";
 if (global.rk_spoilers == 1) rk_text = "파피루스를 만나기 전에 스노우딘의 적 " + string(max(0, 16 - global.rk_kills_snowdin)) + "명을 더 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 7)) {
global.rk_objective_id = "papyrus";
rk_text = "Complete the region's final encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Papyrus after completing the Snowdin quota.";
if (global.rk_language == 1) {
 rk_text = "지역의 마지막 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "스노우딘의 처치 수를 채운 뒤 파피루스를 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 8)) {
global.rk_objective_id = "shyren";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Shyren.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "샤이렌을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 9)) {
global.rk_objective_id = "glad_dummy";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Glad Dummy.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "글래드 더미를 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 10) && (global.rk_kills_waterfall >= 0 && global.rk_kills_waterfall <= 2147483647 && global.rk_kills_waterfall <= 17)) {
global.rk_objective_id = "quota_waterfall";
rk_text = "Defeat " + string(max(0, 18 - global.rk_kills_waterfall)) + " more enemies before moving on.";
if (global.rk_spoilers == 1) rk_text = "Defeat " + string(max(0, 18 - global.rk_kills_waterfall)) + " more enemies in Waterfall before Undyne.";
if (global.rk_language == 1) {
 rk_text = "다음으로 가기 전에 적 " + string(max(0, 18 - global.rk_kills_waterfall)) + "명을 더 처치하세요.";
 if (global.rk_spoilers == 1) rk_text = "언다인을 만나기 전에 워터폴의 적 " + string(max(0, 18 - global.rk_kills_waterfall)) + "명을 더 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 11)) {
global.rk_objective_id = "undyne";
rk_text = "Complete the region's decisive encounter.";
if (global.rk_spoilers == 1) rk_text = "Attack Monster Kid, then defeat Undyne the Undying.";
if (global.rk_language == 1) {
 rk_text = "지역의 결정적인 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "몬스터 키드를 공격한 뒤 불사의 언다인을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 12)) {
global.rk_objective_id = "royal_guards";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill the Royal Guards.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "왕실 근위병을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 13)) {
global.rk_objective_id = "muffet";
rk_text = "Complete the next required encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Muffet.";
if (global.rk_language == 1) {
 rk_text = "다음 필수 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "머펫을 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 14) && (global.rk_kills_hotland_core >= 0 && global.rk_kills_hotland_core <= 2147483647 && global.rk_kills_hotland_core <= 39)) {
global.rk_objective_id = "quota_hotland_core";
rk_text = "Defeat " + string(max(0, 40 - global.rk_kills_hotland_core)) + " more enemies before moving on.";
if (global.rk_spoilers == 1) rk_text = "Defeat " + string(max(0, 40 - global.rk_kills_hotland_core)) + " more enemies in Hotland/CORE before Mettaton NEO.";
if (global.rk_language == 1) {
 rk_text = "다음으로 가기 전에 적 " + string(max(0, 40 - global.rk_kills_hotland_core)) + "명을 더 처치하세요.";
 if (global.rk_spoilers == 1) rk_text = "메타톤 NEO를 만나기 전에 핫랜드와 코어의 적 " + string(max(0, 40 - global.rk_kills_hotland_core)) + "명을 더 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 15)) {
global.rk_objective_id = "mettaton_neo";
rk_text = "Complete the region's final encounter.";
if (global.rk_spoilers == 1) rk_text = "Kill Mettaton NEO after exhausting the Hotland/CORE quota.";
if (global.rk_language == 1) {
 rk_text = "지역의 마지막 조우를 완료하세요.";
 if (global.rk_spoilers == 1) rk_text = "핫랜드와 코어의 처치 수를 채운 뒤 메타톤 NEO를 처치하세요.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 16) && (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 0)) {
global.rk_objective_id = "genocide_final";
rk_text = "Continue to the final encounter. Permanent history will not be changed by the mod.";
if (global.rk_spoilers == 1) rk_text = "Defeat Sans and continue. Any permanent-history decision remains yours.";
if (global.rk_language == 1) {
 rk_text = "마지막 조우로 가세요. 모드는 영구 기록을 바꾸지 않습니다.";
 if (global.rk_spoilers == 1) rk_text = "샌즈를 물리치고 계속하세요. 영구 기록에 관한 결정은 직접 해야 합니다.";
}
return rk_text;
}
if ((global.rk_genocide_stage >= 0 && global.rk_genocide_stage <= 16 && global.rk_genocide_stage == 16) && (global.rk_sans_defeated >= 0 && global.rk_sans_defeated <= 1 && global.rk_sans_defeated == 1)) {
global.rk_objective_id = "genocide_throne";
rk_text = "Continue to the throne room. The final permanent-history decision remains yours.";
if (global.rk_spoilers == 1) rk_text = "Sans is defeated. Continue through the throne room and make the final choice yourself.";
if (global.rk_language == 1) {
 rk_text = "왕좌의 방으로 계속 가세요. 영구 기록에 관한 마지막 결정은 직접 하세요.";
 if (global.rk_spoilers == 1) rk_text = "샌즈를 물리쳤습니다. 왕좌의 방을 지나 마지막 선택을 직접 하세요.";
}
return rk_text;
}
}
return rk_text;
