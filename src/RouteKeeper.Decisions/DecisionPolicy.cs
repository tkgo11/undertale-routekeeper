using System.Text;

namespace RouteKeeper.Decisions;

public enum RouteFamily { Pacifist, Genocide, Neutral }
public enum DecisionAction { Fight = 1, Spare, Flee, LeaveWaterRoom, EnterBoss, ChooseEpilogue, StartFriendship, ScriptedSpare = 12 }
public enum DecisionEnemy { Ordinary, Toriel, Papyrus, Undyne, Mettaton, UndyneUndying, RequiredUnique, MettatonNeo, MonsterKid, Snowdrake }
public enum DecisionMode { Off, Passive, Active, Forced }
public enum WarningCode { None, ExperienceRisk, WaterDeparture, RegionalQuota, RequiredEncounter, NeutralSurvival, NeutralDefeat, NeutralKillCap, RegionalPrerequisites, Epilogue, Friendship, SnowdrakeOpportunity, UnwantedFriendship, NeverSave, HealingItem, LastKeepsake, StartingArmor, LevelIncrease, CallExperience, NeutralLab, AutomaticSpare }
public sealed record DecisionState(RouteFamily Family, DecisionAction Action, DecisionEnemy Enemy,
    bool ExperienceRisk = false, int RuinsKills = 0, int SnowdinKills = 0, int WaterfallKills = 0,
    int HotlandKills = 0, bool WaterUnresolved = false, int NeutralOutcome = 0, bool NeutralKillCapReached = false,
    bool RequiredEncounter = false, bool EpilogueMismatch = false, bool RegionalPrerequisitesMissing = false, bool NeutralFriendshipPending = false, bool LastSnowdrakeOpportunity = false, bool ForbiddenFriendship = false, bool RouteBlocked = false)
{
    public int[] Values => [(int)Family, (int)Action, (int)Enemy, ExperienceRisk ? 1 : 0,
        RuinsKills, SnowdinKills, WaterfallKills, HotlandKills, WaterUnresolved ? 1 : 0,
        NeutralOutcome, NeutralKillCapReached ? 1 : 0, RequiredEncounter ? 1 : 0, EpilogueMismatch ? 1 : 0, RegionalPrerequisitesMissing ? 1 : 0, (Action == DecisionAction.StartFriendship ? ForbiddenFriendship : NeutralFriendshipPending) ? 1 : 0, LastSnowdrakeOpportunity ? 1 : 0];
}
public sealed record DecisionResponse(bool Refuse, WarningCode Warning, bool AcknowledgementConsumed, bool Intervention);

