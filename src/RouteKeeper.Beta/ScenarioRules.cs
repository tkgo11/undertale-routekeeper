using System.Globalization;
using RouteKeeper.Core;

namespace RouteKeeper.Beta;

/// <summary>
/// Presents existing Core requirements as human checklists. It neither evaluates
/// new game rules nor collects/invents raw state mappings or gameplay evidence.
/// The enriched catalog hash binds the exact current Core text/table snapshot.
/// </summary>
public static class ScenarioRules
{
    private static readonly IReadOnlyDictionary<string, RouteId> Routes = new Dictionary<string, RouteId>
    {
        ["route-pacifist"] = RouteId.TruePacifist,
        ["route-soulless-pacifist"] = RouteId.SoullessPacifist,
        ["route-genocide"] = RouteId.Genocide,
        ["route-soulless-genocide"] = RouteId.SoullessGenocide
    };

    public static ScenarioCatalog Enrich(ScenarioCatalog catalog)
    {
        ArgumentNullException.ThrowIfNull(catalog);
        var scenarios = catalog.Scenarios.Select(s =>
        {
            if (Routes.TryGetValue(s.Id, out var route)) return Route(s, route);
            if (s.Id.StartsWith("neutral-", StringComparison.Ordinal) && int.TryParse(s.Id[8..], NumberStyles.None, CultureInfo.InvariantCulture, out int target) && target is >= 0 and < NeutralCatalog.SelectableCount)
                return Neutral(s, NeutralCatalog.Get(target));
            return s;
        }).ToList();

        var template = scenarios.Single(s => s.Id == "neutral-1");
        if (!scenarios.Any(s => s.Id == "neutral-0"))
            scenarios.Add(Neutral(template with { Id = "neutral-0" }, NeutralCatalog.Get(0)));
        foreach (var goal in NeutralGoals.Goals.Where(g => g.Id > 0))
        {
            string id = "call-goal-" + goal.Id.ToString(CultureInfo.InvariantCulture);
            var existing = scenarios.FindIndex(s => s.Id == id);
            var enriched = Goal(template with { Id = id }, goal);
            if (existing < 0) scenarios.Add(enriched); else scenarios[existing] = enriched;
        }
        return catalog with { Scenarios = scenarios.ToArray() };
    }

