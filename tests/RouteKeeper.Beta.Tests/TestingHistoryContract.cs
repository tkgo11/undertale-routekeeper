using RouteKeeper.Beta;

internal static class TestingHistoryContract
{
    public static int Run(string root, ScenarioCatalog catalog)
    {
        int checks = 0;
        void Check(bool value, string message) { if (!value) throw new Exception(message); checks++; Console.WriteLine("PASS " + message); }
        var store = new SessionStore(Path.Combine(root, "history-contract"), catalog);
        var config = new SessionConfiguration("en", "Passive", "SYNTHETIC", "TEST");
        BetaSession Result(SessionConfiguration configuration, TestResult value)
        {
            var session = store.Create(configuration);
            foreach (var step in catalog.Scenarios.Single(s => s.Id == "f10").Steps)
                session = store.Record(session.Id, session.Revision, "f10", step.Id, value, "Synthetic history fixture");
            return session;
        }
        var first = Result(config, TestResult.PASS);
        var second = Result(config, TestResult.FAIL);
        var korean = Result(config with { Language = "ko" }, TestResult.PASS);
        var active = Result(config with { Mode = "Active" }, TestResult.PASS);
        var untouched = store.Create(config);
        var report = TestingHistory.Build(new[] { first, second, korean, active, untouched }, catalog);
        Check(report.Sessions.Length == 5 && report.Sessions[0].Id == untouched.Id, "history includes saved sessions newest first");
        Check(report.Changes.Length == 1 && report.Changes[0].EarlierHumanResult == TestResult.PASS && report.Changes[0].LaterHumanResult == TestResult.FAIL,
            "history compares executed outcomes only within the same build/language/configuration");
        Check(report.Changes[0].Classification.Contains("NOT_INDEPENDENT", StringComparison.Ordinal), "history comparison never certifies independent regression");
        Check(report.Coverage.Single(g => g.Dimension == "Total").Total == catalog.Scenarios.Length * 5 &&
            report.Coverage.Single(g => g.Dimension == "Language" && g.Value == "ko").Total == catalog.Scenarios.Length,
            "cross-session coverage counts scenario executions by language and total");
        Check(report.Sessions.Single(s => s.Id == first.Id).Passed == 1 && report.Sessions.Single(s => s.Id == second.Id).Failed == 1,
            "session history preserves separate pass/fail coverage");
        try { TestingHistory.Build(new[] { first, first }, catalog); throw new Exception("Duplicate counted twice"); }
        catch (InvalidDataException) { checks++; Console.WriteLine("PASS duplicate sessions cannot inflate history coverage"); }
        try { TestingHistory.Build(new[] { first with { CatalogSha256 = new string('0', 64) } }, catalog); throw new Exception("Stale catalog accepted"); }
        catch (InvalidDataException) { checks++; Console.WriteLine("PASS incompatible history catalogs refuse comparison"); }
        try { TestingHistory.Build(Enumerable.Range(0,1001).Select(_ => first with { Id = Guid.NewGuid() }), catalog); throw new Exception("Unbounded history accepted"); }
        catch (InvalidDataException) { checks++; Console.WriteLine("PASS history session budget enforced"); }
        return checks;
    }
}
