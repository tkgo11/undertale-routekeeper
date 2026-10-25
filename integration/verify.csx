#load "hooks.csx"
#load "bindings.csx"
// Structural integration verification. Never writes data or claims runner compatibility.
using System;
using System.IO;
using System.Linq;
using UndertaleModLib;
using System.Security.Cryptography;
using UndertaleModLib.Decompiler;
EnsureDataLoaded();
var folder = Path.GetDirectoryName(ScriptPath);
var context = new GlobalDecompileContext(Data);
string Get(string name) {
    var code=Data.Code.ByName(name) ?? throw new Exception("Missing code: "+name);
    return new Underanalyzer.Decompiler.DecompileContext(context,code,Data.ToolInfo.DecompilerSettings).DecompileToString();
}
void Check(bool condition,string label) {
    if(!condition) throw new Exception("FAIL: "+label);
    Console.WriteLine("PASS: "+label);
}
string Resource(string name) {
    if(name=="state_read") name="read_state";
    if(name=="fact_init") name="init_facts";
    if(name.StartsWith("route_")) name=name.Substring(6);
    return "gml_Script_scr_routekeeper_"+name;
}
var scripts=Directory.GetFiles(Path.Combine(folder,"gml"),"*.gml")
    .Select(Path.GetFileNameWithoutExtension).Where(n=>!n.StartsWith("controller_")).ToArray();
foreach(var name in scripts) {
    var codeName=Resource(name);
    Check(Data.Code.ByName(codeName)!=null,"linked script "+name);
    Check(Data.Scripts.ByName(codeName.Substring("gml_Script_".Length))?.Code==Data.Code.ByName(codeName),"script reference "+name);
}
var controller=Data.GameObjects.ByName("obj_routekeeper");
Check(controller!=null && controller.Persistent && controller.Visible,"persistent visible controller");
foreach(var code in new[]{"gml_Object_obj_routekeeper_Create_0","gml_Object_obj_routekeeper_Step_0","gml_Object_obj_routekeeper_Draw_64"})
    Check(controller.Events.SelectMany(e=>e).SelectMany(e=>e.Actions).Any(a=>a.CodeId?.Name.Content==code),"controller event "+code);
Check(Get("gml_Object_obj_time_Create_0").Contains("instance_create(0, 0, obj_routekeeper)"),"startup hook");
var create=Get("gml_Object_obj_routekeeper_Create_0");
foreach(var setting in new[]{"schema","target_route","target_neutral","target_epilogue","mode","spoilers","language"})
    Check(create.Contains("\""+setting+"\""),"persistent setting "+setting);
var step=Get("gml_Object_obj_routekeeper_Step_0");
Check(step.Contains("scr_routekeeper_read_state()") && step.Contains("scr_routekeeper_evaluate()"),"live shared evaluator");
Check(step.Contains("obj_battlecontroller") && step.Contains("obj_mainchara.cutscene"),"ordinary UI battle/cutscene gates");
Check(step.Contains("joystick_check_button") && step.Contains("gamepad_button_check"),"both authentic input backends");
Check(step.Contains("scr_routekeeper_warning_session(2"),"shared deferred warning acknowledgement");
var state=Get("gml_Script_scr_routekeeper_read_state");
foreach(var fact in new[]{"global.rk_experience = global.xp","global.rk_plot10","global.rk_papyrus_friendship","global.rk_kills_ruins","global.rk_prior_neutral_completion","global.rk_soul_sold"})
    Check(state.Contains(fact),"observed normalized fact "+fact.Split(' ')[0]);
foreach(var hook in RoutekeeperHooks.Names)
    Check(Get(hook).Contains(hook == "gml_Object_obj_mainchara_Step_0" ? "obj_routekeeper.rk_menu" : hook == "gml_Script_scr_load" ? "scr_routekeeper_warning_session" : "scr_routekeeper_decision_guard"),"pre-effect hook "+hook);
