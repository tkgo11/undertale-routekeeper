// Read-only version diff. Emits resource names and signatures, never source/dialogue.
using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using UndertaleModLib;
EnsureDataLoaded();
var baselinePath = Environment.GetEnvironmentVariable("ROUTEKEEPER_COMPARE");
if (string.IsNullOrEmpty(baselinePath)) throw new Exception("ROUTEKEEPER_COMPARE baseline required.");
var baselineStream = File.OpenRead(baselinePath);
var baseline = UndertaleIO.Read(baselineStream);
string Hash(string text) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(text.Replace("\r\n","\n")))).ToLowerInvariant();
var oldCode = baseline.Code.ToDictionary(c=>c.Name.Content,c=>Hash(c.Disassemble(baseline.Variables,baseline.CodeLocals.For(c))));
var newCode = Data.Code.ToDictionary(c=>c.Name.Content,c=>Hash(c.Disassemble(Data.Variables,Data.CodeLocals.For(c))));
var codeChanges = oldCode.Keys.Union(newCode.Keys).OrderBy(x=>x).Where(name=>!oldCode.ContainsKey(name)||!newCode.ContainsKey(name)||oldCode[name]!=newCode[name])
 .Select(name=>new {Name=name,Before=oldCode.GetValueOrDefault(name),After=newCode.GetValueOrDefault(name)}).ToArray();
string ObjectEvents(UndertaleModLib.Models.UndertaleGameObject obj) => obj.Persistent+":"+obj.Visible+":"+
 string.Join("|",obj.Events.SelectMany((events,type)=>events.Select(e=>type+":"+e.EventSubtype+":"+string.Join(",",e.Actions.Select(a=>a.CodeId?.Name.Content)))));
var oldObjects=baseline.GameObjects.ToDictionary(x=>x.Name.Content,x=>Hash(ObjectEvents(x)));
var newObjects=Data.GameObjects.ToDictionary(x=>x.Name.Content,x=>Hash(ObjectEvents(x)));
var objectChanges=oldObjects.Keys.Union(newObjects.Keys).OrderBy(x=>x).Where(name=>!oldObjects.ContainsKey(name)||!newObjects.ContainsKey(name)||oldObjects[name]!=newObjects[name])
 .Select(name=>new {Name=name,Before=oldObjects.GetValueOrDefault(name),After=newObjects.GetValueOrDefault(name)}).ToArray();
Console.WriteLine(JsonSerializer.Serialize(new {Kind="RESOURCE_SIGNATURE_DIFF",Code=codeChanges,Objects=objectChanges,Note="Changed resource disassembly/event linkage; not gameplay verification."},new JsonSerializerOptions{WriteIndented=true}));

baselineStream.Dispose();
