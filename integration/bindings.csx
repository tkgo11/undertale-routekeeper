// Read-only verification of exact-build adapter evidence and source contract.
using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Security.Cryptography;
using UndertaleModLib.Decompiler;
public static class RoutekeeperBindings
{
    public static void Validate(UndertaleModLib.UndertaleData data, string folder, string inputPath)
    {
        using var manifest = JsonDocument.Parse(File.ReadAllText(Path.Combine(folder,"..","profiles","bindings.json")));
        var root = manifest.RootElement;
        using (var input = File.OpenRead(inputPath)) {
            if (Convert.ToHexString(SHA256.HashData(input)).ToLowerInvariant() != root.GetProperty("ExpectedInputSha256").GetString())
                throw new InvalidOperationException("Unverified binding input.");
        }
        if (data.GeneralInfo.BytecodeVersion != root.GetProperty("BytecodeVersion").GetInt32()) throw new Exception("Bytecode mismatch.");
        foreach (var room in root.GetProperty("RequiredRooms").EnumerateArray()) {
            int index = room.GetProperty("Index").GetInt32();
            if (index < 0 || index >= data.Rooms.Count || data.Rooms[index].Name.Content != room.GetProperty("Resource").GetString())
                throw new Exception("Observed region room signature changed.");
        }
        var context = new GlobalDecompileContext(data);
        int checkedEvidence = 0;
        foreach (var evidence in root.GetProperty("Evidence").EnumerateArray()) {
            string name = evidence.GetProperty("Resource").GetString();
            var code = data.Code.ByName(name) ?? throw new Exception("Missing evidence: " + name);
            string text = new Underanalyzer.Decompiler.DecompileContext(context,code,data.ToolInfo.DecompilerSettings).DecompileToString();
            string hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(text.Replace("\r\n", "\n")))).ToLowerInvariant();
            if (hash != evidence.GetProperty("DecompilerSha256").GetString()) throw new Exception("Evidence signature changed: " + name);
            foreach (var marker in evidence.GetProperty("Markers").EnumerateArray())
                if (!text.Contains(marker.GetString())) throw new Exception("Missing evidence marker: " + name);
            checkedEvidence++;
        }
        string native = File.ReadAllText(Path.Combine(folder,"gml","state_read.gml"));
        string Normalize(string text) => Regex.Replace(text,@"\s+","");
        if (Regex.IsMatch(native,@"global\.(?!rk_)[A-Za-z_][A-Za-z_0-9]*(?:\[[^\]]+\])?\s*(?:[+*/-]=|=(?!=))"))
            throw new Exception("State adapter writes vanilla globals.");
        if (Regex.IsMatch(native,@"\b(?:file_delete|file_rename|file_copy|file_text_open_write|file_bin_open|ini_write_[A-Za-z_]+)\s*\("))
            throw new Exception("State adapter contains a save-writing operation.");
        int checkedBindings = 0;
        foreach (var binding in root.GetProperty("Bindings").EnumerateArray()) {
            string assignment = "global.rk_" + binding.GetProperty("Fact").GetString() + "=" + binding.GetProperty("Expression").GetString() + ";";
            if (!Normalize(native).Contains(Normalize(assignment))) throw new Exception("Native binding differs from manifest: " + binding.GetProperty("Fact").GetString());
            checkedBindings++;
        }
        Console.WriteLine($"PASS: {checkedBindings} native bindings, {checkedEvidence} authentic source signatures; no game/save mutation; gameplay NOT_RUN.");
    }
}
