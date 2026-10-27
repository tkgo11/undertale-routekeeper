#requires -Version 5.1
# One safe entry point. Default Check never launches Steam/game or changes saves.
param(
 [ValidateSet('Check','Prepare','Preflight','DryRun','Smoke','NativeTest','Resume','Recover','Report','Cleanup')][string]$Mode='Check',
 [string]$Work,[string]$Archive,[string]$Cli,[string]$Builder,[string]$SteamExe,[string]$GameInstall,
 [ValidateSet('focus','identity','abort','crash','unknown-scene','timeout','bad-image')][string]$Failure
)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'current-account-windows.ps1')
. (Join-Path $PSScriptRoot 'capture-client.ps1')
. (Join-Path $PSScriptRoot 'input-window.ps1')
. (Join-Path $PSScriptRoot 'native-selftest.ps1')
. (Join-Path $PSScriptRoot 'experimental-session.ps1')
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
if(!$Work -and $Mode -in @('Prepare','DryRun','Smoke','NativeTest')){
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
  & $python.Source -c 'import sys; import PIL; assert sys.version_info >= (3,12); assert PIL.__version__ == "11.3.0"; print("OFFLINE_PASS Python/Pillow versions")'
  if($LASTEXITCODE -ne 0){throw 'Python3.12+/Pillow11.3.0 required.'}
  $version=(& $dotnet.Source --version)
  $pinned=(Get-Content -LiteralPath (Join-Path $repo 'global.json') -Raw|ConvertFrom-Json).sdk.version
  if($LASTEXITCODE -ne 0 -or $version.Trim() -cne $pinned){throw 'Exact SDK pinned in global.json required.'}
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
  Invoke-RkPython -Arguments @('report','--run',$Work,'--output',(Join-Path $Work ('report-'+[guid]::NewGuid().ToString('N')+'.html')))
  return
 }
 if($Mode -in @('Recover','Resume','Cleanup')){
  # Resume deliberately performs recovery only, never replays stale inputs.
  if($Work -and (Test-Path -LiteralPath (Join-Path $Work 'active-session/session.json'))){
   Assert-RkNativeHost
   Assert-RkNoLinks $Work
   $lock=[IO.File]::Open((Join-Path $Work 'experiment.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
   try{
   $root=Join-Path $Work 'active-session';$s=Read-RkJournal $root
   $local=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
   $save=Join-Path $local 'UNDERTALE';$owner=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
   Restore-RkE2eSession $s $root $save $owner
   if($Mode -eq 'Cleanup'){
    if(!(Test-RkCacheEqual $s.cacheBefore (Get-RkSteamCacheInventory (Split-Path $s.steamExe))) -or (Get-RkTreeDigest $s.gameInstall) -cne $s.registeredDigest){throw 'Changed cache/registered installation; cleanup refused.'}
    $copy=Join-Path $root 'game';if(Test-Path -LiteralPath $copy){Assert-RkNativeSaveTree $copy;if($s.runDigest -notmatch '^[a-f0-9]{64}$' -or (Get-RkTreeDigest $copy) -cne $s.runDigest){throw 'Disposable copy changed; preserve it as evidence.'};Remove-Item -LiteralPath $copy -Recurse -Force}
   }
   Write-RkAtomicJson (Join-Path $root 'recovery.json') @{kind='LOCAL_RECOVERY_RECEIPT';localRecovery='CONTENT_TREE_VERIFIED';accountHistory='NOT_RESTORED';phase=$s.phase;originalDigest=$s.originalDigest}
   Write-Output (@{localRecovery='CONTENT_TREE_VERIFIED';accountHistory='NOT_RESTORED';gameplay='UNVERIFIED'}|ConvertTo-Json)
   }finally{$lock.Dispose()}
   return
  }
  if($Work){throw 'No known experimental session at this Work. Never guess a different recovery target.'}
  $action=if($Mode -eq 'Cleanup'){'Cleanup'}else{'Recover'}
  & (Join-Path $PSScriptRoot 'run-current-account.ps1') -Action $action
  return
 }
 Assert-RkNativeHost
 if($Mode -eq 'NativeTest'){
  if(!$Work){throw 'NativeTest requires a NEW private disposable Work directory.'}
  Test-RkNativeDesktop $Work | ConvertTo-Json -Depth 8
  Invoke-RkPython -Arguments @('check-native-test','--work',$Work)
  return
 }
 if($Mode -eq 'Smoke' -and !(Test-Path -LiteralPath $Work)){
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
 & (Join-Path $PSScriptRoot 'run-current-account.ps1') -Action Preflight -Lab $Work -PatchedData (Join-Path $Work 'candidate.win') -SteamExe $SteamExe -GameInstall $GameInstall
 Assert-RkProcessesClosed;Assert-RkNetworkOffline
 Assert-RkNativeSaveTree $Work
 $drive=Get-Item -LiteralPath ([IO.Path]::GetPathRoot([IO.Path]::GetFullPath($Work)))
 $volume=Get-Volume -DriveLetter $drive.PSDrive.Name -ErrorAction Stop
 if($volume.FileSystem -ne 'NTFS' -or $volume.SizeRemaining -lt 2GB){throw 'NTFS and at least2GiB available storage required.'}
 if($Mode -eq 'Preflight'){Write-Output (@{result='NOT_RUN';scope='NON_GAME_PREFLIGHT';accountIsolation='UNPROVEN'}|ConvertTo-Json);return}
 # The separate opt-in experiment is a bounded ORIGINAL startup probe only.
 # It cannot certify/advance the unsupported title-to-room or patched baseline.
 $nativeBase=Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'RoutekeeperE2E'
 if(!(Test-Path -LiteralPath $nativeBase)){New-Item -ItemType Directory -Path $nativeBase|Out-Null}
 $native=Join-Path $nativeBase ('native-test-'+[guid]::NewGuid().ToString('N'))
 $null=Test-RkNativeDesktop $native
 Invoke-RkPython -Arguments @('check-native-test','--work',$native)
 $session=[guid]::NewGuid().ToString('N');$nonce=[guid]::NewGuid().ToString('N')
 $consent=New-RkExperimentalConsent $session $nonce
 Write-Host 'Original startup probe only. No automated game input, patched game or baseline PASS is authorized.'
 $null=Invoke-RkOriginalProbe $Work $SteamExe $GameInstall $consent $native
 Invoke-RkPython -Arguments @('ingest-probe','--work',$Work)

} catch {
 Write-Output (@{result='BLOCKED';stage=$Mode;reason=$_.Exception.Message;nativeGameplay='NOT_RUN';accountIsolation='UNPROVEN'}|ConvertTo-Json -Depth 6)
 exit 2
}
