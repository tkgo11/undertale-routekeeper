# Strict protocol JSON: literal whitelisted property names, no duplicate names.
# All protocol objects have globally unique field names; escaped names are refused.
function ConvertFrom-RkHumanJson([string]$Raw,[ValidateSet('Request','Command')][string]$Kind) {
 if([string]::IsNullOrWhiteSpace($Raw) -or $Raw.Length -gt 65536){throw 'Invalid bounded human JSON.'}
 # ConvertFrom-Json enumerates a one-item root array in both supported shells.
 # Check framing before that conversion can erase the root container's type.
 $framed=$Raw.Trim()
 if(!$framed.StartsWith('{') -or !$framed.EndsWith('}')){throw 'Human JSON root must be an object.'}
 $allowed=if($Kind -eq 'Request'){@('schema','kind','id','betaSession','scenario','step','nonce','captureConsent','diagnosticConsent','case','scope','risk','phrase','highRiskPhrase','language','mode','maximumSeconds','issuedUtc','policy','disclosureSha256','parent','pid','ticks','path','sha256','continuationSession')}else{@('schema','session','sequence','action')}
 $seen=New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
 foreach($token in [regex]::Matches($Raw,'"(?:[^"\\]|\\.)*"')){
  $tail=$Raw.Substring($token.Index+$token.Length)
  if($tail -match '^\s*:'){
   $name=$token.Value.Substring(1,$token.Length-2)
   if($name.Contains('\') -or $name -cnotin $allowed -or !$seen.Add($name)){throw 'Duplicate, escaped or unknown protocol property.'}
  }
 }
 $value=$Raw|ConvertFrom-Json -ErrorAction Stop
 if($null -eq $value -or $value -is [Array] -or $value -isnot [pscustomobject]){throw 'Human JSON root must be an object.'}
 if($Kind -eq 'Request'){
  $top=@($allowed|Where-Object {$_ -cnotin @('pid','ticks','path','sha256')})
  if(@($value.PSObject.Properties.Name|Where-Object {$_ -cnotin $top}).Count -or $value.parent -isnot [pscustomobject] -or
     @($value.parent.PSObject.Properties.Name|Where-Object {$_ -cnotin @('pid','ticks','path','sha256')}).Count){throw 'Misplaced human request property.'}
 }
 return $value
}
function Assert-RkHumanLiveRequest($Request) {
 if(Test-Path -LiteralPath ($Request.requestFile+'.stop.json')){throw 'Human startup stop requested.'}
 Assert-RkHumanParent $Request
 Assert-RkHash $Request.requestFile $Request.requestSha256
}
# Human controls every game action. This protocol contains no gameplay inputs.
function Assert-RkHumanRequest($Request) {
 foreach($name in @('kind','id','betaSession','scenario','step','nonce','case','scope','risk','phrase','language','mode','policy','disclosureSha256')){
  if($Request.$name -isnot [string]){throw 'Human request string type required.'}
 }
 if($Request.parent -isnot [pscustomobject] -or
    ($null -ne $Request.highRiskPhrase -and $Request.highRiskPhrase -isnot [string]) -or
    ($Request.issuedUtc -isnot [string] -and $Request.issuedUtc -isnot [DateTime])){throw 'Invalid parent, high-risk phrase or time type.'}
 if(($Request.schema -isnot [int] -and $Request.schema -isnot [long]) -or
    $Request.policy -cne 'routekeeper-human-beta-v1' -or $Request.disclosureSha256 -cnotmatch '^[a-f0-9]{64}$' -or
    ($Request.parent.ticks -isnot [long] -and $Request.parent.ticks -isnot [int]) -or $Request.parent.path -isnot [string] -or
    $Request.parent.sha256 -isnot [string] -or
    ($null -ne $Request.continuationSession -and ($Request.continuationSession -isnot [string] -or ($Request.continuationSession -cne '' -and $Request.continuationSession -cnotmatch '^[a-f0-9]{32}$')))) {throw 'Invalid typed human request.'}
 if($Request.continuationSession -and ($Request.scope -eq 'Smoke' -or $Request.continuationSession -ceq $Request.id)){throw 'Continuation needs separate gameplay scope and a prior transaction.'}
 if($Request.schema -ne 1 -or $Request.kind -cne 'HUMAN_BETA_UI_REQUEST' -or
    $Request.id -cnotmatch '^[a-f0-9]{32}$' -or $Request.betaSession -cnotmatch '^[a-f0-9]{32}$' -or
    $Request.scenario -cnotmatch '^[a-z0-9-]{1,80}$' -or $Request.step -cnotmatch '^[a-z0-9-]{1,80}$' -or
    $Request.nonce -cnotmatch '^[a-f0-9]{32}$' -or $Request.captureConsent -isnot [bool] -or
    $Request.diagnosticConsent -isnot [bool] -or !$Request.diagnosticConsent -or $Request.case -cnotin @('original','patched') -or
    $Request.scope -cnotin @('Smoke','Gameplay','HighRisk') -or $Request.risk -cnotin @('NonDestructive','Gameplay','HighRisk') -or
    $Request.phrase -cne ('AUTHORIZE HUMAN BETA '+$Request.nonce) -or
    $Request.language -cnotin @('en','ko') -or $Request.mode -cnotin @('Off','Passive','Active','Forced')){throw 'Invalid or missing explicit human beta scope/consent.'}
 if($Request.scope -eq 'HighRisk' -and ($Request.highRiskPhrase -isnot [string] -or $Request.highRiskPhrase -cne ('AUTHORIZE HIGH RISK '+$Request.scenario))){throw 'Exact scenario-specific high-risk phrase required.'}
 if($Request.risk -eq 'HighRisk' -and ($Request.scope -cne 'HighRisk' -or $Request.highRiskPhrase -cne ('AUTHORIZE HIGH RISK '+$Request.scenario))){throw 'Ordinary smoke/gameplay consent cannot authorize a high-risk scenario.'}
 if($Request.risk -eq 'Gameplay' -and $Request.scope -eq 'Smoke'){throw 'Gameplay requires separate gameplay scope.'}
 if(($Request.maximumSeconds -isnot [int] -and $Request.maximumSeconds -isnot [long]) -or $Request.maximumSeconds -lt 60 -or
    $Request.maximumSeconds -gt 7200 -or ($Request.scope -eq 'Smoke' -and $Request.maximumSeconds -gt 300)){throw 'Human beta deadline outside its disclosed bounded scope.'}
 $date=if($Request.issuedUtc -is [DateTime]){$Request.issuedUtc.ToUniversalTime()}else{[DateTime]::Parse($Request.issuedUtc).ToUniversalTime()}
 $age=([DateTime]::UtcNow-$date).TotalSeconds
 if($age -lt 0 -or $age -gt 300){throw 'Human beta launch consent expired.'}
 if(($Request.parent.pid -isnot [int] -and $Request.parent.pid -isnot [long]) -or $Request.parent.pid -le 0 -or
    $Request.parent.pid -gt 2147483647 -or $Request.parent.ticks -le 0 -or $Request.parent.sha256 -cnotmatch '^[a-f0-9]{64}$' -or
    [string]::IsNullOrWhiteSpace($Request.parent.path)){throw 'Exact current Beta app process identity is required.'}
}
function Assert-RkHumanParent($Request) {
 $parent=Get-Process -Id $Request.parent.pid -ErrorAction Stop
 Assert-RkProcessIdentity @($parent) $Request.parent.pid $Request.parent.path $Request.parent.ticks
 Assert-RkHash $Request.parent.path $Request.parent.sha256
}
function Read-RkHumanCommand([string]$Root,[int]$Sequence,[string]$Session) {
 $path=Join-Path $Root ('human-command-'+$Sequence.ToString('D6')+'.json');Assert-RkNoLinks $path
 if(!(Test-Path -LiteralPath $path)){return $null}
 if((Get-Item -LiteralPath $path).Length -gt 4096){throw 'Human command exceeds its byte budget.'}
 $value=ConvertFrom-RkHumanJson (Get-Content -LiteralPath $path -Raw -Encoding UTF8) 'Command'
 if(($value.schema -isnot [int] -and $value.schema -isnot [long]) -or $value.session -isnot [string] -or $value.action -isnot [string] -or $value.schema -ne 1 -or $value.session -cne $Session -or $value.sequence -ne $Sequence -or
    ($value.sequence -isnot [int] -and $value.sequence -isnot [long]) -or $value.action -cnotin @('stop','capture')){throw 'Unknown, stale or mismatched human command.'}
 return $value
}
function Invoke-RkHumanLoop($Process,[string]$Runner,[string]$Root,$Request,$SteamProcess,[string]$SteamExe,[long]$SteamTicks,[ref]$UnknownChildren,[double]$RemainingSeconds) {
 $ticks=$Process.StartTime.ToUniversalTime().Ticks;$watch=[Diagnostics.Stopwatch]::StartNew();$sequence=1;$captures=0
 $events=New-Object 'Collections.Generic.List[object]'
 $events.Add(@{kind='OWNED_PROCESS_STARTED';utc=[DateTime]::UtcNow.ToString('o');pid=$Process.Id;classification='AutomatedObservation';scope='PROCESS_ONLY_NOT_GAMEPLAY'})
 Write-RkAtomicJson (Join-Path $Root 'human-status.json') @{schema=1;session=$Request.id;betaSession=$Request.betaSession;state='RUNNING_HUMAN';inputsDispatched=0;nextSequence=$sequence;events=@($events.ToArray())}
 while($watch.Elapsed.TotalSeconds -lt $RemainingSeconds){
  $Process.Refresh();if($Process.HasExited){
   $exitKind=if($Process.ExitCode -eq 0){'OWNED_PROCESS_EXITED'}else{'OWNED_PROCESS_ABNORMAL_EXIT'}
   $events.Add(@{kind=$exitKind;utc=[DateTime]::UtcNow.ToString('o');classification='AutomatedObservation';scope='PROCESS_ONLY_NOT_GAMEPLAY'});break
  }
  Update-RkExternalWatchdog;Assert-RkExperimentalNetwork;Assert-RkHumanLiveRequest $Request
  Assert-RkProcessIdentity @(Get-Process UNDERTALE -ErrorAction SilentlyContinue) $Process.Id $Runner $ticks
  Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $SteamProcess.Id $SteamExe $SteamTicks
  if(([RkWindowInput]::GetAsyncKeyState(19) -band 0x8000) -or (Test-Path -LiteralPath (Join-Path $Root 'abort.request'))){throw 'Human emergency stop requested.'}
  try{$children=@(Get-CimInstance Win32_Process -Filter ('ParentProcessId='+$Process.Id) -OperationTimeoutSec 5 -ErrorAction Stop)}catch{$UnknownChildren.Value=$true;throw}
  if($children.Count){$UnknownChildren.Value=$true;throw 'Unknown descendant during human session; preserve all copies.'}
  $command=Read-RkHumanCommand $Root $sequence $Request.id
  if($command){
   if($sequence -gt 1000){throw 'Human command budget exceeded.'}
   if($command.action -eq 'stop'){break}
   if(!$Request.captureConsent){throw 'Game screenshot collection was not authorized.'}
   if($captures -ge 100){throw 'Optional screenshot count budget exceeded.'}
   # Consume the capture command before the grace period so Stop remains usable.
   $sequence++
   Write-RkAtomicJson (Join-Path $Root 'human-status.json') @{schema=1;session=$Request.id;betaSession=$Request.betaSession;state='RUNNING_HUMAN';inputsDispatched=0;nextSequence=$sequence;capturePending=$true;events=@($events.ToArray())}
   $captureWait=[Diagnostics.Stopwatch]::StartNew();$stopDuringCapture=$false
   while($captureWait.Elapsed.TotalSeconds -lt 3){
    $Process.Refresh();if($Process.HasExited){
     $exitKind=if($Process.ExitCode -eq 0){'OWNED_PROCESS_EXITED'}else{'OWNED_PROCESS_ABNORMAL_EXIT'}
     $events.Add(@{kind=$exitKind;utc=[DateTime]::UtcNow.ToString('o');classification='AutomatedObservation';scope='PROCESS_ONLY_NOT_GAMEPLAY'})
     $stopDuringCapture=$true;break
    }
    Update-RkExternalWatchdog;Assert-RkExperimentalNetwork;Assert-RkHumanLiveRequest $Request
    if(([RkWindowInput]::GetAsyncKeyState(19) -band 0x8000) -or (Test-Path -LiteralPath (Join-Path $Root 'abort.request'))){throw 'Human emergency stop during capture grace period.'}
    $next=Read-RkHumanCommand $Root $sequence $Request.id
    if($next){if($next.action -eq 'stop'){$stopDuringCapture=$true;break}else{throw 'Another capture is already pending.'}}
    if($watch.Elapsed.TotalSeconds -ge $RemainingSeconds){$stopDuringCapture=$true;break}
    Start-Sleep -Milliseconds 100
   }
   if($stopDuringCapture){break}
   $Process.Refresh();if($Process.HasExited){break}
   Assert-RkProcessIdentity @(Get-Process UNDERTALE -ErrorAction SilentlyContinue) $Process.Id $Runner $ticks
   Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $SteamProcess.Id $SteamExe $SteamTicks
   $captures++;$name='human-capture-'+$captures.ToString('D3')+'.png'
   try{
    Save-RkClientCapture $Runner (Join-Path $Root $name)
    $events.Add(@{kind='OPTIONAL_CAPTURE_STORED';utc=[DateTime]::UtcNow.ToString('o');file=$name;classification='UnverifiedClaim';reviewedForSharing=$false})
   }catch{
    # Focus movement to the checklist is normal. Capture failure is visible and
    # must not refocus the game, send a key, or end an otherwise safe human trial.
    $events.Add(@{kind='OPTIONAL_CAPTURE_REFUSED';utc=[DateTime]::UtcNow.ToString('o');reason='CAPTURE_GUARD_REFUSED';classification='AutomatedObservation'})
   }
   Write-RkAtomicJson (Join-Path $Root 'human-status.json') @{schema=1;session=$Request.id;betaSession=$Request.betaSession;state='RUNNING_HUMAN';inputsDispatched=0;nextSequence=$sequence;events=@($events.ToArray())}
  }
  Start-Sleep -Milliseconds 100
 }
 $events.Add(@{kind='HUMAN_SESSION_STOP_REQUESTED';utc=[DateTime]::UtcNow.ToString('o');classification='AutomatedObservation';scope='PROCESS_ONLY_NOT_GAMEPLAY'})
 return @{schema=1;session=$Request.id;betaSession=$Request.betaSession;kind='HUMAN_CONTROLLED_NO_AUTOMATED_INPUT';inputsDispatched=0;events=@($events.ToArray());maximumSeconds=$Request.maximumSeconds;gameplay='NOT_INDEPENDENTLY_VERIFIED'}
}

# Continuation reads only an earlier same-work owned archive after verified local
# restoration. Personal saves are never used as fixtures; source archives remain.
function Get-RkHumanContinuation([string]$Work,$Request,[string]$Owner,[string]$Save,[string]$Case,[string]$PreparedSha256) {
 if(!$Request.continuationSession){return $null}
 if($Request.scope -eq 'Smoke'){throw 'Smoke cannot continue a saved trial.'}
 $priorRoot=Join-Path $Work ('human-'+$Request.continuationSession);Assert-RkNativeSaveTree $priorRoot
 $prior=Read-RkJournal $priorRoot;Assert-RkJournal $prior $priorRoot $Save $Owner
 foreach($name in @('e2eKind','betaSession','case','phase','preparedSha256','humanLanguage','humanMode','humanScope','steamExe','steamSha','gameInstall','registeredDigest')){if($prior.$name -isnot [string]){throw 'Typed prior-trial metadata required.'}}
 if($prior.humanScope -cnotin @('Smoke','Gameplay','HighRisk')){throw 'Prior trial scope is unsupported.'}
 if($prior.e2eKind -cne 'EXPERIMENTAL_HUMAN_BETA' -or $prior.betaSession -cne $Request.betaSession -or
    $prior.case -cne $Case -or $prior.phase -cne 'Restored' -or !(Test-RkCompletionFence $prior) -or
    $prior.preparedSha256 -cne $PreparedSha256 -or $prior.humanLanguage -cne $Request.language -or $prior.humanMode -cne $Request.mode){throw 'Continuation identity, build, configuration or completed restoration differs.'}
 if($prior.humanScope -eq 'HighRisk' -and ($Request.scope -cne 'HighRisk' -or $Request.highRiskPhrase -cne ('AUTHORIZE HIGH RISK '+$Request.scenario))){throw 'A prior high-risk trial needs fresh scenario-specific high-risk scope.'}
 if($prior.originalPresent -ne [bool](Test-Path -LiteralPath $Save) -or ($prior.originalPresent -and (Get-RkTreeDigest $Save) -cne $prior.originalDigest)){throw 'Personal baseline changed since the prior trial; no continuation.'}
 Assert-RkE2eRecoveryReady $prior $priorRoot $Save $Owner
 $archive=Join-Path $priorRoot 'trial-save';Assert-RkNativeSaveTree $archive
 if(!(Test-Path -LiteralPath $archive -PathType Container)){throw 'No owned saved trial archive is available.'}
 if(@(Get-ChildItem -LiteralPath $archive -Recurse -Force -File|Where-Object {$_.Name -like 'system_information_*'}).Count){throw 'Known permanent-history files block continuation; preserve the archive unchanged.'}
 $fencePath=Join-Path $priorRoot 'trial-fence.json';Assert-RkNoLinks $fencePath
 $fence=Get-Content -LiteralPath $fencePath -Raw -Encoding UTF8|ConvertFrom-Json
 foreach($name in @('id','owner','digest')){if($fence.$name -isnot [string]){throw 'Typed prior stop fence required.'}}
 if($fence.schema -ne 1 -or $fence.id -cne $prior.id -or $fence.owner -cne $Owner -or $fence.present -isnot [bool] -or !$fence.present -or
    $fence.digest -cnotmatch '^[a-f0-9]{64}$' -or (Get-RkTreeDigest $archive) -cne $fence.digest){throw 'Prior trial archive does not match its immutable stop fence.'}
 $resultPath=Join-Path $priorRoot 'result.json';$sealPath=Join-Path $priorRoot 'result-integrity.json'
 foreach($path in @($resultPath,$sealPath)){Assert-RkNoLinks $path}
 $seal=Get-Content -LiteralPath $sealPath -Raw -Encoding UTF8|ConvertFrom-Json
 if($seal.sha256 -isnot [string] -or $seal.sha256 -cnotmatch '^[a-f0-9]{64}$'){throw 'Invalid prior-result seal.'}
 Assert-RkHash $resultPath $seal.sha256
 $result=Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8|ConvertFrom-Json
 foreach($name in @('kind','humanSession','betaSession','case','result','localRecovery','localPhase','originalSha256','candidateSha256','runnerSha256')){if($result.$name -isnot [string]){throw 'Typed prior process receipt required.'}}
 $prepared=Get-Content -LiteralPath (Join-Path $Work 'prepared.json') -Raw -Encoding UTF8|ConvertFrom-Json
 if($result.originalSha256 -cne $prepared.originalSha256 -or $result.candidateSha256 -cne $prepared.candidateSha256 -or
    $result.runnerSha256 -cne 'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'){throw 'Prior result build identity differs.'}
 if($result.kind -cne 'HUMAN_BETA_SESSION' -or $result.humanSession -cne $Request.continuationSession -or
    $result.betaSession -cne $Request.betaSession -or $result.case -cne $Case -or $result.result -cne 'NEEDS_REVIEW' -or
    $result.localRecovery -cne 'CONTENT_TREE_VERIFIED' -or $result.localPhase -cne 'Restored' -or
    $result.copyStable -isnot [bool] -or !$result.copyStable -or $result.cacheStable -isnot [bool] -or !$result.cacheStable -or
    $result.registeredStable -isnot [bool] -or !$result.registeredStable){throw 'Prior process/recovery receipt is incomplete; preserve all copies.'}
 return @{archive=$archive;digest=$fence.digest;priorRoot=$priorRoot;preparedSha256=$PreparedSha256;steamExe=$prior.steamExe;steamSha=$prior.steamSha;gameInstall=$prior.gameInstall;registeredDigest=$prior.registeredDigest;cacheBefore=$prior.cacheBefore;
  journalSha256=(Get-FileHash -LiteralPath (Join-Path $priorRoot 'session.json')).Hash.ToLowerInvariant();
  fenceSha256=(Get-FileHash -LiteralPath $fencePath).Hash.ToLowerInvariant();resultSha256=$seal.sha256}
}
function Copy-RkHumanContinuation($Source,$State,[string]$Work) {
 if(!$Source){return}
 Assert-RkProcessesClosed;Assert-RkExperimentalNetwork
 foreach($check in @(@((Join-Path $Work 'prepared.json'),$Source.preparedSha256),@((Join-Path $Source.priorRoot 'session.json'),$Source.journalSha256),@((Join-Path $Source.priorRoot 'trial-fence.json'),$Source.fenceSha256),@((Join-Path $Source.priorRoot 'result.json'),$Source.resultSha256))){Assert-RkHash $check[0] $check[1]}
 Assert-RkNativeSaveTree $Source.archive;Assert-RkNativeSaveTree $State.savePath
 if(Test-Path -LiteralPath $State.savePath){throw 'Continuation target must be absent after personal-save quarantine.'}
 if((Get-RkTreeDigest $Source.archive) -cne $Source.digest){throw 'Continuation archive changed before staging.'}
 Copy-Item -LiteralPath $Source.archive -Destination $State.savePath -Recurse
 if((Get-RkTreeDigest $Source.archive) -cne $Source.digest -or (Get-RkTreeDigest $State.savePath) -cne $Source.digest){throw 'Continuation copy verification failed; preserve every tree.'}
}
