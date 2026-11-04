# Pure in-process interop shim. No real OS input, Steam or game processes.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'input-window.ps1')
Add-Type @'
using System;
public static class RkWindowInput {
 public static int Downs,Ups; public static ushort LastDownScan,LastUpScan; public static bool DownExtended,UpExtended; public static bool Held,LoseFocus,Abort,Exit,FailDown,FailUp;
 public static IntPtr Focus=(IntPtr)1;
 public static uint MapVirtualKey(uint key,uint type){
 switch(key){case 38:return 0x48;case 40:return 0x50;case 37:return 0x4b;case 39:return 0x4d;
 case 90:return 0x2c;case 88:return 0x2d;case 13:return 0x1c;case 121:return 0x44;case 123:return 0x58;case 119:return 0x42;default:return 0;}
 }
 public static IntPtr GetForegroundWindow(){return Focus;}
 public static uint GetWindowThreadProcessId(IntPtr h,out uint pid){pid=456;return 1;}
 public static short GetAsyncKeyState(int key){return unchecked((short)((key==19?Abort:Held)?0x8000:0));}
 public static uint SendScanKey(ushort scan,bool extended,bool release){
  if(release){Ups++;LastUpScan=scan;UpExtended=extended;return FailUp?0u:1u;}
  Downs++;LastDownScan=scan;DownExtended=extended;if(FailDown)return 0;
  if(LoseFocus)Focus=(IntPtr)2;
  return 1;
 }
 public static void Reset(){Downs=Ups=0;LastDownScan=LastUpScan=0;DownExtended=UpExtended=false;Held=LoseFocus=Abort=Exit=FailDown=FailUp=false;Focus=(IntPtr)1;}
}
'@
function Assert-RkHash {}
function Assert-RkNoLinks {}
$game=[pscustomobject]@{Id=456;Path='C:\fixture\UNDERTALE.exe';StartTime=[DateTime]::UtcNow;HasExited=$false}
$game|Add-Member ScriptMethod Refresh {$this.HasExited=[RkWindowInput]::Exit}
$ticks=$game.StartTime.ToUniversalTime().Ticks;$hash='a'*64
$abortPath=Join-Path ([IO.Path]::GetTempPath()) ('rk-direction-no-abort-'+[Guid]::NewGuid().ToString('N'))
$checks=0
function Check([bool]$Value,[string]$Name){if(!$Value){throw $Name};$script:checks++;Write-Host ('PASS '+$Name)}
function Refuses([scriptblock]$Action,[string]$Name){$failed=$false;try{& $Action|Out-Null}catch{$failed=$true};Check $failed $Name}
function SendDirection([scriptblock]$Guard){Send-RkWindowKey $game ([IntPtr]1) $game.Path $hash $ticks $script:testKey 50 $abortPath -AdditionalGuard $Guard}
$script:testKey='left'
[RkWindowInput]::Reset()
$receipt=SendDirection
Check ([RkWindowInput]::Downs -eq 1 -and [RkWindowInput]::Ups -eq 1) 'one OS down has one OS release'
Check ($receipt.kind -ceq 'OWNED_FOREGROUND_KEY_DISPATCH' -and $receipt.gameAction -ceq 'UNPROVEN' -and $receipt.releaseScope -ceq 'GLOBAL_OS_KEYUP_FOR_OWN_INJECTED_KEY') 'receipt is truthful about global release and unproven response'
[RkWindowInput]::Reset();[RkWindowInput]::Held=$true
Refuses {SendDirection} 'preexisting held key refused'
Check ([RkWindowInput]::Downs -eq 0 -and [RkWindowInput]::Ups -eq 0) 'preexisting user key is neither pressed nor released'
[RkWindowInput]::Reset();[RkWindowInput]::Focus=[IntPtr]2
Refuses {SendDirection} 'wrong foreground refused before down'
Check ([RkWindowInput]::Downs -eq 0) 'no down into different foreground'
foreach($fault in @('focus','abort','identity','steam')){
 [RkWindowInput]::Reset();$script:guardCalls=0
 $guard={
  $script:guardCalls++
  if($script:guardCalls -ge 2){
   switch($fault){'focus'{[RkWindowInput]::Focus=[IntPtr]2};'abort'{[RkWindowInput]::Abort=$true};'identity'{[RkWindowInput]::Exit=$true};'steam'{throw 'Synthetic Steam identity loss'}}
  }
 }
 Refuses {SendDirection $guard} ($fault+' loss interrupts held direction')
 Check ([RkWindowInput]::Downs -eq 1 -and [RkWindowInput]::Ups -eq 1) ($fault+' loss releases only injected OS key without another down')
}
[RkWindowInput]::Reset()
Refuses {SendDirection {throw 'Synthetic Steam mismatch'}} 'Steam mismatch before down refuses'
Check ([RkWindowInput]::Downs -eq 0 -and [RkWindowInput]::Ups -eq 0) 'no OS event after initial Steam mismatch'
[RkWindowInput]::Reset();[RkWindowInput]::FailDown=$true
Refuses {SendDirection} 'failed OS down refuses'
Check ([RkWindowInput]::Ups -eq 0) 'failed OS down never releases an unowned key'
[RkWindowInput]::Reset();[RkWindowInput]::FailUp=$true
Refuses {SendDirection} 'OS release failure is reported'
# Every supported logical key must reach the correct physical scan code, and
# only arrows carry KEYEVENTF_EXTENDEDKEY. This catches Enter/F-key misencoding.
$expectedScans=@{up=0x48;down=0x50;left=0x4b;right=0x4d;confirm=0x2c;cancel=0x2d;enter=0x1c;settings=0x44;language=0x58;acknowledge=0x42}
foreach($logicalKey in $expectedScans.Keys){
 $script:testKey=$logicalKey;[RkWindowInput]::Reset()
 $receipt=SendDirection
 $extended=$logicalKey -in @('up','down','left','right')
 $transport=if($extended){'SendInput-scancode-extended'}else{'SendInput-scancode'}
 Check ([RkWindowInput]::Downs -eq 1 -and [RkWindowInput]::Ups -eq 1 -and [RkWindowInput]::LastDownScan -eq $expectedScans[$logicalKey] -and [RkWindowInput]::LastUpScan -eq $expectedScans[$logicalKey]) ($logicalKey+' has matching owned scan down/up')
 Check ([RkWindowInput]::DownExtended -eq $extended -and [RkWindowInput]::UpExtended -eq $extended -and $receipt.transport -ceq $transport -and $receipt.key -ceq $logicalKey) ($logicalKey+' has correct extended encoding and truthful transport')
 [RkWindowInput]::Reset();[RkWindowInput]::Held=$true
 Refuses {SendDirection} ($logicalKey+' refuses a preexisting held key')
 Check ([RkWindowInput]::Downs -eq 0 -and [RkWindowInput]::Ups -eq 0) ($logicalKey+' never releases a user-held key')
}
# Non-extended Enter must retain the same final ownership and cleanup boundaries.
$script:testKey='enter'
foreach($fault in @('focus','abort','identity','steam')){
 [RkWindowInput]::Reset();$script:guardCalls=0
 $guard={
  $script:guardCalls++
  if($script:guardCalls -ge 2){
   switch($fault){'focus'{[RkWindowInput]::Focus=[IntPtr]2};'abort'{[RkWindowInput]::Abort=$true};'identity'{[RkWindowInput]::Exit=$true};'steam'{throw 'Synthetic Steam identity loss'}}
  }
 }
 Refuses {SendDirection $guard} ('Enter '+$fault+' loss interrupts held key')
 Check ([RkWindowInput]::Downs -eq 1 -and [RkWindowInput]::Ups -eq 1 -and ![RkWindowInput]::UpExtended) ('Enter '+$fault+' loss releases only its injected nonextended key')
}
Write-Host ('DIRECTION_INPUT '+$checks+' PASS; no real OS input')
