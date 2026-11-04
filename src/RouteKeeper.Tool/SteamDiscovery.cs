using System.Text.RegularExpressions;

namespace RouteKeeper.Tool;

public sealed record SteamCandidate(string Directory, string DataPath, string? BuildId, string Status = "UnverifiedCandidate");

/// <summary>Read-only hints from conventional locations. Metadata is not compatibility evidence.</summary>
public static partial class SteamDiscovery
{
    [GeneratedRegex("\\\"path\\\"\\s+\\\"([^\\\"]+)\\\"", RegexOptions.IgnoreCase)]
    private static partial Regex LibraryPath();
    [GeneratedRegex("\\\"buildid\\\"\\s+\\\"([0-9]+)\\\"", RegexOptions.IgnoreCase)]
    private static partial Regex BuildId();

    public static IReadOnlyList<SteamCandidate> Discover(IEnumerable<string>? steamRoots = null)
    {
        string userHome = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        steamRoots ??= new[]
        {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Steam"),
            Path.Combine(userHome, "Library", "Application Support", "Steam"),
            Path.Combine(userHome, ".local", "share", "Steam"),
            Path.Combine(userHome, ".steam", "steam"),
            Path.Combine(userHome, ".var", "app", "com.valvesoftware.Steam", ".local", "share", "Steam")
        };
        var libraries = new HashSet<string>(OperatingSystem.IsWindows() ? StringComparer.OrdinalIgnoreCase : StringComparer.Ordinal);
        foreach (string root in steamRoots)
        {
            libraries.Add(Path.GetFullPath(root));
            string config = Path.Combine(root, "steamapps", "libraryfolders.vdf");
            if (!File.Exists(config)) continue;
            foreach (Match match in LibraryPath().Matches(File.ReadAllText(config)))
                libraries.Add(Path.GetFullPath(match.Groups[1].Value.Replace("\\\\", "\\", StringComparison.Ordinal)));
        }
        List<SteamCandidate> candidates = [];
        foreach (string library in libraries)
        {
            string app = Path.Combine(library, "steamapps");
            string manifest = Path.Combine(app, "appmanifest_391540.acf");
            string? build = File.Exists(manifest) ? BuildId().Match(File.ReadAllText(manifest)).Groups[1].Value : null;
            string game = Path.Combine(app, "common", "Undertale");
            foreach (string relative in new[] { "data.win", "game.unx", "game.ios", Path.Combine("UNDERTALE.app", "Contents", "Resources", "game.ios") })
            {
                string data = Path.Combine(game, relative);
                if (File.Exists(data)) candidates.Add(new(game, data, string.IsNullOrEmpty(build) ? null : build));
            }
        }
        return candidates;
    }
}
