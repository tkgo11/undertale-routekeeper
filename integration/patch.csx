#load "bindings.csx"
#load "hooks.csx"
// Development patch generation only. Never patches an installed game in place.
// UndertaleModCli 0.9.2 / UndertaleModLib GPLv3 API.
using System;
using System.IO;
using System.Linq;
using System.Text.Json;
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
        FileSystemInfo info = Directory.Exists(current) ? new DirectoryInfo(current) : new FileInfo(current);
        if (info.LinkTarget != null || (info.Exists && (info.Attributes & FileAttributes.ReparsePoint) != 0))
            throw new InvalidOperationException("Symbolic links are not accepted for patch generation paths.");
    }
}
RejectLinks(FilePath);
RejectLinks(outputPath);
// Pinned CLI SaveDataFile uses FileMode.Create on outputPath + "temp", then
// overwrites outputPath by rename. Protect that host-owned scratch path too.
string scratchPath = outputPath + "temp";
RejectLinks(scratchPath);
if (Path.Exists(scratchPath))
    throw new InvalidOperationException("Compiler scratch output must be new; existing evidence is retained.");
const string expected = "b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7";
string actual;
using (var input = File.OpenRead(FilePath)) actual = Convert.ToHexString(SHA256.HashData(input)).ToLowerInvariant();
if (actual != expected) throw new InvalidOperationException("Unverified build: patch generation refused.");
if (Data.GeneralInfo.BytecodeVersion != 16 || Data.Code.Count != 6272 || Data.Rooms.Count != 336)
    throw new InvalidOperationException("Unexpected structural signature.");
if (Data.GameObjects.ByName("obj_routekeeper") != null)
    throw new InvalidOperationException("Existing ROUTEKEEPER detected.");
