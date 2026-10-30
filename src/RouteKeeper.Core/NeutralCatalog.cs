using System.Text;

namespace RouteKeeper.Core;

public enum NeutralEnding
{
    Any = 0, Family = 1, BetrayedUnbefriendedMettatonAlive = 2,
    BetrayedUnbefriendedMettatonDead = 3, BetrayedBefriendedMettatonAlive = 4,
    BetrayedBefriendedMettatonDead = 5, ExiledUndyneAlivePapyrusAlive = 6,
    ExiledUndyneAlivePapyrusDead = 7, ExiledUndyneDeadPapyrusAlive = 8,
    ExiledUndyneDeadPapyrusDead = 9, UndynePapyrusAlive = 10,
    UndynePapyrusDead = 11, MettatonPapyrusAlive = 12,
    MettatonPapyrusDead = 13, Papyrus = 14, Dog = 15,
    LeaderlessLowKills = 16, LeaderlessHighKills = 17, Alphys = 18,
    Impossible = 20
}

/// <summary>Facts extracted from the original neutral-call selection/event code.
/// Classify predicts the call if Neutral is reached; it does not claim it was reached.</summary>
public sealed record NeutralOutcome(NeutralEnding Ending, int OriginalBranch, IReadOnlyList<string> Modifiers)
{
    public int ModifierMask => Modifiers.Aggregate(0,(mask,id)=>mask | NeutralCatalog.ModifierRules.Single(m=>m.Id==id).Bit);
}
public sealed record NeutralModifier(string Id,int Bit,ObjectiveCondition Condition);
public sealed record NeutralTarget(NeutralEnding Id, string TextKey, int? TorielDead,
    int? PapyrusDead, int? UndyneDead, int? MettatonDead, int MinimumKills, int MaximumKills)
{
    public string English=>TextCatalog.Get(TextKey,0);
    public string Korean=>TextCatalog.Get(TextKey,"ko");
    public string Label(Language language)=>TextCatalog.Get(TextKey,language);
}

