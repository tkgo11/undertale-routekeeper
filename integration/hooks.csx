// Source-validated, version-pinned pre-action hooks. No post-hoc save/state repair.
using System;
using System.Linq;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
using UndertaleModLib;
using UndertaleModLib.Compiler;
using UndertaleModLib.Decompiler;

public static class RoutekeeperHooks
{
    private static readonly Dictionary<string,string> SourceHashes = new() {
        ["gml_Object_obj_battlecontroller_Step_0"] = "684692982516de492c8712401e6940e30a359f8e4ef6c0e62986a03f0d4fd8a2",
        ["gml_Object_obj_doorA_Other_19"] = "1803f17344374bb007ad9defcff78d8a0a61ba32c3795992cbe364c5b74abd0e",
        ["gml_Object_obj_doorAmusicfade_Other_19"] = "0227687fda33f84c614e1b148a66b3e091d07275026322cc2eba079dd21759ec",
        ["gml_Object_obj_doorB_Other_19"] = "1803f17344374bb007ad9defcff78d8a0a61ba32c3795992cbe364c5b74abd0e",
        ["gml_Object_obj_doorBmusicfade_Other_19"] = "a7eb1df34d7fb0c128b13faa788fb88e9c8c5ca1cf5b8643dc65f1654d65b7d5",
        ["gml_Object_obj_doorC_Other_19"] = "1803f17344374bb007ad9defcff78d8a0a61ba32c3795992cbe364c5b74abd0e",
        ["gml_Object_obj_doorCmusicfade_Other_19"] = "8d6b1cad6c28c75ee4e51c64d08ea948a1945fb93dfffb8322b6eda355602789",
        ["gml_Object_obj_doorD_Other_19"] = "1803f17344374bb007ad9defcff78d8a0a61ba32c3795992cbe364c5b74abd0e",
        ["gml_Object_obj_doorDmusicfade_Other_19"] = "8d6b1cad6c28c75ee4e51c64d08ea948a1945fb93dfffb8322b6eda355602789",
        ["gml_Object_obj_doorXmusicfade_Other_19"] = "c2d9a09efe5a0d2e87d9f6aaa270efd4e0cff67797c481a68299ef0d8a80895e",
        ["gml_Object_obj_door_ruins13_Other_19"] = "ab4558a43c1d4795c3967541da021079b766fc0b6dc6b68ae670c85f19eff771",
        ["gml_Object_obj_door_s_musfade_Other_19"] = "cd5ba45565fa08d0af165ff59bc8aeb5df0dfe77a28eab879b0ac2d2378fc64c",
        ["gml_Object_obj_door_t_Other_19"] = "376f719383838334d52661e0d949f25270a28976703f6d0535e6fc67985108a4",
        ["gml_Object_obj_door_u_Other_19"] = "7d90f6f9aae8083fa50c7685c36ca27d7563da4a10cdee34fa146ffaa2ae1b1a",
        ["gml_Object_obj_door_v_Other_19"] = "5629866033d0a85571da580e7768fd782456a95b46da3ff7930efa4a1e334796",
        ["gml_Object_obj_door_w_Other_19"] = "cd5ba45565fa08d0af165ff59bc8aeb5df0dfe77a28eab879b0ac2d2378fc64c",
        ["gml_Object_obj_papyrus8_Collision_1576"] = "08f0dffa94b3987c3328a0b9e52e19de2f7ae5e0c260822d013bbcff698bd369",
        ["gml_Object_obj_monsterkidtrigger7_Collision_1576"] = "9e43b28d66eec560676ac037e1a57e18cc4b8296a987ddad7517ccc884e58621",
        ["gml_Object_obj_mettboss_event_Step_0"] = "2adc8e13d6be93886393edbd253878f82cbfeb6d203368e9462649bfdefbb3bb",
        ["gml_Object_obj_choicer_Other_10"] = "5878cfb67a73beedc161724d517bd8ac098ea4e1ca3d151007ebe2ff540389d0",
        ["gml_Object_obj_torieltrigger12_Collision_1576"] = "2938ded5b0d2ff3a253630589cf063289d8c7dd10d4a1dd454a449276ab4ea68",
    };
    public static IReadOnlyCollection<string> Names => SourceHashes.Keys;
    public static IReadOnlyList<string> Apply(UndertaleData data, CodeImportGroup import)
    {
        var context = new GlobalDecompileContext(data);
        string Source(string name) {
            var code = data.Code.ByName(name) ?? throw new InvalidOperationException("Missing decision hook: " + name);
            var source = new Underanalyzer.Decompiler.DecompileContext(context,code,data.ToolInfo.DecompilerSettings)
                .DecompileToString().Replace("\r\n","\n");
            var hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(source))).ToLowerInvariant();
            if (hash != SourceHashes[name]) throw new InvalidOperationException("Decision hook signature mismatch: " + name);
            return source;
        }
        string ReplaceOne(string source,string before,string after) {
            int index=source.IndexOf(before,StringComparison.Ordinal);
            if(index<0 || source.IndexOf(before,index+before.Length,StringComparison.Ordinal)>=0)
                throw new InvalidOperationException("Decision anchor must occur exactly once.");
            return source.Substring(0,index)+after+source.Substring(index+before.Length);
        }
        var changed = new List<string>();
        const string battle = "gml_Object_obj_battlecontroller_Step_0";
        string modified=Source(battle);
        string fight="if (global.bmenuno == 1)\n                {\n                    global.mytarget = global.bmenucoord[1];";
        modified=ReplaceOne(modified,fight,
            "if (global.bmenuno == 1)\n                {\n                    if (scr_routekeeper_decision_guard(1, global.bmenucoord[1])) { control_clear(0); exit; }\n                    global.mytarget = global.bmenucoord[1];");
        string mercy="if (global.bmenuno == 4)\n                {\n                    OBJ_WRITER.halt = 3;";
        modified=ReplaceOne(modified,mercy,
            "if (global.bmenuno == 4)\n                {\n                    if (global.bmenucoord[4] == 0 && scr_routekeeper_decision_guard(2, -1)) { control_clear(0); exit; }\n                    if (global.bmenucoord[4] == 1 && scr_routekeeper_decision_guard(3, -1)) { control_clear(0); exit; }\n                    OBJ_WRITER.halt = 3;");
        import.QueueReplace(battle,modified);
        changed.Add(battle);
        var encounterPrefixes = new Dictionary<string,string> {
            ["gml_Object_obj_torieltrigger12_Collision_1576"] = "if (global.flag[45] < 4 && conversation == 0 && scr_routekeeper_decision_guard(5, 1)) { other.x = other.xprevious; other.y = other.yprevious; exit; }",
            ["gml_Object_obj_choicer_Other_10"] = "if (canchoose == 1 && choiced == 0 && global.msc == 820 && instance_exists(obj_outsideworld_event) && scr_routekeeper_decision_guard(6, mychoice)) { control_clear(0); exit; }",
            ["gml_Object_obj_papyrus8_Collision_1576"] = "if (conversation == 0 && scr_routekeeper_decision_guard(5, 2)) { other.x = other.xprevious; other.y = other.yprevious; exit; }",
            ["gml_Object_obj_monsterkidtrigger7_Collision_1576"] = "if (touched == 0 && global.interact == 0 && scr_routekeeper_decision_guard(5, 8)) { other.x = other.xprevious; other.y = other.yprevious; exit; }",
            ["gml_Object_obj_mettboss_event_Step_0"] = "if (con == 0 && obj_mainchara.y < 840 && global.interact == 0 && scr_routekeeper_decision_guard(5, 7)) { obj_mainchara.y = max(840, obj_mainchara.yprevious); exit; }",
        };
        foreach (var pair in encounterPrefixes) {
            import.QueueReplace(pair.Key,pair.Value+"\n"+Source(pair.Key));
            changed.Add(pair.Key);
        }
        foreach(string name in SourceHashes.Keys.Where(n=>n!=battle && !encounterPrefixes.ContainsKey(n))) {
            string source=Source(name);
            // Door collision dispatch is before interaction lock, fader and alarm mutation.
            import.QueueReplace(name,"if (scr_routekeeper_decision_guard(4, id)) exit;\n"+source);
            changed.Add(name);
        }
        return changed;
    }
}
