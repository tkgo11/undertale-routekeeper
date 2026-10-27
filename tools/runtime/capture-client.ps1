# Best-effort foreground client pixels. This captures no game state, dispatches
# no input and starts no process. Overlays are NOT proven absent. Keep private.
function Save-RkClientCapture([string]$Executable,[string]$Destination,
 [ValidatePattern('^[a-f0-9]{64}$')][string]$ExpectedRunnerSha256='c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58') {
 Assert-RkNoLinks $Executable
 Assert-RkNoLinks $Destination
 Assert-RkNoLinks ($Destination+'.json')
 if((Test-Path -LiteralPath $Destination) -or (Test-Path -LiteralPath ($Destination+'.json'))){throw 'Capture outputs must be new.'}
 Assert-RkHash $Executable $ExpectedRunnerSha256
 $gameCandidates=@(Get-Process UNDERTALE -ErrorAction Stop | Where-Object {$_.Path -and $_.Path.Equals($Executable,[StringComparison]::OrdinalIgnoreCase)})
 if($gameCandidates.Count -ne 1){throw 'One exact side-copy runner must be active.'}
 $process=$gameCandidates[0]
 Assert-RkHash $process.Path $ExpectedRunnerSha256
 $processStarted=$process.StartTime.ToUniversalTime().ToString('o')
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
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out Rect rect);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref Point point);
}
'@
 }
 $null=[RoutekeeperCapture]::SetProcessDPIAware()
 $window=$process.MainWindowHandle
 if($window -eq [IntPtr]::Zero -or [RoutekeeperCapture]::GetForegroundWindow() -ne $window){throw 'Focus exact UNDERTALE client before capture.'}
 [uint32]$owner=0
 $null=[RoutekeeperCapture]::GetWindowThreadProcessId($window,[ref]$owner)
 if($owner -ne $process.Id){throw 'Window owner mismatch.'}
 $dpi=[RoutekeeperCapture]::GetDpiForWindow($window)
 if($dpi -le 0){throw 'Window DPI unavailable.'}
 $rect=New-Object RoutekeeperCapture+Rect
 $point=New-Object RoutekeeperCapture+Point
 if(![RoutekeeperCapture]::GetClientRect($window,[ref]$rect) -or ![RoutekeeperCapture]::ClientToScreen($window,[ref]$point)){throw 'Game client bounds unavailable.'}
 if($rect.Left -ne 0 -or $rect.Top -ne 0 -or $rect.Right % 320 -ne 0 -or $rect.Bottom % 240 -ne 0 -or $rect.Right/320 -ne $rect.Bottom/240 -or $rect.Right -lt 320 -or $rect.Right -gt 2560){throw 'Unsupported client geometry; do not distort evidence.'}
 $started=[DateTime]::UtcNow.ToString('o')
 $temp=$Destination+'.capture-'+[guid]::NewGuid().ToString('N')+'.tmp'
 $metaTemp=$temp+'.json'
 Assert-RkNoLinks $temp
 $bitmap=New-Object System.Drawing.Bitmap $rect.Right,$rect.Bottom
 $graphics=[Drawing.Graphics]::FromImage($bitmap)
 $published=$false
 try {
  $graphics.CopyFromScreen($point.X,$point.Y,0,0,$bitmap.Size)
  $after=New-Object RoutekeeperCapture+Rect
  $afterPoint=New-Object RoutekeeperCapture+Point
  [uint32]$afterOwner=0
  $null=[RoutekeeperCapture]::GetWindowThreadProcessId($window,[ref]$afterOwner)
  $process.Refresh()
  if($process.HasExited -or $process.MainWindowHandle -ne $window -or $process.StartTime.ToUniversalTime().ToString('o') -ne $processStarted -or $afterOwner -ne $process.Id -or [RoutekeeperCapture]::GetForegroundWindow() -ne $window){throw 'Capture process/focus changed.'}
  if(![RoutekeeperCapture]::GetClientRect($window,[ref]$after) -or ![RoutekeeperCapture]::ClientToScreen($window,[ref]$afterPoint) -or $after.Right -ne $rect.Right -or $after.Bottom -ne $rect.Bottom -or $point.X -ne $afterPoint.X -or $point.Y -ne $afterPoint.Y -or [RoutekeeperCapture]::GetDpiForWindow($window) -ne $dpi){throw 'Capture client geometry/DPI changed.'}
  Assert-RkHash $Executable $ExpectedRunnerSha256
  Assert-RkHash $process.Path $ExpectedRunnerSha256
  $imageStream=New-Object IO.FileStream($temp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$bitmap.Save($imageStream,[Drawing.Imaging.ImageFormat]::Png);$imageStream.Flush($true)}finally{$imageStream.Dispose()}
  $imageHash=(Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash.ToLowerInvariant()
  # No window title, executable path, desktop origin, username or Steam ID.
  $metadata=[ordered]@{schema=1;method='CopyFromScreen';imageSha256=$imageHash;clientSize=@($rect.Right,$rect.Bottom);foregroundBefore=$true;foregroundAfter=$true;ownerPid=[int]$owner;pid=$process.Id;runnerSha256=$ExpectedRunnerSha256;expectedRunnerSha256=$ExpectedRunnerSha256;processStartedUtc=$processStarted;startedUtc=$started;finishedUtc=[DateTime]::UtcNow.ToString('o');dpi=[int]$dpi;overlayIsolation='UNPROVEN';gameplay='NOT_RUN'}
  $bytes=[Text.Encoding]::UTF8.GetBytes(($metadata|ConvertTo-Json -Depth 8)+"`n")
  $stream=New-Object IO.FileStream($metaTemp,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
  Assert-RkNoLinks $Destination
  Assert-RkNoLinks ($Destination+'.json')
  [IO.File]::Move($temp,$Destination)
  $published=$true
  [IO.File]::Move($metaTemp,($Destination+'.json'))
 } catch {
  # A power loss between these two new-file moves leaves an image without a
  # sidecar; the verifier rejects it. Never synthesize missing metadata.
  if($published -and !(Test-Path -LiteralPath ($Destination+'.json'))){Remove-Item -LiteralPath $Destination -Force}
  throw
 } finally {
  $graphics.Dispose();$bitmap.Dispose()
  foreach($partial in @($temp,$metaTemp)){if(Test-Path -LiteralPath $partial){Remove-Item -LiteralPath $partial -Force}}
 }
}