public static class NeutralCatalog
{
    public const int SelectableCount = 19;
    private const int Unlimited = int.MaxValue;
    public static IReadOnlyList<NeutralTarget> Targets { get; } = new NeutralTarget[]
    {
        new(NeutralEnding.Any,"ending.any_neutral_type",null,null,null,null,0,Unlimited),
        new(NeutralEnding.Family,"ending.family",0,0,0,0,0,0),
        new(NeutralEnding.BetrayedUnbefriendedMettatonAlive,"ending.betrayed_no_friendship_robot_spared",0,0,0,0,0,9),
        new(NeutralEnding.BetrayedUnbefriendedMettatonDead,"ending.betrayed_no_friendship_robot_killed",0,0,0,1,1,9),
        new(NeutralEnding.BetrayedBefriendedMettatonAlive,"ending.betrayed_friendship_robot_spared",0,0,0,0,1,9),
        new(NeutralEnding.BetrayedBefriendedMettatonDead,"ending.betrayed_friendship_robot_killed",0,0,0,1,1,9),
        new(NeutralEnding.ExiledUndyneAlivePapyrusAlive,"ending.exiled_warrior_and_skeleton_alive",0,0,0,null,10,Unlimited),
        new(NeutralEnding.ExiledUndyneAlivePapyrusDead,"ending.exiled_warrior_alive_skeleton_dead",0,1,0,null,1,Unlimited),
        new(NeutralEnding.ExiledUndyneDeadPapyrusAlive,"ending.exiled_warrior_dead_skeleton_alive",0,0,1,null,1,Unlimited),
        new(NeutralEnding.ExiledUndyneDeadPapyrusDead,"ending.exiled_warrior_and_skeleton_dead",0,1,1,null,2,Unlimited),
        new(NeutralEnding.UndynePapyrusAlive,"ending.undyne_papyrus_alive",1,0,0,null,1,Unlimited),
        new(NeutralEnding.UndynePapyrusDead,"ending.undyne_papyrus_dead",1,1,0,null,2,Unlimited),
        new(NeutralEnding.MettatonPapyrusAlive,"ending.mettaton_papyrus_alive",1,0,1,0,2,Unlimited),
        new(NeutralEnding.MettatonPapyrusDead,"ending.mettaton_papyrus_dead",1,1,1,0,3,Unlimited),
        new(NeutralEnding.Papyrus,"ending.papyrus",1,0,1,1,3,Unlimited),
        new(NeutralEnding.Dog,"ending.dog_only_four_bosses_killed",1,1,1,1,4,4),
        new(NeutralEnding.LeaderlessLowKills,"ending.leaderless_total_below_20",1,1,1,1,5,19),
        new(NeutralEnding.LeaderlessHighKills,"ending.leaderless_total_20",1,1,1,1,20,Unlimited),
        new(NeutralEnding.Alphys,"ending.alphys_aborted_late_genocide",1,1,1,1,4,Unlimited)
    }.AsReadOnly();
    private static FactTest Eq(string fact,int value)=>new(fact,Comparison.Equal,value);
    private static FactTest Min(string fact,int value)=>new(fact,Comparison.AtLeast,value);
    private static FactTest Max(string fact,int value)=>new(fact,Comparison.AtMost,value);
    private static ObjectiveCondition Greeting(params FactTest[] rest)=>new(new[]{Eq("neutral_papyrus_dead",0)}.Concat(rest).ToArray());
    public static IReadOnlyList<NeutralModifier> ModifierRules { get; }=new NeutralModifier[] {
        new("alphys_call",1,new(Eq("neutral_projection",1),Min("neutral_alphys_friendship",10))),
        new("mettaton_alive",2,new(Min("neutral_projection",6),Max("neutral_projection",7),Eq("neutral_mettaton_dead",0))),
        new("mettaton_dead",4,new(Min("neutral_projection",6),Max("neutral_projection",7),Eq("neutral_mettaton_dead",1))),
        new("snowman_piece",8,Greeting(Eq("snowman_piece_carried",1))),
        new("no_save",16,Greeting(Eq("save_exists",0))),
        new("bandage",32,Greeting(Eq("equipped_armor",4))),
        new("no_healing_items",64,Greeting(Eq("healing_items_used",0))),
        new("low_level_no_healing_bandage",128,Greeting(Eq("healing_items_used",0),Eq("level",1),Eq("equipped_armor",4)))
    }.AsReadOnly();
    private static readonly (string Fact, string Resolved, Func<NeutralTarget,int?> Expected)[] Bosses =
    [
        ("neutral_toriel_dead","toriel_resolved",t=>t.TorielDead),
        ("neutral_papyrus_dead","papyrus_resolved",t=>t.PapyrusDead),
        ("neutral_undyne_dead","undyne_resolved",t=>t.UndyneDead),
        ("neutral_mettaton_dead","mettaton_resolved",t=>t.MettatonDead)
    ];

    public static IEnumerable<string> Facts=>new[]{"neutral_toriel_dead","neutral_papyrus_dead","neutral_undyne_dead","neutral_mettaton_dead","neutral_undyne_friendship","neutral_alphys_friendship","kills","murder_level","mettaton_resolved"}.Concat(ModifierRules.SelectMany(r=>r.Condition.Tests.Select(t=>t.Fact)));
    public static int FriendshipMinimum(int id)=>id==1?4:id is 4 or 5?1:0;

    public static NeutralTarget Get(int id) => id >= 0 && id < SelectableCount ? Targets[id] :
        throw new ArgumentOutOfRangeException(nameof(id),"Unknown or debug-only Neutral target");

