using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace RouteKeeper.Tool;

public sealed record ChunkSignature(string Name, long Offset, uint Length, string Sha256);
public sealed record BuildIdentity(string FileName, long Size, string Sha256, string Md5, byte BytecodeVersion, IReadOnlyList<ChunkSignature> Chunks);
public sealed record CompatibilityProfile(string Id, string Status, string Platform, string Architecture,
    long OriginalSize, string OriginalSha256, string OriginalMd5, byte BytecodeVersion,
    string StructuralSha256, string? PatchedSha256, string? SteamBuildId = null, string? SteamDepotId = null);

/// <summary>Read-only FORM inspection; recognition alone never authorizes patching.</summary>
public static class BuildInspector
{
    public static BuildIdentity Inspect(string path)
    {
        using var stream = File.OpenRead(path);
        if (stream.Length < 8) throw new InvalidDataException("Truncated FORM header.");
        using var reader = new BinaryReader(stream, Encoding.ASCII, leaveOpen: true);
        if (Encoding.ASCII.GetString(reader.ReadBytes(4)) != "FORM") throw new InvalidDataException("Not GameMaker FORM data.");
        if (reader.ReadUInt32() != stream.Length - 8) throw new InvalidDataException("FORM length mismatch.");
        List<ChunkSignature> chunks = [];
        byte? bytecode = null;
        while (stream.Position < stream.Length)
        {
            if (stream.Length - stream.Position < 8) throw new InvalidDataException("Truncated chunk header.");
            string name = Encoding.ASCII.GetString(reader.ReadBytes(4));
            if (name.Any(c => !(c >= 'A' && c <= 'Z') && !(c >= '0' && c <= '9'))) throw new InvalidDataException("Invalid chunk identifier.");
            uint length = reader.ReadUInt32();
            long offset = stream.Position;
            if (length > stream.Length - offset) throw new InvalidDataException("Chunk exceeds FORM bounds.");
            if (name == "GEN8")
            {
                if (bytecode.HasValue || length < 2) throw new InvalidDataException("Invalid GEN8 chunk.");
                reader.ReadByte(); // UndertaleGeneralInfo.IsDebuggerDisabled
                bytecode = reader.ReadByte();
                stream.Position = offset;
            }
            using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
            byte[] buffer = new byte[65536];
            long remaining = length;
            while (remaining > 0)
            {
                int read = stream.Read(buffer, 0, (int)Math.Min(buffer.Length, remaining));
                if (read == 0) throw new EndOfStreamException();
                hash.AppendData(buffer, 0, read);
                remaining -= read;
            }
            chunks.Add(new(name, offset, length, Convert.ToHexString(hash.GetHashAndReset()).ToLowerInvariant()));
        }
        if (!bytecode.HasValue) throw new InvalidDataException("Missing GEN8 chunk.");
        stream.Position = 0;
        string sha = Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant();
        stream.Position = 0;
        string md5 = Convert.ToHexString(MD5.HashData(stream)).ToLowerInvariant();
        return new(Path.GetFileName(path), stream.Length, sha, md5, bytecode.Value, chunks);
    }

    public static string StructuralHash(BuildIdentity identity) => Convert.ToHexString(SHA256.HashData(
        Encoding.UTF8.GetBytes(string.Join("\n", identity.Chunks.Select(c => $"{c.Name}:{c.Offset}:{c.Length}:{c.Sha256}"))))).ToLowerInvariant();

    public static IReadOnlyList<string> Diff(BuildIdentity before, BuildIdentity after)
    {
        List<string> changes = [];
        int count = Math.Max(before.Chunks.Count, after.Chunks.Count);
        for (int i = 0; i < count; i++)
        {
            var a = i < before.Chunks.Count ? before.Chunks[i] : null;
            var b = i < after.Chunks.Count ? after.Chunks[i] : null;
            if (a != b) changes.Add($"chunk[{i}]: {a?.Name ?? "absent"} -> {b?.Name ?? "absent"}; content/layout differs");
        }
        return changes;
    }
}

public static class CompatibilityRegistry
{
    public static CompatibilityProfile[] Load(string path) => JsonSerializer.Deserialize<CompatibilityProfile[]>(File.ReadAllText(path), JsonOptions) ?? throw new InvalidDataException("Missing profiles.");
    public static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = true, PropertyNameCaseInsensitive = true };
    public static CompatibilityProfile RequireVerified(BuildIdentity identity, IEnumerable<CompatibilityProfile> profiles, string platform, string architecture)
    {
        var matches = profiles.Where(p => p.Status == "VerifiedPatch" && p.Platform == platform && p.Architecture == architecture &&
            p.OriginalSize == identity.Size && Equal(p.OriginalSha256, identity.Sha256) && Equal(p.OriginalMd5, identity.Md5) &&
            p.BytecodeVersion == identity.BytecodeVersion && Equal(p.StructuralSha256, BuildInspector.StructuralHash(identity)) &&
            p.PatchedSha256?.Length == 64).ToArray();
        return matches.Length == 1 ? matches[0] : throw new InvalidOperationException("Unknown, ambiguous, or unverified build; patching refused.");
    }
    public static bool Equal(string? a, string? b) => string.Equals(a, b, StringComparison.OrdinalIgnoreCase);
}
