using System.Diagnostics;
using System.IO.Compression;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace RouteKeeper.Tool;

/// <summary>G3M mod_config 2.0.0 package; exact target and patch hashes are mandatory.</summary>
public static class G3MPackage
{
    public static string Config(string originalHash, string patchHash, string relativeDataPath)
    {
        if (!Regex.IsMatch(originalHash, @"\A[0-9a-f]{64}\z") || !Regex.IsMatch(patchHash, @"\A[0-9a-f]{64}\z"))
            throw new ArgumentException("G3M hashes must be lowercase SHA-256.");
        if (!Regex.IsMatch(relativeDataPath, @"\A(?:[A-Za-z0-9_. -]+/)*(?:data\.win|game\.unx|game\.ios)\z") ||
            relativeDataPath.Split('/').Any(p => p is "." or ".." || p.EndsWith('.') || p.EndsWith(' ') ||
                Regex.IsMatch(p, @"\A(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|\z)", RegexOptions.IgnoreCase)))
            throw new ArgumentException("G3M requires a verified portable relative game-data path.");
        return JsonSerializer.Serialize(new
        {
            config_version = "2.0.0", id = "routekeeper", name = "ROUTEKEEPER", version = "0.2.0",
            authors = new[] { "ROUTEKEEPER contributors" }, game = "undertale",
            description = "Native route guidance. Requires the exact approved game data; backups remain managed by G3M.",
            files = new[] { new { source = "${mod_path}/payload/routekeeper.xdelta", target = "${game_path}/" + relativeDataPath, type = "patch",
                source_hash = "sha256:" + patchHash, target_hash = "sha256:" + originalHash } }
        }, CompatibilityRegistry.JsonOptions);
    }

    public static async Task CreateAsync(string original, string candidate, string xdelta, string output,
        IEnumerable<CompatibilityProfile> profiles, string platform, string architecture)
    {
        original = Path.GetFullPath(original); candidate = Path.GetFullPath(candidate); output = Path.GetFullPath(output);
        SafeInstaller.RejectLinks(original,candidate,output);
        if (Path.Exists(output)) throw new IOException("Package output must be new.");
        var identity = BuildInspector.Inspect(original);
        var profile = CompatibilityRegistry.RequireVerified(identity, profiles, platform, architecture);
        string dataPath = profile.GameDataRelativePath ?? throw new InvalidOperationException("G3M game-data location has not been verified.");
        _ = Config(identity.Sha256, new string('a',64), dataPath);
        string expected = SafeInstaller.Hash(candidate);
        if (!CompatibilityRegistry.Equal(expected, profile.PatchedSha256)) throw new InvalidDataException("Candidate is not the approved output.");
        if (File.Exists(xdelta)) xdelta = Path.GetFullPath(xdelta);
        string parent = Path.GetDirectoryName(output)!;
        Directory.CreateDirectory(parent);
        string work = Path.Combine(parent, ".routekeeper-g3m-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(work);
        try
        {
            // External tools receive disposable copies only, never a pristine source.
            string sourceCopy = Path.Combine(work, "original.win"), candidateCopy = Path.Combine(work, "candidate.win");
            File.Copy(original, sourceCopy); File.Copy(candidate, candidateCopy);
            string patch = Path.Combine(work, "routekeeper.xdelta"), decoded = Path.Combine(work, "decoded.win");
            await Run(xdelta, ["-e", "-s", sourceCopy, candidateCopy, patch]);
            byte[] magic = new byte[3]; using (var f = File.OpenRead(patch)) f.ReadExactly(magic);
            if (!magic.SequenceEqual(new byte[] { 0xd6, 0xc3, 0xc4 })) throw new InvalidDataException("Expected a VCDIFF patch.");
            await Run(xdelta, ["-d", "-s", sourceCopy, patch, decoded]);
            if (!CompatibilityRegistry.Equal(SafeInstaller.Hash(decoded), expected) ||
                !CompatibilityRegistry.Equal(SafeInstaller.Hash(sourceCopy), identity.Sha256) ||
                !CompatibilityRegistry.Equal(SafeInstaller.Hash(candidateCopy), expected) ||
                !CompatibilityRegistry.Equal(SafeInstaller.Hash(original), identity.Sha256) ||
                !CompatibilityRegistry.Equal(SafeInstaller.Hash(candidate), expected)) throw new InvalidDataException("Delta verification or original preservation failed.");
            string archive = Path.Combine(work, "package.zip");
            using (var zip = ZipFile.Open(archive, ZipArchiveMode.Create))
            {
                var config = zip.CreateEntry("mod_config.json"); config.LastWriteTime = Epoch;
                using (var writer = new StreamWriter(config.Open())) writer.Write(Config(identity.Sha256, SafeInstaller.Hash(patch), dataPath));
                var entry = zip.CreateEntry("payload/routekeeper.xdelta", CompressionLevel.Optimal); entry.LastWriteTime = Epoch;
                using var input = File.OpenRead(patch); using var destination = entry.Open(); input.CopyTo(destination);
            }
            SafeInstaller.RejectLinks(original,candidate,output,work,archive);
            File.Move(archive, output); // No overwrite, even when another process races.
        }
        finally { if (Directory.Exists(work)) Directory.Delete(work, true); }
    }
    private static readonly DateTimeOffset Epoch = new(1980, 1, 1, 0, 0, 0, TimeSpan.Zero);
    private static async Task Run(string executable, string[] args)
    {
        var start = new ProcessStartInfo(executable) { UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true };
        foreach (string arg in args) start.ArgumentList.Add(arg);
        // Do not inherit environment options that can inject xdelta arguments.
        start.Environment.Remove("XDELTA");
        using var process = new Process { StartInfo = start };
        try { process.Start(); }
        catch (System.ComponentModel.Win32Exception) { throw new IOException("Cannot start xdelta3."); }
        using var timeout = new CancellationTokenSource(TimeSpan.FromMinutes(5));
        var stdout = ProcessOutput.DrainAsync(process.StandardOutput, cancellation: timeout.Token);
        var stderr = ProcessOutput.DrainAsync(process.StandardError, cancellation: timeout.Token);
        try { await Task.WhenAll(process.WaitForExitAsync(timeout.Token), stdout, stderr); }
        catch (OperationCanceledException) { if (!process.HasExited) process.Kill(true); throw new IOException("Delta generation timed out."); }
        if (process.ExitCode != 0) throw new InvalidOperationException("xdelta3 failed; no package was installed.");
    }
}
