using System.Text;

namespace RouteKeeper.Core;

public sealed record GreetingRequirement(ObjectiveCondition[] Alternatives, string English, string Korean,
    bool Permanent = false, string? Deadline = null)
{
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
public sealed record NeutralGreetingGoal(int Id,string English,string Korean,int[] CompatibleTargets,GreetingRequirement[] Requirements);

/// <summary>Selectable call-condition goals. Matching conditions may share/overwrite dialogue slots.</summary>
public static class NeutralGoals
{
    private static FactTest Eq(string fact,int n)=>new(fact,Comparison.Equal,n);
    private static FactTest Min(string fact,int n)=>new(fact,Comparison.AtLeast,n);
    private static FactTest Max(string fact,int n)=>new(fact,Comparison.AtMost,n);
    private static GreetingRequirement R(string fact,int n,string en,string ko,bool permanent=false,string? deadline=null,Comparison comparison=Comparison.Equal)=>new([new(new FactTest(fact,comparison,n))],en,ko,permanent,deadline);
    private static GreetingRequirement Alive(string who)=>R("neutral_"+who+"_dead",0,"Keep the required characters alive.","필요한 인물을 살려 주세요.",true);
    private static readonly int[] All=Enumerable.Range(0,19).ToArray();
    private static readonly int[] WithPapyrus=[0,1,2,3,4,5,6,8,10,12,14];
    private static readonly GreetingRequirement[] Greeting=[Alive("papyrus")];
    private static GreetingRequirement[] Join(params GreetingRequirement[] extra)=>Greeting.Concat(extra).ToArray();
    public static IReadOnlyList<NeutralGreetingGoal> Goals {get;}=new NeutralGreetingGoal[] {
        new(0,"No extra goal","추가 목표 없음",All,[]),
        new(1,"Friend's call","친구의 전화",[0,1],[Alive("toriel"),Alive("papyrus"),Alive("undyne"),Alive("mettaton"),R("water_opportunity_missed",0,"Help the fallen warrior before leaving.","떠나기 전에 쓰러진 전사를 도와주세요.",true),R("kills",0,"Do not defeat any monsters.","몬스터를 죽이지 마세요.",true),R("neutral_undyne_friendship",4,"Finish the warrior's friendship.","전사와 우정을 쌓으세요.",comparison:Comparison.AtLeast),R("neutral_alphys_friendship",10,"Finish the letter and date, but do not enter the hidden lab.","편지와 데이트를 마치되 숨겨진 연구소에는 들어가지 마세요.",comparison:Comparison.AtLeast)]),
        new(2,"Exile / robot spared","추방 / 로봇 생존",[0,6,7],[Alive("toriel"),Alive("undyne"),Alive("mettaton"),new([new(Min("kills",10)),new(Eq("neutral_papyrus_dead",1)),new(Eq("neutral_undyne_dead",1))],"Reach the chosen exile outcome.","선택한 추방 결말의 조건을 채우세요.")]),
        new(3,"Exile / robot defeated","추방 / 로봇 처치",[0,6,7],[R("murder_level",11,"Keep the earlier regional route.","앞선 지역 경로를 유지하세요.",true,comparison:Comparison.AtMost),Alive("toriel"),Alive("undyne"),R("neutral_mettaton_dead",1,"Defeat the robot before the last battle.","마지막 전투 전에 로봇을 쓰러뜨리세요.",deadline:"mettaton_resolved"),new([new(Min("kills",10)),new(Eq("neutral_papyrus_dead",1)),new(Eq("neutral_undyne_dead",1))],"Reach the chosen exile outcome.","선택한 추방 결말의 조건을 채우세요.")]),
        new(4,"Carry a keepsake","기념품 소지",WithPapyrus,Join(R("snowman_piece_carried",1,"Carry a snowy keepsake in your inventory for the call.","통화할 때 눈으로 된 기념품을 소지하세요."),R("keepsake_recoverable",1,"No carried, stored or obtainable keepsake remains in this run.","이번 회차에 소지·보관·획득 가능한 기념품이 남아 있지 않습니다.",true))),
        new(5,"Never SAVE","SAVE 없이 진행",WithPapyrus,Join(R("save_exists",0,"Continue without writing a SAVE.","SAVE를 하지 않고 진행하세요.",true))),
        new(6,"Keep starting armor","처음 방어구 유지",WithPapyrus,Join(R("equipped_armor",4,"Keep your starting armor equipped.","처음 방어구를 계속 착용하세요.",true))),
        new(7,"No healing items","회복 아이템 없이",WithPapyrus,Join(R("healing_items_used",0,"Avoid healing items, even at full HP.","HP가 가득 차 있어도 회복 아이템을 쓰지 마세요.",true))),
        new(8,"LV 1 / no healing / armor","LV 1 / 회복 없음 / 방어구",[0,1,2,4,6],Join(R("healing_items_used",0,"Avoid healing items, even at full HP.","HP가 가득 차 있어도 회복 아이템을 쓰지 마세요.",true),R("level",1,"Keep LV 1 until the call.","통화할 때까지 LV 1을 유지하세요.",true),R("equipped_armor",4,"Keep your starting armor equipped.","처음 방어구를 계속 착용하세요.",true)))
    }.AsReadOnly();
    public static IEnumerable<string> Facts=>Goals.SelectMany(g=>g.Requirements).SelectMany(r=>r.Alternatives.SelectMany(a=>a.Tests.Select(t=>t.Fact)).Concat(r.Deadline is null?[]:new[]{r.Deadline}));
    public static NeutralGreetingGoal Get(int id)=>id>=0&&id<Goals.Count?Goals[id]:throw new ArgumentOutOfRangeException(nameof(id));
    public static Evaluation Evaluate(int id,int target,GameState state,Language language=Language.English)
    {
        var goal=Get(id);var blocked=new List<Objective>();var actions=new List<Objective>();bool unknown=id==8&&target==6;
        if(!goal.CompatibleTargets.Contains(target))blocked.Add(new("greeting_conflict",language==Language.Korean?"이 통화 조건과 맞는 결말 유형을 선택하세요.":"Choose a compatible ending type for this call condition."));
        foreach(var r in goal.Requirements)
        {
            var met=r.Met(state);if(met==true)continue;
            if(met is null){unknown=true;continue;}
            var objective=new Objective("greeting",language==Language.Korean?r.Korean:r.English);
            if(r.Permanent||r.Deadline is string d&&state[d]==1)blocked.Add(objective);
            else {actions.Add(objective);if(r.Deadline is string deadline&&state[deadline] is null)unknown=true;}
        }
        if(id==4 && blocked.Count==0 && state["snowman_piece_carried"]==0 && actions.Count>0) actions[0]=new("greeting",KeepsakeGuidance.Plan(state,language));
        if(id==8 && target==6 && blocked.Count==0) { actions.Clear();actions.Add(new("greeting",language==Language.Korean?"이 결말 유형에서는 이 통화 조건에 도달하지 못할 수 있습니다.":"This call condition may not be attainable with this ending type.")); }
        var status=blocked.Count>0?RouteStatus.BLOCKED:unknown?RouteStatus.UNKNOWN:actions.Count>0?RouteStatus.ACTION_REQUIRED:RouteStatus.ON_TRACK;
        if(status==RouteStatus.UNKNOWN && actions.Count==0) actions.Add(new("greeting",language==Language.Korean?"아직 통화 조건을 확인할 수 없습니다.":"The call condition is not clear yet."));
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
        foreach(var g in Goals)s.Append($"if (argument0 == {g.Id}) {{ if (argument1 == 1) return {GmlRuleEmitter.Quote(g.Korean)}; return {GmlRuleEmitter.Quote(g.English)}; }}\n");
        return s.Append("return \"\";\n").ToString();
    }
    private static string Inverse(Comparison c)=>c switch{Comparison.Equal=>"!=",Comparison.AtLeast=>"<",_=>">"};
    public static string EmitEvaluation(bool standalone=true)
    {
        var s=new StringBuilder("// Generated from NeutralGoals; 0 on track,1 action,3 blocked,4 unknown.\nvar gg_blocked, gg_unknown, gg_action, gg_met;\ngg_blocked = 0; gg_unknown = 0; gg_action = 0;\nglobal.rk_greeting_text = \"The call condition is not clear yet.\"; if (global.rk_language == 1) global.rk_greeting_text = \"아직 통화 조건을 확인할 수 없습니다.\"; global.rk_greeting_status = 0;\n");
        foreach(var g in Goals.Skip(1))
        {
            s.Append($"if (global.rk_target_greeting == {g.Id}) {{\n");
            var compat=string.Join(" && ",g.CompatibleTargets.Select(t=>$"global.rk_target_neutral != {t}"));
            s.Append($"if ({compat}) {{ gg_blocked = 1; global.rk_greeting_text = \"Choose a compatible ending type for this call condition.\"; if (global.rk_language == 1) global.rk_greeting_text = \"이 통화 조건과 맞는 결말 유형을 선택하세요.\"; }}\n");
            foreach(var r in g.Requirements)
            {
                var matches=string.Join(" || ",r.Alternatives.Select(c=>"("+c.Gml+")"));
                var impossible=string.Join(" && ",r.Alternatives.Select(c=>"("+string.Join(" || ",c.Tests.Select(t=>$"(global.rk_{t.Fact} >= 0 && global.rk_{t.Fact} <= {FactDomains.Maximum(t.Fact)} && global.rk_{t.Fact} {Inverse(t.Comparison)} {t.Expected})"))+")"));
                s.Append($"if ({matches}) {{ }} else if ({impossible}) {{\n");
                string isBlocked=r.Permanent?"1":r.Deadline is string d?$"global.rk_{d} == 1":"0";
                s.Append($"if (({isBlocked}) && gg_blocked == 0 || ({isBlocked}) == 0 && gg_blocked == 0 && gg_action == 0) {{ global.rk_greeting_text = {GmlRuleEmitter.Quote(r.English)}; if (global.rk_language == 1) global.rk_greeting_text = {GmlRuleEmitter.Quote(r.Korean)}; }}\nif ({isBlocked}) gg_blocked = 1; else gg_action = 1;\n");
                if(r.Deadline is string deadline)s.Append($"if (global.rk_{deadline} < 0) gg_unknown = 1;\n");
                s.Append("} else gg_unknown = 1;\n");
            }
            s.Append("}\n");
        }
        s.Append("if (global.rk_target_greeting == 8 && global.rk_target_neutral == 6 && gg_blocked == 0) { gg_unknown = 1; global.rk_greeting_text = \"This call condition may not be attainable with this ending type.\"; if (global.rk_language == 1) global.rk_greeting_text = \"이 결말 유형에서는 이 통화 조건에 도달하지 못할 수 있습니다.\"; }\n");
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
