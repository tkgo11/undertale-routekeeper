using System.Text;

namespace RouteKeeper.Core;

public static class GmlRuleEmitter
{
    public static string Operator(Comparison comparison)=>comparison switch {Comparison.AtLeast=>">=",Comparison.AtMost=>"<=",_=>"=="};
    public static string Quote(string text)=>"\""+text.Replace("\\","\\\\",StringComparison.Ordinal).Replace("\"","\\\"",StringComparison.Ordinal).Replace("\r", "",StringComparison.Ordinal).Replace("\n","\\n",StringComparison.Ordinal)+"\"";
    private static string Valid(string fact)=>$"global.rk_{fact} >= 0 && global.rk_{fact} <= {FactDomains.Maximum(fact)}";
    private static string Match(Requirement r)=>$"global.rk_{r.Fact} {Operator(r.Comparison)} {r.Expected}";
    private static void EmitRequirement(StringBuilder text,Requirement r,int index,bool progress=false)
    {
        text.Append($"// requirement {index}: {r.Fact}\n");
        text.Append($"if ({Valid(r.Fact)} && {Match(r)}) {{ ");
        if(progress) text.Append("global.rk_progress_met = global.rk_progress_met + 1; ");
        text.Append("}\n");
        if(r.GuardFact is not null)
        {
            text.Append($"else if ({Valid(r.GuardFact)} && global.rk_{r.GuardFact} < {r.GuardMinimum}) {{ ");
            if(progress) text.Append("global.rk_progress_met = global.rk_progress_met + 1; ");
            text.Append("}\n");
            text.Append($"else if (global.rk_{r.GuardFact} < 0 || global.rk_{r.GuardFact} > {FactDomains.Maximum(r.GuardFact)}) rk_unknown = 1;\n");
        }
        text.Append($"else if (global.rk_{r.Fact} < 0 || global.rk_{r.Fact} > {FactDomains.Maximum(r.Fact)}) rk_unknown = 1;\nelse {{ rk_action = 1;");
        if(r.Irreversible) text.Append(" rk_blocked = 1;");
        text.Append(" }\n");
    }
    public static string EmitEvaluator(RouteId route)
    {
        var definition=RouteCatalog.Get(route);
        var text=new StringBuilder("// Generated from RouteCatalog; do not edit.\n// 0 ON_TRACK, 1 ACTION_REQUIRED, 2 AT_RISK, 3 BLOCKED, 4 UNKNOWN.\nvar rk_unknown, rk_action, rk_blocked;\nrk_unknown = 0; rk_action = 0; rk_blocked = 0;\n");
        for(var i=0;i<definition.Requirements.Count;i++) EmitRequirement(text,definition.Requirements[i],i);
        text.Append("if (rk_blocked) return 3;\nif (rk_unknown) return 4;\nif (rk_action) return 1;\nreturn 0;\n");
        return text.ToString();
    }
    public static string EmitDispatcher()
    {
        var text=new StringBuilder("// Generated dynamic route dispatcher; do not edit.\nvar rk_result;\nrk_result = 4;\n");
        text.Append("if (global.rk_target_route == 3) return scr_routekeeper_neutral_evaluate();\n");
        foreach(var route in Enum.GetValues<RouteId>().Where(r=>r!=RouteId.Neutral))
            text.Append($"if (global.rk_target_route == {(int)route}) rk_result = scr_routekeeper_evaluate_{(int)route}();\n");
        text.Append("global.rk_objective_text = scr_routekeeper_objective();\nreturn rk_result;\n");
        return text.ToString();
    }
    private static void TextAssignment(StringBuilder text,string minimal,string detailed,string koreanMinimal,string koreanDetailed,string? countFact=null,int quota=0)
    {
        string Expression(string value)
        {
            var pieces=value.Split("{remaining}",StringSplitOptions.None);
            return pieces.Length==1 ? Quote(value) : string.Join($" + string(max(0, {quota} - global.rk_{countFact})) + ",pieces.Select(Quote));
        }
        text.Append($"rk_text = {Expression(minimal)};\nif (global.rk_spoilers == 1) rk_text = {Expression(detailed)};\nif (global.rk_language == 1) {{\n rk_text = {Expression(koreanMinimal)};\n if (global.rk_spoilers == 1) rk_text = {Expression(koreanDetailed)};\n}}\n");
    }
    public static string EmitObjectives()
    {
        var text=new StringBuilder("// Generated from the same ObjectiveRules used by C#.\nvar rk_text, rk_unknown, rk_action, rk_blocked;\nrk_text = \"Your next step is not clear yet.\";\nif (global.rk_language == 1) rk_text = \"다음 목표를 아직 알 수 없습니다.\";\nglobal.rk_objective_id = \"unknown\";\nglobal.rk_progress_met = 0; global.rk_progress_total = 0;\nrk_unknown = 0; rk_action = 0; rk_blocked = 0;\n");
        foreach(var route in Enum.GetValues<RouteId>().Where(r=>r!=RouteId.Neutral))
        {
            var definition=RouteCatalog.Get(route);
            text.Append($"if (global.rk_target_route == {(int)route}) {{\nglobal.rk_progress_total = {definition.Requirements.Count};\n");
            for(var i=0;i<definition.Requirements.Count;i++) EmitRequirement(text,definition.Requirements[i],i,true);
            if(route is RouteId.Genocide or RouteId.SoullessGenocide)
                text.Append($"global.rk_progress_met = 0; if ({Valid("genocide_stage")}) global.rk_progress_met = global.rk_genocide_stage; if (global.rk_sans_defeated == 1) global.rk_progress_met = global.rk_progress_met + 1; global.rk_progress_total = 17;\n");
            foreach(var r in definition.Requirements.Where(r=>r.Irreversible))
            {
                var guard=r.GuardFact is null ? "" : $" && ({Valid(r.GuardFact)}) && global.rk_{r.GuardFact} >= {r.GuardMinimum}";
                text.Append($"if (({Valid(r.Fact)}) && !("+Match(r)+")"+guard+") {\n");
                text.Append($"global.rk_objective_id = {Quote(r.Fact)};\n");
                TextAssignment(text,r.Minimal,r.Detailed,r.KoreanMinimal,r.KoreanDetailed);
                text.Append("return rk_text;\n}\n");
            }
            foreach(var rule in ObjectiveRules.For(route))
            {
                text.Append($"if ({rule.Condition.Gml}) {{\nglobal.rk_objective_id = {Quote(rule.Id)};\n");
                TextAssignment(text,rule.Minimal,rule.Detailed,rule.KoreanMinimal,rule.KoreanDetailed,rule.CountFact,rule.Quota);
                text.Append("return rk_text;\n}\n");
            }
            text.Append("}\n");
        }
        text.Append("return rk_text;\n");
        return text.ToString();
    }
    public static IReadOnlyDictionary<string,string> EmitNativeFiles()
    {
        var files=new Dictionary<string,string>{{"route_evaluate.gml",EmitDispatcher()},{"route_objective.gml",EmitObjectives()},
            {"fact_init.gml","// Generated unknown defaults; native bindings replace observations.\n"+string.Join("\n",RouteCatalog.Facts.Order(StringComparer.Ordinal).Select(f=>$"global.rk_{f} = -1;"))+"\n"}};
        foreach(var route in Enum.GetValues<RouteId>().Where(r=>r!=RouteId.Neutral)) files[$"route_evaluate_{(int)route}.gml"]=EmitEvaluator(route);
        return files;
    }
}
