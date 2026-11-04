using System.Buffers.Binary;
using System.IO.Compression;
using System.Text;
using System.Text.Json;
using RouteKeeper.Beta;

if (args is ["--verify-native-summary", var summaryPath])
{
    _ = NativeReceipt.Parse(OwnedFiles.Read(summaryPath, NativeReceipt.MaximumBytes));
    Console.WriteLine("PASS sanitized PowerShell summary accepted by the strict process-only C# contract; gameplay NOT_RUN.");
    return;
}

int checks = 0;
void Check(bool condition, string name) { if (!condition) throw new Exception(name); checks++; Console.WriteLine("PASS " + name); }
void Refuses(Action action, string name)
{
    try { action(); }
    catch (Exception e) when (e is IOException or InvalidDataException or InvalidOperationException or JsonException or ArgumentException) { checks++; Console.WriteLine("PASS " + name); return; }
    throw new Exception("Accepted: " + name);
}
// Resolve only the fixture's system temp alias; production no-link policy remains strict.
string temporary = Path.GetTempPath();
if (OperatingSystem.IsMacOS() && temporary.StartsWith("/var/", StringComparison.Ordinal)) temporary = "/private" + temporary;
string root = Path.Combine(temporary, "rk-beta-test-" + Guid.NewGuid().ToString("N"));
Directory.CreateDirectory(root);
try
{
    var catalog = ScenarioCatalog.Load();
    Check(catalog.Scenarios.Length == 82 && catalog.Scenarios.Sum(s => s.Steps.Length) == 434, "catalog contains 82 versioned bilingual scenarios and 434 source-backed steps");
    checks += ScenarioCatalogContract.Run(catalog);
    checks += NativeReceiptContract.Run(catalog);
    checks += TestingHistoryContract.Run(root, catalog);
    Check(catalog.Scenarios.Where(s => s.Id.StartsWith("neutral-", StringComparison.Ordinal)).Count() == 19, "Any Neutral and all 18 specific target IDs represented");
    Check(catalog.Scenarios.Single(s => s.Id == "reset").Risk == Risk.HighRisk && catalog.Scenarios.Single(s => s.Id == "save-load").Risk == Risk.HighRisk, "SAVE and RESET excluded from smoke authorization");
    var duplicate = catalog with { Scenarios = [catalog.Scenarios[0], catalog.Scenarios[0]] };
    Refuses(duplicate.Validate, "duplicate scenario IDs refused");
    Refuses(() => (catalog with { Schema = 2 }).Validate(), "future catalog schema refuses");
    Refuses(() => (catalog with { Scenarios = [catalog.Scenarios[0] with { Title = new("", "") }] }).Validate(), "missing translations refused");
    var store = new SessionStore(Path.Combine(root, "sessions"), catalog);
    var config = new SessionConfiguration("en", "Passive", "SYNTHETIC", "TEST");
    Refuses(() => store.Create(config with { Mode = "unexpected" }), "invalid configuration refused");
    var session = store.Create(config); Guid id = session.Id;
    Check(store.List().SequenceEqual([id]) && session.Revision == 0 && session.State == "Active", "new session is locally discoverable");
    Check(session.Observations.Count == 0 && session.Attachments.Length == 0, "privacy default collects no screenshots or personal metadata");
    var scenario = catalog.Scenarios.Single(s => s.Id == "f10");
    Check(session.Result(scenario) == TestResult.NOT_RUN, "new scenario NOT_RUN");
    session = store.Record(id, session.Revision, "f10", "exercise", TestResult.PASS, "Synthetic tester observation");
    Check(session.Result(scenario) == TestResult.NOT_RUN, "one passing step never passes scenario");
    var restarted = new SessionStore(Path.Combine(root, "sessions"), catalog);
    Check(restarted.Load(id).Observations.Count == 1, "committed observation survives store restart");
    Refuses(() => store.Record(id, 0, "f10", "confirm", TestResult.PASS, "stale"), "stale concurrent revision refused");
    Refuses(() => store.Record(id, session.Revision, "f10", "unknown", TestResult.PASS, "x"), "unknown step refused");
    Refuses(() => store.Record(id, session.Revision, "f10", "confirm", (TestResult)99, "x"), "invalid result refused");
    Refuses(() => store.Record(id, session.Revision, "f10", "confirm", TestResult.PASS, ""), "empty executed observation refused");
    session = store.Record(id, session.Revision, "f10", "confirm", TestResult.PASS, "Synthetic confirmation");
    Check(session.Result(scenario) == TestResult.PASS, "all applicable steps PASS aggregates to human PASS");
    var row = Reports.Summarize(session, catalog).Single(s => s.Id == "f10");
    Check(row.HumanReportedResult == TestResult.PASS && row.IndependentVerificationStatus == "NOT_RUN" && row.AutomatedStatus == "NOT_RUN", "human PASS does not certify independent or automated status");
    foreach (var value in new[] { TestResult.FAIL, TestResult.BLOCKED, TestResult.NEEDS_REVIEW, TestResult.NOT_RUN })
    {
        session = store.Record(id, session.Revision, "f10", "exercise", value, "Synthetic status");
        Check(session.Result(scenario) == value, "aggregate preserves " + value);
    }
    session = store.Record(id, session.Revision, "f10", "exercise", TestResult.NOT_APPLICABLE, "Reason for non-applicability");
    session = store.Record(id, session.Revision, "f10", "confirm", TestResult.NOT_APPLICABLE, "Reason for non-applicability");
    Check(session.Result(scenario) == TestResult.NOT_APPLICABLE, "all NOT_APPLICABLE is not PASS");
    session = store.SetState(id, session.Revision, "Paused");
    Refuses(() => store.Record(id, session.Revision, "f10", "exercise", TestResult.FAIL, "paused"), "paused session refuses results");
    session = store.SetState(id, session.Revision, "Active");
    Refuses(() => store.Record(id, session.Revision, "reset", "exercise", TestResult.PASS, "unauthorized"), "high-risk human result refuses ordinary session scope");
    session = store.Record(id, session.Revision, "reset", "exercise", TestResult.BLOCKED, "No high-risk authorization");
    Refuses(() => store.AuthorizeHighRisk(id, session.Revision, "reset", "yes"), "generic high-risk consent refused");
    session = store.AuthorizeHighRisk(id, session.Revision, "reset", "AUTHORIZE HIGH RISK reset");
    session = store.Record(id, session.Revision, "reset", "exercise", TestResult.PASS, "Synthetic authorized observation, not real RESET");
    Check(session.AuthorizedHighRiskScenarios.SequenceEqual(["reset"]), "high-risk scope stays scenario-specific");
    Refuses(() => store.Record(id, session.Revision, "save-load", "exercise", TestResult.PASS, "x"), "RESET authorization cannot authorize SAVE/LOAD");
    byte[] png = Png("PRIVATE USER METADATA"); byte[] clean = Screenshot.Sanitize(png);
    Check(!Encoding.Latin1.GetString(clean).Contains("PRIVATE USER METADATA", StringComparison.Ordinal), "PNG ancillary metadata removed");
    Check(clean.Length < png.Length && Screenshot.Sanitize(clean).SequenceEqual(clean), "PNG pixel data stable on sanitized reimport");
    var bad = png.ToArray(); bad[29] ^= 1;
    Refuses(() => Screenshot.Sanitize(bad), "PNG CRC damage refused");
    Refuses(() => Screenshot.Sanitize([1, 2, 3]), "non-PNG refused");
    Refuses(() => Screenshot.Sanitize([..png, 0]), "trailing PNG payload refused");
    Refuses(() => Screenshot.Sanitize(Png("", excessive: true)), "decompression dimensions bounded");
    Refuses(() => Screenshot.ValidateDimensions(Png("", excessive: true)), "image import bounds dimensions before invoking the platform decoder");
    byte[] hidden = Screenshot.Sanitize(Png("", hidden: "PRIVATE-HIDDEN-IDAT"));
    Check(!Encoding.Latin1.GetString(hidden).Contains("PRIVATE-HIDDEN-IDAT", StringComparison.Ordinal) && hidden.SequenceEqual(Screenshot.Sanitize(Png(""))), "canonical compression strips non-pixel data hidden after the zlib stream");
    session = store.Attach(id, session.Revision, "f10", "exercise", png, false);
    var unreviewed = session.Attachments[0];
    Check(!unreviewed.ReviewedForSharing && unreviewed.Classification == EvidenceKind.UnverifiedClaim, "unreviewed PNG stays private and unverified");
    Refuses(() => store.ReadAttachment(id, session.Revision, unreviewed.Id), "unreviewed evidence cannot be exported");
    Refuses(() => store.Attach(id, session.Revision, "f10", "confirm", png, true), "same pixels reused for another step refused");
    var privateReport = Reports.Build(session, catalog, new(true, []));
    Check(privateReport.Evidence.Length == 0, "opt-in export still excludes unreviewed pixels");
    Check(store.ReadPrivateAttachment(id, session.Revision, unreviewed.Id).SequenceEqual(clean), "private evidence remains locally reviewable");
    Refuses(() => store.ReviewAttachment(id, session.Revision, unreviewed.Id, "wrong"), "review cannot approve different screenshot bytes");
    session = store.Attach(id, session.Revision, "f10", "confirm", Png("", color: 220), true);
    var reviewed = session.Attachments[1];
    session = store.ReportBug(id, session.Revision, "f10", "confirm", "Expected <script>alert(1)</script>", "PRIVATE-NAME actual", "PRIVATE-NAME reproduce", "P2", [reviewed.Id]);
    var bug = session.Bugs[0];
    session = store.ReportBug(id, session.Revision, "f10", "confirm", "updated expected", "updated actual", "updated reproduce", "P1", [reviewed.Id], bug.Id);
    Check(session.Bugs.Length == 2 && session.Bugs.All(b => b.Id == bug.Id) && session.Bugs[1].Revision == 2, "stable bug identity retains revision history");
    Refuses(() => store.ReportBug(id, session.Revision, "f10", "exercise", "a", "b", "c", "P2", [unreviewed.Id]), "issue cannot include unreviewed screenshot");
    Refuses(() => store.ReportBug(id, session.Revision, "f10", "exercise", "a", "b", "c", "P9", []), "invalid severity refused");
    var sanitized = Reports.Build(session, catalog, new(false, ["PRIVATE-NAME"]));
    Check(!JsonSerializer.Serialize(sanitized, BetaJson.Options).Contains("PRIVATE-NAME", StringComparison.Ordinal), "text redaction applies to bug history");
    Check(sanitized.Evidence.Length == 0 && sanitized.Bugs.All(b => b.EvidenceIds.Length == 0), "default export drops pixels and dangling evidence IDs");
    Refuses(() => Reports.Build(session, catalog, new(false, [""])), "empty redaction phrase refused");
    string export = Path.Combine(root, "export");
    Reports.Export(store, id, session.Revision, catalog, export, new(false, ["PRIVATE-NAME"])); Reports.VerifyExport(export);
    Check(Directory.GetFiles(export).Length == 4, "offline JSON HTML CSV plus integrity manifest only");
    string html = File.ReadAllText(Path.Combine(export, "report.html"));
    Check(html.Contains("&lt;script&gt;", StringComparison.Ordinal) && !html.Contains("<script>", StringComparison.Ordinal), "HTML escapes tester markup");
    Check(!html.Contains("PRIVATE-NAME", StringComparison.Ordinal), "HTML has redacted observations");
    Refuses(() => Reports.Export(store, id, session.Revision, catalog, export, new(false, [])), "existing exports never overwritten");
    File.AppendAllText(Path.Combine(export, "report.html"), "tampered");
    Refuses(() => Reports.VerifyExport(export), "changed offline report refused by integrity validation");
    string pixelExport = Path.Combine(root, "reviewed-export");
    Reports.Export(store, id, session.Revision, catalog, pixelExport, new(true, [])); Reports.VerifyExport(pixelExport);
    Check(Directory.GetFiles(pixelExport, "*.png").Length == 1, "explicit export includes only reviewed PNG");
    Check(store.ReadAttachment(id, session.Revision, reviewed.Id).SequenceEqual(Screenshot.Sanitize(Png("", color: 220))), "export screenshot hash binds exact sanitized bytes");
    string folder = Path.Combine(root, "sessions", id.ToString("N"));
    File.WriteAllText(Path.Combine(folder, "revision-00000099.json.pending-crash"), "incomplete uncommitted write");
    Check(store.Load(id).Revision == session.Revision, "uncommitted crash file never becomes a revision");
    Refuses(() => store.Delete(id, session.Revision, "DELETE " + id.ToString("N")), "unknown pending evidence prevents destructive cleanup");
    File.Delete(Path.Combine(folder, "revision-00000099.json.pending-crash"));
    byte[] first = File.ReadAllBytes(Path.Combine(folder, "revision-00000000.json"));
    File.AppendAllText(Path.Combine(folder, "revision-00000000.json"), "CORRUPT");
    Refuses(() => store.Load(id), "corrupt committed revision refuses silent rollback");
    File.WriteAllBytes(Path.Combine(folder, "revision-00000000.json"), first);
    string missingPath = Path.Combine(folder, "revision-00000001.json"); byte[] missing = File.ReadAllBytes(missingPath); File.Delete(missingPath);
    Refuses(() => store.Load(id), "middle revision gap refused"); File.WriteAllBytes(missingPath, missing);
    string lastPath = Path.Combine(folder, $"revision-{session.Revision:D8}.json"); byte[] last = File.ReadAllBytes(lastPath); File.Delete(lastPath);
    Refuses(() => store.Load(id), "removed last revision cannot silently roll back committed results"); File.WriteAllBytes(lastPath, last);
    string headPath = Path.Combine(folder, "head.json"); byte[] head = File.ReadAllBytes(headPath); File.Delete(headPath);
    Refuses(() => store.Load(id), "missing publication head preserves history and refuses guessed recovery"); File.WriteAllBytes(headPath, head);
    var different = catalog with { Version = catalog.Version + 1 };
    Refuses(() => new SessionStore(Path.Combine(root, "sessions"), different).Load(id), "changed catalog cannot silently reinterpret old results");
    string evidencePath = Path.Combine(folder, reviewed.Id + ".png"); byte[] pixels = File.ReadAllBytes(evidencePath); File.AppendAllText(evidencePath, "changed");
    Refuses(() => store.Load(id), "modified attachment invalidates session evidence"); File.WriteAllBytes(evidencePath, pixels);
    session = store.SetState(id, session.Revision, "Completed");
    Refuses(() => store.Record(id, session.Revision, "f10", "confirm", TestResult.FAIL, "x"), "completed sessions are immutable");
    Refuses(() => store.SetState(id, session.Revision, "Active"), "completed session cannot be silently resumed");
    Refuses(() => store.Delete(id, session.Revision, "yes"), "deletion requires exact session confirmation");
    store.Delete(id, session.Revision, "DELETE " + id.ToString("N"));
    Check(!Directory.Exists(folder) && store.List().Length == 0, "explicit deletion removes only known session data");
    Check(File.Exists(Path.Combine(pixelExport, reviewed.Id + ".png")), "session deletion leaves separately exported copies intact");
    var reviewSession = store.Create(config);
    reviewSession = store.Attach(reviewSession.Id, reviewSession.Revision, "f10", "exercise", png, false);
    var reviewItem = reviewSession.Attachments[0];
    reviewSession = store.ReviewAttachment(reviewSession.Id, reviewSession.Revision, reviewItem.Id, reviewItem.Sha256);
    Check(reviewSession.Attachments[0].ReviewedForSharing && store.ReadAttachment(reviewSession.Id, reviewSession.Revision, reviewItem.Id).SequenceEqual(clean), "separate pixel review records a new revision without reimporting duplicate evidence");
    var contention = store.Create(config);
    int succeeded = 0, refused = 0;
    using var barrier = new Barrier(2);
    var writers = Enumerable.Range(0, 2).Select(index => Task.Run(() =>
    {
        barrier.SignalAndWait();
        try { store.Record(contention.Id, 0, "f10", "exercise", TestResult.PASS, "Concurrent writer " + index); Interlocked.Increment(ref succeeded); }
        catch (Exception e) when (e is IOException or InvalidOperationException) { Interlocked.Increment(ref refused); }
    })).ToArray();
    Task.WaitAll(writers);
    Check(succeeded == 1 && refused == 1 && store.Load(contention.Id).Revision == 1, "concurrent writers cannot lose a committed update");
    string contentionFolder = Path.Combine(root, "sessions", contention.Id.ToString("N"));
    using (var locked = new FileStream(Path.Combine(contentionFolder, "writer.lock"), FileMode.Open, FileAccess.ReadWrite, FileShare.None))
        Refuses(() => store.Load(contention.Id), "locked session visibly refuses instead of reading a partial transaction");
    string revisionFile = Path.Combine(contentionFolder, "revision-00000001.json");
    string commitHead = Path.Combine(contentionFolder, "head.json");
    byte[] revisionBytes = File.ReadAllBytes(revisionFile), headBytes = File.ReadAllBytes(commitHead);
    var envelope = JsonSerializer.Deserialize<RevisionEnvelope>(revisionBytes, BetaJson.Options)!;
    var future = envelope.Payload with { Schema = 99 };
    byte[] futureBytes = JsonSerializer.SerializeToUtf8Bytes(envelope with { Payload = future, PayloadSha256 = OwnedFiles.Hash(JsonSerializer.SerializeToUtf8Bytes(future, BetaJson.Options)) }, BetaJson.Options);
    File.WriteAllBytes(revisionFile, futureBytes);
    File.WriteAllBytes(commitHead, JsonSerializer.SerializeToUtf8Bytes(new SessionHead(1, contention.Id, 1, OwnedFiles.Hash(futureBytes)), BetaJson.Options));
    Refuses(() => store.Load(contention.Id), "future schema refuses even with locally recomputed consistency hashes");
    File.WriteAllBytes(revisionFile, revisionBytes); File.WriteAllBytes(commitHead, headBytes);
    var notRun = store.Create(config);
    notRun = store.Record(notRun.Id, notRun.Revision, "f10", "exercise", TestResult.NOT_RUN, "");
    notRun = store.Record(notRun.Id, notRun.Revision, "f10", "confirm", TestResult.NOT_RUN, "");
    var emptyCoverage = Reports.Summarize(notRun, catalog).Single(r => r.Id == "f10");
    Check(emptyCoverage.HumanExecutionStatus == "NOT_STARTED" && emptyCoverage.EvidenceCompleteness == "MISSING", "explicit NOT_RUN entries cannot manufacture execution or complete evidence");
    var capacity = store.Create(config); string capacityFolder = Path.Combine(root, "sessions", capacity.Id.ToString("N"));
    List<EvidenceAttachment> fullEvidence = [];
    for (int index = 0; index < 500; index++)
    {
        string evidenceId = "e-capacity-" + index; byte[] pixel = Screenshot.Sanitize(Png("", color: (byte)(index % 256), green: (byte)(index / 256)));
        File.WriteAllBytes(Path.Combine(capacityFolder, evidenceId + ".png"), pixel);
        fullEvidence.Add(new(evidenceId, "f10", "exercise", OwnedFiles.Hash(pixel), pixel.Length, capacity.Created, "image/png", EvidenceKind.UnverifiedClaim, false));
    }
    capacity = capacity with { Attachments = fullEvidence.ToArray() };
    byte[] fullRaw = JsonSerializer.SerializeToUtf8Bytes(new RevisionEnvelope(1, "", OwnedFiles.Hash(JsonSerializer.SerializeToUtf8Bytes(capacity, BetaJson.Options)), capacity), BetaJson.Options);
    File.WriteAllBytes(Path.Combine(capacityFolder, "revision-00000000.json"), fullRaw);
    File.WriteAllBytes(Path.Combine(capacityFolder, "head.json"), JsonSerializer.SerializeToUtf8Bytes(new SessionHead(1, capacity.Id, 0, OwnedFiles.Hash(fullRaw)), BetaJson.Options));
    Check(store.Load(capacity.Id).Attachments.Length == 500, "synthetic full-capacity session validates before negative attachment test");
    Refuses(() => store.Attach(capacity.Id, 0, "f10", "exercise", Png("", color: 1, green: 3), false), "screenshot capacity refusal occurs before publishing private pixels");
    Check(Directory.GetFiles(capacityFolder, "*.png").Length == 500 && store.Load(capacity.Id).Revision == 0, "failed attachment leaves no orphan pixels and preserves the committed session");
    var interrupted = store.Create(config); string interruptedFolder = Path.Combine(root, "sessions", interrupted.Id.ToString("N"));
    byte[] beforeHead = File.ReadAllBytes(Path.Combine(interruptedFolder, "head.json"));
    interrupted = store.Record(interrupted.Id, 0, "f10", "exercise", TestResult.PASS, "SYNTHETIC pending human result");
    byte[] pendingRevision = File.ReadAllBytes(Path.Combine(interruptedFolder, "revision-00000001.json"));
    File.WriteAllBytes(Path.Combine(interruptedFolder, "head.json"), beforeHead);
    Refuses(() => store.Load(interrupted.Id), "interrupted head publication is not silently resumed");
    var recovery = store.InspectPublicationRecovery(interrupted.Id);
    Check(recovery.PendingRevision == 1 && recovery.Pending.Observations.Count == 1, "explicit recovery inspection validates the single contiguous pending change");
    Refuses(() => store.RecoverPublication(interrupted.Id, recovery.OldHeadSha256, recovery.PendingSha256, "yes"), "recovery requires an exact session-specific phrase");
    Refuses(() => store.RecoverPublication(interrupted.Id, recovery.OldHeadSha256, "stale", "RECOVER SESSION " + interrupted.Id.ToString("N")), "recovery refuses a changed or stale pending revision hash");
    File.AppendAllText(Path.Combine(interruptedFolder, "head.json"), " ");
    Refuses(() => store.RecoverPublication(interrupted.Id, recovery.OldHeadSha256, recovery.PendingSha256, "RECOVER SESSION " + interrupted.Id.ToString("N")), "recovery also binds the exact reviewed predecessor head bytes");
    File.WriteAllBytes(Path.Combine(interruptedFolder, "head.json"), beforeHead);
    interrupted = store.RecoverPublication(interrupted.Id, recovery.OldHeadSha256, recovery.PendingSha256, "RECOVER SESSION " + interrupted.Id.ToString("N"));
    Check(store.Load(interrupted.Id).Revision == 1 && File.ReadAllBytes(Path.Combine(interruptedFolder, "revision-00000001.json")).SequenceEqual(pendingRevision), "recovery commits only the validated head and preserves every immutable revision");
    var recoveryHead = JsonSerializer.Deserialize<SessionHead>(File.ReadAllBytes(Path.Combine(interruptedFolder, "head.json")), BetaJson.Options)!;
    Check(recoveryHead.RecoveredFromHeadSha256 == recovery.OldHeadSha256 && recoveryHead.RecoveryUtc is not null, "publication head retains the explicit recovery receipt");
    byte[] committedOne = File.ReadAllBytes(Path.Combine(interruptedFolder, "head.json"));
    interrupted = store.Attach(interrupted.Id, interrupted.Revision, "f10", "exercise", Png(""), false);
    string pendingPixel = Path.Combine(interruptedFolder, interrupted.Attachments[0].Id + ".png"); byte[] pendingPixelBytes = File.ReadAllBytes(pendingPixel);
    File.WriteAllBytes(Path.Combine(interruptedFolder, "head.json"), committedOne); File.AppendAllText(pendingPixel, "CORRUPT");
    Refuses(() => store.InspectPublicationRecovery(interrupted.Id), "recovery refuses changed referenced private pixels");
    File.WriteAllBytes(pendingPixel, pendingPixelBytes);
    File.WriteAllBytes(Path.Combine(interruptedFolder, "head.json"), beforeHead);
    Refuses(() => store.InspectPublicationRecovery(interrupted.Id), "multiple uncommitted revisions cannot be guessed into recovery");
    File.WriteAllBytes(Path.Combine(interruptedFolder, "head.json"), committedOne);
    var pixelRecovery = store.InspectPublicationRecovery(interrupted.Id);
    interrupted = store.RecoverPublication(interrupted.Id, pixelRecovery.OldHeadSha256, pixelRecovery.PendingSha256, "RECOVER SESSION " + interrupted.Id.ToString("N"));
    Check(interrupted.Attachments.Length == 1 && File.ReadAllBytes(pendingPixel).SequenceEqual(pendingPixelBytes), "single pending screenshot attachment recovers without altering its bytes");
    var initialGap = store.Create(config); string initialFolder = Path.Combine(root, "sessions", initialGap.Id.ToString("N")); File.Delete(Path.Combine(initialFolder, "head.json"));
    var initialCandidate = store.InspectPublicationRecovery(initialGap.Id);
    Check(initialCandidate.PendingRevision == 0 && initialCandidate.OldHeadSha256 == "", "first-session creation gap has one explicit initial recovery candidate");
    store.RecoverPublication(initialGap.Id, "", initialCandidate.PendingSha256, "RECOVER SESSION " + initialGap.Id.ToString("N"));
    Check(store.Load(initialGap.Id).Revision == 0, "initial publication recovery commits only the validated initial record");
    var broken = envelope.Payload with { Configuration = null! };
    byte[] brokenBytes = JsonSerializer.SerializeToUtf8Bytes(envelope with { Payload = broken, PayloadSha256 = OwnedFiles.Hash(JsonSerializer.SerializeToUtf8Bytes(broken, BetaJson.Options)) }, BetaJson.Options);
    File.WriteAllBytes(revisionFile, brokenBytes);
    File.WriteAllBytes(commitHead, JsonSerializer.SerializeToUtf8Bytes(new SessionHead(1, contention.Id, 1, OwnedFiles.Hash(brokenBytes)), BetaJson.Options));
    Refuses(() => store.Load(contention.Id), "null configuration is a visible corruption refusal");
    File.WriteAllBytes(revisionFile, revisionBytes); File.WriteAllBytes(commitHead, headBytes);
    if (!OperatingSystem.IsWindows())
    {
        string outside = Path.Combine(root, "outside"); Directory.CreateDirectory(outside);
        string link = Path.Combine(root, "linked"); Directory.CreateSymbolicLink(link, outside);
        Refuses(() => new SessionStore(Path.Combine(link, "escape"), catalog), "linked ancestor refused");
        Check(Directory.GetFileSystemEntries(outside).Length == 0, "linked storage refusal leaves outside unchanged");
        Directory.Delete(link);
    }
    Console.WriteLine($"PASS: {checks} beta platform contract checks; synthetic only, Windows GUI/gameplay NOT_RUN.");
}
finally { Directory.Delete(root, true); }

