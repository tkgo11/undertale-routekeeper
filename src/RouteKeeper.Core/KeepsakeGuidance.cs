namespace RouteKeeper.Core;

/// <summary>Availability follows Snowman Alarm0/SCR_TEXT226..227, not wiki assumptions.</summary>
public static class KeepsakeGuidance
{
    public static bool CanAcquire(int stage,int normalState,int taken,int barrier,bool carried=false,bool stored=false) => stage>=2? taken<3 : barrier==0 && (normalState==0 || normalState==1&&!carried&&!stored);
    public static string Plan(GameState state,Language language)
    {
        int kind=state["snowman_piece_stored"]==1?(state["inventory_space"]==0?1:2):state["snowman_piece_available"]==1?(state["inventory_space"]==0?1:3):state["keepsake_recoverable"]==0?4:0;
        var text=kind switch {
            1=>("Make room in your inventory for the keepsake.","기념품을 넣을 가방 공간을 비우세요."),
            2=>("Retrieve the snowy keepsake from a storage box.","보관함에서 눈으로 된 기념품을 꺼내세요."),
            3=>("Return to the snow figure in the forest and ask for a piece.","숲의 눈으로 된 친구에게 돌아가 조각을 부탁하세요."),
            4=>("No carried, stored or obtainable keepsake remains in this run.","이번 회차에 소지·보관·획득 가능한 기념품이 남아 있지 않습니다."),
            _=>("Carry a snowy keepsake in your inventory for the call.","통화할 때 눈으로 된 기념품을 소지하세요.")};
        return language==Language.Korean?text.Item2:text.Item1;
    }
    public static string EmitGml()
    {
        var s=new System.Text.StringBuilder("// Generated source-backed keepsake acquisition/retrieval objectives.\nif (global.rk_target_greeting == 4 && global.rk_snowman_piece_carried == 0 && gg_blocked == 0) {\n");
        foreach(int kind in new[]{3,2,1}) {
            var facts=new Dictionary<string,int?> { ["snowman_piece_available"]=kind==3?1:0,["snowman_piece_stored"]=kind==2?1:0,["inventory_space"]=kind==1?0:1 };
            string condition=kind==1?"(global.rk_snowman_piece_stored == 1 || global.rk_snowman_piece_available == 1) && global.rk_inventory_space == 0":kind==2?"global.rk_snowman_piece_stored == 1":"global.rk_snowman_piece_available == 1";
            if(kind==1)facts["snowman_piece_stored"]=1;
            s.Append($"if ({condition}) {{ global.rk_greeting_text = {GmlRuleEmitter.Quote(Plan(new(facts),Language.English))}; if (global.rk_language == 1) global.rk_greeting_text = {GmlRuleEmitter.Quote(Plan(new(facts),Language.Korean))}; }}\n");
        }
        return s.Append("}\n").ToString();
    }
}
