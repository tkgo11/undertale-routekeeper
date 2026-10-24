// Source-verified object categories for pre-action decisions. No vanilla state writes.
// 0 ordinary,1 Toriel,2 Papyrus,3 Undyne,4 Mettaton EX,5 Undying,
// 6 required unique encounter,7 NEO,8 Monster Kid.
var target;
target = argument0;
if (!instance_exists(target)) return 0;
if (target.object_index == obj_torielboss) return 1;
if (target.object_index == obj_papyrusboss) return 2;
if (target.object_index == obj_undyneboss) return 3;
if (target.object_index == obj_mettatonex) return 4;
if (target.object_index == obj_undyne_ex) return 5;
if (target.object_index == obj_mettaton_neo) return 7;
if (target.object_index == obj_mkid_battle) return 8;
if (target.object_index == obj_snowdrake) return 9;
if (target.object_index == obj_movedoge || target.object_index == obj_mandog
    || target.object_index == obj_womandog || target.object_index == obj_greatdog
    || target.object_index == obj_lesserdoge
    || target.object_index == obj_shyren || target.object_index == obj_gladdummy
    || target.object_index == obj_spiderb || target.object_index == obj_bara01
    || target.object_index == obj_bara02) return 6;
return 0;
