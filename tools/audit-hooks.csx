#load "../integration/hooks.csx"
// Read-only exact-build event linkage audit, independent of generated rule parity.
using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using System.Text;
using System.Text.Json;
using UndertaleModLib.Decompiler;
EnsureDataLoaded();
using(var stream=File.OpenRead(FilePath)) {
    if(Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant()!="b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7")
        throw new Exception("Uninspected original hook input.");
}
int checkedHooks=0;
foreach(var name in RoutekeeperHooks.Names.Concat(new[]{"gml_Object_obj_time_Create_0"})) {
    var code=Data.Code.ByName(name)??throw new Exception("Missing original hook resource.");
    if(name.StartsWith("gml_Script_")) {
        if(Data.Scripts.ByName(name.Substring(11))?.Code!=code)throw new Exception("Original script dispatch mismatch.");
    } else {
        var match=Regex.Match(name,@"^gml_Object_(.+)_(Create|Step|Draw|Other|Collision)_(\d+)$");
        if(!match.Success)throw new Exception("Unmodeled hook event kind.");
        var obj=Data.GameObjects.ByName(match.Groups[1].Value)??throw new Exception("Original hook owner missing.");
        int kind=match.Groups[2].Value switch {"Create"=>0,"Step"=>3,"Collision"=>4,"Other"=>7,"Draw"=>8,_=>throw new Exception()};
        uint subtype=uint.Parse(match.Groups[3].Value);
        int links=obj.Events[kind].Where(e=>e.EventSubtype==subtype).SelectMany(e=>e.Actions).Count(a=>a.CodeId==code);
        if(links!=1)throw new Exception("Original event/subtype/action dispatch mismatch: "+name);
    }
    checkedHooks++;
}
Console.WriteLine($"PASS: {checkedHooks} original script/object/event/subtype links; read-only metadata audit; gameplay NOT_RUN.");

// Close provenance for EVERY golden source, including scripts beyond bindings.json.
using(var golden=JsonDocument.Parse(File.ReadAllText(Path.Combine(Path.GetDirectoryName(ScriptPath),"..","tests","golden","original-endings.json")))) {
    var context=new GlobalDecompileContext(Data);int sources=0;
    foreach(var entry in golden.RootElement.GetProperty("sourceSha256").EnumerateObject()) {
        var code=Data.Code.ByName(entry.Name)??throw new Exception("Golden original resource missing.");
        var text=new Underanalyzer.Decompiler.DecompileContext(context,code,Data.ToolInfo.DecompilerSettings).DecompileToString().Replace("\r\n","\n");
        var hash=Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(text))).ToLowerInvariant();
        if(hash!=entry.Value.GetString())throw new Exception("Golden source provenance mismatch: "+entry.Name);
        sources++;
    }
    Console.WriteLine($"PASS: all {sources} golden source hashes revalidated against authentic data; no rule-table oracle or runtime execution.");
}
