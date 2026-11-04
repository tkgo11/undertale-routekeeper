using System.Diagnostics;
using System.IO;
using System.Security.Cryptography;
using System.Text.Json;

namespace RouteKeeper.Beta.Windows;

// Only a physical, OS-owned controller is started. This class has no game input API.
internal sealed class NativeController
{
    internal sealed record Trial(string Id, string Scenario, string Step);
    internal sealed record Binding(Guid BetaSession, string Work, string GameInstall, string SteamExe, Trial[] Trials);
    internal static string NativeBase => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "RouteKeeper", "Beta", "native");
    private static string References => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "RouteKeeper", "Beta", "native-ui");
    internal bool Busy { get; private set; }
    internal string? LastLogDirectory { get; private set; }
    internal Binding? ActiveBinding { get; private set; }
    internal Trial? ActiveTrial { get; private set; }
    private string? activeAction;
    internal static string NewWork() => Path.Combine(NativeBase, "prepared-" + Guid.NewGuid().ToString("N"));
    private static string Reference(Guid id) => Path.Combine(References, id.ToString("N") + ".json");
    internal static Guid[] ListReferences()
    {
        string directory = OwnedFiles.NoLinks(References);
        if (!Directory.Exists(directory)) return [];
        // Enumerate names only: corrupt or linked records remain visible by ID;
        // Load performs content/path validation and refuses them without deletion.
        var paths = Directory.EnumerateFiles(directory, "*.json", SearchOption.TopDirectoryOnly).Take(10001).ToArray();
        if (paths.Length > 10000) throw new InvalidDataException("Private native reference scan budget exceeded; preserve and inspect local storage.");
        var ids = paths.Select(Path.GetFileNameWithoutExtension).Where(name => name is not null &&
            System.Text.RegularExpressions.Regex.IsMatch(name, "^[a-f0-9]{32}$")).Select(name => Guid.ParseExact(name!, "N")).Take(1001).ToArray();
        if (ids.Length > 1000) throw new InvalidDataException("Private native reference count exceeds its budget.");
        return ids.Order().ToArray();
    }
    internal static void WithOwnedSmokeReference(Guid id, Action<Binding> inspect)
    {
        var binding = new Binding(id, NewWork(), Path.Combine(AppContext.BaseDirectory, "SYNTHETIC-NOT-AN-INSTALL"),
            Path.Combine(AppContext.BaseDirectory, "SYNTHETIC-NOT-STEAM.exe"), [new Trial(Guid.NewGuid().ToString("N"), "supported-build", "identify")]);
        bool created = false; byte[]? owned = null;
        try
        {
            Save(binding); created = true; owned = OwnedFiles.Read(Reference(id), 65536);
            inspect(binding); // Includes checklist deletion and UI selection; no native invocation.
            File.WriteAllText(OwnedFiles.NoLinks(Reference(id)), "{"); owned = [(byte)'{'];
            if (!ListReferences().Contains(id)) throw new InvalidOperationException("Corrupt native reference disappeared from recovery selection.");
            bool refused = false; try { Load(id); } catch (JsonException) { refused = true; }
            if (!refused || !File.Exists(Reference(id))) throw new InvalidOperationException("Corrupt native reference must refuse loading and remain preserved.");
        }
        finally
        {
            if (created)
            {
                // Remove only this synthetic invocation's unchanged JSON/lock;
                // never create or remove any game workspace, save or journal.
                if (owned is null || !OwnedFiles.Read(Reference(id), 65536).SequenceEqual(owned)) throw new InvalidOperationException("Synthetic reference changed; preserve it for inspection.");
                File.Delete(OwnedFiles.NoLinks(Reference(id))); File.Delete(OwnedFiles.NoLinks(Reference(id) + ".lock"));
            }
        }
    }
    internal static Binding? Load(Guid id)
    {
        if (!File.Exists(OwnedFiles.NoLinks(Reference(id)))) return null;
        var value = JsonSerializer.Deserialize<Binding>(OwnedFiles.Read(Reference(id), 65536), BetaJson.Options) ?? throw new InvalidDataException("Invalid private native reference.");
        Validate(value, id); return value;
    }
    private static void Validate(Binding value, Guid id)
    {
        string work = OwnedFiles.NoLinks(value.Work);
        if (value.BetaSession != id || !string.Equals(Path.GetDirectoryName(work), NativeBase, StringComparison.OrdinalIgnoreCase) ||
            !System.Text.RegularExpressions.Regex.IsMatch(Path.GetFileName(work), "^prepared-[a-f0-9]{32}$") || value.Trials is null || value.Trials.Length > 1000 ||
            value.Trials.Any(t => t is null || string.IsNullOrEmpty(t.Id) || !System.Text.RegularExpressions.Regex.IsMatch(t.Id, "^[a-f0-9]{32}$")) || value.Trials.Select(t => t.Id).Distinct().Count() != value.Trials.Length)
            throw new InvalidDataException("Native reference identity is invalid. Preserve it for local inspection.");
        OwnedFiles.NoLinks(value.GameInstall); OwnedFiles.NoLinks(value.SteamExe);
    }
    internal static void Save(Binding binding)
    {
        Validate(binding, binding.BetaSession); OwnedFiles.NoLinks(References); Directory.CreateDirectory(References);
        string path = OwnedFiles.NoLinks(Reference(binding.BetaSession));
        using var lease = new FileStream(OwnedFiles.NoLinks(path + ".lock"), FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None);
        if (File.Exists(path))
        {
            var prior = Load(binding.BetaSession) ?? throw new InvalidDataException("Native reference disappeared.");
            if (prior.Work != binding.Work || prior.GameInstall != binding.GameInstall || prior.SteamExe != binding.SteamExe ||
                binding.Trials.Length != prior.Trials.Length + 1 || !binding.Trials.Take(prior.Trials.Length).SequenceEqual(prior.Trials))
                throw new InvalidOperationException("Native reference changed in another app or would discard history. Reload it before retrying.");
        }
        byte[] bytes = JsonSerializer.SerializeToUtf8Bytes(binding, BetaJson.Options);
        if (bytes.Length > 65536) throw new InvalidDataException("Native reference budget reached; preserve this history and start a separate checklist.");
        string temporary = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
        using (var file = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None))
        { file.Write(bytes); file.Flush(true); }
        File.Move(temporary, path, true);
    }
    internal static string PolicyDisclosure()
    {
        using var policy = JsonDocument.Parse(OwnedFiles.Read(Path.Combine(AppContext.BaseDirectory, "tools", "runtime", "human-beta-policy.json"), 65536));
        if (policy.RootElement.GetProperty("id").GetString() != "routekeeper-human-beta-v1") throw new InvalidDataException("Unknown native policy.");
        return policy.RootElement.GetProperty("disclosure").GetString() ?? throw new InvalidDataException("Disclosure missing.");
    }
    internal static byte[] Request(Binding binding, Trial trial, SessionConfiguration configuration, Risk risk, string scope,
        string @case, int maximumSeconds, bool capture, string nonce, string phrase, string? highRiskPhrase, string continuationSession = "")
    {
        Validate(binding, binding.BetaSession);
        using var process = Process.GetCurrentProcess();
        string path = OwnedFiles.NoLinks(Environment.ProcessPath ?? throw new InvalidOperationException("Physical app identity unavailable."));
        if (!Path.GetFileName(path).Equals("RouteKeeper.Beta.Windows.exe", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Native launch requires the published physical Windows app, not dotnet or a development host.");
        string disclosure = PolicyDisclosure();
        return JsonSerializer.SerializeToUtf8Bytes(new
        {
            schema = 1, kind = "HUMAN_BETA_UI_REQUEST", id = trial.Id, betaSession = binding.BetaSession.ToString("N"),
            scenario = trial.Scenario, step = trial.Step, nonce, captureConsent = capture, diagnosticConsent = true,
            @case, scope, continuationSession, risk = risk.ToString(), phrase, highRiskPhrase, language = configuration.Language, mode = configuration.Mode,
            maximumSeconds, issuedUtc = DateTimeOffset.UtcNow.ToString("o"), policy = "routekeeper-human-beta-v1",
            disclosureSha256 = Convert.ToHexStringLower(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(disclosure))),
            parent = new { pid = process.Id, ticks = process.StartTime.ToUniversalTime().Ticks, path, sha256 = OwnedFiles.Hash(OwnedFiles.Read(path, 64 * 1024 * 1024)) }
        });
    }
    internal static string WriteRequest(Binding binding, Trial trial, byte[] bytes)
    {
        string directory = OwnedFiles.NoLinks(Path.Combine(binding.Work, "requests")); Directory.CreateDirectory(directory);
        string path = OwnedFiles.NoLinks(Path.Combine(directory, "request-" + trial.Id + ".json"));
        using var file = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None); file.Write(bytes); file.Flush(true); return path;
    }
    internal static string TrialRoot(Binding binding, Trial trial)
    {
        Validate(binding, binding.BetaSession);
        if (!binding.Trials.Contains(trial)) throw new InvalidDataException("Trial does not belong to the selected private reference.");
        return OwnedFiles.NoLinks(Path.Combine(binding.Work, "human-" + trial.Id));
    }
    internal void Command(string action)
    {
        if (!Busy || activeAction != "Run" || ActiveBinding is null || ActiveTrial is null || action is not ("stop" or "capture")) throw new InvalidOperationException("No owned active human session.");
        string root = TrialRoot(ActiveBinding, ActiveTrial);
        string statusPath = OwnedFiles.NoLinks(Path.Combine(root, "human-status.json"));
        JsonDocument? parsed = null;
        try { if (File.Exists(statusPath)) parsed = JsonDocument.Parse(OwnedFiles.Read(statusPath, 65536)); }
        catch (Exception error) when (action == "stop" && error is (IOException or System.Text.Json.JsonException or UnauthorizedAccessException)) { /* Owned request cancellation remains available. */ }
        using var status = parsed;
        bool matching = status is not null && status.RootElement.ValueKind == JsonValueKind.Object &&
            status.RootElement.TryGetProperty("session", out var sessionId) && sessionId.ValueKind == JsonValueKind.String && sessionId.GetString() == ActiveTrial.Id &&
            status.RootElement.TryGetProperty("betaSession", out var betaId) && betaId.ValueKind == JsonValueKind.String && betaId.GetString() == ActiveBinding.BetaSession.ToString("N") &&
            status.RootElement.TryGetProperty("state", out var state) && state.ValueKind == JsonValueKind.String && state.GetString() == "RUNNING_HUMAN";
        if (!matching)
        {
            if (action != "stop") throw new InvalidDataException("Matching controller is not yet running; no capture requested.");
            // A sibling of the immutable request cancels preparation/startup. Never
            // create a transaction root ahead of the save coordinator.
            string stopPath = OwnedFiles.NoLinks(Path.Combine(ActiveBinding.Work, "requests", "request-" + ActiveTrial.Id + ".json.stop.json"));
            using var stop = new FileStream(stopPath, FileMode.CreateNew, FileAccess.Write, FileShare.None);
            stop.Write(JsonSerializer.SerializeToUtf8Bytes(new { schema = 1, session = ActiveTrial.Id, action = "stop" })); stop.Flush(true); return;
        }
        var value = status!.RootElement;
        int sequence = value.GetProperty("nextSequence").GetInt32();
        if (sequence is < 1 or > 1000) throw new InvalidDataException("Unknown command sequence.");
        string destination = OwnedFiles.NoLinks(Path.Combine(root, $"human-command-{sequence:D6}.json"));
        string temporary = destination + "." + Guid.NewGuid().ToString("N") + ".tmp";
        using (var file = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None))
        { file.Write(JsonSerializer.SerializeToUtf8Bytes(new { schema = 1, session = ActiveTrial.Id, sequence, action })); file.Flush(true); }
        File.Move(temporary, destination); // Never replace a pending command.
    }
    private static async Task<string?> Drain(Stream input, string path)
    {
        // Logging failure must never stop consuming the child pipe during recovery.
        FileStream? file = null; string? failure = null;
        try { file = new FileStream(OwnedFiles.NoLinks(path), FileMode.CreateNew, FileAccess.Write, FileShare.Read); }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException) { failure = "PRIVATE_LOG_UNAVAILABLE"; }
        byte[] buffer = new byte[8192]; int retained = 0;
        while (true)
        {
            int read = await input.ReadAsync(buffer); if (read == 0) break;
            int keep = Math.Min(read, 2 * 1024 * 1024 - retained);
            if (keep > 0 && file is not null && failure is null)
            {
                try { await file.WriteAsync(buffer.AsMemory(0, keep)); retained += keep; }
                catch (Exception error) when (error is IOException or UnauthorizedAccessException) { failure = "PRIVATE_LOG_WRITE_FAILED"; }
            }
        }
        if (file is not null)
        {
            try { await file.DisposeAsync(); }
            catch (Exception error) when (error is IOException or UnauthorizedAccessException) { failure = "PRIVATE_LOG_FLUSH_FAILED"; }
        }
        return failure;
    }
    internal static void RecordRecovery(Binding binding, Trial trial, string operation, int exitCode)
    {
        TrialRoot(binding, trial); OwnedFiles.NoLinks(References); Directory.CreateDirectory(References);
        string path = OwnedFiles.NoLinks(Path.Combine(References, "recovery-" + trial.Id + "-" + Guid.NewGuid().ToString("N") + ".json"));
        using var file = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None);
        file.Write(JsonSerializer.SerializeToUtf8Bytes(new { schema = 1, betaSession = binding.BetaSession.ToString("N"), session = trial.Id,
            operation, exitCode, utc = DateTimeOffset.UtcNow, classification = "HISTORICAL_CONTROLLER_EXIT_ONLY_NOT_CURRENT_RECOVERY_READINESS", gameplay = "NOT_INDEPENDENTLY_VERIFIED" })); file.Flush(true);
    }
    internal static string RecoveryHistory(Binding binding, Trial trial)
    {
        string root = TrialRoot(binding, trial);
        string text = "PRIVATE LOCAL SNAPSHOT · NOT_REVERIFIED · NOT_CURRENT_RECOVERY_READINESS\n" + trial.Id + "\n";
        string journal = OwnedFiles.NoLinks(Path.Combine(root, "session.json"));
        if (File.Exists(journal))
        {
            using var json = JsonDocument.Parse(OwnedFiles.Read(journal, 1024 * 1024));
            text += "Journal claimed phase (not reverified): " + (json.RootElement.TryGetProperty("phase", out var phase) ? phase.ToString() : "UNKNOWN") + "\n";
        }
        else text += "Journal unavailable · UNKNOWN / preserve workspace\n";
        if (Directory.Exists(OwnedFiles.NoLinks(References)))
            foreach (string path in Directory.EnumerateFiles(References, "recovery-" + trial.Id + "-*.json").Order(StringComparer.Ordinal).Take(100))
            {
                using var json = JsonDocument.Parse(OwnedFiles.Read(path, 4096));
                if (json.RootElement.GetProperty("session").GetString() != trial.Id || json.RootElement.GetProperty("betaSession").GetString() != binding.BetaSession.ToString("N")) throw new InvalidDataException("Recovery observation identity differs; preserve all copies.");
                text += json.RootElement.GetRawText() + "\n";
            }
        return text;
    }
    internal static void SmokePackage()
    {
        PolicyDisclosure();
        foreach (string relative in new[] { "python/python.exe", "python/pythonw.exe", "compiler/UndertaleModCli.exe", "RouteKeeper.Tool.exe", "tools/runtime/human-session.ps1", "tools/runtime/human-loop.ps1", "tools/windows_e2e.py", "tools/human_beta.py", "beta-dependencies-complete.json" })
        {
            string path = OwnedFiles.NoLinks(Path.Combine(AppContext.BaseDirectory, relative.Replace('/', Path.DirectorySeparatorChar)));
            if (!File.Exists(path) || new FileInfo(path).Length == 0) throw new InvalidDataException("Packaged physical prerequisite missing: " + relative);
        }
        // Presence checks only: never execute Python, compiler, PowerShell, Steam or the game here.
    }
    internal static async Task SmokeDrainFailure()
    {
        using var bytes = new MemoryStream(new byte[3 * 1024 * 1024]);
        string unavailable = Path.Combine(Path.GetTempPath(), "rk-not-created-" + Guid.NewGuid().ToString("N"), "missing", "log");
        string? failure = await Drain(bytes, unavailable);
        if (failure is null || bytes.Position != bytes.Length) throw new InvalidOperationException("Failed private log must still drain the full child stream.");
    }
    internal async Task<int> Invoke(string action, Binding? binding = null, Trial? trial = null, string? request = null)
    {
        if (action is not ("Check" or "Prepare" or "Run" or "Recover" or "Cleanup")) throw new InvalidOperationException("Unknown native action.");
        if (Busy) throw new InvalidOperationException("Wait for the owned controller to finish. It is never killed to interrupt restoration.");
        if (!OperatingSystem.IsWindows()) throw new PlatformNotSupportedException("Native controller requires Windows.");
        string executable = OwnedFiles.NoLinks(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "System32", "WindowsPowerShell", "v1.0", "powershell.exe"));
        string script = OwnedFiles.NoLinks(Path.Combine(AppContext.BaseDirectory, "tools", "runtime", "human-session.ps1"));
        var start = new ProcessStartInfo(executable) { UseShellExecute = false, CreateNoWindow = true, WorkingDirectory = AppContext.BaseDirectory, RedirectStandardOutput = true, RedirectStandardError = true };
        start.Environment["PATH"] = OwnedFiles.NoLinks(Path.Combine(AppContext.BaseDirectory, "python")) + Path.PathSeparator + (start.Environment["PATH"] ?? "");
        foreach (string argument in new[] { "-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", script, "-Action", action }) start.ArgumentList.Add(argument);
        if (binding is not null)
        {
            Validate(binding, binding.BetaSession);
            foreach (string argument in new[] { "-Work", binding.Work, "-GameInstall", binding.GameInstall, "-SteamExe", binding.SteamExe }) start.ArgumentList.Add(argument);
        }
        if (trial is not null) { start.ArgumentList.Add("-SessionName"); start.ArgumentList.Add("human-" + trial.Id); }
        if (request is not null) { start.ArgumentList.Add("-RequestFile"); start.ArgumentList.Add(request); }
        Busy = true; ActiveBinding = binding; ActiveTrial = trial; activeAction = action;
        try
        {
            OwnedFiles.NoLinks(References); Directory.CreateDirectory(References);
            LastLogDirectory = OwnedFiles.NoLinks(Path.Combine(References, "controller-" + Guid.NewGuid().ToString("N"))); Directory.CreateDirectory(LastLogDirectory);
            using var child = Process.Start(start) ?? throw new InvalidOperationException("Controller did not start.");
            Task<string?> stdout = Drain(child.StandardOutput.BaseStream, Path.Combine(LastLogDirectory, "stdout-private.log"));
            Task<string?> stderr = Drain(child.StandardError.BaseStream, Path.Combine(LastLogDirectory, "stderr-private.log"));
            await child.WaitForExitAsync(); var failures = await Task.WhenAll(stdout, stderr);
            if (failures.Any(f => f is not null)) throw new IOException("Controller finished but private diagnostic log retention failed; inspect/import recovery evidence explicitly.");
            return child.ExitCode;
        }
        finally { Busy = false; ActiveBinding = null; ActiveTrial = null; activeAction = null; }
    }
}