    public static Evaluation Evaluate(int targetId, GameState state, SpoilerLevel spoilers = SpoilerLevel.Minimal,
        Language language = Language.English)
    {
        var target=Get(targetId);
        var blocked=false; var unknown=false; var action=false;
        var objectives=new List<Objective>(); var reasons=new List<string>();
        void Mark(string fact,string key,bool invalidated=false)
        {
            if(invalidated) { blocked=true; reasons.Add("invalidated:"+fact); }
            else action=true;
            if(objectives.Count==0) objectives.Add(new(fact,TextCatalog.Get(key,language).Replace("{character}",fact.Replace("neutral_", "").Replace("_dead", ""),StringComparison.Ordinal)));
        }
        if(state["hard_mode"] is null || state["world_erased"] is null || state["true_lab_completed"] is null) unknown=true;
        if(state["hard_mode"]==1) Mark("hard_mode","guidance.hard_mode_cannot_reach_a_neutral_ending",true);
        if(state["world_erased"]==1) Mark("world_erased","guidance.the_world_is_erased_permanent_history_choices_remain_yours",true);
        var stage=state["murder_level"];
        if(stage is null) unknown=true;
        else if(stage>=16) Mark("murder_level","guidance.the_genocide_conclusion_is_already_committed",true);
        if(state["true_lab_completed"]==1) Mark("true_lab_completed","guidance.the_true_pacifist_finale_is_already_unlocked",true);
        foreach(var (fact,resolved,expected) in Bosses)
        {
            if(expected(target) is not int wanted) continue;
            var actual=state[fact];
            if(actual is null) { unknown=true;continue; }
            if(actual==wanted) continue;
            var permanentlyWrong=actual==1 || state[resolved]==1;
            if(wanted==1 && !permanentlyWrong && state[resolved] is null) unknown=true;
            Mark(fact,spoilers==SpoilerLevel.Detailed?"guidance.resolve_character_s_encounter_with_the_selected_outcome":"guidance.preserve_the_selected_encounter_outcomes",permanentlyWrong);
        }
        var kills=state["kills"];
        if(kills is null) unknown=true;
        else if(kills>target.MaximumKills) Mark("kills","guidance.the_selected_kill_limit_has_been_exceeded",true);
        else if(kills<target.MinimumKills) Mark("kills","guidance.follow_the_selected_encounters_before_the_final_battle");
        if(kills is int observedKills && target.MaximumKills<int.MaxValue)
        {
            int reserved=Bosses.Count(b=>b.Item3(target)==1&&state[b.Item1]==0);
            if((long)observedKills+reserved>target.MaximumKills)
                Mark("kills","guidance.too_few_kills_remain_for_the_required_boss_outcomes",true);
        }
        if(targetId is >=1 and <=5)
        {
            var friendship=state["neutral_undyne_friendship"];
            if(friendship is null) unknown=true;
            else if(targetId==1 && friendship<4)
            {
                var locked=kills>0 || state["water_opportunity_missed"]==1;
                Mark("neutral_undyne_friendship","guidance.complete_the_warrior_s_friendship_without_gaining_exp",locked);
            }
            else if(targetId is 2 or 3 && friendship>0 && kills>0)
                Mark("neutral_undyne_friendship","guidance.the_friendship_betrayal_changes_this_variant",true);
            else if(targetId is 2 or 3 && friendship>3)
                Mark("neutral_undyne_friendship","guidance.this_friendship_no_longer_matches_the_selected_variant",true);
            else if(targetId is 4 or 5 && friendship<=0)
                Mark("neutral_undyne_friendship","guidance.start_the_warrior_s_friendship_before_any_additional_kills",kills>0 || state["water_opportunity_missed"]==1);
        }
        if(targetId==18)
        {
            if(stage is >=0 and <12) Mark("murder_level","guidance.follow_genocide_through_waterfall_then_abandon_it_in_hotland",state["undyne_resolved"]==1);
        }
        else if(target.MettatonDead==1 && stage>=12)
            Mark("murder_level","guidance.the_late_genocide_history_overrides_this_neutral_outcome",true);
        if(!blocked && objectives.Count==0)
            objectives.Add(new("continue",TextCatalog.Get("guidance.continue_while_preserving_the_selected_outcomes",language)));
        var status=blocked?RouteStatus.BLOCKED:unknown?RouteStatus.UNKNOWN:action?RouteStatus.ACTION_REQUIRED:RouteStatus.ON_TRACK;
        var basis=new Evaluation(status,objectives,reasons,true);
        var goal=state["target_greeting"]??0;
        return goal>0?NeutralGoals.Merge(basis,NeutralGoals.Evaluate(goal,targetId,state,language)):basis;
    }

