using System.Text;

namespace RouteKeeper.Core;

public enum RouteId { TruePacifist = 0, SoullessPacifist = 1, Genocide = 2, Neutral = 3, SoullessGenocide = 4 }
public enum RouteStatus { ON_TRACK, ACTION_REQUIRED, AT_RISK, BLOCKED, UNKNOWN }
public enum GuidanceMode { Off, Passive, Active, Forced }
public enum SpoilerLevel { Minimal, Detailed }
public enum Language { English, Korean }
public enum Comparison { Equal, AtLeast, AtMost }

public static class FactDomains
{
    private static readonly HashSet<string> Booleans = new(StringComparer.Ordinal)
    {
        "papyrus_alive", "undyne_alive", "water_opportunity_missed", "water_opportunity_active",
        "papyrus_friendship", "undyne_friendship", "prior_neutral_completion", "alphys_friendship",
        "true_lab_completed", "soul_sold", "genocide_aborted", "genocide_requirements_completed",
        "papyrus_hangout_available", "undyne_hangout_available", "alphys_date_available", "true_lab_available",
        "toriel_resolved", "papyrus_resolved", "undyne_resolved", "mettaton_defeated", "mettaton_resolved",
        "neutral_toriel_dead", "neutral_papyrus_dead", "neutral_undyne_dead", "neutral_mettaton_dead",
        "world_erased", "hard_mode", "epilogue_resolved", "epilogue_matches", "snowdrake_killed",
        "doggo_killed", "dogi_killed", "greater_dog_killed", "shyren_killed", "glad_dummy_killed",
        "monster_kid_attacked", "royal_guards_killed", "muffet_killed", "barrier_broken",
        "toriel_alive", "mettaton_alive", "save_exists", "snowman_piece_carried",
        "snowman_piece_stored", "snowman_piece_available", "inventory_space", "keepsake_recoverable",
        "prior_pacifist_completion", "true_reset_available", "sans_defeated", "snowdrake_lost"
    };
    public static IEnumerable<string> KnownFacts=>Booleans.Concat(new[]{"area","level","experience","kills_total","kills","plot10","genocide_stage","murder_level","equipped_armor","healing_items_used","epilogue_choice","neutral_undyne_friendship","neutral_alphys_friendship"});
    public static int Maximum(string fact) => Booleans.Contains(fact) ? 1 : fact is "genocide_stage" or "murder_level" ? 16 :
        fact == "area" ? 4 : int.MaxValue;
}

// Unknown observations remain unknown. Native bindings and save readers have no mutation API here.
public sealed record GameState
{
    public IReadOnlyDictionary<string, int?> Facts { get; }
    public GameState(IReadOnlyDictionary<string, int?> facts) => Facts = new Dictionary<string, int?>(facts).AsReadOnly();
    public int? this[string key] => Facts.TryGetValue(key, out var value) && value is >= 0 && value <= FactDomains.Maximum(key) ? value : null;
    public static GameState From(params (string Key, int? Value)[] facts) => GameStateReader.ReadNormalized(facts.ToDictionary(x => x.Key, x => x.Value));
}
public static class GameStateReader
{
    public static GameState ReadNormalized(IReadOnlyDictionary<string, int?> observations) => new(observations);
}

