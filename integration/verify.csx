// Reload verification for the experimental output; writes no game data.
using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using UndertaleModLib.Decompiler;
using UndertaleModLib;
EnsureDataLoaded();
var context = new GlobalDecompileContext(Data);
string Get(string name) {
    var code = Data.Code.ByName(name) ?? throw new Exception("FAIL missing code: " + name);
    return new Underanalyzer.Decompiler.DecompileContext(context,code,Data.ToolInfo.DecompilerSettings).DecompileToString();
}
void Check(bool condition, string text) { if(!condition) throw new Exception("FAIL: " + text); Console.WriteLine("PASS: " + text); }
var obj = Data.GameObjects.ByName("obj_routekeeper");
Check(obj != null && obj.Persistent && obj.Visible,"persistent visible controller");
Check(Get("gml_Object_obj_time_Create_0").Contains("instance_create(0, 0, obj_routekeeper)"),"verified startup hook retained");
Check(Get("gml_Object_obj_routekeeper_Create_0").Contains("global.rk_soul_sold = -1"),"unbound persistent history remains unknown");
var step = Get("gml_Object_obj_routekeeper_Step_0");
Check(step.Contains("global.rk_experience = global.xp"),"XP observation binding");
Check(step.Contains("scr_routekeeper_evaluate()"),"shared generated evaluator invoked");
Check(step.Contains("obj_battlecontroller") && step.Contains("obj_heart") && step.Contains("obj_mainchara.cutscene"),"battle/cutscene visibility gates");
var evaluator = Get("gml_Script_scr_routekeeper_evaluate");
Check(evaluator.Contains("global.rk_experience") && evaluator.Contains("return 3") && evaluator.Contains("return 4"),"generated status evaluator roundtrip");
var draw = Get("gml_Object_obj_routekeeper_Draw_64");
Check(draw.Contains("fnt_routekeeper") && draw.Contains("한국어"),"localized GUI code roundtrip");
var font = Data.Fonts.ByName("fnt_routekeeper");
Check(font != null && font.Texture != null && font.Glyphs.Any(g=>g.Character=='한'),"embedded Hangul font");
var glyphs = font.Glyphs.Select(g=>(char)g.Character).ToHashSet();
foreach (char c in draw.Where(c=>c>=0xac00 && c<=0xd7a3).Distinct())
    Check(glyphs.Contains(c),"Hangul glyph U+" + ((int)c).ToString("X4"));
Check(Data.Code.Count == 6276,"exactly four new code resources");
Console.WriteLine("PASS: real-data serialize/reload/decompile verification. Gameplay startup is NOT_RUN.");

var pristinePath = Environment.GetEnvironmentVariable("ROUTEKEEPER_ORIGINAL");
if (!string.IsNullOrEmpty(pristinePath)) {
    using var originalFile = File.OpenRead(pristinePath);
    var pristine = UndertaleIO.Read(originalFile);
    int unchanged = 0;
    foreach (var before in pristine.Code) {
        if (before.Name.Content == "gml_Object_obj_time_Create_0") continue;
        var after = Data.Code.ByName(before.Name.Content);
        if (after == null || before.Disassemble(pristine.Variables,pristine.CodeLocals.For(before)) != after.Disassemble(Data.Variables,Data.CodeLocals.For(after)))
            throw new Exception("FAIL: unexpected code modification: " + before.Name.Content);
        unchanged++;
    }
    Check(unchanged == 6271,"all 6271 non-hook original code resources retain identical disassembly");
}
