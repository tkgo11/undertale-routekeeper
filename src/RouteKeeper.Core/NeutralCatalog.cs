using System.Text;

namespace RouteKeeper.Core;

public enum NeutralEnding
{
    Any = 0, Family = 1, BetrayedUnbefriendedMettatonAlive = 2,
    BetrayedUnbefriendedMettatonDead = 3, BetrayedBefriendedMettatonAlive = 4,
    BetrayedBefriendedMettatonDead = 5, ExiledUndyneAlivePapyrusAlive = 6,
    ExiledUndyneAlivePapyrusDead = 7, ExiledUndyneDeadPapyrusAlive = 8,
    ExiledUndyneDeadPapyrusDead = 9, UndynePapyrusAlive = 10,
    UndynePapyrusDead = 11, MettatonPapyrusAlive = 12,
    MettatonPapyrusDead = 13, Papyrus = 14, Dog = 15,
    LeaderlessLowKills = 16, LeaderlessHighKills = 17, Alphys = 18,
    Impossible = 20
}

/// <summary>Facts extracted from the original neutral-call selection/event code.
/// Classify predicts the call if Neutral is reached; it does not claim it was reached.</summary>
public sealed record NeutralOutcome(NeutralEnding Ending, int OriginalBranch, IReadOnlyList<string> Modifiers)
{
    public int ModifierMask => Modifiers.Aggregate(0,(mask,id)=>mask | NeutralCatalog.ModifierRules.Single(m=>m.Id==id).Bit);
}
public sealed record NeutralModifier(string Id,int Bit,ObjectiveCondition Condition);
public sealed record NeutralTarget(NeutralEnding Id, string English, string Korean, int? TorielDead,
    int? PapyrusDead, int? UndyneDead, int? MettatonDead, int MinimumKills, int MaximumKills);

