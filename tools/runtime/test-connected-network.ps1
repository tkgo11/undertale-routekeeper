# Policy tests only: no network APIs, Steam/game, or personal save access.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'experimental-session.ps1')
$checks=0;$script:offlineCalls=0;$script:offlineFailure=$true
function CheckNetwork([bool]$Value,[string]$Name){if(!$Value){throw $Name};$script:checks++;Write-Host ('POLICY_PASS '+$Name)}
function RefusesNetwork([scriptblock]$Action,[string]$Name){$blocked=$false;try{& $Action|Out-Null}catch{$blocked=$true};CheckNetwork $blocked $Name}
function Assert-RkNetworkOffline {$script:offlineCalls++;if($script:offlineFailure){throw 'SYNTHETIC CONNECTED'}}
function Read-Host {param($Prompt) return 'DECLINED'}
RefusesNetwork {Assert-RkExperimentalNetwork} 'default retains offline refusal'
CheckNetwork ($script:offlineCalls -eq 1) 'default dispatches original offline guard'
RefusesNetwork {Initialize-RkExperimentalNetwork -AllowConnectedNetwork} 'switch alone never grants risk consent'
CheckNetwork ((Get-RkExperimentalNetworkRecord).mode -ceq 'OFFLINE_REQUIRED') 'declined consent leaves offline default'
function Read-Host {param($Prompt) return $Prompt.Substring('Type exactly: '.Length)}
Initialize-RkExperimentalNetwork -AllowConnectedNetwork
$record=Get-RkExperimentalNetworkRecord
Assert-RkExperimentalNetwork
CheckNetwork ($script:offlineCalls -eq 1 -and $record.mode -ceq 'CONNECTED_RISK_ACCEPTED' -and $record.accountHistory -ceq 'NOT_RESTORED') 'connected scope remains explicit and never claims restoration'
CheckNetwork ($record.controllerPid -eq $PID -and $record.nonce -cmatch '^[a-f0-9]{32}$') 'risk receipt binds current controller and fresh nonce'
$record.mode='TAMPER'
CheckNetwork ((Get-RkExperimentalNetworkRecord).mode -ceq 'CONNECTED_RISK_ACCEPTED') 'exported receipt cannot mutate active policy'
foreach($field in @('mode','controllerPid','nonce','disclosure')){
 $original=$script:RkConnectedNetworkConsent[$field]
 $script:RkConnectedNetworkConsent[$field]=$(if($field -eq 'controllerPid'){-1}else{'TAMPER'})
 RefusesNetwork {Assert-RkExperimentalNetwork} ('invalid risk context refused: '+$field)
 $script:RkConnectedNetworkConsent[$field]=$original
}
$session=[guid]::NewGuid().ToString('N');$nonce=[guid]::NewGuid().ToString('N')
$launch=New-RkExperimentalConsent $session $nonce
CheckNetwork ($launch.network.nonce -ceq (Get-RkExperimentalNetworkRecord).nonce -and $launch.nonce -ceq $nonce -and $launch.session -ceq $session) 'separate launch consent records exact active network scope'
Assert-RkLaunchNetworkConsent $launch
foreach($field in @('mode','nonce')){
 $bad=$launch.Clone();$bad.network=$launch.network.Clone();$bad.network[$field]='TAMPER'
 RefusesNetwork {Assert-RkLaunchNetworkConsent $bad} ('launch network scope mismatch refused: '+$field)
}
function Read-Host {param($Prompt) return 'DECLINED'}
RefusesNetwork {New-RkExperimentalConsent $session $nonce} 'network acceptance never substitutes for launch consent'
Initialize-RkExperimentalNetwork
RefusesNetwork {Assert-RkExperimentalNetwork} 'reset restores offline refusal'
$script:offlineFailure=$false
Assert-RkExperimentalNetwork
RefusesNetwork {Assert-RkLaunchNetworkConsent $launch} 'connected launch consent cannot transfer to valid offline controller scope'
CheckNetwork ((Get-RkExperimentalNetworkRecord).mode -ceq 'OFFLINE_REQUIRED') 'offline default still accepts independently offline host'
# Documentary chat delegation is explicitly labelled; never fake terminal input.
function Read-Host {throw 'Delegated mode must not spoof an interactive answer'}
RefusesNetwork {New-RkApprovalRecord -OwnerDelegatedOriginalProbe} 'delegation without owner statement refused'
RefusesNetwork {New-RkApprovalRecord -OwnerDelegatedOriginalProbe -ApprovalStatement 'SHORT'} 'short delegated statement refused'
RefusesNetwork {New-RkApprovalRecord -ApprovalStatement 'A sufficiently long statement without delegated selection'} 'statement alone cannot select delegated execution'
$statement='SYNTHETIC owner explicitly requests connected original no-input execution without personal controls.'
Initialize-RkExperimentalNetwork -AllowConnectedNetwork -OwnerDelegatedOriginalProbe -ApprovalStatement $statement
$delegated=New-RkExperimentalConsent $session $nonce -OwnerDelegatedOriginalProbe -ApprovalStatement $statement
Assert-RkLaunchNetworkConsent $delegated
Assert-RkDelegatedOriginalScope $delegated 'original' '' 'active-session'
CheckNetwork ($delegated.approval.method -ceq 'OWNER_CHAT_DELEGATION' -and $delegated.approval.statement -ceq $statement -and $delegated.network.approval.method -ceq 'OWNER_CHAT_DELEGATION') 'delegated original receipt is honest and separate from terminal input'
foreach($scope in @(@('patched','','active-session'),@('original','UNREVIEWED_PLAN','active-session'),@('original','','original-baseline'))){
 RefusesNetwork {Assert-RkDelegatedOriginalScope $delegated $scope[0] $scope[1] $scope[2]} 'delegation cannot authorize patched, gameplay input or navigation baseline'
}
Initialize-RkExperimentalNetwork
if([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT){
 $nativePath=[IO.Path]::GetFullPath($PSScriptRoot)
 CheckNetwork ((Get-RkCanonicalExecutionPath ($nativePath.Replace('\','/')+'/../runtime')) -ceq $nativePath) 'execution path normalizes slash variants before exact process identity comparison'
}
# Explicit later UI delegation is separate from original-only documentary consent.
RefusesNetwork {New-RkApprovalRecord -OwnerDelegatedUiExperiment} 'UI delegation requires statement'
RefusesNetwork {New-RkApprovalRecord -OwnerDelegatedUiExperiment -OwnerDelegatedOriginalProbe -ApprovalStatement $statement} 'mixed delegated scopes refused'
Initialize-RkExperimentalNetwork -AllowConnectedNetwork -OwnerDelegatedUiExperiment -ApprovalStatement $statement
$ui=New-RkExperimentalConsent $session $nonce -OwnerDelegatedUiExperiment -ApprovalStatement $statement
Assert-RkLaunchNetworkConsent $ui
CheckNetwork ($ui.approval.method -ceq 'OWNER_CHAT_UI_DELEGATION' -and $ui.approval.reviewMethod -ceq 'AGENT_DELEGATED') 'UI delegation never claims human review'
Assert-RkDelegatedOriginalScope $ui 'original' '' 'active-session' $true
Assert-RkDelegatedOriginalScope $ui 'patched' 'VALIDATED_PLAN' 'active-session'
RefusesNetwork {Assert-RkDelegatedOriginalScope $ui 'original' '' 'active-session'} 'UI scope cannot become unrestricted original no-plan execution'
. (Join-Path $PSScriptRoot 'native-acquisition.ps1')
$request=@{schema=1;sequence=1;captureSha256=('a'*64);reviewMethod='AGENT_DELEGATED';reviewStatement='SYNTHETIC recognized safe title screen; Enter only';recordedUtc=[DateTime]::UtcNow.ToString('o');action='enter';holdMs=100}
# Test actual ConvertFrom-Json integer/date representations on both PS editions.
$decoded=$request|ConvertTo-Json|ConvertFrom-Json
Assert-RkAcquisitionRequest $decoded 1 ('a'*64)
CheckNetwork $true 'actual JSON integer/date request accepted'
foreach($field in @('captureSha256','reviewMethod','sequence','recordedUtc','action','holdMs')){
 $bad=$request.Clone()
 $bad[$field]=switch($field){'sequence'{2};'recordedUtc'{[DateTime]::UtcNow.AddMinutes(-1).ToString('o')};'holdMs'{1000};default{'TAMPER'}}
 RefusesNetwork {Assert-RkAcquisitionRequest $bad 1 ('a'*64)} ('unsafe/stale acquisition field refused: '+$field)
}
Initialize-RkExperimentalNetwork
Write-Host ('CONNECTED_NETWORK_POLICY '+$checks+' PASS; no native execution')
