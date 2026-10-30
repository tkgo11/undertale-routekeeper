// Read-only export to an explicitly private directory for offline UI validation.
using System;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Security.Cryptography;
var target = Environment.GetEnvironmentVariable("ROUTEKEEPER_PREVIEW_FONT");
var privateRoot=Path.GetFullPath(Path.Combine(Path.GetDirectoryName(ScriptPath),"..",".research"));
if(string.IsNullOrEmpty(target)) throw new Exception("Private preview directory required.");
target=Path.GetFullPath(target);
var comparison=OperatingSystem.IsWindows()?StringComparison.OrdinalIgnoreCase:StringComparison.Ordinal;
if(!target.StartsWith(privateRoot+Path.DirectorySeparatorChar,comparison))
    throw new Exception("Preview export must remain below this repository's ignored .research directory.");
void RejectLinks(string path) {
    for(string current=Path.GetFullPath(path);current!=null;current=Path.GetDirectoryName(current)) {
        FileSystemInfo info=Directory.Exists(current)?new DirectoryInfo(current):new FileInfo(current);
        if(info.LinkTarget!=null || (info.Exists && info.Attributes.HasFlag(FileAttributes.ReparsePoint)))
            throw new Exception("Linked preview path refused.");
    }
}
RejectLinks(FilePath);RejectLinks(target);
foreach(var name in new[]{"page.png","glyphs.json"}) {
    var path=Path.Combine(target,name);RejectLinks(path);
    if(Path.Exists(path))throw new Exception("Preview outputs must be new; existing evidence is retained.");
}
string sourceHash;
using(var input=File.OpenRead(FilePath)) sourceHash=Convert.ToHexString(SHA256.HashData(input)).ToLowerInvariant();
if(sourceHash!="b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7") throw new Exception("Unverified preview input.");
Directory.CreateDirectory(target);
var font = Data.Fonts.ByName("fnt_maintext") ?? throw new Exception("Original English UI font missing.");
using(var stream=new FileStream(Path.Combine(target,"page.png"),FileMode.CreateNew,FileAccess.Write,FileShare.None)) font.Texture.TexturePage.TextureData.Image.SavePng(stream);
var glyphs=font.Glyphs.Select(g=>new { Code=(int)g.Character, X=font.Texture.SourceX+g.SourceX,Y=font.Texture.SourceY+g.SourceY,Width=g.SourceWidth,Height=g.SourceHeight,Advance=g.Shift,Offset=g.Offset });
using(var stream=new FileStream(Path.Combine(target,"glyphs.json"),FileMode.CreateNew,FileAccess.Write,FileShare.None))
    JsonSerializer.Serialize(stream,new{SourceHash=sourceHash,Font="fnt_maintext",Size=font.EmSize,Glyphs=glyphs});
Console.WriteLine("PASS private native font export; original resources unchanged.");