static byte[] Png(string metadata, byte color = 120, bool excessive = false, string hidden = "", byte green = 0)
{
    using var file = new MemoryStream(); file.Write(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 });
    byte[] header = new byte[13]; BinaryPrimitives.WriteInt32BigEndian(header, excessive ? 100000 : 1); BinaryPrimitives.WriteInt32BigEndian(header.AsSpan(4), 1); header[8] = 8; header[9] = 6;
    Chunk(file, "IHDR", header);
    if (metadata.Length > 0) Chunk(file, "tEXt", Encoding.UTF8.GetBytes("Comment\0" + metadata));
    using var compressed = new MemoryStream();
    using (var zip = new ZLibStream(compressed, CompressionLevel.SmallestSize, true)) zip.Write(new byte[] { 0, color, green, 0, 255 });
    Chunk(file, "IDAT", [..compressed.ToArray(), ..Encoding.ASCII.GetBytes(hidden)]); Chunk(file, "IEND", []); return file.ToArray();
}
static void Chunk(Stream file, string type, byte[] payload)
{
    byte[] length = new byte[4]; BinaryPrimitives.WriteInt32BigEndian(length, payload.Length); file.Write(length);
    byte[] data = [..Encoding.ASCII.GetBytes(type), ..payload]; file.Write(data);
    uint crc = uint.MaxValue;
    foreach (byte b in data) { crc ^= b; for (int i = 0; i < 8; i++) crc = (crc >> 1) ^ ((crc & 1) != 0 ? 0xedb88320u : 0u); }
    BinaryPrimitives.WriteUInt32BigEndian(length, ~crc); file.Write(length);
}