public static class NeutralCatalog
{
    public const int SelectableCount = 19;
    private const int Unlimited = int.MaxValue;
    public static IReadOnlyList<NeutralTarget> Targets { get; } = new NeutralTarget[]
    {
        new(NeutralEnding.Any,"Any Neutral type","유형 무관",null,null,null,null,0,Unlimited),
        new(NeutralEnding.Family,"Family","가족",0,0,0,0,0,0),
        new(NeutralEnding.BetrayedUnbefriendedMettatonAlive,"Betrayed: no friendship, robot spared","배신: 우정 없음, 로봇 생존",0,0,0,0,0,9),
        new(NeutralEnding.BetrayedUnbefriendedMettatonDead,"Betrayed: no friendship, robot killed","배신: 우정 없음, 로봇 사망",0,0,0,1,1,9),
        new(NeutralEnding.BetrayedBefriendedMettatonAlive,"Betrayed: friendship, robot spared","배신: 우정 후, 로봇 생존",0,0,0,0,1,9),
        new(NeutralEnding.BetrayedBefriendedMettatonDead,"Betrayed: friendship, robot killed","배신: 우정 후, 로봇 사망",0,0,0,1,1,9),
        new(NeutralEnding.ExiledUndyneAlivePapyrusAlive,"Exiled: warrior and skeleton alive","추방: 전사와 해골 생존",0,0,0,null,10,Unlimited),
        new(NeutralEnding.ExiledUndyneAlivePapyrusDead,"Exiled: warrior alive, skeleton dead","추방: 전사 생존, 해골 사망",0,1,0,null,1,Unlimited),
        new(NeutralEnding.ExiledUndyneDeadPapyrusAlive,"Exiled: warrior dead, skeleton alive","추방: 전사 사망, 해골 생존",0,0,1,null,1,Unlimited),
        new(NeutralEnding.ExiledUndyneDeadPapyrusDead,"Exiled: warrior and skeleton dead","추방: 전사와 해골 사망",0,1,1,null,2,Unlimited),
        new(NeutralEnding.UndynePapyrusAlive,"Undyne: Papyrus alive","언다인: 파피루스 생존",1,0,0,null,1,Unlimited),
        new(NeutralEnding.UndynePapyrusDead,"Undyne: Papyrus dead","언다인: 파피루스 사망",1,1,0,null,2,Unlimited),
        new(NeutralEnding.MettatonPapyrusAlive,"Mettaton: Papyrus alive","메타톤: 파피루스 생존",1,0,1,0,2,Unlimited),
        new(NeutralEnding.MettatonPapyrusDead,"Mettaton: Papyrus dead","메타톤: 파피루스 사망",1,1,1,0,3,Unlimited),
        new(NeutralEnding.Papyrus,"Papyrus","파피루스",1,0,1,1,3,Unlimited),
        new(NeutralEnding.Dog,"Dog: only four bosses killed","개: 보스 네 명만 처치",1,1,1,1,4,4),
        new(NeutralEnding.LeaderlessLowKills,"Leaderless: total below 20","지도자 없음: 총 20킬 미만",1,1,1,1,5,19),
        new(NeutralEnding.LeaderlessHighKills,"Leaderless: total 20+","지도자 없음: 총 20킬 이상",1,1,1,1,20,Unlimited),
        new(NeutralEnding.Alphys,"Alphys: aborted late Genocide","알피스: 후반 몰살 중단",1,1,1,1,4,Unlimited)
    }.AsReadOnly();
    private static FactTest Eq(string fact,int value)=>new(fact,Comparison.Equal,value);
    private static FactTest Min(string fact,int value)=>new(fact,Comparison.AtLeast,value);
    private static FactTest Max(string fact,int value)=>new(fact,Comparison.AtMost,value);
    private static ObjectiveCondition Greeting(params FactTest[] rest)=>new(new[]{Eq("neutral_papyrus_dead",0)}.Concat(rest).ToArray());
    public static IReadOnlyList<NeutralModifier> ModifierRules { get; }=new NeutralModifier[] {
        new("alphys_call",1,new(Eq("neutral_projection",1),Min("neutral_alphys_friendship",10))),
        new("mettaton_alive",2,new(Min("neutral_projection",6),Max("neutral_projection",7),Eq("neutral_mettaton_dead",0))),
        new("mettaton_dead",4,new(Min("neutral_projection",6),Max("neutral_projection",7),Eq("neutral_mettaton_dead",1))),
        new("snowman_piece",8,Greeting(Eq("snowman_piece_carried",1))),
        new("no_save",16,Greeting(Eq("save_exists",0))),
        new("bandage",32,Greeting(Eq("equipped_armor",4))),
        new("no_healing_items",64,Greeting(Eq("healing_items_used",0))),
        new("low_level_no_healing_bandage",128,Greeting(Eq("healing_items_used",0),Eq("level",1),Eq("equipped_armor",4)))
    }.AsReadOnly();
    private static readonly (string Fact, string Resolved, Func<NeutralTarget,int?> Expected)[] Bosses =
    [
        ("neutral_toriel_dead","toriel_resolved",t=>t.TorielDead),
        ("neutral_papyrus_dead","papyrus_resolved",t=>t.PapyrusDead),
        ("neutral_undyne_dead","undyne_resolved",t=>t.UndyneDead),
        ("neutral_mettaton_dead","mettaton_resolved",t=>t.MettatonDead)
    ];

    public static IEnumerable<string> Facts=>new[]{"neutral_toriel_dead","neutral_papyrus_dead","neutral_undyne_dead","neutral_mettaton_dead","neutral_undyne_friendship","neutral_alphys_friendship","kills","murder_level","mettaton_resolved"}.Concat(ModifierRules.SelectMany(r=>r.Condition.Tests.Select(t=>t.Fact)));
    public static int FriendshipMinimum(int id)=>id==1?4:id is 4 or 5?1:0;

    public static NeutralTarget Get(int id) => id >= 0 && id < SelectableCount ? Targets[id] :
        throw new ArgumentOutOfRangeException(nameof(id),"Unknown or debug-only Neutral target");

