using System.Text.Json;
using RouteKeeper.Core;
using RouteKeeper.Decisions;
using RouteKeeper.History;

// Expected rows are derived from ORIGINAL GML by tools/audit-endings.py.
// No expected ending/condition is calculated from Core tables or emitted source.
using var file=JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory,"original-endings.json")));
var root=file.RootElement;int checks=0;
void Check(bool condition,string message) { if(!condition)throw new Exception(message);checks++; }
int[] Numbers(JsonElement row)=>row.EnumerateArray().Select(x=>x.GetInt32()).ToArray();
GameState Neutral(int[] n)=>new(new Dictionary<string,int?> {
    ["neutral_toriel_dead"]=n[0],["neutral_papyrus_dead"]=n[1],["neutral_undyne_dead"]=n[2],["neutral_mettaton_dead"]=n[3],
    ["kills"]=n[4],["neutral_undyne_friendship"]=n[5],["murder_level"]=n[6],["neutral_alphys_friendship"]=n[7],
    ["snowman_piece_carried"]=n[8],["save_exists"]=n[9],["equipped_armor"]=n[10],["healing_items_used"]=n[11],["level"]=n[12],
    ["hard_mode"]=0,["world_erased"]=0,["true_lab_completed"]=0,["water_opportunity_missed"]=0,
    ["toriel_resolved"]=n[0],["papyrus_resolved"]=n[1],["undyne_resolved"]=n[2],["mettaton_resolved"]=n[3],
    ["keepsake_recoverable"]=1
});
GameState With(GameState s,string fact,int value)=>new(new Dictionary<string,int?>(s.Facts){[fact]=value});
var endings=new HashSet<int>();
foreach(var row in root.GetProperty("neutral").EnumerateArray()) {
    var facts=Numbers(row[0]);var state=Neutral(facts);var actual=NeutralCatalog.Classify(state);int expected=row[1].GetInt32();endings.Add(expected);
    Check((int)actual.Ending==expected,$"Original selector mismatch: {string.Join(',',facts)} expected {expected} actual {actual.Ending}");
    Check(actual.OriginalBranch==row[2].GetInt32(),"Original branch mismatch");
    Check(actual.ModifierMask==row[3].GetInt32(),$"Original optional condition mismatch: {string.Join(',',facts)} expected {row[3]} actual {actual.ModifierMask}");
    Check(NeutralCatalog.OpeningSlotSources(state).SequenceEqual(row[4].EnumerateArray().Select(x=>x.GetString()!)),"Original opening-slot precedence mismatch");
}
Check(endings.SetEquals(Enumerable.Range(1,18)),"Every legitimate Neutral variant must be represented");
// No special subtract-four adjustment exists in original con61. Four boss deaths
// are included in global.kills; ordinary-kill15/16/17 correspond to totals19/20/21.
foreach(var (total,expected) in new[]{(4,15),(5,16),(18,16),(19,16),(20,17),(21,17),(24,17)}) {
    var s=Neutral([1,1,1,1,total,0,0,0,0,1,12,1,2]);
    Check((int)NeutralCatalog.Classify(s).Ending==expected,"Leaderless total/non-boss boundary");
}
foreach(var row in root.GetProperty("ratings").EnumerateArray()) {
    var r=Numbers(row);Check(DecisionPolicy.RatingQualifies(r[0],r[1])==(r[2]==1),"Original Mettaton turn/rating threshold mismatch");
}
foreach(var row in root.GetProperty("letter").EnumerateArray()) {
    var r=Numbers(row);Check(StoryEligibility.LetterCallAvailable(r[0],r[1],r[2],r[3],r[4])==(r[5]==1),"Original letter gate mismatch");
}
foreach(var row in root.GetProperty("snowman").EnumerateArray()) {
    var r=Numbers(row);Check(KeepsakeGuidance.CanAcquire(r[0],r[1],r[2],0,r[4]==1,r[3]==1)==(r[6]==1),"Original Snowman acquisition branch mismatch");
}
foreach(var row in root.GetProperty("murder").EnumerateArray()) {
    int expected=row[1].GetInt32();
    var facts=RouteCatalog.Get(RouteId.Genocide).Requirements.GroupBy(r=>r.Fact).ToDictionary(g=>g.Key,g=>(int?)g.Last().Expected);
    facts["genocide_stage"]=expected;facts["toriel_resolved"]=facts["papyrus_resolved"]=facts["undyne_resolved"]=facts["mettaton_defeated"]=1;
    var status=RouteEvaluator.Evaluate(RouteId.Genocide,new(facts)).Status;
    Check(status==(expected==16?RouteStatus.ON_TRACK:RouteStatus.BLOCKED),"Original sequential murder stage at final deadline mismatch");
}
foreach(var row in root.GetProperty("finale").EnumerateArray()) {
    var r=Numbers(row);Check(StoryEligibility.PacifistFinaleSelected(r[0],r[1])==(r[2]==1),"Original Asgore final-intro selection mismatch");
}
foreach(var row in root.GetProperty("trueReset").EnumerateArray()) {
    var r=Numbers(row[0]);var ini=new Dictionary<string,int>{{"reset.s_key",r[0]},{"General.Won",r[1]},{"General.CP",r[2]},{"General.CH",r[3]},{"EndF.EndF",1},{"General.fun",13}};
    var expected=row[1].EnumerateObject().ToDictionary(x=>x.Name,x=>x.Value.GetInt32());
    var actual=HistoryTransitions.Preview(ResetKind.TrueReset,new(ini,new Dictionary<string,string>(),true)).Result.Ini;
    Check(actual.Count==expected.Count&&actual.All(x=>expected.GetValueOrDefault(x.Key,-1)==x.Value),"Original TRUE RESET INI write-set mismatch");
}
// Decision API tests: source-confirmed state transitions, not parity assertions.
var basic=Neutral([0,0,0,0,0,0,0,0,1,0,4,0,1]);
foreach(var (target,goal,effect,value) in new (int,int,string,int)[]{(1,0,"neutral_papyrus_dead",1),(4,0,"kills",1),(0,5,"save_exists",1),(0,6,"equipped_armor",12),(0,7,"healing_items_used",1),(0,8,"level",2),(0,4,"snowman_piece_carried",0)}) {
    var s=With(With(basic,"target_neutral",target),"target_greeting",goal);
    Check(DecisionMonitor.BreaksRoute(RouteId.Neutral,s,new("original-choice",new Dictionary<string,int?>{{effect,value}},true)),"Neutral decision API missed "+effect);
    Check(!DecisionMonitor.BreaksRoute(RouteId.Neutral,s,new("reversible",new Dictionary<string,int?>{{effect,value}},false)),"Reversible preview incorrectly blocked");
}
var mustKill=With(With(basic,"target_neutral",3),"target_greeting",0);
Check(DecisionMonitor.BreaksRoute(RouteId.Neutral,mustKill,new("scripted-spare",new Dictionary<string,int?>{{"mettaton_resolved",1}},true)),"Scripted resolution deadline ignored");
foreach(var mode in new[]{GuidanceMode.Passive,GuidanceMode.Active,GuidanceMode.Forced}) {
    var s=With(With(basic,"target_neutral",0),"target_greeting",5);
    Check(GuidanceController.Update(mode,RouteId.Neutral,s,new("save",new Dictionary<string,int?>{{"save_exists",1}},true)).Status==RouteStatus.AT_RISK,"Shared controller misses Neutral risk");
}
var scripted=new DecisionState(RouteFamily.Neutral,DecisionAction.ScriptedSpare,DecisionEnemy.Mettaton,NeutralOutcome:-1);
Check(DecisionPolicy.BeforeAction(DecisionMode.Forced,scripted,true).Refuse,"Forced scripted resolution escaped");
Check(!DecisionPolicy.BeforeAction(DecisionMode.Passive,scripted,true).Refuse,"Passive acknowledgement trapped scripted resolution");
// Reserved kill budget: all four mandatory boss deaths consume the original
// Dog total4, and a pending robot death consumes one of Betrayed's total9.
var dog=With(With(basic,"target_neutral",15),"target_greeting",0);
Check(DecisionMonitor.BreaksRoute(RouteId.Neutral,dog,new("optional-kill",new Dictionary<string,int?>{{"kills",1}},true)),"Reserved four-boss budget was ignored");
var betrayed=With(With(mustKill,"kills",8),"mettaton_resolved",0);
Check(DecisionMonitor.BreaksRoute(RouteId.Neutral,betrayed,new("optional-kill",new Dictionary<string,int?>{{"kills",9}},true)),"Reserved robot kill budget was ignored");
// Controller/enemy Step ordering at the original automatic boundary. A warning
// survives while talked0/mnfight1; once the attack/finale advances it is invalidated.
foreach(var mode in Enum.GetValues<DecisionMode>())foreach(bool controllerFirst in new[]{false,true})foreach(bool required in new[]{false,true}) {
    WarningState warning=new();bool talked=false;int con=0,alarms=0;
    void Controller(bool acknowledge){if(talked)warning=WarningSession.Apply(warning,WarningEvent.Clear).State;else if(acknowledge)warning=WarningSession.Apply(warning,WarningEvent.Acknowledge).State;}
    void Enemy(){if(talked)return;int code=required?(int)WarningCode.AutomaticSpare:0;var proposal=WarningSession.Apply(warning,WarningEvent.Propose,mode,code,"mett:boundary");warning=proposal.State;int disposition=DecisionPolicy.RatingResolution(mode,proposal.Refuse);if(disposition==1)return;talked=true;if(disposition==2)alarms++;else con=90;}
    if(controllerFirst){Controller(false);Enemy();}else{Enemy();Controller(false);}
    if(mode is DecisionMode.Passive or DecisionMode.Active && required){Check(!talked&&warning.Pending,"Premature scripted resolution");Controller(true);Enemy();}
    Check(talked,"Boundary never resumes");
    Check(mode==DecisionMode.Forced&&required?alarms==1&&con==0:con==90&&alarms==0,"Wrong original branch resumed");
}
var noFriend=With(With(basic,"target_neutral",2),"target_greeting",0);
Check(DecisionMonitor.BreaksRoute(RouteId.Neutral,noFriend,new("hangout-start",new Dictionary<string,int?>{{"neutral_undyne_friendship",1}},true)),"Native pre-hangout policy missing from C# risk API");
var callFriend=With(With(basic,"target_neutral",0),"target_greeting",1);
Check(DecisionMonitor.BreaksRoute(RouteId.Neutral,callFriend,new("leave-water",new Dictionary<string,int?>{{"water_opportunity_missed",1}},true)),"Optional friend call lost its water deadline");
var missing=With(With(With(basic,"snowman_piece_carried",0),"snowman_piece_available",0),"snowman_piece_stored",1);
Check(KeepsakeGuidance.Plan(missing,Language.English).StartsWith("Retrieve"),"Stored keepsake guidance");
Check(KeepsakeGuidance.Plan(With(missing,"inventory_space",0),Language.English).StartsWith("Make room"),"Full inventory guidance");
Check(KeepsakeGuidance.Plan(With(With(missing,"snowman_piece_stored",0),"snowman_piece_available",1),Language.English).StartsWith("Return"),"Snowman acquisition guidance");
Check(NeutralGoals.Evaluate(4,0,With(missing,"keepsake_recoverable",0)).Status==RouteStatus.BLOCKED,"Exhausted source must not claim recoverable keepsake");
// History is observed only; both ordinary RESET and TRUE RESET retain 962/963.
foreach(bool sold in new[]{false,true})foreach(bool erased in new[]{false,true})foreach(int end in new[]{0,1,2}) {
    var files=new Dictionary<string,string>();if(sold)files["system_information_963"]="synthetic";if(erased)files["system_information_962"]="synthetic";
    var h=new HistorySnapshot(new Dictionary<string,int>{{"General.Won",1},{"EndF.EndF",end}},files,true);
    Check(h.SoulSold==sold&&h.WorldErased==(erased&&!sold),"Source-backed permanent-file precedence");
    foreach(var kind in end>0?new[]{ResetKind.Reset,ResetKind.TrueReset}:new[]{ResetKind.Reset}){
        var result=HistoryTransitions.Preview(kind,h).Result;
        Check(result.PermanentFiles.SequenceEqual(h.PermanentFiles)&&result.HasFile8,"RESET changed permanent/file8 history");
        Check(result.PriorNeutralAvailable==(kind==ResetKind.Reset),"RESET prior completion handling");
    }
}
// Original-derived murder fixtures also verify the new transition executor's
// prefix function, independently of the shared route/evaluator tables.
var order=Numbers(root.GetProperty("murderFlagOrder"));
foreach(var row in root.GetProperty("murder").EnumerateArray()) {
    var values=Numbers(row[0]);var flags=order.Select((key,i)=>(key,values[i])).ToDictionary(x=>x.key,x=>x.Item2);
    Check(GenocideTransitionModel.MurderStage(flags)==row[1].GetInt32(),"Transition prefix differs from original GML");
}
for(int target=1;target<=18;target++) {
    var result=EndingReachability.Neutral(target);
    Check(result.Verdict==ReachabilityVerdict.ReachableInSourceModel&&result.Events.Count>5,"Missing ordered Neutral witness: "+target);
    Check((int)NeutralCatalog.Classify(result.FinalState!).Ending==target,"Transition witness ends in wrong original branch");
}
for(int target=0;target<=18;target++)for(int goal=1;goal<=8;goal++) {
    var r=EndingReachability.Neutral(target,goal);
    if(r.Verdict==ReachabilityVerdict.ReachableInSourceModel)Check(NeutralGoals.Evaluate(goal,target,r.FinalState!).Status==RouteStatus.ON_TRACK,"Invalid source-model goal witness");
}
foreach(bool sold in new[]{false,true})foreach(int choice in new[]{1,2}) {
    var p=EndingReachability.Pacifist(sold,choice);
    Check(RouteEvaluator.Evaluate(sold?RouteId.SoullessPacifist:RouteId.TruePacifist,p.FinalState!).Status==RouteStatus.ON_TRACK,"Ordered Pacifist witness missing prerequisites");
    var g=EndingReachability.Genocide(false,sold);
    Check(RouteEvaluator.Evaluate(sold?RouteId.SoullessGenocide:RouteId.Genocide,g.FinalState!).Status==RouteStatus.ON_TRACK,"Ordered Genocide witness missing prerequisites");
}
var late=GenocideTransitionModel.Witness(true);
Check(late.Flags[205]==40&&late.Flags[27]==1&&late.Stage==15,"NEO settlement must not undo its earlier abandonment decision");
Check(EndingReachability.Neutral(6,8).Verdict==ReachabilityVerdict.Unknown,"Unproven LV1/high-kill combination falsely proved");
Check(EndingReachability.Neutral(4,8).Verdict==ReachabilityVerdict.Unknown,"Post-friendship encounter availability ignored");
Check(EndingReachability.Neutral(3,8).Verdict==ReachabilityVerdict.Impossible,"Required boss EXP contradicts LV1");
var clean=new RunTransitionModel();clean.ResolveBoss(false);clean.Advance();clean.ResolveBoss(false);clean.Advance();clean.ResolveBoss(false);clean.GiveWater();clean.BefriendUndyne();clean.Advance();clean.BacktrackTo(1);
try{clean.KillOrdinary();throw new Exception("Jerry farming after clean friendship was invented");}catch(InvalidOperationException){checks++;}
try{var lost=new RunTransitionModel();lost.ResolveBoss(false);lost.Advance();lost.ResolveBoss(false);lost.Advance();lost.ResolveBoss(false);lost.MissWater();lost.BefriendUndyne();throw new Exception("Friendship after water deadline was invented");}catch(InvalidOperationException){checks++;}
foreach(var row in root.GetProperty("levels").EnumerateArray()){var n=Numbers(row);Check(RunTransitionModel.LevelForExperience(n[0])==n[1],"Original level thresholds differ from transition rewards");}
foreach(var row in root.GetProperty("suppression").EnumerateArray()){var n=Numbers(row);Check(RunTransitionModel.EncountersSuppressed(n[0],n[1],n[2])==(n[3]==1),"Original post-boss encounter availability differs");}
// Repeated qualification through Alarm6 -> writer completion -> User11 ->
// attack Step, using original-derived wrap outputs (turn25 wraps to20).
var attackMap=root.GetProperty("attackWrap").EnumerateArray().Select(Numbers).ToDictionary(x=>x[0]);
foreach(bool qualified in new[]{false,true})foreach(bool controllerFirst in new[]{false,true}) {
    int turns=18,alarms=0,opportunities=0;var warning=new WarningState();
    int ratings=qualified?12000:9000;
    for(int tick=0;tick<100;tick++) {
        if(controllerFirst)warning=WarningSession.Apply(warning,WarningEvent.Clear).State;
        bool qualifies=DecisionPolicy.RatingQualifies(turns,ratings);
        var proposal=WarningSession.Apply(warning,WarningEvent.Propose,DecisionMode.Forced,qualifies?20:0,"ex:"+tick);warning=proposal.State;
        int disposition=DecisionPolicy.RatingResolution(DecisionMode.Forced,proposal.Refuse);
        Check(!qualifies||disposition==2,"Forced qualification entered a finale or a permanent pause");
        alarms++;turns++; // Original Alarm6.
        // Original writer completion invokes User11, clearing talked before mnfight2.
        turns=attackMap[turns][1];opportunities++;
        if(!controllerFirst)warning=WarningSession.Apply(warning,WarningEvent.Clear).State;
    }
    Check(alarms==100&&opportunities==100&&turns is >=20 and <=24,"Attack scheduler did not return control");
    // This scheduler subset cannot establish HP/EXP/inventory preservation.
    // Those effects require the original VM and actual battle-event execution.
}
Check(!DecisionPolicy.BeforeAction(DecisionMode.Forced,new(RouteFamily.Neutral,DecisionAction.Fight,DecisionEnemy.Mettaton,ExperienceRisk:true,NeutralOutcome:-1)).Refuse,"Protected scripted spare must not prevent required FIGHT");
var reload=WarningSession.Apply(new WarningState(true,true,20,"battle",true,DecisionMode.Forced),WarningEvent.Clear).State;
Check(!reload.Pending&&!reload.Acknowledged,"Save/reload epoch retained stale warning acknowledgement");
var looxWitness=new RunTransitionModel();looxWitness.KillOrdinary();
Check(looxWitness.Snapshot()["experience"]==root.GetProperty("encounterRewards").GetProperty("Loox").GetInt32(),"Original Loox reward mismatch");
var vulkinWitness=new RunTransitionModel();vulkinWitness.ResolveBoss(false);vulkinWitness.Advance();vulkinWitness.ResolveBoss(false);vulkinWitness.Advance();vulkinWitness.ResolveBoss(false);vulkinWitness.Advance();vulkinWitness.KillOrdinary();
Check(vulkinWitness.Snapshot()["experience"]==root.GetProperty("encounterRewards").GetProperty("Vulkin").GetInt32(),"Original Vulkin reward mismatch");
Console.WriteLine($"PASS {checks} audit assertions (original-derived golden + ordered-event models); gameplay NOT_RUN");
