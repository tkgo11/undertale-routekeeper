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
var adapterSources=new Dictionary<string,string>{{"decision_risk.gml",DecisionPolicy.EmitGml()},{"decision_budget.gml",DecisionPolicy.EmitBudgetGml()},{"decision_required.gml",DecisionPolicy.EmitRequiredGml()},{"decision_item.gml",DecisionPolicy.EmitItemGml()},{"decision_act.gml",DecisionPolicy.EmitActGml()}};
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
    using var ui=System.Text.Json.JsonDocument.Parse(File.ReadAllText(Path.Combine(uiDirectory,"ui","catalog.json")));
    var catalog=File.ReadAllText(Path.Combine(uiDirectory,"gml","ui_catalog.gml"));
    foreach(var entry in ui.RootElement.GetProperty("text").EnumerateObject())for(int language=0;language<2;language++) {
        var code=$"argument0 = \"{entry.Name}\"; argument1 = {language};\n"+catalog;
        if(new GmlObjectiveInterpreter(code,new Dictionary<string,int?>()).Run()!=entry.Value[language].GetString())throw new Exception("UI localization parity");
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
    var itemSource=$"argument0 = {item}; argument1 = {(present?1:0)};\n"+DecisionPolicy.EmitItemGml();
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
Console.WriteLine($"PASS {count} decision checks. Authentic runtime NOT_RUN.");