public sealed record Requirement(string Fact, int Expected, bool Irreversible, string MinimalKey, string DetailedKey, Comparison Comparison = Comparison.Equal, string? GuardFact = null, int GuardMinimum = 1)
{
    public bool Matches(int value) => Comparison switch { Comparison.AtLeast => value >= Expected, Comparison.AtMost => value <= Expected, _ => value == Expected };
    public bool? IsMet(GameState state)
    {
        var value = state[Fact];
        if (value is int known && Matches(known)) return true;
        if (GuardFact is not null)
        {
            if (state[GuardFact] is not int guard) return null;
            if (guard < GuardMinimum) return true;
        }
        return value is null ? null : false;
    }
    public string Minimal=>TextCatalog.Get(MinimalKey,0);
    public string Detailed=>TextCatalog.Get(DetailedKey,0);
    public string KoreanMinimal=>TextCatalog.Get(MinimalKey,"ko");
    public string KoreanDetailed=>TextCatalog.Get(DetailedKey,"ko");
    public string Describe(SpoilerLevel spoilers,Language language)=>TextCatalog.Get(spoilers==SpoilerLevel.Detailed?DetailedKey:MinimalKey,language);
}
public sealed record RouteDefinition(RouteId Id, IReadOnlyList<Requirement> Requirements, bool CompleteCoverage);
public sealed record Objective(string Fact, string Text);
public sealed record Evaluation(RouteStatus Status, IReadOnlyList<Objective> Objectives, IReadOnlyList<string> Reasons,
    bool CompleteCoverage, int MetRequirements = 0, int TotalRequirements = 0);

public static class RouteCatalog
{
    private static Requirement R(string fact, int expected, bool irreversible, string minimal, string detailed, Comparison comparison = Comparison.Equal, string? guard = null, int guardMinimum = 1) =>
        new(fact, expected, irreversible, minimal, detailed, comparison, guard, guardMinimum);
    private static readonly Requirement WorldAvailable = R("world_erased",0,true,
        "guidance.the_world_is_erased_permanent_history_decisions_remain_yours","guidance.the_world_must_be_restored_before_continuing_some_choices");
    private static readonly Requirement[] Pacifist = [
        R("hard_mode",0,true,"guidance.this_challenge_cannot_reach_the_selected_ending","guidance.hard_mode_ends_in_the_ruins_and_cannot_reach"),
        R("experience",0,true,"guidance.avoid_gaining_exp","guidance.do_not_kill_enemies_or_gain_exp"),
        R("kills_total",0,true,"guidance.keep_everyone_safe","guidance.do_not_kill_any_monsters_the_letter_event_checks"),
        R("papyrus_alive",1,true,"guidance.keep_your_new_friends_safe","guidance.spare_papyrus"),
        R("undyne_alive",1,true,"guidance.keep_your_new_friends_safe","guidance.spare_undyne"),
        R("water_opportunity_missed",0,true,"guidance.help_anyone_who_needs_immediate_aid","guidance.give_undyne_water_when_she_collapses_in_hotland"),
        R("papyrus_friendship",1,false,"guidance.spend_time_with_your_new_friend","guidance.complete_papyrus_s_date_or_hangout_at_his_house"),
        R("undyne_friendship",1,false,"guidance.visit_the_friend_who_needs_a_hand","guidance.complete_undyne_s_hangout_with_papyrus_at_her_house"),
        R("prior_neutral_completion",1,false,"guidance.finish_the_journey_then_continue_from_your_save","guidance.defeat_omega_flowey_in_a_neutral_ending_then_reload"),
        R("alphys_friendship",1,false,"guidance.deliver_your_friend_s_message","guidance.deliver_undyne_s_letter_and_complete_alphys_s_date"),
        R("true_lab_completed",1,false,"guidance.explore_the_path_your_friends_opened","guidance.complete_the_true_lab_then_return_to_the_barrier"),
        R("barrier_broken",1,false,"guidance.return_to_the_barrier_and_help_your_friends","guidance.complete_the_asriel_encounter_and_break_the_barrier"),
        R("epilogue_matches",1,true,"guidance.the_final_choice_differs_from_your_selected_outcome","guidance.keep_the_selected_stay_or_leave_epilogue_choice_existing",guard:"epilogue_resolved")
    ];
    private static Requirement History(int expected) => R("soul_sold",expected,true,
        "guidance.existing_permanent_history_does_not_match_this_ending","guidance.an_earlier_soul_sale_determines_this_ending_reset_does");
    private static readonly Requirement[] Genocide = [
        R("hard_mode",0,true,"guidance.this_challenge_cannot_reach_the_selected_ending","guidance.hard_mode_cannot_reach_a_genocide_ending"),
        R("genocide_aborted",0,true,"guidance.a_required_encounter_was_missed","guidance.a_required_enemy_was_spared_or_a_required_encounter"),
        R("snowdrake_lost",0,true,"guidance.a_required_enemy_can_no_longer_be_found","guidance.snowdrake_must_be_killed_before_no_further_encounters_or"),
        R("genocide_stage",2,true,"guidance.the_first_region_s_requirements_were_missed","guidance.complete_the_ruins_kill_quota_and_kill_toriel_before",Comparison.AtLeast,"toriel_resolved"),
        R("genocide_stage",8,true,"guidance.the_forest_s_requirements_were_missed","guidance.complete_snowdin_s_quota_and_unique_encounters_before_killing",Comparison.AtLeast,"papyrus_resolved"),
        R("genocide_stage",12,true,"guidance.the_cavern_s_requirements_were_missed","guidance.complete_waterfall_s_quota_shyren_and_glad_dummy_then",Comparison.AtLeast,"undyne_resolved"),
        R("genocide_stage",16,true,"guidance.the_final_region_s_requirements_were_missed","guidance.complete_hotland_core_s_quota_and_required_encounters_before",Comparison.AtLeast,"mettaton_defeated"),
        R("genocide_stage",16,false,"guidance.complete_the_area_s_remaining_encounters","guidance.complete_the_required_genocide_encounters_in_order",Comparison.AtLeast),
        R("sans_defeated",1,false,"guidance.complete_the_final_encounter","guidance.defeat_sans_then_continue_to_the_throne_room")
    ];
    public static RouteDefinition Get(RouteId id) => id switch
    {
        RouteId.TruePacifist => new(id,[WorldAvailable,..Pacifist,History(0)],true),
        RouteId.SoullessPacifist => new(id,[WorldAvailable,..Pacifist,History(1)],true),
        RouteId.Genocide => new(id,[WorldAvailable,..Genocide,History(0)],true),
        RouteId.SoullessGenocide => new(id,[WorldAvailable,..Genocide,History(1)],true),
        RouteId.Neutral => new(id,[],true),
        _ => throw new ArgumentOutOfRangeException(nameof(id),id,"Unknown route")
    };
    public static IReadOnlyDictionary<string,int> RegionalQuotas { get; } = new Dictionary<string,int>
    { ["ruins"]=20,["snowdin"]=16,["waterfall"]=18,["hotland_core"]=40 }.AsReadOnly();
    public static IEnumerable<string> Facts => Enum.GetValues<RouteId>().SelectMany(id=>Get(id).Requirements)
        .SelectMany(r=>r.GuardFact is null ? new[]{r.Fact} : new[]{r.Fact,r.GuardFact}).Concat(ObjectiveRules.Facts).Concat(NeutralCatalog.Facts).Concat(NeutralGoals.Facts).Concat(FactDomains.KnownFacts).Distinct(StringComparer.Ordinal);
}

