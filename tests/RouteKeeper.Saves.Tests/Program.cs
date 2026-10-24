using RouteKeeper.Saves;

if (args is ["--authentic", var inputDirectory])
{
    var before = SaveInventory.Inspect(inputDirectory);
    var parsed = before.Where(x => x.Name is "file0" or "file8" or "file9")
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
    Console.WriteLine($"PASS: {checks} save preservation checks (synthetic)");
}
finally { Directory.Delete(directory, true); }
