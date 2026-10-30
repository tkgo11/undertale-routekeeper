using RouteKeeper.Saves;

if (args is ["--authentic", var inputDirectory])
{
    var before = SaveInventory.Inspect(inputDirectory);
    var parsed = before.Where(x => x.Kind is SaveKind.Playthrough or SaveKind.PersistentEncounter or SaveKind.Recovery)
        .Select(x => SaveInventory.ReadLines(Path.Combine(inputDirectory, x.Name))).ToArray();
    var after = SaveInventory.Inspect(inputDirectory);
    if (!before.SequenceEqual(after)) throw new Exception("Input changed during read-only inspection.");
    if (parsed.Length == 0) throw new Exception("No supplied line saves inspected.");
    Console.WriteLine($"PASS: authentic read-only save inspection; {parsed.Length} line saves, {before.Count} recognized files; bytes unchanged; positional field mapping NOT_RUN");
    return;
}

var directory = Path.Combine(Path.GetTempPath(), "routekeeper-saves-" + Guid.NewGuid());
Directory.CreateDirectory(directory);
var checks = 0;
void Check(bool condition, string message) { if (!condition) throw new Exception(message); checks++; }
try
{
    File.WriteAllText(Path.Combine(directory, "file0"), "NAME\r\n0\r\n");
    File.WriteAllText(Path.Combine(directory, "system_information_962"), "synthetic history");
    var first = SaveInventory.Inspect(directory);
    var save = SaveInventory.ReadLines(Path.Combine(directory, "file0"));
    Check(save.Lines.SequenceEqual(new[] { "NAME", "0" }) && save.Newline == "\r\n" && save.TrailingNewline, "CRLF parsing");
    Check(first.Count == 2 && first.Single(x => x.Name == "system_information_962").Kind == SaveKind.PermanentHistory, "classification");
    Check(SaveInventory.PermanentHistoryUnchanged(first, SaveInventory.Inspect(directory)), "read-only inventory");
    File.WriteAllText(Path.Combine(directory, "file0"), "reset");
    Check(SaveInventory.PermanentHistoryUnchanged(first, SaveInventory.Inspect(directory)), "ordinary reset does not imply history reset");
    File.Delete(Path.Combine(directory, "system_information_962"));
    Check(!SaveInventory.PermanentHistoryUnchanged(first, SaveInventory.Inspect(directory)), "deleted history detected");
    File.WriteAllText(Path.Combine(directory, "system_information_unknown"), "protected");
    Check(SaveInventory.Inspect(directory).Any(x => x.Kind == SaveKind.PermanentHistory), "unknown history protected");
    File.WriteAllText(Path.Combine(directory, "file0"), "bad\0data");
    try { SaveInventory.ReadLines(Path.Combine(directory, "file0")); throw new Exception("binary accepted"); }
    catch (InvalidDataException) { checks++; }
    string caseHistory=Path.Combine(directory,"SYSTEM_INFORMATION_963");File.WriteAllText(caseHistory,"synthetic case variant");
    var withCaseHistory=SaveInventory.Inspect(directory);
    Check(withCaseHistory.Any(x=>x.Name=="SYSTEM_INFORMATION_963"&&x.Kind==SaveKind.PermanentHistory),"Case-variant history must be conservatively protected");
    File.Delete(caseHistory);
    Check(!SaveInventory.PermanentHistoryUnchanged(withCaseHistory,SaveInventory.Inspect(directory)),"Case-variant history deletion must be detected");
    using(var exact=new MemoryStream(new byte[1024*1024].Select(_=>(byte)'a').ToArray()))
        Check(SaveInventory.ReadLines(exact).Lines[0].Length==1024*1024,"Exact byte bound must be accepted");
    using(var growing=new UnderreportedStream(new byte[1024*1024+1].Select(_=>(byte)'a').ToArray())){
        bool refused=false;try{SaveInventory.ReadLines(growing);}catch(InvalidDataException){refused=true;}
        Check(refused&&growing.CanRead,"Actual read bound, not reported Length; caller retains ownership");
    }
    Console.WriteLine($"PASS: {checks} save preservation checks (synthetic)");
}
finally { Directory.Delete(directory, true); }

sealed class UnderreportedStream(byte[] bytes):MemoryStream(bytes) { public override long Length=>0; }