public static class RouteEvaluator
{
    public static Evaluation Evaluate(RouteId route,GameState state,string locale,SpoilerLevel spoilers=SpoilerLevel.Minimal)=>Evaluate(route,state,spoilers,(Language)TextCatalog.Index(locale));
    public static Evaluation Evaluate(RouteId route,GameState state,SpoilerLevel spoilers=SpoilerLevel.Minimal,Language language=Language.English)
    {
        if (route == RouteId.Neutral) return NeutralCatalog.Evaluate(state["target_neutral"] ?? 0,state,spoilers,language);
        var definition=RouteCatalog.Get(route);
        var reasons=new List<string>(); bool blocked=false,unknown=false,action=false; int met=0;
        foreach(var r in definition.Requirements)
        {
            var result=r.IsMet(state);
            if(result is null) {unknown=true; reasons.Add("unobserved:"+r.Fact);}
            else if(result.Value) met++;
            else {action=true; if(r.Irreversible){blocked=true;reasons.Add("invalidated:"+r.Fact);}}
        }
        var status=blocked ? RouteStatus.BLOCKED : unknown ? RouteStatus.UNKNOWN : action ? RouteStatus.ACTION_REQUIRED : RouteStatus.ON_TRACK;
        var genocide=route is RouteId.Genocide or RouteId.SoullessGenocide;
        return new(status,ObjectivePlanner.Plan(definition,state,spoilers,language),reasons,definition.CompleteCoverage,
            genocide ? (state["genocide_stage"]??0) + (state["sans_defeated"]==1?1:0) : met,genocide ? 17 : definition.Requirements.Count);
    }
}

