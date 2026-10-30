#load "hooks.csx"
#load "bindings.csx"
// Structural integration verification. Never writes data or claims runner compatibility.
using System;
using System.IO;
using System.Linq;
using UndertaleModLib;
using System.Security.Cryptography;
using System.Text.Json;
using UndertaleModLib.Models;
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
var fontManifest=JsonDocument.Parse(File.ReadAllText(Path.Combine(folder,"assets","fonts","manifest.json")));
int addedFonts=fontManifest.RootElement.GetArrayLength();
foreach(var entry in fontManifest.RootElement.EnumerateArray()) {
    var font=Data.Fonts.ByName(entry.GetProperty("resource").GetString());
    Check(font?.Texture!=null,"registered embedded font atlas");
    var expectedGlyphs=File.ReadAllLines(Path.Combine(folder,"assets",entry.GetProperty("glyphs").GetString())).Select(l=>l.Split('\t').Select(int.Parse).ToArray()).ToArray();
    Check(font.Glyphs.Count==expectedGlyphs.Length,"registered glyph count");
    for(int i=0;i<expectedGlyphs.Length;i++) {
        var g=font.Glyphs[i];var e=expectedGlyphs[i];
        Check(g.Character==e[0] && g.SourceX==e[1] && g.SourceY==e[2] && g.Shift==e[3] && g.Offset==e[4] && g.SourceWidth==24 && g.SourceHeight==18,"registered glyph metrics");
    }
}
Check(Data.Code.Count==6272+scripts.Length+3,"expected new code footprint");
var originalPath=Environment.GetEnvironmentVariable("ROUTEKEEPER_ORIGINAL");
if(!string.IsNullOrEmpty(originalPath)) {
    using(var source=File.OpenRead(originalPath)) {
        var pristine=UndertaleIO.Read(source);
        RoutekeeperBindings.Validate(pristine,folder,originalPath);
        Check(Data.Rooms.Count==pristine.Rooms.Count && Data.Sprites.Count==pristine.Sprites.Count && Data.Sounds.Count==pristine.Sounds.Count,"original room/sprite/sound resource counts");
        Check(Data.GameObjects.Count==pristine.GameObjects.Count+1 && Data.Fonts.Count==pristine.Fonts.Count+addedFonts
            && Data.EmbeddedTextures.Count==pristine.EmbeddedTextures.Count+addedFonts && Data.TexturePageItems.Count==pristine.TexturePageItems.Count+addedFonts,"additive controller/font footprint");
        // Payload equality alone misses muted sounds, shifted texture rectangles,
        // font sampling changes and collision geometry. Compare the serialized
        // legacy fields explicitly; never reflect over arbitrary model getters.
        string ObjectMetadata(UndertaleGameObject o,UndertaleData owner) => JsonSerializer.Serialize(new {
            Name=o.Name?.Content,Sprite=owner.Sprites.IndexOf(o.Sprite),o.Visible,o.Managed,o.Solid,o.Depth,o.Persistent,
            Parent=owner.GameObjects.IndexOf(o.ParentId),Mask=owner.Sprites.IndexOf(o.TextureMaskId),
            o.UsesPhysics,o.IsSensor,o.CollisionShape,o.Density,o.Restitution,o.Group,o.LinearDamping,o.AngularDamping,
            o.Friction,o.Awake,o.Kinematic,Vertices=o.PhysicsVertices.Select(v=>new{v.X,v.Y}).ToArray(),
            Events=o.Events.Select(group=>group.Select(e=>new{e.EventSubtype,Actions=e.Actions.Select(a=>new{
                a.LibID,a.ID,a.Kind,a.UseRelative,a.IsQuestion,a.UseApplyTo,a.ExeType,Name=a.ActionName?.Content,
                Code=owner.Code.IndexOf(a.CodeId),a.ArgumentCount,a.Who,a.Relative,a.IsNot,a.UnknownAlwaysZero}).ToArray()}).ToArray()).ToArray() });
        for(int index=0;index<pristine.GameObjects.Count;index++) {
            if(ObjectMetadata(pristine.GameObjects[index],pristine)!=ObjectMetadata(Data.GameObjects[index],Data))
                throw new Exception("original object metadata or event linkage changed at index "+index);
        }
        Check(true,"all original object metadata/event linkage unchanged");
        string RoomMetadata(UndertaleRoom r,UndertaleData owner) => JsonSerializer.Serialize(new {
            Name=r.Name?.Content,Caption=r.Caption?.Content,r.Width,r.Height,r.Speed,r.Persistent,r.BackgroundColor,r.DrawBackgroundColor,
            Code=owner.Code.IndexOf(r.CreationCodeId),r.Flags,r.World,r.Top,r.Left,r.Right,r.Bottom,r.GravityX,r.GravityY,r.MetersPerPixel,
            Backgrounds=r.Backgrounds.Select(b=>new{b.Enabled,b.Foreground,Definition=owner.Backgrounds.IndexOf(b.BackgroundDefinition),
                b.X,b.Y,b.SpeedX,b.SpeedY,b.Stretch,b.TiledHorizontally,b.TiledVertically}).ToArray(),
            Views=r.Views.Select(v=>new{v.Enabled,v.ViewX,v.ViewY,v.ViewWidth,v.ViewHeight,v.PortX,v.PortY,v.PortWidth,v.PortHeight,
                v.BorderX,v.BorderY,v.SpeedX,v.SpeedY,Object=owner.GameObjects.IndexOf(v.ObjectId)}).ToArray(),
            Instances=r.GameObjects.Select(i=>new{i.X,i.Y,Object=owner.GameObjects.IndexOf(i.ObjectDefinition),i.InstanceID,
                Code=owner.Code.IndexOf(i.CreationCode),i.ScaleX,i.ScaleY,i.Color,i.Rotation,PreCode=owner.Code.IndexOf(i.PreCreateCode)}).ToArray(),
            Tiles=r.Tiles.Select(t=>new{t.X,t.Y,Background=owner.Backgrounds.IndexOf(t.BackgroundDefinition),
                t.SourceX,t.SourceY,t.Width,t.Height,t.TileDepth,t.InstanceID,t.ScaleX,t.ScaleY,t.Color}).ToArray() });
        for(int index=0;index<pristine.Rooms.Count;index++) {
            if(RoomMetadata(pristine.Rooms[index],pristine)!=RoomMetadata(Data.Rooms[index],Data))
                throw new Exception("original room metadata or instance linkage changed at index "+index);
        }
        Check(true,"all original legacy room/view/background/instance/tile metadata unchanged");
        string SoundMetadata(UndertaleSound s) => JsonSerializer.Serialize(new {
            Name=s.Name?.Content,Type=s.Type?.Content,File=s.File?.Content,s.Flags,s.Effects,s.Volume,s.Pitch,s.Preload,s.AudioID,s.GroupID });
        for(int index=0;index<pristine.Sounds.Count;index++)
            Check(SoundMetadata(pristine.Sounds[index])==SoundMetadata(Data.Sounds[index]),"original sound metadata "+index);
        string TextureMetadata(UndertaleTexturePageItem t,UndertaleData owner) => JsonSerializer.Serialize(new {
            t.SourceX,t.SourceY,t.SourceWidth,t.SourceHeight,t.TargetX,t.TargetY,t.TargetWidth,t.TargetHeight,
            t.BoundingWidth,t.BoundingHeight,Page=owner.EmbeddedTextures.IndexOf(t.TexturePage) });
        for(int index=0;index<pristine.TexturePageItems.Count;index++) {
            if(TextureMetadata(pristine.TexturePageItems[index],pristine)!=TextureMetadata(Data.TexturePageItems[index],Data))
                throw new Exception("original texture-page metadata changed at index "+index);
        }
        Check(true,"all original texture-page metadata unchanged");
        string SpriteMetadata(UndertaleSprite s,UndertaleData owner) => JsonSerializer.Serialize(new {
            Name=s.Name?.Content,s.Width,s.Height,s.MarginLeft,s.MarginRight,s.MarginTop,s.MarginBottom,
            s.Transparent,s.Smooth,s.Preload,s.BBoxMode,s.SepMasks,s.OriginX,s.OriginY,s.IsSpecialType,
            Textures=s.Textures.Select(t=>owner.TexturePageItems.IndexOf(t.Texture)).ToArray() });
        for(int index=0;index<pristine.Sprites.Count;index++) {
            var a=pristine.Sprites[index];var b=Data.Sprites[index];
            if(SpriteMetadata(a,pristine)!=SpriteMetadata(b,Data)||a.CollisionMasks.Count!=b.CollisionMasks.Count ||
                a.CollisionMasks.Where((mask,i)=>!mask.Data.SequenceEqual(b.CollisionMasks[i].Data)).Any())
                throw new Exception("original sprite metadata or collision mask changed at index "+index);
        }
        Check(true,"all original sprite metadata and collision masks unchanged");
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
            string FontMetadata(UndertaleFont f,UndertaleData owner) => JsonSerializer.Serialize(new {
                Name=f.Name?.Content,Display=f.DisplayName?.Content,f.EmSizeIsFloat,f.EmSize,f.Bold,f.Italic,
                f.RangeStart,f.RangeEnd,f.Charset,f.AntiAliasing,f.ScaleX,f.ScaleY,Texture=owner.TexturePageItems.IndexOf(f.Texture) });
            if(FontMetadata(before,pristine)!=FontMetadata(after,Data))
                throw new Exception("original font metadata changed at index "+index);
            if(before.Name.Content!=after.Name.Content || before.EmSize!=after.EmSize || before.Glyphs.Count!=after.Glyphs.Count)
                throw new Exception("Original font changed at index "+index);
            for(int glyph=0;glyph<before.Glyphs.Count;glyph++) {
                var a=before.Glyphs[glyph]; var b=after.Glyphs[glyph];
                if(a.Character!=b.Character || a.SourceX!=b.SourceX || a.SourceY!=b.SourceY || a.SourceWidth!=b.SourceWidth
                    || a.SourceHeight!=b.SourceHeight || a.Shift!=b.Shift || a.Offset!=b.Offset
                    || !a.Kerning.Select(k=>(k.Character,k.ShiftModifier)).SequenceEqual(b.Kerning.Select(k=>(k.Character,k.ShiftModifier))))
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
