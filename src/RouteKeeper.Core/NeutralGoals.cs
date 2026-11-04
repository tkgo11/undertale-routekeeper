using System.Text;

namespace RouteKeeper.Core;

public sealed record GreetingRequirement
{
    public IReadOnlyList<ObjectiveCondition> Alternatives {get;}
    public string TextKey {get;}
    public bool Permanent {get;}
    public string? Deadline {get;}
    public GreetingRequirement(ObjectiveCondition[] alternatives,string textKey,bool permanent=false,string? deadline=null)
    {Alternatives=Array.AsReadOnly((ObjectiveCondition[])alternatives.Clone());TextKey=textKey;Permanent=permanent;Deadline=deadline;}
    public string English=>TextCatalog.Get(TextKey,0);
    public string Korean=>TextCatalog.Get(TextKey,"ko");
    public string Text(Language language)=>TextCatalog.Get(TextKey,language);
    public bool? Met(GameState state)
    {
        bool unknown=false;
        foreach(var alternative in Alternatives)
        {
            var values=alternative.Tests.Select(t=>state[t.Fact] is int ? (bool?)t.Matches(state):null).ToArray();
            if(values.All(v=>v==true)) return true;
            if(!values.Contains(false)) unknown=true;
        }
        return unknown?null:false;
    }
}
public sealed record NeutralGreetingGoal
{
    public int Id {get;}
    public string TextKey {get;}
    public IReadOnlyList<int> CompatibleTargets {get;}
    public IReadOnlyList<GreetingRequirement> Requirements {get;}
    public NeutralGreetingGoal(int id,string textKey,int[] compatibleTargets,GreetingRequirement[] requirements)
    {Id=id;TextKey=textKey;CompatibleTargets=Array.AsReadOnly((int[])compatibleTargets.Clone());Requirements=Array.AsReadOnly((GreetingRequirement[])requirements.Clone());}
    public string English=>TextCatalog.Get(TextKey,0);
    public string Korean=>TextCatalog.Get(TextKey,"ko");
    public string Label(Language language)=>TextCatalog.Get(TextKey,language);
}

