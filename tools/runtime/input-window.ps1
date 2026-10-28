# Window-targeted messages only: no global SendInput, hooks or Steam input.
# GameMaker acceptance is unverified; a posted message is not an executed action.
function Initialize-RkWindowInput {
 if('RkWindowInput' -as [type]){return}
 Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class RkWindowInput {
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll",SetLastError=true)] public static extern bool PostMessage(IntPtr h,uint message,IntPtr key,IntPtr detail);
 [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint key,uint type);
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
}
'@
}
function Assert-RkInputWindow($Process,[IntPtr]$Window,[string]$Executable,[string]$Hash,[long]$StartTicks,[string]$AbortFile) {
 Assert-RkNoLinks $AbortFile
 if(Test-Path -LiteralPath $AbortFile){throw 'Emergency abort requested.'}
 $Process.Refresh()
 if($Process.HasExited -or $Process.StartTime.ToUniversalTime().Ticks -ne $StartTicks -or !$Process.Path.Equals($Executable,[StringComparison]::OrdinalIgnoreCase)){throw 'Input process identity changed.'}
 Assert-RkHash $Process.Path $Hash
 [uint32]$windowOwner=0
 $null=[RkWindowInput]::GetWindowThreadProcessId($Window,[ref]$windowOwner)
 if($Window -eq [IntPtr]::Zero -or $windowOwner -ne $Process.Id -or [RkWindowInput]::GetForegroundWindow() -ne $Window){throw 'Focus/window owner changed; no further input.'}
 if(([RkWindowInput]::GetAsyncKeyState(19) -band 0x8000) -ne 0){throw 'Pause emergency stop requested.'}
}
function Send-RkWindowKey($Process,[IntPtr]$Window,[string]$Executable,[string]$Hash,[long]$StartTicks,
 [ValidateSet('up','down','left','right','confirm','cancel','enter','settings','language','acknowledge')][string]$Key,
 [ValidateRange(50,500)][int]$HoldMs,[string]$AbortFile) {
 Initialize-RkWindowInput
 $keys=@{up=38;down=40;left=37;right=39;confirm=90;cancel=88;enter=13;settings=121;language=123;acknowledge=119}
 $code=[int]$keys[$Key];$scan=[RkWindowInput]::MapVirtualKey($code,0)
 $extended=if($code -in @(37,38,39,40)){16777216}else{0}
 $down=[IntPtr]::new([long](1 -bor ($scan -shl 16) -bor $extended))
 $up=[IntPtr]::new([long](3221225473 -bor ($scan -shl 16) -bor $extended))
 Assert-RkInputWindow $Process $Window $Executable $Hash $StartTicks $AbortFile
 $posted=$false;$startedUtc=[DateTime]::UtcNow.ToString('o')
 try {
  if(![RkWindowInput]::PostMessage($Window,256,[IntPtr]::new($code),$down)){throw 'Targeted key-down dispatch refused.'}
  $posted=$true;$watch=[Diagnostics.Stopwatch]::StartNew()
  while($watch.ElapsedMilliseconds -lt $HoldMs){
   Assert-RkInputWindow $Process $Window $Executable $Hash $StartTicks $AbortFile
   Start-Sleep -Milliseconds 10
  }
 } finally {
  # Release targets the original HWND only, even after focus loss. Never send
  # global releases into a newly focused app. No OS keyboard-state mutation.
  if($posted){
   $Process.Refresh()
   if($Process.HasExited -or $Process.StartTime.ToUniversalTime().Ticks -ne $StartTicks -or !$Process.Path.Equals($Executable,[StringComparison]::OrdinalIgnoreCase)){throw 'Input process changed during held key; no release to recycled owner.'}
   Assert-RkHash $Process.Path $Hash
   [uint32]$releaseOwner=0
   $null=[RkWindowInput]::GetWindowThreadProcessId($Window,[ref]$releaseOwner)
   if($releaseOwner -eq $Process.Id){
    if(![RkWindowInput]::PostMessage($Window,257,[IntPtr]::new($code),$up)){throw 'Targeted release failed; stop owned test process.'}
   }else{throw 'Original input window vanished/recycled; no release sent to its new owner.'}
  }
 }
 return @{kind='WINDOW_MESSAGE_DISPATCH';startedUtc=$startedUtc;finishedUtc=[DateTime]::UtcNow.ToString('o');key=$Key;requestedHeldMs=$HoldMs;heldMs=$watch.ElapsedMilliseconds;gameAction='UNPROVEN'}
}