    private static Scenario Route(Scenario scenario, RouteId route)
    {
        var definition = RouteCatalog.Get(route);
        List<TestStep> steps =
        [
            Step("select-target", "In the separately authorized disposable trial select this route and the intended mode. Read the existing SOUL-history requirement; do not create, erase or sell a SOUL for this test.",
                "별도로 승인한 일회용 시험에서 이 경로와 의도한 모드를 선택하세요. 기존 SOUL 기록 조건을 읽고 이 시험을 위해 영혼을 만들거나 지우거나 팔지 마세요.",
                "Displayed target/mode match the session configuration. Existing permanent history is observed, never repaired by ROUTEKEEPER.",
                "화면의 목표·모드가 세션 설정과 일치해야 합니다. 기존 영구 기록을 관찰할 뿐 ROUTEKEEPER가 고치면 안 됩니다.")
        ];
        foreach (var requirement in definition.Requirements)
        {
            string id = RequirementId(requirement);
            string deadlineEn = requirement.GuardFact is null ? "" : " A future prerequisite is not declared irreversibly missed before its source-backed resolution deadline.";
            string deadlineKo = requirement.GuardFact is null ? "" : " 원본 근거가 있는 해결 시점 전에는 미래 선행 조건을 비가역 실패로 단정하지 마세요.";
            steps.Add(Step(id,
                "At the relevant story/decision point check this existing prerequisite: " + requirement.Detailed + " Record what was actually observed; leave unavailable facts UNKNOWN." + deadlineEn,
                "해당 이야기·결정 시점에서 기존 선행 조건을 확인하세요: " + requirement.KoreanDetailed + " 실제 관찰을 기록하고 알 수 없는 사실은 UNKNOWN으로 남기세요." + deadlineKo,
                (requirement.Irreversible ? "A supported irreversible violation is reported before/at its documented boundary. " : "Guidance respects the prerequisite's availability and dependencies. ") + "No personal history or game facts are fabricated to make the condition pass.",
                (requirement.Irreversible ? "지원하는 비가역 위반을 문서화한 경계 전·시점에 알려야 합니다. " : "선행 조건의 가능 여부와 의존 관계를 반영하여 안내해야 합니다. ") + "조건을 통과시키려고 개인 기록·게임 사실을 만들어내면 안 됩니다."));
        }
        foreach (var objective in ObjectiveRules.For(route))
        {
            string en = objective.CountFact is null ? objective.Detailed :
                "Check the displayed remaining population in " + Area(objective.CountFact, false) + " against the source quota of " + objective.Quota.ToString(CultureInfo.InvariantCulture) + ". Do not confuse a battle's pending kills with settled regional population.";
            string ko = objective.CountFact is null ? objective.KoreanDetailed :
                Area(objective.CountFact, true) + "의 표시된 남은 개체 수를 원본 할당량 " + objective.Quota.ToString(CultureInfo.InvariantCulture) + "과 대조하세요. 전투의 미정산 처치와 정산된 지역 개체 수를 혼동하지 마세요.";
            steps.Add(Step("objective-" + objective.Id.Replace('_', '-'),
                "When this source-backed objective becomes available, follow and inspect it: " + en,
                "원본 근거가 있는 이 목표를 진행할 수 있을 때 지침과 표시를 확인하세요: " + ko,
                "The displayed objective follows the current available prerequisite/order, not a guessed fixed scene, RNG result or guaranteed combat victory.",
                "추정한 고정 화면·난수 결과·보장된 전투 승리가 아니라 현재 가능한 선행 조건·순서에 맞춰 목표를 표시해야 합니다."));
        }
        steps.Add(Step("ending-observation", "Separately record the actual ending/choice observed and the last route status. Distinguish eligibility guidance from an ending that actually played.",
            "실제로 관찰한 엔딩·선택과 마지막 경로 상태를 따로 기록하세요. 엔딩 가능 여부 안내와 실제 엔딩 재생을 구별하세요.",
            "Human observation remains HumanReported. Unknown state or lack of independent live observations never becomes an independently verified ending PASS.",
            "사람의 관찰은 사람이 보고한 결과로 남겨야 합니다. 알 수 없는 상태·독립 실시간 관찰 부재를 독립 검증 엔딩 PASS로 바꾸면 안 됩니다."));
        return scenario with
        {
            Version = 2, Feature = "Routes", Risk = Risk.HighRisk,
            Source = "src/RouteKeeper.Core/Engine.cs; src/RouteKeeper.Core/Objectives.cs; docs/route-rules.md; profiles/bindings.json",
            Configuration = route + "; exact inspected build; separately authorized disposable progression / 정확한 검사 빌드·별도 승인한 일회용 진행",
            Purpose = new("Verify every declared prerequisite, availability objective and observed ending for this route using the same Core inventory as the mod.", "모드와 같은 Core 목록으로 이 경로의 모든 선언된 선행 조건·가능 목표·관찰 엔딩을 확인합니다."),
            Steps = steps.ToArray()
        };
    }

