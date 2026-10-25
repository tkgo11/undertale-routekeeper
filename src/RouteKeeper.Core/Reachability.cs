namespace RouteKeeper.Core;

public enum ReachabilityVerdict { ReachableInSourceModel, Impossible, Unknown }
public sealed record ReachabilityResult(ReachabilityVerdict Verdict,string Evidence,IReadOnlyList<string> Events,GameState? FinalState=null);

/// <summary>Ordered, source-bounded witness model. Not a VM, RNG proof or runtime approval.
/// Normal route witnesses deliberately use available pre-boss encounters. Unknown
/// zero-EXP scripted kills are not generalized into ordinary kills.</summary>
public sealed class RunTransitionModel
{
    readonly Dictionary<string,int?> facts=new(StringComparer.Ordinal);
    readonly int[] regional=new int[4];
    readonly bool[] resolved=new bool[4];
    readonly List<string> events=[];
    int region,location,experience,kills,pending,friendship;
    bool water,waterGiven,hangoutAllowed=true;
    public static int LevelForExperience(int xp)=>xp<0?throw new ArgumentOutOfRangeException(nameof(xp)):1+new[]{10,30,70,120,200,300,500,800,1200,1700,2500,3500,5000,7000,10000,15000,25000,50000,99999}.Count(x=>xp>=x);
    public static bool? EncountersSuppressed(int area,int count,int plot10)=>area switch {1=>count==0&&plot10>1000,2=>count==0&&plot10>1210,_=>null};
    public IReadOnlyList<string> Events=>events.AsReadOnly();
    public RunTransitionModel(bool soulSold=false,bool priorNeutral=false)
    {
        facts["soul_sold"]=soulSold?1:0;facts["prior_neutral_completion"]=priorNeutral?1:0;
        facts["hard_mode"]=facts["world_erased"]=facts["water_opportunity_missed"]=facts["true_lab_completed"]=facts["barrier_broken"]=0;
        facts["neutral_alphys_friendship"]=0;facts["equipped_armor"]=4;facts["healing_items_used"]=0;facts["save_exists"]=0;
        facts["snowman_piece_carried"]=facts["snowman_piece_stored"]=0;facts["keepsake_recoverable"]=1;
        foreach(string boss in new[]{"toriel","papyrus","undyne","mettaton"}) {facts["neutral_"+boss+"_dead"]=0;facts[boss+"_resolved"]=0;}
    }
    public void KillOrdinary(int count=1)
    {
        if(location<region&&regional[location]==0)throw new InvalidOperationException("Cleared zero-kill-region encounters are suppressed after the plot deadline.");
        if(location!=region)throw new InvalidOperationException("Backtracking encounters outside the verified witness subset.");
        if(count<1||pending!=0||region>3||resolved[region])throw new InvalidOperationException("No modeled encounter available.");
        int capacity=new[]{20,16,18,40}[region];
        if(regional[region]+count>capacity)throw new InvalidOperationException("Population exhausted.");
        // Source-pinned Loox basic reward7; Hotland Vulkin reward70. These
        // witnesses need no manipulated reward, optional encounter or backtracking.
        if(region is 1 or 2)throw new InvalidOperationException("This witness subset does not certify these ordinary encounter rewards.");
        int reward=region==0?7:70;
        for(int i=0;i<count;i++){experience+=reward;kills++;pending++;events.Add($"kill-ordinary:enemy={(region==0?"Loox":"Vulkin")}:region={region}:reward={reward}");ReturnFromBattle();}
    }
    public void ReturnFromBattle()
    {
        regional[region]+=pending;pending=0;events.Add("settle-regional-kill-delta");
    }
    public void ResolveBoss(bool defeat)
    {
        if(region>3||resolved[region]||pending!=0)throw new InvalidOperationException("Boss event order invalid.");
        string boss=new[]{"toriel","papyrus","undyne","mettaton"}[region];
        if(defeat){kills++;pending++;experience+=new[]{150,200,500,800}[region];facts["neutral_"+boss+"_dead"]=1;}
        facts[boss+"_resolved"]=1;resolved[region]=true;
        if(region==2){water=!defeat;facts["water_opportunity_missed"]=0;}
        events.Add($"boss:{boss}:{(defeat?"defeat":"spare")}");ReturnFromBattle();
    }
    public void Advance()
    {
        if(region>=3||!resolved[region]||pending!=0)throw new InvalidOperationException("Cannot leave before boss and counter settlement.");
        if(region==2&&water)MissWater();
        region++;location=region;events.Add("advance-region:"+region);
    }
    public void BacktrackTo(int area)
    {
        if(area<1||area>=region)throw new InvalidOperationException("Ruins backtracking is not available.");
        location=area;events.Add("backtrack-to:"+area);
    }
    public void ReturnToFrontier(){location=region;events.Add("return-to-frontier:"+region);}
    public void GiveWater()
    {
        if(!resolved[2]||!water)throw new InvalidOperationException("Water deadline unavailable.");
        water=false;waterGiven=true;events.Add("give-Undyne-water");
    }
    public void BefriendUndyne()
    {
        if(!resolved[2]||!waterGiven||kills!=0||!hangoutAllowed||facts["neutral_papyrus_dead"]!=0)throw new InvalidOperationException("Friendship prerequisites lost.");
        BacktrackTo(1);facts["papyrus_friendship"]=1;events.Add("Papyrus-hangout-completed");ReturnToFrontier();
        facts["undyne_friendship"]=1;friendship=4;events.Add("undyne-hangout-completed");
    }
    public void MissWater()
    {
        if(!resolved[2]||!water)throw new InvalidOperationException("No water opportunity.");
        water=false;hangoutAllowed=false;facts["water_opportunity_missed"]=1;events.Add("leave-without-water");
    }
    public void Save(){facts["save_exists"]=1;events.Add("save-file0");}
    public void AcquireKeepsake(){if(region!=1)throw new InvalidOperationException("Snowman not accessible in this witness.");facts["snowman_piece_carried"]=1;events.Add("ask-snowman-first-piece");}
    public void StoreKeepsake(){if(facts["snowman_piece_carried"]!=1)throw new InvalidOperationException();facts["snowman_piece_carried"]=0;facts["snowman_piece_stored"]=1;events.Add("store-piece");}
    public void RetrieveKeepsake(){if(facts["snowman_piece_stored"]!=1)throw new InvalidOperationException();facts["snowman_piece_carried"]=1;facts["snowman_piece_stored"]=0;events.Add("retrieve-piece");}
    public void CompleteNeutralAndReload()
    {
        if(!resolved.All(x=>x)||facts["true_lab_completed"]==1||facts["save_exists"]!=1)throw new InvalidOperationException();
        facts["prior_neutral_completion"]=1;events.Add("spare-Asgore;Omega-Flowey;spare-Flowey;neutral-call;credits-Won;reload-pre-barrier-save");
    }
    public void LetterAndDate()
    {
        if(!resolved[3]||friendship<3||kills!=0||facts["prior_neutral_completion"]!=1)throw new InvalidOperationException("Original letter gate unavailable.");
        facts["neutral_alphys_friendship"]=10;facts["alphys_friendship"]=1;events.Add("prior-neutral-reload;letter;alphys-date");
    }
    public void TrueLabAndFinale(int epilogue)
    {
        if(facts["neutral_alphys_friendship"]!=10||epilogue is <1 or >2)throw new InvalidOperationException();
        facts["true_lab_completed"]=facts["barrier_broken"]=facts["epilogue_resolved"]=facts["epilogue_matches"]=1;facts["epilogue_choice"]=epilogue;
        events.Add("true-lab-power;final-intro-special-end;asriel;barrier;epilogue:"+epilogue);
    }
    public GameState Snapshot()
    {
        var copy=new Dictionary<string,int?>(facts){["experience"]=experience,["kills"]=kills,["kills_total"]=kills,["level"]=LevelForExperience(experience),["murder_level"]=0,["neutral_undyne_friendship"]=friendship,["papyrus_alive"]=facts["neutral_papyrus_dead"]==0?1:0,["undyne_alive"]=facts["neutral_undyne_dead"]==0?1:0};
        return new(copy);
    }
}

