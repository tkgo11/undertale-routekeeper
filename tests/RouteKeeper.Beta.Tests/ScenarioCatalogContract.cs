using System.Text.Json;
using RouteKeeper.Beta;
using RouteKeeper.Core;

/// <summary>Coverage contracts for the human catalogue, not a second route-rule oracle.</summary>
public static class ScenarioCatalogContract
{
    public static int Run(ScenarioCatalog catalog)
    {
        int checks = 0;
        void Check(bool condition, string name)
        {
            if (!condition) throw new InvalidOperationException("Scenario catalog contract: " + name);
            checks++;
            Console.WriteLine("PASS catalog " + name);
        }
        catalog.Validate();
        Check(catalog.Version >= 2, "new meanings use a new catalog version");
        Check(catalog.Scenarios.Length >= 82, "complete base, route, optional-goal and epilogue inventory present");
        Check(catalog.Scenarios.Sum(s => s.Steps.Length) > 300, "route prerequisites are separate steps rather than one generic confirmation");
        for (int id = 0; id < NeutralCatalog.SelectableCount; id++)
        {
            var scenario = catalog.Scenarios.Single(s => s.Id == "neutral-" + id);
            Check(scenario.Risk == Risk.HighRisk && scenario.Source.Contains("NeutralCatalog.cs", StringComparison.Ordinal), "Neutral target" + id + " has its own grounded high-risk case");
        }
        foreach (var goal in NeutralGoals.Goals.Where(g => g.Id > 0))
        {
            var scenario = catalog.Scenarios.Single(s => s.Id == "call-goal-" + goal.Id);
            Check(scenario.Risk == Risk.HighRisk && scenario.Steps.Length >= goal.Requirements.Count + 2 && scenario.Source.Contains("NeutralGoals.cs", StringComparison.Ordinal), "call goal" + goal.Id + " records every canonical prerequisite");
        }
        foreach (var pair in new[] { (Id: "route-pacifist", Route: RouteId.TruePacifist), (Id: "route-soulless-pacifist", Route: RouteId.SoullessPacifist), (Id: "route-genocide", Route: RouteId.Genocide), (Id: "route-soulless-genocide", Route: RouteId.SoullessGenocide) })
        {
            var scenario = catalog.Scenarios.Single(s => s.Id == pair.Id);
            foreach (var requirement in RouteCatalog.Get(pair.Route).Requirements)
                Check(scenario.Steps.Any(s => s.Id == ScenarioRules.RequirementId(requirement)), pair.Id + " includes prerequisite " + requirement.Fact + "/" + requirement.GuardFact);
            foreach (var objective in ObjectiveRules.For(pair.Route))
                Check(scenario.Steps.Any(s => s.Id == "objective-" + objective.Id.Replace('_', '-')), pair.Id + " includes ordered objective " + objective.Id);
        }
        var reset = catalog.Scenarios.Single(s => s.Id == "reset");
        var trueReset = catalog.Scenarios.Single(s => s.Id == "true-reset");
        Check(reset.Risk == Risk.HighRisk && trueReset.Risk == Risk.HighRisk && !reset.Steps.SequenceEqual(trueReset.Steps), "ordinary and TRUE RESET are independently scoped scenarios");
        Check(catalog.Scenarios.Single(s => s.Id == "save-load").Risk == Risk.HighRisk, "SAVE/LOAD is separate from ordinary smoke scope");
        Check(catalog.Scenarios.Single(s => s.Id == "epilogue-stay").Risk == Risk.HighRisk && catalog.Scenarios.Single(s => s.Id == "epilogue-leave").Risk == Risk.HighRisk, "Stay and Leave are independently selectable high-risk cases");
        Check(catalog.Scenarios.Any(s => s.Id == "off") && catalog.Scenarios.Any(s => s.Id == "controller-input"), "Off and supported controller integration are represented");
        Check(catalog.Scenarios.All(s => s.Steps.All(step => !step.Instruction.Ko.Contains("아래 영문", StringComparison.Ordinal) && !step.Instruction.Ko.Contains(step.Instruction.En, StringComparison.Ordinal) && !step.Expected.Ko.Contains(step.Expected.En, StringComparison.Ordinal))), "Korean instructions and expectations are translated rather than English-spliced placeholders");
        Check(catalog.Scenarios.All(s => s.Steps.All(step => !step.Instruction.En.Contains("{remaining}", StringComparison.Ordinal) && !step.Instruction.Ko.Contains("{remaining}", StringComparison.Ordinal))), "unobserved current population is not replaced with a fabricated remaining count");
        Check(catalog.Scenarios.All(s => s.AutomatedStatus == "NOT_RUN" && s.CompatibilityConfidence is "InspectedOnly" or "UNKNOWN"), "catalogue coverage never fabricates automated gameplay or compatibility evidence");
        var unknownCase = catalog.Scenarios.Single(s => s.Id == "call-goal-8");
        Check(unknownCase.Steps.Any(step => step.Id == "unresolved-combination" && step.Expected.En.Contains("UNKNOWN", StringComparison.Ordinal) && step.Expected.Ko.Contains("UNKNOWN", StringComparison.Ordinal)), "unresolved target6/call8 remains explicitly UNKNOWN in both languages");
        var state = GameState.From(("neutral_papyrus_dead", 0), ("healing_items_used", 0), ("level", 1), ("equipped_armor", 4));
        Check(NeutralGoals.Evaluate(8, 6, state).Status == RouteStatus.UNKNOWN, "canonical unresolved combination is not promoted by catalogue generation");
        Check(JsonSerializer.Serialize(ScenarioRules.Enrich(catalog), BetaJson.Options) == JsonSerializer.Serialize(catalog, BetaJson.Options), "Core enrichment is deterministic and idempotent");
        Console.WriteLine($"PASS: {checks} scenario catalogue contracts; {catalog.Scenarios.Length} scenarios/{catalog.Scenarios.Sum(s => s.Steps.Length)} independently recordable steps; gameplay NOT_RUN.");
        return checks;
    }
}
