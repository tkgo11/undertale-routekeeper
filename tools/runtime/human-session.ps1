#requires -Version 5.1
# The child controller owns the exact game/Steam lifecycle, never the UI thread.
param([ValidateSet('Check','Prepare','Run','Recover','Cleanup')][string]$Action='Check',
 [string]$Work,[string]$GameInstall,[string]$SteamExe,[string]$RequestFile,[string]$SessionName,
 [string]$Python,[string]$Compiler,[string]$Builder)
$ErrorActionPreference='Stop'
$env:PYTHONDONTWRITEBYTECODE='1'
$privateErrorRoot=$null
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
foreach($helper in @('safety.ps1','current-account-state.ps1','current-account-windows.ps1','native-host.ps1','capture-client.ps1','input-window.ps1','native-selftest.ps1','native-gameplay.ps1','experimental-session.ps1','human-loop.ps1')){. (Join-Path $PSScriptRoot $helper)}
function Invoke-RkPython([string[]]$Arguments) {
 & $Python -B (Join-Path $repo 'tools/windows_e2e.py') @Arguments
 if($LASTEXITCODE -ne 0){throw 'Native prerequisite or preparation verification failed; no later operation authorized.'}
}
function Write-RkHumanSummary([string]$Root,$Request,$Result) {
 $ok=$Result.localRecovery -ceq 'CONTENT_TREE_VERIFIED' -and $Result.localPhase -ceq 'Restored' -and
     $Result.copyStable -eq $true -and $Result.cacheStable -eq $true -and $Result.registeredStable -eq $true
 $state=if($ok){if($Result.result -ceq 'BLOCKED'){'BLOCKED'}else{'RESTORED'}}else{'RECOVERY_REQUIRED'}
 $events=@()
 if($Result.humanObservations){
  foreach($event in @($Result.humanObservations.events)){
   if($event.kind -cin @('OWNED_PROCESS_STARTED','HUMAN_SESSION_STOP_REQUESTED','OPTIONAL_CAPTURE_REFUSED','OWNED_PROCESS_EXITED','OWNED_PROCESS_ABNORMAL_EXIT')){
    # Reconstruct an exact bounded DTO; no PID, filename, reason or raw diagnostic.
    $events+=@{kind=[string]$event.kind;utc=[string]$event.utc;classification='AutomatedObservation';scope='PROCESS_ONLY_NOT_GAMEPLAY'}
   }
  }
 }
 if($events.Count -gt 200){throw 'Process observation budget exceeded.'}
 $summary=@{schema=1;session=$Request.id;betaSession=$Request.betaSession;scenario=$Request.scenario;step=$Request.step;
  state=$state;case=$Result.case;inputsDispatched=0;gameplay='NOT_INDEPENDENTLY_VERIFIED';humanResults='HUMAN_REPORTED_ONLY';
  localRecovery=$(if($ok){'CONTENT_TREE_VERIFIED'}else{'UNVERIFIED_PRESERVE_ALL_COPIES'});accountHistory='NOT_RESTORED';
  originalSha256=$Result.originalSha256;candidateSha256=$Result.candidateSha256;events=$events;utc=[DateTime]::UtcNow.ToString('o')}
 Write-RkAtomicJson (Join-Path $Root 'human-summary.json') $summary
 Write-RkAtomicJson (Join-Path $Root 'human-status.json') @{schema=1;session=$Request.id;betaSession=$Request.betaSession;state=$state;inputsDispatched=0;nextSequence=0}
}
try {
 Assert-RkNativeHost
 if(!$Python){$Python=Join-Path $repo 'python/python.exe'}
 Assert-RkNoLinks $Python
 if(!(Test-Path -LiteralPath $Python -PathType Leaf)){throw 'Packaged physical Python interpreter is missing.'}
 $probe=@(& $Python -B (Join-Path $repo 'tools/windows_e2e.py') prerequisites)
 if($LASTEXITCODE -ne 0){throw 'Pinned Python/Pillow prerequisites unavailable.'}
 if($Action -eq 'Check'){Write-Output 'READY_NATIVE_PREREQUISITES_ONLY; GAMEPLAY_NOT_RUN';return}
 $base=Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'RouteKeeper/Beta/native'
 $owner=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
 if([string]::IsNullOrWhiteSpace($Work)){throw 'Explicit owned native workspace required.'}
 $Work=[IO.Path]::GetFullPath($Work);Assert-RkNoLinks $Work
 if(!(Test-RkWithin $Work $base) -or [IO.Path]::GetFileName($Work) -cnotmatch '^prepared-[a-f0-9]{32}$'){throw 'Native workspace must be an owned prepared-ID child under Beta native storage.'}
 Initialize-RkPrivateRoot $base $owner
 $privateErrorRoot=$base
 if($Action -eq 'Prepare'){
  if(Test-Path -LiteralPath $Work){throw 'Preparation must use a new workspace; existing data is never overwritten.'}
  if(!$Compiler){$Compiler=Join-Path $repo 'compiler/UndertaleModCli.exe'}
  if(!$Builder){$Builder=Join-Path $repo 'RouteKeeper.Tool.exe'}
  foreach($path in @($GameInstall,$SteamExe,$Compiler,$Builder)){if([string]::IsNullOrWhiteSpace($path)){throw 'Complete original installation/client/compiler/builder paths required.'};Assert-RkNoLinks $path}
  Assert-RkSteamClient $SteamExe
  Assert-RkSteamRegistration (Split-Path $SteamExe) $GameInstall
  & $Python -B (Join-Path $repo 'tools/human_beta.py') --source $GameInstall --work $Work --compiler $Compiler --builder $Builder
  if($LASTEXITCODE -ne 0){throw 'Installed-game preparation failed; unsealed private evidence retained.'}
  Initialize-RkPrivateRoot $Work $owner
  return
 }
 Invoke-RkPython -Arguments @('verify-prepared','--work',$Work)
 if($Action -in @('Recover','Cleanup')){
  if($SessionName -cnotmatch '^human-[a-f0-9]{32}$'){throw 'Exact human session identifier required; no guessed recovery.'}
  $root=Join-Path $Work $SessionName
  $save=Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'UNDERTALE'
  $account=Enter-RkNativeAccountLease $save $owner $root
  try{
  Assert-RkNativeSaveTree $root
  $state=Read-RkJournal $root
  Assert-RkJournal $state $root $save $owner
  if($state.e2eKind -cne 'EXPERIMENTAL_HUMAN_BETA'){throw 'Not a human beta transaction.'}
  Assert-RkProcessesClosed;Assert-RkExperimentalNetwork
  if((Get-RkTreeDigest $state.gameInstall) -cne $state.registeredDigest -or !(Test-RkCacheEqual $state.cacheBefore (Get-RkSteamCacheInventory (Split-Path $state.steamExe)))){throw 'Registered installation/cache changed; preserve all copies.'}
  Restore-RkE2eSession $state $root $save $owner
  if($Action -eq 'Cleanup'){
   $game=Join-Path $root 'game';Assert-RkNativeSaveTree $game
   if(!(Test-RkCompletionFence $state) -or (Get-RkTreeDigest $game) -cne $state.runDigest){throw 'Owned game copy changed or restoration unproven; no cleanup.'}
   Remove-Item -LiteralPath $game -Recurse -Force
  }
  Write-Output 'LOCAL_RECOVERY_CONTENT_VERIFIED; ACCOUNT_HISTORY_NOT_RESTORED'
  }finally{Exit-RkNativeAccountLease $account}
  return
 }
 Assert-RkNoLinks $RequestFile
 if(!(Test-RkWithin $RequestFile (Join-Path $Work 'requests')) -or (Get-Item -LiteralPath $RequestFile).Length -gt 65536){throw 'Human launch request must be a bounded owned local file.'}
 $request=ConvertFrom-RkHumanJson (Get-Content -LiteralPath $RequestFile -Raw -Encoding UTF8) 'Request'
 Assert-RkHumanRequest $request;Assert-RkHumanParent $request
 if([IO.Path]::GetFileName($RequestFile) -cne ('request-'+$request.id+'.json')){throw 'Launch request filename/session mismatch.'}
 $request|Add-Member NoteProperty requestFile $RequestFile -Force
 $request|Add-Member NoteProperty requestSha256 ((Get-FileHash -LiteralPath $RequestFile).Hash.ToLowerInvariant()) -Force
 $SessionName='human-'+$request.id;$root=Join-Path $Work $SessionName
 if(Test-Path -LiteralPath $root){throw 'Human session already exists; resume means explicit recovery only.'}
 $native=Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) ('RoutekeeperE2E/native-beta-'+$request.id)
 Test-RkNativeDesktop $native
 $policy=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'human-beta-policy.json') -Raw -Encoding UTF8|ConvertFrom-Json
 $hasher=[Security.Cryptography.SHA256]::Create()
 try{$disclosureHash=([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($policy.disclosure)))).Replace('-','').ToLowerInvariant()}finally{$hasher.Dispose()}
 if($request.policy -cne $policy.id -or $request.disclosureSha256 -cne $disclosureHash){throw 'User-reviewed human policy differs from current disclosure.'}
 $consent=@{schema=1;policy=$policy.id;scope=('human-beta-'+$request.scope.ToLowerInvariant());session=$request.id;nonce=$request.nonce;
  disclosureSha256=$disclosureHash;recordedUtc=$request.issuedUtc;network=(Get-RkExperimentalNetworkRecord);credentialsStored=$false;
  approval=@{method='DIRECT_BETA_UI_PHRASE';statement=$request.phrase;humanScope=$request.scope;scenario=$request.scenario;highRiskPhrase=$request.highRiskPhrase}}
 $result=Invoke-RkGameSession -Work $Work -SteamExe $SteamExe -GameInstall $GameInstall -Consent $consent -NativeTest $native -Case $request.case -SessionName $SessionName -HumanContext $request
 Write-RkHumanSummary $root $request $result
 if($result.localRecovery -cne 'CONTENT_TREE_VERIFIED' -or $result.result -ceq 'BLOCKED'){exit 2}
} catch {
 # Full exception paths/proprietary diagnostics remain local; exported summaries
 # use only bounded result codes. Never synthesize successful recovery.
 $failure=$_
 if($privateErrorRoot){
  try{
   $errorPath=Join-Path $privateErrorRoot ('controller-error-'+[guid]::NewGuid().ToString('N')+'.log');Assert-RkNoLinks $errorPath
   $detail=($failure|Format-List * -Force|Out-String)+[Environment]::NewLine+$failure.ScriptStackTrace
   if($detail.Length -gt 65536){$detail=$detail.Substring(0,65536)}
   $errorBytes=[Text.Encoding]::UTF8.GetBytes($detail)
   $errorStream=[IO.File]::Open($errorPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
   try{$errorStream.Write($errorBytes,0,$errorBytes.Length);$errorStream.Flush($true)}finally{$errorStream.Dispose()}
  }catch{}
 }
 [Console]::Error.WriteLine('BLOCKED_NATIVE_GUARD_OR_RECOVERY; preserve private workspace and inspect local private controller-error logs.')
 exit 2
}
