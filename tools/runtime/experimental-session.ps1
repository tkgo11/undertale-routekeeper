function New-RkExperimentalConsent([string]$Session,[string]$Nonce) {
 # Not a bypass for identity, preflight, path, backup or scenario prerequisites.
 $policy=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'experimental-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
 Write-Host $policy.disclosure
 $expected='AUTHORIZE EXPERIMENTAL SESSION '+$Nonce
 if((Read-Host ('Type exactly: '+$expected)) -cne $expected){throw 'Session consent declined.'}
 $hasher=[Security.Cryptography.SHA256]::Create()
 try{$disclosureHash=([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($policy.disclosure)))).Replace('-','').ToLowerInvariant()}finally{$hasher.Dispose()}
 return @{schema=1;policy=$policy.id;session=$Session;nonce=$Nonce;disclosureSha256=$disclosureHash;recordedUtc=[DateTime]::UtcNow.ToString('o');accountIsolation='UNPROVEN';scope='non-destructive-smoke';credentialsStored=$false}
}
# Experimental coordinator. Reuses existing save transactions and capture.
# No cache/history restoration, registered-install writes or global keyboard input.
function Write-RkE2eGameStopBoundary($State) {
 if(@(Get-Process UNDERTALE -ErrorAction SilentlyContinue).Count){throw 'Game still running; no stop boundary.'}
 Assert-RkNativeSaveTree $State.savePath
 $path=Join-Path $State.root 'game-stop-boundary.json';Assert-RkNoLinks $path
 if(Test-Path -LiteralPath $path){throw 'Game-stop boundary already exists; never absorb later changes.'}
 $present=[bool](Test-Path -LiteralPath $State.savePath)
 $digest=if($present){Get-RkTreeDigest $State.savePath}else{''}
 Write-RkAtomicJson $path @{schema=1;id=$State.id;owner=$State.owner;present=$present;digest=$digest}
}
function Write-RkE2eTrialFence($State) {
 Assert-RkProcessesClosed;Assert-RkNetworkOffline;Assert-RkNativeSaveTree $State.savePath
 Assert-RkJournal $State $State.root $State.savePath $State.owner
 $present=[bool](Test-Path -LiteralPath $State.savePath)
 $digest=if($present){Get-RkTreeDigest $State.savePath}else{''}
 $boundary=Join-Path $State.root 'game-stop-boundary.json';Assert-RkNoLinks $boundary
 if(Test-Path -LiteralPath $boundary){
  $b=Get-Content -LiteralPath $boundary -Raw -Encoding UTF8|ConvertFrom-Json
  if($b.schema -ne 1 -or $b.id -cne $State.id -or $b.owner -cne $State.owner -or $b.present -isnot [bool] -or $b.present -ne $present -or $b.digest -cne $digest){throw 'Local data changed during client shutdown; no trial fence may absorb it.'}
 }elseif($present){throw 'No owned game-stop boundary for existing data; preserve unknown changes.'}
 Write-RkAtomicJson (Join-Path $State.root 'trial-fence.json') @{schema=1;id=$State.id;owner=$State.owner;present=$present;digest=$digest}
}
function Assert-RkE2eRecoveryReady($State,[string]$Root,[string]$Save,[string]$Owner) {
 Assert-RkJournal $State $Root $Save $Owner
 $launch=Join-Path $Root 'game-launch.json';Assert-RkNoLinks $launch
 if(Test-Path -LiteralPath $launch){
  $record=Get-Content -LiteralPath $launch -Raw -Encoding UTF8|ConvertFrom-Json
  if($record.id -cne $State.id -or $record.owner -cne $Owner -or $record.stage -cne 'Observed' -or ($record.pid -isnot [int] -and $record.pid -isnot [long]) -or $record.pid -le 0 -or $record.pid -gt 2147483647){throw 'Interrupted/uncommitted game launch; preserve all copies.'}
  if(@(Get-CimInstance Win32_Process -Filter ('ParentProcessId='+$record.pid) -OperationTimeoutSec 5 -ErrorAction Stop).Count){throw 'Game descendants remain; automatic restoration refused.'}
 }
 if($State.unverifiedChildren -eq $true){throw 'Unverified game descendants were observed; automatic restoration/cleanup refused. Preserve all copies.'}
 if($State.e2eKind -notin @('EXPERIMENTAL_ORIGINAL_PROBE','EXPERIMENTAL_GAMEPLAY_SMOKE')){throw 'Not an owned experimental probe.'}
 # The common terminal fence already prevents rewinding later personal changes.
 if($State.phase -eq 'Restored' -or (Test-RkCompletionFence $State)){return}
 $protected=Join-Path $Root 'protected-save'
 if($State.phase -in @('Prepared','QuarantinePending') -and !(Test-Path -LiteralPath $protected)){return}
 $present=[bool](Test-Path -LiteralPath $Save)
 $path=Join-Path $Root 'trial-fence.json';Assert-RkNoLinks $path
 if(!(Test-Path -LiteralPath $path)){
  if($present){throw 'No committed trial fence. Preserve unknown changes; automatic recovery refused.'}
  $boundary=Join-Path $Root 'game-stop-boundary.json';Assert-RkNoLinks $boundary
  if(Test-Path -LiteralPath $boundary){
   $b=Get-Content -LiteralPath $boundary -Raw -Encoding UTF8|ConvertFrom-Json
   if($b.schema -ne 1 -or $b.id -cne $State.id -or $b.owner -cne $Owner -or $b.present -isnot [bool] -or $b.present -or $b.digest -cne ''){throw 'Known trial disappeared or stop boundary is corrupt; preserve all snapshots.'}
  }
  return
 }
 $f=Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json
 if($f.schema -ne 1 -or $f.id -cne $State.id -or $f.owner -cne $Owner -or $f.present -isnot [bool] -or $f.digest -isnot [string]){throw 'Trial fence identity corrupt.'}
 if($f.present -and $f.digest -notmatch '^[a-f0-9]{64}$'){throw 'Invalid present-trial digest.'}
 if(!$f.present -and $f.digest -cne ''){throw 'Absent trial has a nonempty digest.'}
 if($State.phase -eq 'Restoring'){
  # The shared transaction journals Restoring BEFORE renaming the trial. Resume
  # only states independently accounted for by the archived trial and snapshot.
  $archive=Join-Path $Root 'trial-save';Assert-RkNoLinks $archive
  $archived=[bool](Test-Path -LiteralPath $archive)
  if($archived){
   if(!$f.present -or (Get-RkTreeDigest $archive) -cne $f.digest){throw 'Archived trial differs from its committed fence.'}
  }
  if($archived -or !$f.present){
   if($State.originalPresent){
    $snapshot=Join-Path $Root 'snapshot';Assert-RkNoLinks $snapshot
    if(!(Test-Path -LiteralPath $snapshot) -or (Get-RkTreeDigest $snapshot) -cne $State.originalDigest){throw 'Independent original snapshot is missing or corrupt.'}
   }
   if(!$present){return}
   if($State.originalPresent -and !(Test-Path -LiteralPath $protected) -and (Get-RkTreeDigest $Save) -ceq $State.originalDigest){return}
   throw 'Unknown target during interrupted restoration; preserve all trees.'
  }
 }
 if($f.present -ne $present){throw 'Trial presence changed after closure; no recovery mutation authorized.'}
 if(!$present){if($f.digest -cne ''){throw 'Absent trial has a nonempty digest.'};return}
 if($f.digest -notmatch '^[a-f0-9]{64}$' -or (Get-RkTreeDigest $Save) -cne $f.digest){throw 'Unknown personal changes after trial closure; no overwrite or move is authorized.'}

}
function Restore-RkE2eSession($State,[string]$Root,[string]$Save,[string]$Owner) {
 Assert-RkProcessesClosed;Assert-RkNetworkOffline;Assert-RkNativeSaveTree $Save;Assert-RkNativeSaveTree $Root
 Assert-RkE2eRecoveryReady $State $Root $Save $Owner
 Restore-RkSaveTransaction $State $Root $Save $Owner
}
function Stop-RkOwnedProbeProcess($Process,[string]$Path,[long]$Ticks) {
 if(!$Process){return}
 $Process.Refresh();if($Process.HasExited){return}
 Assert-RkProcessIdentity @($Process) $Process.Id $Path $Ticks
 $null=$Process.CloseMainWindow()
 if(!$Process.WaitForExit(5000)){
  $Process.Refresh();Assert-RkProcessIdentity @($Process) $Process.Id $Path $Ticks
  $Process.Kill();if(!$Process.WaitForExit(5000)){throw 'Owned game did not terminate; no restoration permitted.'}
 }
}
function Invoke-RkGameSession([string]$Work,[string]$SteamExe,[string]$GameInstall,$Consent,[string]$NativeTest,
 [ValidateSet('original','patched')][string]$Case='original',[string]$Plan,[string]$Baseline,[ValidateSet('active-session','original-baseline')][string]$SessionName='active-session') {
 # Called ONLY after native preflight/self-test, explicit per-session consent,
 # pinned preparation and the legacy hard history/cache checks. Registered game untouched.
 if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Native Windows required; no probe in Cloud/compatibility layers.'}
 Assert-RkNativeHost
 Invoke-RkPython -Arguments @('verify-prepared','--work',$Work)
 Invoke-RkPython -Arguments @('check-native-test','--work',$NativeTest)
 $global:LASTEXITCODE=0
 & (Join-Path $PSScriptRoot 'run-current-account.ps1') -Action Preflight -Lab $Work -PatchedData (Join-Path $Work 'candidate.win') -SteamExe $SteamExe -GameInstall $GameInstall
 if($LASTEXITCODE -ne 0){throw 'Legacy preflight/recovery failed; no later operation authorized.'}
 $policy=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'experimental-policy.json') -Raw -Encoding UTF8|ConvertFrom-Json
 if(!$Consent -or $Consent.policy -cne $policy.id -or $Consent.scope -cne 'non-destructive-smoke' -or $Consent.nonce -notmatch '^[a-f0-9]{32}$' -or $Consent.session -notmatch '^[a-f0-9]{32}$'){throw 'Explicit current experimental session consent required.'}
 $hasher=[Security.Cryptography.SHA256]::Create()
 try{$disclosureHash=([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($policy.disclosure)))).Replace('-','').ToLowerInvariant()}finally{$hasher.Dispose()}
 if($Consent.disclosureSha256 -cne $disclosureHash){throw 'Consent disclosure differs from current policy.'}
 $age=([DateTime]::UtcNow-[DateTime]::Parse($Consent.recordedUtc).ToUniversalTime()).TotalSeconds
 if($age -lt 0 -or $age -gt 300){throw 'Consent expired; no launch.'}
 Assert-RkProcessesClosed;Assert-RkNetworkOffline
 $owner=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
 $local=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
 if($Plan){
  $null=Invoke-RkNativeJson -Arguments @('validate','--plan',$Plan,'--case',$Case)
  if($Case -eq 'patched'){
   Invoke-RkPython -Arguments @('check-baseline','--baseline',$Baseline,'--work',$Work)
  }
 }elseif($Case -ne 'original'){throw 'Patched execution requires an explicit reviewed native plan and original baseline.'}
 $save=Join-Path $local 'UNDERTALE';$root=Join-Path $Work $SessionName
 Assert-RkNativeSaveTree $save
 Initialize-RkPrivateRoot $Work $owner
 $guard=[IO.File]::Open((Join-Path $Work 'experiment.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 try {
  $before=Get-RkSteamCacheInventory (Split-Path $SteamExe)
  if($before.appCacheFilesPresent -or $before.permanentHistoryPresent){throw 'Existing Steam app cache/history blocks probe; never delete it to pass.'}
  $registered=Get-RkTreeDigest $GameInstall
  $metadata=@{e2eKind=$(if($Plan){'EXPERIMENTAL_GAMEPLAY_SMOKE'}else{'EXPERIMENTAL_ORIGINAL_PROBE'});consentSession=$Consent.session;steamExe=$SteamExe;steamSha=(Get-FileHash -LiteralPath $SteamExe).Hash.ToLowerInvariant();gameInstall=$GameInstall;registeredDigest=$registered;cacheBefore=$before}
  if($Plan -and $Case -eq 'patched'){
   $base=Read-RkJournal $Baseline
   Assert-RkJournal $base $Baseline $save $owner
   if($base.case -cne 'original' -or $base.phase -ne 'Restored' -or !(Test-RkCompletionFence $base) -or $base.steamSha -cne $metadata.steamSha -or $base.gameInstall -cne $GameInstall -or $base.registeredDigest -cne $registered -or !(Test-RkCacheEqual $base.cacheBefore $before)){throw 'Original baseline client/install/cache differs; no patched comparison.'}
   if($base.originalPresent -ne [bool](Test-Path -LiteralPath $save) -or ($base.originalPresent -and (Get-RkTreeDigest $save) -cne $base.originalDigest)){throw 'Personal local baseline changed; preserve it and refuse patched comparison.'}
  }
  $state=New-RkSaveTransaction $root $save $owner $Case $metadata
  if($Plan){$null=Invoke-RkNativeJson -Arguments @('stage','--plan',$Plan,'--case',$Case,'--root',$root)}
  Write-RkAtomicJson (Join-Path $root 'consent.json') $Consent
  $inventory=Get-Content -LiteralPath (Join-Path $Work 'identity-private.json') -Raw -Encoding UTF8|ConvertFrom-Json
  $profile=Get-Content -LiteralPath (Join-Path $Work 'prepared.json') -Raw -Encoding UTF8|ConvertFrom-Json
  $files=@($inventory.files|Where-Object {$_.path.StartsWith('Undertale/')}|ForEach-Object {@{path=$_.path.Substring(10);original=$_.sha256;patched=$(if($_.path -ceq 'Undertale/data.win'){$profile.candidateSha256}else{$_.sha256})}})
  $game=Join-Path $root 'game'
  New-RkSideCopy (Join-Path $Work 'original/Undertale') $game $files (Join-Path $Work 'candidate.win') $Case
  $state|Add-Member NoteProperty runDigest (Get-RkTreeDigest $game);Save-RkJournal $state
  $runner=Join-Path $game 'UNDERTALE.exe';$abort=Join-Path $root 'abort.request'
  $gameProcess=$null;$steamProcess=$null;$gameTicks=0;$steamTicks=0;$unknownChildren=$false
  $prepared=Get-Content -LiteralPath (Join-Path $Work 'prepared.json') -Raw -Encoding UTF8|ConvertFrom-Json
  $result=@{repositoryHead=$prepared.repositoryHead;originalSha256=$prepared.originalSha256;candidateSha256=$prepared.candidateSha256;runnerSha256=$prepared.runnerSha256;schema=1;kind='EXPERIMENTAL_ORIGINAL_STARTUP_PROBE';result='BLOCKED';case='original';patched='NOT_RUN';gameplay='UNVERIFIED';accountHistory='NOT_RESTORED';inputsDispatched=0;reason='No independently verified title-to-room/input baseline; patched execution is not authorized.'}
  $result.harness=$prepared.harness
  $result.case=$Case
  if($Plan){$result.kind='EXPERIMENTAL_NATIVE_GAMEPLAY';$result.reason='Native observations incomplete; no gameplay PASS.'}
  try {
   Start-RkSaveTransaction $state
   Assert-RkProcessesClosed;Assert-RkNetworkOffline;Assert-RkHash $SteamExe $state.steamSha
   Start-Process -FilePath $SteamExe -ArgumentList '-offline' | Out-Null
   $deadline=[DateTime]::UtcNow.AddSeconds(30)
   do {
    if(Test-Path -LiteralPath $abort){throw 'Emergency abort requested.'}
    Assert-RkNetworkOffline
    $clients=@(Get-Process steam -ErrorAction SilentlyContinue)
    if(!$clients.Count){Start-Sleep -Milliseconds 250}
   }while(!$clients.Count -and [DateTime]::UtcNow -lt $deadline)
   if($clients.Count -ne 1 -or !$clients[0].Path.Equals($SteamExe,[StringComparison]::OrdinalIgnoreCase)){throw 'Legitimate pinned Steam process unavailable. No authentication input is automated.'}
   $steamProcess=$clients[0];$steamTicks=$steamProcess.StartTime.ToUniversalTime().Ticks
   Assert-RkHash $SteamExe $state.steamSha
   Assert-RkHash $runner 'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
   if(@(Get-Process UNDERTALE -ErrorAction SilentlyContinue).Count){throw 'Unexpected game process before owned launch.'}
   Write-RkAtomicJson (Join-Path $root 'game-launch.json') @{id=$state.id;owner=$owner;stage='Pending';pid=0}
   $gameProcess=Start-Process -FilePath $runner -WorkingDirectory $game -PassThru
   $gameTicks=$gameProcess.StartTime.ToUniversalTime().Ticks
   Write-RkAtomicJson (Join-Path $root 'game-launch.json') @{id=$state.id;owner=$owner;stage='Observed';pid=$gameProcess.Id;startedTicks=$gameTicks}
   $deadline=[DateTime]::UtcNow.AddSeconds(15)
   Initialize-RkWindowInput
   do {
    Assert-RkNetworkOffline
    if((Test-Path -LiteralPath $abort) -or ([RkWindowInput]::GetAsyncKeyState(19) -band 0x8000)){throw 'Emergency abort requested.'}
    $gameProcess.Refresh()
    try{$descendants=@(Get-CimInstance Win32_Process -Filter ('ParentProcessId='+$gameProcess.Id) -OperationTimeoutSec 5 -ErrorAction Stop)}catch{$unknownChildren=$true;throw}
    if($descendants.Count){$unknownChildren=$true;throw 'Unexpected game child process; preserve session for review.'}
    Assert-RkProcessIdentity @(Get-Process UNDERTALE -ErrorAction SilentlyContinue) $gameProcess.Id $runner $gameTicks
    Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $steamProcess.Id $SteamExe $steamTicks
    if($gameProcess.HasExited){throw 'Original runner exited/redirected before a verified window.'}
    if($gameProcess.MainWindowHandle -eq [IntPtr]::Zero){Start-Sleep -Milliseconds 100}
   }while($gameProcess.MainWindowHandle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -lt $deadline)
   if($gameProcess.MainWindowHandle -eq [IntPtr]::Zero){throw 'Original window timeout.'}
   $initialCapture=$Case+'.png'
   Save-RkClientCapture $runner (Join-Path $root $initialCapture)
   $result.processObserved=$true;$result.capture=$initialCapture
   if($Case -eq 'patched'){$result.patched='PROCESS_AND_DISK_IDENTITY_OBSERVED_NOT_GAMEPLAY_PASS'}
   if($Plan){$result.loadedGameData='UNVERIFIED_DISK_IDENTITY_ONLY';$result.nativeObservations=Invoke-RkNativePlan $gameProcess $runner $root $Case $abort $save ([ref]$unknownChildren)}
   # No keys sent into an unrecognized scene. A window/screenshot is NOT a
   # baseline PASS and cannot authorize the patched runner or any route scenario.
  } catch {$result.reason=$_.Exception.Message}
  finally {
   try {
    try{if($unknownChildren){$state|Add-Member NoteProperty unverifiedChildren $true -Force;Save-RkJournal $state}}finally{Stop-RkOwnedProbeProcess $gameProcess $runner $gameTicks}
    if($gameProcess -and !$unknownChildren){Write-RkE2eGameStopBoundary $state}
    if($steamProcess){
     $steamProcess.Refresh()
     if(!$steamProcess.HasExited){
      Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $steamProcess.Id $SteamExe $steamTicks
      Assert-RkHash $SteamExe $state.steamSha
      Start-Process -FilePath $SteamExe -ArgumentList '-shutdown' | Out-Null
     }
    }
    $deadline=[DateTime]::UtcNow.AddSeconds(30)
    while(@(Get-Process steam,steamwebhelper,UNDERTALE -ErrorAction SilentlyContinue).Count -and [DateTime]::UtcNow -lt $deadline){Start-Sleep -Milliseconds 250}
    Assert-RkProcessesClosed;Assert-RkNetworkOffline
    if($unknownChildren){throw 'Unexpected child process was observed; automatic restoration is not proven safe.'}
    $result.copyStable=(Get-RkTreeDigest $game) -ceq $state.runDigest
    Write-RkE2eTrialFence $state
    Restore-RkE2eSession $state $root $save $owner
    $result.localRecovery='CONTENT_TREE_VERIFIED';$result.localPhase=$state.phase
    $result.cacheStable=Test-RkCacheEqual $state.cacheBefore (Get-RkSteamCacheInventory (Split-Path $SteamExe))
    $result.registeredStable=(Get-RkTreeDigest $GameInstall) -ceq $state.registeredDigest
   } catch {$result.localRecovery='BLOCKED_PRESERVE_ALL_COPIES';$result.recoveryReason=$_.Exception.Message}
   if($Plan){$result.inputsDispatched=@(Get-ChildItem -LiteralPath $root -Filter 'input-dispatch-*.json').Count;$result.inputAttempts=@(Get-ChildItem -LiteralPath $root -Filter 'input-intent-*.json').Count}
   Write-RkAtomicJson (Join-Path $root 'result.json') $result
   Write-RkAtomicJson (Join-Path $root 'result-integrity.json') @{sha256=(Get-FileHash -LiteralPath (Join-Path $root 'result.json')).Hash.ToLowerInvariant()}
  }
  return $result
 } finally {$guard.Dispose()}
}

# Compatibility wrapper retains the original-only probe contract.
function Invoke-RkOriginalProbe([string]$Work,[string]$SteamExe,[string]$GameInstall,$Consent,[string]$NativeTest){
 Invoke-RkGameSession $Work $SteamExe $GameInstall $Consent $NativeTest
}
