using RouteKeeper.Core;

var nativeFiles = GmlRuleEmitter.EmitNativeFiles();
if (args is ["--emit-native", var directory] || args is ["--emit-gml", var sourceFile])
{
    var outputDirectory = args[0] == "--emit-native" ? args[1] : Path.GetDirectoryName(Path.GetFullPath(args[1]))!;
    Directory.CreateDirectory(outputDirectory);
    foreach (var (name, source) in nativeFiles) File.WriteAllText(Path.Combine(outputDirectory, name), source);
    Console.WriteLine("PASS generated route scripts");
    return;
}
if (args is ["--verify-native", var checkedDirectory] || args is ["--verify-gml", var checkedFile])
{
    var inputDirectory = args[0] == "--verify-native" ? args[1] : Path.GetDirectoryName(Path.GetFullPath(args[1]))!;
    foreach (var (name, expected) in nativeFiles)
        if (File.ReadAllText(Path.Combine(inputDirectory, name)).Replace("\r\n", "\n") != expected.Replace("\r\n", "\n"))
            throw new InvalidOperationException("Stale generated " + name);
    Console.WriteLine("PASS checked-in native route scripts match shared rules");
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
GameState Candidate() => new(RouteCatalog.Get(RouteId.TruePacifist).Requirements.ToDictionary(r => r.Fact, r => (int?)r.Expected).Concat(new Dictionary<string, int?> { ["papyrus_hangout_available"] = 1, ["undyne_hangout_available"] = 1, ["alphys_date_available"] = 1, ["true_lab_available"] = 1, ["mettaton_defeated"] = 1 }).ToDictionary(x => x.Key, x => x.Value));
GameState With(GameState state, string key, int? value) => new(new Dictionary<string, int?>(state.Facts) { [key] = value });

Check("Gameplay guidance omits developer implementation text",()=>{
    var text=Enum.GetValues<RouteId>().SelectMany(route=>RouteCatalog.Get(route).Requirements.SelectMany(r=>new[]{r.Minimal,r.Detailed,r.KoreanMinimal,r.KoreanDetailed})
        .Concat(ObjectiveRules.For(route).SelectMany(r=>new[]{r.Minimal,r.Detailed,r.KoreanMinimal,r.KoreanDetailed})));
    foreach(var line in text)Assert(!new[]{"ROUTEKEEPER","by the mod","모드는 영구 기록을","system_information","flag was set"}.Any(line.Contains),line);
});
Check("Unknown facts never imply success", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, GameState.From()).Status == RouteStatus.UNKNOWN));
Check("Invalid observations remain unknown", () => {
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "experience", -1)).Status == RouteStatus.UNKNOWN);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "papyrus_alive", 2)).Status == RouteStatus.UNKNOWN);
});
Check("Implemented requirements can establish on-track state", () => {
    var result = RouteEvaluator.Evaluate(RouteId.TruePacifist, Candidate());
    Assert(result.Status == RouteStatus.ON_TRACK && result.CompleteCoverage);
});
Check("EXP invalidates pacifist even with unknown prerequisites", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, GameState.From(("experience", 1))).Status == RouteStatus.BLOCKED));
Check("Missing friendship requires action instead of reset", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "papyrus_friendship", 0)).Status == RouteStatus.ACTION_REQUIRED));
Check("Missed water opportunity invalidates current run", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "water_opportunity_missed", 1)).Status == RouteStatus.BLOCKED));
Check("Unknown history prevents an unaltered ending guarantee", () => Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, With(Candidate(), "soul_sold", null)).Status == RouteStatus.UNKNOWN));
Check("Sold soul distinguishes pacifist variants", () => {
    var state = With(Candidate(), "soul_sold", 1);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Status == RouteStatus.BLOCKED);
    Assert(RouteEvaluator.Evaluate(RouteId.SoullessPacifist, state).Status == RouteStatus.ON_TRACK);
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
Check("Neutral evaluation requires observed branch facts", () => Assert(RouteEvaluator.Evaluate(RouteId.Neutral, GameState.From()).Status == RouteStatus.UNKNOWN));
Check("Genocide aborted flag overrides missing progress", () => Assert(RouteEvaluator.Evaluate(RouteId.Genocide, GameState.From(("genocide_aborted", 1))).Status == RouteStatus.BLOCKED));
Check("Genocide quotas include shared Hotland CORE", () => Assert(RouteCatalog.RegionalQuotas["hotland_core"] == 40 && RouteCatalog.RegionalQuotas["waterfall"] == 18));
Check("GML uses unknown-safe normalized namespace", () => {
    var gml = GmlRuleEmitter.EmitEvaluator(RouteId.TruePacifist);
    Assert(gml.Contains("global.rk_experience < 0") && gml.Contains("global.rk_soul_sold == 0") && gml.EndsWith("return 0;\n"));
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
    Assert(guidance.Show && guidance.Message == "Your next step is not clear yet.");
});
Check("Undyne objective waits for Papyrus even if available", () => {
    var state = With(With(Candidate(), "papyrus_friendship", 0), "undyne_friendship", 0);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist, state).Objectives.Single().Fact == "papyrus_friendship");
});
Check("No objective suggests selling a soul", () => {
    var result = RouteEvaluator.Evaluate(RouteId.SoullessPacifist, Candidate());
    Assert(result.Status == RouteStatus.BLOCKED && result.Objectives.All(x => !x.Text.Contains("Sell your", StringComparison.Ordinal)));
});
Check("Erased world is blocked without touching permanent history", () => {
    var state=With(Candidate(),"world_erased",1);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist,state).Status==RouteStatus.BLOCKED && state["world_erased"]==1);
});
Check("Future Genocide deadlines do not block early progress", () => {
    var state=GameState.From(("hard_mode",0),("world_erased",0),("genocide_aborted",0),("genocide_stage",0),
        ("soul_sold",0),("toriel_resolved",0),("papyrus_resolved",0),("undyne_resolved",0),("mettaton_defeated",0),("kills_ruins",3),("kills_snowdin",0),("snowdrake_lost",0),("sans_defeated",0));
    Assert(RouteEvaluator.Evaluate(RouteId.Genocide,state).Status==RouteStatus.ACTION_REQUIRED);
    Assert(RouteEvaluator.Evaluate(RouteId.Genocide,state).Objectives.Single().Text.Contains("17"));
    Assert(RouteEvaluator.Evaluate(RouteId.Genocide,With(state,"toriel_resolved",1)).Status==RouteStatus.BLOCKED);
});
Check("All ordered Genocide stages provide actionable objectives", () => {
    for(int stage=0;stage<=16;stage++) {
        var facts=new Dictionary<string,int?>{{"genocide_stage",stage},{"sans_defeated",0},{"kills_ruins",0},{"kills_snowdin",0},{"kills_waterfall",0},{"kills_hotland_core",0}};
        Assert(ObjectiveRules.For(RouteId.Genocide).Any(r=>r.Condition.Matches(new GameState(facts))));
    }
});
Check("Epilogue mismatch only blocks after the choice resolves", () => {
    var state=With(With(Candidate(),"epilogue_matches",0),"epilogue_resolved",0);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist,state).Status==RouteStatus.ON_TRACK);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist,With(state,"epilogue_resolved",1)).Status==RouteStatus.BLOCKED);
});
Check("Missing Snowdrake blocks before an exhausted region's boss", () => {
    var state=GameState.From(("hard_mode",0),("world_erased",0),("genocide_aborted",0),("genocide_stage",5),
        ("soul_sold",0),("toriel_resolved",1),("papyrus_resolved",0),("undyne_resolved",0),("mettaton_defeated",0),
        ("snowdrake_killed",0),("kills_snowdin",16),("snowdrake_lost",1),("sans_defeated",0));
    Assert(RouteEvaluator.Evaluate(RouteId.Genocide,state).Status==RouteStatus.BLOCKED);
    Assert(RouteEvaluator.Evaluate(RouteId.Genocide,With(state,"snowdrake_lost",0)).Status==RouteStatus.ACTION_REQUIRED,"A live final-encounter Snowdrake is still recoverable");
});
Check("Final objectives advance after the barrier and Sans", () => {
    var complete=With(With(Candidate(),"epilogue_resolved",1),"barrier_broken",1);
    Assert(RouteEvaluator.Evaluate(RouteId.TruePacifist,complete).Objectives.First().Fact=="ending_complete");
    var facts=RouteCatalog.Facts.ToDictionary(f=>f,f=>(int?)0);facts["genocide_stage"]=16;facts["sans_defeated"]=1;facts["snowdrake_killed"]=1;
    Assert(RouteEvaluator.Evaluate(RouteId.Genocide,new GameState(facts)).Objectives.First().Fact=="genocide_throne");
});
Check("Generated GML semantics match C# over randomized snapshots", () => {
    var random = new Random(72144);
    foreach (var route in Enum.GetValues<RouteId>().Where(r => r != RouteId.Neutral))
    {
        var gml = GmlRuleEmitter.EmitEvaluator(route);
        for (var sample = 0; sample < 1500; sample++)
        {
            var requirements = RouteCatalog.Get(route).Requirements;
            var facts = requirements.SelectMany(r => r.GuardFact is null ? new[] { r.Fact } : new[] { r.Fact, r.GuardFact })
                .Distinct().ToDictionary(f => f, f => sample == 0 ? (int?)0 : random.Next(0, 7) switch
                { 0 => null, 1 => -1, 2 => 0, 3 => 1, 4 => 2, 5 => 16, _ => int.MaxValue });
            var expected = (int)RouteEvaluator.Evaluate(route, new GameState(facts)).Status;
            var actual = new GmlSubsetInterpreter(gml, facts).Run();
            Assert(expected == actual, $"Route {route} sample {sample}: C# {expected}, GML subset {actual}");
        }
    }
});
Check("Generated objectives and progress match C# in both languages and spoiler levels", () => {
    var random=new Random(15039);
    var source=GmlRuleEmitter.EmitObjectives();
    foreach(var route in Enum.GetValues<RouteId>().Where(r=>r!=RouteId.Neutral))
    foreach(var language in Enum.GetValues<Language>())
    foreach(var spoilers in Enum.GetValues<SpoilerLevel>())
    for(int sample=0;sample<100;sample++) {
        var facts=RouteCatalog.Facts.ToDictionary(f=>f,f=>(int?)(random.Next(5) switch {0=>-1,1=>0,2=>1,3=>16,_=>2}));
        facts["target_route"]=(int)route; facts["language"]=(int)language; facts["spoilers"]=(int)spoilers;
        var state=new GameState(facts);
        var expected=RouteEvaluator.Evaluate(route,state,spoilers,language);
        var interpreter=new GmlObjectiveInterpreter(source,facts);
        var actual=interpreter.Run();
        var expectedText=expected.Objectives.FirstOrDefault()?.Text ?? (language==Language.Korean?"다음 목표를 아직 알 수 없습니다.":"Your next step is not clear yet.");
        Assert(actual==expectedText,$"Objective mismatch {route}/{language}/{spoilers}/{sample}: {actual} != {expectedText}");
        Assert(interpreter.Integer("progress_met")==expected.MetRequirements && interpreter.Integer("progress_total")==expected.TotalRequirements,"Progress mismatch");
    }
});
Console.WriteLine($"{count - failures.Count}/{count} PASS; authentic runtime: NOT_RUN");
foreach (var failure in failures) Console.Error.WriteLine(failure);
Environment.ExitCode = failures.Count == 0 ? 0 : 1;