    /// <summary>Source-selected opening slot origins, separate from condition satisfaction.</summary>
    public static IReadOnlyList<string> OpeningSlotSources(GameState state)
    {
        var outcome=Classify(state);int mask=outcome.ModifierMask;
        var slots=Enumerable.Repeat("base",7).ToArray();
        void Put(string origin,params int[] indexes) { foreach(int index in indexes)slots[index-2]=origin; }
        if((mask&8)!=0)Put("keepsake",3,4,5,6);
        if((mask&16)!=0)Put("save",2,4,5,6);
        if((mask&32)!=0)Put("armor",3,4,5,6);
        if((mask&64)!=0)Put("healing",3,4,5,6);
        if((mask&128)!=0)Put("composite",3,4,5,6,7,8);
        if(outcome.OriginalBranch==7)Put("late",2,3);
        return slots;
    }

    public static NeutralOutcome Classify(GameState state)
    {
        var keys=new[]{"neutral_toriel_dead","neutral_papyrus_dead","neutral_undyne_dead","neutral_mettaton_dead","kills","murder_level","neutral_undyne_friendship"};
        if(keys.Any(k=>state[k] is null)) throw new InvalidOperationException("Neutral classification requires observed outcome facts.");
        bool t=state[keys[0]]==1,p=state[keys[1]]==1,u=state[keys[2]]==1,m=state[keys[3]]==1;
        int kills=state["kills"]!.Value,stage=state["murder_level"]!.Value,friend=state["neutral_undyne_friendship"]!.Value;
        NeutralEnding ending; int branch;
        if(stage>=12 && m) { ending=NeutralEnding.Alphys;branch=7; }
        else if(!t)
        {
            if(p||u||kills>=10) { ending=u?(p?NeutralEnding.ExiledUndyneDeadPapyrusDead:NeutralEnding.ExiledUndyneDeadPapyrusAlive):(p?NeutralEnding.ExiledUndyneAlivePapyrusDead:NeutralEnding.ExiledUndyneAlivePapyrusAlive);branch=1; }
            else if(friend>3 && kills==0) { ending=NeutralEnding.Family;branch=0; }
            else if(kills>0 && friend>0) { ending=m?NeutralEnding.BetrayedBefriendedMettatonDead:NeutralEnding.BetrayedBefriendedMettatonAlive;branch=0; }
            else { ending=m?NeutralEnding.BetrayedUnbefriendedMettatonDead:NeutralEnding.BetrayedUnbefriendedMettatonAlive;branch=0; }
        }
        else if(!u) { ending=p?NeutralEnding.UndynePapyrusDead:NeutralEnding.UndynePapyrusAlive;branch=2; }
        else if(!m) { ending=p?NeutralEnding.MettatonPapyrusDead:NeutralEnding.MettatonPapyrusAlive;branch=3; }
        else if(!p) { ending=NeutralEnding.Papyrus;branch=4; }
        else if(kills==4) { ending=NeutralEnding.Dog;branch=6; }
        else { ending=kills>=20?NeutralEnding.LeaderlessHighKills:NeutralEnding.LeaderlessLowKills;branch=5; }
        var projection=new GameState(new Dictionary<string,int?>(state.Facts){["neutral_projection"]=(int)ending});
        var modifiers=ModifierRules.Where(r=>r.Condition.Matches(projection)).Select(r=>r.Id).ToArray();
        return new(ending,branch,modifiers);
    }
}