/// <summary>Source-validated pre-action refusal policy; never mutates EXP, death flags, or history.</summary>
public static class DecisionPolicy
{
    private sealed record Test(int Argument, string Operator, int Value)
    {
        public bool Matches(int[] values) => Operator switch
        {
            "==" => values[Argument] == Value,
            "<" => values[Argument] < Value,
            _ => throw new InvalidOperationException("Unsupported predicate")
        };
        public string Gml => $"argument{Argument} {Operator} {Value}";
    }
    private sealed record Rule(WarningCode Warning, Test[] Tests)
    {
        public bool Matches(int[] values) => Tests.All(t => t.Matches(values));
    }
    private static Test Eq(int argument, int value) => new(argument, "==", value);
    private static Test Lt(int argument, int value) => new(argument, "<", value);
    private static Rule R(WarningCode warning, params Test[] tests) => new(warning, tests);
    private static readonly Rule[] Rules = [
        R(WarningCode.AutomaticSpare, Eq(0,2), Eq(1,12), Eq(9,-1)),
        R(WarningCode.UnwantedFriendship, Eq(0,2), Eq(1,7), Eq(14,1)),
        R(WarningCode.SnowdrakeOpportunity, Eq(0,1), Eq(1,1), Eq(3,1), Eq(15,1)),
        R(WarningCode.Friendship, Eq(0,2), Eq(1,1), Eq(3,1), Eq(14,1)),
        R(WarningCode.WaterDeparture, Eq(0,2), Eq(1,4), Eq(8,1), Eq(14,1)),
        R(WarningCode.Epilogue, Eq(0,0), Eq(1,6), Eq(12,1)),
        R(WarningCode.ExperienceRisk, Eq(0,0), Eq(1,1), Eq(3,1)),
        R(WarningCode.WaterDeparture, Eq(0,0), Eq(1,4), Eq(8,1)),
        // Toriel's own kill can be the twentieth Ruins kill.
        R(WarningCode.RegionalQuota, Eq(0,1), Eq(1,1), Eq(2,1), Lt(4,19)),
        R(WarningCode.RegionalQuota, Eq(0,1), Eq(1,1), Eq(2,2), Lt(5,16)),
        R(WarningCode.RegionalQuota, Eq(0,1), Eq(1,1), Eq(2,5), Lt(6,18)),
        R(WarningCode.RegionalQuota, Eq(0,1), Eq(1,1), Eq(2,8), Lt(6,18)),
        R(WarningCode.RegionalQuota, Eq(0,1), Eq(1,1), Eq(2,7), Lt(7,40)),
        R(WarningCode.RegionalQuota, Eq(0,1), Eq(1,5), Eq(2,1), Lt(4,19)),
        R(WarningCode.RegionalQuota, Eq(0,1), Eq(1,5), Eq(2,2), Lt(5,16)),
        R(WarningCode.RegionalQuota, Eq(0,1), Eq(1,5), Eq(2,8), Lt(6,18)),
        R(WarningCode.RegionalQuota, Eq(0,1), Eq(1,5), Eq(2,7), Lt(7,40)),
        R(WarningCode.RegionalPrerequisites, Eq(0,1), Eq(1,5), Eq(13,1)),
        R(WarningCode.RequiredEncounter, Eq(0,1), Eq(1,2), Eq(11,1)),
        R(WarningCode.RequiredEncounter, Eq(0,1), Eq(1,3), Eq(11,1)),
        R(WarningCode.NeutralSurvival, Eq(0,2), Eq(1,1), Eq(9,1)),
        R(WarningCode.NeutralDefeat, Eq(0,2), Eq(1,2), Eq(9,-1)),
        R(WarningCode.NeutralKillCap, Eq(0,2), Eq(1,1), Eq(10,1), Eq(3,1))
    ];

    public static WarningCode Risk(DecisionState state)
    {
        if (!Enum.IsDefined(state.Family) || !Enum.IsDefined(state.Action) || !Enum.IsDefined(state.Enemy))
            throw new ArgumentOutOfRangeException(nameof(state));
        var values = state.Values;
        return Rules.FirstOrDefault(r => r.Matches(values))?.Warning ?? WarningCode.None;
    }

    public static DecisionResponse BeforeAction(DecisionMode mode, DecisionState state,
        bool acknowledged = false, bool sourceValidatedAdapter = true)
    {
        if (!Enum.IsDefined(mode)) throw new ArgumentOutOfRangeException(nameof(mode));
        if (mode == DecisionMode.Off || !sourceValidatedAdapter || state.RouteBlocked) return new(false, WarningCode.None, false, false);
        var warning = Risk(state);
        if (warning == WarningCode.None) return new(false, warning, false, false);
        // A quota cannot be repaired from an already active boss battle. Only the
        // pre-encounter adapter can enforce it while backtracking is still possible.
        var enforceable = CanEnforce((int)warning,(int)state.Action,(int)state.Family,0,0);
        if (mode == DecisionMode.Forced && enforceable) return new(true, warning, false, true);
        return new(!acknowledged, warning, acknowledged, false);
    }

    public static bool RequiresDefeat(DecisionEnemy enemy, DecisionAction action, int snowdinKills = 0, bool snowdrakeKilled = false)
    {
        if (!Enum.IsDefined(enemy) || !Enum.IsDefined(action)) throw new ArgumentOutOfRangeException(nameof(enemy));
        if (enemy == DecisionEnemy.Snowdrake && action is DecisionAction.Spare or DecisionAction.Flee && snowdinKills >= 16 && !snowdrakeKilled) return true;
        // Snowdrake can be encountered again until the population is exhausted;
        // one-time unique encounters set the abandonment flag on removal.
        return action == DecisionAction.Flee ? enemy == DecisionEnemy.RequiredUnique : enemy is not (DecisionEnemy.Ordinary or DecisionEnemy.Snowdrake);
    }
    public static string EmitRequiredGml() => "// Generated one-time encounter classification.\nif (argument0 == 9 && argument2 >= 16 && argument3 == 0 && (argument1 == 2 || argument1 == 3)) return 1;\nif (argument1 == 3) return argument0 == 6;\nreturn argument0 > 0 && argument0 != 9;\n";