    public static Evaluation Evaluate(int targetId, GameState state, SpoilerLevel spoilers = SpoilerLevel.Minimal,
        Language language = Language.English)
    {
        var target=Get(targetId);
        var blocked=false; var unknown=false; var action=false;
        var objectives=new List<Objective>(); var reasons=new List<string>();
        void Mark(string fact,string english,string korean,bool invalidated=false)
        {
            if(invalidated) { blocked=true; reasons.Add("invalidated:"+fact); }
            else action=true;
            if(objectives.Count==0) objectives.Add(new(fact,language==Language.Korean?korean:english));
        }
        if(state["hard_mode"] is null || state["world_erased"] is null || state["true_lab_completed"] is null) unknown=true;
        if(state["hard_mode"]==1) Mark("hard_mode","Hard Mode cannot reach a Neutral ending.","하드 모드에서는 뉴트럴 엔딩에 도달할 수 없습니다.",true);
        if(state["world_erased"]==1) Mark("world_erased","The world is erased; permanent-history choices remain yours.","세계가 지워졌습니다. 영구 기록은 직접 결정해야 합니다.",true);
        var stage=state["murder_level"];
        if(stage is null) unknown=true;
        else if(stage>=16) Mark("murder_level","The Genocide conclusion is already committed.","몰살 결말이 이미 확정되었습니다.",true);
        if(state["true_lab_completed"]==1) Mark("true_lab_completed","The True Pacifist finale is already unlocked.","진정한 불살의 최종 분기가 이미 열렸습니다.",true);
        foreach(var (fact,resolved,expected) in Bosses)
        {
            if(expected(target) is not int wanted) continue;
            var actual=state[fact];
            if(actual is null) { unknown=true;continue; }
            if(actual==wanted) continue;
            var permanentlyWrong=actual==1 || state[resolved]==1;
            if(wanted==1 && !permanentlyWrong && state[resolved] is null) unknown=true;
            var character=fact.Replace("neutral_", "").Replace("_dead", "");
            Mark(fact,spoilers==SpoilerLevel.Detailed?$"Resolve {character}'s encounter with the selected outcome.":"Preserve the selected encounter outcomes.",
                "선택한 조우 결과를 지켜 주세요.",permanentlyWrong);
        }
        var kills=state["kills"];
        if(kills is null) unknown=true;
        else if(kills>target.MaximumKills) Mark("kills","The selected kill limit has been exceeded.","선택한 처치 수 제한을 초과했습니다.",true);
        else if(kills<target.MinimumKills) Mark("kills","Follow the selected encounters before the final battle.","최종 전투 전에 선택한 조우 조건을 충족하세요.");
        if(kills is int observedKills && target.MaximumKills<int.MaxValue)
        {
            int reserved=Bosses.Count(b=>b.Item3(target)==1&&state[b.Item1]==0);
            if((long)observedKills+reserved>target.MaximumKills)
                Mark("kills","Too few kills remain for the required boss outcomes.","필수 보스 결과를 위한 처치 수가 남아 있지 않습니다.",true);
        }
        if(targetId is >=1 and <=5)
        {
            var friendship=state["neutral_undyne_friendship"];
            if(friendship is null) unknown=true;
            else if(targetId==1 && friendship<4)
            {
                var locked=kills>0 || state["water_opportunity_missed"]==1;
                Mark("neutral_undyne_friendship","Complete the warrior's friendship without gaining EXP.","EXP를 얻지 않고 전사와 우정을 쌓으세요.",locked);
            }
            else if(targetId is 2 or 3 && friendship>0 && kills>0)
                Mark("neutral_undyne_friendship","The friendship betrayal changes this variant.","우정 배신 기록이 이 변형을 바꿉니다.",true);
            else if(targetId is 2 or 3 && friendship>3)
                Mark("neutral_undyne_friendship","This friendship no longer matches the selected variant.","이 우정은 선택한 변형과 맞지 않습니다.",true);
            else if(targetId is 4 or 5 && friendship<=0)
                Mark("neutral_undyne_friendship","Start the warrior's friendship before any additional kills.","추가 처치 전에 전사와 우정을 시작하세요.",kills>0 || state["water_opportunity_missed"]==1);
        }
        if(targetId==18)
        {
            if(stage is >=0 and <12) Mark("murder_level","Follow Genocide through Waterfall, then abandon it in Hotland.","워터폴까지 몰살 조건을 지킨 뒤 핫랜드에서 중단하세요.",state["undyne_resolved"]==1);
        }
        else if(target.MettatonDead==1 && stage>=12)
            Mark("murder_level","The late Genocide history overrides this Neutral outcome.","후반 몰살 기록이 이 뉴트럴 결과를 바꿉니다.",true);
        if(!blocked && objectives.Count==0)
            objectives.Add(new("continue",language==Language.Korean?"선택한 결과를 유지하며 여정을 계속하세요.":"Continue while preserving the selected outcomes."));
        var status=blocked?RouteStatus.BLOCKED:unknown?RouteStatus.UNKNOWN:action?RouteStatus.ACTION_REQUIRED:RouteStatus.ON_TRACK;
        var basis=new Evaluation(status,objectives,reasons,true);
        var goal=state["target_greeting"]??0;
        return goal>0?NeutralGoals.Merge(basis,NeutralGoals.Evaluate(goal,targetId,state,language)):basis;
    }

