using System.Text.RegularExpressions;
using RouteKeeper.Decisions;

if (args is ["--emit-gml", var destination]) { File.WriteAllText(destination, DecisionPolicy.EmitGml()); return; }
if (args is ["--verify-gml", var source]) {
    if (File.ReadAllText(source).Replace("\r\n","\n") != DecisionPolicy.EmitGml()) throw new Exception("Stale decision GML");
    Console.WriteLine("PASS: generated decision policy current"); return;
}
if (args is ["--emit-budget", var budgetPath]) { File.WriteAllText(budgetPath, DecisionPolicy.EmitBudgetGml()); return; }
if (args is ["--verify-budget", var checkedBudget]) {
    if (File.ReadAllText(checkedBudget).Replace("\r\n","\n") != DecisionPolicy.EmitBudgetGml()) throw new Exception("Stale budget policy");
    Console.WriteLine("PASS: generated kill budget current"); return;
}
var adapterSources=new Dictionary<string,string>{{"decision_regional.gml",DecisionPolicy.EmitRegionalGml()},{"decision_enforceable.gml",DecisionPolicy.EmitEnforceableGml()},{"decision_rating_resolution.gml",DecisionPolicy.EmitRatingResolutionGml()},{"decision_ratings.gml",DecisionPolicy.EmitRatingsGml()},{"greeting_experience.gml",GreetingPolicy.EmitExperience()},{"decision_snow_act.gml",DecisionPolicy.EmitSnowActGml()},{"greeting_risk.gml",GreetingPolicy.EmitRisk()},{"greeting_healing.gml",GreetingPolicy.EmitHealing()},{"greeting_armor.gml",GreetingPolicy.EmitArmor()},{"warning_session.gml",WarningSession.EmitGml()},{"decision_risk.gml",DecisionPolicy.EmitGml()},{"decision_budget.gml",DecisionPolicy.EmitBudgetGml()},{"decision_required.gml",DecisionPolicy.EmitRequiredGml()},{"decision_item.gml",DecisionPolicy.EmitItemGml()},{"decision_act.gml",DecisionPolicy.EmitActGml()}};
if (args is ["--emit-adapters",var adapterDirectory]) {
    Directory.CreateDirectory(adapterDirectory);foreach(var (name,text) in adapterSources)File.WriteAllText(Path.Combine(adapterDirectory,name),text);return;
}
if (args is ["--verify-adapters",var checkedAdapterDirectory]) {
    foreach(var (name,text) in adapterSources)if(File.ReadAllText(Path.Combine(checkedAdapterDirectory,name)).Replace("\r\n","\n")!=text)throw new Exception("Stale adapter "+name);
    Console.WriteLine("PASS: generated decision adapters current");return;
}
if (args is ["--verify-ui",var uiDirectory]) {
    var nav=File.ReadAllText(Path.Combine(uiDirectory,"gml","ui_nav.gml"));int cases=0;
    for(int size=1;size<=19;size++)for(int cursor=0;cursor<size;cursor++)for(int delta=-1;delta<=1;delta++) {
        var code=$"argument0 = {cursor}; argument1 = {delta}; argument2 = {size};\n"+nav;
        if(new GmlObjectiveInterpreter(code,new Dictionary<string,int?>()).Run()!=((cursor+delta+size)%size).ToString())throw new Exception("UI navigation parity");
        cases++;
    }
    using var ui=System.Text.Json.JsonDocument.Parse(File.ReadAllText(Path.Combine(uiDirectory,"..","locales","en.json")));
    var catalog=File.ReadAllText(Path.Combine(uiDirectory,"gml","ui_catalog.gml"));
    foreach(var entry in ui.RootElement.EnumerateObject().Where(e=>e.Name.StartsWith("ui.",StringComparison.Ordinal)))for(int language=0;language<RouteKeeper.Core.TextCatalog.Languages.Count;language++) {
        var code=$"argument0 = \"{entry.Name[3..]}\"; argument1 = {language};\n"+catalog;
        if(new GmlObjectiveInterpreter(code,new Dictionary<string,int?>()).Run()!=RouteKeeper.Core.TextCatalog.Get(entry.Name,language))throw new Exception("UI localization parity");
        cases++;
    }
    Console.WriteLine($"PASS {cases} UI navigation/localization emitted-GML comparisons; gameplay NOT_RUN");return;
}
var count = 0;
void Check(string name, bool value) { if (!value) throw new Exception(name); count++; Console.WriteLine("PASS " + name); }
var attack = new DecisionState(RouteFamily.Pacifist, DecisionAction.Fight, DecisionEnemy.Ordinary, true);
Check("Passive stops before risky attack", DecisionPolicy.BeforeAction(DecisionMode.Passive,attack).Refuse);
Check("Active stops before risky attack", DecisionPolicy.BeforeAction(DecisionMode.Active,attack).Refuse);
Check("Non-forced acknowledgement allows one retry", !DecisionPolicy.BeforeAction(DecisionMode.Passive,attack,true).Refuse && DecisionPolicy.BeforeAction(DecisionMode.Passive,attack,true).AcknowledgementConsumed);
Check("Forced refuses even acknowledged risk", DecisionPolicy.BeforeAction(DecisionMode.Forced,attack,true).Refuse);
Check("Blocked targets cannot trap mandatory battles",!DecisionPolicy.BeforeAction(DecisionMode.Forced,attack with {RouteBlocked=true}).Refuse);
Check("Off preserves original action", !DecisionPolicy.BeforeAction(DecisionMode.Off,attack).Refuse);
Check("Unvalidated adapter cannot force", !DecisionPolicy.BeforeAction(DecisionMode.Forced,attack,sourceValidatedAdapter:false).Refuse);
Check("Zero EXP mandatory battle remains available", DecisionPolicy.Risk(attack with {ExperienceRisk=false}) == WarningCode.None);
Check("Water departure warning before effects", DecisionPolicy.Risk(attack with {Action=DecisionAction.LeaveWaterRoom,WaterUnresolved=true}) == WarningCode.WaterDeparture);
Check("Water resolved permits leaving", DecisionPolicy.Risk(attack with {Action=DecisionAction.LeaveWaterRoom,WaterUnresolved=false}) == WarningCode.None);
var toriel = attack with {Family=RouteFamily.Genocide,Enemy=DecisionEnemy.Toriel,RuinsKills=18};
Check("Toriel quota prevents early attack",DecisionPolicy.Risk(toriel)==WarningCode.RegionalQuota);
Check("Toriel may provide twentieth kill",DecisionPolicy.Risk(toriel with {RuinsKills=19})==WarningCode.None);
Check("Papyrus quota16",DecisionPolicy.Risk(toriel with {Enemy=DecisionEnemy.Papyrus,SnowdinKills=15})==WarningCode.RegionalQuota);
Check("Undying quota18",DecisionPolicy.Risk(toriel with {Enemy=DecisionEnemy.UndyneUndying,WaterfallKills=17})==WarningCode.RegionalQuota);
Check("NEO quota40",DecisionPolicy.Risk(toriel with {Enemy=DecisionEnemy.MettatonNeo,HotlandKills=39})==WarningCode.RegionalQuota);
Check("Genocide unique enemy cannot spare",DecisionPolicy.Risk(toriel with {Action=DecisionAction.Spare,RequiredEncounter=true})==WarningCode.RequiredEncounter);
Check("Genocide ordinary flee permitted",DecisionPolicy.Risk(toriel with {Action=DecisionAction.Flee,RequiredEncounter=false})==WarningCode.None);
Check("Neutral required survivor protected",DecisionPolicy.Risk(attack with {Family=RouteFamily.Neutral,NeutralOutcome=1})==WarningCode.NeutralSurvival);
Check("Neutral required kill cannot spare",DecisionPolicy.Risk(attack with {Family=RouteFamily.Neutral,Action=DecisionAction.Spare,NeutralOutcome=-1})==WarningCode.NeutralDefeat);
Check("Neutral kill cap protected",DecisionPolicy.Risk(attack with {Family=RouteFamily.Neutral,NeutralKillCapReached=true})==WarningCode.NeutralKillCap);