/// <summary>Selectable call-condition goals. Matching conditions may share/overwrite dialogue slots.</summary>
public static class NeutralGoals
{
    private static FactTest Eq(string fact,int n)=>new(fact,Comparison.Equal,n);
    private static FactTest Min(string fact,int n)=>new(fact,Comparison.AtLeast,n);
    private static FactTest Max(string fact,int n)=>new(fact,Comparison.AtMost,n);
    private static GreetingRequirement R(string fact,int n,string key,bool permanent=false,string? deadline=null,Comparison comparison=Comparison.Equal)=>new([new(new FactTest(fact,comparison,n))],key,permanent,deadline);
    private static GreetingRequirement Alive(string who)=>R("neutral_"+who+"_dead",0,"guidance.keep_the_required_characters_alive",true);
    private static readonly int[] All=Enumerable.Range(0,19).ToArray();
    private static readonly int[] WithPapyrus=[0,1,2,3,4,5,6,8,10,12,14];
    private static readonly GreetingRequirement[] Greeting=[Alive("papyrus")];
    private static GreetingRequirement[] Join(params GreetingRequirement[] extra)=>Greeting.Concat(extra).ToArray();
    public static IReadOnlyList<NeutralGreetingGoal> Goals {get;}=new NeutralGreetingGoal[] {
        new(0,"guidance.no_extra_goal",All,[]),
        new(1,"guidance.friend_s_call",[0,1],[Alive("toriel"),Alive("papyrus"),Alive("undyne"),Alive("mettaton"),R("water_opportunity_missed",0,"guidance.help_the_fallen_warrior_before_leaving",true),R("kills",0,"guidance.do_not_defeat_any_monsters",true),R("neutral_undyne_friendship",4,"guidance.finish_the_warrior_s_friendship",comparison:Comparison.AtLeast),R("neutral_alphys_friendship",10,"guidance.finish_the_letter_and_date_but_do_not_enter",comparison:Comparison.AtLeast)]),
        new(2,"guidance.exile_robot_spared",[0,6,7],[Alive("toriel"),Alive("undyne"),Alive("mettaton"),new([new(Min("kills",10)),new(Eq("neutral_papyrus_dead",1)),new(Eq("neutral_undyne_dead",1))],"guidance.reach_the_chosen_exile_outcome")]),
        new(3,"guidance.exile_robot_defeated",[0,6,7],[R("murder_level",11,"guidance.keep_the_earlier_regional_route",true,comparison:Comparison.AtMost),Alive("toriel"),Alive("undyne"),R("neutral_mettaton_dead",1,"guidance.defeat_the_robot_before_the_last_battle",deadline:"mettaton_resolved"),new([new(Min("kills",10)),new(Eq("neutral_papyrus_dead",1)),new(Eq("neutral_undyne_dead",1))],"guidance.reach_the_chosen_exile_outcome")]),
        new(4,"guidance.carry_a_keepsake",WithPapyrus,Join(R("snowman_piece_carried",1,"guidance.carry_a_snowy_keepsake_in_your_inventory_for_the"),R("keepsake_recoverable",1,"guidance.no_carried_stored_or_obtainable_keepsake_remains_in_this",true))),
        new(5,"guidance.never_save",WithPapyrus,Join(R("save_exists",0,"guidance.continue_without_writing_a_save",true))),
        new(6,"guidance.keep_starting_armor",WithPapyrus,Join(R("equipped_armor",4,"guidance.keep_your_starting_armor_equipped",true))),
        new(7,"guidance.no_healing_items",WithPapyrus,Join(R("healing_items_used",0,"guidance.avoid_healing_items_even_at_full_hp",true))),
        new(8,"guidance.lv_1_no_healing_armor",[0,1,2,4,6],Join(R("healing_items_used",0,"guidance.avoid_healing_items_even_at_full_hp",true),R("level",1,"guidance.keep_lv_1_until_the_call",true),R("equipped_armor",4,"guidance.keep_your_starting_armor_equipped",true)))
    }.AsReadOnly();
    public static IEnumerable<string> Facts=>Goals.SelectMany(g=>g.Requirements).SelectMany(r=>r.Alternatives.SelectMany(a=>a.Tests.Select(t=>t.Fact)).Concat(r.Deadline is null?[]:new[]{r.Deadline}));
    public static NeutralGreetingGoal Get(int id)=>id>=0&&id<Goals.Count?Goals[id]:throw new ArgumentOutOfRangeException(nameof(id));
    public static Evaluation Evaluate(int id,int target,GameState state,Language language=Language.English)
    {
        var goal=Get(id);var blocked=new List<Objective>();var actions=new List<Objective>();bool unknown=id==8&&target==6;
        if(!goal.CompatibleTargets.Contains(target))blocked.Add(new("greeting_conflict",TextCatalog.Get("guidance.choose_a_compatible_ending_type_for_this_call_condition",language)));
        foreach(var r in goal.Requirements)
        {
            var met=r.Met(state);if(met==true)continue;
            if(met is null){unknown=true;continue;}
            var objective=new Objective("greeting",r.Text(language));
            if(r.Permanent||r.Deadline is string d&&state[d]==1)blocked.Add(objective);
            else {actions.Add(objective);if(r.Deadline is string deadline&&state[deadline] is null)unknown=true;}
        }
        if(id==4 && blocked.Count==0 && state["snowman_piece_carried"]==0 && actions.Count>0) actions[0]=new("greeting",KeepsakeGuidance.Plan(state,language));
        if(id==8 && target==6 && blocked.Count==0) { actions.Clear();actions.Add(new("greeting",TextCatalog.Get("guidance.this_call_condition_may_not_be_attainable_with_this",language))); }
        var status=blocked.Count>0?RouteStatus.BLOCKED:unknown?RouteStatus.UNKNOWN:actions.Count>0?RouteStatus.ACTION_REQUIRED:RouteStatus.ON_TRACK;
        if(status==RouteStatus.UNKNOWN && actions.Count==0) actions.Add(new("greeting",TextCatalog.Get("guidance.the_call_condition_is_not_clear_yet",language)));
        return new(status,blocked.Count>0?blocked:actions,[],true);
    }
    public static Evaluation Merge(Evaluation basis,Evaluation goal)
    {
        int Rank(RouteStatus s)=>s switch{RouteStatus.BLOCKED=>3,RouteStatus.UNKNOWN=>2,RouteStatus.ACTION_REQUIRED=>1,_=>0};
        var dominant=Rank(goal.Status)>Rank(basis.Status)?goal:basis;
        // A concrete extra-goal objective precedes the generic "continue" objective.
        var objectives=goal.Objectives.Count>0&&(basis.Status!=RouteStatus.BLOCKED||goal.Status==RouteStatus.BLOCKED)?goal.Objectives:basis.Objectives;
        return new(dominant.Status,objectives,basis.Reasons.Concat(goal.Reasons).ToArray(),true);
    }
    public static string EmitLabels()
    {
        var s=new StringBuilder("// Generated call-condition labels; conditions can share dialogue slots.\n");
        foreach(var g in Goals)s.Append($"if (argument0 == {g.Id}) return {TextCatalog.Gml(g.TextKey,"argument1")};\n");
        return s.Append("return \"\";\n").ToString();
    }
    private static string Inverse(Comparison c)=>c switch{Comparison.Equal=>"!=",Comparison.AtLeast=>"<",_=>">"};
    public static string EmitEvaluation(bool standalone=true)
    {
        var s=new StringBuilder("// Generated from NeutralGoals; 0 on track,1 action,3 blocked,4 unknown.\nvar gg_blocked, gg_unknown, gg_action, gg_met;\ngg_blocked = 0; gg_unknown = 0; gg_action = 0;\nglobal.rk_greeting_text = scr_routekeeper_text(\"guidance.the_call_condition_is_not_clear_yet\",global.rk_language); global.rk_greeting_status = 0;\n");
        foreach(var g in Goals.Skip(1))
        {
            s.Append($"if (global.rk_target_greeting == {g.Id}) {{\n");
            var compat=string.Join(" && ",g.CompatibleTargets.Select(t=>$"global.rk_target_neutral != {t}"));
            s.Append($"if ({compat}) {{ gg_blocked = 1; global.rk_greeting_text = scr_routekeeper_text(\"guidance.choose_a_compatible_ending_type_for_this_call_condition\",global.rk_language); }}\n");
            foreach(var r in g.Requirements)
            {
                var matches=string.Join(" || ",r.Alternatives.Select(c=>"("+c.Gml+")"));
                var impossible=string.Join(" && ",r.Alternatives.Select(c=>"("+string.Join(" || ",c.Tests.Select(t=>$"(global.rk_{t.Fact} >= 0 && global.rk_{t.Fact} <= {FactDomains.Maximum(t.Fact)} && global.rk_{t.Fact} {Inverse(t.Comparison)} {t.Expected})"))+")"));
                s.Append($"if ({matches}) {{ }} else if ({impossible}) {{\n");
                string isBlocked=r.Permanent?"1":r.Deadline is string d?$"global.rk_{d} == 1":"0";
                s.Append($"if (({isBlocked}) && gg_blocked == 0 || ({isBlocked}) == 0 && gg_blocked == 0 && gg_action == 0) {{ global.rk_greeting_text = {TextCatalog.Gml(r.TextKey)}; }}\nif ({isBlocked}) gg_blocked = 1; else gg_action = 1;\n");
                if(r.Deadline is string deadline)s.Append($"if (global.rk_{deadline} < 0) gg_unknown = 1;\n");
                s.Append("} else gg_unknown = 1;\n");
            }
            s.Append("}\n");
        }
        s.Append("if (global.rk_target_greeting == 8 && global.rk_target_neutral == 6 && gg_blocked == 0) { gg_unknown = 1; global.rk_greeting_text = scr_routekeeper_text(\"guidance.this_call_condition_may_not_be_attainable_with_this\",global.rk_language); }\n");
        s.Append(KeepsakeGuidance.EmitGml());
        s.Append("if (gg_action) global.rk_greeting_status = 1;\nif (gg_unknown) global.rk_greeting_status = 4;\nif (gg_blocked) global.rk_greeting_status = 3;\n");
        if(standalone)s.Append("return global.rk_greeting_status;\n");
        return s.ToString();
    }
    public static int BossOutcome(int goal,int enemy)=>goal switch {
        1 when enemy is >=1 and <=4=>1,
        2 when enemy is 1 or 3 or 4=>1,
        3 when enemy is 1 or 3=>1,3 when enemy==4=>-1,
        >=4 and <=8 when enemy==2=>1,_=>0};
    public static string EmitProtection()
    {
        var s=new StringBuilder("// Generated additional call-goal boss outcomes.\n");
        foreach(var g in Goals.Skip(1))for(int enemy=1;enemy<=4;enemy++)if(BossOutcome(g.Id,enemy) is int result&&result!=0)s.Append($"if (global.rk_target_greeting == {g.Id} && argument0 == {enemy}) return {result};\n");
        return s.Append("return 0;\n").ToString();
    }
}