    private static Scenario Neutral(Scenario scenario, NeutralTarget target)
    {
        int id = (int)target.Id;
        List<TestStep> steps =
        [
            Step("select-target", "Select Neutral target " + id.ToString(CultureInfo.InvariantCulture) + " (" + target.English + ") and No extra goal for this base-variant check.",
                "기본 변형 검사에서 중립 목표 " + id.ToString(CultureInfo.InvariantCulture) + "(" + target.Korean + ")와 추가 목표 없음을 선택하세요.",
                "The exact selected variant is shown; Any Neutral is a broad target, not a promise of one particular phone variant.",
                "정확한 선택 변형을 표시해야 합니다. 아무 중립 엔딩 목표는 특정 전화 변형 하나를 보장하는 것이 아닙니다."),
            Step("ordinary-route-scope", "Check the observed world/Hard Mode/True Lab/full-Genocide commitments before judging ordinary Neutral eligibility.",
                "일반 중립 가능 여부를 판단하기 전에 관찰한 세계·하드모드·진실의 연구소·완전 몰살 확정 상태를 확인하세요.",
                "An erased world, Hard Mode, committed True Pacifist or full Genocide is not mislabelled as an ordinary Neutral route; missing facts stay UNKNOWN.",
                "소멸한 세계·하드모드·확정 평화·완전 몰살을 일반 중립 경로로 잘못 표시하면 안 됩니다. 누락 사실은 UNKNOWN으로 남겨야 합니다.")
        ];
        foreach (var boss in new[] { (Id: "toriel", En: "Toriel", Ko: "토리엘", Dead: target.TorielDead), (Id: "papyrus", En: "Papyrus", Ko: "파피루스", Dead: target.PapyrusDead), (Id: "undyne", En: "Undyne", Ko: "언다인", Dead: target.UndyneDead), (Id: "mettaton", En: "Mettaton", Ko: "메타톤", Dead: target.MettatonDead) })
        {
            if (boss.Dead is not int dead) continue;
            steps.Add(Step("outcome-" + boss.Id,
                "At " + boss.En + "'s relevant encounter preserve the selected outcome: " + (dead == 0 ? "alive/spared." : "defeated/dead.") + " Inspect guidance both before the commitment and after its resolution.",
                boss.Ko + "의 해당 전투에서 선택 결과(" + (dead == 0 ? "생존·살려주기" : "처치·사망") + ")를 유지하세요. 확정 전과 해결 후의 안내를 확인하세요.",
                "The target's declared boss outcome is used with its resolution deadline; a future required death is not mistaken for an already missed deadline.",
                "목표의 선언된 보스 결과와 해결 시점을 함께 사용해야 합니다. 미래에 필요한 사망을 이미 놓친 시점으로 오인하면 안 됩니다."));
        }
        string rangeEn = "at least " + target.MinimumKills.ToString(CultureInfo.InvariantCulture) + (target.MaximumKills == int.MaxValue ? " with no declared finite upper bound" : " and at most " + target.MaximumKills.ToString(CultureInfo.InvariantCulture));
        string rangeKo = "최소 " + target.MinimumKills.ToString(CultureInfo.InvariantCulture) + (target.MaximumKills == int.MaxValue ? ", 선언된 유한 상한 없음" : ", 최대 " + target.MaximumKills.ToString(CultureInfo.InvariantCulture));
        steps.Add(Step("total-kill-range", "Inspect the observed total-kill requirement: " + rangeEn + ". Counts include the applicable boss kills; do not subtract an invented four-boss allowance.",
            "관찰한 총 처치 수 조건(" + rangeKo + ")을 확인하세요. 해당 보스 처치도 포함하며 임의의 네 보스 허용분을 빼면 안 됩니다.",
            "Guidance and ending prediction use the canonical total-kill bounds; a counter prediction is not an observed ending.",
            "원래 총 처치 범위를 사용해 안내·엔딩을 예측해야 합니다. 수치 예측을 관찰한 엔딩으로 처리하면 안 됩니다."));
        if (NeutralCatalog.FriendshipMinimum(id) > 0 || id is 2 or 3)
            steps.Add(Step("friendship-order", "Inspect the selected friendship/betrayal branch before and after any separately authorized additional kill. Follow the existing target's friendship order rather than inventing a new requirement.",
                "별도로 승인한 추가 처치 전후에 선택한 우정·배신 분기를 확인하세요. 새 조건을 만들어내지 말고 기존 목표의 우정 순서를 따르세요.",
                "Family/befriended/unbefriended branches remain distinct and irreversible friendship/kill history is not repaired.",
                "가족·친분 있음·친분 없음 분기를 구별해야 하며 비가역 우정·처치 기록을 고치면 안 됩니다."));
        if (id == 18)
            steps.Add(Step("late-abandonment", TextCatalog.Get("guidance.follow_genocide_through_waterfall_then_abandon_it_in_hotland", "en"),
                TextCatalog.Get("guidance.follow_genocide_through_waterfall_then_abandon_it_in_hotland", "ko"),
                "The original late-abandonment override is used; an ordinary EX outcome cannot substitute for the source-backed NEO/history branch.",
                "원본의 후반 포기 우선 분기를 사용해야 합니다. 일반 EX 결과로 원본 근거 NEO·기록 분기를 대신하면 안 됩니다."));
        steps.Add(Step("phone-observation", "At the separately authorized ending record the actual phone family/variant and the displayed target eligibility. Record spoken-slot observations separately from optional conditions.",
            "별도로 승인한 엔딩에서 실제 전화 계열·변형과 표시 목표 가능 여부를 기록하세요. 대사 슬롯 관찰과 선택 조건을 따로 기록하세요.",
            "A source-selected prediction is not proof of a reachable playthrough or an exclusive spoken line. Compound target6/call-goal8 remains UNKNOWN where its global reachability is unresolved.",
            "원본 선택 예측을 실제 도달 가능한 플레이·배타적 대사 증거로 처리하면 안 됩니다. 전체 도달 여부가 미해결인 목표6·통화 목표8 조합은 UNKNOWN으로 유지해야 합니다."));
        return scenario with
        {
            Version = 2, Feature = "Neutral", Risk = Risk.HighRisk,
            Title = new("Neutral — " + target.English, "중립 — " + target.Korean),
            Purpose = new("Verify the selected canonical Neutral target and each declared boss/count/friendship requirement without equating prediction with an observed ending.", "선택한 원래 중립 목표의 보스·처치 수·우정 조건을 확인하되 예측과 실제 관찰 엔딩을 동일시하지 않습니다."),
            Configuration = "Neutral target " + id.ToString(CultureInfo.InvariantCulture) + "; call goal0 / 중립 목표·추가 통화 목표 없음",
            Source = "src/RouteKeeper.Core/NeutralCatalog.cs; docs/route-rules.md; tests/golden/original-endings.json",
            Steps = steps.ToArray()
        };
    }