var guard=Get("gml_Script_scr_routekeeper_decision_guard");
var load=Get("gml_Script_scr_load");
Check(load.IndexOf("scr_routekeeper_warning_session",StringComparison.Ordinal)<load.IndexOf("global.xp =",StringComparison.Ordinal),"reload invalidates warnings before restoring game state");
Check(guard.IndexOf("scr_routekeeper_read_state()",StringComparison.Ordinal)<guard.IndexOf("obj_routekeeper.rk_status == 3",StringComparison.Ordinal),"decision observes current state before blocked-route gate");
Check(Get("gml_Script_scr_routekeeper_greeting_pending_risk").Contains("global.xpreward[3]"),"unbanked battle EXP included in optional LV protection");
var battle=Get("gml_Object_obj_battlecontroller_Step_0");
Check(battle.Contains("scr_routekeeper_decision_act"),"final-Hum guard linked before ACT effects");
Check(battle.Contains("scr_routekeeper_decision_item") && battle.IndexOf("scr_routekeeper_decision_item",StringComparison.Ordinal)<battle.IndexOf("scr_itemuseb",StringComparison.Ordinal),"item escape guard precedes consumption");
Check(guard.Contains("obj_routekeeper.rk_status == 3"),"blocked targets cannot trap mandatory battles");
Check(guard.Contains("scr_routekeeper_warning_session") && Get("gml_Script_scr_routekeeper_warning_session").Contains("global.rk_warning_enforced"),"shared Forced and dismissible warning policies");
var session=Get("gml_Script_scr_routekeeper_warning_session");
Check(session.Contains("global.rk_warning_mode") && session.Contains("global.rk_decision_context"),"acknowledgements bound to exact proposal and mode");
Check(state.IndexOf("return 0;",StringComparison.Ordinal)<state.IndexOf("global.flag[",StringComparison.Ordinal),"unready branch exits before game-state reads");
var overworld=Get("gml_Object_obj_overworldcontroller_Draw_0");
Check(overworld.Contains("scr_routekeeper_decision_guard(9") && overworld.Contains("scr_routekeeper_decision_guard(10"),"pre-SAVE and pre-discard hooks");
Check(step.Contains("target_greeting") && Get("gml_Object_obj_routekeeper_Create_0").Contains("target_greeting"),"persistent call-condition selection");
// Compare emitted classifiers to the actual unchanged item-effect switch, not a
// second manually maintained ID list. Pinning is enforced by bindings.csx.
var itemUse=Get("gml_Script_scr_itemuseb");
var cases=System.Text.RegularExpressions.Regex.Matches(itemUse,@"(?m)^    case (\d+):").Cast<System.Text.RegularExpressions.Match>().ToArray();
int[] EffectIds(string marker) => cases.Select((m,i)=>new{Id=int.Parse(m.Groups[1].Value),Body=itemUse.Substring(m.Index,(i+1<cases.Length?cases[i+1].Index:itemUse.Length)-m.Index)}).Where(c=>c.Body.Contains(marker)).Select(c=>c.Id).OrderBy(i=>i).ToArray();
int[] EmittedIds(string name) => System.Text.RegularExpressions.Regex.Matches(File.ReadAllText(Path.Combine(folder,"gml",name+".gml")),@"argument0 == (\d+)").Cast<System.Text.RegularExpressions.Match>().Select(m=>int.Parse(m.Groups[1].Value)).OrderBy(i=>i).ToArray();
Check(EffectIds("scr_recoitem").SequenceEqual(EmittedIds("greeting_healing")),"all healing-item cases match authentic effects");
Check(EffectIds("scr_armoreq").SequenceEqual(EmittedIds("greeting_armor")),"all armor-item cases match authentic effects");
var automatic=Get("gml_Object_obj_mettatonex_Step_0");
Check(automatic.Contains("scr_routekeeper_decision_guard(12") && automatic.IndexOf("scr_routekeeper_decision_guard(12",StringComparison.Ordinal)<automatic.IndexOf("con = 90;",StringComparison.Ordinal),"rating outcome hook precedes scripted finale");
Check(automatic.Contains("global.ratings >= 10000") && automatic.Contains("global.ratings >= 12000"),"original rating thresholds retained");
Check(step.Contains("global.rk_warning_code == 20"),"scripted turn-boundary warning not cleared as an ordinary battle warning");
var draw=Get("gml_Object_obj_routekeeper_Draw_64");
Check(draw.Contains("scr_routekeeper_ui_option") && draw.Contains("global.rk_progress_met"),"localized objectives/progress GUI");
foreach(var restored in new[]{"draw_set_font(old_font)","draw_set_color(old_color)","draw_set_alpha(old_alpha)","draw_set_halign(old_halign)","draw_set_valign(old_valign)"})
    Check(draw.Contains(restored),"draw state restored "+restored.Split('(')[0]);
