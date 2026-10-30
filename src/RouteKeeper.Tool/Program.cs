using RouteKeeper.Core;
using System.Text.Json;
using RouteKeeper.Tool;

static object Describe(ReachabilityResult r)=>new { Verdict=r.Verdict.ToString(),r.Evidence,r.Events,r.FinalState };

try
{
    switch (args.FirstOrDefault())
    {
        case "analyze-reachability" when args.Length == 1:
            var rows=from target in Enumerable.Range(0,19) from goal in Enumerable.Range(0,9)
                let analysis=EndingReachability.Neutral(target,goal)
                select new { Target=target,CallGoal=goal,Verdict=analysis.Verdict.ToString(),analysis.Evidence,analysis.Events,analysis.FinalState };
            Console.WriteLine(JsonSerializer.Serialize(new { Scope="SOURCE_MODEL_ONLY; combat, RNG and movement witnesses are not runtime execution",Neutral=rows,
                Pacifist=new[]{EndingReachability.Pacifist(false,1),EndingReachability.Pacifist(false,2),EndingReachability.Pacifist(true,1),EndingReachability.Pacifist(true,2)}.Select(Describe),
                Genocide=new[]{EndingReachability.Genocide(false,false),EndingReachability.Genocide(false,true)}.Select(Describe) },CompatibilityRegistry.JsonOptions));
            break;
        case "g3m-package" when args.Length is 7 or 8:
            await G3MPackage.CreateAsync(args[1], args[2], args[3], args[4], CompatibilityRegistry.Load(Path.Combine(args.Length == 8 ? args[7] : AppContext.BaseDirectory,"profiles","registry.json")), args[5], args[6]);
            Console.WriteLine("PASS: exact-hash G3M package generated and delta roundtrip verified; no game installed.");
            break;
        case "build" when args.Length is 4 or 5:
            Console.WriteLine(JsonSerializer.Serialize(await ModBuilder.BuildAsync(args[1], args[2], args[3], args.Length == 5 ? args[4] : AppContext.BaseDirectory), CompatibilityRegistry.JsonOptions));
            break;
        case "install-source" when args.Length is 5 or 6:
            await SourceInstaller.InstallAsync(args[1], args[2], args[3], args[4], args.Length == 6 ? args[5] : AppContext.BaseDirectory);
            Console.WriteLine("PASS: source patch built and installed using a verified profile; pristine original retained.");
            break;
        case "inspect-runner" when args.Length == 2:
            Console.WriteLine(JsonSerializer.Serialize(ExecutableInspector.Inspect(args[1]), CompatibilityRegistry.JsonOptions));
            break;
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
            Console.Error.WriteLine("Usage: g3m-package ORIGINAL CANDIDATE XDELTA3 NEW_ZIP PLATFORM ARCH [ASSETS] | build SOURCE NEW_OUTPUT CLI [ASSET_ROOT] | install-source TARGET CLI PLATFORM ARCH [ASSET_ROOT] | inspect-runner EXECUTABLE | discover | inspect DATA | diff BEFORE AFTER | install TARGET CANDIDATE REGISTRY PLATFORM ARCH | restore TARGET");
            return 2;
    }
    return 0;
}
catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or InvalidOperationException or JsonException or ArgumentException)
{
    Console.Error.WriteLine("FAIL: " + ex.Message);
    return 1;
}
