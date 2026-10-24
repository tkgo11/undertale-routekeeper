using System.Text;

namespace RouteKeeper.Core;

public enum RouteId { TruePacifist, SoullessPacifist, Genocide, Neutral }
public enum RouteStatus { ON_TRACK, ACTION_REQUIRED, AT_RISK, BLOCKED, UNKNOWN }
public enum GuidanceMode { Off, Passive, Active, Forced }
public enum SpoilerLevel { Minimal, Detailed }
public enum Language { English, Korean }

// Facts are normalized observations, never names of unverified game variables.
// Missing facts remain unknown; adapters must not substitute false or zero.
public sealed record GameState
{
    public IReadOnlyDictionary<string, int?> Facts { get; }
    public GameState(IReadOnlyDictionary<string, int?> facts) => Facts =
        new Dictionary<string, int?>(facts).AsReadOnly();
    public int? this[string key]
    {
        get
        {
            if (!Facts.TryGetValue(key, out var value) || value is null || value < 0) return null;
            return key == "experience" || value <= 1 ? value : null;
        }
    }
    public static GameState From(params (string Key, int? Value)[] facts) =>
        GameStateReader.ReadNormalized(facts.ToDictionary(x => x.Key, x => x.Value));
}

public static class GameStateReader
{
    // Adapters supply normalized observations, not raw game-variable guesses.
    // Copy immediately so later adapter updates cannot mutate an evaluated snapshot.
    public static GameState ReadNormalized(IReadOnlyDictionary<string, int?> observations) => new(observations);
}

public sealed record Requirement(string Fact, int Expected, bool Irreversible,
    string Minimal, string Detailed, string KoreanMinimal, string KoreanDetailed);
public sealed record RouteDefinition(RouteId Id, IReadOnlyList<Requirement> Requirements, bool CompleteCoverage);
public sealed record Objective(string Fact, string Text);
public sealed record Evaluation(RouteStatus Status, IReadOnlyList<Objective> Objectives, IReadOnlyList<string> Reasons,
    bool CompleteCoverage);

public static class RouteCatalog
{
    private static Requirement R(string fact, int expected, bool irreversible, string minimal, string detailed,
        string koreanMinimal, string koreanDetailed) => new(fact, expected, irreversible, minimal, detailed, koreanMinimal, koreanDetailed);
    private static readonly Requirement[] Pacifist = [
        R("experience", 0, true, "Avoid gaining EXP.", "Do not kill enemies or gain EXP.", "EXP 획득을 피하세요.", "적을 죽이거나 EXP를 얻지 마세요."),
        R("papyrus_alive", 1, true, "Keep your new friends safe.", "Spare Papyrus.", "새 친구들을 지켜 주세요.", "파피루스를 살려 주세요."),
        R("undyne_alive", 1, true, "Keep your new friends safe.", "Spare Undyne.", "새 친구들을 지켜 주세요.", "언다인을 살려 주세요."),
        R("water_opportunity_missed", 0, true, "Help anyone who needs immediate aid.", "Give Undyne water when she collapses in Hotland.", "즉시 도움이 필요한 상대를 도와주세요.", "핫랜드에서 쓰러진 언다인에게 물을 주세요."),
        R("papyrus_friendship", 1, false, "Spend time with your friends.", "Complete Papyrus's date or hangout.", "친구들과 시간을 보내세요.", "파피루스와 데이트 또는 어울리기를 완료하세요."),
        R("undyne_friendship", 1, false, "Spend time with your friends.", "Complete Undyne's hangout.", "친구들과 시간을 보내세요.", "언다인과 어울리기를 완료하세요."),
        R("prior_neutral_completion", 1, false, "Continue your journey; earlier progress may be needed.", "Complete a Neutral ending, then reload your SAVE.", "여정을 계속하세요. 앞선 진행이 필요할 수 있습니다.", "뉴트럴 엔딩을 완료한 뒤 SAVE를 불러오세요."),
        R("alphys_friendship", 1, false, "Follow up when a friend contacts you.", "Deliver Undyne's letter and complete Alphys's date.", "친구에게 연락이 오면 이야기를 이어가세요.", "언다인의 편지를 전하고 알피스와의 데이트를 완료하세요."),
        R("true_lab_completed", 1, false, "Explore the next available path.", "Complete the True Lab.", "새로 열린 길을 탐험하세요.", "진실의 연구소를 완료하세요.")
    ];
    public static RouteDefinition Get(RouteId id) => id switch
    {
        RouteId.TruePacifist => new(id, [.. Pacifist, R("soul_sold", 0, true,
            "Previous permanent history affects this outcome.", "A sold soul prevents the unaltered True Pacifist ending.",
            "이전의 영구 기록이 결과에 영향을 줍니다.", "영혼을 판 기록이 있으면 변형되지 않은 진정한 불살 엔딩을 볼 수 없습니다.")], false),
        RouteId.SoullessPacifist => new(id, [.. Pacifist, R("soul_sold", 1, false,
            "Permanent history must be inspected without changing it.", "This variant requires an existing sold-soul history; ROUTEKEEPER never creates or removes it.",
            "영구 기록을 변경하지 않고 확인해야 합니다.", "이 변형은 영혼을 판 기존 기록이 필요합니다. ROUTEKEEPER는 기록을 만들거나 지우지 않습니다.")], false),
        RouteId.Genocide => new(id, [
            R("genocide_aborted", 0, true, "A required encounter may have been missed.", "This run must not have aborted the Genocide route.", "필수 조우를 놓쳤을 수 있습니다.", "현재 진행에서 몰살 경로가 중단되지 않아야 합니다."),
            R("genocide_requirements_completed", 1, false, "Complete the current area's requirements before moving on.", "Satisfy regional quotas, unique kills, and required bosses in order.", "다음 지역으로 가기 전에 현재 지역의 조건을 충족하세요.", "지역별 처치 수, 필수 적 처치, 보스를 순서에 맞게 완료하세요.")], false),
        RouteId.Neutral => new(id, [], false),
        _ => throw new ArgumentOutOfRangeException(nameof(id), id, "Unknown route")
    };

