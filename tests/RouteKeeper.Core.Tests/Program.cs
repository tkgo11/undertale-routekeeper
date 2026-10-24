using RouteKeeper.Core;

if (args is ["--emit-gml", var path])
{
    Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path))!);
    File.WriteAllText(path, GmlRuleEmitter.EmitEvaluator(RouteId.TruePacifist));
    return;
}

if (args is ["--verify-gml", var sourcePath])
{
    var expected = GmlRuleEmitter.EmitEvaluator(RouteId.TruePacifist).Replace("\r\n", "\n");
    var actual = File.ReadAllText(sourcePath).Replace("\r\n", "\n");
    if (expected != actual) throw new InvalidOperationException("Checked-in GML differs from RouteCatalog; regenerate it.");
    Console.WriteLine("PASS checked-in GML matches shared route rules");
    return;
}

var failures = new List<string>();
var count = 0;
void Check(string name, Action assertion)
{
    count++;
    try { assertion(); Console.WriteLine("PASS " + name); }
    catch (Exception e) { failures.Add(name + ": " + e.Message); Console.WriteLine("FAIL " + name); }
}
void Assert(bool condition, string message = "Assertion failed") { if (!condition) throw new Exception(message); }
GameState Candidate() => new(RouteCatalog.Get(RouteId.TruePacifist).Requirements.ToDictionary(r => r.Fact, r => (int?)r.Expected).Concat(new Dictionary<string, int?> { ["papyrus_hangout_available"] = 1, ["undyne_hangout_available"] = 1, ["alphys_date_available"] = 1, ["true_lab_available"] = 1 }).ToDictionary(x => x.Key, x => x.Value));
GameState With(GameState state, string key, int? value) => new(new Dictionary<string, int?>(state.Facts) { [key] = value });

