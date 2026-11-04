# Regression fixtures only: no host network changes, probes, Steam or game launches.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'current-account-windows.ps1')
$networkChecks=0
function NetworkCheck([bool]$Value,[string]$Name){if(!$Value){throw $Name};$script:networkChecks++;Write-Host ('OFFLINE_PASS '+$Name)}
function NetworkRefuses($Observation,[string]$Name){$refused=$false;try{Assert-RkOfflineObservation $Observation}catch{$refused=$true};NetworkCheck $refused $Name}
function NetworkFixture {
 return @{internet=$false;connectivity=0x202;adapters=@(
  @{hardware=$true;status='Disconnected'},
  @{hardware=$false;status='Up'}, # host-only/NAT/VPN/hidden miniport, no name exemption
  @{hardware=$false;status='Up'}
 )}
}
$offline=NetworkFixture
Assert-RkOfflineObservation $offline
NetworkCheck $true 'disconnected physical link permits active virtual and local-only interfaces'
foreach($status in @('Disconnected','Disabled','Not Present')){
 $observation=NetworkFixture;$observation.adapters[0].status=$status;Assert-RkOfflineObservation $observation
 NetworkCheck $true ('explicit physical offline status accepted: '+$status)
}
foreach($status in @('Up','Unknown','Dormant','Testing','', 'unrecognized')){
 $observation=NetworkFixture;$observation.adapters[0].status=$status
 NetworkRefuses $observation ('active or ambiguous physical status refused: '+$status)
}
foreach($flags in @(0x40,0x400,0x440,0x800,-1)){
 $observation=NetworkFixture;$observation.connectivity=$flags
 NetworkRefuses $observation ('Internet/unknown NLM flags refused despite false boolean: '+$flags)
}
$observation=NetworkFixture;$observation.internet=$true;NetworkRefuses $observation 'Internet boolean refused even with local-only flags'
$observation=NetworkFixture;$observation.internet='false';NetworkRefuses $observation 'string false cannot impersonate connectivity observation'
$observation=NetworkFixture;$observation.connectivity=$null;NetworkRefuses $observation 'missing NLM flags refused'
$observation=NetworkFixture;$observation.adapters=@();NetworkRefuses $observation 'empty inventory refused'
$observation=NetworkFixture;$observation.adapters=@(@{hardware=$false;status='Up'});NetworkRefuses $observation 'virtual-only inventory cannot certify physical disconnection'
foreach($value in @($null,'false',0)){
 $observation=NetworkFixture;$observation.adapters[1].hardware=$value;NetworkRefuses $observation 'unknown or coerced adapter classification refused'
}
$observation=NetworkFixture;$observation.adapters+=@{hardware=$true;status='Up'};NetworkRefuses $observation 'second connected uplink refused'
NetworkRefuses $null 'missing observation refused'
# Exercise the public gate without actually calling CIM or COM.
function Get-RkNetworkObservation {throw 'SYNTHETIC query failure'}
$refused=$false;try{Assert-RkNetworkOffline}catch{$refused=$true}
NetworkCheck $refused 'query failure propagates through public gate'
function Get-RkNetworkObservation {NetworkFixture}
Assert-RkNetworkOffline
NetworkCheck $true 'public gate accepts observed physical disconnection with virtual links up'
Write-Host ('OFFLINE_PASS network policy checks: '+$networkChecks+'; host networking unchanged')
