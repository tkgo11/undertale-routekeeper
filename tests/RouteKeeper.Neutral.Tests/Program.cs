using RouteKeeper.Core;

var outputs=new Dictionary<string,string>
{
    ["greeting_label.gml"]=NeutralGoals.EmitLabels(),
    ["greeting_evaluate.gml"]=NeutralGoals.EmitEvaluation(),
    ["greeting_protect.gml"]=NeutralGoals.EmitProtection(),
    ["neutral_label.gml"]=NeutralGmlEmitter.EmitLabels(),
    ["neutral_modifiers.gml"]=NeutralGmlEmitter.EmitModifiers(),
    ["neutral_classify.gml"]=NeutralGmlEmitter.EmitClassifier(),
    ["neutral_evaluate.gml"]=NeutralGmlEmitter.EmitEvaluator(),
    ["neutral_protect.gml"]=NeutralGmlEmitter.EmitProtection()
};
if(args is ["--emit-gml",var directory])
{
    Directory.CreateDirectory(directory);
    foreach(var (name,source) in outputs)File.WriteAllText(Path.Combine(directory,name),source);
    Console.WriteLine("PASS generated Neutral scripts");return;
}
if(args is ["--verify-gml",var checkedDirectory])
{
    foreach(var (name,source) in outputs)
        if(File.ReadAllText(Path.Combine(checkedDirectory,name)).Replace("\r\n","\n")!=source.Replace("\r\n","\n"))throw new Exception("Stale generated "+name);
    Console.WriteLine("PASS Neutral generated source matches model");return;
}
int passed=0;
void Check(string name,Action run) { run();passed++;Console.WriteLine("PASS "+name); }
void Assert(bool condition) { if(!condition)throw new Exception("Assertion failed"); }
GameState State(int t=0,int p=0,int u=0,int m=0,int kills=0,int friendship=0,int stage=0)=>new(new Dictionary<string,int?>
{
    ["neutral_toriel_dead"]=t,["neutral_papyrus_dead"]=p,["neutral_undyne_dead"]=u,["neutral_mettaton_dead"]=m,
    ["kills"]=kills,["neutral_undyne_friendship"]=friendship,["neutral_alphys_friendship"]=0,["murder_level"]=stage,
    ["toriel_resolved"]=1,["papyrus_resolved"]=1,["undyne_resolved"]=1,["mettaton_resolved"]=1,
    ["true_lab_completed"]=0,["hard_mode"]=0,["world_erased"]=0,["water_opportunity_missed"]=0,["language"]=0,["keepsake_recoverable"]=1
});
GameState With(GameState s,string key,int? value)=>new(new Dictionary<string,int?>(s.Facts){[key]=value});
var fixtures=new (NeutralEnding Ending,GameState State)[]
{
    (NeutralEnding.Family,State(friendship:4)),
    (NeutralEnding.BetrayedUnbefriendedMettatonAlive,State()),
    (NeutralEnding.BetrayedUnbefriendedMettatonDead,State(m:1,kills:1)),
    (NeutralEnding.BetrayedBefriendedMettatonAlive,State(kills:1,friendship:4)),
    (NeutralEnding.BetrayedBefriendedMettatonDead,State(m:1,kills:1,friendship:4)),
    (NeutralEnding.ExiledUndyneAlivePapyrusAlive,State(kills:10)),
    (NeutralEnding.ExiledUndyneAlivePapyrusDead,State(p:1,kills:1)),
    (NeutralEnding.ExiledUndyneDeadPapyrusAlive,State(u:1,kills:1)),
    (NeutralEnding.ExiledUndyneDeadPapyrusDead,State(p:1,u:1,kills:2)),
    (NeutralEnding.UndynePapyrusAlive,State(t:1,kills:1)),
    (NeutralEnding.UndynePapyrusDead,State(t:1,p:1,kills:2)),
    (NeutralEnding.MettatonPapyrusAlive,State(t:1,u:1,kills:2)),
    (NeutralEnding.MettatonPapyrusDead,State(t:1,u:1,p:1,kills:3)),
    (NeutralEnding.Papyrus,State(t:1,u:1,m:1,kills:3)),
    (NeutralEnding.Dog,State(t:1,u:1,p:1,m:1,kills:4)),
    (NeutralEnding.LeaderlessLowKills,State(t:1,u:1,p:1,m:1,kills:5)),
    (NeutralEnding.LeaderlessHighKills,State(t:1,u:1,p:1,m:1,kills:20)),
    (NeutralEnding.Alphys,State(t:1,u:1,p:1,m:1,kills:50,stage:12))
};
foreach(var (ending,state) in fixtures)
{
    Check("classify "+ending,()=>Assert(NeutralCatalog.Classify(state).Ending==ending));
    Check("target reachable "+ending,()=>Assert(NeutralCatalog.Evaluate((int)ending,state).Status==RouteStatus.ON_TRACK));
}
Check("Hard Mode cannot produce a legitimate Neutral target",()=>Assert(NeutralCatalog.Evaluate(0,With(State(),"hard_mode",1)).Status==RouteStatus.BLOCKED));
Check("Erased world cannot produce a Neutral target",()=>Assert(NeutralCatalog.Evaluate(0,With(State(),"world_erased",1)).Status==RouteStatus.BLOCKED));
Check("Unobserved history cannot prove reachability",()=>Assert(NeutralCatalog.Evaluate(0,With(State(),"world_erased",null)).Status==RouteStatus.UNKNOWN));
Check("Dog requires exactly four kills",()=>Assert(NeutralCatalog.Evaluate(15,State(t:1,p:1,u:1,m:1,kills:5)).Status==RouteStatus.BLOCKED));
Check("A dead protected boss blocks target",()=>Assert(NeutralCatalog.Evaluate(1,State(p:1,kills:1)).Status==RouteStatus.BLOCKED));
Check("A pending required kill requires action",()=>Assert(NeutralCatalog.Evaluate(10,With(State(),"toriel_resolved",0)).Status==RouteStatus.ACTION_REQUIRED));
Check("A spared required boss blocks target",()=>Assert(NeutralCatalog.Evaluate(10,State()).Status==RouteStatus.BLOCKED));
Check("Missing resolution does not fabricate a spare",()=>Assert(NeutralCatalog.Evaluate(10,With(State(),"toriel_resolved",null)).Status==RouteStatus.UNKNOWN));
Check("Betrayal after friendship cannot become unbefriended",()=>Assert(NeutralCatalog.Evaluate(2,State(kills:1,friendship:4)).Status==RouteStatus.BLOCKED));
Check("Alphys overrides other late Genocide neutral branches",()=>Assert(NeutralCatalog.Classify(State(t:1,p:1,u:1,m:1,kills:4,stage:12)).Ending==NeutralEnding.Alphys));
Check("Full Genocide commitment blocks Neutral target",()=>Assert(NeutralCatalog.Evaluate(0,State(stage:16)).Status==RouteStatus.BLOCKED));
Check("True Lab commitment blocks Neutral target",()=>Assert(NeutralCatalog.Evaluate(0,With(State(),"true_lab_completed",1)).Status==RouteStatus.BLOCKED));
Check("Family Alphys cameo modifier",()=>Assert(NeutralCatalog.Classify(With(State(friendship:4),"neutral_alphys_friendship",10)).Modifiers.Contains("alphys_call")));
Check("Debug-only ending is never selectable",()=> {try{NeutralCatalog.Get(20);throw new Exception("accepted impossible");}catch(ArgumentOutOfRangeException){} });
Check("All target IDs contiguous and localized",()=>Assert(NeutralCatalog.Targets.Select(t=>(int)t.Id).SequenceEqual(Enumerable.Range(0,19))&&NeutralCatalog.Targets.All(t=>t.English.Length>0&&t.Korean.Length>0)));
Check("C# and emitted classifier agree on 10000 snapshots",()=>
{
    var random=new Random(391540);
    for(int i=0;i<10000;i++)
    {
        var s=State(random.Next(2),random.Next(2),random.Next(2),random.Next(2),random.Next(70),random.Next(5),random.Next(17));
        var actual=new GmlProgram(outputs["neutral_classify.gml"],s.Facts).Run();
        Assert(actual==(int)NeutralCatalog.Classify(s).Ending);
    }
});
Check("C# and emitted evaluator agree on 19000 target snapshots",()=>
{
    var random=new Random(391541);
    for(int i=0;i<19000;i++)
    {
        var s=State(random.Next(2),random.Next(2),random.Next(2),random.Next(2),random.Next(70),random.Next(5),random.Next(17));
        foreach(var boss in new[]{"toriel","papyrus","undyne","mettaton"})s=With(s,boss+"_resolved",random.Next(3)-1);
        if(i%11==0)s=With(s,"murder_level",null);
        int target=i%19;s=With(s,"target_neutral",target);
        var actual=new GmlProgram(outputs["neutral_evaluate.gml"],s.Facts).Run();
        var expected=(int)NeutralCatalog.Evaluate(target,s).Status;
        if(actual!=expected)throw new Exception($"Parity target{target} sample{i}: {actual}!={expected}");
    }
});
Check("Optional Neutral call conditions match generated source on 5000 snapshots",()=> {
    var random=new Random(391542);
    for(int i=0;i<5000;i++) {
        var s=State(random.Next(2),random.Next(2),random.Next(2),random.Next(2),random.Next(70),random.Next(5),random.Next(17));
        s=With(s,"snowman_piece_carried",random.Next(2));s=With(s,"save_exists",random.Next(2));
        s=With(s,"equipped_armor",random.Next(2)==0?4:10);s=With(s,"healing_items_used",random.Next(3));
        s=With(s,"level",random.Next(2)==0?1:10);s=With(s,"neutral_alphys_friendship",random.Next(2)==0?0:10);
        var projected=NeutralCatalog.Classify(s);s=With(s,"neutral_projection",(int)projected.Ending);
        var actual=new GmlProgram(outputs["neutral_modifiers.gml"],s.Facts).Run();
        Assert(actual==projected.ModifierMask);
    }
});
Check("Call goals preserve irreversible vs recoverable requirements",()=>{
    var basic=With(With(With(With(State(),"level",1),"equipped_armor",4),"healing_items_used",0),"save_exists",0);
    Assert(NeutralGoals.Evaluate(5,0,basic).Status==RouteStatus.ON_TRACK);
    Assert(NeutralGoals.Evaluate(5,0,With(basic,"save_exists",1)).Status==RouteStatus.BLOCKED);
    Assert(NeutralGoals.Evaluate(6,0,With(basic,"equipped_armor",12)).Status==RouteStatus.BLOCKED);
    Assert(NeutralGoals.Evaluate(7,0,With(basic,"healing_items_used",1)).Status==RouteStatus.BLOCKED);
    Assert(NeutralGoals.Evaluate(8,0,With(basic,"level",2)).Status==RouteStatus.BLOCKED);
    Assert(NeutralGoals.Evaluate(4,0,With(basic,"snowman_piece_carried",0)).Status==RouteStatus.ACTION_REQUIRED);
    Assert(NeutralGoals.Evaluate(4,0,With(basic,"snowman_piece_carried",null)).Status==RouteStatus.UNKNOWN);
});
Check("Incompatible ending and call goals fail explicitly",()=>{
    Assert(NeutralGoals.Evaluate(5,15,State()).Status==RouteStatus.BLOCKED);
    Assert(NeutralGoals.Evaluate(1,4,State()).Status==RouteStatus.BLOCKED);
    Assert(NeutralGoals.Evaluate(2,1,State()).Status==RouteStatus.BLOCKED);
});
Check("Call-goal boss protections reflect required outcomes",()=>{
    Assert(NeutralGoals.BossOutcome(4,2)==1 && NeutralGoals.BossOutcome(1,1)==1);
    Assert(NeutralGoals.BossOutcome(3,4)==-1 && NeutralGoals.BossOutcome(2,4)==1);
    Assert(NeutralGoals.BossOutcome(0,1)==0);
    foreach(int incompatible in new[]{3,5,8,10,12,14})Assert(NeutralGoals.Evaluate(8,incompatible,State()).Status==RouteStatus.BLOCKED);
});
Check("Every selectable goal has an achievable declared fixture",()=>{
    for(int goal=1;goal<=8;goal++){
        var s=With(With(With(With(With(With(State(friendship:4),"level",1),"equipped_armor",4),"healing_items_used",0),"save_exists",0),"snowman_piece_carried",1),"keepsake_recoverable",1);
        s=With(s,"neutral_alphys_friendship",10);
        if(goal==2)s=With(s,"kills",10);
        if(goal==3){s=With(s,"kills",10);s=With(s,"neutral_mettaton_dead",1);}
        Assert(NeutralGoals.Evaluate(goal,0,s).Status==RouteStatus.ON_TRACK);
    }
});
Check("All call goals match emitted status and objective on 6000 snapshots",()=>{
    var random=new Random(20261025);var code=NeutralGoals.EmitEvaluation();var integratedCode=NeutralGmlEmitter.EmitEvaluator();
    for(int sample=0;sample<6000;sample++){
        int goal=sample%9,target=random.Next(19),language=random.Next(2);
        var s=State(random.Next(2),random.Next(2),random.Next(2),random.Next(2),random.Next(15),random.Next(5),random.Next(17));
        foreach(var key in new[]{"save_exists","healing_items_used","snowman_piece_carried"})s=With(s,key,random.Next(3)-1);
        s=With(s,"equipped_armor",random.Next(3)==0?4:12);s=With(s,"level",random.Next(3)==0?1:2);s=With(s,"neutral_alphys_friendship",random.Next(2)==0?0:10);
        s=With(s,"mettaton_resolved",random.Next(3)-1);s=With(s,"target_greeting",goal);s=With(s,"target_neutral",target);s=With(s,"language",language);
        var vm=new GmlObjectiveInterpreter(code,s.Facts);int actual=int.Parse(vm.Run());var expected=NeutralGoals.Evaluate(goal,target,s,(Language)language);
        if(actual!=(int)expected.Status)throw new Exception($"Goal status parity {sample}/{goal}");
        if(expected.Objectives.Count>0 && vm.Text("greeting_text")!=expected.Objectives[0].Text)throw new Exception($"Goal objective parity {sample}/{goal}: "+vm.Text("greeting_text")+" != "+expected.Objectives[0].Text);
        var integrated=new GmlProgram(integratedCode,s.Facts).Run();
        if(integrated!=(int)NeutralCatalog.Evaluate(target,s).Status)throw new Exception($"Integrated goal status parity sample={sample} goal={goal} target={target} actual={integrated} expected={NeutralCatalog.Evaluate(target,s).Status} facts={System.Text.Json.JsonSerializer.Serialize(s.Facts)}");
    }
});
Check("Call-goal labels and integrated boss policies match emitted source on 738 cases",()=>{
    var standalone=NeutralGoals.EmitProtection();var integrated=NeutralGmlEmitter.EmitProtection();var labels=NeutralGoals.EmitLabels();
    foreach(var goal in NeutralGoals.Goals){
        for(int language=0;language<2;language++){
            var prefix=$"argument0 = {goal.Id}; argument1 = {language}; ";
            var actual=new GmlObjectiveInterpreter(prefix+labels,new Dictionary<string,int?>()).Run();
            Assert(actual==(language==1?goal.Korean:goal.English));
        }
        for(int enemy=1;enemy<=4;enemy++){
            int extra=NeutralGoals.BossOutcome(goal.Id,enemy);var prefix=$"argument0 = {enemy}; ";
            var facts=new Dictionary<string,int?>{{"target_greeting",goal.Id}};
            Assert(int.Parse(new GmlObjectiveInterpreter(prefix+standalone,facts).Run())==extra);
            foreach(var target in NeutralCatalog.Targets){
                facts["target_neutral"]=(int)target.Id;
                var outcomes=new[]{target.TorielDead,target.PapyrusDead,target.UndyneDead,target.MettatonDead};
                int basis=outcomes[enemy-1] is int dead?(dead==0?1:-1):0;
                Assert(int.Parse(new GmlObjectiveInterpreter(prefix+integrated,facts).Run())==(extra!=0?extra:basis));
            }
        }
    }
});
Console.WriteLine($"PASS {passed} Neutral tests; authentic runtime NOT_RUN");
