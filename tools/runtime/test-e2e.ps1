# Synthetic Win32 responses and real disposable filesystem recovery only.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'input-window.ps1')
. (Join-Path $PSScriptRoot 'experimental-session.ps1')
function Check([bool]$Value,[string]$Message){if(!$Value){throw $Message};Write-Host ('OFFLINE_PASS '+$Message)}
foreach($file in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1'){
 $tokens=$null;$errors=$null;$null=[Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
 Check (!$errors) ('AST '+$file.Name)
}
# Compile actual native declaration, but rename it so source functions below bind
# to the clearly synthetic responder instead. No real Windows API is called.
$source=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'input-window.ps1') -Raw
$declaration=[regex]::Match($source,"(?s)Add-Type @'\r?\n(.*?)\r?\n'@").Groups[1].Value
Add-Type -TypeDefinition ($declaration.Replace('class RkWindowInput','class RkWindowInputDeclarationOnly'))
Add-Type @'
using System;
using System.Collections.Generic;
public static class RkWindowInput {
 public static IntPtr Focus=new IntPtr(10);public static uint Owner=42;public static bool LoseFocus=false;public static bool Abort=false;
 public static List<uint> Messages=new List<uint>();
 public static IntPtr GetForegroundWindow(){return Focus;}
 public static uint GetWindowThreadProcessId(IntPtr w,out uint id){id=Owner;return 1;}
 public static uint MapVirtualKey(uint key,uint type){return key;}
 public static short GetAsyncKeyState(int key){return Abort?(short)-32768:(short)0;}
 public static bool PostMessage(IntPtr w,uint m,IntPtr key,IntPtr detail){Messages.Add(m);if(m==256&&LoseFocus)Focus=new IntPtr(20);return true;}
}
'@
$root=Join-Path ([IO.Path]::GetTempPath()) ('rk-e2e-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
 $exe=Join-Path $root 'synthetic.exe';[IO.File]::WriteAllText($exe,'OWNED SYNTHETIC FIXTURE')
 $hash=(Get-FileHash -LiteralPath $exe).Hash.ToLowerInvariant();$start=[DateTime]::UtcNow
 $process=[pscustomobject]@{Id=42;Path=$exe;StartTime=$start;HasExited=$false};$process|Add-Member ScriptMethod Refresh {}
 $abort=Join-Path $root 'abort.request'
 $receipt=Send-RkWindowKey $process ([IntPtr]::new(10)) $exe $hash $start.Ticks 'confirm' 50 $abort
 Check ($receipt.gameAction -eq 'UNPROVEN') 'dispatch is not gameplay proof'
 Check ([RkWindowInput]::Messages.Count -eq 2 -and [RkWindowInput]::Messages[0] -eq 256 -and [RkWindowInput]::Messages[1] -eq 257) 'targeted press and release'
 # Reused PID with unchanged numeric window owner must not receive key-up.
 $script:refreshCount=0
 $process|Add-Member ScriptMethod Refresh { $script:refreshCount++;if($script:refreshCount -ge 2){$this.StartTime=$this.StartTime.AddSeconds(1)} } -Force
 [RkWindowInput]::Messages.Clear();$refused=$false
 try{Send-RkWindowKey $process ([IntPtr]::new(10)) $exe $hash $start.Ticks 'confirm' 50 $abort|Out-Null}catch{$refused=$true}
 Check ($refused -and [RkWindowInput]::Messages.Count -eq 1) 'recycled process identity never receives targeted release'
 $process.StartTime=$start;$process|Add-Member ScriptMethod Refresh {} -Force
 [RkWindowInput]::LoseFocus=$true;$refused=$false
 try{Send-RkWindowKey $process ([IntPtr]::new(10)) $exe $hash $start.Ticks 'confirm' 50 $abort|Out-Null}catch{$refused=$true}
 Check $refused 'focus loss interrupts held input'
 Check ([RkWindowInput]::Messages[[RkWindowInput]::Messages.Count-1] -eq 257) 'release after focus loss'
 [RkWindowInput]::Focus=[IntPtr]::new(10);[RkWindowInput]::LoseFocus=$false;[RkWindowInput]::Abort=$true;$before=[RkWindowInput]::Messages.Count;$refused=$false
 try{Send-RkWindowKey $process ([IntPtr]::new(10)) $exe $hash $start.Ticks 'confirm' 50 $abort|Out-Null}catch{$refused=$true}
 Check ($refused -and [RkWindowInput]::Messages.Count -eq $before) 'Pause abort sends no new key'
 [RkWindowInput]::Abort=$false;[IO.File]::WriteAllText($abort,'abort');$refused=$false
 try{Send-RkWindowKey $process ([IntPtr]::new(10)) $exe $hash $start.Ticks 'confirm' 50 $abort|Out-Null}catch{$refused=$true}
 Check $refused 'abort tombstone sends no key'
 Remove-Item -LiteralPath $abort
 $process.StartTime=$start.AddSeconds(1);$refused=$false
 try{Send-RkWindowKey $process ([IntPtr]::new(10)) $exe $hash $start.Ticks 'confirm' 50 $abort|Out-Null}catch{$refused=$true}
 Check $refused 'recycled process refuses input'
 # Existing transaction + new post-trial fence; all paths are owned fixtures.
 function Assert-RkProcessesClosed {if($script:fakeBusy){throw 'synthetic process still owns trial'}}
 function Assert-RkNetworkOffline {}
 function Assert-RkNativeSaveTree([string]$Path){Assert-RkNoLinks $Path;if(Test-Path -LiteralPath $Path){Assert-RkTreeNoLinks $Path}}
 $save=Join-Path $root 'fenced-save';New-Item -ItemType Directory -Path $save|Out-Null
 [IO.File]::WriteAllText((Join-Path $save 'file0'),'ORIGINAL SYNTHETIC')
 $s=New-RkSaveTransaction (Join-Path $root 'fenced-transaction') $save 'SYNTHETIC' 'original' @{e2eKind='EXPERIMENTAL_ORIGINAL_PROBE'}
 Start-RkSaveTransaction $s;New-Item -ItemType Directory -Path $save|Out-Null
 [IO.File]::WriteAllText((Join-Path $save 'file0'),'TRIAL SYNTHETIC')
 $refused=$false;try{Restore-RkE2eSession $s $s.root $save 'SYNTHETIC'}catch{$refused=$true}
 Check $refused 'unfenced post-crash trial is preserved, not guessed'
 $script:fakeBusy=$true;$refused=$false;try{Write-RkE2eTrialFence $s}catch{$refused=$true}
 Check $refused 'live process blocks trial closure fence'
 $script:fakeBusy=$false;Write-RkE2eGameStopBoundary $s
 [IO.File]::WriteAllText((Join-Path $save 'file0'),'UNRECOGNIZED SHUTDOWN CHANGE')
 $refused=$false;try{Write-RkE2eTrialFence $s}catch{$refused=$true}
 Check $refused 'changes during Steam shutdown cannot be absorbed into a later fence'
 [IO.File]::WriteAllText((Join-Path $save 'file0'),'TRIAL SYNTHETIC')
 Write-RkE2eTrialFence $s
 $renamed=Join-Path $root 'unexpectedly-renamed-trial';Move-Item -LiteralPath $save -Destination $renamed
 $refused=$false;try{Restore-RkE2eSession $s $s.root $save 'SYNTHETIC'}catch{$refused=$true}
 Check ($refused -and !(Test-Path -LiteralPath $save)) 'known trial disappearance is not treated as an originally absent target'
 Move-Item -LiteralPath $renamed -Destination $save
 [IO.File]::WriteAllText((Join-Path $save 'file0'),'LATER PERSONAL CHANGE')
 $refused=$false;try{Restore-RkE2eSession $s $s.root $save 'SYNTHETIC'}catch{$refused=$true}
 Check ($refused -and (Get-Content -LiteralPath (Join-Path $save 'file0') -Raw) -ceq 'LATER PERSONAL CHANGE') 'unknown changes after trial closure cannot be moved or overwritten'
 [IO.File]::WriteAllText((Join-Path $save 'file0'),'TRIAL SYNTHETIC')
 Restore-RkE2eSession $s $s.root $save 'SYNTHETIC'
 Check ((Get-Content -LiteralPath (Join-Path $save 'file0') -Raw) -ceq 'ORIGINAL SYNTHETIC') 'verified trial fence restores independent original snapshot'
 Restore-RkE2eSession $s $s.root $save 'SYNTHETIC'
 Check ($s.phase -eq 'Restored') 'verified restoration is idempotent'
 # Independent failure injection inside the SHARED restoration implementation.
 function New-FencedFixture([string]$Name){
  $localSave=Join-Path $root ($Name+'-save');New-Item -ItemType Directory -Path $localSave|Out-Null
  [IO.File]::WriteAllText((Join-Path $localSave 'file0'),'ORIGINAL '+$Name)
  $tx=New-RkSaveTransaction (Join-Path $root ($Name+'-tx')) $localSave 'SYNTHETIC' 'original' @{e2eKind='EXPERIMENTAL_ORIGINAL_PROBE'}
  Start-RkSaveTransaction $tx;New-Item -ItemType Directory -Path $localSave|Out-Null
  [IO.File]::WriteAllText((Join-Path $localSave 'file0'),'TRIAL '+$Name)
  Write-RkE2eGameStopBoundary $tx;Write-RkE2eTrialFence $tx
  return $tx
 }
 function Move-Item([string]$LiteralPath,[string]$Destination){
  if($script:failProtectedReturn -and [IO.Path]::GetFileName($LiteralPath) -eq 'protected-save'){throw 'Injected protected return failure'}
  Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
 }
 $mid=New-FencedFixture 'mid-restore';$script:failProtectedReturn=$true;$refused=$false
 try{Restore-RkE2eSession $mid $mid.root $mid.savePath 'SYNTHETIC'}catch{$refused=$true}
 Check ($refused -and $mid.phase -eq 'Restoring' -and !(Test-Path -LiteralPath $mid.savePath)) 'injected failure archives trial before original return'
 $script:failProtectedReturn=$false
 Restore-RkE2eSession $mid $mid.root $mid.savePath 'SYNTHETIC'
 Check ((Get-Content -LiteralPath (Join-Path $mid.savePath 'file0') -Raw) -ceq 'ORIGINAL mid-restore') 'archived fenced trial permits safe restoration resume'
 $tampered=New-FencedFixture 'tampered-archive';$script:failProtectedReturn=$true
 try{Restore-RkE2eSession $tampered $tampered.root $tampered.savePath 'SYNTHETIC'}catch{}
 $script:failProtectedReturn=$false
 [IO.File]::WriteAllText((Join-Path $tampered.root 'trial-save/file0'),'UNKNOWN ARCHIVE CONTENT')
 $refused=$false;try{Restore-RkE2eSession $tampered $tampered.root $tampered.savePath 'SYNTHETIC'}catch{$refused=$true}
 Check ($refused -and !(Test-Path -LiteralPath $tampered.savePath)) 'tampered archived trial never permits interrupted recovery'
 [IO.File]::WriteAllText((Join-Path $tampered.root 'trial-save/file0'),'TRIAL tampered-archive')
 New-Item -ItemType Directory -Path $tampered.savePath|Out-Null
 [IO.File]::WriteAllText((Join-Path $tampered.savePath 'file0'),'UNKNOWN TARGET CONTENT')
 $refused=$false;try{Restore-RkE2eSession $tampered $tampered.root $tampered.savePath 'SYNTHETIC'}catch{$refused=$true}
 Check ($refused -and (Get-Content -LiteralPath (Join-Path $tampered.savePath 'file0') -Raw) -ceq 'UNKNOWN TARGET CONTENT') 'unknown target during Restoring is preserved'
 $script:originalFence=(Get-Command Write-RkCompletionFence).ScriptBlock
 function Write-RkCompletionFence($State){if($script:failCompletion){throw 'Injected terminal fence failure'};& $script:originalFence $State}
 $terminal=New-FencedFixture 'terminal-gap';$script:failCompletion=$true;$refused=$false
 try{Restore-RkE2eSession $terminal $terminal.root $terminal.savePath 'SYNTHETIC'}catch{$refused=$true}
 Check ($refused -and $terminal.phase -eq 'Restoring') 'injected failure after original return before completion fence'
 $script:failCompletion=$false
 Restore-RkE2eSession $terminal $terminal.root $terminal.savePath 'SYNTHETIC'
 Check ($terminal.phase -eq 'Restored') 'verified returned original resumes across terminal fence gap'
 function Read-Host([string]$Prompt){return $script:answer}
 $session=[guid]::NewGuid().ToString('N');$nonce=[guid]::NewGuid().ToString('N')
 $s|Add-Member NoteProperty unverifiedChildren $true -Force
 $refused=$false;try{Restore-RkE2eSession $s $s.root $save 'SYNTHETIC'}catch{$refused=$true}
 Check $refused 'unverified descendants persistently refuse automatic recovery even after terminal restoration'
 $s.unverifiedChildren=$false
 $launch=Join-Path $s.root 'game-launch.json'
 Write-RkAtomicJson $launch @{id=$s.id;owner='SYNTHETIC';stage='Pending';pid=0}
 $refused=$false;try{Restore-RkE2eSession $s $s.root $save 'SYNTHETIC'}catch{$refused=$true}
 Check $refused 'uncommitted launch cannot authorize recovery of even a terminal session'
 Write-RkAtomicJson $launch @{id=$s.id;owner='WRONG';stage='Observed';pid=42}
 $refused=$false;try{Restore-RkE2eSession $s $s.root $save 'SYNTHETIC'}catch{$refused=$true}
 Check $refused 'launch marker owner mismatch is refused'
 Write-RkAtomicJson $launch @{id=$s.id;owner='SYNTHETIC';stage='Observed';pid=42}
 function Get-CimInstance {return [pscustomobject]@{ProcessId=99;ParentProcessId=42}}
 $refused=$false;try{Restore-RkE2eSession $s $s.root $save 'SYNTHETIC'}catch{$refused=$true}
 Check $refused 'observed surviving descendant blocks recovery'
 function Get-CimInstance {return @()}
 Restore-RkE2eSession $s $s.root $save 'SYNTHETIC'
 Check ($s.phase -eq 'Restored') 'closed descendant fixture preserves valid terminal idempotency'
 $script:answer='decline';$refused=$false
 try{New-RkExperimentalConsent $session $nonce|Out-Null}catch{$refused=$true}
 Check $refused 'missing explicit session phrase cannot authorize'
 $script:answer='AUTHORIZE EXPERIMENTAL SESSION '+$nonce
 $consent=New-RkExperimentalConsent $session $nonce
 Check ($consent.nonce -ceq $nonce -and $consent.session -ceq $session -and $consent.disclosureSha256 -match '^[a-f0-9]{64}$' -and !$consent.credentialsStored) 'synthetic consent binds session/nonce/disclosure without credentials'
 . (Join-Path $PSScriptRoot 'native-gameplay.ps1')
Initialize-RkNativeObserver
$probe=@('space value','quote"value','trailing\','한글')
$code='import sys,json;print(json.dumps(sys.argv[1:]))'
$parts=@('-c',$code)+$probe
$argsText=(@($parts|ForEach-Object {ConvertTo-RkNativeArgument $_}) -join ' ')
$result=[RkBoundedObserver]::Run((Get-Command python).Source,$argsText,5000)|ConvertFrom-Json
if(($result|ConvertTo-Json -Compress) -cne ($probe|ConvertTo-Json -Compress)){throw 'Argument quoting changed values.'}
$blocked=$false
try{$null=[RkBoundedObserver]::Run((Get-Command python).Source,'-c "import time;time.sleep(10)"',100)}catch{$blocked=$true}
if(!$blocked){throw 'Timeout was ignored.'}
$blocked=$false
try{$null=[RkBoundedObserver]::Run((Get-Command python).Source,'-c "print(''x''*3000000)"',5000)}catch{$blocked=$true}
if(!$blocked){throw 'Output budget was ignored.'}
$blocked=$false
try{$null=[RkBoundedObserver]::Run((Get-Command python).Source,'-c "print(''PASS'');raise SystemExit(7)"',5000)}catch{$blocked=$true}
Check $blocked 'success text cannot override failed observer exit'
Check $true 'real Python child quoting/timeout/output budget; no Windows/game APIs'
 $work=Join-Path $root 'dry-run'
 & (Join-Path $PSScriptRoot 'test-windows.ps1') -Mode DryRun -Work $work | Out-Null
 Check ($LASTEXITCODE -eq 0) 'single-entry DryRun completes without launch'
 $recovery=Get-Content -LiteralPath (Join-Path $work 'synthetic-recovery.json') -Raw|ConvertFrom-Json
 Check ($recovery.phase -eq 'Restored') 'existing save transaction integrated and restored synthetic content'
 Check ((Get-Content -LiteralPath (Join-Path $work 'synthetic-save/file0') -Raw) -ceq 'SYNTHETIC E2E SAVE') 'independent synthetic save bytes preserved'
 $result=Get-Content -LiteralPath (Join-Path $work 'execution/result.json') -Raw|ConvertFrom-Json
 Check ($result.nativeGameplay -eq 'NOT_RUN' -and $result.result -eq 'NEEDS_REVIEW') 'DryRun cannot certify native gameplay'
} finally {Remove-Item -LiteralPath $root -Recurse -Force}
