. (Join-Path $PSScriptRoot 'watchdog.ps1')
. (Join-Path $PSScriptRoot 'steam-launch-context.ps1')
# A current-account lease serializes all experimental coordinators, irrespective
# of checklist/workspace. The durable marker outlives a crashed controller.
$script:RkNativeAccountLease=$null
function Enter-RkNativeAccountLease([string]$Save,[string]$Owner,[string]$RecoveryRoot,[switch]$NewRun,[string]$GuardRoot) {
 if($script:RkNativeAccountLease){
  $active=$script:RkNativeAccountLease
  if($NewRun -or $active.save -cne $Save -or $active.owner -cne $Owner -or ($RecoveryRoot -and $active.root -and $active.root -cne $RecoveryRoot)){throw 'Different current-account operation is already active.'}
  return @{owned=$false;lease=$active}
 }
 if(!$GuardRoot){$GuardRoot=Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'RouteKeeper/Beta/native-account'}
 Assert-RkNoLinks $GuardRoot;Initialize-RkPrivateRoot $GuardRoot $Owner
 $lockPath=Join-Path $GuardRoot 'account.lock';Assert-RkNoLinks $lockPath
 $stream=[IO.File]::Open($lockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 try{
  if($NewRun){
   $accountLocal=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
   foreach($legacyPath in @((Join-Path $accountLocal 'RoutekeeperSmoke/active'),(Join-Path $accountLocal 'RoutekeeperCurrentSession'))){
    Assert-RkNoLinks $legacyPath
    if(Test-Path -LiteralPath $legacyPath){throw 'A retained legacy account transaction exists; review/recover/archive it before any new experimental trial.'}
   }
  }
  $markerPath=Join-Path $GuardRoot 'active.json';Assert-RkNoLinks $markerPath
  if(Test-Path -LiteralPath $markerPath){
   if((Get-Item -LiteralPath $markerPath).Length -gt 65536){throw 'Account marker exceeds budget; preserve it.'}
   $marker=Get-Content -LiteralPath $markerPath -Raw -Encoding UTF8|ConvertFrom-Json
   foreach($name in @('owner','savePath','root','id')){if($marker.$name -isnot [string]){throw 'Invalid durable account marker.'}}
   if($marker.schema -ne 1 -or $marker.owner -cne $Owner -or $marker.savePath -cne $Save -or $marker.id -cnotmatch '^[a-f0-9]{32}$' -or
      $NewRun -or !$RecoveryRoot -or $marker.root -cne $RecoveryRoot){throw 'An unresolved account transaction exists. Recover only its exact retained journal; no new trial may adopt its save.'}
  }
  $lease=@{stream=$stream;save=$Save;owner=$Owner;guard=$GuardRoot;marker=$markerPath;root=$RecoveryRoot}
  $script:RkNativeAccountLease=$lease
  return @{owned=$true;lease=$lease}
 }catch{$stream.Dispose();throw}
}
function Exit-RkNativeAccountLease($Handle) {
 if($Handle -and $Handle.owned){$Handle.lease.stream.Dispose();$script:RkNativeAccountLease=$null}
}
function Set-RkNativeAccountMarker($State) {
 $lease=$script:RkNativeAccountLease
 if(!$lease -or $lease.save -cne $State.savePath -or $lease.owner -cne $State.owner){throw 'Current-account lease required before save mutation.'}
 Assert-RkJournal $State $State.root $State.savePath $State.owner
 if(Test-Path -LiteralPath $lease.marker){
  $marker=Get-Content -LiteralPath $lease.marker -Raw -Encoding UTF8|ConvertFrom-Json
  if($marker.root -cne $State.root -or $marker.id -cne $State.id -or $marker.owner -cne $State.owner -or $marker.savePath -cne $State.savePath){throw 'Account marker belongs to another journal; preserve all copies.'}
 }else{
  Write-RkAtomicJson $lease.marker @{schema=1;owner=$State.owner;savePath=$State.savePath;root=$State.root;id=$State.id}
 }
 $lease.root=$State.root
}
function Complete-RkNativeAccountMarker($State,[switch]$LegacyRecovery) {
 $lease=$script:RkNativeAccountLease
 if(!$lease){throw 'Current-account lease required for marker closure.'}
 Set-RkNativeAccountMarker $State
 Assert-RkProcessesClosed;Assert-RkExperimentalNetwork
 # Reread the exact durable journal; a caller's in-memory claim is insufficient.
 $verified=Read-RkJournal $State.root;Assert-RkJournal $verified $State.root $State.savePath $State.owner
 if($verified.id -cne $State.id -or $verified.phase -cne 'Restored' -or !(Test-RkCompletionFence $verified)){throw 'Account transaction has no verified completed restoration.'}
 if($LegacyRecovery){
  $legacyRoot=Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'RoutekeeperSmoke/active'
  if($null -ne $verified.PSObject.Properties['e2eKind'] -or [IO.Path]::GetFullPath($verified.root) -cne [IO.Path]::GetFullPath($legacyRoot)){throw 'Legacy marker closure is limited to the exact retained legacy account journal.'}
 }else{Assert-RkE2eRecoveryReady $verified $verified.root $verified.savePath $verified.owner}
 Assert-RkNativeSaveTree $verified.savePath
 if($verified.originalPresent -ne [bool](Test-Path -LiteralPath $verified.savePath) -or
    ($verified.originalPresent -and (Get-RkTreeDigest $verified.savePath) -cne $verified.originalDigest)){throw 'Personal baseline differs after restoration; retain account marker.'}
 if([string]::IsNullOrWhiteSpace($verified.gameInstall) -or [string]::IsNullOrWhiteSpace($verified.steamExe) -or
    (Get-RkTreeDigest $verified.gameInstall) -cne $verified.registeredDigest -or
    !(Test-RkCacheEqual $verified.cacheBefore (Get-RkSteamCacheInventory (Split-Path $verified.steamExe)))){throw 'Registered installation/cache preservation is unverified; retain account marker.'}
 # Close only the exact validated marker while holding the account-wide lease.
 $marker=Get-Content -LiteralPath $lease.marker -Raw -Encoding UTF8|ConvertFrom-Json
 if($marker.id -cne $verified.id -or $marker.root -cne $verified.root){throw 'Account marker changed; preserve it.'}
 Remove-Item -LiteralPath $lease.marker
}
$script:RkConnectedNetworkConsent=$null
function Get-RkNetworkRiskDisclosure {
 $policy=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'experimental-policy.json') -Raw -Encoding UTF8|ConvertFrom-Json
 return $policy.connectedNetworkDisclosure
}
function New-RkApprovalRecord([switch]$OwnerDelegatedOriginalProbe,[string]$ApprovalStatement,[switch]$OwnerDelegatedUiExperiment) {
 if($OwnerDelegatedOriginalProbe -and $OwnerDelegatedUiExperiment){throw 'Choose one delegated scope.'}
 if($OwnerDelegatedUiExperiment){
  if([string]::IsNullOrWhiteSpace($ApprovalStatement) -or $ApprovalStatement.Length -lt 30){throw 'Explicit owner UI delegation statement required.'}
  return @{method='OWNER_CHAT_UI_DELEGATION';statement=$ApprovalStatement;scope='non-destructive-ui-and-original-copy-recovery';reviewMethod='AGENT_DELEGATED';recordedUtc=[DateTime]::UtcNow.ToString('o')}
 }
 if($OwnerDelegatedOriginalProbe){
  if([string]::IsNullOrWhiteSpace($ApprovalStatement) -or $ApprovalStatement.Length -lt 30){throw 'Explicit current owner statement required for delegated original-only execution.'}
  # Operator-supplied documentary authorization, not independent authentication
  # and never a claim that a human typed a terminal nonce.
  return @{method='OWNER_CHAT_DELEGATION';statement=$ApprovalStatement;scope='original-no-input-and-original-copy-recovery';recordedUtc=[DateTime]::UtcNow.ToString('o')}
 }
 if($ApprovalStatement){throw 'Approval statement requires explicit delegated-original selection.'}
 return @{method='DIRECT_TERMINAL_NONCE';scope='non-destructive-smoke'}
}
function Initialize-RkExperimentalNetwork([switch]$AllowConnectedNetwork,[switch]$OwnerDelegatedOriginalProbe,[string]$ApprovalStatement,[switch]$OwnerDelegatedUiExperiment) {
 $script:RkConnectedNetworkConsent=$null
 if(!$AllowConnectedNetwork){return}
 $disclosure=Get-RkNetworkRiskDisclosure
 if([string]::IsNullOrWhiteSpace($disclosure)){throw 'Connected-network risk disclosure is missing.'}
 Write-Host $disclosure -ForegroundColor Yellow
 $approval=New-RkApprovalRecord -OwnerDelegatedOriginalProbe:$OwnerDelegatedOriginalProbe -ApprovalStatement $ApprovalStatement -OwnerDelegatedUiExperiment:$OwnerDelegatedUiExperiment
 $nonce=[guid]::NewGuid().ToString('N')
 $expected='ACCEPT CONNECTED NETWORK RISK '+$nonce
 if(!$OwnerDelegatedOriginalProbe -and !$OwnerDelegatedUiExperiment -and (Read-Host ('Type exactly: '+$expected)) -cne $expected){throw 'Connected-network consent declined.'}
 $script:RkConnectedNetworkConsent=@{mode='CONNECTED_RISK_ACCEPTED';nonce=$nonce;controllerPid=$PID;disclosure=$disclosure;recordedUtc=[DateTime]::UtcNow.ToString('o');accountHistory='NOT_RESTORED';approval=$approval}
}
function Get-RkExperimentalNetworkRecord {
 if($null -eq $script:RkConnectedNetworkConsent){return @{mode='OFFLINE_REQUIRED';accountHistory='NOT_RESTORED'}}
 return $script:RkConnectedNetworkConsent.Clone()
}
function Assert-RkExperimentalNetwork {
 if($null -eq $script:RkConnectedNetworkConsent){Assert-RkNetworkOffline;return}
 $c=$script:RkConnectedNetworkConsent
 if($c.mode -cne 'CONNECTED_RISK_ACCEPTED' -or $c.controllerPid -ne $PID -or
    $c.nonce -cnotmatch '^[a-f0-9]{32}$' -or $c.disclosure -cne (Get-RkNetworkRiskDisclosure)){
  throw 'Current-controller connected-network consent is invalid; no execution or recovery.'
 }
 # This mode accepts possible connectivity, including uncertain observations.
 # Never label it offline or isolated; no network settings/probes are changed.
}
function Assert-RkLaunchNetworkConsent($Consent) {
 Assert-RkExperimentalNetwork
 $network=Get-RkExperimentalNetworkRecord
 if($Consent.network.mode -cne $network.mode -or $Consent.network.nonce -cne $network.nonce){throw 'Launch consent network scope differs from this controller.'}
}
function Assert-RkDelegatedOriginalScope($Consent,[string]$Case,$Plan,[string]$SessionName,[bool]$Acquisition=$false) {
 if($Consent.approval.method -eq 'OWNER_CHAT_UI_DELEGATION' -and ($Consent.approval.scope -cne 'non-destructive-ui-and-original-copy-recovery' -or $Case -notin @('original','patched') -or (!$Plan -and !$Acquisition))){throw 'UI delegation requires a validated UI plan or live reviewed acquisition.'}
 if($Consent.approval.method -eq 'OWNER_CHAT_DELEGATION' -and ($Case -cne 'original' -or $Plan -or $SessionName -cne 'active-session' -or $Consent.approval.scope -cne 'original-no-input-and-original-copy-recovery')){throw 'Delegated approval permits only the original no-input startup probe.'}
}
function New-RkExperimentalConsent([string]$Session,[string]$Nonce,[switch]$OwnerDelegatedOriginalProbe,[string]$ApprovalStatement,[switch]$OwnerDelegatedUiExperiment) {
 # Not a bypass for identity, preflight, path, backup or scenario prerequisites.
 $policy=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'experimental-policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
 Write-Host $policy.disclosure
 $approval=New-RkApprovalRecord -OwnerDelegatedOriginalProbe:$OwnerDelegatedOriginalProbe -ApprovalStatement $ApprovalStatement -OwnerDelegatedUiExperiment:$OwnerDelegatedUiExperiment
 $expected='AUTHORIZE EXPERIMENTAL SESSION '+$Nonce
 if(!$OwnerDelegatedOriginalProbe -and !$OwnerDelegatedUiExperiment -and (Read-Host ('Type exactly: '+$expected)) -cne $expected){throw 'Session consent declined.'}
 $hasher=[Security.Cryptography.SHA256]::Create()
 try{$disclosureHash=([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($policy.disclosure)))).Replace('-','').ToLowerInvariant()}finally{$hasher.Dispose()}
 return @{schema=1;policy=$policy.id;session=$Session;nonce=$Nonce;disclosureSha256=$disclosureHash;recordedUtc=[DateTime]::UtcNow.ToString('o');accountIsolation='UNPROVEN';scope='non-destructive-smoke';credentialsStored=$false;network=(Get-RkExperimentalNetworkRecord);approval=$approval}
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
 Assert-RkProcessesClosed;Assert-RkExperimentalNetwork;Assert-RkNativeSaveTree $State.savePath
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
 $watchdogRoot=Join-Path $Root 'watchdog';Assert-RkNoLinks $watchdogRoot
 if(Test-Path -LiteralPath $watchdogRoot){
  foreach($name in @('stop.json','failure.json')){if(Test-Path -LiteralPath (Join-Path $watchdogRoot $name)){throw 'External watchdog intervened/failed; automatic recovery refused. Preserve all copies.'}}
  $receiptPath=Join-Path $watchdogRoot 'result.json';Assert-RkNoLinks $receiptPath
  if(!(Test-Path -LiteralPath $receiptPath)){throw 'External watchdog closure unverified; automatic recovery refused.'}
  $receipt=Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8|ConvertFrom-Json
  if($receipt.result -cne 'OWNED_PROCESS_EXITED'){throw 'External watchdog intervention requires manual recovery review.'}
 }
 $launch=Join-Path $Root 'game-launch.json';Assert-RkNoLinks $launch
 if(Test-Path -LiteralPath $launch){
  $record=Get-Content -LiteralPath $launch -Raw -Encoding UTF8|ConvertFrom-Json
  if($record.id -cne $State.id -or $record.owner -cne $Owner -or $record.stage -cne 'Observed' -or ($record.pid -isnot [int] -and $record.pid -isnot [long]) -or $record.pid -le 0 -or $record.pid -gt 2147483647){throw 'Interrupted/uncommitted game launch; preserve all copies.'}
  if(@(Get-CimInstance Win32_Process -Filter ('ParentProcessId='+$record.pid) -OperationTimeoutSec 5 -ErrorAction Stop).Count){throw 'Game descendants remain; automatic restoration refused.'}
 }
 if($State.unverifiedChildren -eq $true){throw 'Unverified game descendants were observed; automatic restoration/cleanup refused. Preserve all copies.'}
 if($State.e2eKind -notin @('EXPERIMENTAL_ORIGINAL_PROBE','EXPERIMENTAL_GAMEPLAY_SMOKE','EXPERIMENTAL_HUMAN_BETA')){throw 'Not an owned experimental probe.'}
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
 $account=Enter-RkNativeAccountLease $Save $Owner $Root
 try{
  Assert-RkProcessesClosed;Assert-RkExperimentalNetwork;Assert-RkNativeSaveTree $Save;Assert-RkNativeSaveTree $Root
  Assert-RkE2eRecoveryReady $State $Root $Save $Owner
  Set-RkNativeAccountMarker $State
  Restore-RkSaveTransaction $State $Root $Save $Owner
  Complete-RkNativeAccountMarker $State
 }finally{Exit-RkNativeAccountLease $account}
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
function Stop-RkOwnedSteamClient($Process,[string]$Path,[long]$Ticks,[string]$Hash) {
 if(!$Process){return}
 $Process.Refresh()
 if($Process.HasExited){return}
 Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $Process.Id $Path $Ticks
 Assert-RkHash $Path $Hash
 Start-Process -FilePath $Path -ArgumentList '-shutdown' | Out-Null
}
function Wait-RkProbeProcessesClosed {
 $deadline=[DateTime]::UtcNow.AddSeconds(30)
 while(@(Get-Process steam,steamwebhelper,UNDERTALE -ErrorAction SilentlyContinue).Count -and [DateTime]::UtcNow -lt $deadline){Start-Sleep -Milliseconds 250}
 Assert-RkProcessesClosed;Assert-RkExperimentalNetwork
}
function Complete-RkProbeStopBoundary($State,$GameProcess,[string]$Runner,[long]$GameTicks,$SteamProcess,[string]$SteamExe,[long]$SteamTicks,[bool]$UnknownChildren) {
 # Every stop operation is independent. A guardian/boundary failure must never
 # skip legitimate owned-client shutdown, but still forbids all save recovery.
 $failures=@()
 if($UnknownChildren){
  try{$State|Add-Member NoteProperty unverifiedChildren $true -Force;Save-RkJournal $State}
  catch{$failures+=@{stage='child-journal';reason=$_.Exception.Message}}
 }
 try{Stop-RkOwnedProbeProcess $GameProcess $Runner $GameTicks}
 catch{$failures+=@{stage='game-stop';reason=$_.Exception.Message}}
 try{Complete-RkExternalWatchdog}
 catch{$failures+=@{stage='watchdog-close';reason=$_.Exception.Message}}
 if($GameProcess -and !$UnknownChildren -and !$failures.Count){
  try{Write-RkE2eGameStopBoundary $State}
  catch{$failures+=@{stage='game-stop-boundary';reason=$_.Exception.Message}}
 }
 try{Stop-RkOwnedSteamClient $SteamProcess $SteamExe $SteamTicks $State.steamSha}
 catch{$failures+=@{stage='steam-shutdown';reason=$_.Exception.Message}}
 try{Wait-RkProbeProcessesClosed}
 catch{$failures+=@{stage='process-offline-boundary';reason=$_.Exception.Message}}
 if($UnknownChildren){$failures+=@{stage='unknown-children';reason='Unexpected child process was observed; automatic restoration is not proven safe.'}}
 return @{errors=@($failures)}
}
function Assert-RkOriginalProbeCompletion($Probe,[string]$Root) {
 # This certifies completion of capture/recovery only, never navigation or pixels.
 if(!$Probe -or $Probe.kind -cne 'EXPERIMENTAL_ORIGINAL_STARTUP_PROBE' -or
    $Probe.result -cne 'NEEDS_REVIEW' -or $Probe.case -cne 'original' -or
    $Probe.processObserved -isnot [bool] -or !$Probe.processObserved -or
    $Probe.inputsDispatched -ne 0 -or $Probe.capture -cne 'original.png' -or
    $Probe.localRecovery -cne 'CONTENT_TREE_VERIFIED' -or $Probe.localPhase -cne 'Restored' -or
    $Probe.cacheStable -isnot [bool] -or !$Probe.cacheStable -or
    $Probe.registeredStable -isnot [bool] -or !$Probe.registeredStable -or
    $Probe.copyStable -isnot [bool] -or !$Probe.copyStable -or @($Probe.cleanupErrors).Count){
  throw 'Original startup capture/recovery did not complete; preserve the detailed report. No gameplay PASS.'
 }
 $image=Join-Path $Root 'original.png';$sidecar=$image+'.json';$launchPath=Join-Path $Root 'game-launch.json'
 foreach($path in @($image,$sidecar,$launchPath)){Assert-RkNoLinks $path;if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw 'Original startup capture/process evidence is incomplete.'}}
 $capture=Get-Content -LiteralPath $sidecar -Raw -Encoding UTF8|ConvertFrom-Json
 $launch=Get-Content -LiteralPath $launchPath -Raw -Encoding UTF8|ConvertFrom-Json
 $capturedStart=if($capture.processStartedUtc -is [DateTime]){$capture.processStartedUtc.ToUniversalTime()}else{[DateTime]::Parse($capture.processStartedUtc).ToUniversalTime()}
 if($capture.schema -ne 1 -or $capture.method -cne 'CopyFromScreen' -or
    $capture.imageSha256 -cne (Get-FileHash -LiteralPath $image).Hash.ToLowerInvariant() -or
    $Probe.runnerSha256 -cne 'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58' -or
    $capture.runnerSha256 -cne $Probe.runnerSha256 -or $capture.expectedRunnerSha256 -cne $Probe.runnerSha256 -or
    $capture.foregroundBefore -isnot [bool] -or !$capture.foregroundBefore -or
    $capture.foregroundAfter -isnot [bool] -or !$capture.foregroundAfter -or
    $capture.pid -le 0 -or $capture.ownerPid -ne $capture.pid -or $capture.windowHandle -le 0 -or
    $launch.stage -cne 'Observed' -or $launch.pid -ne $capture.pid -or
    $capturedStart.Ticks -ne $launch.startedTicks){
  throw 'Original startup image does not match the owned launch/window evidence.'
 }
 return 'NEEDS_REVIEW'
}
function Assert-RkProbeWorkReady([string]$Work,[string]$Mode,[string]$Owner) {
 # Local preparation only, before asking for fresh launch consent. Execution
 # repeats its guards; this check never authorizes reusing an earlier probe.
 if($Mode -in @('Smoke','CaptureBootstrap')){
  $previous=Join-Path $Work 'active-session';Assert-RkNoLinks $previous
  if(Test-Path -LiteralPath $previous){throw 'Original probe evidence already exists at this Work. Preserve it and review recovery; never relaunch this session.'}
 }
 Initialize-RkPrivateRoot $Work $Owner
 Initialize-RkPrivateRoot $Work $Owner
 $path=Join-Path $Work 'experiment.lock';Assert-RkNoLinks $path
 $lock=[IO.File]::Open($path,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 try{$null=Resolve-RkWatchdogPython}finally{$lock.Dispose()}
}
function Invoke-RkProbeDiagnostic([scriptblock]$Command) {
 & $Command | Out-Host
}
function Get-RkCanonicalExecutionPath([string]$Path) {
 return [IO.Path]::GetFullPath($Path)
}
function Get-RkBaselineSessionRoot([string]$Baseline) {
 $path=Get-RkCanonicalExecutionPath $Baseline
 Assert-RkNoLinks $path
 if([IO.Path]::GetFileName($path) -ceq 'live-baseline-review.json'){
  if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw 'Baseline certificate must be an existing regular file.'}
  return [IO.Path]::GetDirectoryName($path)
 }
 if(!(Test-Path -LiteralPath $path -PathType Container)){throw 'Baseline must be a session directory or live-baseline-review.json.'}
 return $path
}
function Get-RkSteamStartupCandidate($Observed,[string]$SteamExe) {
 $clients=@($Observed)
 if($clients.Count -gt 1){throw 'Multiple Steam processes during startup; preserve the session.'}
 if(!$clients.Count -or !$clients[0].Path){return $null}
 if(!$clients[0].Path.Equals($SteamExe,[StringComparison]::OrdinalIgnoreCase)){throw 'Unexpected Steam startup path; preserve the session.'}
 return $clients[0]
}
function Invoke-RkGameSession([string]$Work,[string]$SteamExe,[string]$GameInstall,$Consent,[string]$NativeTest,
 [ValidateSet('original','patched')][string]$Case='original',[string]$Plan,[string]$Baseline,[string]$SessionName='active-session',[switch]$Acquisition,$HumanContext) {
 $human=$null -ne $HumanContext
 if($human){
  Assert-RkHumanRequest $HumanContext
  if($Plan -or $Acquisition -or $Baseline -or $SessionName -cne ('human-'+$HumanContext.id)){throw 'Human sessions cannot replay automation plans or reuse another namespace.'}
 }elseif($SessionName -cnotin @('active-session','original-baseline')){throw 'Unsupported automatic session namespace.'}
 # Called ONLY after native preflight/self-test, explicit per-session consent,
 # pinned preparation and the legacy hard history/cache checks. Registered game untouched.
 $SteamExe=Get-RkCanonicalExecutionPath $SteamExe
 $GameInstall=Get-RkCanonicalExecutionPath $GameInstall
 $Work=Get-RkCanonicalExecutionPath $Work
 if(![string]::IsNullOrWhiteSpace($Baseline)){$Baseline=Get-RkCanonicalExecutionPath $Baseline}
 if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Native Windows required; no probe in Cloud/compatibility layers.'}
 Assert-RkNativeHost
 Invoke-RkProbeDiagnostic {Invoke-RkPython -Arguments @('verify-prepared','--work',$Work)}
 Invoke-RkProbeDiagnostic {Invoke-RkPython -Arguments @('check-native-test','--work',$NativeTest)}
 $global:LASTEXITCODE=0
 Invoke-RkProbeDiagnostic {& (Join-Path $PSScriptRoot 'run-current-account.ps1') -Action Preflight -Lab $Work -PatchedData (Join-Path $Work 'candidate.win') -SteamExe $SteamExe -GameInstall $GameInstall}
 if($LASTEXITCODE -ne 0){throw 'Legacy preflight/recovery failed; no later operation authorized.'}
 $policyName=if($human){'human-beta-policy.json'}else{'experimental-policy.json'}
 $policy=Get-Content -LiteralPath (Join-Path $PSScriptRoot $policyName) -Raw -Encoding UTF8|ConvertFrom-Json
 $scope=if($human){'human-beta-'+$HumanContext.scope.ToLowerInvariant()}else{'non-destructive-smoke'}
 if(!$Consent -or $Consent.policy -cne $policy.id -or $Consent.scope -cne $scope -or $Consent.nonce -notmatch '^[a-f0-9]{32}$' -or $Consent.session -notmatch '^[a-f0-9]{32}$'){throw 'Explicit current experimental session consent required.'}
 $hasher=[Security.Cryptography.SHA256]::Create()
 try{$disclosureHash=([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($policy.disclosure)))).Replace('-','').ToLowerInvariant()}finally{$hasher.Dispose()}
 if($Consent.disclosureSha256 -cne $disclosureHash){throw 'Consent disclosure differs from current policy.'}
 $age=([DateTime]::UtcNow-[DateTime]::Parse($Consent.recordedUtc).ToUniversalTime()).TotalSeconds
 if($age -lt 0 -or $age -gt 300){throw 'Consent expired; no launch.'}
 Assert-RkProcessesClosed;Assert-RkExperimentalNetwork
 $owner=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
 $local=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
 if($human){
  Assert-RkHumanParent $HumanContext
  if($Consent.session -cne $HumanContext.id -or $Consent.nonce -cne $HumanContext.nonce){throw 'Human consent/session differs from the reviewed request.'}
 }elseif($Plan){
  $null=Invoke-RkNativeJson -Arguments @('validate','--plan',$Plan,'--case',$Case)
  if($Case -eq 'patched'){
   Invoke-RkProbeDiagnostic {Invoke-RkPython -Arguments @('check-baseline','--baseline',$Baseline,'--work',$Work)}
  }
 }elseif($Case -eq 'patched' -and $Acquisition){
  Invoke-RkProbeDiagnostic {Invoke-RkPython -Arguments @('check-baseline','--baseline',$Baseline,'--work',$Work)}
 }elseif($Case -ne 'original'){throw 'Patched execution requires an explicit reviewed native plan and original baseline.'}
 Assert-RkLaunchNetworkConsent $Consent
 if(!$human){Assert-RkDelegatedOriginalScope $Consent $Case $Plan $SessionName ([bool]$Acquisition)}
 $save=Join-Path $local 'UNDERTALE';$root=Join-Path $Work $SessionName
 $account=Enter-RkNativeAccountLease $save $owner $null -NewRun
 try {
 Assert-RkNativeSaveTree $save
 Initialize-RkPrivateRoot $Work $owner
 $guard=[IO.File]::Open((Join-Path $Work 'experiment.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
 try {
  $before=Get-RkSteamCacheInventory (Split-Path $SteamExe)
  if($before.appCacheFilesPresent -or $before.permanentHistoryPresent){throw 'Existing Steam app cache/history blocks probe; never delete it to pass.'}
  $registered=Get-RkTreeDigest $GameInstall
  $metadata=@{e2eKind=$(if($Plan){'EXPERIMENTAL_GAMEPLAY_SMOKE'}else{'EXPERIMENTAL_ORIGINAL_PROBE'});consentSession=$Consent.session;steamExe=$SteamExe;steamSha=(Get-FileHash -LiteralPath $SteamExe).Hash.ToLowerInvariant();gameInstall=$GameInstall;registeredDigest=$registered;cacheBefore=$before;network=(Get-RkExperimentalNetworkRecord)}
  if($human){$metadata.e2eKind='EXPERIMENTAL_HUMAN_BETA';$metadata.betaSession=$HumanContext.betaSession;$metadata.humanScope=$HumanContext.scope;$metadata.scenario=$HumanContext.scenario;$metadata.step=$HumanContext.step}
  if(($Plan -or $Acquisition) -and $Case -eq 'patched'){
   # Python has validated the complete certificate/evidence chain above. Its
   # accepted file spelling and directory spelling identify the same journal.
   $baselineRoot=Get-RkBaselineSessionRoot $Baseline
   $base=Read-RkJournal $baselineRoot
   Assert-RkJournal $base $baselineRoot $save $owner
   if($base.case -cne 'original' -or $base.phase -ne 'Restored' -or !(Test-RkCompletionFence $base) -or $base.steamSha -cne $metadata.steamSha -or $base.gameInstall -cne $GameInstall -or $base.registeredDigest -cne $registered -or !(Test-RkCacheEqual $base.cacheBefore $before)){throw 'Original baseline client/install/cache differs; no patched comparison.'}
   if($base.originalPresent -ne [bool](Test-Path -LiteralPath $save) -or ($base.originalPresent -and (Get-RkTreeDigest $save) -cne $base.originalDigest)){throw 'Personal local baseline changed; preserve it and refuse patched comparison.'}
  }
  $continuation=$null
  if($human){
   $metadata.preparedSha256=(Get-FileHash -LiteralPath (Join-Path $Work 'prepared.json')).Hash.ToLowerInvariant()
   $metadata.humanLanguage=$HumanContext.language;$metadata.humanMode=$HumanContext.mode
   $metadata.continuationSession=[string]$HumanContext.continuationSession
   $continuation=Get-RkHumanContinuation $Work $HumanContext $owner $save $Case $metadata.preparedSha256
   if($continuation){
    if($continuation.steamExe -cne $SteamExe -or $continuation.steamSha -cne $metadata.steamSha -or
       $continuation.gameInstall -cne $GameInstall -or $continuation.registeredDigest -cne $registered -or
       !(Test-RkCacheEqual $continuation.cacheBefore $before)){throw 'Prior continuation Steam client, registered install or cache baseline differs.'}
    $metadata.continuationDigest=$continuation.digest
   }
  }
  $state=New-RkSaveTransaction $root $save $owner $Case $metadata
  Set-RkNativeAccountMarker $state
  if($Plan){$null=Invoke-RkNativeJson -Arguments @('stage','--plan',$Plan,'--case',$Case,'--root',$root)}
  Write-RkAtomicJson (Join-Path $root 'consent.json') $Consent
  $inventory=Get-Content -LiteralPath (Join-Path $Work 'identity-private.json') -Raw -Encoding UTF8|ConvertFrom-Json
  $profile=Get-Content -LiteralPath (Join-Path $Work 'prepared.json') -Raw -Encoding UTF8|ConvertFrom-Json
  $files=@($inventory.files|Where-Object {$_.path.StartsWith('Undertale/')}|ForEach-Object {@{path=$_.path.Substring(10);original=$_.sha256;patched=$(if($_.path -ceq 'Undertale/data.win'){$profile.candidateSha256}else{$_.sha256})}})
  $game=Join-Path $root 'game'
  New-RkSideCopy (Join-Path $Work 'original/Undertale') $game $files (Join-Path $Work 'candidate.win') $Case
  $launchContext=New-RkSteamLaunchContext $Work $GameInstall $Case $SessionName -HumanGuided:$human
  Write-RkAtomicJson (Join-Path $root 'launch-context.json') $launchContext
  $state|Add-Member NoteProperty runDigest (Get-RkTreeDigest $game);Save-RkJournal $state
  $runner=Join-Path $game 'UNDERTALE.exe';$abort=Join-Path $root 'abort.request'
  $gameProcess=$null;$steamProcess=$null;$gameTicks=0;$steamTicks=0;$unknownChildren=$false
  $prepared=Get-Content -LiteralPath (Join-Path $Work 'prepared.json') -Raw -Encoding UTF8|ConvertFrom-Json
  $result=@{repositoryHead=$prepared.repositoryHead;originalSha256=$prepared.originalSha256;candidateSha256=$prepared.candidateSha256;runnerSha256=$prepared.runnerSha256;schema=1;kind='EXPERIMENTAL_ORIGINAL_STARTUP_PROBE';result='BLOCKED';case='original';patched='NOT_RUN';gameplay='UNVERIFIED';accountHistory='NOT_RESTORED';inputsDispatched=0;reason='No independently verified title-to-room/input baseline; patched execution is not authorized.'}
  $result.network=Get-RkExperimentalNetworkRecord
  $result.harness=$prepared.harness
  $result.case=$Case
  if($human){$result.kind='HUMAN_BETA_SESSION';$result.reason='Human controlled; process observations never certify gameplay.';$result.betaSession=$HumanContext.betaSession;$result.humanSession=$HumanContext.id}
  if($Plan){$result.kind='EXPERIMENTAL_NATIVE_GAMEPLAY';$result.reason='Native observations incomplete; no gameplay PASS.'}
  try {
   Start-RkSaveTransaction $state
   if($human){Copy-RkHumanContinuation $continuation $state $Work}
   Assert-RkProcessesClosed;Assert-RkExperimentalNetwork;Assert-RkHash $SteamExe $state.steamSha
   if($human){Assert-RkHumanLiveRequest $HumanContext}
   Start-Process -FilePath $SteamExe -ArgumentList '-offline' | Out-Null
   $deadline=[DateTime]::UtcNow.AddSeconds(30)
   do {
    if(Test-Path -LiteralPath $abort){throw 'Emergency abort requested.'}
    Assert-RkExperimentalNetwork
    if($human){Assert-RkHumanLiveRequest $HumanContext}
    $clients=@(Get-Process steam -ErrorAction SilentlyContinue)
    $candidate=Get-RkSteamStartupCandidate $clients $SteamExe
    if(!$candidate){Start-Sleep -Milliseconds 250}
   }while(!$candidate -and [DateTime]::UtcNow -lt $deadline)
   if(!$candidate){throw 'Legitimate pinned Steam process/path unavailable before startup timeout. No authentication input is automated.'}
   $steamProcess=$candidate;$steamTicks=$steamProcess.StartTime.ToUniversalTime().Ticks
   Assert-RkHash $SteamExe $state.steamSha
   Assert-RkHash $runner 'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
   if(@(Get-Process UNDERTALE -ErrorAction SilentlyContinue).Count){throw 'Unexpected game process before owned launch.'}
   Write-RkAtomicJson (Join-Path $root 'game-launch.json') @{id=$state.id;owner=$owner;stage='Pending';pid=0}
   $null=Assert-RkSteamLaunchContext $Work $GameInstall $Case $SessionName -HumanGuided:$human
   if($human){Assert-RkHumanLiveRequest $HumanContext}
   $gameProcess=Start-Process -FilePath $runner -WorkingDirectory $game -PassThru
   $gameTicks=$gameProcess.StartTime.ToUniversalTime().Ticks
   $gameBudget=[Diagnostics.Stopwatch]::StartNew()
   if($human){Start-RkExternalWatchdog $gameProcess $root $runner 'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58' -HumanGuided -MaximumSeconds $HumanContext.maximumSeconds}
   else{Start-RkExternalWatchdog $gameProcess $root $runner 'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'}
   Write-RkAtomicJson (Join-Path $root 'game-launch.json') @{id=$state.id;owner=$owner;stage='Observed';pid=$gameProcess.Id;startedTicks=$gameTicks}
   $deadline=[DateTime]::UtcNow.AddSeconds(45)
   Initialize-RkWindowInput
   $stableWindow=[IntPtr]::Zero;$stableFrames=0
   do {
    Update-RkExternalWatchdog
    if($human){Assert-RkHumanLiveRequest $HumanContext}
    Assert-RkExperimentalNetwork
    if((Test-Path -LiteralPath $abort) -or ([RkWindowInput]::GetAsyncKeyState(19) -band 0x8000)){throw 'Emergency abort requested.'}
    $gameProcess.Refresh()
    try{$descendants=@(Get-CimInstance Win32_Process -Filter ('ParentProcessId='+$gameProcess.Id) -OperationTimeoutSec 5 -ErrorAction Stop)}catch{$unknownChildren=$true;throw}
    if($descendants.Count){$unknownChildren=$true;throw 'Unexpected game child process; preserve session for review.'}
    Assert-RkProcessIdentity @(Get-Process UNDERTALE -ErrorAction SilentlyContinue) $gameProcess.Id $runner $gameTicks
    Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $steamProcess.Id $SteamExe $steamTicks
    if($gameProcess.HasExited){throw ($Case+' runner exited/redirected before a verified window.')}
    $window=$gameProcess.MainWindowHandle
    [uint32]$windowOwner=0
    $null=[RkWindowInput]::GetWindowThreadProcessId($window,[ref]$windowOwner)
    if($window -ne [IntPtr]::Zero -and $windowOwner -eq $gameProcess.Id -and [RkWindowInput]::GetForegroundWindow() -eq $window){
     if($window -eq $stableWindow){$stableFrames++}else{$stableWindow=$window;$stableFrames=1}
    }else{$stableWindow=[IntPtr]::Zero;$stableFrames=0}
    if($stableFrames -lt 6){Start-Sleep -Milliseconds 100}
   }while($stableFrames -lt 6 -and [DateTime]::UtcNow -lt $deadline)
   if($stableFrames -lt 6){throw ($Case+' owned window/focus did not stabilize before timeout.')}
   $result.windowObservation=@{pid=$gameProcess.Id;startedTicks=$gameTicks;windowHandle=$stableWindow.ToInt64();ownerPid=[int]$windowOwner;foreground=[RkWindowInput]::GetForegroundWindow().ToInt64();stableFrames=$stableFrames;observedUtc=[DateTime]::UtcNow.ToString('o')}
   Write-RkAtomicJson (Join-Path $root 'window-observed.json') $result.windowObservation
   $initialCapture=$Case+'.png'
   if(!$human){Save-RkClientCapture $runner (Join-Path $root $initialCapture);$result.capture=$initialCapture}
   $result.processObserved=$true;$result.result='NEEDS_REVIEW'
   if($Case -eq 'patched'){$result.patched='PROCESS_AND_DISK_IDENTITY_OBSERVED_NOT_GAMEPLAY_PASS'}
   if($Plan){$result.loadedGameData='UNVERIFIED_DISK_IDENTITY_ONLY';$result.nativeObservations=Invoke-RkNativePlan $gameProcess $runner $root $Case $abort $save ([ref]$unknownChildren) $steamProcess $SteamExe $steamTicks}
   if($Acquisition){$result.kind='EXPERIMENTAL_NATIVE_ACQUISITION';$result.acquisition=Invoke-RkNativeAcquisition $gameProcess $runner $root $Case $abort $steamProcess $SteamExe $steamTicks ([ref]$unknownChildren)}
   if($human){$result.humanObservations=Invoke-RkHumanLoop $gameProcess $runner $root $HumanContext $steamProcess $SteamExe $steamTicks ([ref]$unknownChildren) ([Math]::Max(0,$HumanContext.maximumSeconds-$gameBudget.Elapsed.TotalSeconds-45))}
   # No keys sent into an unrecognized scene. A window/screenshot is NOT a
   # baseline PASS and cannot authorize the patched runner or any route scenario.
  } catch {
   $result.result='BLOCKED';$result.reason=$_.Exception.Message
   $result.failureDiagnostic=@{exceptionType=$_.Exception.GetType().FullName;errorId=$_.FullyQualifiedErrorId;position=$_.InvocationInfo.PositionMessage;scriptStackTrace=$_.ScriptStackTrace;utc=[DateTime]::UtcNow.ToString('o')}
   if($gameProcess -and ('RkWindowInput' -as [type])){
    try{$gameProcess.Refresh();$result.failureWindowObservation=@{pid=$gameProcess.Id;exited=$gameProcess.HasExited;windowHandle=$gameProcess.MainWindowHandle.ToInt64();foreground=[RkWindowInput]::GetForegroundWindow().ToInt64();observedUtc=[DateTime]::UtcNow.ToString('o')}}catch{}
   }
  }
  finally {
   try {
    $stopped=Complete-RkProbeStopBoundary $state $gameProcess $runner $gameTicks $steamProcess $SteamExe $steamTicks $unknownChildren
    $result.cleanupErrors=$stopped.errors
    if($stopped.errors.Count){throw (($stopped.errors|ForEach-Object {$_.stage+': '+$_.reason}) -join '; ')}
    $result.copyStable=(Get-RkTreeDigest $game) -ceq $state.runDigest
    Write-RkE2eTrialFence $state
    Restore-RkE2eSession $state $root $save $owner
    $result.localRecovery='CONTENT_TREE_VERIFIED';$result.localPhase=$state.phase
    $result.cacheStable=Test-RkCacheEqual $state.cacheBefore (Get-RkSteamCacheInventory (Split-Path $SteamExe))
    $result.registeredStable=(Get-RkTreeDigest $GameInstall) -ceq $state.registeredDigest
   } catch {$result.result='BLOCKED';$result.localRecovery='BLOCKED_PRESERVE_ALL_COPIES';$result.recoveryReason=$_.Exception.Message}
   if($Plan -or $Acquisition){$result.inputsDispatched=@(Get-ChildItem -LiteralPath $root -Filter 'input-dispatch-*.json').Count;$result.inputAttempts=@(Get-ChildItem -LiteralPath $root -Filter 'input-intent-*.json').Count}
   Write-RkAtomicJson (Join-Path $root 'result.json') $result
   Write-RkAtomicJson (Join-Path $root 'result-integrity.json') @{sha256=(Get-FileHash -LiteralPath (Join-Path $root 'result.json')).Hash.ToLowerInvariant()}
  }
  return $result
 } finally {$guard.Dispose()}
 } finally {Exit-RkNativeAccountLease $account}
}

# Compatibility wrapper retains the original-only probe contract.
function Invoke-RkOriginalProbe([string]$Work,[string]$SteamExe,[string]$GameInstall,$Consent,[string]$NativeTest){
 Invoke-RkGameSession $Work $SteamExe $GameInstall $Consent $NativeTest
}
