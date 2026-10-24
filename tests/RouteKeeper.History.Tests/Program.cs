using RouteKeeper.History;
var passed = 0;
void Check(bool condition, string name) { if (!condition) throw new Exception(name); Console.WriteLine("PASS " + name); passed++; }
var ini = new Dictionary<string,int> { ["General.Won"] = 2, ["General.CP"] = 1, ["General.CH"] = 7, ["General.fun"] = 81, ["EndF.EndF"] = 1, ["reset.s_key"] = 1, ["Papyrus.PD"] = 3 };
var files = new Dictionary<string,string> { ["system_information_963"] = "synthetic-sha963", ["system_information_unknown"] = "synthetic-protected" };
var before = new HistorySnapshot(ini,files,true);
var reset = HistoryTransitions.Preview(ResetKind.Reset,before);
Check(reset.ClearsRunProgress && !reset.ReplacesIni, "Ordinary reset initializes run without replacing INI");
Check(reset.Result.PriorNeutralAvailable && reset.Result.Ini["Papyrus.PD"] == 3, "Ordinary reset retains prior ending and remembered friendship metadata");
Check(reset.Result.SoulSold && reset.Result.PermanentFiles.Count == 2, "Ordinary reset preserves all permanent history");
Check(reset.Result.HasFile8, "Ordinary reset retains file8");
var trueReset = HistoryTransitions.Preview(ResetKind.TrueReset,before);
Check(trueReset.ReplacesIni && trueReset.ClearsRunProgress, "True Reset replaces ordinary INI");
Check(!trueReset.Result.PriorNeutralAvailable && !trueReset.Result.TrueResetAvailable, "True Reset removes playable prior-ending prerequisite");
Check(trueReset.Result.Ini["General.BW"] == 2 && trueReset.Result.Ini["General.BP"] == 1 && trueReset.Result.Ini["General.BH"] == 7, "True Reset retains border unlock backups separately");
Check(trueReset.Result.Ini["reset.s_key"] == 1 && trueReset.Result.Ini["reset.reset"] == 1, "True Reset retains secret key and reset marker");
Check(!trueReset.Result.Ini.ContainsKey("Papyrus.PD"), "True Reset clears remembered ordinary friendship");
Check(trueReset.Result.PermanentFiles.SequenceEqual(before.PermanentFiles) && trueReset.Result.SoulSold, "True Reset cannot remove sold soul or unknown permanent files");
Check(trueReset.Result.HasFile8, "True Reset retains persistent Flowey encounter file8");
Check(trueReset.NewFunValueRequired && !trueReset.Result.Ini.ContainsKey("General.fun"), "Random fun value remains unspecified");
Check(before.Ini.ContainsKey("General.fun") && before.PriorNeutralAvailable, "Preview leaves source snapshot intact");
ini["General.Won"] = 99;files.Clear();
Check(before.Ini["General.Won"] == 2 && before.SoulSold, "Observed snapshots defensively copy mutable inputs");
var erased = new HistorySnapshot(new Dictionary<string,int>(),new Dictionary<string,string>{{"system_information_962","synthetic"}},false);
Check(erased.WorldErased && !erased.SoulSold, "World erasure distinct from restored sold soul");
try { HistoryTransitions.Preview(ResetKind.TrueReset,erased); throw new Exception("Unsupported True Reset accepted"); } catch (InvalidOperationException) { passed++; }
Check(HistoryTransitions.Preview(ResetKind.Reset,erased).Result.WorldErased, "Ordinary reset cannot restore an erased world");
Console.WriteLine($"PASS {passed} history transition checks; actual RESET runtime NOT_RUN");