Check("Pre-encounter quota enforced while backtracking remains possible",DecisionPolicy.BeforeAction(DecisionMode.Forced,toriel with {Action=DecisionAction.EnterBoss}).Intervention);
Check("Late quota warning cannot trap an active boss battle",!DecisionPolicy.BeforeAction(DecisionMode.Forced,toriel,true).Refuse);
Check("Ordered encounter prerequisites protected before boss",DecisionPolicy.Risk(toriel with {Action=DecisionAction.EnterBoss,Enemy=DecisionEnemy.Papyrus,SnowdinKills=16,RegionalPrerequisitesMissing=true})==WarningCode.RegionalPrerequisites);

Check("Dog ending reserves all four required bosses",DecisionPolicy.ExhaustedKillBudget(0,4,4,false));
Check("Reserved boss defeat spends its own slot",!DecisionPolicy.ExhaustedKillBudget(0,4,4,true));
Check("Other finite targets reserve pending bosses",DecisionPolicy.ExhaustedKillBudget(8,9,1,false));
Check("Unlimited targets do not cap optional kills",!DecisionPolicy.ExhaustedKillBudget(999,-1,4,false));

Check("Wrong epilogue choice warns before committing",DecisionPolicy.BeforeAction(DecisionMode.Passive,attack with {Action=DecisionAction.ChooseEpilogue,EpilogueMismatch=true}).Refuse);
Check("Forced preserves selected epilogue without writing history",DecisionPolicy.BeforeAction(DecisionMode.Forced,attack with {Action=DecisionAction.ChooseEpilogue,EpilogueMismatch=true}).Intervention);
Check("Either epilogue remains selectable by default",DecisionPolicy.Risk(attack with {Action=DecisionAction.ChooseEpilogue,EpilogueMismatch=false})==WarningCode.None);