var folder = Path.GetDirectoryName(ScriptPath);
RoutekeeperBindings.Validate(Data, folder, FilePath);
var context = new GlobalDecompileContext(Data);
string Decompile(string name) {
    var code = Data.Code.ByName(name) ?? throw new Exception("Missing hook: " + name);
    return new Underanalyzer.Decompiler.DecompileContext(context, code, Data.ToolInfo.DecompilerSettings).DecompileToString().Replace("\r\n", "\n");
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

// Append manifest-declared licensed atlases; original fonts/pages remain unchanged.
var fontManifest = JsonDocument.Parse(File.ReadAllText(Path.Combine(folder,"assets","fonts","manifest.json")));
foreach (var entry in fontManifest.RootElement.EnumerateArray()) {
    string FontFile(string field) {
        var relative = entry.GetProperty(field).GetString();
        if (Path.IsPathRooted(relative) || relative.Split('/','\\').Contains("..")) throw new Exception("Invalid font manifest path");
        var path=Path.Combine(folder,"assets",relative); RejectLinks(path); return path;
    }
    var resource=entry.GetProperty("resource").GetString();
    if (!System.Text.RegularExpressions.Regex.IsMatch(resource,@"^fnt_routekeeper[a-zA-Z0-9_]*$") || Data.Fonts.ByName(resource)!=null) throw new Exception("Font resource conflict");
    var page = new UndertaleEmbeddedTexture { Name = Data.Strings.MakeString("Routekeeper "+resource) };
    var fontImage = GMImage.FromPng(File.ReadAllBytes(FontFile("atlas")));
    if (fontImage.Width>2048 || fontImage.Height>2048) throw new Exception("Unsupported font atlas size");
    page.TextureData.Image=fontImage; Data.EmbeddedTextures.Add(page);
    var item = new UndertaleTexturePageItem {
        Name=Data.Strings.MakeString("Routekeeper "+resource),
        SourceWidth=(ushort)fontImage.Width,SourceHeight=(ushort)fontImage.Height,
        TargetWidth=(ushort)fontImage.Width,TargetHeight=(ushort)fontImage.Height,
        BoundingWidth=(ushort)fontImage.Width,BoundingHeight=(ushort)fontImage.Height,TexturePage=page
    };
    Data.TexturePageItems.Add(item);
    var font = new UndertaleFont {
        Name=Data.Strings.MakeString(resource),DisplayName=Data.Strings.MakeString(entry.GetProperty("displayName").GetString()),
        EmSize=entry.GetProperty("lineHeight").GetInt32(),AntiAliasing=0,RangeStart=32,Texture=item
    };
    int previous=-1;
    foreach(var line in File.ReadAllLines(FontFile("glyphs"))) {
        var v=line.Split('\t').Select(int.Parse).ToArray();
        if(v.Length!=5 || v[0]<=previous || v[0]>65535 || v[0]<32 || v[1]<0 || v[2]<0 || v[1]+24>fontImage.Width || v[2]+18>fontImage.Height || v[3]<0 || v[3]>24 || v[4]<-24 || v[4]>24) throw new Exception("Invalid glyph metadata");
        previous=v[0];
        font.Glyphs.Add(new UndertaleFont.Glyph {Character=(ushort)v[0],SourceX=(ushort)v[1],SourceY=(ushort)v[2],SourceWidth=24,SourceHeight=18,Shift=(short)v[3],Offset=(short)v[4]});
    }
    if(font.Glyphs.Count!=entry.GetProperty("glyphCount").GetInt32()) throw new Exception("Glyph count mismatch");
    font.RangeEnd=font.Glyphs.Last().Character;Data.Fonts.Add(font);
}
// The authentic Windows runner rejects font/alignment getters on load. Render
// glyphs through mod-owned sprites that alias the exact existing font atlas;
// never change the original font resources or any vanilla draw-state setters.
var glyphCode = new System.Text.StringBuilder();
glyphCode.AppendLine("var character; character = argument0;");
glyphCode.AppendLine("global.rk_glyph_sprite = -1; global.rk_glyph_x = 0; global.rk_glyph_y = 0;");
glyphCode.AppendLine("global.rk_glyph_width = 0; global.rk_glyph_height = 0; global.rk_glyph_offset = 0;");
glyphCode.AppendLine("switch (scr_routekeeper_locale_font(argument1)) {");
var uiFonts = new[] { Data.Fonts.ByName("fnt_maintext") }
    .Concat(fontManifest.RootElement.EnumerateArray().Select(entry => Data.Fonts.ByName(entry.GetProperty("resource").GetString())));
foreach (var font in uiFonts) {
    var texture = font.Texture;
    if (font.ScaleX != 1 || font.ScaleY != 1 || font.Ascender != 0 || font.AscenderOffset != 0
        || texture == null || texture.TargetX != 0 || texture.TargetY != 0
        || texture.SourceWidth != texture.TargetWidth || texture.SourceHeight != texture.TargetHeight
        || texture.BoundingWidth != texture.TargetWidth || texture.BoundingHeight != texture.TargetHeight
        || font.Glyphs.Any(glyph => glyph.Kerning.Count != 0))
        throw new InvalidOperationException("Unsupported UI glyph atlas geometry; no guessed text metrics.");
    var spriteName = "spr_routekeeper_glyphs_" + font.Name.Content;
    if (Data.Sprites.ByName(spriteName) != null) throw new InvalidOperationException("UI glyph sprite conflict.");
    var sprite = new UndertaleSprite {
        Name = Data.Strings.MakeString(spriteName), Width = texture.TargetWidth, Height = texture.TargetHeight,
        MarginLeft = 0, MarginTop = 0, MarginRight = (int)texture.TargetWidth - 1,
        MarginBottom = (int)texture.TargetHeight - 1, OriginX = 0, OriginY = 0,
        Transparent = true, Smooth = false, Preload = true
    };
    sprite.Textures.Add(new UndertaleSprite.TextureEntry { Texture = texture });
    Data.Sprites.Add(sprite);
    glyphCode.AppendLine("case " + font.Name.Content + ":");
    glyphCode.AppendLine("global.rk_glyph_sprite = " + spriteName + "; switch (character) {");
    string GlyphMetrics(UndertaleFont.Glyph glyph) {
        if (glyph.SourceX + glyph.SourceWidth > texture.TargetWidth || glyph.SourceY + glyph.SourceHeight > texture.TargetHeight
            || glyph.Shift < 0)
            throw new InvalidOperationException("UI glyph exceeds authenticated atlas or has unsupported advance.");
        return "global.rk_glyph_x = " + glyph.SourceX + "; global.rk_glyph_y = " + glyph.SourceY
            + "; global.rk_glyph_width = " + glyph.SourceWidth + "; global.rk_glyph_height = " + glyph.SourceHeight
            + "; global.rk_glyph_offset = " + glyph.Offset + "; return " + glyph.Shift + ";";
    }
    foreach (var glyph in font.Glyphs) glyphCode.AppendLine("case " + glyph.Character + ": " + GlyphMetrics(glyph));
    var fallback = font.Glyphs.SingleOrDefault(glyph => glyph.Character == 63)
        ?? throw new InvalidOperationException("UI font lacks an explicit missing-glyph fallback.");
    glyphCode.AppendLine("default: " + GlyphMetrics(fallback) + " } break;");
}
glyphCode.AppendLine("} return 0;");
var obj = new UndertaleGameObject {
    Name = Data.Strings.MakeString("obj_routekeeper"), Persistent = true, Visible = true, Awake = true
};
Data.GameObjects.Add(obj);
var import = new CodeImportGroup(Data) { AutoCreateAssets = true, MainThreadAction = MainThreadAction };
// Import every maintained script; generated route logic and handwritten adapters
// share the same resource namespace. Event files are bound explicitly below.
foreach (var path in Directory.GetFiles(Path.Combine(folder,"gml"),"*.gml").OrderBy(p=>p,StringComparer.Ordinal)) {
    var name = Path.GetFileNameWithoutExtension(path);
    if (name.StartsWith("controller_",StringComparison.Ordinal)) continue;
    if (name == "state_read") name = "read_state";
    if (name == "fact_init") name = "init_facts";
    if (name.StartsWith("route_",StringComparison.Ordinal)) name = name.Substring(6);
    import.QueueReplace("gml_Script_scr_routekeeper_" + name, File.ReadAllText(path));
}
import.QueueReplace("gml_Object_obj_routekeeper_Create_0", File.ReadAllText(Path.Combine(folder,"gml","controller_create.gml")));
import.QueueReplace("gml_Object_obj_routekeeper_Step_0", File.ReadAllText(Path.Combine(folder,"gml","controller_step.gml")));
import.QueueReplace("gml_Object_obj_routekeeper_Draw_64", File.ReadAllText(Path.Combine(folder,"gml","controller_draw.gml")));
import.QueueReplace("gml_Script_scr_routekeeper_ui_glyph", glyphCode.ToString());
var changedHooks = RoutekeeperHooks.Apply(Data, import);
import.QueueAppend("gml_Object_obj_time_Create_0", "\nif (!instance_exists(obj_routekeeper)) instance_create(0, 0, obj_routekeeper);\n");
import.Import();
Console.WriteLine("PASS: native route controller and " + changedHooks.Count + " source-validated decision hooks compiled; gameplay verification is NOT_RUN.");
