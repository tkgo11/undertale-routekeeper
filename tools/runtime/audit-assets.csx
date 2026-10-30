// Read-only inventory of actual external audio File fields, not caster aliases.
using System;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Security.Cryptography;
using UndertaleModLib.Models;
EnsureDataLoaded();
var root=Environment.GetEnvironmentVariable("ROUTEKEEPER_RUNTIME_ROOT");
var report=Environment.GetEnvironmentVariable("ROUTEKEEPER_RUNTIME_REPORT");
if(string.IsNullOrWhiteSpace(root)||string.IsNullOrWhiteSpace(report))throw new Exception("Private runtime root/report paths are required.");
root=Path.GetFullPath(root);
report=Path.GetFullPath(report);
if(report.StartsWith(root+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)||Path.GetExtension(report)!=".json")throw new Exception("Report must be a new private JSON outside pristine inputs.");
var rows=Data.Sounds.Where(s=>!s.Flags.HasFlag(UndertaleSound.AudioEntryFlags.IsEmbedded)).Select(s=>{
    var relative=s.File?.Content ?? "";
    if(string.IsNullOrWhiteSpace(relative)||Path.IsPathRooted(relative)||relative.Split('/','\\').Any(p=>p==".."))throw new Exception("Unknown external sound path; inspect privately.");
    var path=Path.Combine(root,relative.Replace('\\',Path.DirectorySeparatorChar));
    string hash=null;
    if(File.Exists(path)){using(var stream=File.OpenRead(path))hash=Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant();}
    return new {Resource=s.Name.Content,File=relative,Present=File.Exists(path),Sha256=hash,s.AudioID,s.GroupID,EmbeddedBytes=s.AudioFile?.Data?.Length ?? 0,Flags=s.Flags.ToString()};
}).ToArray();
using(var output=new FileStream(report,FileMode.CreateNew,FileAccess.Write))JsonSerializer.Serialize(output,rows,new JsonSerializerOptions{WriteIndented=true});
int unresolved=rows.Count(r=>!r.Present&&r.EmbeddedBytes==0),review=rows.Count(r=>!r.Present&&r.EmbeddedBytes>0);
Console.WriteLine($"{(unresolved>0?"BLOCKED":review>0?"NOT_RUN":"OFFLINE_PASS")}: stream-flag inventory {rows.Length}; files present {rows.Count(r=>r.Present)}; embedded-reference review {review}; unresolved {unresolved}. Playback NOT_RUN.");
// A stream flag alone does not prove an external file is required. UTMT permits
// non-embedded sounds to reference arbitrary embedded entries; do not declare
// these references resolved (or demand extra files) without runner evidence.
if(unresolved>0)throw new Exception("Unresolved audio references; inspect private report before runtime claims.");