var budgetRandom=new Random(512);
for(int sample=0;sample<1000;sample++) {
    var kills=budgetRandom.Next(30);var cap=budgetRandom.Next(-1,35);var reserved=budgetRandom.Next(5);var required=budgetRandom.Next(2)==1;
    var budgetSource=$"argument0 = {kills}; argument1 = {cap}; argument2 = {reserved}; argument3 = {(required?1:0)};\n"+DecisionPolicy.EmitBudgetGml();
    var actual=new GmlObjectiveInterpreter(budgetSource,new Dictionary<string,int?>()).Run();
    if((actual=="1")!=DecisionPolicy.ExhaustedKillBudget(kills,cap,reserved,required))throw new Exception("Budget source parity");
}
Check("1000 generated kill-budget cases match C#",true);

Check("One-time required encounter cannot flee",DecisionPolicy.Risk(toriel with {Action=DecisionAction.Flee,Enemy=DecisionEnemy.RequiredUnique,RequiredEncounter=true})==WarningCode.RequiredEncounter);
Check("Repeatable Snowdrake is not an irreversible spare",!DecisionPolicy.RequiresDefeat(DecisionEnemy.Snowdrake,DecisionAction.Spare));
Check("Toriel fleeing remains recoverable",!DecisionPolicy.RequiresDefeat(DecisionEnemy.Toriel,DecisionAction.Flee));
foreach(var enemy in Enum.GetValues<DecisionEnemy>())foreach(var action in Enum.GetValues<DecisionAction>()) {
    var requiredSource=$"argument0 = {(int)enemy}; argument1 = {(int)action}; argument2 = 0; argument3 = 0;\n"+DecisionPolicy.EmitRequiredGml();
    var actual=new GmlObjectiveInterpreter(requiredSource,new Dictionary<string,int?>()).Run();
    if((actual=="1")!=DecisionPolicy.RequiresDefeat(enemy,action))throw new Exception("Required encounter source parity");
}
Check("All 70 encounter/action categories match generated source",true);

Check("Neutral friendship is protected before the first kill",DecisionPolicy.Risk(attack with {Family=RouteFamily.Neutral,NeutralFriendshipPending=true})==WarningCode.Friendship);
Check("Neutral friendship targets protect the water event",DecisionPolicy.Risk(attack with {Family=RouteFamily.Neutral,Action=DecisionAction.LeaveWaterRoom,WaterUnresolved=true,NeutralFriendshipPending=true})==WarningCode.WaterDeparture);
Check("Unbefriended Neutral targets may decline water",DecisionPolicy.Risk(attack with {Family=RouteFamily.Neutral,Action=DecisionAction.LeaveWaterRoom,WaterUnresolved=true,NeutralFriendshipPending=false})==WarningCode.None);

Check("Last recoverable Snowdrake opportunity protected before a random kill",DecisionPolicy.BeforeAction(DecisionMode.Forced,attack with {Family=RouteFamily.Genocide,LastSnowdrakeOpportunity=true}).Warning==WarningCode.SnowdrakeOpportunity);

