using System.ComponentModel;
using System.Diagnostics;

namespace RouteKeeper.Tool;

public sealed record BuildReceipt(string Profile, string InputSha256, string OutputSha256, long OutputSize,
    string CompatibilityStatus, string Gameplay = "NOT_RUN");

/// <summary>Builds a new candidate from a disposable copy; never installs or approves it.</summary>
public static class ModBuilder
{
    public static async Task<BuildReceipt> BuildAsync(string source, string output, string compiler, string assetRoot, string? profileId = null)
    {
        source = Path.GetFullPath(source); output = Path.GetFullPath(output); assetRoot = Path.GetFullPath(assetRoot);
        SafeInstaller.RejectLinks(source,output,assetRoot);
        if (File.Exists(compiler)) compiler = Path.GetFullPath(compiler);
        if (string.Equals(source, output, OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal))
            throw new InvalidOperationException("Build output must be distinct from the original.");
        if (Path.Exists(output)) throw new InvalidOperationException("Build output must be new.");
        var original = BuildInspector.Inspect(source);
        var profiles = CompatibilityRegistry.Load(Path.Combine(assetRoot, "profiles", "registry.json"));
        var matching = profiles.Where(p => (profileId is null || p.Id == profileId) && (p.Status is "InspectedOnly" or "VerifiedPatch") && p.OriginalSize == original.Size &&
            CompatibilityRegistry.Equal(p.OriginalSha256, original.Sha256) && CompatibilityRegistry.Equal(p.OriginalMd5, original.Md5) &&
            p.BytecodeVersion == original.BytecodeVersion && CompatibilityRegistry.Equal(p.StructuralSha256, BuildInspector.StructuralHash(original))).ToArray();
        if (matching.Length != 1) throw new InvalidOperationException("Unknown or ambiguous build; candidate generation refused.");
        string patch = Path.Combine(assetRoot, "integration", "patch.csx");
        string verification = Path.Combine(assetRoot, "integration", "verify.csx");
        if (!File.Exists(patch) || !File.Exists(verification)) throw new IOException("Packaged patch scripts are missing.");
        var version = await RunAsync(compiler, ["--version"], assetRoot);
        if (!System.Text.RegularExpressions.Regex.IsMatch(version.Trim(), @"\A0\.9\.2\.0(?:\+[0-9A-Za-z.-]+)?\z"))
            throw new InvalidOperationException("Compiler must be UndertaleModCli 0.9.2.0.");
        string parent = Path.GetDirectoryName(output)!;
        Directory.CreateDirectory(parent);
        string workspace = Path.Combine(parent, ".routekeeper-build-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(workspace);
        try
        {
            string disposableOriginal = Path.Combine(workspace, "original.win");
            string candidate = Path.Combine(workspace, "candidate.win");
            File.Copy(source, disposableOriginal, overwrite: false);
            File.SetAttributes(disposableOriginal, FileAttributes.Normal);
            RequireOriginal(disposableOriginal, original.Sha256);
            // The compiler never receives the user's only original file as input.
            await RunAsync(compiler, ["load", disposableOriginal, "-s", patch, "-o", candidate], assetRoot);
            RequireOriginal(disposableOriginal, original.Sha256);
            await RunAsync(compiler, ["load", candidate, "-s", verification], assetRoot, disposableOriginal);
            RequireOriginal(disposableOriginal, original.Sha256);
            var result = BuildInspector.Inspect(candidate);
            if (result.BytecodeVersion != original.BytecodeVersion) throw new InvalidDataException("Candidate bytecode differs.");
            RequireOriginal(source, original.Sha256);
            SafeInstaller.RejectLinks(source,output,candidate,workspace);
            File.Move(candidate, output); // Never overwrite a concurrent or existing output.
            // Approval belongs to the exact output too, never just its input.
            string status = matching[0].Status == "VerifiedPatch" && CompatibilityRegistry.Equal(matching[0].PatchedSha256, result.Sha256)
                ? "VerifiedPatch" : "InspectedOnly";
            return new(matching[0].Id, original.Sha256, result.Sha256, result.Size, status);
        }
        finally
        {
            // This workspace contains disposable inputs, never the user's source.
            if (Directory.Exists(workspace)) Directory.Delete(workspace, recursive: true);
        }
    }
    private static void RequireOriginal(string path, string hash)
    {
        if (!CompatibilityRegistry.Equal(SafeInstaller.Hash(path), hash)) throw new InvalidDataException("Original changed during build.");
    }
    private static async Task<string> RunAsync(string executable, string[] arguments, string directory, string? original = null)
    {
        var start = new ProcessStartInfo(executable)
        {
            WorkingDirectory = directory, UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true
        };
        foreach (string argument in arguments) start.ArgumentList.Add(argument);
        if (original is not null) start.Environment["ROUTEKEEPER_ORIGINAL"] = original;
        using var process = new Process { StartInfo = start };
        try { process.Start(); }
        catch (Win32Exception) { throw new IOException("Cannot start the specified UndertaleModCli executable."); }
        // Only the version probe needs text. Drain compile diagnostics without
        // storing them, including a child that fills stderr before stdout.
        using var timeout = new CancellationTokenSource(TimeSpan.FromMinutes(5));
        var stdout = ProcessOutput.DrainAsync(process.StandardOutput, arguments is ["--version"] ? 8192 : 0, timeout.Token);
        var stderr = ProcessOutput.DrainAsync(process.StandardError, cancellation: timeout.Token);
        try { await Task.WhenAll(process.WaitForExitAsync(timeout.Token), stdout, stderr); }
        catch (OperationCanceledException)
        {
            if (!process.HasExited) process.Kill(entireProcessTree: true);
            throw new IOException("UndertaleModCli exceeded the five-minute build limit.");
        }
        // Compiler diagnostics can contain proprietary source. Do not echo them to
        // ordinary logs; the private structural harness supports detailed debugging.
        if (process.ExitCode != 0) throw new InvalidOperationException($"UndertaleModCli failed with exit {process.ExitCode}; use the private validation harness for diagnostics.");
        if (arguments is ["--version"] && stdout.Result.Truncated)
            throw new InvalidOperationException("Compiler version response exceeded its limit.");
        return stdout.Result.Prefix;
    }
}
