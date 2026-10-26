#requires -Version 5.1
# Experimental non-destructive smoke on the SAME Windows account. No admin/VM.
# Side-by-side official runner only; Steam ownership is never bypassed.
param(
 [ValidateSet('Preflight','Run','Recover','Archive','Observe','Cleanup')][string]$Action='Preflight',
 [ValidateSet('original','patched')][string]$Case='original',
 [string]$Lab,[string]$PatchedData,[string]$SteamExe,[string]$GameInstall,
 [switch]$AcceptSteamAccountRisk,[switch]$CloudDisabledAndOffline,
 [ValidateRange(1,30)][int]$Minutes=10,
 [ValidateSet('startup','english','korean','settings','keyboard','battle','warnings','forced')][string]$Scenario='startup',
 [ValidateSet('NOT_RUN','PASS','FAIL','BLOCKED')][string]$Outcome='NOT_RUN',[string]$Actual='',[switch]$Capture,[switch]$RestartForSettings,[ValidateRange(0,10)][int]$CaptureDelaySeconds=3
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'current-account-windows.ps1')
. (Join-Path $PSScriptRoot 'capture-client.ps1')
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows required; no compatibility-layer result can validate this protocol.'}
$identity=[Security.Principal.WindowsIdentity]::GetCurrent();$owner=$identity.User.Value
if(([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Use the current Windows account without elevation.'}
$local=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
$homeDir=[Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
if($env:LOCALAPPDATA -cne $local -or $env:USERPROFILE -cne $homeDir){throw 'Profile redirection is unsupported.'}
$save=Join-Path $local 'UNDERTALE';$parent=Join-Path $local 'RoutekeeperSmoke';$root=Join-Path $parent 'active'
$legacy=Join-Path $local 'RoutekeeperCurrentSession'
if(Test-Path -LiteralPath $legacy){throw 'Legacy swap/quarantine session exists. Do not run a new test or delete backups. See the legacy recovery section in runtime-validation.md; this protocol does not trust legacy restore paths.'}
if($Action -eq 'Preflight'){
 Write-Host 'EXPERIMENTAL, native execution NOT_RUN. Same account, side-by-side copies; registered Steam installation is read-only.'
 Write-Host 'Disable Cloud BEFORE setup; Go Offline and exit Steam; disconnect adapters manually. Never SAVE/RESET/TRUE RESET/complete endings.'
 Write-Host 'Local-save restoration cannot undo Steam account-level history. Known persistent files block Run; account isolation is NOT guaranteed.'
 if(!$SteamExe -or !$GameInstall -or !$Lab -or !$PatchedData){Write-Host 'Supply Lab, PatchedData, SteamExe and GameInstall for read-only readiness checks.';return}
}
if($Action -in @('Run','Preflight')){
 foreach($value in @($Lab,$PatchedData,$SteamExe,$GameInstall)){if([string]::IsNullOrWhiteSpace($value)){throw 'Supply all four input paths.'};Assert-RkNoLinks $value}
 $Lab=(Resolve-Path -LiteralPath $Lab).Path;$PatchedData=(Resolve-Path -LiteralPath $PatchedData).Path
 $SteamExe=(Resolve-Path -LiteralPath $SteamExe).Path;$GameInstall=(Resolve-Path -LiteralPath $GameInstall).Path
 if(!(Test-RkWithin $Lab $homeDir) -or (Test-RkWithin $Lab $save) -or (Test-RkWithin $Lab $parent)){throw 'Use a private lab inside this user profile, outside saves and session storage.'}
 if((Test-RkWithin $GameInstall $parent) -or (Test-RkWithin $save $GameInstall) -or (Test-RkWithin $GameInstall $Lab) -or (Test-RkWithin $GameInstall $save) -or (Test-RkWithin $parent $GameInstall)){throw 'Steam registration must be separate from lab/session/save paths.'}
 Assert-RkSteamClient $SteamExe
 Assert-RkSteamRegistration (Split-Path $SteamExe) $GameInstall
 # The registered library is read-only and may contain another build; it is
 # fingerprinted, never executed/patched/approved. Pin the ACTUAL side-copy input.
 Assert-RkHash (Join-Path $Lab 'original/Undertale/UNDERTALE.exe') 'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
 Assert-RkHash (Join-Path $Lab 'original/Undertale/data.win') 'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'
 $profiles=@(Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\..\profiles\registry.json') -Raw -Encoding UTF8 | ConvertFrom-Json | Where-Object OriginalSha256 -eq 'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7')
 if($profiles.Count -ne 1){throw 'Unique exact-build profile required.'};Assert-RkHash $PatchedData $profiles[0].PatchedSha256
 $inventory=Get-Content -LiteralPath (Join-Path $Lab 'identity-private.json') -Raw -Encoding UTF8 | ConvertFrom-Json
 if((Get-RkInventoryDigest $inventory.files) -cne 'd0d633daad4d0c45a3f6761e9627ad7188853219ff96122b426d06b7a345932a'){throw 'Authorized ZIP inventory mismatch.'}
 Assert-RkNativeSaveTree $save
 if((Test-Path -LiteralPath $save) -and (Get-ChildItem -LiteralPath $save -Recurse -File -Force | Where-Object Name -like 'system_information_*')){throw 'Existing persistent history detected; same-account smoke refused.'}
 $cache=Get-RkSteamCacheInventory (Split-Path $SteamExe)
 if($cache.appCacheFilesPresent){throw 'Preexisting app391540 cache files could rehydrate personal state. Same-account smoke refused; do not delete personal caches to bypass this check.'}
 if($cache.permanentHistoryPresent){throw 'Cached permanent history detected; do not delete it to pass this gate.'}
 if($Action -eq 'Preflight'){Write-Host 'Read-only filesystem/signature checks passed. NOT a Steam readiness, isolation or gameplay PASS.';return}
 if(!$AcceptSteamAccountRisk -or !$CloudDisabledAndOffline){throw 'Acknowledge same-account risk and confirm Cloud disabled/Steam Offline Mode.'}
}
Assert-RkNetworkOffline
Initialize-RkPrivateRoot $parent $owner
$lockName=if($Action -eq 'Observe'){'observation.lock'}else{'session.lock'}
$observationGuard=$null
$lock=[IO.File]::Open((Join-Path $parent $lockName),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try {
 if($Action -eq 'Run'){
  Assert-RkProcessesClosed
  $metadata=@{runnerSha='c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58';dataSha=$(if($Case -eq 'original'){$profiles[0].OriginalSha256}else{$profiles[0].PatchedSha256});harnessSha=(Get-RkTreeDigest $PSScriptRoot);steamExe=$SteamExe;steamSha=(Get-FileHash -LiteralPath $SteamExe).Hash;gameInstall=$GameInstall;registeredDigest=(Get-RkTreeDigest $GameInstall);cacheBefore=(Get-RkSteamCacheInventory (Split-Path $SteamExe))}
  if($Case -eq 'patched'){Assert-RkOriginalSmoke $parent $metadata $save}
  $s=New-RkSaveTransaction $root $save $owner $Case $metadata
  $files=@($inventory.files | Where-Object { $_.path.StartsWith('Undertale/') } | ForEach-Object {
   @{path=$_.path.Substring(10);original=$_.sha256;patched=$(if($_.path -ceq 'Undertale/data.win'){$profiles[0].PatchedSha256}else{$_.sha256})}
  })
  $run=Join-Path $root 'game'
  New-RkSideCopy (Join-Path $Lab 'original\Undertale') $run $files $PatchedData $Case
  $plan=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'smoke-scenarios.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  Write-RkAtomicJson (Join-Path $root 'observations.json') $plan
  $report=@{result='NOT_RUN';kind='CURRENT_ACCOUNT_SIDE_COPY';case=$Case;id=$s.id;runnerSha=$s.runnerSha;dataSha=$s.dataSha;harnessSha=$s.harnessSha;accountIsolation='UNPROVEN';note='No automatic gameplay PASS; early non-destructive smoke only.'}
  $gameProcess=$null
  try {
   Assert-RkProcessesClosed;Assert-RkNetworkOffline
   if(!(Test-RkCacheEqual $s.cacheBefore (Get-RkSteamCacheInventory (Split-Path $SteamExe)))){throw 'Steam cache changed during staging.'}
   Start-RkSaveTransaction $s
   Assert-RkHash $SteamExe $s.steamSha
   Start-Process -FilePath $SteamExe -ArgumentList '-offline' | Out-Null
   $deadline=(Get-Date).AddSeconds(90)
   do {Start-Sleep -Milliseconds 500;$clients=@(Get-Process steam -ErrorAction SilentlyContinue)} while(!$clients.Count -and (Get-Date) -lt $deadline)
   if($clients.Count -ne 1 -or !$clients[0].Path.Equals($SteamExe,[StringComparison]::OrdinalIgnoreCase)){throw 'Expected Steam process was not observed.'}
   $steamStartTicks=$clients[0].StartTime.ToUniversalTime().Ticks
   Assert-RkNetworkOffline;Assert-RkHash $SteamExe $s.steamSha
   # No -applaunch, app-id shim or DLL injection. If the official runner redirects
   # to the registered installation, fail; never swap that installation instead.
   $launches=if($RestartForSettings -and $Case -eq 'patched'){2}else{1}
   for($launch=0;$launch -lt $launches;$launch++){
    Assert-RkNetworkOffline
    Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $clients[0].Id $SteamExe $steamStartTicks
    if(@(Get-Process UNDERTALE -ErrorAction SilentlyContinue).Count){throw 'An unexpected game process exists before side-copy launch.'}
   $gameProcess=Start-Process -FilePath (Join-Path $run 'UNDERTALE.exe') -WorkingDirectory $run -PassThru
   Start-Sleep -Seconds 3;$gameProcess.Refresh()
   if($gameProcess.HasExited -or !$gameProcess.Path.Equals((Join-Path $run 'UNDERTALE.exe'),[StringComparison]::OrdinalIgnoreCase)){throw 'Official side-copy runner exited/redirected. This launch method is NOT validated; no install-swap fallback.'}
   $gameStartTicks=$gameProcess.StartTime.ToUniversalTime().Ticks
   Assert-RkProcessIdentity @(Get-Process UNDERTALE -ErrorAction SilentlyContinue) $gameProcess.Id (Join-Path $run 'UNDERTALE.exe') $gameStartTicks
   $report.processObserved=$true
   Write-Host 'Early smoke only. Do not SAVE/RESET or reach an ending. Observe from a second PowerShell. Keep Steam open until the final restoration prompt.'
   $gameDeadline=(Get-Date).AddMinutes($Minutes);$steamPid=$clients[0].Id
   while(!$gameProcess.WaitForExit(1000)){
    Assert-RkNetworkOffline
    Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $steamPid $SteamExe $steamStartTicks
    Assert-RkProcessIdentity @(Get-Process UNDERTALE -ErrorAction SilentlyContinue) $gameProcess.Id (Join-Path $run 'UNDERTALE.exe') $gameStartTicks
    if((Get-Date) -ge $gameDeadline){$null=$gameProcess.CloseMainWindow();if(!$gameProcess.WaitForExit(10000)){$gameProcess.Kill();$gameProcess.WaitForExit()};break}
   }
   Assert-RkNetworkOffline
   Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $steamPid $SteamExe $steamStartTicks
   if(@(Get-Process UNDERTALE -ErrorAction SilentlyContinue).Count){throw 'An unowned game process remains after side-copy exit; comparison blocked.'}
   $report.exitCode=$gameProcess.ExitCode
   if($gameProcess.ExitCode -ne 0){$report.result='BLOCKED'}
    if($launches -eq 2 -and $launch -eq 0){Write-Host 'Relaunching the SAME trial once for mod settings persistence. Personal saves remain protected.';Start-Sleep -Seconds 2}
   }
   foreach($file in $files){Assert-RkHash (Join-Path $run $file.path) $file.$Case}
  } catch {$report.result='BLOCKED';$report.reason=$_.Exception.Message;Write-Warning $report.reason}
  finally {
   if($gameProcess -and !$gameProcess.HasExited){$null=$gameProcess.CloseMainWindow();if(!$gameProcess.WaitForExit(10000)){$gameProcess.Kill();$gameProcess.WaitForExit()}}
   Write-Host 'Exit Steam completely while staying offline. If it stays running, Recover must wait; originals are preserved.'
   $deadline=(Get-Date).AddSeconds(60)
   while(@(Get-Process steam,steamwebhelper,UNDERTALE -ErrorAction SilentlyContinue).Count -and (Get-Date) -lt $deadline){Start-Sleep -Seconds 1}
   try {
    Assert-RkProcessesClosed;Assert-RkNetworkOffline;Assert-RkNativeSaveTree $save
    Restore-RkSaveTransaction $s $root $save $owner
    $s.cacheStable=Test-RkCacheEqual $s.cacheBefore (Get-RkSteamCacheInventory (Split-Path $s.steamExe))
    $s.registeredStable=(Get-RkTreeDigest $s.gameInstall) -ceq $s.registeredDigest;Save-RkJournal $s
    if(!$s.cacheStable -or !$s.registeredStable){throw 'Local saves restored, but Steam cache/registered tree changed. No account rollback; comparison/archive/cleanup blocked.'}
   } catch {$report.result='BLOCKED';$report.recovery=$_.Exception.Message;Write-Warning 'Stay offline. Preserve the session and snapshots. Run Recover after Steam exits; do not reconnect Cloud until changes are reviewed.'}
   $report.localPhase=$s.phase;$report.cacheStable=$s.cacheStable;$report.registeredStable=$s.registeredStable
   Write-RkAtomicJson (Join-Path $root 'result.json') $report
  }
 } else {
  $s=Read-RkJournal $root;Assert-RkJournal $s $root $save $owner
  if($Action -eq 'Observe'){
   # Observation writes only this owned private report. It does not assert PASS.
   $plan=Get-Content -LiteralPath (Join-Path $root 'observations.json') -Raw -Encoding UTF8 | ConvertFrom-Json
   $entry=@($plan | Where-Object id -eq $Scenario)
   if($entry.Count -ne 1 -or [string]::IsNullOrWhiteSpace($Actual)){throw 'Supply one known scenario and a concrete Actual observation.'}
   $entry[0].actual=$Actual;$entry[0].status=$Outcome;$entry[0].method='OPERATOR_REPORTED';$entry[0].recordedUtc=[DateTime]::UtcNow.ToString('o')
   if($Capture){Start-Sleep -Seconds $CaptureDelaySeconds;$image=Join-Path $root ('capture-'+$Scenario+'-'+[guid]::NewGuid().ToString('N')+'.png');Save-RkClientCapture (Join-Path $root 'game\UNDERTALE.exe') $image;$entry[0]|Add-Member NoteProperty image ([IO.Path]::GetFileName($image)) -Force}
   Write-RkAtomicJson (Join-Path $root 'observations.json') $plan
  } else {
   $observationGuard=[IO.File]::Open((Join-Path $parent 'observation.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
   Assert-RkProcessesClosed;Assert-RkNativeSaveTree $save
   if($Action -eq 'Recover'){
    Restore-RkSaveTransaction $s $root $save $owner
    $s.cacheStable=Test-RkCacheEqual $s.cacheBefore (Get-RkSteamCacheInventory (Split-Path $s.steamExe))
    $s.registeredStable=(Get-RkTreeDigest $s.gameInstall) -ceq $s.registeredDigest;Save-RkJournal $s
    Write-RkAtomicJson (Join-Path $root 'recovery.json') @{result='NOT_RUN';localRestoration='CONTENT_TREE_VERIFIED';accountHistory='NOT_RESTORED';cacheStable=$s.cacheStable;registeredStable=$s.registeredStable}
    if(!$s.cacheStable -or !$s.registeredStable){throw 'Local restoration verified; Steam cache/install differ. Keep Cloud disabled; no account restoration or safe comparison is claimed.'}
   } else {
    if($s.phase -ne 'Restored' -or !$s.cacheStable -or !$s.registeredStable){throw 'Recovery/cache/install checks incomplete; preserve all files.'}
    Restore-RkSaveTransaction $s $root $save $owner
    if(!(Test-RkCacheEqual $s.cacheBefore (Get-RkSteamCacheInventory (Split-Path $s.steamExe))) -or (Get-RkTreeDigest $s.gameInstall) -cne $s.registeredDigest){throw 'Baseline changed since recovery; archive/cleanup refused.'}
    if(Test-Path -LiteralPath (Join-Path $root 'protected-save')){throw 'A protected original remains; do not remove it.'}
    $archive=Join-Path $parent ('completed-'+$s.id)
    if(Test-Path -LiteralPath $archive){throw 'Archive exists.'}
    if($Action -eq 'Cleanup'){
     # Keep verified snapshots, observations and result. Only own game media and
     # trial saves are removed; never Steam folders, personal saves or account cache.
     $ownedNames=@('game','trial-save')+@(Get-ChildItem -LiteralPath $root -Directory -Force | Where-Object Name -match '^game[.]partial-[a-f0-9]{32}$' | ForEach-Object Name)
     foreach($name in $ownedNames){$path=Join-Path $root $name;if(Test-Path -LiteralPath $path){Assert-RkTreeNoLinks $path;Remove-Item -LiteralPath $path -Recurse -Force}}
    }
    [IO.Directory]::Move($root,$archive)
    Write-Host 'Session archived; independent snapshots and private reports retained. Account-level history was never restored.'
   }
  }
 }
} finally {if($observationGuard){$observationGuard.Dispose()};$lock.Dispose()}