    // Source: undertale.wiki/w/Genocide_Route. Counts alone never prove route reachability.
    public static IReadOnlyDictionary<string, int> RegionalQuotas { get; } =
        new Dictionary<string, int> { ["ruins"] = 20, ["snowdin"] = 16, ["waterfall"] = 18, ["hotland_core"] = 40 }.AsReadOnly();
}

public static class RouteEvaluator
{
    public static Evaluation Evaluate(RouteId route, GameState state, SpoilerLevel spoilers = SpoilerLevel.Minimal,
        Language language = Language.English)
    {
        var definition = RouteCatalog.Get(route);
        var objectives = ObjectivePlanner.Plan(definition, state, spoilers, language);
        var actionRequired = false;
        var reasons = new List<string>();
        var blocked = false;
        var unknown = false;
        foreach (var requirement in definition.Requirements)
        {
            var value = state[requirement.Fact];
            if (value is null) { unknown = true; reasons.Add("unobserved:" + requirement.Fact); continue; }
            if (value == requirement.Expected) continue;
            actionRequired = true;
            if (requirement.Irreversible) { blocked = true; reasons.Add("invalidated:" + requirement.Fact); }
        }
        // Coverage gaps must remain visible even if all implemented requirements pass.
        if (!definition.CompleteCoverage) reasons.Add("coverage:partial");
        var status = blocked ? RouteStatus.BLOCKED : unknown ? RouteStatus.UNKNOWN :
            actionRequired ? RouteStatus.ACTION_REQUIRED :
            definition.CompleteCoverage ? RouteStatus.ON_TRACK : RouteStatus.UNKNOWN;
        return new(status, objectives, reasons, definition.CompleteCoverage);
    }
}

public static class ObjectivePlanner
{
    // Availability facts must come from verified event adapters. An unmet late-game
    // prerequisite is not an instruction to attempt an unavailable action now.
    private static readonly IReadOnlyDictionary<string, string> Availability = new Dictionary<string, string>
    {
        ["papyrus_friendship"] = "papyrus_hangout_available",
        ["undyne_friendship"] = "undyne_hangout_available",
        ["alphys_friendship"] = "alphys_date_available",
        ["true_lab_completed"] = "true_lab_available"
    };
    private static readonly IReadOnlyDictionary<string, string[]> Dependencies = new Dictionary<string, string[]>
    {
        ["papyrus_friendship"] = ["papyrus_alive"],
        ["undyne_friendship"] = ["papyrus_friendship", "undyne_alive", "water_opportunity_missed"],
        ["alphys_friendship"] = ["prior_neutral_completion", "papyrus_friendship", "undyne_friendship"],
        ["true_lab_completed"] = ["alphys_friendship"]
    };
    public static IReadOnlyList<Objective> Plan(RouteDefinition route, GameState state,
        SpoilerLevel spoilers = SpoilerLevel.Minimal, Language language = Language.English)
    {
        var unmet = route.Requirements.Where(r => state[r.Fact] is int value && value != r.Expected).ToArray();
        // Broken conditions are explanations, not instructions to continue a blocked run.
        var invalidated = unmet.Where(r => r.Irreversible).ToArray();
        if (invalidated.Length > 0) return invalidated.Select(r => Describe(r, spoilers, language)).ToArray();
        var next = unmet.FirstOrDefault(r =>
            r.Fact != "soul_sold" && // Never suggest creating permanent history.
            (!Availability.TryGetValue(r.Fact, out var available) || state[available] == 1) &&
            (!Dependencies.TryGetValue(r.Fact, out var dependencies) || dependencies.All(fact =>
                route.Requirements.FirstOrDefault(d => d.Fact == fact) is { } dependency && state[fact] == dependency.Expected)));
        return next is null ? [] : [Describe(next, spoilers, language)];
    }
    private static Objective Describe(Requirement requirement, SpoilerLevel spoilers, Language language) =>
        new(requirement.Fact, (language, spoilers) switch
        {
            (Language.Korean, SpoilerLevel.Detailed) => requirement.KoreanDetailed,
            (Language.Korean, _) => requirement.KoreanMinimal,
            (_, SpoilerLevel.Detailed) => requirement.Detailed,
            _ => requirement.Minimal
        });
}

