# Foreground client-area evidence only; no gameplay PASS is inferred.
function Save-RkClientCapture([string]$Executable,[string]$Destination) {
 Assert-RkNoLinks $Destination
 $gameCandidates=@(Get-Process UNDERTALE -ErrorAction Stop | Where-Object {$_.Path -and $_.Path.Equals($Executable,[StringComparison]::OrdinalIgnoreCase)})
 if($gameCandidates.Count -ne 1){throw 'One exact side-copy runner must be active.'}
 $process=$gameCandidates[0]
Add-Type -AssemblyName System.Drawing
if (!('RoutekeeperCapture' -as [type])) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class RoutekeeperCapture {
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left,Top,Right,Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct Point { public int X,Y; }
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out Rect rect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref Point point);
}
'@
}
$null=[RoutekeeperCapture]::SetProcessDPIAware()
$window=$process.MainWindowHandle
if ($window -eq [IntPtr]::Zero -or [RoutekeeperCapture]::GetForegroundWindow() -ne $window) { throw 'Focus UNDERTALE before capture; other windows are excluded.' }
$rect=New-Object RoutekeeperCapture+Rect
$point=New-Object RoutekeeperCapture+Point
if (![RoutekeeperCapture]::GetClientRect($window,[ref]$rect) -or ![RoutekeeperCapture]::ClientToScreen($window,[ref]$point)) { throw 'Game client bounds unavailable.' }
if ($rect.Right -le 0 -or $rect.Bottom -le 0 -or $rect.Right -gt 8192 -or $rect.Bottom -gt 8192) { throw 'Unexpected game dimensions.' }
$bitmap=New-Object System.Drawing.Bitmap $rect.Right,$rect.Bottom
$graphics=[Drawing.Graphics]::FromImage($bitmap)
$directory=Split-Path $Destination
try {
    $graphics.CopyFromScreen($point.X,$point.Y,0,0,$bitmap.Size)
    $bitmap.Save($Destination)
} finally { $graphics.Dispose(); $bitmap.Dispose() }
}