    private static Scenario Goal(Scenario template, NeutralGreetingGoal goal)
    {
        List<TestStep> steps =
        [
            Step("compatible-target", "Select call goal " + goal.Id.ToString(CultureInfo.InvariantCulture) + " (" + goal.English + ") with a canonical compatible Neutral target: " + string.Join(", ", goal.CompatibleTargets) + ".",
                "통화 목표 " + goal.Id.ToString(CultureInfo.InvariantCulture) + "(" + goal.Korean + ")와 원래 호환 중립 목표(" + string.Join(", ", goal.CompatibleTargets) + ")를 선택하세요.",
                "Compatible choices are available; an incompatible target reports the conflict rather than promising an unattainable call.",
                "호환 선택을 사용할 수 있어야 하며 비호환 목표는 불가능한 통화를 약속하지 않고 충돌을 알려야 합니다.")
        ];
        for (int index = 0; index < goal.Requirements.Count; index++)
        {
            var requirement = goal.Requirements[index];
            string deadlineEn = requirement.Deadline is null ? "" : " Check this before and after the source-backed encounter-resolution deadline.";
            string deadlineKo = requirement.Deadline is null ? "" : " 원본 근거 전투 해결 시점 전후에 확인하세요.";
            steps.Add(Step("condition-" + (index + 1).ToString(CultureInfo.InvariantCulture),
                "Check this existing call condition in the authorized trial: " + requirement.English + deadlineEn,
                "승인한 시험에서 기존 통화 조건을 확인하세요: " + requirement.Korean + deadlineKo,
                "At least one canonical alternative must hold: " + Alternatives(requirement, false) + ". Unobserved facts remain unknown; permanent violations are not silently repaired.",
                "원래 대안 중 하나 이상을 충족해야 합니다: " + Alternatives(requirement, true) + ". 관찰하지 않은 사실은 미확인으로 남기고 영구 위반을 조용히 고치면 안 됩니다."));
        }
        if (goal.Id == 8)
            steps.Add(Step("unresolved-combination", "Inspect the compound target6/call-goal8 case through its source-backed synthetic diagnostic; do not manufacture a playthrough witness.",
                "원본 근거 합성 진단으로 목표6·통화 목표8 조합을 확인하세요. 플레이 도달 증거를 만들어내지 마세요.",
                "The unresolved global combination stays UNKNOWN even when a plausible selector-state fixture satisfies individual values.",
                "그럴듯한 선택 상태 자료의 개별 값이 맞더라도 전체 조합의 미해결 도달 여부는 UNKNOWN으로 남아야 합니다."));
        steps.Add(Step("condition-versus-dialogue", "Record the actual observed call and which optional conditions were satisfied. Inspect any shared/overwritten dialogue slots separately.",
            "실제로 관찰한 통화와 만족한 선택 조건을 기록하고 공유·덮어쓴 대사 슬롯은 따로 확인하세요.",
            "Condition satisfaction does not promise one exclusive spoken line; shared-slot precedence remains the original game's behavior.",
            "조건 만족이 배타적 대사 한 줄을 보장하면 안 됩니다. 공유 슬롯의 우선순위는 원본 게임 동작을 따라야 합니다."));
        return template with
        {
            Id = "call-goal-" + goal.Id.ToString(CultureInfo.InvariantCulture), Version = 2, Feature = "NeutralCallGoals", Risk = Risk.HighRisk,
            Title = new("Optional call — " + goal.English, "선택 통화 — " + goal.Korean),
            Purpose = new("Verify every canonical prerequisite of this selectable call condition, compatibility and shared-dialogue limitations.", "선택 가능한 이 통화 조건의 모든 원래 선행 조건·호환성·공유 대사 한계를 확인합니다."),
            Configuration = "Call goal " + goal.Id.ToString(CultureInfo.InvariantCulture) + "; compatible Neutral targets " + string.Join(",", goal.CompatibleTargets) + " / 호환 중립 목표와 선택 통화 조건",
            Source = "src/RouteKeeper.Core/NeutralGoals.cs; src/RouteKeeper.Core/NeutralCatalog.cs; docs/route-rules.md; docs/ending-audit.md",
            Steps = steps.ToArray()
        };
    }

