# Harmless mock/owned-fixture regression. Never starts Steam/game or touches saves.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'experimental-session.ps1')
$checks=0
function ProbeCheck([bool]$Value,[string]$Name){if(!$Value){throw $Name};$script:checks++;Write-Host ('OFFLINE_PASS '+$Name)}
$realSteamStop=${function:Stop-RkOwnedSteamClient}
function Stage([string]$Name){$script:events+=,$Name;if($Name -in $script:failStages){throw ('injected '+$Name)}}
function Save-RkJournal($State){Stage 'child-journal'}
function Stop-RkOwnedProbeProcess($Process,$Path,$Ticks){Stage 'game-stop'}
function Complete-RkExternalWatchdog {Stage 'watchdog-close'}
function Write-RkE2eGameStopBoundary($State){Stage 'game-stop-boundary'}
function Stop-RkOwnedSteamClient($Process,$Path,$Ticks,$Hash){Stage 'steam-shutdown'}
function Wait-RkProbeProcessesClosed {Stage 'process-offline-boundary'}
foreach($failed in @('', 'game-stop','watchdog-close','game-stop-boundary','steam-shutdown','process-offline-boundary')){
 $script:events=@();$script:failStages=@($failed)
 $outcome=Complete-RkProbeStopBoundary ([pscustomobject]@{steamSha='SYNTHETIC'}) $null '' 0 $null '' 0 $false
 ProbeCheck (($script:events -join ',') -ceq 'game-stop,watchdog-close,steam-shutdown,process-offline-boundary') ('independent cleanup stages attempted after '+$failed)
 # The game fixture must be truthy to exercise stop-boundary creation.
 $script:events=@()
 $outcome=Complete-RkProbeStopBoundary ([pscustomobject]@{steamSha='SYNTHETIC'}) @{owned=$true} '' 0 @{owned=$true} '' 0 $false
 $expected=if($failed -in @('game-stop','watchdog-close')){'game-stop,watchdog-close,steam-shutdown,process-offline-boundary'}else{'game-stop,watchdog-close,game-stop-boundary,steam-shutdown,process-offline-boundary'}
 ProbeCheck (($script:events -join ',') -ceq $expected) ('Steam shutdown survives preceding failures without publishing an unverified stop fence: '+$failed)
 ProbeCheck ($outcome.errors.Count -eq $(if($failed){1}else{0})) ('cleanup failure retained: '+$failed)
 if($failed){ProbeCheck ($outcome.errors[0].stage -ceq $failed -and $outcome.errors[0].reason -ceq ('injected '+$failed)) ('exact cleanup error preserved: '+$failed)}
}
$script:events=@();$script:failStages=@('child-journal','watchdog-close')
$state=[pscustomobject]@{steamSha='SYNTHETIC'}
$outcome=Complete-RkProbeStopBoundary $state @{owned=$true} '' 0 @{owned=$true} '' 0 $true
ProbeCheck ($state.unverifiedChildren -and $outcome.errors.Count -eq 3 -and 'steam-shutdown' -in $script:events -and 'game-stop-boundary' -notin $script:events) 'unknown children preserved; journal/guardian errors cannot skip shutdown or permit a stop fence'
# Execute the actual coordinator recovery block with harmless dependencies. Its
# real failure guard must prevent all trial fencing/restoration after stop errors.
$tokens=$null;$errors=$null
$sessionAst=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'experimental-session.ps1'),[ref]$tokens,[ref]$errors)
$recovery=@($sessionAst.FindAll({param($node) $node -is [Management.Automation.Language.TryStatementAst] -and $node.Body.Extent.Text -like '*$stopped=Complete-RkProbeStopBoundary*' -and $node.CatchClauses.Count -eq 1},$true))
if($errors -or $recovery.Count -ne 1){throw 'Unique coordinator recovery block not found'}
$recoveryCode=$recovery[0].Body.Extent.Text
$recoveryBlock=[scriptblock]::Create($recoveryCode.Substring(1,$recoveryCode.Length-2))
function Get-RkTreeDigest {param($Path) return 'SYNTHETIC-DIGEST'}
function Write-RkE2eTrialFence {param($State) Stage 'trial-fence'}
function Restore-RkE2eSession {param($State,$Root,$Save,$Owner) Stage 'restore';$State.phase='Restored'}
function Get-RkSteamCacheInventory {param($Path) return @{}}
function Test-RkCacheEqual {param($Before,$After) return $true}
foreach($failed in @('','game-stop','watchdog-close','game-stop-boundary','steam-shutdown','process-offline-boundary')){
 $script:events=@();$script:failStages=@($failed);$result=@{}
 $state=[pscustomobject]@{steamSha='SYNTHETIC';runDigest='SYNTHETIC-DIGEST';registeredDigest='SYNTHETIC-DIGEST';phase='Running';cacheBefore=@{}}
 $gameProcess=@{owned=$true};$runner='SYNTHETIC';$gameTicks=0;$steamProcess=@{owned=$true};$SteamExe='SYNTHETIC';$steamTicks=0;$unknownChildren=$false
 $refused=$false;try{& $recoveryBlock}catch{$refused=$true}
 ProbeCheck ($refused -eq [bool]$failed -and (('restore' -in $script:events) -eq !$failed) -and (('trial-fence' -in $script:events) -eq !$failed) -and 'steam-shutdown' -in $script:events) ('real coordinator forbids recovery after any failed stop boundary: '+$failed)
}
# Exercise real owned-client stop implementation with mocked observation/dispatch.
function Get-Process {param($Name) return @([pscustomobject]@{Id=42})}
function Assert-RkProcessIdentity {param($Processes,$Id,$Path,$Ticks) Stage 'steam-identity'}
function Assert-RkHash {param($Path,$Hash) Stage 'steam-hash'}
function Start-Process {param($FilePath,$ArgumentList) if($FilePath -cne 'SYNTHETIC-STEAM' -or $ArgumentList -cne '-shutdown'){throw 'unexpected dispatch'};Stage 'steam-dispatch'}
$client=[pscustomobject]@{Id=42;HasExited=$false};$client|Add-Member ScriptMethod Refresh {}
foreach($failed in @('','steam-identity','steam-hash')){
 $script:events=@();$script:failStages=@($failed);$refused=$false
 try{& $realSteamStop $client 'SYNTHETIC-STEAM' 123 'SYNTHETIC'}catch{$refused=$true}
 ProbeCheck ($refused -eq [bool]$failed -and (('steam-dispatch' -in $script:events) -eq !$failed)) ('normal shutdown requires owned identity/hash: '+$failed)
}
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$root=Join-Path $repo ('.research/probe-cleanup-'+[guid]::NewGuid().ToString('N'))
$sessionRoot=Join-Path $root 'active-session';New-Item -ItemType Directory -Path $sessionRoot | Out-Null
$image=Join-Path $sessionRoot 'original.png'
[IO.File]::WriteAllBytes($image,[Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='))
$started=[DateTime]::UtcNow
$runner='c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
$capture=@{schema=1;method='CopyFromScreen';imageSha256=(Get-FileHash -LiteralPath $image).Hash.ToLowerInvariant();runnerSha256=$runner;expectedRunnerSha256=$runner;foregroundBefore=$true;foregroundAfter=$true;pid=42;ownerPid=42;windowHandle=123;processStartedUtc=$started.ToString('o')}
$launch=@{stage='Observed';pid=42;startedTicks=$started.Ticks}
Write-RkAtomicJson ($image+'.json') $capture
Write-RkAtomicJson (Join-Path $sessionRoot 'game-launch.json') $launch
$probe=@{kind='EXPERIMENTAL_ORIGINAL_STARTUP_PROBE';result='NEEDS_REVIEW';case='original';processObserved=$true;inputsDispatched=0;capture='original.png';localRecovery='CONTENT_TREE_VERIFIED';localPhase='Restored';cacheStable=$true;registeredStable=$true;copyStable=$true;cleanupErrors=@();runnerSha256=$runner}
ProbeCheck ((Assert-RkOriginalProbeCompletion $probe $sessionRoot) -ceq 'NEEDS_REVIEW') 'capture completion remains review-only, never gameplay PASS'
# Match coordinator output shape: diagnostic JSON must never join its return value.
$returned=@(& {
 Invoke-RkProbeDiagnostic { '{'; '  "prepared": true'; '}' }
 Invoke-RkProbeDiagnostic { '{'; '  "nativeTest": "VERIFIED"'; '}' }
 $probe
})
ProbeCheck ($returned.Count -eq 1 -and [object]::ReferenceEquals($returned[0],$probe)) 'noisy diagnostics leave one structured probe return'
ProbeCheck ((Assert-RkOriginalProbeCompletion $returned[0] $sessionRoot) -ceq 'NEEDS_REVIEW') 'diagnostic output cannot turn capture-only completion into a blocked result'
$refused=$false
try{Invoke-RkProbeDiagnostic { '{'; '  "failure": true'; '}'; throw 'injected diagnostic failure' }}catch{$refused=$_.Exception.Message -ceq 'injected diagnostic failure'}
ProbeCheck $refused 'diagnostic exceptions propagate to the coordinator'
$diagnosticExe=Join-Path $PSHOME $(if($PSVersionTable.PSEdition -eq 'Core'){'pwsh.exe'}else{'powershell.exe'})
$global:LASTEXITCODE=0;$refused=$false
try{
 Invoke-RkProbeDiagnostic {
  & $diagnosticExe -NoProfile -Command 'Write-Output ''diagnostic child failure''; exit 7'
  if($LASTEXITCODE -ne 0){throw ('diagnostic child exit '+$LASTEXITCODE)}
 }
}catch{$refused=$_.Exception.Message -ceq 'diagnostic child exit 7'}
ProbeCheck ($refused -and $LASTEXITCODE -eq 7) 'diagnostic native failure keeps its nonzero status and exception'
$global:LASTEXITCODE=0
foreach($field in @('processObserved','cacheStable','registeredStable','copyStable')){
 $bad=$probe.Clone();$bad[$field]=$false;$refused=$false
 try{Assert-RkOriginalProbeCompletion $bad $sessionRoot|Out-Null}catch{$refused=$true}
 ProbeCheck $refused ('incomplete probe refused: '+$field)
}
foreach($change in @(@('localRecovery','BLOCKED_PRESERVE_ALL_COPIES'),@('localPhase','Running'),@('result','BLOCKED'),@('inputsDispatched',1),@('capture','../unknown.png'),@('cleanupErrors',@(@{stage='watchdog-close';reason='SYNTHETIC'})))){
 $bad=$probe.Clone();$bad[$change[0]]=$change[1];$refused=$false
 try{Assert-RkOriginalProbeCompletion $bad $sessionRoot|Out-Null}catch{$refused=$true}
 ProbeCheck $refused ('failed probe refused: '+$change[0])
}
foreach($field in @('pid','windowHandle','runnerSha256','imageSha256','processStartedUtc')){
 $bad=$capture.Clone();$bad[$field]=$(if($field -eq 'pid'){43}elseif($field -eq 'windowHandle'){0}elseif($field -eq 'processStartedUtc'){$started.AddSeconds(1).ToString('o')}else{'SYNTHETIC WRONG'})
 Write-RkAtomicJson ($image+'.json') $bad;$refused=$false
 try{Assert-RkOriginalProbeCompletion $probe $sessionRoot|Out-Null}catch{$refused=$true}
 ProbeCheck $refused ('capture/owned-launch binding refused: '+$field)
}
Write-RkAtomicJson ($image+'.json') $capture
Move-Item -LiteralPath ($image+'.json') -Destination ($image+'.missing')
$refused=$false;try{Assert-RkOriginalProbeCompletion $probe $sessionRoot|Out-Null}catch{$refused=$true}
ProbeCheck $refused 'missing capture sidecar refuses completion'
Move-Item -LiteralPath ($image+'.missing') -Destination ($image+'.json')
# Execute the exact Smoke branch in disposable child shells with observation
# functions mocked. This tests operator exit codes without any native launch.
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'test-windows.ps1'),[ref]$tokens,[ref]$errors)
$smoke=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Clauses[0].Item1.Extent.Text -ceq '$Mode -eq ''Smoke'''},$true))
if($errors -or $smoke.Count -ne 1){throw 'Unique Smoke branch not found'}
$body=$smoke[0].Clauses[0].Item2.Extent.Text
$body=$body.Substring(1,$body.Length-2)
$child=Join-Path $root 'mock-smoke.ps1'
$header=@'
param([string]$Repo,[string]$Work)
$ErrorActionPreference='Stop'
. (Join-Path $Repo 'tools/runtime/safety.ps1')
. (Join-Path $Repo 'tools/runtime/experimental-session.ps1')
function Invoke-RkOriginalProbe {Get-Content (Join-Path $Work 'fixture-probe.json') -Raw | ConvertFrom-Json}
function Invoke-RkPython {param($Arguments) [IO.File]::WriteAllText((Join-Path $Work 'report-generated.txt'),'SYNTHETIC REPORT')}
try {
'@
[IO.File]::WriteAllText($child,$header+"`n"+$body+"`n} catch { Write-Output `$_.Exception.Message; exit 2 }`n",[Text.UTF8Encoding]::new($false))
foreach($failed in @($false,$true)){
 $fixture=$probe.Clone();if($failed){$fixture.localRecovery='BLOCKED_PRESERVE_ALL_COPIES'}
 Write-RkAtomicJson (Join-Path $root 'fixture-probe.json') $fixture
 $exe=if($PSVersionTable.PSEdition -eq 'Core'){
  if([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT){Join-Path $PSHOME 'pwsh.exe'}else{Join-Path $PSHOME 'pwsh'}
 }else{Join-Path $PSHOME 'powershell.exe'}
 & $exe -NoProfile -File $child -Repo $repo -Work $root | Out-Null
 $exitCode=$LASTEXITCODE
 ProbeCheck ($exitCode -eq $(if($failed){2}else{0}) -and (Test-Path -LiteralPath (Join-Path $root 'report-generated.txt'))) ('Smoke retains report and returns honest exit status, failed='+$failed)
}
function Initialize-RkPrivateRoot {param($Path,$Owner) Stage 'private-acl'}
function Resolve-RkWatchdogPython {Stage 'resolve-guardian';return 'SYNTHETIC-PYTHONW'}
$script:events=@();$script:failStages=@();$refused=$false
try{Assert-RkProbeWorkReady $root 'Smoke' 'SYNTHETIC'}catch{$refused=$true}
ProbeCheck ($refused -and !$script:events.Count) 'existing probe Work refuses before consent/private initialization'
$fresh=Join-Path $root 'fresh-work';New-Item -ItemType Directory -Path $fresh | Out-Null
Assert-RkProbeWorkReady $fresh 'Smoke' 'SYNTHETIC'
ProbeCheck (($script:events -join ',') -ceq 'private-acl,private-acl,resolve-guardian') 'repeat ACL, lock and guardian readiness run before launch consent'
$held=[IO.File]::Open((Join-Path $fresh 'experiment.lock'),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try{
 $refused=$false;try{Assert-RkProbeWorkReady $fresh 'Smoke' 'SYNTHETIC'}catch{$refused=$true}
 ProbeCheck $refused 'busy experiment lock refuses before launch consent'
}finally{$held.Dispose()}
$script:failStages=@('resolve-guardian');$refused=$false
try{Assert-RkProbeWorkReady $fresh 'Smoke' 'SYNTHETIC'}catch{$refused=$true}
ProbeCheck $refused 'guardian resolution failure refuses before launch consent'
$released=[IO.File]::Open((Join-Path $fresh 'experiment.lock'),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None);$released.Dispose()
ProbeCheck $true 'readiness failure releases its experiment lock'
$global:LASTEXITCODE=0
Write-Host ('OFFLINE_PASS probe cleanup/completion checks: '+$checks+'; evidence '+$root)
