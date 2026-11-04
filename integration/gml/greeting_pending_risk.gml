// Verified state-to-policy adapter: action,item,current EXP reward,enemy kind.
if (global.rk_target_route != 3) return 0;
var action, item, healing, armor_change, copies, slot, level_risk, xp_risk;
action = argument0; item = argument1;
healing = 0; armor_change = 0; copies = 0; level_risk = 0; xp_risk = 0;
if (action == 8) {
    healing = scr_routekeeper_greeting_healing(item);
    armor_change = (global.armor == 4 && scr_routekeeper_greeting_armor(item));
}
for (slot = 0; slot < 8; slot += 1) if (global.item[slot] == 16) copies += 1;
if (action == 1) {
    xp_risk = scr_routekeeper_greeting_experience(global.xp, argument2, argument3, 0, global.xpreward[3]);
    // scr_levelup enters LV2 at XP10; boss scripts can award EXP directly.
    level_risk = scr_routekeeper_greeting_experience(global.xp, argument2, argument3, 1, global.xpreward[3]);
}
return scr_routekeeper_greeting_risk(global.rk_target_greeting,action,item,healing,armor_change,copies <= 1,level_risk,xp_risk);
