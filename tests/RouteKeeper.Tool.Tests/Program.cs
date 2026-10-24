using System.Text;
using System.Text.Json;
using RouteKeeper.Tool;

string root = Path.Combine(Path.GetTempPath(), "routekeeper-tests-" + Guid.NewGuid().ToString("N"));
Directory.CreateDirectory(root);
int passed = 0;
try
{
    byte[] Data(byte marker)
    {
        using var memory = new MemoryStream(); using var writer = new BinaryWriter(memory);
        writer.Write(Encoding.ASCII.GetBytes("FORM")); writer.Write(18u);
        writer.Write(Encoding.ASCII.GetBytes("GEN8")); writer.Write(2u); writer.Write((byte)0); writer.Write((byte)16);
        writer.Write(Encoding.ASCII.GetBytes("TEST")); writer.Write(0u);
        var result = memory.ToArray(); result[16] = marker; return result;
    }
    string original = Path.Combine(root, "data.win"), candidate = Path.Combine(root, "patched.win");
    File.WriteAllBytes(original, Data(0)); File.WriteAllBytes(candidate, Data(1));
    var identity = BuildInspector.Inspect(original);
    var profile = new CompatibilityProfile("synthetic-only", "VerifiedPatch", "Synthetic", "test", identity.Size, identity.Sha256, identity.Md5, identity.BytecodeVersion, BuildInspector.StructuralHash(identity), SafeInstaller.Hash(candidate));
    void Check(string name, Action action) { action(); passed++; Console.WriteLine("PASS " + name); }
    void Assert(bool ok) { if (!ok) throw new Exception("Assertion failed"); }
    void Reject(Action action) { try { action(); } catch (Exception ex) when (ex is InvalidOperationException or InvalidDataException or IOException) { return; } throw new Exception("Expected rejection"); }
    Check("FORM identity, bytecode, hashes", () => Assert(identity.Size == 26 && identity.BytecodeVersion == 16 && identity.Chunks.Count == 2 && identity.Sha256.Length == 64 && identity.Md5.Length == 32));
    Check("chunk diff sees modified data", () => Assert(BuildInspector.Diff(identity, BuildInspector.Inspect(candidate)).Count == 1));
    Check("unknown build denied", () => Reject(() => CompatibilityRegistry.RequireVerified(identity, [], "Synthetic", "test")));
    Check("inspection-only profile denied", () => Reject(() => CompatibilityRegistry.RequireVerified(identity, [profile with { Status = "InspectedOnly" }], "Synthetic", "test")));
    Check("platform mismatch denied", () => Reject(() => CompatibilityRegistry.RequireVerified(identity, [profile], "Windows", "x64")));
    Check("structural signature mismatch denied", () => Reject(() => CompatibilityRegistry.RequireVerified(identity, [profile with { StructuralSha256 = new string('0', 64) }], "Synthetic", "test")));
    Check("ambiguous profiles denied", () => Reject(() => CompatibilityRegistry.RequireVerified(identity, [profile, profile], "Synthetic", "test")));
    Check("same-file candidate rejected before backup", () => { Reject(() => SafeInstaller.Install(original, original, [profile], "Synthetic", "test")); Assert(!File.Exists(original + ".routekeeper-original")); });
    Check("wrong output hash rejected without target mutation", () => { Reject(() => SafeInstaller.Install(original, candidate, [profile with { PatchedSha256 = new string('0', 64) }], "Synthetic", "test")); Assert(SafeInstaller.Hash(original) == identity.Sha256 && !File.Exists(original + ".routekeeper-original")); });
    Check("exclusive lock prevents concurrent installers", () => { using var held = new FileStream(original + ".routekeeper-lock", FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None); Reject(() => SafeInstaller.Install(original, candidate, [profile], "Synthetic", "test")); Assert(SafeInstaller.Hash(original) == identity.Sha256); });
    string save = Path.Combine(root, "file0"); File.WriteAllText(save, "synthetic save unchanged");
    Check("verified install backs up pristine original", () => { SafeInstaller.Install(original, candidate, [profile], "Synthetic", "test"); Assert(SafeInstaller.Hash(original) == profile.PatchedSha256 && SafeInstaller.Hash(original + ".routekeeper-original") == identity.Sha256); });
    Check("idempotent reinstall", () => { SafeInstaller.Install(original, candidate, [profile], "Synthetic", "test"); Assert(SafeInstaller.Hash(original + ".routekeeper-original") == identity.Sha256); });
    Check("restore and repeated restore", () => { SafeInstaller.Restore(original); SafeInstaller.Restore(original); Assert(SafeInstaller.Hash(original) == identity.Sha256); });
    Check("save untouched", () => Assert(File.ReadAllText(save) == "synthetic save unchanged"));
    Check("update keeps original", () => { File.WriteAllBytes(candidate, Data(2)); var updated = profile with { PatchedSha256 = SafeInstaller.Hash(candidate) }; SafeInstaller.Install(original, candidate, [updated], "Synthetic", "test"); Assert(SafeInstaller.Hash(original) == updated.PatchedSha256 && SafeInstaller.Hash(original + ".routekeeper-original") == identity.Sha256); });
    Check("external mod blocks restore", () => { File.WriteAllBytes(original, Data(3)); Reject(() => SafeInstaller.Restore(original)); Assert(File.ReadAllBytes(original)[16] == 3); });
    Check("corrupt backup blocks restore", () => { File.WriteAllBytes(original, Data(2)); File.WriteAllBytes(original + ".routekeeper-original", Data(4)); Reject(() => SafeInstaller.Restore(original)); Assert(File.ReadAllBytes(original)[16] == 2); });
    Check("truncated FORM rejected", () => { var path = Path.Combine(root, "bad.win"); File.WriteAllBytes(path, [70, 79, 82, 77]); Reject(() => BuildInspector.Inspect(path)); });
    Check("oversized chunk rejected", () => { var path = Path.Combine(root, "bad.win"); var bytes = Data(0); bytes[12] = 250; File.WriteAllBytes(path, bytes); Reject(() => BuildInspector.Inspect(path)); });
    Check("pending update before replacement can restore", () => { File.WriteAllBytes(original + ".routekeeper-original", Data(0)); File.WriteAllBytes(original, Data(1)); var pending = new InstallJournal(1, identity.Sha256, SafeInstaller.Hash(candidate), profile.Id, "Pending", SafeInstaller.Hash(original)); File.WriteAllText(original + ".routekeeper.json", JsonSerializer.Serialize(pending)); SafeInstaller.Restore(original); Assert(SafeInstaller.Hash(original) == identity.Sha256); });
    Check("symbolic-link target rejected", () => { if (OperatingSystem.IsWindows()) return; string link = Path.Combine(root, "linked.win"); File.CreateSymbolicLink(link, original); Reject(() => SafeInstaller.Install(link, candidate, [profile], "Synthetic", "test")); });
    Check("duplicate GEN8 rejected", () => { string path = Path.Combine(root, "bad.win"); var data = Data(0); Encoding.ASCII.GetBytes("GEN8").CopyTo(data, 18); File.WriteAllBytes(path, data); Reject(() => BuildInspector.Inspect(path)); });
    Check("malformed journal fails closed", () => { File.WriteAllText(original + ".routekeeper.json", "{\"SchemaVersion\":1}"); Reject(() => SafeInstaller.Restore(original)); Assert(SafeInstaller.Hash(original) == identity.Sha256); });
    Check("Steam library discovery returns unverified metadata only", () =>
    {
        string steam = Path.Combine(root, "Steam"), library = Path.Combine(root, "ExtraLibrary");
        Directory.CreateDirectory(Path.Combine(steam, "steamapps"));
        string app = Path.Combine(library, "steamapps");
        string game = Path.Combine(app, "common", "Undertale");
        Directory.CreateDirectory(game);
        File.WriteAllText(Path.Combine(steam, "steamapps", "libraryfolders.vdf"), "\"libraryfolders\" { \"1\" { \"path\" \"" + library.Replace("\\", "\\\\", StringComparison.Ordinal) + "\" } }");
        File.WriteAllText(Path.Combine(app, "appmanifest_391540.acf"), "\"AppState\" { \"buildid\" \"123456\" }");
        File.WriteAllBytes(Path.Combine(game, "data.win"), Data(0));
        var found = SteamDiscovery.Discover([steam]);
        Assert(found.Count == 1 && found[0].BuildId == "123456" && found[0].Status == "UnverifiedCandidate");
    });
    Console.WriteLine($"PASS {passed} synthetic tests; authentic gameplay NOT_RUN"); return 0;
}
finally { Directory.Delete(root, recursive: true); }
