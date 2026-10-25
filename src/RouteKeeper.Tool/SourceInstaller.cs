namespace RouteKeeper.Tool;

/// <summary>Verified-profile-only build and install; unverified builds fail before invoking a compiler.</summary>
public static class SourceInstaller
{
    public static async Task InstallAsync(string target, string compiler, string platform, string architecture, string assetRoot)
    {
        target = Path.GetFullPath(target); assetRoot = Path.GetFullPath(assetRoot);
        var registry = CompatibilityRegistry.Load(Path.Combine(assetRoot, "profiles", "registry.json"));
        string backup = target + ".routekeeper-original";
        string original = File.Exists(backup) ? backup : target;
        var profile = CompatibilityRegistry.RequireVerified(BuildInspector.Inspect(original), registry, platform, architecture);
        SafeInstaller.ValidateRunner(target,profile);
        string candidate = target + ".routekeeper-candidate-" + Guid.NewGuid().ToString("N");
        try
        {
            await ModBuilder.BuildAsync(original, candidate, compiler, assetRoot, profile.Id);
            SafeInstaller.Install(target, candidate, registry, platform, architecture);
        }
        finally { if (File.Exists(candidate)) File.Delete(candidate); }
    }
}
