using System.Text.Json;

namespace RouteKeeper.Beta;

public sealed record RevisionEnvelope(int Schema, string PreviousSha256, string PayloadSha256, BetaSession Payload);
public sealed record SessionHead(int Schema, Guid Id, int Revision, string RevisionSha256,
    string? RecoveredFromHeadSha256 = null, DateTimeOffset? RecoveryUtc = null);
public sealed record PublicationRecovery(Guid Id, string OldHeadSha256, int PendingRevision, string PendingSha256, BetaSession Pending);

/// <summary>Immutable complete revisions, flushed before atomic publication; prior committed results survive interruption.</summary>
public sealed class SessionStore
{
    private readonly string root;
    private readonly ScenarioCatalog catalog;
    private readonly string catalogHash;
    public SessionStore(string root, ScenarioCatalog catalog)
    {
        this.root = OwnedFiles.NoLinks(root); catalog.Validate();
        // Defensive copy: callers cannot alter the frozen scenario definition after opening a store.
        this.catalog = JsonSerializer.Deserialize<ScenarioCatalog>(JsonSerializer.SerializeToUtf8Bytes(catalog, BetaJson.Options), BetaJson.Options)!;
        catalogHash = OwnedFiles.Hash(JsonSerializer.SerializeToUtf8Bytes(this.catalog, BetaJson.Options));
        Directory.CreateDirectory(this.root);
    }
    private string Folder(Guid id) => Path.Combine(root, id.ToString("N"));
    private static string RevisionPath(string folder, int revision) => Path.Combine(folder, $"revision-{revision:D8}.json");
    private FileStream Lock(string folder)
    {
        OwnedFiles.NoLinks(folder);
        string path = OwnedFiles.NoLinks(Path.Combine(folder, "writer.lock"));
        return new FileStream(path, FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None);
    }
    public BetaSession Create(SessionConfiguration configuration)
    {
        configuration.Validate();
        Guid id = Guid.NewGuid(); string folder = Folder(id);
        OwnedFiles.NoLinks(folder); Directory.CreateDirectory(folder);
        using var guard = Lock(folder);
        var now = DateTimeOffset.UtcNow;
        var session = new BetaSession(1, id, 0, catalogHash, catalog.Version, now, now, configuration, "Active", [], [], [], []);
        Publish(folder, session, "");
        return session;
    }
    public Guid[] List() => Directory.EnumerateDirectories(root).Select(Path.GetFileName)
        .Where(n => Guid.TryParseExact(n, "N", out _)).Select(n => Guid.ParseExact(n!, "N")).ToArray();
    public BetaSession Load(Guid id)
    {
        string folder = OwnedFiles.NoLinks(Folder(id));
        if (!Directory.Exists(folder)) throw new DirectoryNotFoundException("Session does not exist.");
        using var guard = Lock(folder);
        return ReadChain(folder, id).Session;
    }
    public byte[] ReadAttachment(Guid id, int expectedRevision, string evidenceId)
    {
        string folder = Folder(id); using var guard = Lock(folder);
        var current = ReadChain(folder, id).Session;
        if (current.Revision != expectedRevision) throw new InvalidOperationException("Reload changed session before exporting evidence.");
        var attachment = current.Attachments.SingleOrDefault(a => a.Id == evidenceId && a.ReviewedForSharing) ?? throw new InvalidOperationException("Screenshot has not been reviewed for sharing.");
        var bytes = OwnedFiles.Read(Path.Combine(folder, attachment.Id + ".png"), Screenshot.MaximumBytes);
        if (OwnedFiles.Hash(bytes) != attachment.Sha256) throw new InvalidDataException("Screenshot changed during export.");
        return bytes;
    }
    public byte[] ReadPrivateAttachment(Guid id, int expectedRevision, string evidenceId)
    {
        string folder = Folder(id); using var guard = Lock(folder);
        var current = ReadChain(folder, id).Session;
        if (current.Revision != expectedRevision) throw new InvalidOperationException("Reload changed session before reviewing evidence.");
        var attachment = current.Attachments.SingleOrDefault(a => a.Id == evidenceId) ?? throw new InvalidDataException("Unknown attachment.");
        return OwnedFiles.Read(Path.Combine(folder, attachment.Id + ".png"), Screenshot.MaximumBytes);
    }
    public BetaSession ReviewAttachment(Guid id, int revision, string evidenceId, string reviewedSha256) => Update(id, revision, current =>
    {
        var attachment = current.Attachments.SingleOrDefault(a => a.Id == evidenceId) ?? throw new InvalidDataException("Unknown attachment.");
        if (attachment.Sha256 != reviewedSha256) throw new InvalidDataException("Review is for different pixels.");
        return current with { Attachments = current.Attachments.Select(a => a.Id == evidenceId ? a with { ReviewedForSharing = true } : a).ToArray() };
    });
    private (BetaSession Session, string Hash) ReadChain(string folder, Guid id, bool allowOnePendingRevision = false)
    {
        SessionHead? head = null;
        try { head = ReadHead(folder); }
        catch (FileNotFoundException) when (allowOnePendingRevision) { }
        var paths = Directory.EnumerateFiles(folder, "revision-*.json").Order(StringComparer.Ordinal).ToArray();
        if (paths.Length is 0 or > 10000 ||
            (head is null ? !allowOnePendingRevision || paths.Length != 1 :
                head.Schema != 1 || head.Id != id || head.Revision < 0 ||
                (head.Revision != paths.Length - 1 && (!allowOnePendingRevision || head.Revision != paths.Length - 2)) ||
                (head.RecoveredFromHeadSha256 is not null && (head.RecoveredFromHeadSha256.Length is not (0 or 64) || head.RecoveryUtc is null))))
            throw new InvalidDataException("Session head/chain mismatch; interrupted publication or missing revision. Preserve all files for recovery review.");
        string previous = ""; BetaSession? last = null; long total = 0;
        for (int index = 0; index < paths.Length; index++)
        {
            if (paths[index] != RevisionPath(folder, index)) throw new InvalidDataException("Session revision gap; preserve files for recovery review.");
            byte[] raw = OwnedFiles.Read(paths[index]);
            total += raw.Length;
            if (total > 128L * 1024 * 1024) throw new InvalidDataException("Session history exceeds 128 MiB budget.");
            var envelope = JsonSerializer.Deserialize<RevisionEnvelope>(raw, BetaJson.Options) ?? throw new InvalidDataException("Missing session payload.");
            if (envelope.Schema != 1 || envelope.PreviousSha256 != previous || envelope.Payload is null ||
                envelope.PayloadSha256 != OwnedFiles.Hash(JsonSerializer.SerializeToUtf8Bytes(envelope.Payload, BetaJson.Options)))
                throw new InvalidDataException("Session integrity failure. Original files preserved; automatic rollback refused.");
            Validate(envelope.Payload, id, index);
            if (last is not null && (envelope.Payload.Created != last.Created || envelope.Payload.Updated < last.Updated || envelope.Payload.Configuration != last.Configuration))
                throw new InvalidDataException("Session identity/configuration changed in revision history.");
            if (last is not null)
            {
                var before = last.NativeReceipts ?? []; var after = envelope.Payload.NativeReceipts ?? [];
                if (after.Length < before.Length || before.Where((receipt, i) => !NativeReceipt.Same(receipt, after[i])).Any())
                    throw new InvalidDataException("Immutable native process receipt history changed.");
            }
            previous = OwnedFiles.Hash(raw); last = envelope.Payload;
            if (head is not null && index == head.Revision && head.RevisionSha256 != previous) throw new InvalidDataException("Committed session head integrity failure.");
        }
        VerifyAttachments(folder, last!);
        return (last!, previous);
    }
    private static SessionHead ReadHead(string folder) => JsonSerializer.Deserialize<SessionHead>(OwnedFiles.Read(Path.Combine(folder, "head.json")), BetaJson.Options) ?? throw new InvalidDataException("Missing session head.");
    public PublicationRecovery InspectPublicationRecovery(Guid id)
    {
        string folder = Folder(id); using var guard = Lock(folder);
        return RecoveryCandidate(folder, id);
    }
    private PublicationRecovery RecoveryCandidate(string folder, Guid id)
    {
        var pending = ReadChain(folder, id, true);
        string headPath = OwnedFiles.NoLinks(Path.Combine(folder, "head.json"));
        string headHash = File.Exists(headPath) ? OwnedFiles.HashFile(headPath) : "";
        if (headHash.Length != 0 && ReadHead(folder).Revision == pending.Session.Revision) throw new InvalidOperationException("No interrupted publication to recover.");
        return new(id, headHash, pending.Session.Revision, pending.Hash, pending.Session);
    }
    public BetaSession RecoverPublication(Guid id, string oldHeadSha256, string pendingSha256, string typedPhrase)
    {
        if (typedPhrase != "RECOVER SESSION " + id.ToString("N")) throw new InvalidOperationException("Exact session recovery phrase required after reviewing the pending change.");
        string folder = Folder(id); using var guard = Lock(folder);
        var candidate = RecoveryCandidate(folder, id);
        if (candidate.OldHeadSha256 != oldHeadSha256 || candidate.PendingSha256 != pendingSha256)
            throw new InvalidDataException("Recovery candidate changed after review; preserve all files and inspect again.");
        // Revalidate the complete chain and PNGs under the same writer lock.
        var fresh = ReadChain(folder, id, true);
        if (fresh.Hash != pendingSha256) throw new InvalidDataException("Pending revision changed during recovery.");
        OwnedFiles.Replace(Path.Combine(folder, "head.json"), JsonSerializer.SerializeToUtf8Bytes(
            new SessionHead(1, id, candidate.PendingRevision, pendingSha256, oldHeadSha256, DateTimeOffset.UtcNow), BetaJson.Options));
        return ReadChain(folder, id).Session;
    }
    private void Validate(BetaSession session, Guid id, int revision)
    {
        if (session.Schema != 1 || session.Id != id || session.Revision != revision || session.CatalogSha256 != catalogHash ||
            session.CatalogVersion != catalog.Version || session.State is not ("Active" or "Paused" or "Completed") ||
            session.Configuration is null || session.Observations is null || session.Attachments is null || session.Bugs is null || session.AuthorizedHighRiskScenarios is null ||
            session.Observations.Values.Any(o => o is null) || session.Attachments.Any(a => a is null) || session.Bugs.Any(b => b is null) ||
            session.Created > session.Updated || session.Updated > DateTimeOffset.UtcNow.AddMinutes(1))
            throw new InvalidDataException("Unsupported, stale, corrupt or mismatched session; no silent migration.");
        session.Configuration.Validate();
        var receipts = session.NativeReceipts ?? [];
        if (receipts.Length > 1000 || receipts.Any(r => r is null) || receipts.Select(r => r.Session).Distinct().Count() != receipts.Length ||
            JsonSerializer.SerializeToUtf8Bytes(receipts, BetaJson.Options).Length > 1024 * 1024)
            throw new InvalidDataException("Duplicate or excessive native process receipts.");
        foreach (var receipt in receipts)
        {
            receipt.Validate(); RequireStep(receipt.Scenario, receipt.Step);
            if (receipt.BetaSession != id.ToString("N") || receipt.Utc < session.Created || receipt.Utc > session.Updated.AddMinutes(1)) throw new InvalidDataException("Native receipt identity or timestamp differs from the beta session.");
        }
        if (session.AuthorizedHighRiskScenarios.Distinct().Count() != session.AuthorizedHighRiskScenarios.Length ||
            session.AuthorizedHighRiskScenarios.Any(s => Scenario(s).Risk != Risk.HighRisk)) throw new InvalidDataException("Invalid high-risk authorization.");
        foreach (var (key, observation) in session.Observations)
        {
            RequireStep(observation.ScenarioId, observation.StepId);
            if (key != BetaSession.Key(observation.ScenarioId, observation.StepId) || !Enum.IsDefined(observation.Result) ||
                observation.Classification != EvidenceKind.HumanReported || observation.At < session.Created || observation.At > session.Updated)
                throw new InvalidDataException("Invalid observation identity/classification.");
            Text(observation.Actual);
            if (observation.Result != TestResult.NOT_RUN && string.IsNullOrWhiteSpace(observation.Actual)) throw new InvalidDataException("Observation explanation required.");
            RequireRisk(session, Scenario(observation.ScenarioId), observation.Result);
        }
        if (session.Attachments.Length > 500 || session.Attachments.Sum(a => a.Bytes) > 128L * 1024 * 1024 || session.Attachments.Select(a => a.Id).Distinct().Count() != session.Attachments.Length ||
            session.Attachments.Select(a => a.Sha256).Distinct().Count() != session.Attachments.Length)
            throw new InvalidDataException("Duplicate/excessive evidence.");
        foreach (var attachment in session.Attachments)
        {
            RequireStep(attachment.ScenarioId, attachment.StepId); ScenarioCatalog.ValidateToken(attachment.Id);
            if (attachment.MediaType != "image/png" || attachment.Classification != EvidenceKind.UnverifiedClaim ||
                attachment.Bytes is < 1 or > Screenshot.MaximumBytes || attachment.Sha256 is not { Length: 64 } ||
                attachment.At < session.Created || attachment.At > session.Updated) throw new InvalidDataException("Invalid evidence metadata.");
        }
        if (session.Bugs.Length > 1000) throw new InvalidDataException("Too many bug revisions.");
        Dictionary<string, int> bugs = [];
        foreach (var bug in session.Bugs)
        {
            RequireStep(bug.ScenarioId, bug.StepId); ScenarioCatalog.ValidateToken(bug.Id);
            if (bug.Revision != bugs.GetValueOrDefault(bug.Id) + 1 || bug.At < session.Created || bug.At > session.Updated || bug.Severity is not ("P0" or "P1" or "P2" or "P3") ||
                bug.EvidenceIds is null || bug.EvidenceIds.Distinct().Count() != bug.EvidenceIds.Length ||
                bug.EvidenceIds.Any(e => !session.Attachments.Any(a => a.Id == e && a.ScenarioId == bug.ScenarioId && a.StepId == bug.StepId && a.ReviewedForSharing)))
                throw new InvalidDataException("Invalid bug history or unreviewed evidence.");
            Text(bug.Expected, true); Text(bug.Actual, true); Text(bug.Reproduction, true);
            bugs[bug.Id] = bug.Revision;
        }
    }
    private static void Text(string text, bool required = false)
    {
        if (text is null || text.Length > 8000 || (required && string.IsNullOrWhiteSpace(text))) throw new InvalidDataException("Text must be at most 8000 characters and required fields cannot be blank.");
    }
    private Scenario Scenario(string id) => catalog.Scenarios.SingleOrDefault(s => s.Id == id) ?? throw new InvalidDataException("Unknown scenario.");
    private void RequireStep(string scenario, string step)
    {
        if (!Scenario(scenario).Steps.Any(s => s.Id == step)) throw new InvalidDataException("Unknown step.");
    }
    private static void RequireRisk(BetaSession session, Scenario scenario, TestResult result)
    {
        if (scenario.Risk == Risk.HighRisk && result is TestResult.PASS or TestResult.FAIL or TestResult.NEEDS_REVIEW && !session.AuthorizedHighRiskScenarios.Contains(scenario.Id))
            throw new InvalidOperationException("Separate scenario-specific high-risk authorization required. Ordinary smoke consent is insufficient.");
    }
    private static void VerifyAttachments(string folder, BetaSession session)
    {
        foreach (var attachment in session.Attachments)
        {
            byte[] bytes = OwnedFiles.Read(Path.Combine(folder, attachment.Id + ".png"), Screenshot.MaximumBytes);
            if (bytes.LongLength != attachment.Bytes || OwnedFiles.Hash(bytes) != attachment.Sha256) throw new InvalidDataException("Missing or changed screenshot; preserve session and original evidence.");
        }
    }
    private static void Publish(string folder, BetaSession session, string previous, (string Path, byte[] Bytes)? attachment = null)
    {
        string digest = OwnedFiles.Hash(JsonSerializer.SerializeToUtf8Bytes(session, BetaJson.Options));
        byte[] raw = JsonSerializer.SerializeToUtf8Bytes(new RevisionEnvelope(1, previous, digest, session), BetaJson.Options);
        if (Directory.EnumerateFiles(folder, "revision-*.json").Sum(p => new FileInfo(p).Length) + raw.Length > 128L * 1024 * 1024)
            throw new InvalidDataException("Session history budget reached; export and start another session.");
        if (raw.Length > OwnedFiles.MaximumJsonBytes) throw new InvalidDataException("Session revision exceeds storage budget.");
        bool created = false;
        try
        {
            if (attachment is { } pending)
            {
                OwnedFiles.NoLinks(pending.Path);
                using var stream = new FileStream(pending.Path, FileMode.CreateNew, FileAccess.Write, FileShare.None);
                created = true; stream.Write(pending.Bytes); stream.Flush(true);
            }
            OwnedFiles.CommitNew(RevisionPath(folder, session.Revision), raw);
            SessionHead? oldHead = null;
            if (File.Exists(Path.Combine(folder, "head.json"))) oldHead = ReadHead(folder);
            OwnedFiles.Replace(Path.Combine(folder, "head.json"), JsonSerializer.SerializeToUtf8Bytes(new SessionHead(1, session.Id, session.Revision, OwnedFiles.Hash(raw), oldHead?.RecoveredFromHeadSha256, oldHead?.RecoveryUtc), BetaJson.Options));
        }
        catch
        {
            // No published revision can reference this PNG yet. Remove only our
            // unchanged newly created bytes (or their partial-write prefix).
            // A published revision/head gap retains pixels for recovery review.
            if (created && attachment is { } pending && !Path.Exists(RevisionPath(folder, session.Revision)))
            {
                var actual = OwnedFiles.Read(pending.Path, Screenshot.MaximumBytes);
                if (actual.Length <= pending.Bytes.Length && actual.AsSpan().SequenceEqual(pending.Bytes.AsSpan(0, actual.Length))) File.Delete(OwnedFiles.NoLinks(pending.Path));
            }
            throw;
        }
    }
    private BetaSession Update(Guid id, int expectedRevision, Func<BetaSession, BetaSession> change, (string Path, byte[] Bytes)? attachment = null)
    {
        string folder = Folder(id); using var guard = Lock(folder);
        var current = ReadChain(folder, id);
        if (current.Session.Revision != expectedRevision) throw new InvalidOperationException("Session changed. Reload before recording another result.");
        if (current.Session.State == "Completed") throw new InvalidOperationException("Completed session is immutable; create a new session.");
        var changed = change(current.Session);
        if (ReferenceEquals(changed, current.Session)) return current.Session;
        var next = changed with { Revision = expectedRevision + 1, Updated = DateTimeOffset.UtcNow };
        Validate(next, id, next.Revision);
        Publish(folder, next, current.Hash, attachment);
        return next;
    }
    public BetaSession AppendNativeReceipt(Guid id, int expectedRevision, NativeReceipt receipt) => Update(id, expectedRevision, current =>
    {
        receipt.Validate(); RequireStep(receipt.Scenario, receipt.Step);
        if (receipt.BetaSession != id.ToString("N")) throw new InvalidDataException("Native receipt belongs to another beta session.");
        var receipts = current.NativeReceipts ?? [];
        var existing = receipts.SingleOrDefault(r => r.Session == receipt.Session);
        if (existing is not null)
        {
            if (!NativeReceipt.Same(existing, receipt)) throw new InvalidDataException("Native transaction receipt changed; preserve the original.");
            return current;
        }
        // Freeze caller-owned arrays before publication.
        var frozen = NativeReceipt.Parse(JsonSerializer.SerializeToUtf8Bytes(receipt, BetaJson.Options));
        return current with { NativeReceipts = [..receipts, frozen] };
    });
    public BetaSession Record(Guid id, int revision, string scenario, string step, TestResult result, string actual) => Update(id, revision, current =>
    {
        if (current.State != "Active") throw new InvalidOperationException("Resume the paused session before recording.");
        RequireStep(scenario, step); RequireRisk(current, Scenario(scenario), result); Text(actual);
        var observations = new Dictionary<string, StepObservation>(current.Observations)
        { [BetaSession.Key(scenario, step)] = new(scenario, step, result, actual, DateTimeOffset.UtcNow) };
        return current with { Observations = observations };
    });
    public BetaSession SetState(Guid id, int revision, string state) => Update(id, revision, current => current with { State = state });
    public BetaSession AuthorizeHighRisk(Guid id, int revision, string scenario, string typedPhrase) => Update(id, revision, current =>
    {
        if (Scenario(scenario).Risk != Risk.HighRisk || typedPhrase != "AUTHORIZE HIGH RISK " + scenario) throw new InvalidOperationException("Exact scenario-specific authorization phrase required.");
        return current with { AuthorizedHighRiskScenarios = current.AuthorizedHighRiskScenarios.Append(scenario).Distinct().ToArray() };
    });
    public BetaSession Attach(Guid id, int revision, string scenario, string step, byte[] png, bool reviewedForSharing)
    {
        byte[] clean = Screenshot.Sanitize(png); string hash = OwnedFiles.Hash(clean);
        string evidenceId = "e-" + Guid.NewGuid().ToString("N");
        return Update(id, revision, current =>
        {
            RequireStep(scenario, step);
            if (current.Attachments.Any(a => a.Sha256 == hash)) throw new InvalidOperationException("Duplicate screenshot; capture new evidence for this step.");
            return current with { Attachments = [..current.Attachments, new(evidenceId, scenario, step, hash, clean.Length, DateTimeOffset.UtcNow, "image/png", EvidenceKind.UnverifiedClaim, reviewedForSharing)] };
        }, (Path.Combine(Folder(id), evidenceId + ".png"), clean));
    }
    public BetaSession ReportBug(Guid id, int revision, string scenario, string step, string expected, string actual, string reproduction, string severity,
        string[] evidenceIds, string? existingId = null) => Update(id, revision, current =>
    {
        RequireStep(scenario, step);
        string bugId = existingId ?? "bug-" + Guid.NewGuid().ToString("N");
        if (existingId is not null && !current.Bugs.Any(b => b.Id == existingId && b.ScenarioId == scenario && b.StepId == step)) throw new InvalidDataException("Unknown issue identity.");
        int bugRevision = current.Bugs.Count(b => b.Id == bugId) + 1;
        return current with { Bugs = [..current.Bugs, new(bugId, bugRevision, scenario, step, expected, actual, reproduction, severity, DateTimeOffset.UtcNow, evidenceIds)] };
    });
    public void Delete(Guid id, int revision, string typedPhrase)
    {
        if (typedPhrase != "DELETE " + id.ToString("N")) throw new InvalidOperationException("Exact session deletion phrase required.");
        string folder = Folder(id); using var guard = Lock(folder);
        var current = ReadChain(folder, id);
        if (current.Session.Revision != revision) throw new InvalidOperationException("Reload changed session before deletion.");
        // Allow only files owned by this store. Never recurse into unknown directories or follow links.
        var known = current.Session.Attachments.Select(a => a.Id + ".png").Append("writer.lock").Append("head.json")
            .Concat(Enumerable.Range(0, revision + 1).Select(r => Path.GetFileName(RevisionPath(folder, r)))).ToHashSet(StringComparer.Ordinal);
        var entries = Directory.GetFileSystemEntries(folder);
        foreach (var entry in entries)
        {
            OwnedFiles.NoLinks(entry);
            if (Directory.Exists(entry) || !known.Contains(Path.GetFileName(entry))) throw new IOException("Unknown files present; automatic deletion refused. Review the session directory manually.");
        }
        foreach (var entry in entries.Where(e => Path.GetFileName(e) != "writer.lock"))
        {
            OwnedFiles.NoLinks(entry); File.Delete(entry);
        }
        guard.Dispose();
        File.Delete(OwnedFiles.NoLinks(Path.Combine(folder, "writer.lock")));
        Directory.Delete(folder, false); // Unknown concurrent additions prevent removal.
    }
}