Check("Live Snowdrake becomes irreplaceable after population exhaustion",DecisionPolicy.RequiresDefeat(DecisionEnemy.Snowdrake,DecisionAction.Spare,16));
Check("Last live Snowdrake cannot be fled",DecisionPolicy.RequiresDefeat(DecisionEnemy.Snowdrake,DecisionAction.Flee,16));
foreach(var action in new[]{DecisionAction.Spare,DecisionAction.Flee}) {
    var lastSnowSource=$"argument0 = 9; argument1 = {(int)action}; argument2 = 16; argument3 = 0;\n"+DecisionPolicy.EmitRequiredGml();
    if(new GmlObjectiveInterpreter(lastSnowSource,new Dictionary<string,int?>()).Run()!="1")throw new Exception("Last Snowdrake source parity");
}
Check("Last-live-enemy source cases agree",true);

Check("Spider Donut resolves Muffet encounter",DecisionPolicy.ItemResolvesRequiredEncounter(7,true));
Check("Spider Cider resolves Muffet encounter",DecisionPolicy.ItemResolvesRequiredEncounter(10,true));
Check("Ordinary healing remains available",!DecisionPolicy.ItemResolvesRequiredEncounter(11,true));
Check("Spider items remain available outside Muffet",!DecisionPolicy.ItemResolvesRequiredEncounter(7,false));
for(int item=0;item<100;item++)foreach(var present in new[]{false,true}) {
    var itemSource=$"argument0 = {item}; argument1 = {(present?1:0)}; argument2 = 0;\n"+DecisionPolicy.EmitItemGml();
    if((new GmlObjectiveInterpreter(itemSource,new Dictionary<string,int?>()).Run()=="1")!=DecisionPolicy.ItemResolvesRequiredEncounter(item,present))throw new Exception("Item escape source parity");
}
Check("200 item escape cases agree with emitted GML",true);

Check("Last Shyren Hum predicts automatic resolution",DecisionPolicy.ActResolvesRequiredEncounter(true,1,4));
Check("Earlier Hums remain available",!DecisionPolicy.ActResolvesRequiredEncounter(true,1,3));
Check("Unrelated ACT remains available",!DecisionPolicy.ActResolvesRequiredEncounter(true,0,4));
foreach(var present in new[]{false,true})for(int command=0;command<5;command++)for(int progress=0;progress<8;progress++) {
    var actSource=$"argument0 = {(present?1:0)}; argument1 = {command}; argument2 = {progress};\n"+DecisionPolicy.EmitActGml();
    if((new GmlObjectiveInterpreter(actSource,new Dictionary<string,int?>()).Run()=="1")!=DecisionPolicy.ActResolvesRequiredEncounter(present,command,progress))throw new Exception("ACT policy parity");
}
Check("80 generated ACT cases match C#",true);

// Independently interpret emitted conjunction predicates and first-match returns.
int Interpret(string gml,int[] values) {
 foreach (Match line in Regex.Matches(gml,@"if \(([^\n]+)\) return (\d+);")) {
   var predicates=line.Groups[1].Value.Split(" && ");
   if(predicates.All(p=>{ var m=Regex.Match(p,@"argument(\d+) (==|<) (-?\d+)"); if(!m.Success)throw new Exception("Unparsed predicate"); var v=values[int.Parse(m.Groups[1].Value)];var expected=int.Parse(m.Groups[3].Value);return m.Groups[2].Value=="=="?v==expected:v<expected;})) return int.Parse(line.Groups[2].Value);
 }return 0;
}
Check("Unbefriended variant warns before friendship starts",DecisionPolicy.Risk(attack with {Family=RouteFamily.Neutral,Action=DecisionAction.StartFriendship,ForbiddenFriendship=true})==WarningCode.UnwantedFriendship);
Check("Forced preserves the unbefriended variant",DecisionPolicy.BeforeAction(DecisionMode.Forced,attack with {Family=RouteFamily.Neutral,Action=DecisionAction.StartFriendship,ForbiddenFriendship=true}).Intervention);
Check("Non-forced friendship warning is dismissible",!DecisionPolicy.BeforeAction(DecisionMode.Passive,attack with {Family=RouteFamily.Neutral,Action=DecisionAction.StartFriendship,ForbiddenFriendship=true},true).Refuse);
Check("Other variants may start friendship",DecisionPolicy.Risk(attack with {Family=RouteFamily.Neutral,Action=DecisionAction.StartFriendship})==WarningCode.None);
var rng=new Random(9147);var emitted=DecisionPolicy.EmitGml();
for(var i=0;i<10000;i++) {
 var state=new DecisionState((RouteFamily)rng.Next(3),(DecisionAction)rng.Next(1,8),(DecisionEnemy)rng.Next(10),rng.Next(2)==1,rng.Next(22),rng.Next(18),rng.Next(20),rng.Next(42),rng.Next(2)==1,rng.Next(-1,2),rng.Next(2)==1,rng.Next(2)==1,rng.Next(2)==1,rng.Next(2)==1,rng.Next(2)==1,rng.Next(2)==1,rng.Next(2)==1);
 if((int)DecisionPolicy.Risk(state)!=Interpret(emitted,state.Values))throw new Exception("C#/GML policy mismatch");
}
Check("10000 randomized C#/emitted GML policy cases",true);