Check("Unknown facts never imply success", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, GameState.From()).Status == RouteStatus.UNKNOWN));
Check("Invalid observations remain unknown", () => {
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "experience", -1)).Status == RouteStatus.UNKNOWN);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "papyrus_alive", 2)).Status == RouteStatus.UNKNOWN);
});
Check("Partial coverage remains visible", () => {
    var result = RouteEvaluator.Evaluate(RouteId.TruePacifist, Candidate());
    Assert(result.Status == RouteStatus.UNKNOWN && !result.CompleteCoverage && result.Reasons.Contains("coverage:partial"));
});
Check("EXP invalidates pacifist even with unknown prerequisites", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, GameState.From(("experience", 1))).Status == RouteStatus.BLOCKED));
Check("Missing friendship requires action instead of reset", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "papyrus_friendship", 0)).Status == RouteStatus.ACTION_REQUIRED));
Check("Missed water opportunity invalidates current run", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "water_opportunity_missed", 1)).Status == RouteStatus.BLOCKED));
Check("Unknown history prevents an unaltered ending guarantee", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "soul_sold", null)).Status == RouteStatus.UNKNOWN));
Check("Sold soul distinguishes pacifist variants", () => {
    var state = With(Candidate(), "soul_sold", 1);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Status == RouteStatus.BLOCKED);
    Assert(RouteEvaluator.Evaluate(RouteId.SoullessPacifist, state).Status == RouteStatus.UNKNOWN);
    Assert(state["soul_sold"] == 1);
});
Check("Minimal spoilers hide named friends", () => {
    var state = With(Candidate(), "papyrus_friendship", 0);
    Assert(!RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Objectives[0].Text.Contains("Papyrus"));
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state, SpoilerLevel.Detailed).Objectives[0].Text.Contains("Papyrus"));
});
Check("Korean objectives are localized", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "experience", 2), language: Language.Korean).Objectives[0].Text == "EXP 획득을 피하세요."));
Check("Passive hides incomplete ordinary prerequisites", () => Assert(!GuidanceController.Update(GuidanceMode.Passive, RouteId.TruePacifist, With(Candidate(), "papyrus_friendship", 0)).Show));
Check("Active displays current objective", () => Assert(GuidanceController.Update(GuidanceMode.Active, RouteId.TruePacifist, With(Candidate(), "papyrus_friendship", 0)).Show));
var kill = new PendingDecision("kill", new Dictionary<string, int?> { ["experience"] = 10 }, true);
Check("Warn before irreversible EXP gain", () => {
    var result = GuidanceController.Update(GuidanceMode.Passive, RouteId.TruePacifist, Candidate(), kill);
    Assert(result.Status == RouteStatus.AT_RISK && result.Show && result.Dismissible && !result.BlockDecision);
    Assert(Candidate()["experience"] == 0);
});
Check("Battle and cutscene UI is deferred", () => Assert(!GuidanceController.Update(GuidanceMode.Active, RouteId.TruePacifist, Candidate(), kill, false).Show));
Check("Off disables warnings", () => Assert(!GuidanceController.Update(GuidanceMode.Off, RouteId.TruePacifist, Candidate(), kill).Show));
Check("Forced does not claim an unverified interception", () => {
    var result = GuidanceController.Update(GuidanceMode.Forced, RouteId.TruePacifist, Candidate(), kill);
    Assert(result.Enforcement == "UNVERIFIED_NO_INTERVENTION" && !result.BlockDecision);
});
Check("Permanent history decisions are never applied", () => {
    var state = Candidate();
    var decision = new PendingDecision("sell_soul", new Dictionary<string, int?> { ["soul_sold"] = 1 }, true, true);
    var result = GuidanceController.Update(GuidanceMode.Forced, RouteId.TruePacifist, state, decision);
    Assert(result.Status == RouteStatus.AT_RISK && !result.BlockDecision && state["soul_sold"] == 0);
});
Check("Neutral variants remain explicitly unclassified", () => Assert(RouteEvaluator.Evaluate(RouteId.Neutral, Candidate()).Status == RouteStatus.UNKNOWN));
Check("Genocide aborted flag overrides missing progress", () => Assert(RouteEvaluator.Evaluate(RouteId.Genocide, GameState.From(("genocide_aborted", 1))).Status == RouteStatus.BLOCKED));
Check("Genocide quotas include shared Hotland CORE", () => Assert(RouteCatalog.RegionalQuotas["hotland_core"] == 40 && RouteCatalog.RegionalQuotas["waterfall"] == 18));
Check("GML uses unknown-safe normalized namespace", () => {
    var gml = GmlRuleEmitter.EmitEvaluator(RouteId.TruePacifist);
    Assert(gml.Contains("global.rk_experience < 0") && gml.Contains("global.rk_soul_sold != 0") && gml.EndsWith("4; // Partial coverage never claims full reachability.\n"));
});
Check("State snapshots survive adapter dictionary updates", () => {
    var observations = new Dictionary<string, int?> { ["experience"] = 0 };
    var snapshot = GameStateReader.ReadNormalized(observations);
    observations["experience"] = 100;
    Assert(snapshot["experience"] == 0);
    Assert(snapshot.Facts is not Dictionary<string, int?>);
});
Check("Invalid routes are rejected", () => {
    try { RouteEvaluator.Evaluate((RouteId)999, Candidate()); throw new Exception("Invalid route accepted"); }
    catch (ArgumentOutOfRangeException) { }
});
Check("Alphys objective waits for friendships and prior Neutral", () => {
    var state = With(With(With(Candidate(), "prior_neutral_completion", 0), "alphys_friendship", 0), "true_lab_completed", 0);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Objectives.Single().Fact == "prior_neutral_completion");
    state = With(state, "prior_neutral_completion", 1);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Objectives.Single().Fact == "alphys_friendship");
    state = With(state, "alphys_friendship", 1);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Objectives.Single().Fact == "true_lab_completed");
});
Check("Unavailable or unobserved hangouts are not actionable", () => {
    var state = With(With(Candidate(), "papyrus_friendship", 0), "papyrus_hangout_available", null);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Objectives.Count == 0);
    state = With(state, "papyrus_hangout_available", 0);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Objectives.Count == 0);
    state = With(state, "papyrus_hangout_available", 1);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Objectives.Single().Fact == "papyrus_friendship");
});
Check("Active explains unavailable objectives without directing a premature action", () => {
    var state = With(With(Candidate(), "papyrus_friendship", 0), "papyrus_hangout_available", null);
    var guidance = GuidanceController.Update(GuidanceMode.Active, RouteId.TruePacifist, state);
    Assert(guidance.Show && guidance.Message == "No next action can be verified yet.");
});
Check("Undyne objective waits for Papyrus even if available", () => {
    var state = With(With(Candidate(), "papyrus_friendship", 0), "undyne_friendship", 0);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Objectives.Single().Fact == "papyrus_friendship");
});
Check("No objective suggests selling a soul", () => {
    var result = RouteEvaluator.Evaluate(RouteId.SoullessPacifist, Candidate());
    Assert(result.Objectives.Count == 0);
});
Check("Generated GML semantics match C# over randomized snapshots", () => {
    var random = new Random(72144);
    foreach (var route in Enum.GetValues<RouteId>())
    {
        var gml = GmlRuleEmitter.EmitEvaluator(route);
        for (var sample = 0; sample < 1500; sample++)
        {
            var facts = RouteCatalog.Get(route).Requirements.ToDictionary(r => r.Fact,
                r => sample == 0 ? (int?)r.Expected : random.Next(0, 6) switch { 0 => null, 1 => -1, 2 => 0, 3 => 1, 4 => 2, _ => r.Expected });
            var expected = (int)RouteEvaluator.Evaluate(route, new GameState(facts)).Status;
            var actual = new GmlSubsetInterpreter(gml, facts).Run();
            Assert(expected == actual, $"Route {route} sample {sample}: C# {expected}, GML subset {actual}");
        }
    }
});
Console.WriteLine($"{count - failures.Count}/{count} PASS; authentic runtime: NOT_RUN");
foreach (var failure in failures) Console.Error.WriteLine(failure);
Environment.ExitCode = failures.Count == 0 ? 0 : 1;
