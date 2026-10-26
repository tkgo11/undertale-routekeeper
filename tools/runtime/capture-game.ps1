# Best-effort foreground client rectangle. Screen overlays/focus races remain
# unverified; private output is not guaranteed window-isolated evidence.
param([ValidateSet('original','patched')][string]$Case='patched',
    [ValidatePattern('^[A-Za-z0-9_-]{1,40}$')][string]$Label='observation',
    [ValidateRange(0,10)][int]$DelaySeconds=0)
$ErrorActionPreference='Stop'
if ($env:USERNAME -ne 'WDAGUtilityAccount') { throw 'Disposable Sandbox account required.' }
. (Join-Path $PSScriptRoot 'safety.ps1')
Assert-RkNoLinks 'C:\RoutekeeperSession'
$state=Get-Content -LiteralPath 'C:\RoutekeeperSession\session.json' -Raw | ConvertFrom-Json
if ($state.schema -ne 2 -or $state.case -ne $Case) { throw 'Unknown or different disposable case.' }
if (Get-NetAdapter | Where-Object Status -eq 'Up') { throw 'VM must remain offline.' }
if ($DelaySeconds) { Start-Sleep -Seconds $DelaySeconds }
$process=Get-Process UNDERTALE -ErrorAction Stop | Select-Object -First 1
if (!(Test-Path -LiteralPath (Join-Path (Split-Path $process.Path) '.routekeeper-disposable-install'))) { throw 'Expected a marked disposable game.' }
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
if ($window -eq [IntPtr]::Zero -or [RoutekeeperCapture]::GetForegroundWindow() -ne $window) { throw 'Focus UNDERTALE before capture; screen overlays are not guaranteed to be excluded.' }
$rect=New-Object RoutekeeperCapture+Rect
$point=New-Object RoutekeeperCapture+Point
if (![RoutekeeperCapture]::GetClientRect($window,[ref]$rect) -or ![RoutekeeperCapture]::ClientToScreen($window,[ref]$point)) { throw 'Game client bounds unavailable.' }
if ($rect.Right -le 0 -or $rect.Bottom -le 0 -or $rect.Right -gt 8192 -or $rect.Bottom -gt 8192) { throw 'Unexpected game dimensions.' }
$bitmap=New-Object System.Drawing.Bitmap $rect.Right,$rect.Bottom
$graphics=[Drawing.Graphics]::FromImage($bitmap)
$directory='C:\RoutekeeperEvidence\native-windows'
New-Item -ItemType Directory -Path $directory -Force | Out-Null
try {
    $graphics.CopyFromScreen($point.X,$point.Y,0,0,$bitmap.Size)
    $bitmap.Save((Join-Path $directory ($Case+'-'+$Label+'-'+[guid]::NewGuid().ToString('N')+'.png')))
} finally { $graphics.Dispose(); $bitmap.Dispose() }
# A capture is evidence to review, never a scenario PASS or registry promotion.
