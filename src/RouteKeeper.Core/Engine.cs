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

public sealed record Requirement(string Fact, int Expected, bool Irreversible, string Minimal, string Detailed,
    string KoreanMinimal, string KoreanDetailed, Comparison Comparison = Comparison.Equal, string? GuardFact = null, int GuardMinimum = 1)
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
    public string Describe(SpoilerLevel spoilers, Language language) => (language, spoilers) switch
    {
        (Language.Korean, SpoilerLevel.Detailed) => KoreanDetailed,
        (Language.Korean, _) => KoreanMinimal,
        (_, SpoilerLevel.Detailed) => Detailed,
        _ => Minimal
    };
}
public sealed record RouteDefinition(RouteId Id, IReadOnlyList<Requirement> Requirements, bool CompleteCoverage);
public sealed record Objective(string Fact, string Text);
public sealed record Evaluation(RouteStatus Status, IReadOnlyList<Objective> Objectives, IReadOnlyList<string> Reasons,
    bool CompleteCoverage, int MetRequirements = 0, int TotalRequirements = 0);

public static class RouteCatalog
{
    private static Requirement R(string fact, int expected, bool irreversible, string minimal, string detailed,
        string koreanMinimal, string koreanDetailed, Comparison comparison = Comparison.Equal, string? guard = null, int guardMinimum = 1) =>
        new(fact, expected, irreversible, minimal, detailed, koreanMinimal, koreanDetailed, comparison, guard, guardMinimum);
    private static readonly Requirement WorldAvailable = R("world_erased",0,true,
        "The world is erased. Permanent-history decisions remain yours.",
        "The world must be restored before continuing. Some choices outlast a RESET.",
        "세계가 지워졌습니다. 영구 기록에 관한 결정은 직접 해야 합니다.",
        "계속하려면 세계가 복원되어 있어야 합니다. 어떤 선택은 RESET 뒤에도 남습니다.");
    private static readonly Requirement[] Pacifist = [
        R("hard_mode",0,true,"This challenge cannot reach the selected ending.","Hard Mode ends in the Ruins and cannot reach a normal ending.","이 도전에서는 선택한 엔딩에 도달할 수 없습니다.","하드 모드는 폐허에서 끝나므로 일반 엔딩에 도달할 수 없습니다."),
        R("experience",0,true,"Avoid gaining EXP.","Do not kill enemies or gain EXP.","EXP 획득을 피하세요.","적을 죽이거나 EXP를 얻지 마세요."),
        R("kills_total",0,true,"Keep everyone safe.","Do not kill any monsters; the letter event checks the kill count separately from EXP.","모두를 지켜 주세요.","아무 몬스터도 죽이지 마세요. 편지 이벤트는 EXP와 별도로 처치 수를 확인합니다."),
        R("papyrus_alive",1,true,"Keep your new friends safe.","Spare Papyrus.","새 친구들을 지켜 주세요.","파피루스를 살려 주세요."),
        R("undyne_alive",1,true,"Keep your new friends safe.","Spare Undyne.","새 친구들을 지켜 주세요.","언다인을 살려 주세요."),
        R("water_opportunity_missed",0,true,"Help anyone who needs immediate aid.","Give Undyne water when she collapses in Hotland.","즉시 도움이 필요한 상대를 도와주세요.","핫랜드에서 쓰러진 언다인에게 물을 주세요."),
        R("papyrus_friendship",1,false,"Spend time with your new friend.","Complete Papyrus's date or hangout at his house.","새 친구와 시간을 보내세요.","파피루스의 집에서 데이트 또는 어울리기를 완료하세요."),
        R("undyne_friendship",1,false,"Visit the friend who needs a hand.","Complete Undyne's hangout with Papyrus at her house.","도움이 필요한 친구를 찾아가세요.","파피루스와 함께 언다인의 집에서 어울리기를 완료하세요."),
        R("prior_neutral_completion",1,false,"Finish the journey, then continue from your SAVE.","Defeat Omega Flowey in a Neutral ending, then reload your SAVE.","여정을 마친 뒤 SAVE에서 계속하세요.","뉴트럴 엔딩에서 오메가 플라위를 물리친 뒤 SAVE를 불러오세요."),
        R("alphys_friendship",1,false,"Deliver your friend's message.","Deliver Undyne's letter and complete Alphys's date.","친구의 편지를 전해 주세요.","언다인의 편지를 전하고 알피스와의 데이트를 완료하세요."),
        R("true_lab_completed",1,false,"Explore the path your friends opened.","Complete the True Lab, then return to the barrier.","친구들이 열어 준 길을 탐험하세요.","진실의 연구소를 완료한 뒤 결계로 돌아가세요."),
        R("barrier_broken",1,false,"Return to the barrier and help your friends.","Complete the Asriel encounter and break the barrier.","결계로 돌아가 친구들을 도와주세요.","아스리엘 조우를 완료하고 결계를 부수세요."),
        R("epilogue_matches",1,true,"The final choice differs from your selected outcome.","Keep the selected Stay or Leave epilogue choice; existing SOUL history determines its normal or altered form.","마지막 선택이 목표한 결과와 다릅니다.","함께 살기 또는 떠나기 선택을 지켜 주세요. 기존 영혼 기록에 따라 일반 또는 변형 결말이 됩니다.",guard:"epilogue_resolved")
    ];
    private static Requirement History(int expected) => R("soul_sold",expected,true,
        "Existing permanent history does not match this ending.",
        "An earlier SOUL sale determines this ending. RESET does not erase that choice.",
        "기존 영구 기록이 이 엔딩과 맞지 않습니다.",
        "이 엔딩은 이전의 영혼 판매 선택에 따라 달라집니다. RESET으로도 지워지지 않는 선택입니다.");
    private static readonly Requirement[] Genocide = [
        R("hard_mode",0,true,"This challenge cannot reach the selected ending.","Hard Mode cannot reach a Genocide ending.","이 도전에서는 선택한 엔딩에 도달할 수 없습니다.","하드 모드에서는 몰살 엔딩에 도달할 수 없습니다."),
        R("genocide_aborted",0,true,"A required encounter was missed.","A required enemy was spared or a required encounter was lost.","필수 조우를 놓쳤습니다.","필수 적을 살렸거나 꼭 필요한 조우를 놓쳤습니다."),
        R("snowdrake_lost",0,true,"A required enemy can no longer be found.","Snowdrake must be killed before no further encounters or live Snowdrake remain.","필수 적을 더는 찾을 수 없습니다.","새 조우나 살아 있는 스노우드레이크가 남아 있을 때 처치해야 합니다."),
        R("genocide_stage",2,true,"The first region's requirements were missed.","Complete the Ruins kill quota and kill Toriel before leaving the Ruins.","첫 지역의 조건을 놓쳤습니다.","폐허를 떠나기 전에 지역 처치 수를 채우고 토리엘을 처치하세요.",Comparison.AtLeast,"toriel_resolved"),
        R("genocide_stage",8,true,"The forest's requirements were missed.","Complete Snowdin's quota and unique encounters before killing Papyrus.","숲 지역의 조건을 놓쳤습니다.","파피루스를 처치하기 전에 스노우딘의 처치 수와 필수 조우를 완료하세요.",Comparison.AtLeast,"papyrus_resolved"),
        R("genocide_stage",12,true,"The cavern's requirements were missed.","Complete Waterfall's quota, Shyren and Glad Dummy, then defeat Undyne the Undying.","동굴 지역의 조건을 놓쳤습니다.","워터폴의 처치 수와 샤이렌, 글래드 더미를 완료한 뒤 불사의 언다인을 처치하세요.",Comparison.AtLeast,"undyne_resolved"),
        R("genocide_stage",16,true,"The final region's requirements were missed.","Complete Hotland/CORE's quota and required encounters before defeating Mettaton NEO.","마지막 지역의 조건을 놓쳤습니다.","메타톤 NEO를 처치하기 전에 핫랜드와 코어의 처치 수와 필수 조우를 완료하세요.",Comparison.AtLeast,"mettaton_defeated"),
        R("genocide_stage",16,false,"Complete the area's remaining encounters.","Complete the required Genocide encounters in order.","현재 지역에 남은 조우를 완료하세요.","몰살의 필수 조우를 순서에 맞게 완료하세요.",Comparison.AtLeast),
        R("sans_defeated",1,false,"Complete the final encounter.","Defeat Sans, then continue to the throne room.","마지막 조우를 완료하세요.","샌즈를 물리친 뒤 왕좌의 방으로 계속 가세요.")
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
        var message=risk ? (language==Language.Korean ? "이 선택은 선택한 경로를 막을 수 있습니다." : "This choice may block your selected route.") : evaluation.Objectives.FirstOrDefault()?.Text;
        if(show && message is null) message=language==Language.Korean ? "다음 목표를 아직 알 수 없습니다." : "Your next step is not clear yet.";
        return new(status,show,mode!=GuidanceMode.Forced,false,show?message:null,mode==GuidanceMode.Forced?"UNVERIFIED_NO_INTERVENTION":"OBSERVE_ONLY");
    }
}