    /// <summary>Source-selected opening slot origins, separate from condition satisfaction.</summary>
    public static IReadOnlyList<string> OpeningSlotSources(GameState state)
    {
        var outcome=Classify(state);int mask=outcome.ModifierMask;
        var slots=Enumerable.Repeat("base",7).ToArray();
        void Put(string origin,params int[] indexes) { foreach(int index in indexes)slots[index-2]=origin; }
        if((mask&8)!=0)Put("keepsake",3,4,5,6);
        if((mask&16)!=0)Put("save",2,4,5,6);
        if((mask&32)!=0)Put("armor",3,4,5,6);
        if((mask&64)!=0)Put("healing",3,4,5,6);
        if((mask&128)!=0)Put("composite",3,4,5,6,7,8);
        if(outcome.OriginalBranch==7)Put("late",2,3);
        return slots;
    }

    public static NeutralOutcome Classify(GameState state)
    {
        var keys=new[]{"neutral_toriel_dead","neutral_papyrus_dead","neutral_undyne_dead","neutral_mettaton_dead","kills","murder_level","neutral_undyne_friendship"};
        if(keys.Any(k=>state[k] is null)) throw new InvalidOperationException("Neutral classification requires observed outcome facts.");
        bool t=state[keys[0]]==1,p=state[keys[1]]==1,u=state[keys[2]]==1,m=state[keys[3]]==1;
        int kills=state["kills"]!.Value,stage=state["murder_level"]!.Value,friend=state["neutral_undyne_friendship"]!.Value;
        NeutralEnding ending; int branch;
        if(stage>=12 && m) { ending=NeutralEnding.Alphys;branch=7; }
        else if(!t)
        {
            if(p||u||kills>=10) { ending=u?(p?NeutralEnding.ExiledUndyneDeadPapyrusDead:NeutralEnding.ExiledUndyneDeadPapyrusAlive):(p?NeutralEnding.ExiledUndyneAlivePapyrusDead:NeutralEnding.ExiledUndyneAlivePapyrusAlive);branch=1; }
            else if(friend>3 && kills==0) { ending=NeutralEnding.Family;branch=0; }
            else if(kills>0 && friend>0) { ending=m?NeutralEnding.BetrayedBefriendedMettatonDead:NeutralEnding.BetrayedBefriendedMettatonAlive;branch=0; }
            else { ending=m?NeutralEnding.BetrayedUnbefriendedMettatonDead:NeutralEnding.BetrayedUnbefriendedMettatonAlive;branch=0; }
        }
        else if(!u) { ending=p?NeutralEnding.UndynePapyrusDead:NeutralEnding.UndynePapyrusAlive;branch=2; }
        else if(!m) { ending=p?NeutralEnding.MettatonPapyrusDead:NeutralEnding.MettatonPapyrusAlive;branch=3; }
        else if(!p) { ending=NeutralEnding.Papyrus;branch=4; }
        else if(kills==4) { ending=NeutralEnding.Dog;branch=6; }
        else { ending=kills>=20?NeutralEnding.LeaderlessHighKills:NeutralEnding.LeaderlessLowKills;branch=5; }
        var projection=new GameState(new Dictionary<string,int?>(state.Facts){["neutral_projection"]=(int)ending});
        var modifiers=ModifierRules.Where(r=>r.Condition.Matches(projection)).Select(r=>r.Id).ToArray();
        return new(ending,branch,modifiers);
    }
}
