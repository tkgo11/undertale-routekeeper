using System.Security.Cryptography;

namespace RouteKeeper.Beta;

/// <summary>Cooperative single-writer local storage. Revalidation is not hostile-writer isolation.</summary>
public static class OwnedFiles
{
    public const int MaximumJsonBytes = 8 * 1024 * 1024;
    public static string Hash(byte[] bytes) => Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
    public static string HashFile(string path)
    {
        NoLinks(path);
        using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        return Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant();
    }
    public static string NoLinks(string path)
    {
        path = Path.GetFullPath(path);
        for (string? current = path; current is not null; current = Path.GetDirectoryName(current))
        {
            FileSystemInfo info = Directory.Exists(current) ? new DirectoryInfo(current) : new FileInfo(current);
            if (info.LinkTarget is not null || (info.Exists && info.Attributes.HasFlag(FileAttributes.ReparsePoint)))
                throw new IOException("Linked storage refused; select an ordinary local directory.");
        }
        return path;
    }
    public static byte[] Read(string path, int maximum = MaximumJsonBytes)
    {
        NoLinks(path);
        using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        if (stream.Length > maximum) throw new InvalidDataException("Local record exceeds size limit.");
        using var output = new MemoryStream();
        byte[] buffer = new byte[65536];
        int count;
        while ((count = stream.Read(buffer)) != 0)
        {
            if (output.Length + count > maximum) throw new InvalidDataException("Local record grew beyond size limit.");
            output.Write(buffer, 0, count);
        }
        return output.ToArray();
    }
    public static void Create(string path, byte[] bytes)
    {
        NoLinks(path);
        using var stream = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None);
        stream.Write(bytes); stream.Flush(true);
    }
    public static void CommitNew(string path, byte[] bytes)
    {
        if (bytes.Length > MaximumJsonBytes) throw new InvalidDataException("Session exceeds storage budget; export and create another session.");
        NoLinks(path);
        string temp = path + ".pending-" + Guid.NewGuid().ToString("N");
        // A crash leaves an uncommitted pending file, never a partially published revision.
        Create(temp, bytes);
        NoLinks(path); NoLinks(temp);
        File.Move(temp, path, false);
    }
    public static void Replace(string path, byte[] bytes)
    {
        NoLinks(path);
        string temp = path + ".pending-" + Guid.NewGuid().ToString("N");
        Create(temp, bytes);
        NoLinks(path); NoLinks(temp); File.Move(temp, path, true);
    }
}
