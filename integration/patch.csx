// Development patch generation only. Never patches an installed game in place.
// UndertaleModCli 0.9.2 / UndertaleModLib GPLv3 API.
using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using UndertaleModLib.Compiler;
using UndertaleModLib.Models;
using UndertaleModLib.Util;
using UndertaleModLib.Decompiler;

EnsureDataLoaded();
// The host writes output after script execution. Refuse unsafe host arguments
// before adding any resource, including --overwrite pointing at the sole original.
var cliArgs = Environment.GetCommandLineArgs();
string destination = null;
for (int i = 0; i < cliArgs.Length; i++) {
    if ((cliArgs[i] == "-o" || cliArgs[i] == "--output") && i + 1 < cliArgs.Length)
        destination = cliArgs[++i];
    else if (cliArgs[i].StartsWith("--output=")) destination = cliArgs[i].Substring(9);
}
if (string.IsNullOrEmpty(destination)) throw new InvalidOperationException("Explicit new output path required.");
string outputPath = Path.GetFullPath(destination);
if (string.Equals(outputPath,Path.GetFullPath(FilePath),StringComparison.OrdinalIgnoreCase)
    || File.Exists(outputPath) || Directory.Exists(outputPath))
    throw new InvalidOperationException("Output must be a new file distinct from the pristine original.");
void RejectLinks(string path) {
    for (string current = Path.GetFullPath(path); current != null; current = Path.GetDirectoryName(current)) {
        if ((File.Exists(current) || Directory.Exists(current))
            && (File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0)
            throw new InvalidOperationException("Symbolic links are not accepted for patch generation paths.");
    }
}
RejectLinks(FilePath);
RejectLinks(outputPath);
const string expected = "b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7";
string actual;
using (var input = File.OpenRead(FilePath)) actual = Convert.ToHexString(SHA256.HashData(input)).ToLowerInvariant();
if (actual != expected) throw new InvalidOperationException("Unverified build: patch generation refused.");
if (Data.GeneralInfo.BytecodeVersion != 16 || Data.Code.Count != 6272 || Data.Rooms.Count != 336)
    throw new InvalidOperationException("Unexpected structural signature.");
if (Data.GameObjects.ByName("obj_routekeeper") != null)
    throw new InvalidOperationException("Existing ROUTEKEEPER detected.");
var folder = Path.GetDirectoryName(ScriptPath);
var context = new GlobalDecompileContext(Data);
string Decompile(string name) {
    var code = Data.Code.ByName(name) ?? throw new Exception("Missing hook: " + name);
    return new Underanalyzer.Decompiler.DecompileContext(context, code, Data.ToolInfo.DecompilerSettings).DecompileToString();
}
// A pinned decompiler signature catches unexpected tool/API drift too.
string hook = Decompile("gml_Object_obj_time_Create_0");
string hookHash = Convert.ToHexString(SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(hook))).ToLowerInvariant();
if (hookHash != "2c96d9edfaab627915a0b7d8c05eb5c57353225602c52f772e36bb50730aba88")
    throw new InvalidOperationException("Hook signature mismatch.");
var load = Decompile("gml_Script_scr_load");
if (!load.Contains("global.xp = ossafe_file_text_read_real(myfileid)"))
    throw new InvalidOperationException("XP observation binding mismatch.");
if (!Decompile("gml_Object_obj_mainchara_Create_0").Contains("cutscene = 0"))
    throw new InvalidOperationException("Cutscene gate binding mismatch.");
if (!Data.Variables.Any(v => v.Name.Content == "debug"))
    throw new InvalidOperationException("Debug safety gate missing.");
if (!Data.GameObjects.ByName("obj_time").Persistent)
    throw new InvalidOperationException("Controller spawn lifetime mismatch.");
foreach (var name in new[] {"obj_mainchara", "obj_battlecontroller", "obj_heart"})
    if (Data.GameObjects.ByName(name) == null) throw new Exception("Missing safety gate: " + name);

// Add a new atlas; never rewrite the game's fonts or texture pages.
var page = new UndertaleEmbeddedTexture { Name = Data.Strings.MakeString("Routekeeper UI atlas") };
page.TextureData.Image = GMImage.FromPng(File.ReadAllBytes(Path.Combine(folder, "assets", "ui-font.png")));
Data.EmbeddedTextures.Add(page);
var item = new UndertaleTexturePageItem {
    Name = Data.Strings.MakeString("Routekeeper font page"),
    SourceWidth = 768, SourceHeight = 192, TargetWidth = 768, TargetHeight = 192,
    BoundingWidth = 768, BoundingHeight = 192, TexturePage = page
};
Data.TexturePageItems.Add(item);
var font = new UndertaleFont {
    Name = Data.Strings.MakeString("fnt_routekeeper"),
    DisplayName = Data.Strings.MakeString("Routekeeper Noto Sans CJK subset"),
    EmSize = 16, AntiAliasing = 1, RangeStart = 32, Texture = item
};
foreach (var line in File.ReadAllLines(Path.Combine(folder, "assets", "ui-font.tsv"))) {
    var v = line.Split('\t').Select(int.Parse).ToArray();
    font.Glyphs.Add(new UndertaleFont.Glyph {
        Character = (ushort)v[0], SourceX = (ushort)v[1], SourceY = (ushort)v[2],
        SourceWidth = 24, SourceHeight = 24, Shift = (short)v[3], Offset = 0
    });
}
font.RangeEnd = font.Glyphs.Last().Character;
Data.Fonts.Add(font);
var obj = new UndertaleGameObject {
    Name = Data.Strings.MakeString("obj_routekeeper"), Persistent = true, Visible = true, Awake = true
};
Data.GameObjects.Add(obj);
foreach (var function in new[] { "draw_get_font", "draw_get_halign", "draw_get_valign" })
    Data.Functions.EnsureDefined(function, Data.Strings);
var import = new CodeImportGroup(Data) { AutoCreateAssets = true, MainThreadAction = MainThreadAction };
import.QueueReplace("gml_Script_scr_routekeeper_evaluate", File.ReadAllText(Path.Combine(folder,"gml","route_evaluate.gml")));
import.QueueReplace("gml_Object_obj_routekeeper_Create_0", File.ReadAllText(Path.Combine(folder,"gml","controller_create.gml")));
import.QueueReplace("gml_Object_obj_routekeeper_Step_0", File.ReadAllText(Path.Combine(folder,"gml","controller_step.gml")));
import.QueueReplace("gml_Object_obj_routekeeper_Draw_64", File.ReadAllText(Path.Combine(folder,"gml","controller_draw.gml")));
import.QueueAppend("gml_Object_obj_time_Create_0", "\nif (!instance_exists(obj_routekeeper)) instance_create(0, 0, obj_routekeeper);\n");
import.Import();
Console.WriteLine("PASS: experimental native controller compiled; gameplay verification is NOT_RUN.");
