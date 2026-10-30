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
# Reuse the same hash-pinned capture/sidecar implementation. This legacy
# account-specific wrapper grants no launch or Steam-isolation approval.
. (Join-Path $PSScriptRoot 'capture-client.ps1')
$directory='C:\RoutekeeperEvidence\native-windows'
Assert-RkNoLinks $directory
New-Item -ItemType Directory -Path $directory -Force | Out-Null
Save-RkClientCapture $process.Path (Join-Path $directory ($Case+'-'+$Label+'-'+[guid]::NewGuid().ToString('N')+'.png'))