var font=Data.Fonts.ByName("fnt_routekeeper");
Check(font?.Texture!=null,"embedded font atlas");
var glyphs=font.Glyphs.Select(g=>(char)g.Character).ToHashSet();
var required=string.Concat(Directory.GetFiles(Path.Combine(folder,"gml"),"*.gml").Select(File.ReadAllText))
    .Where(c=>c>126 && !char.IsControl(c)).Distinct().ToArray();
Check(required.All(glyphs.Contains),"all "+required.Length+" non-ASCII source characters have glyphs");
Check(Data.Code.Count==6272+scripts.Length+3,"expected new code footprint");
var originalPath=Environment.GetEnvironmentVariable("ROUTEKEEPER_ORIGINAL");
if(!string.IsNullOrEmpty(originalPath)) {
    using(var source=File.OpenRead(originalPath)) {
        var pristine=UndertaleIO.Read(source);
        RoutekeeperBindings.Validate(pristine,folder,originalPath);
        Check(Data.Rooms.Count==pristine.Rooms.Count && Data.Sprites.Count==pristine.Sprites.Count && Data.Sounds.Count==pristine.Sounds.Count,"original room/sprite/sound resource counts");
        Check(Data.GameObjects.Count==pristine.GameObjects.Count+1 && Data.Fonts.Count==pristine.Fonts.Count+1
            && Data.EmbeddedTextures.Count==pristine.EmbeddedTextures.Count+1 && Data.TexturePageItems.Count==pristine.TexturePageItems.Count+1,"additive controller/font footprint");
        for(int index=0;index<pristine.EmbeddedTextures.Count;index++) {
            var oldImage=pristine.EmbeddedTextures[index].TextureData.Image;
            var newImage=Data.EmbeddedTextures[index].TextureData.Image;
            if(oldImage.Width!=newImage.Width || oldImage.Height!=newImage.Height
                || !SHA256.HashData(oldImage.ToSpan()).SequenceEqual(SHA256.HashData(newImage.ToSpan())))
                throw new Exception("Original texture changed at index "+index);
        }
        Check(true,"all original texture payloads unchanged");
        Check(pristine.EmbeddedAudio.Count==Data.EmbeddedAudio.Count && pristine.EmbeddedAudio.Select((audio,index)=>
            audio.Data.SequenceEqual(Data.EmbeddedAudio[index].Data)).All(equal=>equal),"all original embedded audio unchanged");
        for(int index=0;index<pristine.Fonts.Count;index++) {
            var before=pristine.Fonts[index]; var after=Data.Fonts[index];
            if(before.Name.Content!=after.Name.Content || before.EmSize!=after.EmSize || before.Glyphs.Count!=after.Glyphs.Count)
                throw new Exception("Original font changed at index "+index);
            for(int glyph=0;glyph<before.Glyphs.Count;glyph++) {
                var a=before.Glyphs[glyph]; var b=after.Glyphs[glyph];
                if(a.Character!=b.Character || a.SourceX!=b.SourceX || a.SourceY!=b.SourceY || a.SourceWidth!=b.SourceWidth
                    || a.SourceHeight!=b.SourceHeight || a.Shift!=b.Shift || a.Offset!=b.Offset)
                    throw new Exception("Original font glyph changed.");
            }
        }
        Check(true,"all original font glyphs unchanged");
        var allowed=RoutekeeperHooks.Names.Concat(new[]{"gml_Object_obj_time_Create_0"}).ToHashSet();
        int unchanged=0,changed=0;
        foreach(var before in pristine.Code) {
            var after=Data.Code.ByName(before.Name.Content);
            bool identical=after!=null && before.Disassemble(pristine.Variables,pristine.CodeLocals.For(before))
                ==after.Disassemble(Data.Variables,Data.CodeLocals.For(after));
            if(allowed.Contains(before.Name.Content)) { Check(!identical,"intended hook changed "+before.Name.Content); changed++; }
            else { if(!identical) throw new Exception("Unexpected original code modification: "+before.Name.Content); unchanged++; }
        }
        Check(unchanged==6272-allowed.Count && changed==allowed.Count,"all "+unchanged+" non-hook originals retain identical disassembly");
    }
}
Console.WriteLine("PASS: authentic compile/serialize/reload/source-contract verification; gameplay NOT_RUN.");
