using System.Text;
using System.Text.Json;
using RouteKeeper.Tool;

// Explicit synthetic compiler subprocess; no actual GML/game execution here.
var mockFixture=Environment.GetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_COMPILER");
if(mockFixture is not null && args.FirstOrDefault() is "--version" or "load") {
    if(args[0]=="--version"){Console.WriteLine(Environment.GetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_VERSION")??"0.9.2.0");return 0;}
    if(Environment.GetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_DIAGNOSTICS")=="1"){
        string diagnostic=new('x',8192);
        for(int n=0;n<256;n++){Console.Error.Write(diagnostic);Console.Out.Write(diagnostic);}
    }
    int outputIndex=Array.IndexOf(args,"-o");
    if(outputIndex>=0)File.Copy(mockFixture,args[outputIndex+1],false);
    return 0;
}
string PhysicalDirectory(string path) {
    string full=Path.GetFullPath(path),current=Path.GetPathRoot(full)!;
    foreach(var part in full[current.Length..].Split(new[]{Path.DirectorySeparatorChar,Path.AltDirectorySeparatorChar},StringSplitOptions.RemoveEmptyEntries)) {
        var next=Path.Combine(current,part);current=new DirectoryInfo(next).ResolveLinkTarget(true)?.FullName??next;
    }
    return current;
}
string root = Path.Combine(PhysicalDirectory(Path.GetTempPath()), "routekeeper-tests-" + Guid.NewGuid().ToString("N"));
Directory.CreateDirectory(root);
int passed = 0;
try
{
    byte[] Data(byte marker)
    {
        using var memory = new MemoryStream(); using var writer = new BinaryWriter(memory);
        writer.Write(Encoding.ASCII.GetBytes("FORM")); writer.Write(18u);
        writer.Write(Encoding.ASCII.GetBytes("GEN8")); writer.Write(2u); writer.Write((byte)0); writer.Write((byte)16);
        writer.Write(Encoding.ASCII.GetBytes("TEST")); writer.Write(0u);
        var result = memory.ToArray(); result[16] = marker; return result;
    }
    string original = Path.Combine(root, "data.win"), candidate = Path.Combine(root, "patched.win");
    File.WriteAllBytes(original, Data(0)); File.WriteAllBytes(candidate, Data(1));
    var identity = BuildInspector.Inspect(original);
    var profile = new CompatibilityProfile("synthetic-only", "VerifiedPatch", "Synthetic", "test", identity.Size, identity.Sha256, identity.Md5, identity.BytecodeVersion, BuildInspector.StructuralHash(identity), SafeInstaller.Hash(candidate));
    void Check(string name, Action action) { action(); passed++; Console.WriteLine("PASS " + name); }
    void Assert(bool ok) { if (!ok) throw new Exception("Assertion failed"); }
    void Reject(Action action) { try { action(); } catch (Exception ex) when (ex is InvalidOperationException or InvalidDataException or IOException) { return; } throw new Exception("Expected rejection"); }
    Check("Child output is fully drained with a bounded prefix at adjacent boundaries",()=>{
        foreach(int size in new[]{0,1,4095,4096,8191,8192,8193,65537}){
            using var reader=new StringReader(new string('x',size));
            var result=ProcessOutput.DrainAsync(reader,8192).GetAwaiter().GetResult();
            Assert(result.Prefix==new string('x',Math.Min(size,8192))&&result.Truncated==(size>8192)&&reader.Read()==-1);
        }
        using var discarded=new StringReader(new string('y',100000));
        Assert(ProcessOutput.DrainAsync(discarded).GetAwaiter().GetResult()==new ProcessOutput.Result("",true)&&discarded.Read()==-1);
    });
    Check("FORM identity, bytecode, hashes", () => Assert(identity.Size == 26 && identity.BytecodeVersion == 16 && identity.Chunks.Count == 2 && identity.Sha256.Length == 64 && identity.Md5.Length == 32));
    Check("chunk diff sees modified data", () => Assert(BuildInspector.Diff(identity, BuildInspector.Inspect(candidate)).Count == 1));
    Check("unknown build denied", () => Reject(() => CompatibilityRegistry.RequireVerified(identity, [], "Synthetic", "test")));
    Check("inspection-only profile denied", () => Reject(() => CompatibilityRegistry.RequireVerified(identity, [profile with { Status = "InspectedOnly" }], "Synthetic", "test")));
    Check("platform mismatch denied", () => Reject(() => CompatibilityRegistry.RequireVerified(identity, [profile], "Windows", "x64")));
    Check("structural signature mismatch denied", () => Reject(() => CompatibilityRegistry.RequireVerified(identity, [profile with { StructuralSha256 = new string('0', 64) }], "Synthetic", "test")));
    Check("ambiguous profiles denied", () => Reject(() => CompatibilityRegistry.RequireVerified(identity, [profile, profile], "Synthetic", "test")));
    Check("same-file candidate rejected before backup", () => { Reject(() => SafeInstaller.Install(original, original, [profile], "Synthetic", "test")); Assert(!File.Exists(original + ".routekeeper-original")); });
    Check("wrong output hash rejected without target mutation", () => { Reject(() => SafeInstaller.Install(original, candidate, [profile with { PatchedSha256 = new string('0', 64) }], "Synthetic", "test")); Assert(SafeInstaller.Hash(original) == identity.Sha256 && !File.Exists(original + ".routekeeper-original")); });
    Check("exclusive lock prevents concurrent installers", () => { using var held = new FileStream(original + ".routekeeper-lock", FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None); Reject(() => SafeInstaller.Install(original, candidate, [profile], "Synthetic", "test")); Assert(SafeInstaller.Hash(original) == identity.Sha256); });
    string save = Path.Combine(root, "file0"); File.WriteAllText(save, "synthetic save unchanged");
    if (!OperatingSystem.IsWindows()) {
        Check("ancestor-linked installation refused before sidecars", () => {
            string physical=Path.Combine(root,"ancestor-physical"),alias=Path.Combine(root,"ancestor-alias");
            Directory.CreateDirectory(physical);File.WriteAllBytes(Path.Combine(physical,"data.win"),Data(0));
            Directory.CreateSymbolicLink(alias,physical);
            Reject(()=>SafeInstaller.Install(Path.Combine(alias,"data.win"),candidate,[profile],"Synthetic","test"));
            Assert(Directory.GetFiles(physical).Length==1&&SafeInstaller.Hash(Path.Combine(physical,"data.win"))==identity.Sha256);
        });
        Check("ancestor-linked candidate refused before target sidecars", () => {
            string physical=Path.Combine(root,"candidate-physical"),alias=Path.Combine(root,"candidate-alias");
            Directory.CreateDirectory(physical);File.WriteAllBytes(Path.Combine(physical,"candidate.win"),Data(1));Directory.CreateSymbolicLink(alias,physical);
            Reject(()=>SafeInstaller.Install(original,Path.Combine(alias,"candidate.win"),[profile],"Synthetic","test"));
            Assert(SafeInstaller.Hash(original)==identity.Sha256&&!File.Exists(original+".routekeeper-original"));
        });
        Check("ancestor-linked restore refused without external mutations", () => {
            string physical=Path.Combine(root,"restore-physical"),alias=Path.Combine(root,"restore-alias");
            Directory.CreateDirectory(physical);string target=Path.Combine(physical,"data.win");File.WriteAllBytes(target,Data(0));
            SafeInstaller.Install(target,candidate,[profile],"Synthetic","test");Directory.CreateSymbolicLink(alias,physical);
            Reject(()=>SafeInstaller.Restore(Path.Combine(alias,"data.win")));Assert(SafeInstaller.Hash(target)==profile.PatchedSha256);
        });
    } else Console.WriteLine("NOT_RUN ancestor symlink reproduction: native link permission required");
    Check("verified install backs up pristine original", () => { SafeInstaller.Install(original, candidate, [profile], "Synthetic", "test"); Assert(SafeInstaller.Hash(original) == profile.PatchedSha256 && SafeInstaller.Hash(original + ".routekeeper-original") == identity.Sha256); });
    Check("idempotent reinstall", () => { SafeInstaller.Install(original, candidate, [profile], "Synthetic", "test"); Assert(SafeInstaller.Hash(original + ".routekeeper-original") == identity.Sha256); });
    Check("restore and repeated restore", () => { SafeInstaller.Restore(original); SafeInstaller.Restore(original); Assert(SafeInstaller.Hash(original) == identity.Sha256); });
    Check("save untouched", () => Assert(File.ReadAllText(save) == "synthetic save unchanged"));
    Check("update keeps original", () => { File.WriteAllBytes(candidate, Data(2)); var updated = profile with { PatchedSha256 = SafeInstaller.Hash(candidate) }; SafeInstaller.Install(original, candidate, [updated], "Synthetic", "test"); Assert(SafeInstaller.Hash(original) == updated.PatchedSha256 && SafeInstaller.Hash(original + ".routekeeper-original") == identity.Sha256); });
    Check("external mod blocks restore", () => { File.WriteAllBytes(original, Data(3)); Reject(() => SafeInstaller.Restore(original)); Assert(File.ReadAllBytes(original)[16] == 3); });
    Check("corrupt backup blocks restore", () => { File.WriteAllBytes(original, Data(2)); File.WriteAllBytes(original + ".routekeeper-original", Data(4)); Reject(() => SafeInstaller.Restore(original)); Assert(File.ReadAllBytes(original)[16] == 2); });
    Check("truncated FORM rejected", () => { var path = Path.Combine(root, "bad.win"); File.WriteAllBytes(path, [70, 79, 82, 77]); Reject(() => BuildInspector.Inspect(path)); });
    Check("oversized chunk rejected", () => { var path = Path.Combine(root, "bad.win"); var bytes = Data(0); bytes[12] = 250; File.WriteAllBytes(path, bytes); Reject(() => BuildInspector.Inspect(path)); });
    Check("pending update before replacement can restore", () => { File.WriteAllBytes(original + ".routekeeper-original", Data(0)); File.WriteAllBytes(original, Data(1)); var pending = new InstallJournal(1, identity.Sha256, SafeInstaller.Hash(candidate), profile.Id, "Pending", SafeInstaller.Hash(original)); File.WriteAllText(original + ".routekeeper.json", JsonSerializer.Serialize(pending)); SafeInstaller.Restore(original); Assert(SafeInstaller.Hash(original) == identity.Sha256); });
    if (!OperatingSystem.IsWindows()) Check("symbolic-link target rejected", () => { string link = Path.Combine(root, "linked.win"); File.CreateSymbolicLink(link, original); Reject(() => SafeInstaller.Install(link, candidate, [profile], "Synthetic", "test")); });
    else Console.WriteLine("NOT_RUN symbolic-link target: native link permission required");
    Check("duplicate GEN8 rejected", () => { string path = Path.Combine(root, "bad.win"); var data = Data(0); Encoding.ASCII.GetBytes("GEN8").CopyTo(data, 18); File.WriteAllBytes(path, data); Reject(() => BuildInspector.Inspect(path)); });
    Check("malformed journal fails closed", () => { File.WriteAllText(original + ".routekeeper.json", "{\"SchemaVersion\":1}"); Reject(() => SafeInstaller.Restore(original)); Assert(SafeInstaller.Hash(original) == identity.Sha256); });
    Check("Steam library discovery returns unverified metadata only", () =>
    {
        string steam = Path.Combine(root, "Steam"), library = Path.Combine(root, "ExtraLibrary");
        Directory.CreateDirectory(Path.Combine(steam, "steamapps"));
        string app = Path.Combine(library, "steamapps");
        string game = Path.Combine(app, "common", "Undertale");
        Directory.CreateDirectory(game);
        File.WriteAllText(Path.Combine(steam, "steamapps", "libraryfolders.vdf"), "\"libraryfolders\" { \"1\" { \"path\" \"" + library.Replace("\\", "\\\\", StringComparison.Ordinal) + "\" } }");
        File.WriteAllText(Path.Combine(app, "appmanifest_391540.acf"), "\"AppState\" { \"buildid\" \"123456\" }");
        File.WriteAllBytes(Path.Combine(game, "data.win"), Data(0));
        var found = SteamDiscovery.Discover([steam]);
        Assert(found.Count == 1 && found[0].BuildId == "123456" && found[0].Status == "UnverifiedCandidate");
    });
    string runner=Path.Combine(root,"runner.bin");
    void LE16(byte[] bytes,int offset,ushort value)=>System.Buffers.Binary.BinaryPrimitives.WriteUInt16LittleEndian(bytes.AsSpan(offset),value);
    void LE32(byte[] bytes,int offset,uint value)=>System.Buffers.Binary.BinaryPrimitives.WriteUInt32LittleEndian(bytes.AsSpan(offset),value);
    void BE32(byte[] bytes,int offset,uint value)=>System.Buffers.Binary.BinaryPrimitives.WriteUInt32BigEndian(bytes.AsSpan(offset),value);
    byte[] PE(ushort machine) {
        var bytes=new byte[128];bytes[0]=77;bytes[1]=90;LE32(bytes,0x3c,64);
        bytes[64]=80;bytes[65]=69;LE16(bytes,68,machine);return bytes;
    }
    foreach(var (machine,arch) in new[]{((ushort)0x14c,"x86"),((ushort)0x8664,"x64"),((ushort)0xaa64,"arm64")})
        Check("PE header "+arch,()=>{File.WriteAllBytes(runner,PE(machine));var r=ExecutableInspector.Inspect(runner);Assert(r.Architectures.Single()==arch&&r.Verification=="HeaderOnly_NotGameProvenance");});
    Check("Bad PE signature denied",()=>{var bytes=PE(0x8664);bytes[64]=0;File.WriteAllBytes(runner,bytes);Reject(()=>ExecutableInspector.Inspect(runner));});
    Check("PE offset beyond file denied",()=>{var bytes=PE(0x8664);LE32(bytes,0x3c,uint.MaxValue);File.WriteAllBytes(runner,bytes);Reject(()=>ExecutableInspector.Inspect(runner));});
    byte[] ELF(byte width,ushort machine) {
        var bytes=new byte[width==1?52:64];new byte[]{127,69,76,70}.CopyTo(bytes,0);
        bytes[4]=width;bytes[5]=1;bytes[6]=1;LE16(bytes,18,machine);LE32(bytes,20,1);LE16(bytes,width==1?40:52,(ushort)bytes.Length);return bytes;
    }
    foreach(var (width,machine,arch) in new[]{((byte)1,(ushort)3,"x86"),((byte)2,(ushort)62,"x64"),((byte)2,(ushort)183,"arm64")})
        Check("ELF header "+arch+" retains OS uncertainty",()=>{File.WriteAllBytes(runner,ELF(width,machine));var r=ExecutableInspector.Inspect(runner);Assert(r.Architectures.Single()==arch&&r.PlatformFamily=="ELFUnix");});
    Check("ELF machine width mismatch denied",()=>{File.WriteAllBytes(runner,ELF(1,62));Reject(()=>ExecutableInspector.Inspect(runner));});
    Check("Linux-specific ELF ABI recorded",()=>{var bytes=ELF(2,62);bytes[7]=3;File.WriteAllBytes(runner,bytes);Assert(ExecutableInspector.Inspect(runner).PlatformFamily=="LinuxABI");});
    byte[] Mach(uint cpu) {var bytes=new byte[32];LE32(bytes,0,0xfeedfacf);LE32(bytes,4,cpu);return bytes;}
    Check("Thin Mach-O arm64 header",()=>{File.WriteAllBytes(runner,Mach(0x0100000c));Assert(ExecutableInspector.Inspect(runner).Architectures.Single()=="arm64");});
    Check("Mach-O universal preserves both architectures",()=>{
        var bytes=new byte[128];BE32(bytes,0,0xcafebabe);BE32(bytes,4,2);
        BE32(bytes,8,0x01000007);BE32(bytes,16,64);BE32(bytes,20,32);
        BE32(bytes,28,0x0100000c);BE32(bytes,36,96);BE32(bytes,40,32);
        Mach(0x01000007).CopyTo(bytes,64);Mach(0x0100000c).CopyTo(bytes,96);
        File.WriteAllBytes(runner,bytes);Assert(ExecutableInspector.Inspect(runner).Architectures.SequenceEqual(new[]{"x64","arm64"}));
        BE32(bytes,36,999999);File.WriteAllBytes(runner,bytes);Reject(()=>ExecutableInspector.Inspect(runner));
    });
    Check("Java magic cannot masquerade as a universal runner",()=>{var bytes=new byte[128];BE32(bytes,0,0xcafebabe);BE32(bytes,4,61);File.WriteAllBytes(runner,bytes);Reject(()=>ExecutableInspector.Inspect(runner));});
    Check("Candidate builder refuses source overwrite before compiler invocation",()=>Reject(()=>ModBuilder.BuildAsync(original,original,"missing-compiler",root).GetAwaiter().GetResult()));
    Check("Candidate builder refuses an existing output",()=>Reject(()=>ModBuilder.BuildAsync(original,candidate,"missing-compiler",root).GetAwaiter().GetResult()));
    string buildAssets=Path.Combine(root,"build-assets");Directory.CreateDirectory(Path.Combine(buildAssets,"profiles"));
    File.WriteAllText(Path.Combine(buildAssets,"profiles","registry.json"),"[]");
    Check("Unknown input cannot create a candidate or invoke a compiler",()=>{
        var destination=Path.Combine(root,"never-created","candidate.win");
        Reject(()=>ModBuilder.BuildAsync(original,destination,"missing-compiler",buildAssets).GetAwaiter().GetResult());
        Assert(!Directory.Exists(Path.GetDirectoryName(destination)));
    });
    File.WriteAllText(Path.Combine(buildAssets,"profiles","registry.json"),JsonSerializer.Serialize(new[]{profile with {Status="InspectedOnly"}}));
    Check("Source installation rejects diagnostic profiles before compiler invocation",()=>{
        var before=Directory.GetFiles(root).Order().ToArray();
        Reject(()=>SourceInstaller.InstallAsync(original,"missing-compiler","Synthetic","test",buildAssets).GetAwaiter().GetResult());
        Assert(before.SequenceEqual(Directory.GetFiles(root).Order())&&SafeInstaller.Hash(original)==identity.Sha256);
    });
    Check("G3M config pins both original and patch SHA256",()=>{
        using var config=JsonDocument.Parse(G3MPackage.Config(identity.Sha256,new string('a',64),"data.win"));
        var item=config.RootElement.GetProperty("files")[0];
        Assert(config.RootElement.GetProperty("config_version").GetString()=="2.0.0" && item.GetProperty("target").GetString()=="${game_path}/data.win" && item.GetProperty("target_hash").GetString()=="sha256:"+identity.Sha256 && item.GetProperty("source_hash").GetString()=="sha256:"+new string('a',64));
    });
    Check("G3M malformed hashes rejected",()=>{try{G3MPackage.Config("../data.win",new string('a',64),"data.win");throw new Exception("Expected refusal");}catch(ArgumentException){}});
    Check("G3M rejects trailing newlines and Windows path aliases",()=>{
        foreach(string path in new[]{"data.win\n","CON/data.win","a./game.unx","a /game.ios","NUL.txt/data.win","com1/data.win","a/LPT9.any/data.win"}){
            bool refused=false;try{G3MPackage.Config(identity.Sha256,new string('a',64),path);}catch(ArgumentException){refused=true;}
            Assert(refused);
        }
        foreach(string hash in new[]{identity.Sha256+"\n",new string('A',64),new string('a',63)}){
            bool refused=false;try{G3MPackage.Config(hash,new string('a',64),"data.win");}catch(ArgumentException){refused=true;}
            Assert(refused);
        }
        _=G3MPackage.Config(identity.Sha256,new string('a',64),"Undertale.app/Contents/Resources/game.ios");
    });
    Check("G3M rejects traversal paths",()=>{try{G3MPackage.Config(identity.Sha256,new string('a',64),"../data.win");throw new Exception("Expected refusal");}catch(ArgumentException){}});
    Check("G3M refuses an unverified game before starting external tools",()=>{
        var output=Path.Combine(root,"not-created","mod.zip");
        Reject(()=>G3MPackage.CreateAsync(original,candidate,"missing-xdelta",output,[profile with {Status="InspectedOnly"}],"Synthetic","test").GetAwaiter().GetResult());
        Assert(!Directory.Exists(Path.GetDirectoryName(output)));
    });
    Check("G3M requires verified relative data location",()=>{
        var output=Path.Combine(root,"missing-location","mod.zip");
        Reject(()=>G3MPackage.CreateAsync(original,candidate,"missing-xdelta",output,[profile],"Synthetic","test").GetAwaiter().GetResult());
        Assert(!Directory.Exists(Path.GetDirectoryName(output)));
    });
    Check("G3M candidate hash mismatch fails before creating workspace",()=>{
        var output=Path.Combine(root,"wrong-g3m-output","mod.zip");
        Reject(()=>G3MPackage.CreateAsync(original,candidate,"missing-xdelta",output,[profile with {GameDataRelativePath="data.win",PatchedSha256=new string('0',64)}],"Synthetic","test").GetAwaiter().GetResult());
        Assert(!Directory.Exists(Path.GetDirectoryName(output)));
    });
    Check("Native verification cannot omit the exact runner pin",()=>Reject(()=>CompatibilityRegistry.RequireVerified(identity,[profile with {Platform="Windows",Architecture="x86"}],"Windows","x86")));
    string gateDir=Path.Combine(root,"runner-gate");Directory.CreateDirectory(gateDir);
    string gateData=Path.Combine(gateDir,"data.win"),gateCandidate=Path.Combine(gateDir,"candidate.win"),gateExe=Path.Combine(gateDir,"UNDERTALE.exe");
    File.WriteAllBytes(gateData,Data(0));File.WriteAllBytes(gateCandidate,Data(1));
    var exact=profile with {Platform="Windows",Architecture="x86",ExecutableRelativePath="UNDERTALE.exe",ExecutableSha256=new string('0',64)};
    Check("Pinned runner must exist before backup or replacement",()=>{Reject(()=>SafeInstaller.Install(gateData,gateCandidate,[exact],"Windows","x86"));Assert(!File.Exists(gateData+".routekeeper-original")&&SafeInstaller.Hash(gateData)==identity.Sha256);});
    File.WriteAllBytes(gateExe,PE(0x14c));exact=exact with {ExecutableSha256=SafeInstaller.Hash(gateExe)};
    Check("Exact PE runner passes hash and architecture gates",()=>SafeInstaller.ValidateRunner(gateData,exact));
    Check("Same data with different runner is rejected",()=>Reject(()=>SafeInstaller.ValidateRunner(gateData,exact with {ExecutableSha256=new string('0',64)})));
    Check("Exact runner with wrong declared architecture is rejected",()=>Reject(()=>SafeInstaller.ValidateRunner(gateData,exact with {Architecture="x64"})));
    Check("Runner traversal is rejected",()=>Reject(()=>SafeInstaller.ValidateRunner(gateData,exact with {ExecutableRelativePath="../UNDERTALE.exe"})));
    Check("Partial runner identity is rejected",()=>Reject(()=>SafeInstaller.ValidateRunner(gateData,exact with {ExecutableSha256=null})));
    Check("Pinned runner installs only the approved candidate",()=>{SafeInstaller.Install(gateData,gateCandidate,[exact],"Windows","x86");Assert(SafeInstaller.Hash(gateData)==profile.PatchedSha256&&SafeInstaller.Hash(gateData+".routekeeper-original")==identity.Sha256);SafeInstaller.Restore(gateData);});
    Check("Unapproved candidate receipt cannot inherit VerifiedPatch from its input",()=>{
        string assets=Path.Combine(root,"receipt-assets");Directory.CreateDirectory(Path.Combine(assets,"profiles"));Directory.CreateDirectory(Path.Combine(assets,"integration"));
        File.WriteAllText(Path.Combine(assets,"integration","patch.csx"),"SYNTHETIC COMPILER CONTRACT ONLY");
        File.WriteAllText(Path.Combine(assets,"integration","verify.csx"),"SYNTHETIC COMPILER CONTRACT ONLY");
        string input=Path.Combine(root,"receipt-original.win"),fixture=Path.Combine(root,"receipt-fixture.win"),output=Path.Combine(root,"receipt-output.win");
        File.WriteAllBytes(input,Data(0));File.WriteAllBytes(fixture,Data(1));
        File.WriteAllText(Path.Combine(assets,"profiles","registry.json"),JsonSerializer.Serialize(new[]{profile with {PatchedSha256=new string('0',64)}}));
        string compiler=Path.Combine(AppContext.BaseDirectory,"RouteKeeper.Tool.Tests"+(OperatingSystem.IsWindows()?".exe":""));
        string? previousFixture=Environment.GetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_COMPILER");
        try {
            Environment.SetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_COMPILER",fixture);
            var receipt=ModBuilder.BuildAsync(input,output,compiler,assets).GetAwaiter().GetResult();
            Assert(receipt.CompatibilityStatus=="InspectedOnly"&&receipt.OutputSha256==SafeInstaller.Hash(fixture));
            File.WriteAllText(Path.Combine(assets,"profiles","registry.json"),JsonSerializer.Serialize(new[]{profile with {PatchedSha256=SafeInstaller.Hash(fixture)}}));
            var approved=ModBuilder.BuildAsync(input,output+".approved",compiler,assets).GetAwaiter().GetResult();Assert(approved.CompatibilityStatus=="VerifiedPatch");
            File.WriteAllText(Path.Combine(assets,"profiles","registry.json"),JsonSerializer.Serialize(new[]{profile with {Status="InspectedOnly",PatchedSha256=SafeInstaller.Hash(fixture)}}));
            var inspected=ModBuilder.BuildAsync(input,output+".inspected",compiler,assets).GetAwaiter().GetResult();Assert(inspected.CompatibilityStatus=="InspectedOnly");
            string? previousVersion=Environment.GetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_VERSION");
            string? previousDiagnostics=Environment.GetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_DIAGNOSTICS");
            try {
                foreach(string unsupported in new[]{"0.9.2.01","0.9.2.0evil","0.9.2.0\nextra",new string('a',8193)}){
                    Environment.SetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_VERSION",unsupported);
                    Reject(()=>ModBuilder.BuildAsync(input,output+".bad-version",compiler,assets).GetAwaiter().GetResult());
                    Assert(!File.Exists(output+".bad-version"));
                }
                Environment.SetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_VERSION","0.9.2.0+03c7048");
                Environment.SetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_DIAGNOSTICS","1");
                var noisy=ModBuilder.BuildAsync(input,output+".noisy",compiler,assets).GetAwaiter().GetResult();
                Assert(noisy.OutputSha256==SafeInstaller.Hash(fixture));
            } finally {
                Environment.SetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_VERSION",previousVersion);
                Environment.SetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_DIAGNOSTICS",previousDiagnostics);
            }
            Assert(SafeInstaller.Hash(input)==identity.Sha256);
        } finally {Environment.SetEnvironmentVariable("ROUTEKEEPER_SYNTHETIC_COMPILER",previousFixture);}
    });
    Check("Duplicate FORM names and excessive chunk tables fail closed",()=>{
        byte[] AppendChunks(int count,bool duplicate){
            using var memory=new MemoryStream();memory.Write(Data(0));
            using var writer=new BinaryWriter(memory,Encoding.ASCII,leaveOpen:true);
            const string digits="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            for(int n=0;n<count;n++){
                string name=duplicate?"TEST":"T"+digits[n/1296%36]+digits[n/36%36]+digits[n%36];
                writer.Write(Encoding.ASCII.GetBytes(name));writer.Write(0u);
            }
            var bytes=memory.ToArray();System.Buffers.Binary.BinaryPrimitives.WriteUInt32LittleEndian(bytes.AsSpan(4),(uint)(bytes.Length-8));return bytes;
        }
        int denied=0;
        foreach(var fixture in new[]{AppendChunks(1,true),AppendChunks(1024,false)}){
            string malformed=Path.Combine(root,"excessive-form.win");File.WriteAllBytes(malformed,fixture);
            try{BuildInspector.Inspect(malformed);}catch(InvalidDataException){denied++;}
        }
        Assert(denied==2);
    });
    Console.WriteLine($"PASS {passed} synthetic tests; authentic gameplay NOT_RUN"); return 0;
}
finally { Directory.Delete(root, recursive: true); }
