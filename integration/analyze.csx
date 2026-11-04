// Read-only metadata and selected hook signatures; never dumps game code or saves.
using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using UndertaleModLib.Decompiler;
EnsureDataLoaded();
var context = new GlobalDecompileContext(Data);
var hooks = new[] { "gml_Object_obj_time_Create_0", "gml_Script_scr_load", "gml_Object_obj_mainchara_Create_0" };
var signatures = hooks.Select(name => {
    var code = Data.Code.ByName(name) ?? throw new Exception("Missing hook: " + name);
    var text = new Underanalyzer.Decompiler.DecompileContext(context,code,Data.ToolInfo.DecompilerSettings).DecompileToString();
    return new { Name = name, DecompilerSha256 = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(text))).ToLowerInvariant() };
}).ToArray();
using(var input=File.OpenRead(FilePath)) Console.WriteLine(JsonSerializer.Serialize(new {
    FileSha256=Convert.ToHexString(SHA256.HashData(input)).ToLowerInvariant(),
    FileSize=new FileInfo(FilePath).Length,
    InternalName=Data.GeneralInfo.Name.Content,
    NominalVersion=$"{Data.GeneralInfo.Major}.{Data.GeneralInfo.Minor}.{Data.GeneralInfo.Release}.{Data.GeneralInfo.Build}",
    Bytecode=Data.GeneralInfo.BytecodeVersion,
    CodeCount=Data.Code.Count, RoomCount=Data.Rooms.Count,
    TimePersistent=Data.GameObjects.ByName("obj_time")?.Persistent,
    Hooks=signatures, Status="InspectedOnly", Os="Unknown", Architecture="Unknown", SteamBuildId=(string)null
},new JsonSerializerOptions{WriteIndented=true}));
