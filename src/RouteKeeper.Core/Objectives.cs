namespace RouteKeeper.Core;

public sealed record FactTest(string Fact,Comparison Comparison,int Expected)
{
    public bool Matches(GameState state) => state[Fact] is int value && (Comparison switch
    { Comparison.AtLeast=>value>=Expected,Comparison.AtMost=>value<=Expected,_=>value==Expected });
    public string Gml => $"(global.rk_{Fact} >= 0 && global.rk_{Fact} <= {FactDomains.Maximum(Fact)} && global.rk_{Fact} {GmlRuleEmitter.Operator(Comparison)} {Expected})";
}
public sealed record ObjectiveCondition(params FactTest[] Tests)
{
    public bool Matches(GameState state)=>Tests.All(t=>t.Matches(state));
    public string Gml=>string.Join(" && ",Tests.Select(t=>t.Gml));
}
public sealed record ObjectiveRule(string Id,ObjectiveCondition Condition,string Minimal,string Detailed,string KoreanMinimal,string KoreanDetailed,
    string? CountFact=null,int Quota=0)
{
    public string Template(SpoilerLevel spoilers,Language language)=>(language,spoilers) switch
    {
        (Language.Korean,SpoilerLevel.Detailed)=>KoreanDetailed,(Language.Korean,_)=>KoreanMinimal,
        (_,SpoilerLevel.Detailed)=>Detailed,_=>Minimal
    };
    public string Text(GameState state,SpoilerLevel spoilers,Language language)=>Template(spoilers,language)
        .Replace("{remaining}",Math.Max(0,Quota-(state[CountFact??""]??0)).ToString(System.Globalization.CultureInfo.InvariantCulture),StringComparison.Ordinal);
}
public static class ObjectiveRules
{
    private static FactTest Eq(string f,int v)=>new(f,Comparison.Equal,v);
    private static FactTest Min(string f,int v)=>new(f,Comparison.AtLeast,v);
    private static FactTest Max(string f,int v)=>new(f,Comparison.AtMost,v);
    private static ObjectiveRule O(string id,string en,string detail,string ko,string koDetail,params FactTest[] tests)=>new(id,new(tests),en,detail,ko,koDetail);
    private static readonly ObjectiveRule[] Pacifist=[
        O("water_opportunity_missed","Help the collapsed person before leaving.","Take water from the cooler and give it to Undyne before leaving.","떠나기 전에 쓰러진 상대를 도와주세요.","떠나기 전에 정수기의 물을 언다인에게 주세요.",Eq("water_opportunity_active",1)),
        O("papyrus_friendship","Visit your new friend's home.","Go to Papyrus's house and finish his date or hangout.","새 친구의 집을 방문하세요.","파피루스의 집에서 데이트 또는 어울리기를 마치세요.",Eq("papyrus_friendship",0),Eq("papyrus_hangout_available",1)),
        O("undyne_friendship","Meet your friends at their home.","Meet Papyrus outside Undyne's house and finish her hangout.","친구의 집에서 함께 시간을 보내세요.","언다인의 집 앞에서 파피루스를 만나 어울리기를 마치세요.",Eq("undyne_friendship",0),Eq("papyrus_friendship",1),Eq("undyne_hangout_available",1)),
        O("prior_neutral_completion","Finish the journey, then continue from your SAVE.","Defeat Asgore and Omega Flowey, then reload your SAVE.","여정을 마친 뒤 SAVE에서 계속하세요.","아스고어와 오메가 플라위를 물리친 뒤 SAVE를 불러오세요.",Eq("prior_neutral_completion",0),Eq("mettaton_defeated",1)),
        O("alphys_friendship","Deliver your friend's message.","Get Undyne's letter, deliver it to Alphys, and finish the date.","친구의 편지를 전해 주세요.","언다인의 편지를 알피스에게 전하고 데이트를 마치세요.",Eq("alphys_friendship",0),Eq("prior_neutral_completion",1),Eq("papyrus_friendship",1),Eq("undyne_friendship",1),Eq("alphys_date_available",1)),
        O("true_lab_completed","Explore the path your friends opened.","Enter the bathroom in Alphys's lab and complete the True Lab.","친구들이 열어 준 길을 탐험하세요.","알피스의 연구실 화장실로 들어가 진실의 연구소를 완료하세요.",Eq("alphys_friendship",1),Eq("true_lab_completed",0),Eq("true_lab_available",1)),
        O("ending_complete","Your selected path is complete.","The barrier is open, and your final choice matches your goal.","선택한 경로를 마쳤습니다.","결계가 열렸고 마지막 선택도 목표와 맞습니다.",Eq("barrier_broken",1),Eq("epilogue_resolved",1),Eq("epilogue_matches",1),Eq("papyrus_friendship",1),Eq("undyne_friendship",1),Eq("alphys_friendship",1)),
        O("epilogue","Finish your farewells and choose your future.","Speak with your friends, leave the Underground, then keep your selected Stay/Leave choice.","친구들에게 인사하고 앞날을 선택하세요.","친구들과 이야기한 뒤 지하를 떠나 함께 살기 또는 떠나기 선택을 지키세요.",Eq("barrier_broken",1),Eq("papyrus_friendship",1),Eq("undyne_friendship",1),Eq("alphys_friendship",1)),
        O("barrier","Return to the barrier and help your friends.","Return to the barrier and complete the Asriel encounter without RESET.","결계로 돌아가 친구들을 도와주세요.","결계로 돌아가 리셋하지 않고 아스리엘 조우를 완료하세요.",Eq("true_lab_completed",1),Eq("barrier_broken",0),Eq("papyrus_friendship",1),Eq("undyne_friendship",1),Eq("alphys_friendship",1),Eq("prior_neutral_completion",1)),
        O("travel_ruins","Explore the Ruins without gaining EXP.","Spare Toriel and continue out of the Ruins without gaining EXP.","EXP를 얻지 않고 폐허를 탐험하세요.","토리엘을 살리고 EXP를 얻지 않은 채 폐허를 나가세요.",Eq("area",0)),
        O("travel_snowdin","Continue through the forest and make a friend.","Spare Papyrus, then visit his house for a date or hangout.","숲을 지나며 새 친구를 만드세요.","파피루스를 살린 뒤 집을 방문해 데이트 또는 어울리기를 하세요.",Eq("area",1)),
        O("travel_waterfall","Continue through the caverns and help those in need.","Flee from Undyne to Hotland, then give her water when she collapses.","동굴을 지나며 도움이 필요한 상대를 도와주세요.","언다인에게서 핫랜드까지 도망친 뒤 쓰러진 언다인에게 물을 주세요.",Eq("area",2)),
        O("travel_hotland","Continue toward the castle without gaining EXP.","Spare Mettaton EX and continue toward Asgore without gaining EXP.","EXP를 얻지 않고 성을 향해 계속 가세요.","메타톤 EX를 살리고 EXP를 얻지 않은 채 아스고어에게 가세요.",Min("area",3))
    ];
    private static ObjectiveRule Stage(int stage,string id,string en,string detail,string ko,string koDetail)=>
        O(id,en,detail,ko,koDetail,Eq("genocide_stage",stage));
    private static ObjectiveRule Quota(int stage,string area,int quota,string detail,string koDetail)=>
        new("quota_"+area,new(Eq("genocide_stage",stage),Max("kills_"+area,quota-1)),
            "Defeat {remaining} more enemies before moving on.",detail,"다음으로 가기 전에 적 {remaining}명을 더 처치하세요.",koDetail,"kills_"+area,quota);
    private static readonly ObjectiveRule[] Genocide=[
        Quota(0,"ruins",20,"Defeat {remaining} more enemies in the Ruins before leaving.","폐허를 떠나기 전에 적 {remaining}명을 더 처치하세요."),
        Stage(1,"toriel","Complete the region's final encounter.","Kill Toriel, then enter Snowdin.","지역의 마지막 조우를 완료하세요.","토리엘을 처치한 뒤 스노우딘으로 가세요."),
        Stage(2,"doggo","Complete the next required encounter.","Kill Doggo; do not spare required enemies.","다음 필수 조우를 완료하세요.","도고를 처치하세요. 필수 적을 살려 주지 마세요."),
        Stage(3,"dog_pair","Complete the next required encounter.","Kill Dogamy and Dogaressa.","다음 필수 조우를 완료하세요.","도가미와 도가레사를 처치하세요."),
        Stage(4,"greater_dog","Complete the next required encounter.","Kill Greater Dog; kill Lesser Dog if encountered.","다음 필수 조우를 완료하세요.","그레이터 도그를 처치하세요. 레서 도그와 조우했다면 처치하세요."),
        Stage(5,"snowdrake","Find the missing required enemy before exhausting the area.","Kill Snowdrake before the Snowdin encounter quota is exhausted.","지역의 적이 사라지기 전에 필수 적을 찾으세요.","스노우딘 조우 수가 소진되기 전에 스노우드레이크를 처치하세요."),
        Quota(6,"snowdin",16,"Defeat {remaining} more enemies in Snowdin before Papyrus.","파피루스를 만나기 전에 스노우딘의 적 {remaining}명을 더 처치하세요."),
        Stage(7,"papyrus","Complete the region's final encounter.","Kill Papyrus after completing the Snowdin quota.","지역의 마지막 조우를 완료하세요.","스노우딘의 처치 수를 채운 뒤 파피루스를 처치하세요."),
        Stage(8,"shyren","Complete the next required encounter.","Kill Shyren.","다음 필수 조우를 완료하세요.","샤이렌을 처치하세요."),
        Stage(9,"glad_dummy","Complete the next required encounter.","Kill Glad Dummy.","다음 필수 조우를 완료하세요.","글래드 더미를 처치하세요."),
        Quota(10,"waterfall",18,"Defeat {remaining} more enemies in Waterfall before Undyne.","언다인을 만나기 전에 워터폴의 적 {remaining}명을 더 처치하세요."),
        Stage(11,"undyne","Complete the region's decisive encounter.","Attack Monster Kid, then defeat Undyne the Undying.","지역의 결정적인 조우를 완료하세요.","몬스터 키드를 공격한 뒤 불사의 언다인을 처치하세요."),
        Stage(12,"royal_guards","Complete the next required encounter.","Kill the Royal Guards.","다음 필수 조우를 완료하세요.","왕실 근위병을 처치하세요."),
        Stage(13,"muffet","Complete the next required encounter.","Kill Muffet.","다음 필수 조우를 완료하세요.","머펫을 처치하세요."),
        Quota(14,"hotland_core",40,"Defeat {remaining} more enemies in Hotland/CORE before Mettaton NEO.","메타톤 NEO를 만나기 전에 핫랜드와 코어의 적 {remaining}명을 더 처치하세요."),
        Stage(15,"mettaton_neo","Complete the region's final encounter.","Kill Mettaton NEO after exhausting the Hotland/CORE quota.","지역의 마지막 조우를 완료하세요.","핫랜드와 코어의 처치 수를 채운 뒤 메타톤 NEO를 처치하세요."),
        O("genocide_final","Continue to the final encounter.","Defeat Sans, then continue toward the throne room.","마지막 조우로 가세요.","샌즈를 물리친 뒤 왕좌의 방으로 가세요.",Eq("genocide_stage",16),Eq("sans_defeated",0)),
        O("genocide_throne","Continue to the throne room and choose your future.","Continue through the throne room. Some choices outlast a RESET.","왕좌의 방으로 가서 앞날을 선택하세요.","왕좌의 방을 지나세요. 어떤 선택은 RESET 뒤에도 남습니다.",Eq("genocide_stage",16),Eq("sans_defeated",1))
    ];
    public static IReadOnlyList<ObjectiveRule> For(RouteId route)=>route switch
    {RouteId.TruePacifist or RouteId.SoullessPacifist=>Pacifist,RouteId.Genocide or RouteId.SoullessGenocide=>Genocide,_=>[]};
    public static IEnumerable<string> Facts=>Pacifist.Concat(Genocide).SelectMany(r=>r.Condition.Tests.Select(t=>t.Fact).Concat(r.CountFact is null?[]:new[]{r.CountFact}));
}
