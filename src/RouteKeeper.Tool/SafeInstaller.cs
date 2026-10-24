using System.Security.Cryptography;
using System.Text.Json;

namespace RouteKeeper.Tool;

public sealed record InstallJournal(int SchemaVersion, string OriginalSha256, string InstalledSha256, string ProfileId, string Phase, string? PreviousSha256 = null);

/// <summary>Replaces only game data. Never locates, parses, or writes saves or permanent history.</summary>
public static class SafeInstaller
{
    public static string Hash(string path)
    {
        using var stream = File.OpenRead(path);
        return Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant();
    }

    public static void Install(string target, string candidate, IEnumerable<CompatibilityProfile> profiles, string platform, string architecture)
    {
        target = Path.GetFullPath(target);
        candidate = Path.GetFullPath(candidate);
        if (target == candidate) throw new InvalidOperationException("Candidate must be a separate file.");
        string backup = target + ".routekeeper-original";
        string journalPath = target + ".routekeeper.json";
        RejectLinks(target, candidate, backup, journalPath, target + ".routekeeper-lock");
        using var fileLock = new FileStream(target + ".routekeeper-lock", FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None);
        InstallJournal? previous = ReadJournal(journalPath);
        string initialHash = Hash(target);
        if (previous is not null)
        {
            RequireHash(backup, previous.OriginalSha256);
            string current = Hash(target);
            if (!CompatibilityRegistry.Equal(current, previous.InstalledSha256) && !CompatibilityRegistry.Equal(current, previous.OriginalSha256) && !CompatibilityRegistry.Equal(current, previous.PreviousSha256))
                throw new InvalidOperationException("Installed data changed externally; refusing replacement.");
        }
        string original = previous is null ? target : backup;
        var profile = CompatibilityRegistry.RequireVerified(BuildInspector.Inspect(original), profiles, platform, architecture);
        // Reopen and hash a private staging copy: candidate may be changed by another process.
        string staged = target + ".routekeeper-stage-" + Guid.NewGuid().ToString("N");
        try
        {
            DurableCopy(candidate, staged);
            RequireHash(staged, profile.PatchedSha256!);
            var patched = BuildInspector.Inspect(staged);
            if (patched.BytecodeVersion != profile.BytecodeVersion) throw new InvalidDataException("Candidate bytecode version changed.");
            if (previous is not null && CompatibilityRegistry.Equal(Hash(target), profile.PatchedSha256)) return;
            if (!File.Exists(backup)) DurableCopy(target, backup);
            RequireHash(backup, profile.OriginalSha256);
            RequireHash(target, initialHash);
            string oldHash = initialHash;
            var pending = new InstallJournal(1, profile.OriginalSha256, profile.PatchedSha256!, profile.Id, "Pending", oldHash);
            WriteJournal(journalPath, pending);
            // Detect target changes since inspection and before atomic rename.
            RequireHash(target, oldHash);
            try
            {
                File.Move(staged, target, overwrite: true);
                RequireHash(target, profile.PatchedSha256!);
                WriteJournal(journalPath, pending with { Phase = "Installed" });
            }
            catch
            {
                // Original backup is always retained. Never overwrite unexpected external changes.
                string current = Hash(target);
                if (CompatibilityRegistry.Equal(current, profile.PatchedSha256) || CompatibilityRegistry.Equal(current, oldHash))
                {
                    AtomicCopy(backup, target);
                    WriteJournal(journalPath, pending with { Phase = "Restored" });
                }
                throw;
            }
        }
        finally { if (File.Exists(staged)) File.Delete(staged); }
    }

    public static void Restore(string target)
    {
        target = Path.GetFullPath(target);
        string backup = target + ".routekeeper-original", journalPath = target + ".routekeeper.json";
        RejectLinks(target, backup, journalPath, target + ".routekeeper-lock");
        using var fileLock = new FileStream(target + ".routekeeper-lock", FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None);
        var journal = ReadJournal(journalPath) ?? throw new InvalidOperationException("No installation journal.");
        RequireHash(backup, journal.OriginalSha256);
        string current = Hash(target);
        if (!CompatibilityRegistry.Equal(current, journal.InstalledSha256) && !CompatibilityRegistry.Equal(current, journal.OriginalSha256) && !CompatibilityRegistry.Equal(current, journal.PreviousSha256))
            throw new InvalidOperationException("Externally modified game; restoration refused.");
        RequireHash(target, current);
        if (!CompatibilityRegistry.Equal(current, journal.OriginalSha256)) AtomicCopy(backup, target);
        RequireHash(target, journal.OriginalSha256);
        WriteJournal(journalPath, journal with { Phase = "Restored" });
    }

    private static InstallJournal? ReadJournal(string path)
    {
        if (!File.Exists(path)) return null;
        var journal = JsonSerializer.Deserialize<InstallJournal>(File.ReadAllText(path), CompatibilityRegistry.JsonOptions);
        if (journal is null || journal.SchemaVersion != 1 || journal.OriginalSha256?.Length != 64 || journal.InstalledSha256?.Length != 64 || (journal.PreviousSha256 is not null && journal.PreviousSha256.Length != 64) ||
            journal.Phase is not ("Pending" or "Installed" or "Restored")) throw new InvalidDataException("Invalid installation journal.");
        return journal;
    }
    private static void RequireHash(string path, string hash)
    {
        if (!File.Exists(path) || !CompatibilityRegistry.Equal(Hash(path), hash)) throw new InvalidDataException("Integrity verification failed: " + Path.GetFileName(path));
    }
    private static void WriteJournal(string path, InstallJournal journal)
    {
        string temporary = path + "." + Guid.NewGuid().ToString("N");
        try
        {
            using (var stream = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None))
            {
                JsonSerializer.Serialize(stream, journal, CompatibilityRegistry.JsonOptions);
                stream.Flush(flushToDisk: true);
            }
            File.Move(temporary, path, overwrite: true);
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }
    private static void AtomicCopy(string source, string target)
    {
        string temporary = target + "." + Guid.NewGuid().ToString("N");
        try { DurableCopy(source, temporary); File.Move(temporary, target, overwrite: true); }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }
    private static void DurableCopy(string source, string target)
    {
        using var input = File.OpenRead(source);
        using var output = new FileStream(target, FileMode.CreateNew, FileAccess.Write, FileShare.None);
        input.CopyTo(output);
        output.Flush(flushToDisk: true);
    }
    private static void RejectLinks(params string[] paths)
    {
        foreach (string path in paths)
        {
            var info = new FileInfo(path);
            if (info.LinkTarget is not null || (info.Exists && info.Attributes.HasFlag(FileAttributes.ReparsePoint)))
                throw new InvalidOperationException("Symbolic-link game data or installer sidecar refused.");
        }
    }
}
