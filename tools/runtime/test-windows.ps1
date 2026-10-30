#requires -Version 5.1
# One safe entry point. Default Check never launches Steam/game or changes saves.
param(
 [ValidateSet('Check','Prepare','Preflight','DryRun','Smoke','OriginalBaseline','PatchedSmoke','FullE2E','NativeTest','Resume','Recover','Report','Cleanup')][string]$Mode='Check',
 [string]$Work,[string]$Archive,[string]$Cli,[string]$Builder,[string]$SteamExe,[string]$GameInstall,
 [string]$NativePlan,[string]$OriginalPlan,[string]$PatchedPlan,[string]$Baseline,
 [ValidateSet('focus','identity','abort','crash','unknown-scene','timeout','bad-image')][string]$Failure,
 [switch]$AllowConnectedNetwork,[switch]$OwnerDelegatedOriginalProbe,[string]$ApprovalStatement,[string]$NativeTestReceipt
)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'current-account-windows.ps1')
. (Join-Path $PSScriptRoot 'capture-client.ps1')
. (Join-Path $PSScriptRoot 'input-window.ps1')
. (Join-Path $PSScriptRoot 'native-selftest.ps1')
. (Join-Path $PSScriptRoot 'native-gameplay.ps1')
. (Join-Path $PSScriptRoot 'experimental-session.ps1')
. (Join-Path $PSScriptRoot 'sdk-policy.ps1')
function Invoke-RkPython([string[]]$Arguments) {
 & python (Join-Path $repo 'tools/windows_e2e.py') @Arguments
 if($LASTEXITCODE -ne 0){throw 'E2E command failed closed; inspect private diagnostics. No launch or restore is inferred.'}
}
function Assert-RkNativeHost {
 if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Native Windows required; Linux/compatibility results do not approve execution.'}
 if([Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() -cne 'X64'){throw 'Native x64 Windows host required; ARM/emulation is unsupported.'}
 if($PSVersionTable.PSVersion.Major -notin @(5,7)){throw 'PowerShell5.1 or7 required.'}
 if(![Environment]::Is64BitProcess -or [Environment]::OSVersion.Version.Major -lt 10){throw '64-bit PowerShell on Windows10+ required. The official game runner remains x86.'}
 $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
 if(([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Use an unelevated current account.'}
 $local=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
 $homeDir=[Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
 if($env:LOCALAPPDATA -cne $local -or $env:USERPROFILE -cne $homeDir){throw 'Profile redirection is unsupported.'}
}

try {
if($Work){$Work=[IO.Path]::GetFullPath($Work)}
if($OwnerDelegatedOriginalProbe -or $ApprovalStatement){
 if($Mode -cne 'Smoke'){throw 'Delegated execution is original no-input Smoke only.'}
 $null=New-RkApprovalRecord -OwnerDelegatedOriginalProbe:$OwnerDelegatedOriginalProbe -ApprovalStatement $ApprovalStatement
}
if($AllowConnectedNetwork){
 if($Mode -notin @('Preflight','Smoke','OriginalBaseline','PatchedSmoke','FullE2E','Recover','Resume','Cleanup')){throw 'Connected-network mode applies only to explicit experimental execution/recovery.'}
 Initialize-RkExperimentalNetwork -AllowConnectedNetwork -OwnerDelegatedOriginalProbe:$OwnerDelegatedOriginalProbe -ApprovalStatement $ApprovalStatement
}
if(!$Work -and $Mode -in @('Prepare','DryRun','Smoke','OriginalBaseline','PatchedSmoke','FullE2E','NativeTest')){
 $base=if([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT){Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'RoutekeeperE2E'}else{Join-Path $repo 'private-evidence/windows-e2e'}
 Assert-RkNoLinks $base
 New-Item -ItemType Directory -Path $base -Force|Out-Null
 $Work=Join-Path $base ($Mode.ToLowerInvariant()+'-'+[guid]::NewGuid().ToString('N'))
 Write-Host ('Private Work: '+$Work)
}
if(!$Builder){$Builder=Join-Path $repo 'src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll'}
if(!$Archive){$Archive=Join-Path $repo 'private-data/runtime-windows/runtime.zip'}
if(!$Cli){$found=Get-Command UndertaleModCli -ErrorAction SilentlyContinue;if($found){$Cli=$found.Source}}
 if($Mode -eq 'Check'){
  $python=Get-Command python -ErrorAction Stop;$dotnet=Get-Command dotnet -ErrorAction Stop
  $probe=@(& $python.Source (Join-Path $repo 'tools/windows_e2e.py') prerequisites)
  if($LASTEXITCODE -ne 0){throw 'Python prerequisite probe failed.'}
  try{$requirements=($probe -join "`n")|ConvertFrom-Json}catch{throw 'Invalid Python prerequisite output.'}
  if($requirements.kind -cne 'PREREQUISITES_ONLY' -or $requirements.pillow -cne '11.3.0' -or $requirements.python.Count -ne 3){throw 'Unexpected Python prerequisite output.'}
  if(@($requirements.python|Where-Object {($_ -isnot [int] -and $_ -isnot [long]) -or $_ -lt 0}).Count -or $requirements.python[0] -lt 3 -or ($requirements.python[0] -eq 3 -and $requirements.python[1] -lt 12)){throw 'Unsupported Python version in probe output.'}
  Write-Host 'OFFLINE_PASS explicit Python/Pillow/module prerequisites'

  $versions=@(& $dotnet.Source --version)
  if($LASTEXITCODE -ne 0 -or $versions.Count -ne 1 -or $versions[0] -isnot [string]){throw 'Invalid SDK probe output.'}
  $version=$versions[0]
  $sdk=(Get-Content -LiteralPath (Join-Path $repo 'global.json') -Raw|ConvertFrom-Json).sdk
  if(!(Test-RkSdkAllowed $version.Trim() $sdk.version $sdk.rollForward)){
   throw 'Installed .NET SDK is incompatible with global.json rollForward policy.'
  }
  Write-Host ('OFFLINE_PASS .NET SDK '+$version)
  Write-Output (@{kind='CHECK_ONLY';nativeWindows=([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT);nativeGameplay='NOT_RUN';defaultRun='NO-GO'}|ConvertTo-Json)
  return
 }
 if($Mode -eq 'Prepare'){
  if(!$Work -or !$Archive -or !$Cli){throw 'Prepare requires Work, Archive and Cli; output must be new.'}
  if(!$Builder){$Builder=Join-Path $repo 'src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll'}
  Invoke-RkPython -Arguments @('prepare','--archive',$Archive,'--output',$Work,'--cli',$Cli,'--builder',$Builder)
  return
 }
 if($Mode -eq 'DryRun'){
  if(!$Work){throw 'DryRun requires a NEW private Work directory.'}
  Assert-RkNoLinks $Work
  if(Test-Path -LiteralPath $Work){throw 'Never reuse an existing E2E output.'}
  New-Item -ItemType Directory -Path $Work | Out-Null
  # Actual filesystem transaction on ONLY owned synthetic fixtures; no host saves.
  $fixture=Join-Path $Work 'synthetic-save';New-Item -ItemType Directory -Path $fixture | Out-Null
  [IO.File]::WriteAllText((Join-Path $fixture 'file0'),'SYNTHETIC E2E SAVE')
  $state=New-RkSaveTransaction (Join-Path $Work 'synthetic-transaction') $fixture 'SYNTHETIC' 'original'
  try {
   Start-RkSaveTransaction $state
   $arguments=@('dry-run','--output',(Join-Path $Work 'execution'))
   if($Failure){$arguments+=@('--failure',$Failure)}
   Invoke-RkPython -Arguments $arguments
  } finally {
   Restore-RkSaveTransaction $state $state.root $fixture 'SYNTHETIC'
   Write-RkAtomicJson (Join-Path $Work 'synthetic-recovery.json') @{kind='SYNTHETIC_FILESYSTEM_ONLY';phase=$state.phase;originalDigest=$state.originalDigest;accountHistory='NOT_RESTORED';nativeWindows='NOT_RUN'}
  }
  return
 }
 if($Mode -eq 'Report'){
  if(!$Work){throw 'Report requires the existing execution run directory.'}
  Invoke-RkPython -Arguments @('report','--run',$Work)
  return
 }
 if($Mode -in @('Recover','Resume','Cleanup')){
  # Resume deliberately performs recovery only, never replays stale inputs.
  if($Work -and (Test-Path -LiteralPath (Join-Path $Work 'active-session/session.json')) -and (Test-Path -LiteralPath (Join-Path $Work 'original-baseline/session.json'))){
   $prior=Read-RkJournal (Join-Path $Work 'original-baseline')
   if($prior.phase -ne 'Restored' -or !(Test-RkCompletionFence $prior)){throw 'Ambiguous interrupted sessions; preserve both and refuse guessed recovery.'}
  }
  $sessionName='active-session'
  if($Work -and !(Test-Path -LiteralPath (Join-Path $Work 'active-session/session.json')) -and (Test-Path -LiteralPath (Join-Path $Work 'original-baseline/session.json'))){$sessionName='original-baseline'}
  if($Work -and (Test-Path -LiteralPath (Join-Path $Work ($sessionName+'/session.json')))){
   Assert-RkNativeHost
   Assert-RkNoLinks $Work
   $lock=[IO.File]::Open((Join-Path $Work 'experiment.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
   try{
   $root=Join-Path $Work $sessionName;$s=Read-RkJournal $root
   $local=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
   $save=Join-Path $local 'UNDERTALE';$owner=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
   Restore-RkE2eSession $s $root $save $owner
   if($Mode -eq 'Cleanup'){
    if(!(Test-RkCacheEqual $s.cacheBefore (Get-RkSteamCacheInventory (Split-Path $s.steamExe))) -or (Get-RkTreeDigest $s.gameInstall) -cne $s.registeredDigest){throw 'Changed cache/registered installation; cleanup refused.'}
    $copy=Join-Path $root 'game';if(Test-Path -LiteralPath $copy){Assert-RkNativeSaveTree $copy;if($s.runDigest -notmatch '^[a-f0-9]{64}$' -or (Get-RkTreeDigest $copy) -cne $s.runDigest){throw 'Disposable copy changed; preserve it as evidence.'};Remove-Item -LiteralPath $copy -Recurse -Force}
   }
   Write-RkAtomicJson (Join-Path $root 'recovery.json') @{kind='LOCAL_RECOVERY_RECEIPT';localRecovery='CONTENT_TREE_VERIFIED';accountHistory='NOT_RESTORED';phase=$s.phase;originalDigest=$s.originalDigest;network=(Get-RkExperimentalNetworkRecord)}
   Write-Output (@{localRecovery='CONTENT_TREE_VERIFIED';accountHistory='NOT_RESTORED';gameplay='UNVERIFIED'}|ConvertTo-Json)
   }finally{$lock.Dispose()}
   return
  }
  if($Work){throw 'No known experimental session at this Work. Never guess a different recovery target.'}
  if($AllowConnectedNetwork){throw 'Connected-network mode cannot be used for legacy recovery; supply an exact experimental Work.'}
  $action=if($Mode -eq 'Cleanup'){'Cleanup'}else{'Recover'}
 $global:LASTEXITCODE=0
  & (Join-Path $PSScriptRoot 'run-current-account.ps1') -Action $action
 if($LASTEXITCODE -ne 0){throw 'Legacy preflight/recovery failed; no later operation authorized.'}
  return
 }
 Assert-RkNativeHost
 if($Mode -eq 'NativeTest'){
  if(!$Work){throw 'NativeTest requires a NEW private disposable Work directory.'}
  Test-RkNativeDesktop $Work | ConvertTo-Json -Depth 8
  Invoke-RkPython -Arguments @('check-native-test','--work',$Work)
  return
 }
 if($Mode -in @('Smoke','OriginalBaseline','PatchedSmoke','FullE2E') -and !(Test-Path -LiteralPath $Work)){
  if(!$Archive -or !$Cli){throw 'New Smoke work needs the supplied Archive and verified Cli for automatic preparation.'}
  if(!$Builder){$Builder=Join-Path $repo 'src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll'}
  Invoke-RkPython -Arguments @('prepare','--archive',$Archive,'--output',$Work,'--cli',$Cli,'--builder',$Builder)
 }
 if(!$SteamExe){
  $client=Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue
  if($client -and $client.SteamExe){$SteamExe=$client.SteamExe}
 }
 if(!$GameInstall -and (Test-Path -LiteralPath $Builder)){
  $hints=(& dotnet $Builder discover | ConvertFrom-Json)
  if($LASTEXITCODE -ne 0){throw 'Read-only Steam discovery failed.'}
  $hints=@($hints)
  if($hints.Count -eq 1){$GameInstall=$hints[0].Directory}
 }
 if(!$Work -or !$SteamExe -or !$GameInstall){throw 'Unique Steam client/library not established; supply genuine SteamExe and GameInstall. Discovery hints never approve a build.'}
 Invoke-RkPython -Arguments @('verify-prepared','--work',$Work)
 $global:LASTEXITCODE=0
 & (Join-Path $PSScriptRoot 'run-current-account.ps1') -Action Preflight -Lab $Work -PatchedData (Join-Path $Work 'candidate.win') -SteamExe $SteamExe -GameInstall $GameInstall
 if($LASTEXITCODE -ne 0){throw 'Legacy preflight/recovery failed; no later operation authorized.'}
 Assert-RkProcessesClosed;Assert-RkExperimentalNetwork
 Assert-RkNativeSaveTree $Work
 $drive=Get-Item -LiteralPath ([IO.Path]::GetPathRoot([IO.Path]::GetFullPath($Work)))
 $volume=Get-Volume -DriveLetter $drive.PSDrive.Name -ErrorAction Stop
 if($volume.FileSystem -ne 'NTFS' -or $volume.SizeRemaining -lt 2GB){throw 'NTFS and at least2GiB available storage required.'}
 if($Mode -eq 'Preflight'){Write-Output (@{result='NOT_RUN';scope='NON_GAME_PREFLIGHT';accountIsolation='UNPROVEN'}|ConvertTo-Json);return}
 Assert-RkProbeWorkReady $Work $Mode ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
 # Validate the complete supplied private contract before a benign test or launch.
 if($Mode -eq 'OriginalBaseline'){$OriginalPlan=$NativePlan}
 if($Mode -eq 'PatchedSmoke'){$PatchedPlan=$NativePlan}
 if($Mode -in @('OriginalBaseline','FullE2E')){
  if(!$OriginalPlan){throw 'OriginalPlan/NativePlan required: private reviewed authentic scene contract, no guessed bootstrap.'}
  $null=Invoke-RkNativeJson -Arguments @('validate','--plan',$OriginalPlan,'--case','original')
 }
 if($Mode -in @('PatchedSmoke','FullE2E')){
  if(!$PatchedPlan){throw 'PatchedPlan/NativePlan required.'}
  $null=Invoke-RkNativeJson -Arguments @('validate','--plan',$PatchedPlan,'--case','patched')
 }
 # Legacy Smoke remains an original-only probe. New UI modes additionally
 # require private authentic contracts and scoped original-baseline review.
 if($NativeTestReceipt){$native=[IO.Path]::GetFullPath($NativeTestReceipt)}else{
  $nativeBase=Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'RoutekeeperE2E'
  if(!(Test-Path -LiteralPath $nativeBase)){New-Item -ItemType Directory -Path $nativeBase|Out-Null}
  $native=Join-Path $nativeBase ('native-test-'+[guid]::NewGuid().ToString('N'))
  $null=Test-RkNativeDesktop $native
 }
 Invoke-RkPython -Arguments @('check-native-test','--work',$native)
 $session=[guid]::NewGuid().ToString('N');$nonce=[guid]::NewGuid().ToString('N')
 $consent=New-RkExperimentalConsent $session $nonce -OwnerDelegatedOriginalProbe:$OwnerDelegatedOriginalProbe -ApprovalStatement $ApprovalStatement
 if($Mode -eq 'Smoke'){
  Write-Host 'Original startup probe only; no game input or patched baseline.'
  $probe=Invoke-RkOriginalProbe $Work $SteamExe $GameInstall $consent $native
  Invoke-RkPython -Arguments @('ingest-probe','--work',$Work)
  $completion=Assert-RkOriginalProbeCompletion $probe (Join-Path $Work 'active-session')
  Write-Output (@{execution=$completion;nativeGameplay='UNVERIFIED';accountHistory='NOT_RESTORED'}|ConvertTo-Json)
 }else{
  $originalRoot=Join-Path $Work 'original-baseline'
  if($Mode -in @('OriginalBaseline','FullE2E') -and !(Test-Path -LiteralPath $originalRoot)){
   $null=Invoke-RkGameSession $Work $SteamExe $GameInstall $consent $native 'original' $OriginalPlan '' 'original-baseline'
   Invoke-RkPython -Arguments @('finish-native','--work',$Work,'--session','original-baseline')
  }
  if($Mode -eq 'OriginalBaseline'){
   Invoke-RkPython -Arguments @('report','--run',$originalRoot)
  }else{
   if(!$Baseline){$Baseline=$originalRoot}
   Invoke-RkPython -Arguments @('check-baseline','--baseline',$Baseline,'--work',$Work)
   # A reviewed original navigation trace is a comparison prerequisite, never
   # approval of internal gameplay, account isolation or ending compatibility.
   $null=Invoke-RkGameSession $Work $SteamExe $GameInstall $consent $native 'patched' $PatchedPlan $Baseline
   Invoke-RkPython -Arguments @('finish-native','--work',$Work)
  }
 }


} catch {
 Write-Output (@{result='BLOCKED';stage=$Mode;reason=$_.Exception.Message;nativeGameplay='NOT_RUN';accountIsolation='UNPROVEN'}|ConvertTo-Json -Depth 6)
 exit 2
}
