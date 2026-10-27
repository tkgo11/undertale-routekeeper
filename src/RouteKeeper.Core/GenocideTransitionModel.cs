namespace RouteKeeper.Core;

/// <summary>Source-ordered kill events and delayed regional settlement. Combat
/// victory/RNG is assumed, never claimed executed; ordinary EXP stays unknown.</summary>
public sealed class GenocideTransitionModel
{
    readonly Dictionary<int,int> flags=[];
    readonly List<string> events=[];
    int kills,pending,area;
    bool sans;
    public IReadOnlyDictionary<int,int> Flags=>flags.AsReadOnly();
    public IReadOnlyList<string> Events=>events.AsReadOnly();
    public int Stage=>MurderStage(flags);
    int Get(int n)=>flags.GetValueOrDefault(n);
    public static int MurderStage(IReadOnlyDictionary<int,int> f)
    {
        int G(int n)=>f.GetValueOrDefault(n);int stage=0;
        if(G(202)>=20)stage=1;else return stage;
        if(G(45)==4)stage=2;else return stage;
        if(G(52)==1)stage=3;else return stage;
        if(G(53)==1)stage=4;else return stage;
        if(G(54)==1)stage=5;else return stage;
        if(G(57)==2)stage=6;else return stage;
        if(G(203)>=16)stage=7;else return stage;
        if(G(67)==1)stage=8;else return stage;
        if(G(81)==1)stage=9;else return stage;
        if(G(252)==1)stage=10;else return stage;
        if(G(204)>=18)stage=11;else return stage;
        if(G(251)==1&&G(350)==1)stage=12;else return stage;
        if(G(402)==1)stage=13;else return stage;
        if(G(397)==1)stage=14;else return stage;
        if(G(205)>=40)stage=15;else return stage;
        if(G(425)==1&&G(27)==0)stage=16;
        return stage;
    }
    void Kill(int count,string name){kills+=count;pending+=count;events.Add(name+":kills+"+count);}
    public void Settle(){flags[202+area]=Get(202+area)+pending;events.Add("overworld-return:region="+area+":delta="+pending);pending=0;}
    public void Ordinary(int count)
    {
        if(count<1||pending!=0||(long)Get(202+area)+count>new[]{20,16,18,40}[area])throw new InvalidOperationException("No remaining modeled population.");
        for(int i=0;i<count;i++){Kill(1,"ordinary-encounter:region="+area);Settle();}
    }
    public void Toriel()
    {
        if(area!=0||Get(202)<19)throw new InvalidOperationException("Ruins deadline missed.");
        flags[45]=4;Kill(1,"Toriel");Settle();if(Stage!=2)throw new InvalidOperationException();area=1;
    }
    public void Unique(int flag,int expectedStage,int count,string name)
    {
        bool supported=(flag,expectedStage,count,area) is (52,2,1,1) or (53,3,2,1) or (54,4,1,1) or (57,5,1,1) or (81,8,1,2) or (252,9,1,2) or (402,12,2,3) or (397,13,1,3);
        if(!supported)throw new InvalidOperationException("Unverified unique event.");
        if(pending!=0||Stage!=expectedStage)throw new InvalidOperationException("Required event order violated: "+name);
        flags[flag]=flag==57?2:1;Kill(count,name);Settle();
    }
    public void Papyrus(){if(Stage!=7)throw new InvalidOperationException("Snowdin deadline missed.");flags[67]=1;Kill(1,"Papyrus");Settle();area=2;}
    public void Undying(){if(Stage!=11)throw new InvalidOperationException("Waterfall deadline missed.");flags[251]=flags[350]=1;Kill(1,"Undying");Settle();area=3;}
    public void Neo()
    {
        if(Stage<12||pending!=0)throw new InvalidOperationException("Not the NEO branch.");
        // The abandonment check occurs BEFORE the later overworld delta update.
        if(Get(205)<40)flags[27]=1;
        flags[425]=1;Kill(1,"NEO-before-regional-settlement");
    }
    public void Sans(){if(Stage!=16||pending!=0)throw new InvalidOperationException("Sans unavailable.");sans=true;events.Add("Sans-death-c35:EXP-floor99999");}
    public GameState Snapshot(bool sold)
    {
        var f=new Dictionary<string,int?>{["kills"]=kills,["kills_total"]=kills,["murder_level"]=Stage,["genocide_stage"]=Stage,
            ["neutral_undyne_friendship"]=0,["neutral_alphys_friendship"]=0,["hard_mode"]=0,["world_erased"]=0,["true_lab_completed"]=0,
            ["genocide_aborted"]=Get(27),["snowdrake_lost"]=0,["sans_defeated"]=sans?1:0,["soul_sold"]=sold?1:0};
        foreach(var (boss,flag) in new[]{("toriel",45),("papyrus",67),("undyne",350),("mettaton",425)}) {
            f["neutral_"+boss+"_dead"]=Get(flag)>0?1:0;f[boss+"_resolved"]=Get(flag)>0?1:0;
        }
        f["mettaton_defeated"]=f["mettaton_resolved"];
        if(sans)f["experience"]=99999;
        return new(f);
    }
    public static GenocideTransitionModel Witness(bool abandonLate)
    {
        var m=new GenocideTransitionModel();m.Ordinary(19);m.Toriel();
        m.Unique(52,2,1,"Doggo");m.Unique(53,3,2,"Dogi");m.Unique(54,4,1,"GreaterDog");m.Unique(57,5,1,"Snowdrake");m.Ordinary(11);m.Papyrus();
        m.Unique(81,8,1,"Shyren");m.Unique(252,9,1,"GladDummy");m.Ordinary(16);m.Undying();
        m.Unique(402,12,2,"RoyalGuards");m.Unique(397,13,1,"Muffet");m.Ordinary(abandonLate?36:37);m.Neo();m.Settle();
        if(!abandonLate)m.Sans();return m;
    }
}
