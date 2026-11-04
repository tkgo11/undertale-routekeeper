using System.Text.Json;
using System.Text.Json.Serialization;

namespace RouteKeeper.Beta;

public enum TestResult { NOT_RUN, PASS, FAIL, BLOCKED, NEEDS_REVIEW, NOT_APPLICABLE }
public enum EvidenceKind { HumanReported, AutomatedObservation, IndependentlyVerifiedState, Synthetic, AuthenticGameplay, UnverifiedClaim }
public enum Risk { NonDestructive, Gameplay, HighRisk }
public sealed record LocalText(string En, string Ko)
{
    public string In(string language) => language == "ko" ? Ko : En;
}
public sealed record TestStep(string Id, LocalText Instruction, LocalText Expected);
public sealed record Scenario(string Id, int Version, string Feature, LocalText Title, LocalText Purpose,
    LocalText Preconditions, Risk Risk, string Configuration, string Source, LocalText EvidenceRequirements,
    LocalText CompletionCriteria, LocalText Reproduction, TestStep[] Steps,
    string ImplementationStatus = "PARTIAL", string AutomatedStatus = "NOT_RUN",
    string CompatibilityConfidence = "InspectedOnly");
public sealed record ScenarioCatalog(int Schema, int Version, Scenario[] Scenarios)
{
    public static ScenarioCatalog Load()
    {
        using var stream = typeof(ScenarioCatalog).Assembly.GetManifestResourceStream("RouteKeeper.Beta.scenarios.json")!;
        var value = JsonSerializer.Deserialize<ScenarioCatalog>(stream, BetaJson.Options) ?? throw new InvalidDataException("Missing scenario catalog.");
        value = ScenarioRules.Enrich(value);
        value.Validate();
        return value;
    }
    public void Validate()
    {
        if (Schema != 1 || Version < 1 || Scenarios is not { Length: > 0 and <= 300 }) throw new InvalidDataException("Unsupported scenario catalog.");
        HashSet<string> ids = [];
        foreach (var scenario in Scenarios)
        {
            if (scenario is null) throw new InvalidDataException("Null scenario.");
            ValidateToken(scenario.Id);
            if (!ids.Add(scenario.Id) || scenario.Version < 1 || !Enum.IsDefined(scenario.Risk) ||
                scenario.Steps is not { Length: > 0 and <= 50 } || string.IsNullOrWhiteSpace(scenario.Source) ||
                string.IsNullOrWhiteSpace(scenario.Feature) || string.IsNullOrWhiteSpace(scenario.Configuration) ||
                scenario.ImplementationStatus is not ("COMPLETE" or "PARTIAL") ||
                scenario.AutomatedStatus is not ("PASS" or "FAIL" or "NOT_RUN" or "BLOCKED") ||
                scenario.CompatibilityConfidence is not ("InspectedOnly" or "UNKNOWN" or "VerifiedPatch"))
                throw new InvalidDataException("Invalid scenario metadata.");
            foreach (var text in new[] { scenario.Title, scenario.Purpose, scenario.Preconditions, scenario.EvidenceRequirements, scenario.CompletionCriteria, scenario.Reproduction }) ValidateText(text);
            HashSet<string> steps = [];
            foreach (var step in scenario.Steps)
            {
                if (step is null) throw new InvalidDataException("Null step.");
                ValidateToken(step.Id);
                if (!steps.Add(step.Id)) throw new InvalidDataException("Duplicate step ID.");
                ValidateText(step.Instruction); ValidateText(step.Expected);
            }
        }
    }
    private static void ValidateText(LocalText text)
    {
        if (text is null || string.IsNullOrWhiteSpace(text.En) || string.IsNullOrWhiteSpace(text.Ko) || text.En.Length > 8000 || text.Ko.Length > 8000)
            throw new InvalidDataException("Missing or excessive translated text.");
    }
    public static void ValidateToken(string token)
    {
        if (string.IsNullOrEmpty(token) || token.Length > 80 || token.Any(c => !(c is >= 'a' and <= 'z' or >= '0' and <= '9' or '-')))
            throw new InvalidDataException("Invalid stable identifier.");
    }
}

public sealed record SessionConfiguration(string Language, string Mode, string Build, string RouteKeeperVersion, string Display = "NOT_COLLECTED")
{
    public void Validate()
    {
        if (Language is not ("en" or "ko") || Mode is not ("Off" or "Passive" or "Active" or "Forced") ||
            string.IsNullOrWhiteSpace(Build) || Build.Length > 120 || string.IsNullOrWhiteSpace(RouteKeeperVersion) ||
            RouteKeeperVersion.Length > 120 || Display is null || Display.Length > 160) throw new InvalidDataException("Invalid session configuration.");
    }
}
public sealed record StepObservation(string ScenarioId, string StepId, TestResult Result, string Actual, DateTimeOffset At,
    EvidenceKind Classification = EvidenceKind.HumanReported);
public sealed record EvidenceAttachment(string Id, string ScenarioId, string StepId, string Sha256, long Bytes,
    DateTimeOffset At, string MediaType, EvidenceKind Classification, bool ReviewedForSharing);
public sealed record BugReport(string Id, int Revision, string ScenarioId, string StepId, string Expected, string Actual,
    string Reproduction, string Severity, DateTimeOffset At, string[] EvidenceIds);
public sealed record BetaSession(int Schema, Guid Id, int Revision, string CatalogSha256, int CatalogVersion,
    DateTimeOffset Created, DateTimeOffset Updated, SessionConfiguration Configuration, string State,
    Dictionary<string, StepObservation> Observations, EvidenceAttachment[] Attachments, BugReport[] Bugs,
    string[] AuthorizedHighRiskScenarios,
    [property: JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)] NativeReceipt[]? NativeReceipts = null)
{
    public static string Key(string scenario, string step) => scenario + "/" + step;
    public TestResult Result(Scenario scenario)
    {
        var results = scenario.Steps.Select(step => Observations.GetValueOrDefault(Key(scenario.Id, step.Id))?.Result ?? TestResult.NOT_RUN).ToArray();
        if (results.Contains(TestResult.FAIL)) return TestResult.FAIL;
        if (results.Contains(TestResult.BLOCKED)) return TestResult.BLOCKED;
        if (results.Contains(TestResult.NEEDS_REVIEW)) return TestResult.NEEDS_REVIEW;
        if (results.Contains(TestResult.NOT_RUN)) return TestResult.NOT_RUN;
        if (results.All(r => r == TestResult.NOT_APPLICABLE)) return TestResult.NOT_APPLICABLE;
        return TestResult.PASS;
    }
}
public static class BetaJson
{
    public static JsonSerializerOptions Options { get; } = new()
    {
        WriteIndented = true, PropertyNameCaseInsensitive = false, MaxDepth = 32,
        UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow,
        Converters = { new JsonStringEnumConverter(allowIntegerValues: false) }
    };
}
