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
        if (!version.Trim().StartsWith("0.9.2.0", StringComparison.Ordinal)) throw new InvalidOperationException("Compiler must be UndertaleModCli 0.9.2.0.");
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
            File.Move(candidate, output); // Never overwrite a concurrent or existing output.
            return new(matching[0].Id, original.Sha256, result.Sha256, result.Size, matching[0].Status);
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
        var stdout = process.StandardOutput.ReadToEndAsync();
        var stderr = process.StandardError.ReadToEndAsync();
        using var timeout = new CancellationTokenSource(TimeSpan.FromMinutes(5));
        try { await process.WaitForExitAsync(timeout.Token); }
        catch (OperationCanceledException)
        {
            if (!process.HasExited) process.Kill(entireProcessTree: true);
            throw new IOException("UndertaleModCli exceeded the five-minute build limit.");
        }
        await Task.WhenAll(stdout, stderr);
        // Compiler diagnostics can contain proprietary source. Do not echo them to
        // ordinary logs; the private structural harness supports detailed debugging.
        if (process.ExitCode != 0) throw new InvalidOperationException($"UndertaleModCli failed with exit {process.ExitCode}; use the private validation harness for diagnostics.");
        return stdout.Result;
    }
}
