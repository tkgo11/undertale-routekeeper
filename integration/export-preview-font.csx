// Read-only export to an explicitly private directory for offline UI validation.
using System;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Security.Cryptography;
var target = Environment.GetEnvironmentVariable("ROUTEKEEPER_PREVIEW_FONT");
if (string.IsNullOrEmpty(target) || !Path.GetFullPath(target).Contains(Path.DirectorySeparatorChar+".research"+Path.DirectorySeparatorChar))
    throw new Exception("Preview font export requires an ignored .research directory.");
string sourceHash;
using(var input=File.OpenRead(FilePath)) sourceHash=Convert.ToHexString(SHA256.HashData(input)).ToLowerInvariant();
if(sourceHash!="b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7") throw new Exception("Unverified preview input.");
Directory.CreateDirectory(target);
var font = Data.Fonts.ByName("fnt_maintext") ?? throw new Exception("Original English UI font missing.");
using(var stream=File.Create(Path.Combine(target,"page.png"))) font.Texture.TexturePage.TextureData.Image.SavePng(stream);
var glyphs=font.Glyphs.Select(g=>new { Code=(int)g.Character, X=font.Texture.SourceX+g.SourceX,Y=font.Texture.SourceY+g.SourceY,Width=g.SourceWidth,Height=g.SourceHeight,Advance=g.Shift,Offset=g.Offset });
File.WriteAllText(Path.Combine(target,"glyphs.json"),JsonSerializer.Serialize(new{SourceHash=sourceHash,Font="fnt_maintext",Size=font.EmSize,Glyphs=glyphs}));
Console.WriteLine("PASS private native font export; original resources unchanged.");