public sealed record PendingDecision(string Id, IReadOnlyDictionary<string, int?> Effects, bool Irreversible,
    bool AltersPermanentHistory = false);
public sealed record GuidanceResult(RouteStatus Status, bool Show, bool Dismissible, bool BlockDecision,
    string? Message, string Enforcement);

public static class DecisionMonitor
{
    public static bool BreaksRoute(RouteId route, GameState state, PendingDecision decision)
    {
        var requirements = RouteCatalog.Get(route).Requirements;
        return decision.Irreversible && requirements.Any(r => r.Irreversible && state[r.Fact] == r.Expected &&
            decision.Effects.TryGetValue(r.Fact, out var next) && next is not null && next != r.Expected);
    }
}

public static class GuidanceController
{
    // There are no verified intervention adapters yet. Forced therefore warns but never claims preservation.
    public static GuidanceResult Update(GuidanceMode mode, RouteId route, GameState state,
        PendingDecision? decision = null, bool safeToDisplay = true, SpoilerLevel spoilers = SpoilerLevel.Minimal,
        Language language = Language.English)
    {
        var evaluation = RouteEvaluator.Evaluate(route, state, spoilers, language);
        var risk = decision is not null && DecisionMonitor.BreaksRoute(route, state, decision);
        var status = evaluation.Status == RouteStatus.BLOCKED ? RouteStatus.BLOCKED : risk ? RouteStatus.AT_RISK : evaluation.Status;
        var warning = risk || status == RouteStatus.BLOCKED;
        var show = mode != GuidanceMode.Off && safeToDisplay && (mode != GuidanceMode.Passive || warning);
        var message = risk ? (language == Language.Korean ? "이 선택은 선택한 경로를 막을 수 있습니다." : "This choice may block your selected route.") :
            evaluation.Objectives.FirstOrDefault()?.Text;
        if (show && message is null)
            message = language == Language.Korean ? "아직 다음 행동을 확인할 수 없습니다." : "No next action can be verified yet.";
        return new(status, show && message is not null, mode != GuidanceMode.Forced, false,
            show ? message : null, mode == GuidanceMode.Forced ? "UNVERIFIED_NO_INTERVENTION" : "OBSERVE_ONLY");
    }
}

public static class GmlRuleEmitter
{
    // GameMaker Studio 1-compatible source. Caller provides global.rk_* normalized facts; -1 means unknown.
    // The same requirement table used above is emitted here; no game globals are assumed.
    public static string EmitEvaluator(RouteId route)
    {
        var definition = RouteCatalog.Get(route);
        var text = new StringBuilder("// Generated from RouteCatalog; do not edit.\n// Status: 0 ON_TRACK, 1 ACTION_REQUIRED, 2 AT_RISK, 3 BLOCKED, 4 UNKNOWN.\nvar rk_unknown, rk_action, rk_blocked;\nrk_unknown = 0; rk_action = 0; rk_blocked = 0;\n");
        for (var i = 0; i < definition.Requirements.Count; i++)
        {
            var r = definition.Requirements[i];
            var invalid = r.Fact == "experience" ? $"global.rk_{r.Fact} < 0" : $"global.rk_{r.Fact} < 0 || global.rk_{r.Fact} > 1";
            text.Append($"// global.rk_{r.Fact}\nif ({invalid}) rk_unknown = 1;\nelse if (global.rk_{r.Fact} != {r.Expected}) {{ rk_action = 1;");
            if (r.Irreversible) text.Append(" rk_blocked = 1;");
            text.Append(" }\n");
        }
        text.Append("if (rk_blocked) return 3;\nif (rk_unknown) return 4;\nif (rk_action) return 1;\nreturn ");
        text.Append(definition.CompleteCoverage ? "0;\n" : "4; // Partial coverage never claims full reachability.\n");
        return text.ToString();
    }
}
