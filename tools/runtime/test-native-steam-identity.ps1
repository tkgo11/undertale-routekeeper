# Mock-only native guard regression. No Steam/game launch or Windows input.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'native-gameplay.ps1')
. (Join-Path $PSScriptRoot 'input-window.ps1')
$checks=0
function Check([bool]$Value,[string]$Name){if(!$Value){throw $Name};$script:checks++;Write-Host ('PASS '+$Name)}
function Refuses([scriptblock]$Action,[string]$Name){$refused=$false;try{& $Action|Out-Null}catch{$refused=$true};Check $refused $Name}
$started=[DateTime]::UtcNow
$steam=[pscustomobject]@{Id=123;Path='C:\fixture\steam.exe';StartTime=$started}
$script:observedSteam=@($steam)
function Get-Process {param($Name,$ErrorAction) return $script:observedSteam}
$context=@{steamProcess=$steam;steamExe=$steam.Path;steamTicks=$started.Ticks}
Assert-RkNativeSteamIdentity $context
Check $true 'same pinned Steam identity accepted'
$script:observedSteam=@()
Refuses {Assert-RkNativeSteamIdentity $context} 'Steam exit refuses further native activity'
$script:observedSteam=@([pscustomobject]@{Id=124;Path=$steam.Path;StartTime=$started})
Refuses {Assert-RkNativeSteamIdentity $context} 'Steam restart PID refuses activity'
$script:observedSteam=@([pscustomobject]@{Id=123;Path=$steam.Path;StartTime=$started.AddSeconds(1)})
Refuses {Assert-RkNativeSteamIdentity $context} 'recycled PID with changed start refuses activity'
Refuses {Invoke-RkNativePlan $null '' 'nonexistent' 'original' '' '' ([ref]$false)} 'missing Steam context refuses before loading plan'

# Exercise actual dispatch/finally logic against an in-process inert API shim.
Add-Type @'
using System;
public static class RkWindowInput {
 public static int Downs=0, Ups=0;
 public static uint MapVirtualKey(uint key,uint type){return key;}
 public static short GetAsyncKeyState(int key){return 0;}
 public static uint SendScanKey(ushort scan,bool extended,bool release){if(release)Ups++;else Downs++;return 1;}
 public static bool PostMessage(IntPtr h,uint message,IntPtr key,IntPtr detail){if(message==256)Downs++;if(message==257)Ups++;return true;}
 public static uint GetWindowThreadProcessId(IntPtr h,out uint pid){pid=456;return 1;}
}
'@
function Assert-RkInputWindow {}
function Assert-RkHash {}
$game=[pscustomobject]@{Id=456;Path='C:\fixture\UNDERTALE.exe';StartTime=$started;HasExited=$false}
$game|Add-Member ScriptMethod Refresh {}
$hash='a'*64
Refuses {Send-RkWindowKey $game ([IntPtr]1) $game.Path $hash $started.Ticks 'confirm' 50 '' -AdditionalGuard {throw 'Steam exited'}} 'Steam guard refusal before dispatch'
Check ([RkWindowInput]::Downs -eq 0 -and [RkWindowInput]::Ups -eq 0) 'no key messages after initial Steam refusal'
$script:guardCalls=0
Refuses {Send-RkWindowKey $game ([IntPtr]1) $game.Path $hash $started.Ticks 'confirm' 50 '' -AdditionalGuard {$script:guardCalls++;if($script:guardCalls -ge 2){throw 'Steam restarted'}}} 'Steam restart during hold interrupts dispatch'
Check ([RkWindowInput]::Downs -eq 1 -and [RkWindowInput]::Ups -eq 1) 'interrupted hold releases only its injected OS key'
Write-Host ('NATIVE_STEAM_IDENTITY '+$checks+' PASS; no native processes or messages')
