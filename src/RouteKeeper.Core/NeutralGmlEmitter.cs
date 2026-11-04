using System.Text;

namespace RouteKeeper.Core;

public static class NeutralGmlEmitter
{
    private static string Quote(string value) => "\""+value.Replace("\\","\\\\").Replace("\"","\\\"")+"\"";
    public static string EmitLabels()
    {
        var code=new StringBuilder("// Generated Neutral target labels; selectable IDs 0..18.\n");
        foreach(var target in NeutralCatalog.Targets)
            code.Append($"if (argument0 == {(int)target.Id}) return {TextCatalog.Gml(target.TextKey,"argument1")};\n");
        return code.Append("return \"\";\n").ToString();
    }
    public static string EmitProtection()
    {
        var code=new StringBuilder("// EnemyKind: Toriel1 Papyrus2 Undyne3 Mettaton4. 1 preserve, -1 kill, 0 unrestricted.\n");
        code.Append(NeutralGoals.EmitProtection().Replace("return 0;\n",""));
        foreach(var target in NeutralCatalog.Targets)
        {
            code.Append($"if (global.rk_target_neutral == {(int)target.Id}) {{\n");
            var values=new[]{target.TorielDead,target.PapyrusDead,target.UndyneDead,target.MettatonDead};
            for(int i=0;i<4;i++) if(values[i] is int expected) code.Append($"if (argument0 == {i+1}) return {(expected==0?1:-1)};\n");
            code.Append("return 0; }\n");
        }
        return code.Append("return 0;\n").ToString();
    }
    public static string EmitModifiers()
    {
        var code=new StringBuilder("// Generated optional call conditions; several may share dialogue slots.\nvar mask; mask = 0;\nif (global.rk_neutral_projection < 0) return 0;\n");
        foreach(var rule in NeutralCatalog.ModifierRules)
            code.Append($"if ({rule.Condition.Gml}) mask += {rule.Bit};\n");
        return code.Append("return mask;\n").ToString();
    }
    public static string EmitClassifier() => """
// Generated from NeutralCatalog. Projection if Neutral is reached, not proof of completion.
var t, p, u, m, k, f, stage;
t = global.rk_neutral_toriel_dead; p = global.rk_neutral_papyrus_dead;
u = global.rk_neutral_undyne_dead; m = global.rk_neutral_mettaton_dead;
k = global.rk_kills; f = global.rk_neutral_undyne_friendship; stage = global.rk_murder_level;
if (t < 0 || p < 0 || u < 0 || m < 0 || k < 0 || f < 0 || stage < 0) return -1;
if (stage >= 12 && m == 1) return 18;
if (t == 0) {
    if (p == 1 || u == 1 || k >= 10) {
        if (u == 1) { if (p == 1) return 9; return 8; }
        if (p == 1) return 7;
        return 6;
    }
    if (f > 3 && k == 0) return 1;
    if (k > 0 && f > 0) { if (m == 1) return 5; return 4; }
    if (m == 1) return 3;
    return 2;
}
if (u == 0) { if (p == 1) return 11; return 10; }
if (m == 0) { if (p == 1) return 13; return 12; }
if (p == 0) return 14;
if (k == 4) return 15;
if (k >= 20) return 17;
return 16;
""" + "\n";

