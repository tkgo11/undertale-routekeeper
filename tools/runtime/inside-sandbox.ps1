# Run only inside Windows Sandbox. The mapped lab contains disposable game copies.
param([string]$Lab = 'C:\RoutekeeperLab', [string]$SteamRoot = 'C:\Program Files (x86)\Steam')
$ErrorActionPreference = 'Stop'
if ($env:USERNAME -ne 'WDAGUtilityAccount') { throw 'Refusing to use a normal Windows account or its saves.' }
if (!(Test-Path (Join-Path $Lab '.routekeeper-disposable-runtime-lab'))) { throw 'Missing disposable lab marker.' }
Add-Type -AssemblyName System.Drawing
$saveRoot = Join-Path $env:LOCALAPPDATA 'UNDERTALE'
if (Test-Path $saveRoot) { throw 'Sandbox save directory already exists; start a fresh Sandbox session.' }
$evidence = 'C:\RoutekeeperEvidence\native-windows'
New-Item -ItemType Directory -Path $evidence -Force | Out-Null
$report = @()
if ($SteamRoot.StartsWith($Lab,[System.StringComparison]::OrdinalIgnoreCase) -or $SteamRoot.StartsWith('\\')) { throw 'Steam client/profile must stay inside the disposable VM, outside the host-mapped lab.' }
if (!(Get-Process steam -ErrorAction SilentlyContinue)) {
    @{ result='BLOCKED'; execution='NATIVE_WINDOWS'; reason='Start and authenticate a legitimately licensed Steam client inside this fresh Sandbox. Then rerun this script. No Steam API bypass is used.' } | ConvertTo-Json | Set-Content (Join-Path $evidence 'blocked.json')
    return
}
# Disconnect only this disposable VM before a game launch, preventing Cloud
# synchronization. Never map/copy a host Steam userdata directory into the VM.
Get-NetAdapter | Where-Object Status -eq 'Up' | Disable-NetAdapter -Confirm:$false
if (Get-NetAdapter | Where-Object Status -eq 'Up') { throw 'Cannot establish offline VM isolation.' }
$remote = @()
if (Test-Path (Join-Path $SteamRoot 'userdata')) { $remote = Get-ChildItem (Join-Path $SteamRoot 'userdata') -Directory -ErrorAction Stop | ForEach-Object { Join-Path $_.FullName '391540\remote' } }
foreach ($path in $remote) { if ((Test-Path $path) -and (Get-ChildItem $path -File -Recurse -ErrorAction Stop)) { throw 'Existing Steam Cloud cache detected; refusing to use personal game data.' } }
$installed = Join-Path $SteamRoot 'steamapps\common\Undertale'
if (!(Test-Path (Join-Path $SteamRoot 'steamapps\appmanifest_391540.acf'))) { throw 'Install/register owned UNDERTALE through Steam in this disposable VM first. Do not run it yet.' }

foreach ($kind in @('original','patched')) {
    # Separate fresh save state for the two runs. Only this newly-created Sandbox
    # account is touched; no host account/save path is mapped into the VM.
    if (Test-Path $saveRoot) { Move-Item $saveRoot (Join-Path $evidence ($kind + '-previous-disposable-save')) }
    $game = Join-Path $Lab ('runs\' + $kind)
    $exe = Join-Path $game 'UNDERTALE.exe'
    $runner = (Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($runner -ne 'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58') { throw 'Runner hash mismatch.' }
    if (Test-Path $installed) { Remove-Item $installed -Recurse -Force }
    Copy-Item $game $installed -Recurse
    Start-Process (Join-Path $SteamRoot 'steam.exe') -ArgumentList '-applaunch 391540' | Out-Null
    Start-Sleep -Seconds 5
    $process = Get-Process UNDERTALE -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $installed 'UNDERTALE.exe') } | Select-Object -First 1
    if (!$process) { $report += @{case=$kind;result='BLOCKED';execution='NATIVE_WINDOWS';reason='Steam did not launch the expected exact runner.'}; continue }
    Start-Sleep -Seconds 20
    $process.Refresh()
    if ((Get-FileHash (Join-Path $installed 'UNDERTALE.exe') -Algorithm SHA256).Hash.ToLowerInvariant() -ne $runner) { if (!$process.HasExited) { $process.Kill(); $process.WaitForExit() }; throw 'Steam changed the exact runner; refusing a mismatched result.' }
    $expectedData = (Get-FileHash (Join-Path $game 'data.win') -Algorithm SHA256).Hash
    if ((Get-FileHash (Join-Path $installed 'data.win') -Algorithm SHA256).Hash -ne $expectedData) { if (!$process.HasExited) { $process.Kill(); $process.WaitForExit() }; throw 'Steam changed the tested game data; refusing a mismatched result.' }
    $item = [ordered]@{ case=$kind; execution='NATIVE_WINDOWS'; result='NOT_RUN'; pid=$process.Id; alive=(!$process.HasExited); note='Captured observation; requires review and scenario assertions.' }
    if (!$process.HasExited) {
        $item.title = $process.MainWindowTitle
        $bitmap = New-Object System.Drawing.Bitmap 1024,768
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen(0,0,0,0,$bitmap.Size)
        $bitmap.Save((Join-Path $evidence ($kind + '-startup.png')))
        $graphics.Dispose(); $bitmap.Dispose()
        # This deliberately does not synthesize a gameplay PASS from a live window.
        $null = $process.CloseMainWindow()
        if (!$process.WaitForExit(10000)) { $process.Kill(); $process.WaitForExit(); $item.note += ' Close timed out; process terminated.' }
    }
    $item.exitCode = $process.ExitCode
    $report += $item
}
$report | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $evidence 'observations.json')