public static class EndingReachability
{
    public static ReachabilityResult Neutral(int target,int goal=0)
    {
        var choice=NeutralCatalog.Get(target);var extra=NeutralGoals.Get(goal);
        if(!extra.CompatibleTargets.Contains(target))return new(ReachabilityVerdict.Impossible,"Source-backed boss/friendship/goal contradiction.",[]);
        // Do not treat minimum ordinary EXP as a proof about every scripted
        // 0-EXP outcome or every optional encounter available after friendship.
        if(goal==8 && target is 4 or 6)return new(ReachabilityVerdict.Unknown,"LV1 plus betrayal/high-kill Exile requires a full zero-EXP and encounter-availability graph; selector matches are insufficient.",[]);
        if(target==18) { var g=Genocide(true,false); return g with {Evidence="Ordered late quota abandonment and NEO resolution; not a normal EX battle."}; }
        if(goal is 2 or 3 && target==0)return Neutral(6,goal);
        if(target==0)return Neutral(1,goal);
        var model=new RunTransitionModel(priorNeutral:goal==1);
        bool friend=target is 1 or 4 or 5||goal==1;
        int extraKills=target==17?16:target==16?1:target==6?10:0;
        if(extraKills>0)model.KillOrdinary(extraKills);
        model.ResolveBoss(choice.TorielDead==1);model.Advance();
        if(goal==4){model.AcquireKeepsake();model.StoreKeepsake();model.RetrieveKeepsake();}
        model.ResolveBoss(choice.PapyrusDead==1);model.Advance();model.ResolveBoss(choice.UndyneDead==1);
        if(friend){model.GiveWater();model.BefriendUndyne();}model.Advance();
        if(target==4)model.KillOrdinary();
        bool mettaton=choice.MettatonDead==1||goal==3;
        model.ResolveBoss(mettaton);
        if(goal==1)model.LetterAndDate();
        var final=model.Snapshot();var outcome=NeutralCatalog.Classify(final);
        bool type=target==0||(int)outcome.Ending==target;
        if(!type||NeutralGoals.Evaluate(goal,target,final).Status!=RouteStatus.ON_TRACK)
            return new(ReachabilityVerdict.Unknown,"The bounded transition witness did not establish all conditions.",model.Events,final);
        return new(ReachabilityVerdict.ReachableInSourceModel,"Ordered pre-boss encounters, actual boss EXP/counts and friendship order; not gameplay execution.",model.Events,final);
    }
    public static ReachabilityResult Pacifist(bool sold,int epilogue)
    {
        var m=new RunTransitionModel(sold,false);
        for(int r=0;r<4;r++){m.ResolveBoss(false);if(r==2){m.GiveWater();m.BefriendUndyne();}if(r<3)m.Advance();}
        m.Save();m.CompleteNeutralAndReload();m.LetterAndDate();m.TrueLabAndFinale(epilogue);
        return new(ReachabilityVerdict.ReachableInSourceModel,"Ordered clean-run/letter/finale subset; permanent history is an input, never modified.",m.Events,m.Snapshot());
    }
    public static ReachabilityResult Genocide(bool abandonLate,bool sold)
    {
        var m=GenocideTransitionModel.Witness(abandonLate);
        return new(ReachabilityVerdict.ReachableInSourceModel,"Ordered quota/unique/boss events and delayed settlement; no combat/RNG execution.",m.Events,m.Snapshot(sold));
    }
}