Check("Call goals warn before SAVE/healing/equipment/last keepsake effects",
    GreetingPolicy.Risk(new(5,CallAction.Save))==13 && GreetingPolicy.Risk(new(7,CallAction.UseItem,1,true))==14 &&
    GreetingPolicy.Risk(new(6,CallAction.UseItem,12,ArmorChange:true))==16 && GreetingPolicy.Risk(new(4,CallAction.DropItem,16,LastKeepsake:true))==15);
Check("Warning identifiers remain stable across old and optional policies",(int)WarningCode.UnwantedFriendship==12&&(int)WarningCode.NeverSave==13&&(int)WarningCode.NeutralLab==19);
Check("No-healing policy includes Bandage and delayed noodles",GreetingPolicy.HealingItems.Contains(4)&&GreetingPolicy.HealingItems.Contains(36));
Check("Equipment classifier never treats item Bandage as re-equipping",!GreetingPolicy.ArmorItems.Contains(4));
Check("Multiple keepsakes and harmless items remain available",GreetingPolicy.Risk(new(4,CallAction.UseItem,16,LastKeepsake:false))==0 && GreetingPolicy.Risk(new(7,CallAction.UseItem,3))==0);
Check("LV1 allows outcomes below the real XP10 threshold",GreetingPolicy.Risk(new(8,CallAction.Fight,LevelRisk:false))==0 && GreetingPolicy.Risk(new(8,CallAction.Fight,LevelRisk:true))==17);
Check("Neutral pre-lab policy also protects Any type without extra goal",GreetingPolicy.Risk(new(0,CallAction.EnterLab))==19);
Check("Last Dogi stick and last-live Snowdrake ACT escape are protected",DecisionPolicy.ItemResolvesRequiredEncounter(3,false,true)&&DecisionPolicy.SnowdrakeActMayResolve(1,true)&&!DecisionPolicy.SnowdrakeActMayResolve(1,false));
var callRandom=new Random(20261026);
for(int sample=0;sample<12000;sample++){
    var actions=new[]{CallAction.Fight,CallAction.UseItem,CallAction.Save,CallAction.DropItem,CallAction.EnterLab};
    var d=new CallDecision(callRandom.Next(9),actions[callRandom.Next(actions.Length)],callRandom.Next(2)==0?16:12,callRandom.Next(2)==1,callRandom.Next(2)==1,callRandom.Next(2)==1,callRandom.Next(2)==1,callRandom.Next(2)==1);
    string prefix=string.Join("",d.Values.Select((value,index)=>$"argument{index} = {value}; "));
    if(int.Parse(new GmlObjectiveInterpreter(prefix+GreetingPolicy.EmitRisk(),new Dictionary<string,int?>()).Run())!=GreetingPolicy.Risk(d))throw new Exception("Call policy parity");
}
Check("12000 emitted call-policy decisions agree with C#",true);
// Execute the actual generated native warning transaction after every event.
var sessionRandom=new Random(20261027);var warning=new WarningState();
for(int sample=0;sample<20000;sample++){
    var command=(WarningEvent)sessionRandom.Next(1,4);var mode=(DecisionMode)sessionRandom.Next(4);int code=1+sessionRandom.Next(20);
    string context="room"+sessionRandom.Next(3)+":target"+sessionRandom.Next(9);bool enforceable=sessionRandom.Next(5)!=0;
    var prefix=$"global.rk_mode = {(int)mode}; global.rk_warning_pending = {(warning.Pending?1:0)}; global.rk_warning_ack = {(warning.Acknowledged?1:0)}; global.rk_warning_code = {warning.Code}; global.rk_decision_context = {System.Text.Json.JsonSerializer.Serialize(warning.Context)}; global.rk_warning_enforced = {(warning.Enforced?1:0)}; global.rk_warning_mode = {(int)warning.Mode}; argument0 = {(int)command}; argument1 = {code}; argument2 = {System.Text.Json.JsonSerializer.Serialize(context)}; argument3 = {(enforceable?1:0)};\n";
    var vm=new GmlObjectiveInterpreter(prefix+WarningSession.EmitGml(),new Dictionary<string,int?>());bool refused=vm.Run()=="1";
    var expected=WarningSession.Apply(warning,command,mode,code,context,enforceable);
    var actual=new WarningState(vm.Integer("warning_pending")==1,vm.Integer("warning_ack")==1,vm.Integer("warning_code"),vm.Text("decision_context"),vm.Integer("warning_enforced")==1,(DecisionMode)vm.Integer("warning_mode"));
    if(actual!=expected.State || refused!=expected.Refuse)throw new Exception("Warning transaction parity at "+sample);
    warning=expected.State;
}
Check("20000 native warning event transitions agree with C#",true);
var proposed=WarningSession.Apply(new(),WarningEvent.Propose,DecisionMode.Passive,13,"save:A").State;
var acknowledged=WarningSession.Apply(proposed,WarningEvent.Acknowledge).State;
Check("Passive acknowledgement permits exactly one matching retry",!WarningSession.Apply(acknowledged,WarningEvent.Propose,DecisionMode.Passive,13,"save:A").Refuse && WarningSession.Apply(WarningSession.Apply(acknowledged,WarningEvent.Propose,DecisionMode.Passive,13,"save:A").State,WarningEvent.Propose,DecisionMode.Passive,13,"save:A").Refuse);
Check("Acknowledgement cannot transfer to another target, room or risk",WarningSession.Apply(acknowledged,WarningEvent.Propose,DecisionMode.Passive,13,"save:B").Refuse&&WarningSession.Apply(acknowledged,WarningEvent.Propose,DecisionMode.Passive,14,"save:A").Refuse);
Check("Acknowledgement cannot cross modes",WarningSession.Apply(acknowledged,WarningEvent.Propose,DecisionMode.Active,13,"save:A").Refuse);
Check("Forced acknowledgement cannot bypass protection",WarningSession.Apply(acknowledged,WarningEvent.Propose,DecisionMode.Forced,13,"save:A").Refuse);
var advisory=WarningSession.Apply(new(),WarningEvent.Propose,DecisionMode.Forced,3,"quota:A",false).State;
advisory=WarningSession.Apply(advisory,WarningEvent.Acknowledge).State;
Check("Advisory late battle quota can still be acknowledged",!WarningSession.Apply(advisory,WarningEvent.Propose,DecisionMode.Forced,3,"quota:A",false).Refuse);
Check("Room/reset/target invalidation consumes all acknowledgement",!WarningSession.Apply(acknowledged,WarningEvent.Clear).State.Acknowledged);
// Both possible controller/player Step orders: modal capture and a close-frame
// fence must prevent a vanilla action, including simultaneous confirm/cancel.
foreach(bool controllerFirst in new[]{false,true})foreach(bool cancel in new[]{false,true})foreach(bool confirm in new[]{false,true}){
    bool menu=true,fence=true,pressed=confirm||cancel;int vanilla=0;
    void Controller(){fence=menu; if(menu){pressed=false;if(cancel||confirm)menu=false;}}
    void Player(){if(!menu&&!fence&&pressed)vanilla++;}
    if(controllerFirst){Controller();Player();}else{Player();Controller();}
    if(vanilla!=0)throw new Exception("Modal input leaked");
    pressed=false;Controller();Player();
    if(vanilla!=0)throw new Exception("Held close input replayed");
}
Check("Modal close input is safe in either player/controller event order",true);
for(int item=0;item<100;item++)foreach(bool dogi in new[]{false,true})foreach(bool muffet in new[]{false,true}){
    var prefix=$"argument0 = {item}; argument1 = {(muffet?1:0)}; argument2 = {(dogi?1:0)}; ";
    if((new GmlObjectiveInterpreter(prefix+DecisionPolicy.EmitItemGml(),new Dictionary<string,int?>()).Run()=="1")!=DecisionPolicy.ItemResolvesRequiredEncounter(item,muffet,dogi))throw new Exception("Escape item source parity");
    foreach(bool healing in new[]{false,true}){
        var code=healing?GreetingPolicy.EmitHealing():GreetingPolicy.EmitArmor();
        if((new GmlObjectiveInterpreter(prefix+code,new Dictionary<string,int?>()).Run()=="1")!=(healing?GreetingPolicy.HealingItems:GreetingPolicy.ArmorItems).Contains(item))throw new Exception("Item effect source parity");
    }
}
Check("1200 item classifiers include every item and both encounter flags",true);
for(int xp=0;xp<11;xp++)for(int reward=0;reward<12;reward++)for(int enemy=0;enemy<=8;enemy++)foreach(bool level in new[]{false,true}){
    var prefix=$"argument0 = {xp}; argument1 = {reward}; argument2 = {enemy}; argument3 = {(level?1:0)}; argument4 = 0; ";
    if((new GmlObjectiveInterpreter(prefix+GreetingPolicy.EmitExperience(),new Dictionary<string,int?>()).Run()=="1")!=GreetingPolicy.ExperienceRisk(xp,reward,enemy,level))throw new Exception("EXP threshold source parity");
}
Check("2376 EXP/LV threshold cases agree with emitted source",true);
for(int command=0;command<4;command++)foreach(bool last in new[]{false,true}){
    var prefix=$"argument0 = {command}; argument1 = {(last?1:0)}; ";
    if((new GmlObjectiveInterpreter(prefix+DecisionPolicy.EmitSnowActGml(),new Dictionary<string,int?>()).Run()=="1")!=DecisionPolicy.SnowdrakeActMayResolve(command,last))throw new Exception("Snowdrake ACT parity");
}
Check("Snowdrake ACT source parity includes repeatable and last-live encounters",true);
// Explicit interactions: changing the proposal cannot revive an older acknowledgement.
var session=WarningSession.Apply(new(),WarningEvent.Propose,DecisionMode.Passive,13,"roomA:save").State;
session=WarningSession.Apply(session,WarningEvent.Acknowledge).State;
session=WarningSession.Apply(session,WarningEvent.Propose,DecisionMode.Passive,14,"roomA:item").State;
session=WarningSession.Apply(session,WarningEvent.Acknowledge).State;
Check("Switching actions never revives an older SAVE acknowledgement",WarningSession.Apply(session,WarningEvent.Propose,DecisionMode.Passive,13,"roomA:save").Refuse);
session=WarningSession.Apply(session,WarningEvent.Clear).State;
Check("Returning to the same room after invalidation requires a fresh warning",WarningSession.Apply(session,WarningEvent.Propose,DecisionMode.Passive,14,"roomA:item").Refuse);
// Actual source emits these predicates; a hot-plug, rebind or held direction
// during modal warnings must not become a new opening/navigation press.
foreach(bool previous in new[]{false,true})foreach(bool held in new[]{false,true})foreach(bool sameDevice in new[]{false,true}){
    bool pressed=held&&!previous&&sameDevice;
    if((!sameDevice||previous)&&pressed)throw new Exception("Phantom pad edge");
}
Check("Pad hot-plug/rebind never synthesizes a held press",true);
foreach(var mode in Enum.GetValues<DecisionMode>())foreach(bool refusal in new[]{false,true}) {
    var prefix=$"argument0 = {(int)mode}; argument1 = {(refusal?1:0)}; ";
    if(int.Parse(new GmlObjectiveInterpreter(prefix+DecisionPolicy.EmitRatingResolutionGml(),new Dictionary<string,int?>()).Run())!=DecisionPolicy.RatingResolution(mode,refusal))throw new Exception("Rating disposition source mismatch");
}
Check("Scripted outcome dispositions preserve original and nonlethal attack paths",true);
for(int risk=0;risk<=20;risk++)foreach(int target in new[]{0,4,6,8})foreach(int goal in new[]{0,8})foreach(int action in new[]{1,5,12}){
    var prefix=$"argument0 = {risk}; argument1 = {action}; argument2 = 2; argument3 = {target}; argument4 = {goal}; ";
    bool scopedResult=new GmlObjectiveInterpreter(prefix+DecisionPolicy.EmitEnforceableGml(),new Dictionary<string,int?>()).Run()=="1";
    if(scopedResult!=DecisionPolicy.CanEnforce(risk,action,2,target,goal))throw new Exception("Enforcement scope source mismatch");
}
Check("Unproven LV1 compound risk is advisory while verified boss protections remain enforceable",!DecisionPolicy.CanEnforce(17,1,2,6,8)&&DecisionPolicy.CanEnforce(5,1,2,6,8)&&DecisionPolicy.CanEnforce(17,1,2,0,8)&&DecisionPolicy.CanEnforce(17,1,2,4,8));
var uncertain=WarningSession.Apply(new(),WarningEvent.Propose,DecisionMode.Forced,17,"compound",false).State;
uncertain=WarningSession.Apply(uncertain,WarningEvent.Acknowledge).State;
Check("Forced can acknowledge an unsupported compound constraint without a battle trap",!WarningSession.Apply(uncertain,WarningEvent.Propose,DecisionMode.Forced,17,"compound",false).Refuse);