    // Authentic scr_itemuseb dispatches Spider Donut/Cider to Muffet's user event 6.
    // Treat that route-ending item action like Spare, before consumption or healing.
    public static bool ItemResolvesRequiredEncounter(int itemId, bool muffetPresent, bool lastDogi = false) => (muffetPresent && itemId is 7 or 10) || (lastDogi && itemId == 3);
    public static string EmitItemGml() => "// Generated item escape classification; source-validated Muffet and last-Dogi paths.\nreturn (argument1 && (argument0 == 7 || argument0 == 10)) || (argument2 && argument0 == 3);\n";

    public static bool ActResolvesRequiredEncounter(bool shyrenPresent, int command, int encouragement) => shyrenPresent && command == 1 && encouragement == 4;
    public static string EmitActGml() => "// Generated final Shyren Hum classification; ordinary ACT remains available.\nreturn argument0 && argument1 == 1 && argument2 == 4;\n";

    public static bool SnowdrakeActMayResolve(int command,bool lastLive)=>command==1&&lastLive;
    public static string EmitSnowActGml()=>"// Generated possible random Snowdrake escape, only the last live encounter.\nreturn argument0 == 1 && argument1;\n";

    // Original EX Step checks the scheduled turn index, not limb visibility.
    // 0 original resolution, 1 wait for acknowledgement, 2 take original attack path.
    public static int RatingResolution(DecisionMode mode,bool refused)=>!refused?0:mode==DecisionMode.Forced?2:1;
    public static string EmitRatingResolutionGml()=>"// Generated scripted outcome disposition; does not change ratings/HP/history.\nif (argument1 == 0) return 0;\nif (argument0 == 3) return 2;\nreturn 1;\n";
    public static bool CanEnforce(int risk,int action,int family,int neutral,int goal)=>!(risk==3&&action==1)&&!(risk==17&&family==2&&goal==8&&neutral==6);
    public static string EmitEnforceableGml()=>"// Generated scoped enforcement; uncertain compound LV1 remains advisory.\nif (argument0 == 3 && argument1 == 1) return 0;\nif (argument0 == 17 && argument2 == 2 && argument4 == 8 && argument3 == 6) return 0;\nreturn 1;\n";
    public static bool RatingQualifies(int turns,int ratings)=>turns>=19?ratings>=10000:ratings>=12000;
    public static string EmitRatingsGml()=>"// Source-audited EX turn-boundary threshold.\nif (argument0 >= 19) return argument1 >= 10000;\nreturn argument1 >= 12000;\n";

    public static bool ExhaustedKillBudget(int kills, int maximumKills, int reservedBossKills, bool requiredBossKill)
    {
        if (kills < 0 || reservedBossKills < 0 || maximumKills < -1) throw new ArgumentOutOfRangeException(nameof(kills));
        return maximumKills >= 0 && !requiredBossKill && (long)kills + reservedBossKills >= maximumKills;
    }
    public static string EmitBudgetGml() => "// Generated kill budget; reserve future required bosses before optional kills.\nreturn argument1 >= 0 && !argument3 && argument0 + argument2 >= argument1;\n";

    public static string EmitGml()
    {
        var source = new StringBuilder("// Generated from DecisionPolicy. Source-level policy, not runtime certification.\n");
        source.Append("// args: family,action,enemy,xpRisk,ruins,snowdin,waterfall,hotland,waterPending,neutralOutcome,killCap,requiredEncounter,epilogueMismatch,regionalPrerequisitesMissing,neutralFriendshipPending,lastSnowdrakeOpportunity.\n");
        foreach (var rule in Rules)
            source.Append($"if ({string.Join(" && ", rule.Tests.Select(t => t.Gml))}) return {(int)rule.Warning};\n");
        source.Append("return 0;\n");
        return source.ToString();
    }
}
