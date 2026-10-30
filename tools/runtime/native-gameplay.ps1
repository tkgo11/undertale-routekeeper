# Real Windows adapter. Uses the shared owned-process/save coordinator, never FakeAdapter.
# Scene contracts are private authentic captures; no guesses, global input or memory writes.
function Initialize-RkNativeObserver {
 if('RkBoundedObserver' -as [type]){return}
 Add-Type @'
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
public static class RkBoundedObserver {
 public static string Run(string exe,string arguments,int timeout) {
  using(var p=new Process()) {
   p.StartInfo=new ProcessStartInfo(exe,arguments) { UseShellExecute=false, RedirectStandardOutput=true, RedirectStandardError=true, CreateNoWindow=true };
   p.StartInfo.EnvironmentVariables["PYTHONIOENCODING"]="utf-8";
   p.Start();int overflow=0;
   Func<Stream,byte[]> drain=stream=> { using(var target=new MemoryStream()) {
    byte[] buffer=new byte[4096];int count;
    while((count=stream.Read(buffer,0,buffer.Length))>0) {
     if(target.Length+count<=2097152) target.Write(buffer,0,count);
     else { Interlocked.Exchange(ref overflow,1);try{p.Kill();}catch(InvalidOperationException){} }
    }
    return target.ToArray();
   }};
   var output=Task.Run(()=>drain(p.StandardOutput.BaseStream));
   var error=Task.Run(()=>drain(p.StandardError.BaseStream));
   try {
    if(!p.WaitForExit(timeout)) {p.Kill();p.WaitForExit(5000);throw new InvalidOperationException("Native observer timeout; no input authorized.");}
    if(!Task.WaitAll(new Task[]{output,error},5000))throw new InvalidOperationException("Native observer pipes did not close.");
    if(overflow!=0 || p.ExitCode!=0)throw new InvalidOperationException("Native observer failed or exceeded output budget; preserve evidence.");
    return new UTF8Encoding(false,true).GetString(output.Result);
   } finally {if(!p.HasExited){p.Kill();p.WaitForExit(5000);}}
  }
 }
}
'@
}
function ConvertTo-RkNativeArgument([string]$Value){
 if($Value.Contains([char]0)){throw 'NUL in observer argument.'}
 $escaped=[regex]::Replace($Value,'(\\*)"','$1$1\"')
 $escaped=[regex]::Replace($escaped,'(\\+)$','$1$1')
 return '"'+$escaped+'"'
}
function Invoke-RkNativeJson([string[]]$Arguments) {
 Initialize-RkNativeObserver
 $exe=(Get-Command python -ErrorAction Stop).Source
 $parts=@((Join-Path $PSScriptRoot '../native_gameplay.py'))+$Arguments
 $argumentsText=(@($parts|ForEach-Object {ConvertTo-RkNativeArgument $_}) -join ' ')
 $output=[RkBoundedObserver]::Run($exe,$argumentsText,20000)
 try{return ($output|ConvertFrom-Json)}catch{throw 'Malformed native observer output.'}
}
function Wait-RkNativeScene($Context,[string]$Scene,$Step) {
 $watch=[Diagnostics.Stopwatch]::StartNew();$stable=0;$last=$null;$matched=New-Object 'Collections.Generic.List[string]'
 for($frame=0;$frame -lt $Step.maxFrames -and $watch.ElapsedMilliseconds -lt $Step.timeoutMs;$frame++){
  Update-RkExternalWatchdog
  if($Context.watch.ElapsedMilliseconds -gt 300000 -or $Context.counter -ge 2000 -or $Context.bytes -ge 64MB){throw 'Native global watchdog/frame budget expired.'}
  if((Get-FileHash -LiteralPath (Join-Path $Context.root 'native-plan.json')).Hash.ToLowerInvariant() -cne $Context.planSha){throw 'Frozen native plan changed; stop inputs.'}
  Assert-RkExperimentalNetwork
  Assert-RkInputWindow $Context.process $Context.window $Context.runner $Context.hash $Context.ticks $Context.abort
  Assert-RkProcessIdentity @(Get-Process UNDERTALE -ErrorAction SilentlyContinue) $Context.process.Id $Context.runner $Context.ticks
  try{$children=@(Get-CimInstance Win32_Process -Filter ('ParentProcessId='+$Context.process.Id) -OperationTimeoutSec 5 -ErrorAction Stop)}catch{$Context.unknownChildren.Value=$true;throw}
  if($children.Count){$Context.unknownChildren.Value=$true;throw 'Unexpected game child process; stop inputs.'}
  $Context.counter++
  $name='frame-'+$Context.counter.ToString('D5')+'.png';$path=Join-Path $Context.root $name
  Save-RkWindowCapture $Context.process $Context.runner $path $Context.hash $Context.window
  $Context.pending=@{frame=$name;scene=$Scene;scenario=$Step.scenario}
  $Context.bytes+=(Get-Item -LiteralPath $path).Length+(Get-Item -LiteralPath ($path+'.json')).Length
  $result=Invoke-RkNativeJson -Arguments @('match','--plan',(Join-Path $Context.root 'native-plan.json'),'--case',$Context.case,'--scene',$Scene,'--frame',$path,'--pid',([string]$Context.process.Id),'--started',$Context.started)
  if($result.result -eq 'MATCH'){$stable++;$matched.Add($name)}elseif($result.result -eq 'NEEDS_REVIEW'){$stable=0;$matched.Clear()}else{throw 'Invalid scene observer verdict.'}
  $last=$name
  if($watch.ElapsedMilliseconds -ge $Step.timeoutMs -or $Context.watch.ElapsedMilliseconds -ge 300000){throw 'Observer exceeded bounded scene/global timeout.'}
  if($stable -ge $Step.stableFrames){return @{frame=$last;frames=@($matched.ToArray())}}
  Start-Sleep -Milliseconds 100
 }
 throw 'Unrecognized/unstable scene or bounded timeout; no further input.'
}
function Invoke-RkNativePlan($Process,[string]$Runner,[string]$Root,[string]$Case,[string]$Abort,[string]$Save,[ref]$UnknownChildren) {
 $plan=Get-Content -LiteralPath (Join-Path $Root 'native-plan.json') -Raw -Encoding UTF8|ConvertFrom-Json
 $context=@{process=$Process;window=$Process.MainWindowHandle;runner=$Runner;root=$Root;case=$Case;abort=$Abort;bytes=0;hash='c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58';ticks=$Process.StartTime.ToUniversalTime().Ticks;started=$Process.StartTime.ToUniversalTime().ToString('o');counter=0;unknownChildren=$UnknownChildren;watch=[Diagnostics.Stopwatch]::StartNew()}
 $context.planSha=(Get-FileHash -LiteralPath (Join-Path $Root 'native-plan.json')).Hash.ToLowerInvariant()
 $rows=New-Object 'Collections.Generic.List[object]'
 $observations=@{schema=1;kind='WINDOWS_GAMEPLAY_OBSERVATIONS';case=$Case;pid=$Process.Id;processStartedUtc=$context.started;planSha256=(Get-FileHash -LiteralPath (Join-Path $Root 'native-plan.json')).Hash.ToLowerInvariant();steps=@();execution='BLOCKED';implementation='REAL_WINDOWS_ADAPTER';internalState='UNAVAILABLE'}
 try {
  for($index=0;$index -lt $plan.steps.Count;$index++){
   $step=$plan.steps[$index]
   $beforeCapture=Wait-RkNativeScene $context $step.before $step
   $dispatch=$null
   if($step.action -ne 'checkpoint'){
    Write-RkAtomicJson (Join-Path $Root ('input-intent-'+$index+'.json')) @{step=$index;key=$step.action;state='ATTEMPTED_NOT_ACKNOWLEDGED';startedUtc=[DateTime]::UtcNow.ToString('o')}
    $dispatch=Send-RkWindowKey $Process $context.window $Runner $context.hash $context.ticks $step.action $step.holdMs $Abort
    Write-RkAtomicJson (Join-Path $Root ('input-dispatch-'+$index+'.json')) $dispatch
   }
   $afterCapture=Wait-RkNativeScene $context $step.after $step
   $setting=$null
   if($step.setting){
    Assert-RkNativeSaveTree $Save
    $settingRoot=Join-Path $Root ('settings-'+$index);New-Item -ItemType Directory -Path $settingRoot|Out-Null
    $setting=Invoke-RkNativeJson -Arguments @('settings','--file',(Join-Path $Save 'routekeeper.ini'),'--section',$step.setting.section,'--key',$step.setting.key,'--expected',([string]$step.setting.expected),'--snapshot',(Join-Path $settingRoot 'routekeeper.ini'))
    if($setting.result -ne 'PASS'){throw 'Independent mod-settings file differs from expected value.'}
   }
   $rows.Add(@{index=$index;scenario=$step.scenario;before=$beforeCapture.frame;after=$afterCapture.frame;beforeFrames=$beforeCapture.frames;afterFrames=$afterCapture.frames;dispatch=$dispatch;setting=$setting})
   $observations.steps=@($rows.ToArray());$context.pending=$null
   # Durable checkpoint after every observed response, never after dispatch alone.
   Write-RkAtomicJson (Join-Path $Root 'native-observations.json') $observations
  }
  $observations.execution='OBSERVED_TRANSITIONS'
 }catch{$observations.reason=$_.Exception.Message;throw}
 finally{
  $observations.steps=@($rows.ToArray());$observations.pending=$context.pending
  Write-RkAtomicJson (Join-Path $Root 'native-observations.json') $observations
  Write-RkAtomicJson (Join-Path $Root 'native-observations-integrity.json') @{sha256=(Get-FileHash -LiteralPath (Join-Path $Root 'native-observations.json')).Hash.ToLowerInvariant()}
 }
 return $observations
}
