# Harmless protocol/filesystem fixtures; no Steam/game or native API calls.
param([string]$SummaryFixture)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'experimental-session.ps1')
. (Join-Path $PSScriptRoot 'human-loop.ps1')
$checks=0
function Check([bool]$Value,[string]$Name){if(!$Value){throw $Name};$script:checks++;Write-Output ('OFFLINE_PASS '+$Name)}
function Refuses([scriptblock]$Code,[string]$Name){$refused=$false;try{& $Code|Out-Null}catch{$refused=$true};Check $refused $Name}
$base=@{schema=1;kind='HUMAN_BETA_UI_REQUEST';id=('a'*32);betaSession=('b'*32);scenario='save-load';step='exercise';nonce=('c'*32);captureConsent=$false;diagnosticConsent=$true;case='patched';scope='HighRisk';risk='HighRisk';phrase=('AUTHORIZE HUMAN BETA '+('c'*32));highRiskPhrase='AUTHORIZE HIGH RISK save-load';language='en';mode='Passive';maximumSeconds=7200;issuedUtc=[DateTime]::UtcNow.ToString('o');policy='routekeeper-human-beta-v1';disclosureSha256=('d'*64);continuationSession='';parent=@{pid=123;ticks=123;sha256=('e'*64);path='SYNTHETIC_PHYSICAL_APP'}}
$raw=$base|ConvertTo-Json -Depth 8
$request=ConvertFrom-RkHumanJson $raw 'Request';Assert-RkHumanRequest $request
Check $true 'WPF-shaped strict request accepted without process launch'
foreach($mutation in @(@{schema='1'},@{scope='Smoke'},@{highRiskPhrase=@('AUTHORIZE HIGH RISK save-load')},@{issuedUtc=@('2026-11-03')},@{maximumSeconds=7201},@{maximumSeconds=59},@{captureConsent='false'},@{diagnosticConsent=$false},@{phrase='wrong'},@{issuedUtc=[DateTime]::UtcNow.AddMinutes(-6).ToString('o')},@{parent=@($base.parent)},@{continuationSession=$base.id})){
 $value=$base.Clone();foreach($key in $mutation.Keys){$value[$key]=$mutation[$key]}
 Refuses {Assert-RkHumanRequest (ConvertFrom-RkHumanJson ($value|ConvertTo-Json -Depth 8) 'Request')} ('typed request refusal: '+($mutation.Keys -join ','))
}
$duplicate=$raw -replace '"schema"\s*:\s*1','"schema": 1, "schema": 1'
Check ($duplicate -cne $raw) 'duplicate fixture mutates JSON across PowerShell formatting versions'
Refuses {ConvertFrom-RkHumanJson $duplicate 'Request'} 'duplicate field refused'
Refuses {ConvertFrom-RkHumanJson ($raw -replace '"schema"\s*:\s*1','"schema": 1, "unknown": 1') 'Request'} 'unknown field refused'
Refuses {ConvertFrom-RkHumanJson ($raw -replace '"schema"','"sch\u0065ma"') 'Request'} 'escaped protocol key refused'
$command='{"schema":1,"session":"'+('a'*32)+'","sequence":1,"action":"capture"}'
Check ((ConvertFrom-RkHumanJson $command 'Command').action -ceq 'capture') 'typed command JSON parsed'
Refuses {ConvertFrom-RkHumanJson ($command -replace '"sequence":1','"sequence":1,"sequence":2') 'Command'} 'duplicate command sequence refused'
# Execute the actual sanitized summary function without executing its entrypoint.
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'human-session.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Human session parse failed'}
$summary=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Write-RkHumanSummary'},$true))
if($summary.Count -ne 1){throw 'Unique summary function missing'}
Invoke-Expression $summary[0].Extent.Text
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$root=Join-Path $repo ('.research/human-beta-contract-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $root|Out-Null
try{
 $now=[DateTime]::UtcNow.ToString('o')
 $result=@{case='patched';result='NEEDS_REVIEW';localRecovery='CONTENT_TREE_VERIFIED';localPhase='Restored';copyStable=$true;cacheStable=$true;registeredStable=$true;originalSha256=('1'*64);candidateSha256=('2'*64);humanObservations=@{events=@(@{kind='OWNED_PROCESS_STARTED';utc=$now;pid=123;classification='AutomatedObservation';scope='PROCESS_ONLY_NOT_GAMEPLAY'},@{kind='OPTIONAL_CAPTURE_STORED';utc=$now;file='PRIVATE.png';classification='UnverifiedClaim'},@{kind='OPTIONAL_CAPTURE_REFUSED';utc=$now;reason='PRIVATE_ERROR'},@{kind='OWNED_PROCESS_ABNORMAL_EXIT';utc=$now})}}
 Write-RkHumanSummary $root $request $result
 $summaryRaw=Get-Content -LiteralPath (Join-Path $root 'human-summary.json') -Raw -Encoding UTF8
 $safe=$summaryRaw|ConvertFrom-Json
 Check ($safe.state -ceq 'RESTORED' -and @($safe.events).Count -eq 3 -and $summaryRaw -cnotmatch 'PRIVATE|"pid"|"file"|"reason"') 'summary exports only explicit process DTOs'
 Check ($safe.gameplay -ceq 'NOT_INDEPENDENTLY_VERIFIED' -and $safe.humanResults -ceq 'HUMAN_REPORTED_ONLY' -and $safe.accountHistory -ceq 'NOT_RESTORED') 'summary cannot assert gameplay or account restoration'
 if($SummaryFixture){$fixturePath=[IO.Path]::GetFullPath($SummaryFixture);if(!(Test-RkWithin $fixturePath (Join-Path $repo '.research')) -or (Test-Path -LiteralPath $fixturePath)){throw 'Fixture must be a new private research path'};Assert-RkNoLinks $fixturePath;[IO.File]::WriteAllText($fixturePath,$summaryRaw,[Text.UTF8Encoding]::new($false))}
 $result.copyStable=$false;Write-RkHumanSummary $root $request $result
 Check (((Get-Content -LiteralPath (Join-Path $root 'human-summary.json') -Raw -Encoding UTF8)|ConvertFrom-Json).state -ceq 'RECOVERY_REQUIRED') 'failed preservation cannot report restored'
 # Actual portable filesystem transaction helpers; Windows-only gates mocked.
 function Assert-RkNativeSaveTree([string]$Path){Assert-RkNoLinks $Path;if(Test-Path -LiteralPath $Path -PathType Container){Assert-RkTreeNoLinks $Path}}
 function Assert-RkProcessesClosed {}
 function Assert-RkExperimentalNetwork {}
 $work=Join-Path $root 'work';New-Item -ItemType Directory -Path $work|Out-Null
 $save=Join-Path $root 'isolated-save';$priorId='f'*32;$priorRoot=Join-Path $work ('human-'+$priorId);New-Item -ItemType Directory -Path $priorRoot|Out-Null
 $prepared=@{originalSha256=('1'*64);candidateSha256=('2'*64)};Write-RkAtomicJson (Join-Path $work 'prepared.json') $prepared
 $preparedHash=(Get-FileHash -LiteralPath (Join-Path $work 'prepared.json')).Hash.ToLowerInvariant()
 $prior=[pscustomobject]@{schema=2;owner='SYNTHETIC';root=$priorRoot;savePath=$save;id=('9'*32);case='patched';phase='Restored';originalPresent=$false;originalDigest='';e2eKind='EXPERIMENTAL_HUMAN_BETA';betaSession=$request.betaSession;preparedSha256=$preparedHash;humanLanguage='en';humanMode='Passive';humanScope='HighRisk';steamExe='SYNTHETIC_STEAM';steamSha=('8'*64);gameInstall='SYNTHETIC_REGISTERED';registeredDigest=('7'*64);cacheBefore=@{}}
 Save-RkJournal $prior;Write-RkCompletionFence $prior
 $archive=Join-Path $priorRoot 'trial-save';New-Item -ItemType Directory -Path $archive|Out-Null
 [IO.File]::WriteAllText((Join-Path $archive 'synthetic.txt'),'SYNTHETIC',[Text.UTF8Encoding]::new($false))
 $digest=Get-RkTreeDigest $archive;Write-RkAtomicJson (Join-Path $priorRoot 'trial-fence.json') @{schema=1;id=$prior.id;owner=$prior.owner;present=$true;digest=$digest}
 $result.copyStable=$true;$result.kind='HUMAN_BETA_SESSION';$result.humanSession=$priorId;$result.betaSession=$request.betaSession;$result.runnerSha256='c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
 Write-RkAtomicJson (Join-Path $priorRoot 'result.json') $result
 Write-RkAtomicJson (Join-Path $priorRoot 'result-integrity.json') @{sha256=(Get-FileHash -LiteralPath (Join-Path $priorRoot 'result.json')).Hash.ToLowerInvariant()}
 $request.continuationSession=$priorId
 $source=Get-RkHumanContinuation $work $request 'SYNTHETIC' $save 'patched' $preparedHash
 Check ($source.digest -ceq $digest) 'same owned restored trial archive eligible'
 [IO.File]::WriteAllText((Join-Path $archive 'system_information_962'),'SYNTHETIC',[Text.UTF8Encoding]::new($false))
 Refuses {Get-RkHumanContinuation $work $request 'SYNTHETIC' $save 'patched' $preparedHash} 'permanent-history archive cannot bypass preflight via continuation'
 Remove-Item -LiteralPath (Join-Path $archive 'system_information_962')
 foreach($field in @('betaSession','case','humanLanguage','humanMode','preparedSha256','phase')){
  $old=$prior.$field;$prior.$field='DIFFERENT';Save-RkJournal $prior
  Refuses {Get-RkHumanContinuation $work $request 'SYNTHETIC' $save 'patched' $preparedHash} ('continuation refuses differing '+$field)
  $prior.$field=$old;Save-RkJournal $prior
 }
 $request.scope='Gameplay';Refuses {Get-RkHumanContinuation $work $request 'SYNTHETIC' $save 'patched' $preparedHash} 'prior HighRisk cannot downgrade scope';$request.scope='HighRisk'
 $request.scope='Smoke';Refuses {Get-RkHumanContinuation $work $request 'SYNTHETIC' $save 'patched' $preparedHash} 'Smoke cannot continue saved trial';$request.scope='HighRisk'
 $source=Get-RkHumanContinuation $work $request 'SYNTHETIC' $save 'patched' $preparedHash
 Copy-RkHumanContinuation $source ([pscustomobject]@{savePath=$save}) $work
 Check ((Get-RkTreeDigest $save) -ceq $digest -and (Get-RkTreeDigest $archive) -ceq $digest) 'continuation copies without moving or changing prior archive'
 Refuses {Copy-RkHumanContinuation $source ([pscustomobject]@{savePath=$save}) $work} 'existing continuation target never overwritten'
 Remove-Item -LiteralPath $save -Recurse
 [IO.File]::WriteAllText((Join-Path $archive 'changed.txt'),'SYNTHETIC',[Text.UTF8Encoding]::new($false))
 Refuses {Copy-RkHumanContinuation $source ([pscustomobject]@{savePath=$save}) $work} 'changed source archive refused before copy'
 Check (!(Test-Path -LiteralPath $save)) 'failed archive validation leaves target absent'
 # Account-wide locks use real FileShare.None and durable markers on fixtures.
 function Initialize-RkPrivateRoot([string]$Path,[string]$Owner){Assert-RkNoLinks $Path;if(!(Test-Path -LiteralPath $Path)){New-Item -ItemType Directory -Path $Path|Out-Null}}
 $guardRoot=Join-Path $root 'account-guard'
 $handle=Enter-RkNativeAccountLease $save 'SYNTHETIC' $priorRoot -GuardRoot $guardRoot
 Set-RkNativeAccountMarker $prior
 Refuses {Enter-RkNativeAccountLease $save 'SYNTHETIC' $null -NewRun -GuardRoot $guardRoot} 'same-process new coordinator cannot reenter an active account transaction'
 $childScript=Join-Path $root 'lock-child.ps1'
 $childCode=@'
param($Runtime,$Guard,$Save)
$ErrorActionPreference='Stop'
. (Join-Path $Runtime 'safety.ps1')
. (Join-Path $Runtime 'experimental-session.ps1')
function Initialize-RkPrivateRoot($Path,$Owner){if(!(Test-Path -LiteralPath $Path)){New-Item -ItemType Directory -Path $Path|Out-Null}}
try{$lease=Enter-RkNativeAccountLease $Save 'SYNTHETIC' $null -NewRun -GuardRoot $Guard;Exit-RkNativeAccountLease $lease;exit 0}catch{exit 7}
'@
 [IO.File]::WriteAllText($childScript,$childCode,[Text.UTF8Encoding]::new($false))
 $shell=(Get-Process -Id $PID).Path
 & $shell -NoProfile -NonInteractive -File $childScript $PSScriptRoot $guardRoot $save
 Check ($LASTEXITCODE -eq 7) 'second process cannot acquire current-account lease'
 Exit-RkNativeAccountLease $handle
 Check (Test-Path -LiteralPath (Join-Path $guardRoot 'active.json')) 'account marker survives controller lease disposal/crash boundary'
 Refuses {Enter-RkNativeAccountLease $save 'SYNTHETIC' $null -NewRun -GuardRoot $guardRoot} 'new workspace cannot adopt an unresolved trial as personal data'
 Refuses {Enter-RkNativeAccountLease $save 'SYNTHETIC' (Join-Path $work 'different-root') -GuardRoot $guardRoot} 'recovery requires exact marked journal root'
 $handle=Enter-RkNativeAccountLease $save 'SYNTHETIC' $priorRoot -GuardRoot $guardRoot
 try{
  $prior.phase='Running';Save-RkJournal $prior
  Refuses {Complete-RkNativeAccountMarker $prior} 'unfinished restoration cannot clear durable marker'
  Check (Test-Path -LiteralPath (Join-Path $guardRoot 'active.json')) 'failed completion preserves marker'
  $prior.phase='Restored';$prior.steamExe=Join-Path $root 'steam.exe'
  # registered tree must be separate from mutable journals used by this fixture.
  $registered=Join-Path $root 'registered';New-Item -ItemType Directory -Path $registered|Out-Null
  [IO.File]::WriteAllText((Join-Path $registered 'synthetic.txt'),'SYNTHETIC',[Text.UTF8Encoding]::new($false))
  $prior.gameInstall=$registered;$prior.registeredDigest=Get-RkTreeDigest $registered;Save-RkJournal $prior
  function Get-RkSteamCacheInventory {param($Path) return @{}}
  function Test-RkCacheEqual {param($Before,$After) return $true}
  Refuses {Complete-RkNativeAccountMarker $prior -LegacyRecovery} 'legacy closure cannot bypass checks for experimental or arbitrary roots'
  Complete-RkNativeAccountMarker $prior
  Check (!(Test-Path -LiteralPath (Join-Path $guardRoot 'active.json'))) 'only verified exact restored journal closes account marker'
 }finally{Exit-RkNativeAccountLease $handle}
 $handle=Enter-RkNativeAccountLease $save 'SYNTHETIC' $null -NewRun -GuardRoot $guardRoot
 Exit-RkNativeAccountLease $handle
 Check $true 'verified restoration permits a later new transaction'
 # Execute real loop ordering with harmless process/window/observer mocks.
 if(!('RkWindowInput' -as [type])){Add-Type 'public static class RkWindowInput { public static short GetAsyncKeyState(int key) { return 0; } }'}
 function Update-RkExternalWatchdog {throw 'Terminal guardian receipt would refuse a heartbeat'}
 $process=[pscustomobject]@{Id=456;StartTime=[DateTime]::UtcNow;HasExited=$true;ExitCode=0};$process|Add-Member ScriptMethod Refresh {}
 $loopRoot=Join-Path $root 'loop-natural';New-Item -ItemType Directory -Path $loopRoot|Out-Null
 $unknown=$false
 $observation=Invoke-RkHumanLoop $process 'SYNTHETIC' $loopRoot $request $null 'SYNTHETIC' 1 ([ref]$unknown) 10
 Check (@($observation.events|Where-Object {$_.kind -ceq 'OWNED_PROCESS_EXITED'}).Count -eq 1) 'natural exit recorded before terminal guardian heartbeat race'
 $process.ExitCode=7
 $loopRoot=Join-Path $root 'loop-abnormal';New-Item -ItemType Directory -Path $loopRoot|Out-Null
 $observation=Invoke-RkHumanLoop $process 'SYNTHETIC' $loopRoot $request $null 'SYNTHETIC' 1 ([ref]$unknown) 10
 Check (@($observation.events|Where-Object {$_.kind -ceq 'OWNED_PROCESS_ABNORMAL_EXIT'}).Count -eq 1) 'nonzero naturally observed exit is process-only abnormal event'
 function Update-RkExternalWatchdog {}
 function Assert-RkHumanLiveRequest {param($Request)}
 function Assert-RkProcessIdentity {param($Observed,$PidValue,$Path,$Ticks)}
 function Get-Process {param($Name) return @()}
 function Get-CimInstance {param($ClassName,$Filter,$OperationTimeoutSec,$ErrorAction) return @()}
 $script:captureCalls=0
 function Save-RkClientCapture {param($Runner,$Destination) $script:captureCalls++}
 $process.HasExited=$false;$request.captureConsent=$true
 $loopRoot=Join-Path $root 'loop-stop-capture';New-Item -ItemType Directory -Path $loopRoot|Out-Null
 Write-RkAtomicJson (Join-Path $loopRoot 'human-command-000001.json') @{schema=1;session=$request.id;sequence=1;action='capture'}
 Write-RkAtomicJson (Join-Path $loopRoot 'human-command-000002.json') @{schema=1;session=$request.id;sequence=2;action='stop'}
 $observation=Invoke-RkHumanLoop $process 'SYNTHETIC' $loopRoot $request $null 'SYNTHETIC' 1 ([ref]$unknown) 10
 Check ($script:captureCalls -eq 0) 'Stop during capture grace avoids capture and exits safely'
 Check (((Get-Content -LiteralPath (Join-Path $loopRoot 'human-status.json') -Raw -Encoding UTF8)|ConvertFrom-Json).nextSequence -eq 2) 'capture grace publishes next command sequence for Stop'
 # Source ordering, not a Windows execution claim.
 $sessionSource=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'experimental-session.ps1') -Raw -Encoding UTF8
 Check ($sessionSource -match 'Assert-RkHumanLiveRequest \$HumanContext\}\s*Start-Process -FilePath \$SteamExe' -and $sessionSource -match 'Assert-RkHumanLiveRequest \$HumanContext\}\s*\$gameProcess=Start-Process') 'parent/request revalidation immediately precedes both launch operations'
 Check ($sessionSource -match 'if\(\$human\)\{Assert-RkHumanLiveRequest \$HumanContext\}\s*\$clients=' -and $sessionSource -match 'Update-RkExternalWatchdog\s*if\(\$human\)\{Assert-RkHumanLiveRequest') 'startup polling rechecks parent identity'
}finally{Remove-Item -LiteralPath $root -Recurse -Force}
Write-Output ('OFFLINE_PASS '+$checks+' human beta protocol/filesystem checks; native Windows/gameplay NOT_RUN')
