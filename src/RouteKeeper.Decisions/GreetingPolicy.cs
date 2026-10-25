using System.Text;
namespace RouteKeeper.Decisions;

public enum CallAction { Fight=1, UseItem=8, Save=9, DropItem=10, EnterLab=11 }
public sealed record CallDecision(int Goal,CallAction Action,int Item=0,bool Healing=false,bool ArmorChange=false,bool LastKeepsake=false,bool LevelRisk=false,bool ExperienceRisk=false)
{
    public int[] Values=>[Goal,(int)Action,Item,Healing?1:0,ArmorChange?1:0,LastKeepsake?1:0,LevelRisk?1:0,ExperienceRisk?1:0];
}
public static class GreetingPolicy
{
    // Exact scr_itemuseb main-switch cases invoking scr_recoitem (including delayed noodles).
    public static readonly int[] HealingItems=[1,2,4,5,6,7,8,9,10,16,17,18,19,20,21,22,23,28,35,36,37,38,39,40,41,42,43,55,58,59,61,62];
    public static readonly int[] ArmorItems=[12,15,24,44,46,48,50,53,64];
    public static bool ExperienceRisk(int experience,int reward,int enemy,bool levelOnly) =>
        enemy is >=1 and <=5 or 7 || (levelOnly ? experience+reward>=10 : reward>0);
    public static string EmitExperience()=>"// Generated EXP threshold; scr_levelup LV2 begins at XP10.\nif ((argument2 >= 1 && argument2 <= 5) || argument2 == 7) return 1;\nif (argument3 == 1) { if (argument0 + argument1 >= 10) return 1; return 0; }\nif (argument1 > 0) return 1;\nreturn 0;\n";
    private sealed record Rule(WarningCode Code,params (int Index,int Value)[] Conditions);
    private static readonly Rule[] Rules=[
        new(WarningCode.NeutralLab,(1,11)),new(WarningCode.NeverSave,(0,5),(1,9)),
        new(WarningCode.HealingItem,(0,7),(1,8),(3,1)),new(WarningCode.HealingItem,(0,8),(1,8),(3,1)),
        new(WarningCode.LastKeepsake,(0,4),(1,8),(2,16),(5,1)),new(WarningCode.LastKeepsake,(0,4),(1,10),(2,16),(5,1)),
        new(WarningCode.StartingArmor,(0,6),(1,8),(4,1)),new(WarningCode.StartingArmor,(0,8),(1,8),(4,1)),
        new(WarningCode.LevelIncrease,(0,8),(1,1),(6,1)),new(WarningCode.CallExperience,(0,1),(1,1),(7,1))
    ];
    public static int Risk(CallDecision decision)
    {
        if(decision.Goal is <0 or >8 || !Enum.IsDefined(decision.Action))throw new ArgumentOutOfRangeException(nameof(decision));
        var values=decision.Values;return (int)(Rules.FirstOrDefault(r=>r.Conditions.All(c=>values[c.Index]==c.Value))?.Code??WarningCode.None);
    }
    public static string EmitRisk()
    {
        var s=new StringBuilder("// Generated optional call-condition pre-effect risks.\n");
        foreach(var r in Rules)s.Append($"if ({string.Join(" && ",r.Conditions.Select(c=>$"argument{c.Index} == {c.Value}"))}) return {(int)r.Code};\n");
        return s.Append("return 0;\n").ToString();
    }
    private static string EmitIds(IEnumerable<int> ids)=>"// Generated from source-verified item-effect cases.\n"+string.Join("\n",ids.Select(id=>$"if (argument0 == {id}) return 1;"))+"\nreturn 0;\n";
    public static string EmitHealing()=>EmitIds(HealingItems);
    public static string EmitArmor()=>EmitIds(ArmorItems);
}

public sealed record WarningState(bool Pending=false,bool Acknowledged=false,int Code=0,string Context="",bool Enforced=false,DecisionMode Mode=DecisionMode.Passive);
public sealed record WarningTransition(WarningState State,bool Refuse);
public enum WarningEvent { Propose=1, Acknowledge=2, Clear=3 }
/// <summary>One acknowledgement belongs to one exact proposal, never a future choice.</summary>
public static class WarningSession
{
    public static WarningTransition Apply(WarningState old,WarningEvent command,DecisionMode mode=DecisionMode.Passive,int code=0,string context="",bool enforceable=true)
    {
        if(command==WarningEvent.Clear)return new(new(),false);
        if(command==WarningEvent.Acknowledge)return new(old.Pending?old with {Pending=false,Acknowledged=true}:old,false);
        if(command!=WarningEvent.Propose)throw new ArgumentOutOfRangeException(nameof(command));
        if(mode==DecisionMode.Off||code==0)return new(new(),false);
        bool enforced=mode==DecisionMode.Forced&&enforceable;
        if(!enforced&&old.Acknowledged&&old.Code==code&&old.Context==context&&old.Mode==mode)return new(old with{Pending=false,Acknowledged=false,Enforced=false},false);
        return new(new(true,false,code,context,enforced,mode),true);
    }
    public static string EmitGml()=>"""
// Generated warning transaction; args command,code,context,enforceable.
if (argument0 == 3 || (argument0 == 1 && (global.rk_mode == 0 || argument1 == 0))) {
    global.rk_warning_pending = 0; global.rk_warning_ack = 0;
    global.rk_warning_mode = 1; global.rk_warning_code = 0; global.rk_decision_context = ""; global.rk_warning_enforced = 0;
    return 0;
}
if (argument0 == 2) {
    if (global.rk_warning_pending) { global.rk_warning_pending = 0; global.rk_warning_ack = 1; }
    return 0;
}
if (argument0 != 1) return 0;
var enforced;
enforced = (global.rk_mode == 3 && argument3);
if (!enforced && global.rk_warning_ack == 1 && global.rk_warning_code == argument1 && global.rk_decision_context == argument2 && global.rk_warning_mode == global.rk_mode) {
    global.rk_warning_pending = 0; global.rk_warning_ack = 0; global.rk_warning_enforced = 0;
    return 0;
}
global.rk_warning_mode = global.rk_mode; global.rk_decision_context = argument2; global.rk_warning_code = argument1;
global.rk_warning_enforced = enforced; global.rk_warning_ack = 0; global.rk_warning_pending = 1;
return 1;
"""+"\n";
}