    public static string EmitEvaluator()
    {
        var code=new StringBuilder("""
// Generated from NeutralCatalog target table and evaluation policy.
var nt, blocked, unknown, action, k, stage, friend, min_kills, max_kills, matched, total, reserved;
nt = global.rk_target_neutral; blocked = 0; unknown = 0; action = 0;
k = global.rk_kills; stage = global.rk_murder_level; friend = global.rk_neutral_undyne_friendship;
min_kills = 0; max_kills = -1; matched = 0; total = 0;
global.rk_neutral_friendship_min = 0;
global.rk_objective_text = "";
global.rk_neutral_keep_toriel = -1; global.rk_neutral_keep_papyrus = -1;
global.rk_neutral_keep_undyne = -1; global.rk_neutral_keep_mettaton = -1;
if (nt < 0 || nt >= 19) return 4;
"""+"\n");
        foreach(var target in NeutralCatalog.Targets)
        {
            code.Append($"if (nt == {(int)target.Id}) {{\nglobal.rk_neutral_friendship_min = {NeutralCatalog.FriendshipMinimum((int)target.Id)};\nmin_kills = {target.MinimumKills}; max_kills = {(target.MaximumKills==int.MaxValue?-1:target.MaximumKills)};\n");
            var names=new[]{"toriel","papyrus","undyne","mettaton"};
            var values=new[]{target.TorielDead,target.PapyrusDead,target.UndyneDead,target.MettatonDead};
            for(int i=0;i<names.Length;i++)
            {
                var name=names[i];
                if(values[i] is not int wanted) continue;
                code.Append($"global.rk_neutral_keep_{name} = {1-wanted};\ntotal += 1;\n");
                code.Append($"if (global.rk_neutral_{name}_dead < 0) unknown = 1;\nelse if (global.rk_neutral_{name}_dead != {wanted}) {{\n");
                code.Append($"if (global.rk_neutral_{name}_dead == 1 || global.rk_{name}_resolved == 1) blocked = 1;\nelse {{ action = 1; if (global.rk_{name}_resolved < 0) unknown = 1; }}\n}} else matched += 1;\n");
            }
            code.Append("}\n");
        }
        code.Append(NeutralGoals.EmitEvaluation(false));
        code.Append("""
if (global.rk_target_greeting == 1) { global.rk_neutral_friendship_min = 4; max_kills = 0; }
if (global.rk_target_greeting == 1 || global.rk_target_greeting == 2 || global.rk_target_greeting == 3) global.rk_neutral_keep_toriel = 1;
if (global.rk_target_greeting == 1 || global.rk_target_greeting >= 4) global.rk_neutral_keep_papyrus = 1;
if (global.rk_target_greeting >= 1 && global.rk_target_greeting <= 3) global.rk_neutral_keep_undyne = 1;
if (global.rk_target_greeting == 1 || global.rk_target_greeting == 2) global.rk_neutral_keep_mettaton = 1;
if (global.rk_target_greeting == 3) global.rk_neutral_keep_mettaton = 0;
global.rk_neutral_kill_cap = max_kills;
reserved = 0;
if (global.rk_neutral_keep_toriel == 0 && global.rk_neutral_toriel_dead == 0) reserved += 1;
if (global.rk_neutral_keep_papyrus == 0 && global.rk_neutral_papyrus_dead == 0) reserved += 1;
if (global.rk_neutral_keep_undyne == 0 && global.rk_neutral_undyne_dead == 0) reserved += 1;
if (global.rk_neutral_keep_mettaton == 0 && global.rk_neutral_mettaton_dead == 0) reserved += 1;
if (max_kills >= 0 && k >= 0 && k + reserved > max_kills) blocked = 1;
if (global.rk_hard_mode < 0 || global.rk_world_erased < 0 || global.rk_true_lab_completed < 0) unknown = 1;
if (global.rk_hard_mode == 1 || global.rk_world_erased == 1) blocked = 1;
if (stage < 0) unknown = 1;
else if (stage >= 16) blocked = 1;
if (global.rk_true_lab_completed == 1) blocked = 1;
if (k < 0) unknown = 1;
else if (max_kills >= 0 && k > max_kills) blocked = 1;
else if (k < min_kills) action = 1;
if (nt >= 1 && nt <= 5) {
    if (friend < 0) unknown = 1;
    else if (nt == 1 && friend < 4) {
        if (k > 0 || global.rk_water_opportunity_missed == 1) blocked = 1;
        else action = 1;
    }
    else if ((nt == 2 || nt == 3) && friend > 0 && k > 0) blocked = 1;
    else if ((nt == 2 || nt == 3) && friend > 3) blocked = 1;
    else if ((nt == 4 || nt == 5) && friend <= 0) {
        if (k > 0 || global.rk_water_opportunity_missed == 1) blocked = 1;
        else action = 1;
    }
}
if (nt == 18) {
    if (stage >= 0 && stage < 12) {
        if (global.rk_undyne_resolved == 1) blocked = 1;
        else action = 1;
    }
}
else if (global.rk_neutral_keep_mettaton == 0 && stage >= 12) blocked = 1;
if (global.rk_target_greeting > 0) {
    total += 1;
    if (global.rk_greeting_status == 0) matched += 1;
    if (global.rk_greeting_status == 1) action = 1;
    if (global.rk_greeting_status == 4) unknown = 1;
    if (global.rk_greeting_status == 3) blocked = 1;
}
global.rk_progress_met = matched;
global.rk_progress_total = total;
if (blocked) {
    global.rk_objective_text = scr_routekeeper_text("guidance.this_neutral_outcome_is_blocked_in_this_run",global.rk_language);
    if (global.rk_greeting_status == 3) global.rk_objective_text = global.rk_greeting_text;
    return 3;
}
if (unknown) {
    global.rk_objective_text = scr_routekeeper_text("guidance.observe_the_remaining_encounters_before_selecting_an_outcome",global.rk_language);
    if (global.rk_greeting_status > 0) global.rk_objective_text = global.rk_greeting_text;
    return 4;
}
global.rk_objective_text = scr_routekeeper_text("guidance.continue_while_preserving_the_selected_encounter_outcomes",global.rk_language);
if (nt == 1 && friend < 4) {
    global.rk_objective_text = scr_routekeeper_text("guidance.befriend_the_warrior_without_gaining_exp",global.rk_language);
}
if ((nt == 4 || nt == 5) && friend <= 0) {
    global.rk_objective_text = scr_routekeeper_text("guidance.start_the_warrior_s_friendship_before_additional_kills",global.rk_language);
}
if (nt == 18 && stage < 12) {
    global.rk_objective_text = scr_routekeeper_text("guidance.maintain_the_regional_route_through_waterfall",global.rk_language);
}
if (global.rk_target_greeting > 0 && global.rk_greeting_status == 1) global.rk_objective_text = global.rk_greeting_text;
if (action) return 1;
return 0;
""");
        return code.Append('\n').ToString();
    }
}
