using System.Net;
using System.Text;
using System.Text.Json;

namespace RouteKeeper.Beta;

public sealed record ScenarioSummary(string Id, string Feature, string ImplementationStatus, string AutomatedStatus,
    string HumanExecutionStatus, TestResult HumanReportedResult, string IndependentVerificationStatus,
    string EvidenceCompleteness, string CompatibilityConfidence);
public sealed record CoverageGroup(string Dimension, string Value, int Total, int Completed, int Passed, int Failed, int Blocked, int NotRun, int PendingReview);
public sealed record ExportOptions(bool IncludeReviewedScreenshots, string[] RedactLiterals);
public sealed record SessionReport(int Schema, Guid SessionId, int Revision, SessionConfiguration Configuration,
    string Classification, string IndependentVerification, string Authenticity, string State,
    ScenarioSummary[] Scenarios, CoverageGroup[] Coverage, StepObservation[] Observations,
    BugReport[] Bugs, EvidenceAttachment[] Evidence, NativeReceipt[] NativeReceipts)
{
    public EvidenceKind NativeObservationClassification => EvidenceKind.AutomatedObservation;
    public string NativeObservationScope => "PROCESS_ONLY";
    public string NativeIndependentGameplayVerification => "NOT_RUN";
}

public static class Reports
{
    public static ScenarioSummary[] Summarize(BetaSession session, ScenarioCatalog catalog) => catalog.Scenarios.Select(s =>
    {
        var result = session.Result(s);
        int executed = s.Steps.Count(step => session.Observations.TryGetValue(BetaSession.Key(s.Id, step.Id), out var observation) && observation.Result != TestResult.NOT_RUN && !string.IsNullOrWhiteSpace(observation.Actual));
        return new ScenarioSummary(s.Id, s.Feature, s.ImplementationStatus, s.AutomatedStatus,
            executed == 0 ? "NOT_STARTED" : s.Steps.All(step => session.Observations.TryGetValue(BetaSession.Key(s.Id, step.Id), out var o) && o.Result != TestResult.NOT_RUN) ? "COMPLETE" : "IN_PROGRESS",
            result, "NOT_RUN", executed == 0 ? "MISSING" : executed == s.Steps.Length ? "HUMAN_OBSERVATIONS_COMPLETE_UNVERIFIED" : "PARTIAL_UNVERIFIED", s.CompatibilityConfidence);
    }).ToArray();
    public static CoverageGroup[] Coverage(BetaSession session, ScenarioCatalog catalog)
    {
        var rows = Summarize(session, catalog);
        var groups = rows.GroupBy(r => r.Feature).Select(g => Group("Feature", g.Key, g)).ToList();
        groups.Add(Group("Total", "All", rows));
        groups.Add(Group("GameBuild", session.Configuration.Build, rows));
        groups.Add(Group("Language", session.Configuration.Language, rows));
        groups.Add(Group("Configuration", session.Configuration.Mode + "/" + session.Configuration.Display, rows));
        return groups.ToArray();
    }
    private static CoverageGroup Group(string dimension, string value, IEnumerable<ScenarioSummary> values)
    {
        var rows = values.ToArray();
        return new(dimension, value, rows.Length, rows.Count(r => r.HumanExecutionStatus == "COMPLETE"), rows.Count(r => r.HumanReportedResult == TestResult.PASS),
            rows.Count(r => r.HumanReportedResult == TestResult.FAIL), rows.Count(r => r.HumanReportedResult == TestResult.BLOCKED),
            rows.Count(r => r.HumanReportedResult == TestResult.NOT_RUN), rows.Count(r => r.HumanReportedResult == TestResult.NEEDS_REVIEW));
    }
    private static string Redact(string value, string[] literals)
    {
        foreach (var literal in literals.OrderByDescending(s => s.Length)) value = value.Replace(literal, "[REDACTED]", StringComparison.OrdinalIgnoreCase);
        return value;
    }
    public static SessionReport Build(BetaSession session, ScenarioCatalog catalog, ExportOptions options)
    {
        if (options.RedactLiterals is null || options.RedactLiterals.Length > 100 || options.RedactLiterals.Any(s => string.IsNullOrWhiteSpace(s) || s.Length > 2000)) throw new InvalidDataException("Specify up to 100 nonempty redaction phrases.");
        string R(string text) => Redact(text, options.RedactLiterals);
        var configuration = session.Configuration with { Build = R(session.Configuration.Build), Display = R(session.Configuration.Display), RouteKeeperVersion = R(session.Configuration.RouteKeeperVersion) };
        var observations = session.Observations.Values.Select(o => o with { Actual = R(o.Actual) }).ToArray();
        var evidence = options.IncludeReviewedScreenshots ? session.Attachments.Where(a => a.ReviewedForSharing).ToArray() : [];
        var ids = evidence.Select(a => a.Id).ToHashSet();
        var bugs = session.Bugs.Select(b => b with { Expected = R(b.Expected), Actual = R(b.Actual), Reproduction = R(b.Reproduction), EvidenceIds = b.EvidenceIds.Where(ids.Contains).ToArray() }).ToArray();
        var coverage = Coverage(session, catalog).Select(g => g with { Value = R(g.Value) }).ToArray();
        return new(1, session.Id, session.Revision, configuration, "HUMAN_REPORTED", "NOT_RUN", "LOCAL_HASHES_ARE_NOT_AUTHENTICATION", session.State,
            Summarize(session, catalog), coverage, observations, bugs, evidence, session.NativeReceipts ?? []);
    }
    public static void Export(SessionStore store, Guid id, int expectedRevision, ScenarioCatalog catalog, string newDirectory, ExportOptions options)
    {
        var session = store.Load(id);
        if (session.Revision != expectedRevision) throw new InvalidOperationException("Session changed; review the latest revision before exporting.");
        var report = Build(session, catalog, options);
        string output = OwnedFiles.NoLinks(newDirectory);
        if (Path.Exists(output)) throw new IOException("Export directory must be new; previous reports are never overwritten.");
        Directory.CreateDirectory(output);
        OwnedFiles.Create(Path.Combine(output, "report.json"), JsonSerializer.SerializeToUtf8Bytes(report, BetaJson.Options));
        var csv = new StringBuilder("Scenario,Feature,Implementation,Automated,HumanExecution,HumanReported,IndependentVerification,Evidence,Compatibility\r\n");
        foreach (var row in report.Scenarios)
            csv.AppendLine(string.Join(',', new[] { row.Id, row.Feature, row.ImplementationStatus, row.AutomatedStatus, row.HumanExecutionStatus, row.HumanReportedResult.ToString(), row.IndependentVerificationStatus, row.EvidenceCompleteness, row.CompatibilityConfidence }.Select(Csv)));
        OwnedFiles.Create(Path.Combine(output, "summary.csv"), Encoding.UTF8.GetBytes(csv.ToString()));
        string E(string value) => WebUtility.HtmlEncode(value);
        var html = new StringBuilder("<!doctype html><html lang=\"en\"><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\"><meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; base-uri 'none'\"><title>ROUTEKEEPER Beta Report</title><style>body{font:16px system-ui;margin:2rem;color:#172033;background:#f5f7fb}table{border-collapse:collapse;width:100%;background:white}td,th{border:1px solid #bbc5d4;padding:.5rem;text-align:left}pre{white-space:pre-wrap;overflow-wrap:anywhere}img{max-width:100%}article{padding:1rem;background:white;margin:1rem 0}</style><h1>ROUTEKEEPER Beta Report</h1><p>Human-reported observations. Independent verification: NOT_RUN. Local hashes detect changes; they do not authenticate gameplay. No upload performed.</p>");
        html.Append($"<p>Session {id:N}, revision {session.Revision}, {E(report.Configuration.Language)}, {E(report.Configuration.Mode)}, build {E(report.Configuration.Build)}.</p><table><tr><th>Scenario</th><th>Implementation</th><th>Automated</th><th>Human execution</th><th>Human result</th><th>Independent</th><th>Evidence</th><th>Compatibility</th></tr>");
        foreach (var row in report.Scenarios)
            html.Append($"<tr><td>{E(row.Id)}</td><td>{E(row.ImplementationStatus)}</td><td>{E(row.AutomatedStatus)}</td><td>{E(row.HumanExecutionStatus)}</td><td>{row.HumanReportedResult}</td><td>{E(row.IndependentVerificationStatus)}</td><td>{E(row.EvidenceCompleteness)}</td><td>{E(row.CompatibilityConfidence)}</td></tr>");
        html.Append("</table><h2>Step observations</h2>");
        foreach (var observation in report.Observations) html.Append($"<article><h3>{E(observation.ScenarioId)}/{E(observation.StepId)} — {observation.Result}</h3><p>{observation.At:O} · HumanReported</p><pre>{E(observation.Actual)}</pre></article>");
        html.Append("<h2>Native process receipts</h2><p>AutomatedObservation · PROCESS_ONLY. Independent gameplay verification: NOT_RUN. These observations never change human results.</p>");
        foreach (var receipt in report.NativeReceipts)
        {
            html.Append($"<article><h3>{E(receipt.Scenario)}/{E(receipt.Step)} · {E(receipt.State)}</h3><p>Transaction {E(receipt.Session)} · {receipt.Utc:O} · Account history NOT_RESTORED</p>");
            foreach (var item in receipt.Events) html.Append($"<p>{E(item.Kind)} · {item.Utc:O} · AutomatedObservation · PROCESS_ONLY</p>");
            html.Append("</article>");
        }
        html.Append("<h2>Issue history</h2>");
        foreach (var bug in report.Bugs) html.Append($"<article><h3>{E(bug.Id)} revision {bug.Revision} · {E(bug.Severity)}</h3><p>{E(bug.ScenarioId)}/{E(bug.StepId)}</p><h4>Expected</h4><pre>{E(bug.Expected)}</pre><h4>Actual</h4><pre>{E(bug.Actual)}</pre><h4>Reproduction</h4><pre>{E(bug.Reproduction)}</pre></article>");
        foreach (var attachment in report.Evidence)
        {
            byte[] bytes = store.ReadAttachment(id, expectedRevision, attachment.Id);
            OwnedFiles.Create(Path.Combine(output, attachment.Id + ".png"), bytes);
            html.Append($"<article><p>{E(attachment.ScenarioId)}/{E(attachment.StepId)} · Reviewed screenshot · UnverifiedClaim</p><img alt=\"Reviewed tester screenshot\" src=\"{E(attachment.Id)}.png\"></article>");
        }
        OwnedFiles.Create(Path.Combine(output, "report.html"), Encoding.UTF8.GetBytes(html.Append("</html>").ToString()));
        // A manifest is published last. Incomplete exports have no valid manifest.
        var hashes = Directory.GetFiles(output).ToDictionary(p => Path.GetFileName(p)!, OwnedFiles.HashFile);
        OwnedFiles.Create(Path.Combine(output, "integrity.json"), JsonSerializer.SerializeToUtf8Bytes(hashes, BetaJson.Options));
    }
    private static string Csv(string value)
    {
        if (value.Length > 0 && "=+-@\t\r\n".Contains(value[0])) value = "'" + value;
        return "\"" + value.Replace("\"", "\"\"") + "\"";
    }
    public static void VerifyExport(string directory)
    {
        directory = OwnedFiles.NoLinks(directory);
        var hashes = JsonSerializer.Deserialize<Dictionary<string, string>>(OwnedFiles.Read(Path.Combine(directory, "integrity.json")), BetaJson.Options) ?? throw new InvalidDataException("Missing report hashes.");
        if (!hashes.ContainsKey("report.json") || !hashes.ContainsKey("report.html") || !hashes.ContainsKey("summary.csv") || hashes.Count > 503 || Directory.GetDirectories(directory).Length != 0)
            throw new InvalidDataException("Invalid export file set.");
        var actual = Directory.GetFiles(directory).Select(Path.GetFileName).ToHashSet();
        if (!actual.SetEquals(hashes.Keys.Append("integrity.json"))) throw new InvalidDataException("Unexpected/missing export files.");
        foreach (var (file, hash) in hashes)
        {
            if (Path.GetFileName(file) != file || file.Contains(':') || file is "." or ".." || OwnedFiles.HashFile(Path.Combine(directory, file)) != hash)
                throw new InvalidDataException("Report content changed.");
        }
    }
}
