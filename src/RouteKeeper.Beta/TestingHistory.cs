namespace RouteKeeper.Beta;

public sealed record SessionHistoryRow(Guid Id, DateTimeOffset Created, DateTimeOffset Updated, string State,
    string Build, string Language, string Configuration, int Completed, int Passed, int Failed, int Blocked, int NotRun);
public sealed record HumanResultChange(Guid EarlierSession, Guid LaterSession, string ScenarioId, string Build,
    string Language, string Configuration, TestResult EarlierHumanResult, TestResult LaterHumanResult,
    string Classification = "HUMAN_REPORTED_COMPARISON_NOT_INDEPENDENT_VERIFICATION");
public sealed record TestingHistoryReport(SessionHistoryRow[] Sessions, CoverageGroup[] Coverage, HumanResultChange[] Changes);

/// <summary>Comparable human reports across sessions; no inference about authentic gameplay or independent state.</summary>
public static class TestingHistory
{
    public static TestingHistoryReport Build(IEnumerable<BetaSession> sessions, ScenarioCatalog catalog)
    {
        var values = sessions.Take(1001).ToArray();
        if (values.Length > 1000 || values.Any(s => s is null) || values.Select(s => s.Id).Distinct().Count() != values.Length)
            throw new InvalidDataException("History requires up to 1000 distinct validated sessions.");
        // Callers load through SessionStore first. A catalog mismatch must remain visible,
        // rather than assigning today's meanings to an older checklist.
        string hash = OwnedFiles.Hash(System.Text.Json.JsonSerializer.SerializeToUtf8Bytes(catalog, BetaJson.Options));
        if (values.Any(s => s.CatalogVersion != catalog.Version || s.CatalogSha256 != hash))
            throw new InvalidDataException("History catalog differs; preserve and review the original sessions separately.");
        var ordered = values.OrderBy(s => s.Created).ThenBy(s => s.Id).ToArray();
        var rows = ordered.Select(s =>
        {
            var total = Reports.Coverage(s, catalog).Single(r => r.Dimension == "Total");
            return new SessionHistoryRow(s.Id, s.Created, s.Updated, s.State, s.Configuration.Build,
                s.Configuration.Language, Configuration(s), total.Completed, total.Passed, total.Failed, total.Blocked, total.NotRun);
        }).ToArray();
        var coverage = ordered.SelectMany(s => Reports.Coverage(s, catalog))
            .GroupBy(r => (r.Dimension, r.Value))
            .Select(g => new CoverageGroup(g.Key.Dimension, g.Key.Value, g.Sum(r => r.Total), g.Sum(r => r.Completed),
                g.Sum(r => r.Passed), g.Sum(r => r.Failed), g.Sum(r => r.Blocked), g.Sum(r => r.NotRun), g.Sum(r => r.PendingReview))).ToArray();
        var changes = new List<HumanResultChange>();
        foreach (var group in ordered.GroupBy(s => (s.Configuration.Build, s.Configuration.Language, Configuration: Configuration(s))))
        {
            var comparable = group.ToArray();
            for (int i = 1; i < comparable.Length; i++)
                foreach (var scenario in catalog.Scenarios)
                {
                    var before = comparable[i - 1].Result(scenario); var after = comparable[i].Result(scenario);
                    // An unexecuted case is a coverage gap, not a behavioral change.
                    if (before == after || before == TestResult.NOT_RUN || after == TestResult.NOT_RUN) continue;
                    changes.Add(new(comparable[i - 1].Id, comparable[i].Id, scenario.Id, group.Key.Build,
                        group.Key.Language, group.Key.Configuration, before, after));
                }
        }
        return new(rows.Reverse().ToArray(), coverage, changes.ToArray());
    }
    private static string Configuration(BetaSession session) => session.Configuration.Mode + "/" + session.Configuration.Display;
}
