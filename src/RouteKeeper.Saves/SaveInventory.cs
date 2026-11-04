using System.Security.Cryptography;
using System.Text;

namespace RouteKeeper.Saves;

public enum SaveKind { Playthrough, Recovery, PersistentEncounter, PermanentHistory, Configuration }
public sealed record SaveEntry(string Name, SaveKind Kind, long Bytes, string Sha256);
public sealed record LineSave(IReadOnlyList<string> Lines, string Newline, bool TrailingNewline);

/// <summary>Read-only inventory. Deliberately exposes no API for writing game saves.</summary>
public static class SaveInventory
{
    private static readonly Dictionary<string, SaveKind> Known = new(StringComparer.OrdinalIgnoreCase)
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
                if (!name.StartsWith("system_information_", StringComparison.OrdinalIgnoreCase)) continue;
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
        using var input=File.OpenRead(path);
        return ReadLines(input);
    }

    // Bound bytes actually consumed, rather than trusting a pre-read file length
    // that a concurrent writer can invalidate. The caller retains stream ownership.
    internal static LineSave ReadLines(Stream input)
    {
        const int maximum=1024*1024;
        var bytes=new byte[maximum+1];int count=0,read;
        while(count<bytes.Length && (read=input.Read(bytes,count,bytes.Length-count))!=0)count+=read;
        if(count>maximum)throw new InvalidDataException("Save exceeds read-only parser limit.");
        using var data=new MemoryStream(bytes,0,count,writable:false);
        using var reader=new StreamReader(data,new UTF8Encoding(false,true),detectEncodingFromByteOrderMarks:true);
        var text=reader.ReadToEnd();
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
