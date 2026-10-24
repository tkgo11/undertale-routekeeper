using System.Security.Cryptography;
using System.Text;

namespace RouteKeeper.Saves;

public enum SaveKind { Playthrough, Recovery, PersistentEncounter, PermanentHistory, Configuration }
public sealed record SaveEntry(string Name, SaveKind Kind, long Bytes, string Sha256);
public sealed record LineSave(IReadOnlyList<string> Lines, string Newline, bool TrailingNewline);

/// <summary>Read-only inventory. Deliberately exposes no API for writing game saves.</summary>
public static class SaveInventory
{
    private static readonly Dictionary<string, SaveKind> Known = new(StringComparer.Ordinal)
    {
        ["file0"] = SaveKind.Playthrough, ["file8"] = SaveKind.PersistentEncounter,
        ["file9"] = SaveKind.Recovery, ["undertale.ini"] = SaveKind.Configuration,
        ["system_information_962"] = SaveKind.PermanentHistory,
        ["system_information_963"] = SaveKind.PermanentHistory
    };

    public static IReadOnlyList<SaveEntry> Inspect(string directory)
    {
        var results = new List<SaveEntry>();
        foreach (var file in Directory.EnumerateFiles(directory).Order(StringComparer.Ordinal))
        {
            var name = Path.GetFileName(file);
            var kind = Known.GetValueOrDefault(name);
            if (!Known.ContainsKey(name))
            {
                if (!name.StartsWith("system_information_", StringComparison.Ordinal)) continue;
                kind = SaveKind.PermanentHistory; // Unknown history files are protected too.
            }
            if ((File.GetAttributes(file) & FileAttributes.ReparsePoint) != 0)
                throw new IOException("Refusing symbolic save file.");
            using var stream = File.OpenRead(file);
            results.Add(new(name, kind, stream.Length, Convert.ToHexStringLower(SHA256.HashData(stream))));
        }
        return results;
    }

    public static LineSave ReadLines(string path)
    {
        var info = new FileInfo(path);
        if (info.Length > 1024 * 1024) throw new InvalidDataException("Save exceeds read-only parser limit.");
        var text = File.ReadAllText(path, new UTF8Encoding(false, true));
        if (text.Contains('\0')) throw new InvalidDataException("Unexpected binary save.");
        var newline = text.Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n";
        var normalized = text.Replace("\r\n", "\n", StringComparison.Ordinal);
        if (normalized.Contains('\r')) throw new InvalidDataException("Unsupported newline.");
        var trailing = normalized.EndsWith('\n');
        var lines = normalized.Split('\n').ToList();
        if (trailing) lines.RemoveAt(lines.Count - 1);
        return new(lines, newline, trailing);
    }

    public static bool PermanentHistoryUnchanged(IEnumerable<SaveEntry> before, IEnumerable<SaveEntry> after)
    {
        static string[] History(IEnumerable<SaveEntry> entries) => entries
            .Where(x => x.Kind == SaveKind.PermanentHistory)
            .Select(x => $"{x.Name}:{x.Bytes}:{x.Sha256}").Order(StringComparer.Ordinal).ToArray();
        return History(before).SequenceEqual(History(after));
    }
}