public static class ObjectivePlanner
{
    public static IReadOnlyList<Objective> Plan(RouteDefinition route,GameState state,SpoilerLevel spoilers=SpoilerLevel.Minimal,Language language=Language.English)
    {
        var invalid=route.Requirements.Where(r=>r.Irreversible && r.IsMet(state)==false).ToArray();
        if(invalid.Length>0) return invalid.Select(r=>new Objective(r.Fact,r.Describe(spoilers,language))).ToArray();
        var rule=ObjectiveRules.For(route.Id).FirstOrDefault(r=>r.Condition.Matches(state));
        return rule is null ? [] : [new(rule.Id,rule.Text(state,spoilers,language))];
    }
}

public sealed record PendingDecision(string Id,IReadOnlyDictionary<string,int?> Effects,bool Irreversible,bool AltersPermanentHistory=false);
public sealed record GuidanceResult(RouteStatus Status,bool Show,bool Dismissible,bool BlockDecision,string? Message,string Enforcement);
public static class DecisionMonitor
{
    public static bool BreaksRoute(RouteId route,GameState state,PendingDecision decision)
    {
        if (!decision.Irreversible) return false;
        var next=new GameState(state.Facts.Concat(decision.Effects).GroupBy(x=>x.Key).ToDictionary(g=>g.Key,g=>g.Last().Value));
        if (route == RouteId.Neutral)
        {
            int target=state["target_neutral"]??0,goal=state["target_greeting"]??0;
            if (NeutralCatalog.Evaluate(target,state).Status==RouteStatus.BLOCKED) return false;
            if (target is 2 or 3 && state["neutral_undyne_friendship"]==0 && next["neutral_undyne_friendship"]>0) return true;
            if (NeutralCatalog.Evaluate(target,next).Status==RouteStatus.BLOCKED) return true;
            // Last-carried keepsake use/discard is warned even though retrieval
            // might later repair it. Do not confuse this with permanent invalidity.
            return goal>0 && NeutralGoals.Get(goal).Requirements.Any(r=>r.Met(state)==true&&r.Met(next)==false);
        }
        return RouteCatalog.Get(route).Requirements.Any(r=>r.Irreversible && r.IsMet(state)==true && r.IsMet(next)==false);
    }
}
public static class GuidanceController
{
    public static GuidanceResult Update(GuidanceMode mode,RouteId route,GameState state,PendingDecision? decision=null,bool safeToDisplay=true,
        SpoilerLevel spoilers=SpoilerLevel.Minimal,Language language=Language.English)
    {
        var evaluation=RouteEvaluator.Evaluate(route,state,spoilers,language);
        var risk=decision is not null && DecisionMonitor.BreaksRoute(route,state,decision);
        var status=evaluation.Status==RouteStatus.BLOCKED ? RouteStatus.BLOCKED : risk ? RouteStatus.AT_RISK : evaluation.Status;
        var show=mode!=GuidanceMode.Off && safeToDisplay && (mode!=GuidanceMode.Passive || risk || status==RouteStatus.BLOCKED);
        var message=risk ? (TextCatalog.Get("guidance.this_choice_may_block_your_selected_route",language)) : evaluation.Objectives.FirstOrDefault()?.Text;
        if(show && message is null) message=TextCatalog.Get("guidance.your_next_step_is_not_clear_yet",language);
        return new(status,show,mode!=GuidanceMode.Forced,false,show?message:null,mode==GuidanceMode.Forced?"UNVERIFIED_NO_INTERVENTION":"OBSERVE_ONLY");
    }
}
