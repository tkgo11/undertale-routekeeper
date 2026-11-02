# GameMaker's direct keyboard/control backend requires guarded foreground OS input.
# A dispatch alone never proves that the game processed an action.
function Initialize-RkWindowInput {
 if('RkWindowInput' -as [type]){return}
 Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class RkWindowInput {
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint key,uint type);
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);
 [StructLayout(LayoutKind.Sequential)] public struct MouseInput { public int x,y; public uint data,flags,time; public UIntPtr extra; }
 [StructLayout(LayoutKind.Sequential)] public struct KeyboardInput { public ushort key,scan; public uint flags,time; public UIntPtr extra; }
 [StructLayout(LayoutKind.Explicit)] public struct InputUnion {
  [FieldOffset(0)] public MouseInput mouse;
  [FieldOffset(0)] public KeyboardInput keyboard;
 }
 [StructLayout(LayoutKind.Sequential)] public struct Input { public uint type; public InputUnion data; }
 [DllImport("user32.dll",SetLastError=true)] static extern uint SendInput(uint count,Input[] inputs,int size);
 public static uint SendScanKey(ushort scan,bool extended,bool release) {
  Input value=new Input();value.type=1;
  value.data.keyboard=new KeyboardInput { scan=scan,flags=(uint)(0x0008|(extended?0x0001:0)|(release?0x0002:0)) };
  return SendInput(1,new[]{value},Marshal.SizeOf(typeof(Input)));
 }
}
'@
}
function Assert-RkInputWindow($Process,[IntPtr]$Window,[string]$Executable,[string]$Hash,[long]$StartTicks,[string]$AbortFile) {
 if(Get-Command Assert-RkExternalWatchdog -ErrorAction SilentlyContinue){Assert-RkExternalWatchdog}
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
function Send-RkOwnedKey($Process,[IntPtr]$Window,[string]$Executable,[string]$Hash,[long]$StartTicks,
 [string]$Key,[int]$Code,[int]$Scan,[bool]$Extended,[int]$HoldMs,[string]$AbortFile,[scriptblock]$AdditionalGuard) {
 Assert-RkInputWindow $Process $Window $Executable $Hash $StartTicks $AbortFile
 if($AdditionalGuard){& $AdditionalGuard}
 if(([RkWindowInput]::GetAsyncKeyState($Code) -band 0x8000) -ne 0){throw 'Key already held; no OS input authorized.'}
 # Recheck the foreground immediately after any additional process guard.
 Assert-RkInputWindow $Process $Window $Executable $Hash $StartTicks $AbortFile
 $sent=$false;$startedUtc=[DateTime]::UtcNow.ToString('o');$watch=[Diagnostics.Stopwatch]::StartNew()
 try {
  if([RkWindowInput]::SendScanKey([uint16]$Scan,$Extended,$false) -ne 1){throw 'Owned foreground key-down dispatch refused.'}
  $sent=$true
  while($watch.ElapsedMilliseconds -lt $HoldMs){
   Assert-RkInputWindow $Process $Window $Executable $Hash $StartTicks $AbortFile
   if($AdditionalGuard){& $AdditionalGuard}
   Start-Sleep -Milliseconds 10
  }
  # Detect ownership/abort loss during the final hold interval as a failure too.
  Assert-RkInputWindow $Process $Window $Executable $Hash $StartTicks $AbortFile
  if($AdditionalGuard){& $AdditionalGuard}
  Assert-RkInputWindow $Process $Window $Executable $Hash $StartTicks $AbortFile
 } finally {
  # OS state is global. Release only our successfully injected key, even after
  # focus/process/abort loss. No new key-down is permitted during this cleanup.
  if($sent -and [RkWindowInput]::SendScanKey([uint16]$Scan,$Extended,$true) -ne 1){throw 'Injected key-up failed; stop owned test and inspect keyboard state.'}
 }
 $transport=if($Extended){'SendInput-scancode-extended'}else{'SendInput-scancode'}
 return @{kind='OWNED_FOREGROUND_KEY_DISPATCH';transport=$transport;releaseScope='GLOBAL_OS_KEYUP_FOR_OWN_INJECTED_KEY';startedUtc=$startedUtc;finishedUtc=[DateTime]::UtcNow.ToString('o');key=$Key;requestedHeldMs=$HoldMs;heldMs=$watch.ElapsedMilliseconds;gameAction='UNPROVEN'}
}
function Send-RkWindowKey($Process,[IntPtr]$Window,[string]$Executable,[string]$Hash,[long]$StartTicks,
 [ValidateSet('up','down','left','right','confirm','cancel','enter','settings','language','acknowledge')][string]$Key,
 [ValidateRange(50,500)][int]$HoldMs,[string]$AbortFile,[scriptblock]$AdditionalGuard) {
 Initialize-RkWindowInput
 $keys=@{up=38;down=40;left=37;right=39;confirm=90;cancel=88;enter=13;settings=121;language=123;acknowledge=119}
 $code=[int]$keys[$Key];$scan=[RkWindowInput]::MapVirtualKey($code,0)
 $extended=$Key -in @('up','down','left','right')
 return (Send-RkOwnedKey $Process $Window $Executable $Hash $StartTicks $Key $code $scan $extended $HoldMs $AbortFile $AdditionalGuard)
}
