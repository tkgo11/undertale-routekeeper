using System.Text;
using System.Text.Json;
using RouteKeeper.Beta;

public static class NativeReceiptContract
{
    public static int Run(ScenarioCatalog catalog)
    {
        int checks = 0;
        void Check(bool ok, string name) { if (!ok) throw new Exception(name); checks++; }
        void Refuses(Action action) { try { action(); } catch (Exception e) when (e is InvalidDataException or InvalidOperationException or JsonException) { checks++; return; } throw new Exception("Native receipt accepted invalid data"); }
        string root = Path.Combine(Path.GetTempPath(), "rk-native-receipt-" + Guid.NewGuid().ToString("N"));
        if (OperatingSystem.IsMacOS() && root.StartsWith("/var/", StringComparison.Ordinal)) root = "/private" + root;
        try
        {
            var store = new SessionStore(root, catalog);
            var session = store.Create(new("en", "Passive", "SYNTHETIC", "TEST"));
            byte[] legacy = JsonSerializer.SerializeToUtf8Bytes(session, BetaJson.Options);
            Check(!Encoding.UTF8.GetString(legacy).Contains("NativeReceipts", StringComparison.Ordinal) && legacy.SequenceEqual(JsonSerializer.SerializeToUtf8Bytes(JsonSerializer.Deserialize<BetaSession>(legacy, BetaJson.Options), BetaJson.Options)), "legacy receipt-free payload retains exact hash bytes");
            var now = DateTimeOffset.UtcNow;
            var receipt = new NativeReceipt(1, Guid.NewGuid().ToString("N"), session.Id.ToString("N"), "f10", "exercise", "RESTORED", "patched", 0,
                "NOT_INDEPENDENTLY_VERIFIED", "HUMAN_REPORTED_ONLY", "CONTENT_TREE_VERIFIED", "NOT_RESTORED", new('a', 64), new('b', 64),
                [new("OWNED_PROCESS_STARTED", now.AddSeconds(-1), "AutomatedObservation", "PROCESS_ONLY_NOT_GAMEPLAY"),
                 new("HUMAN_SESSION_STOP_REQUESTED", now, "AutomatedObservation", "PROCESS_ONLY_NOT_GAMEPLAY")], now);
            byte[] Json(NativeReceipt r) => JsonSerializer.SerializeToUtf8Bytes(r, BetaJson.Options);
            Check(NativeReceipt.Parse(Json(receipt)).Events.Length == 2, "typed sanitized receipt roundtrip");
            Check(NativeReceipt.Parse(Json(receipt with { Events = [receipt.Events[0] with { Kind = "OWNED_PROCESS_ABNORMAL_EXIT" }] })).Events[0].Kind == "OWNED_PROCESS_ABNORMAL_EXIT", "abnormal process exit remains a process observation");
            Refuses(() => NativeReceipt.Parse(Encoding.UTF8.GetBytes(Encoding.UTF8.GetString(Json(receipt)).Replace("\"schema\": 1", "\"schema\": 1, \"schema\": 1", StringComparison.Ordinal))));
            Refuses(() => NativeReceipt.Parse(Encoding.UTF8.GetBytes(Encoding.UTF8.GetString(Json(receipt)).Replace("\"schema\": 1", "\"schema\": 1, \"privatePath\": \"secret\"", StringComparison.Ordinal))));
            Refuses(() => NativeReceipt.Parse(new byte[NativeReceipt.MaximumBytes + 1]));
            Refuses(() => (receipt with { Events = Enumerable.Repeat(receipt.Events[0], 201).ToArray() }).Validate());
            Refuses(() => NativeReceipt.Parse(Encoding.UTF8.GetBytes(Encoding.UTF8.GetString(Json(receipt)).Replace("\"kind\": \"OWNED_PROCESS_STARTED\"", "\"kind\": \"OWNED_PROCESS_STARTED\", \"file\": \"private-path\"", StringComparison.Ordinal))));
            Refuses(() => (receipt with { InputsDispatched = 1 }).Validate());
            Refuses(() => (receipt with { LocalRecovery = "UNVERIFIED_PRESERVE_ALL_COPIES" }).Validate());
            Refuses(() => (receipt with { Events = [receipt.Events[0] with { Kind = "GAMEPLAY_PASS" }] }).Validate());
            Refuses(() => (receipt with { Events = [receipt.Events[0] with { Scope = "GAMEPLAY" }] }).Validate());
            Refuses(() => (receipt with { Events = [receipt.Events[0] with { Utc = now.AddMinutes(1) }] }).Validate());
            Refuses(() => store.AppendNativeReceipt(session.Id, 0, receipt with { BetaSession = Guid.NewGuid().ToString("N") }));
            Refuses(() => store.AppendNativeReceipt(session.Id, 0, receipt with { Step = "unknown" }));
            session = store.AppendNativeReceipt(session.Id, 0, receipt);
            Check(session.Revision == 1 && store.Load(session.Id).NativeReceipts!.Length == 1, "receipt persisted across restart");
            Check(store.AppendNativeReceipt(session.Id, 1, NativeReceipt.Parse(Json(receipt))).Revision == 1, "same immutable transaction import is idempotent");
            Refuses(() => store.AppendNativeReceipt(session.Id, 0, receipt));
            Refuses(() => store.AppendNativeReceipt(session.Id, 1, receipt with { State = "BLOCKED" }));
            Check(store.Load(session.Id).Revision == 1, "refusal leaves revision unchanged");
            receipt.Events[0] = receipt.Events[0] with { Kind = "OPTIONAL_CAPTURE_REFUSED" };
            Check(store.Load(session.Id).NativeReceipts![0].Events[0].Kind == "OWNED_PROCESS_STARTED", "caller mutation cannot change published receipt");
            var report = Reports.Build(store.Load(session.Id), catalog, new(false, []));
            Check(report.NativeReceipts.Length == 1 && report.IndependentVerification == "NOT_RUN" && report.Scenarios.Single(s => s.Id == "f10").HumanReportedResult == TestResult.NOT_RUN, "process observations cannot pass human or independent gameplay");
            string output = Path.Combine(root, "export");
            Reports.Export(store, session.Id, 1, catalog, output, new(false, [])); Reports.VerifyExport(output);
            Check(File.ReadAllText(Path.Combine(output, "report.html")).Contains("PROCESS_ONLY", StringComparison.Ordinal), "reviewable process receipt exported separately");
            session = store.SetState(session.Id, 1, "Completed");
            Refuses(() => store.AppendNativeReceipt(session.Id, session.Revision, receipt with { Session = Guid.NewGuid().ToString("N") }));
        }
        finally { if (Directory.Exists(root)) Directory.Delete(root, true); }
        return checks;
    }
}
