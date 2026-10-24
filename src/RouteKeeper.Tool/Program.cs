using System.Text.Json;
using RouteKeeper.Tool;

try
{
    switch (args.FirstOrDefault())
    {
        case "discover" when args.Length == 1:
            Console.WriteLine(JsonSerializer.Serialize(SteamDiscovery.Discover(), CompatibilityRegistry.JsonOptions));
            break;
        case "inspect" when args.Length == 2:
            var identity = BuildInspector.Inspect(args[1]);
            Console.WriteLine(JsonSerializer.Serialize(new { Identity = identity, StructuralSha256 = BuildInspector.StructuralHash(identity), Status = "InspectedOnly", Note = "Filename does not establish OS or Steam build. Hooks and modifications require UndertaleModLib analysis." }, CompatibilityRegistry.JsonOptions));
            break;
        case "diff" when args.Length == 3:
            Console.WriteLine(JsonSerializer.Serialize(BuildInspector.Diff(BuildInspector.Inspect(args[1]), BuildInspector.Inspect(args[2])), CompatibilityRegistry.JsonOptions));
            break;
        case "install" when args.Length == 6:
            SafeInstaller.Install(args[1], args[2], CompatibilityRegistry.Load(args[3]), args[4], args[5]);
            Console.WriteLine("PASS: installed; pristine original retained.");
            break;
        case "restore" when args.Length == 2:
            SafeInstaller.Restore(args[1]);
            Console.WriteLine("PASS: restored; verified backup retained.");
            break;
        default:
            Console.Error.WriteLine("Usage: discover | inspect DATA | diff BEFORE AFTER | install TARGET CANDIDATE REGISTRY PLATFORM ARCH | restore TARGET");
            return 2;
    }
    return 0;
}
catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or InvalidOperationException or JsonException or ArgumentException)
{
    Console.Error.WriteLine("FAIL: " + ex.Message);
    return 1;
}
