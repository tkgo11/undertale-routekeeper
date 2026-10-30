namespace RouteKeeper.Core;

/// <summary>Availability follows Snowman Alarm0/SCR_TEXT226..227, not wiki assumptions.</summary>
public static class KeepsakeGuidance
{
    public static bool CanAcquire(int stage,int normalState,int taken,int barrier,bool carried=false,bool stored=false) => stage>=2? taken<3 : barrier==0 && (normalState==0 || normalState==1&&!carried&&!stored);
    public static string PlanId(GameState state)
    {
        int kind=state["snowman_piece_stored"]==1?(state["inventory_space"]==0?1:2):state["snowman_piece_available"]==1?(state["inventory_space"]==0?1:3):state["keepsake_recoverable"]==0?4:0;
        var text=kind switch {
            1=>"guidance.make_room_in_your_inventory_for_the_keepsake",
            2=>"guidance.retrieve_the_snowy_keepsake_from_a_storage_box",
            3=>"guidance.return_to_the_snow_figure_in_the_forest_and",
            4=>"guidance.no_carried_stored_or_obtainable_keepsake_remains_in_this",
            _=>"guidance.carry_a_snowy_keepsake_in_your_inventory_for_the"};
        return text;
    }
    public static string Plan(GameState state,Language language)=>TextCatalog.Get(PlanId(state),language);
    public static string EmitGml()
    {
        var s=new System.Text.StringBuilder("// Generated source-backed keepsake acquisition/retrieval objectives.\nif (global.rk_target_greeting == 4 && global.rk_snowman_piece_carried == 0 && gg_blocked == 0) {\n");
        foreach(int kind in new[]{3,2,1}) {
            var facts=new Dictionary<string,int?> { ["snowman_piece_available"]=kind==3?1:0,["snowman_piece_stored"]=kind==2?1:0,["inventory_space"]=kind==1?0:1 };
            string condition=kind==1?"(global.rk_snowman_piece_stored == 1 || global.rk_snowman_piece_available == 1) && global.rk_inventory_space == 0":kind==2?"global.rk_snowman_piece_stored == 1":"global.rk_snowman_piece_available == 1";
            if(kind==1)facts["snowman_piece_stored"]=1;
            s.Append($"if ({condition}) {{ global.rk_greeting_text = {TextCatalog.Gml(PlanId(new(facts)))}; }}\n");
        }
        return s.Append("}\n").ToString();
    }
}
