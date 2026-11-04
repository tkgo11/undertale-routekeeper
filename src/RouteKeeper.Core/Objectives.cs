namespace RouteKeeper.Core;

public sealed record FactTest(string Fact,Comparison Comparison,int Expected)
{
    public bool Matches(GameState state) => state[Fact] is int value && (Comparison switch
    { Comparison.AtLeast=>value>=Expected,Comparison.AtMost=>value<=Expected,_=>value==Expected });
    public string Gml => $"(global.rk_{Fact} >= 0 && global.rk_{Fact} <= {FactDomains.Maximum(Fact)} && global.rk_{Fact} {GmlRuleEmitter.Operator(Comparison)} {Expected})";
}
public sealed record ObjectiveCondition
{
    public IReadOnlyList<FactTest> Tests { get; }
    public ObjectiveCondition(params FactTest[] tests)=>Tests=Array.AsReadOnly((FactTest[])tests.Clone());
    public bool Matches(GameState state)=>Tests.All(t=>t.Matches(state));
    public string Gml=>string.Join(" && ",Tests.Select(t=>t.Gml));
}
public sealed record ObjectiveRule(string Id,ObjectiveCondition Condition,string MinimalKey,string DetailedKey,
    string? CountFact=null,int Quota=0)
{
    public string Minimal=>TextCatalog.Get(MinimalKey,0);
    public string Detailed=>TextCatalog.Get(DetailedKey,0);
    public string KoreanMinimal=>TextCatalog.Get(MinimalKey,"ko");
    public string KoreanDetailed=>TextCatalog.Get(DetailedKey,"ko");
    public string Template(SpoilerLevel spoilers,Language language)=>TextCatalog.Get(spoilers==SpoilerLevel.Detailed?DetailedKey:MinimalKey,language);
    public string Text(GameState state,SpoilerLevel spoilers,Language language)=>Template(spoilers,language)
        .Replace("{remaining}",Math.Max(0,Quota-(state[CountFact??""]??0)).ToString(System.Globalization.CultureInfo.InvariantCulture),StringComparison.Ordinal);
}
public static class ObjectiveRules
{
    private static FactTest Eq(string f,int v)=>new(f,Comparison.Equal,v);
    private static FactTest Min(string f,int v)=>new(f,Comparison.AtLeast,v);
    private static FactTest Max(string f,int v)=>new(f,Comparison.AtMost,v);
    private static ObjectiveRule O(string id,string minimal,string detail,params FactTest[] tests)=>new(id,new(tests),minimal,detail);
    private static readonly ObjectiveRule[] Pacifist=[
        O("water_opportunity_missed","guidance.help_the_collapsed_person_before_leaving","guidance.take_water_from_the_cooler_and_give_it_to",Eq("water_opportunity_active",1)),
        O("papyrus_friendship","guidance.visit_your_new_friend_s_home","guidance.go_to_papyrus_s_house_and_finish_his_date",Eq("papyrus_friendship",0),Eq("papyrus_hangout_available",1)),
        O("undyne_friendship","guidance.meet_your_friends_at_their_home","guidance.meet_papyrus_outside_undyne_s_house_and_finish_her",Eq("undyne_friendship",0),Eq("papyrus_friendship",1),Eq("undyne_hangout_available",1)),
        O("prior_neutral_completion","guidance.finish_the_journey_then_continue_from_your_save","guidance.defeat_asgore_and_omega_flowey_then_reload_your_save",Eq("prior_neutral_completion",0),Eq("mettaton_defeated",1)),
        O("alphys_friendship","guidance.deliver_your_friend_s_message","guidance.get_undyne_s_letter_deliver_it_to_alphys_and",Eq("alphys_friendship",0),Eq("prior_neutral_completion",1),Eq("papyrus_friendship",1),Eq("undyne_friendship",1),Eq("alphys_date_available",1)),
        O("true_lab_completed","guidance.explore_the_path_your_friends_opened","guidance.enter_the_bathroom_in_alphys_s_lab_and_complete",Eq("alphys_friendship",1),Eq("true_lab_completed",0),Eq("true_lab_available",1)),
        O("ending_complete","guidance.your_selected_path_is_complete","guidance.the_barrier_is_open_and_your_final_choice_matches",Eq("barrier_broken",1),Eq("epilogue_resolved",1),Eq("epilogue_matches",1),Eq("papyrus_friendship",1),Eq("undyne_friendship",1),Eq("alphys_friendship",1)),
        O("epilogue","guidance.finish_your_farewells_and_choose_your_future","guidance.speak_with_your_friends_leave_the_underground_then_keep",Eq("barrier_broken",1),Eq("papyrus_friendship",1),Eq("undyne_friendship",1),Eq("alphys_friendship",1)),
        O("barrier","guidance.return_to_the_barrier_and_help_your_friends","guidance.return_to_the_barrier_and_complete_the_asriel_encounter",Eq("true_lab_completed",1),Eq("barrier_broken",0),Eq("papyrus_friendship",1),Eq("undyne_friendship",1),Eq("alphys_friendship",1),Eq("prior_neutral_completion",1)),
        O("travel_ruins","guidance.explore_the_ruins_without_gaining_exp","guidance.spare_toriel_and_continue_out_of_the_ruins_without",Eq("area",0)),
        O("travel_snowdin","guidance.continue_through_the_forest_and_make_a_friend","guidance.spare_papyrus_then_visit_his_house_for_a_date",Eq("area",1)),
        O("travel_waterfall","guidance.continue_through_the_caverns_and_help_those_in_need","guidance.flee_from_undyne_to_hotland_then_give_her_water",Eq("area",2)),
        O("travel_hotland","guidance.continue_toward_the_castle_without_gaining_exp","guidance.spare_mettaton_ex_and_continue_toward_asgore_without_gaining",Min("area",3))
    ];
    private static ObjectiveRule Stage(int stage,string id,string minimal,string detail)=>
        O(id,minimal,detail,Eq("genocide_stage",stage));
    private static ObjectiveRule Quota(int stage,string area,int quota,string detail)=>
        new("quota_"+area,new(Eq("genocide_stage",stage),Max("kills_"+area,quota-1)),
            "guidance.defeat_remaining_more_enemies_before_moving_on",detail,"kills_"+area,quota);
    private static readonly ObjectiveRule[] Genocide=[
        Quota(0,"ruins",20,"guidance.defeat_remaining_more_enemies_in_the_ruins_before_leaving"),
        Stage(1,"toriel","guidance.complete_the_region_s_final_encounter","guidance.kill_toriel_then_enter_snowdin"),
        Stage(2,"doggo","guidance.complete_the_next_required_encounter","guidance.kill_doggo_do_not_spare_required_enemies"),
        Stage(3,"dog_pair","guidance.complete_the_next_required_encounter","guidance.kill_dogamy_and_dogaressa"),
        Stage(4,"greater_dog","guidance.complete_the_next_required_encounter","guidance.kill_greater_dog_kill_lesser_dog_if_encountered"),
        Stage(5,"snowdrake","guidance.find_the_missing_required_enemy_before_exhausting_the_area","guidance.kill_snowdrake_before_the_snowdin_encounter_quota_is_exhausted"),
        Quota(6,"snowdin",16,"guidance.defeat_remaining_more_enemies_in_snowdin_before_papyrus"),
        Stage(7,"papyrus","guidance.complete_the_region_s_final_encounter","guidance.kill_papyrus_after_completing_the_snowdin_quota"),
        Stage(8,"shyren","guidance.complete_the_next_required_encounter","guidance.kill_shyren"),
        Stage(9,"glad_dummy","guidance.complete_the_next_required_encounter","guidance.kill_glad_dummy"),
        Quota(10,"waterfall",18,"guidance.defeat_remaining_more_enemies_in_waterfall_before_undyne"),
        Stage(11,"undyne","guidance.complete_the_region_s_decisive_encounter","guidance.attack_monster_kid_then_defeat_undyne_the_undying"),
        Stage(12,"royal_guards","guidance.complete_the_next_required_encounter","guidance.kill_the_royal_guards"),
        Stage(13,"muffet","guidance.complete_the_next_required_encounter","guidance.kill_muffet"),
        Quota(14,"hotland_core",40,"guidance.defeat_remaining_more_enemies_in_hotland_core_before_mettaton"),
        Stage(15,"mettaton_neo","guidance.complete_the_region_s_final_encounter","guidance.kill_mettaton_neo_after_exhausting_the_hotland_core_quota"),
        O("genocide_final","guidance.continue_to_the_final_encounter","guidance.defeat_sans_then_continue_toward_the_throne_room",Eq("genocide_stage",16),Eq("sans_defeated",0)),
        O("genocide_throne","guidance.continue_to_the_throne_room_and_choose_your_future","guidance.continue_through_the_throne_room_some_choices_outlast_a",Eq("genocide_stage",16),Eq("sans_defeated",1))
    ];
    private static readonly IReadOnlyList<ObjectiveRule> PacifistView=Array.AsReadOnly(Pacifist),GenocideView=Array.AsReadOnly(Genocide);
    public static IReadOnlyList<ObjectiveRule> For(RouteId route)=>route switch
    {RouteId.TruePacifist or RouteId.SoullessPacifist=>PacifistView,RouteId.Genocide or RouteId.SoullessGenocide=>GenocideView,_=>[]};
    public static IEnumerable<string> Facts=>Pacifist.Concat(Genocide).SelectMany(r=>r.Condition.Tests.Select(t=>t.Fact).Concat(r.CountFact is null?[]:new[]{r.CountFact}));
}