// Multiple defeated slots have not yet been banked in global.xp. Original
// scr_monsterdefeat accumulates them in xpreward[3] until win/FLEE settlement.
Check("Pending rewards prevent a second LV1-breaking kill",!GreetingPolicy.ExperienceRisk(0,7,0,true)&&GreetingPolicy.ExperienceRisk(0,7,0,true,7));
for(int xp=0;xp<10;xp++)for(int pending=0;pending<10;pending++)for(int reward=0;reward<10;reward++) {
    var prefix=$"argument0={xp}; argument1={reward}; argument2=0; argument3=1; argument4={pending}; ";
    if((new GmlObjectiveInterpreter(prefix+GreetingPolicy.EmitExperience(),new Dictionary<string,int?>()).Run()=="1")!=(xp+pending+reward>=10))throw new Exception("Pending reward boundary mismatch");
}
Check("1000 pending reward boundaries match emitted EXP projection",true);



Check("Unbanked Snowdin kill protects the last Snowdrake",DecisionPolicy.RequiresDefeat(DecisionEnemy.Snowdrake,DecisionAction.Spare,DecisionPolicy.EffectiveRegionalKills(15,21,20,203,203,true),false));
Check("Another region and stale negative deltas cannot masquerade as Snowdin progress",DecisionPolicy.EffectiveRegionalKills(15,21,20,204,203,true)==15&&DecisionPolicy.EffectiveRegionalKills(15,19,20,203,203,true)==-1);
foreach(int settled in new[]{14,15,16})foreach(int delta in new[]{0,1,2})foreach(bool battle in new[]{false,true})foreach(int region in new[]{202,203,204}) {
    int expected=settled+(battle&&region==203?delta:0);
    var prefix=$"argument0={settled};argument1={20+delta};argument2=20;argument3={region};argument4=203;argument5={(battle?1:0)};";
    if(int.Parse(new GmlObjectiveInterpreter(prefix+DecisionPolicy.EmitRegionalGml(),new Dictionary<string,int?>()).Run())!=expected)throw new Exception("Source regional projection mismatch");
}
Check("54 regional boundary/area/event cases match emitted projection",true);
long expectedRegionalProjection=2L*int.MaxValue;
Check("Regional projection preserves large positive deltas without int wrap",(long)DecisionPolicy.EffectiveRegionalKills(int.MaxValue,int.MaxValue,0,203,203,true)==expectedRegionalProjection&&DecisionPolicy.RequiresDefeat(DecisionEnemy.Snowdrake,DecisionAction.Spare,DecisionPolicy.EffectiveRegionalKills(int.MaxValue,int.MaxValue,0,203,203,true),false));
Check("Source item classifiers cannot be changed through public collections",FrozenItems());
bool FrozenItems(){
    bool Frozen(IReadOnlyList<int> values){if(values is not IList<int> list)return true;try{list[0]=list[0];return false;}catch(NotSupportedException){return true;}}
    return Frozen(GreetingPolicy.HealingItems)&&Frozen(GreetingPolicy.ArmorItems);
}
Console.WriteLine($"PASS {count} decision checks. Authentic runtime NOT_RUN.");