    private static string Alternatives(GreetingRequirement requirement, bool korean) => string.Join(korean ? " 또는 " : " OR ", requirement.Alternatives.Select(a =>
        "(" + string.Join(korean ? " 및 " : " AND ", a.Tests.Select(t => Fact(t.Fact, korean) + " " + Operator(t.Comparison) + " " + t.Expected.ToString(CultureInfo.InvariantCulture))) + ")"));
    private static string Operator(Comparison comparison) => comparison switch { Comparison.AtLeast => ">=", Comparison.AtMost => "<=", _ => "=" };
    public static string RequirementId(Requirement requirement) => "require-" + requirement.Fact.Replace('_', '-') +
        (requirement.GuardFact is null ? "" : "-when-" + requirement.GuardFact.Replace('_', '-'));
    private static string Fact(string id, bool korean)
    {
        if (!korean) return id.Replace('_', ' ');
        return id switch
        {
            "neutral_toriel_dead" => "토리엘 사망 여부", "neutral_papyrus_dead" => "파피루스 사망 여부", "neutral_undyne_dead" => "언다인 사망 여부", "neutral_mettaton_dead" => "메타톤 사망 여부",
            "water_opportunity_missed" => "물 제공 기회 상실 여부", "kills" => "총 처치 수", "neutral_undyne_friendship" => "언다인 우정 진행값", "neutral_alphys_friendship" => "알피스 우정 진행값",
            "murder_level" => "몰살 단계", "snowman_piece_carried" => "눈사람 조각 소지 여부", "keepsake_recoverable" => "기념품 회수 가능 여부", "save_exists" => "일반 SAVE 존재 여부",
            "equipped_armor" => "착용 방어구 원본 ID", "healing_items_used" => "회복 아이템 사용 기록", "level" => "LV", _ => id
        };
    }
    private static string Area(string fact, bool korean) => fact switch
    {
        "kills_ruins" => korean ? "유적" : "the Ruins", "kills_snowdin" => korean ? "스노우딘" : "Snowdin",
        "kills_waterfall" => korean ? "워터폴" : "Waterfall", "kills_hotland_core" => korean ? "핫랜드·CORE" : "Hotland/CORE", _ => fact
    };
    private static TestStep Step(string id, string en, string ko, string expectedEn, string expectedKo) => new(id, new(en, ko), new(expectedEn, expectedKo));
}
