# Official Steam launch only. All mutable game/save state stays inside the VM.
param([string]$Lab='C:\RoutekeeperInput',[string]$SteamRoot='C:\Program Files (x86)\Steam',
    [ValidateSet('original','patched')][string]$Case='original',[switch]$OfflineReady,
    [switch]$Interactive,[ValidateRange(1,240)][int]$Minutes=30)
$ErrorActionPreference = 'Stop'
if ($env:USERNAME -ne 'WDAGUtilityAccount') { throw 'Refusing to use a normal Windows account or its saves.' }
. (Join-Path $PSScriptRoot 'safety.ps1')
Assert-RkNoLinks $Lab
if (!(Test-Path -LiteralPath (Join-Path $Lab '.routekeeper-disposable-runtime-lab'))) { throw 'Missing disposable lab marker.' }
$evidence='C:\RoutekeeperEvidence\native-windows'
New-Item -ItemType Directory -Path $evidence -Force | Out-Null
if (!$OfflineReady) {
    @{result='BLOCKED'; reason='Inside this VM: authenticate owned Steam, disable game Cloud, install/register UNDERTALE without launching, enter Steam Offline Mode and restart Steam. Then rerun with -OfflineReady.'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $evidence 'setup.json')
    return
}
Assert-RkNoLinks $SteamRoot
if ($SteamRoot.StartsWith('\\') -or (Test-RkWithin $SteamRoot $Lab) -or (Test-RkWithin $SteamRoot 'C:\RoutekeeperEvidence')) { throw 'Steam must stay inside the disposable VM, outside host mappings.' }
$steam=Join-Path $SteamRoot 'steam.exe'
$client=@(Get-Process steam -ErrorAction SilentlyContinue | Where-Object Path -eq $steam)
if ($client.Count -ne 1) { throw 'The expected Steam client is not running. OfflineReady is operator attestation, not an entitlement check.' }
# Administrator is required. Disconnect every adapter before any game launch.
Get-NetAdapter | Where-Object Status -eq 'Up' | Disable-NetAdapter -Confirm:$false
if (Get-NetAdapter | Where-Object Status -eq 'Up') { throw 'Cannot establish offline VM isolation.' }
if (Get-Process UNDERTALE -ErrorAction SilentlyContinue) { throw 'Close the existing game first.' }
$stateRoot='C:\RoutekeeperSession'
$saveRoot=Join-Path $env:LOCALAPPDATA 'UNDERTALE'
Assert-RkNoLinks $saveRoot
if (!(Test-RkWithin $saveRoot $env:USERPROFILE) -or (Test-RkWithin $saveRoot $Lab) -or (Test-RkWithin $saveRoot 'C:\RoutekeeperEvidence')) { throw 'Save path must stay inside the disposable VM user profile.' }
Assert-RkNoLinks $stateRoot
$stateFile=Join-Path $stateRoot 'session.json'
if (!(Test-Path -LiteralPath $stateFile)) {
    if (Test-Path -LiteralPath $stateRoot) { throw 'Unexpected existing session directory.' }
    if (Test-Path -LiteralPath $saveRoot) { throw 'Preexisting saves detected; start a fresh Sandbox.' }
    $userdata=Join-Path $SteamRoot 'userdata'
    Assert-RkNoLinks $userdata
    if (Test-Path -LiteralPath $userdata) {
        foreach ($account in Get-ChildItem -LiteralPath $userdata -Directory -Force) {
            $cache=Join-Path $account.FullName '391540'
            Assert-RkNoLinks $cache
            if ((Test-Path -LiteralPath $cache) -and (Get-ChildItem -LiteralPath $cache -File -Recurse -Force -ErrorAction Stop)) { throw 'Existing app Cloud/cache files detected; start a fresh Sandbox.' }
        }
    }
    New-Item -ItemType Directory -Path $stateRoot | Out-Null
    $state=@{schema=2; case=$Case; steamRoot=$SteamRoot}
} else {
    $state=Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
    Assert-RkSession $state $Case $SteamRoot
}
$state | ConvertTo-Json | Set-Content -LiteralPath $stateFile
$installed=Join-Path $SteamRoot 'steamapps\common\Undertale'
Assert-RkNoLinks $installed
if (!(Test-Path -LiteralPath (Join-Path $SteamRoot 'steamapps\appmanifest_391540.acf'))) { throw 'Register owned UNDERTALE in the default VM Steam library first.' }
$files=Get-Content -LiteralPath (Join-Path $Lab 'files.json') -Raw | ConvertFrom-Json
$game=Join-Path $Lab ('runs\' + $Case)
foreach ($file in $files) { Assert-RkRelative $file.path; Assert-RkHash (Join-Path $game $file.path) $file.$Case }
Assert-RkHash (Join-Path $game 'UNDERTALE.exe') 'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
$manifestPath=Join-Path $SteamRoot 'steamapps\appmanifest_391540.acf'
Assert-RkNoLinks $manifestPath
$registration=Get-Content -LiteralPath $manifestPath -Raw
if ($registration -notmatch '"appid"\s+"391540"' -or $registration -notmatch '"installdir"\s+"Undertale"') { throw 'Unexpected Steam app/library registration.' }
$id=[guid]::NewGuid().ToString('N')
$report=[ordered]@{case=$Case; execution='NATIVE_WINDOWS'; result='NOT_RUN'; id=$id; note='Observations require manual scenario assertions.'}
$process=$null
$transaction=$null
try {
    $transaction=Start-RkDisposableInstall $game $installed $files $id
    $settings=Join-Path $stateRoot ('install-settings-'+$Case+'.ini')
    Assert-RkNoLinks $settings
    if (Test-Path -LiteralPath $settings) { Copy-Item -LiteralPath $settings -Destination (Join-Path $installed 'routekeeper.ini') }
    Start-Process -FilePath $steam -ArgumentList '-applaunch 391540' | Out-Null
    $deadline=(Get-Date).AddSeconds(30)
    do {
        Start-Sleep -Milliseconds 500
        $process=Get-Process UNDERTALE -ErrorAction SilentlyContinue | Where-Object Path -eq (Join-Path $installed 'UNDERTALE.exe') | Select-Object -First 1
    } while (!$process -and (Get-Date) -lt $deadline)
    if (!$process) { $report.result='BLOCKED'; $report.note='Steam did not launch the exact expected runner.'; return }
    foreach ($file in $files) { Assert-RkHash (Join-Path $installed $file.path) $file.$Case }
    $report.runnerSha256=(Get-FileHash -LiteralPath (Join-Path $installed 'UNDERTALE.exe')).Hash
    $report.dataSha256=(Get-FileHash -LiteralPath (Join-Path $installed 'data.win')).Hash
    try { & (Join-Path $PSScriptRoot 'capture-game.ps1') -Case $Case -Label startup } catch { $report.capture='NOT_RUN: '+$_.Exception.Message }
    if ($Interactive) {
        Write-Host 'Run the operator scenario checklist using only RKTEST saves. Close the game to finish; no automatic PASS is inferred.'
        if (!$process.WaitForExit($Minutes*60000)) { $report.note+=' Operator time limit reached.' }
    } else { Start-Sleep -Seconds 20 }
    $process.Refresh()
    if (!$process.HasExited) {
        $null=$process.CloseMainWindow()
        $report.cleanClose=$process.WaitForExit(10000)
        if (!$report.cleanClose) { $process.Kill(); $process.WaitForExit() }
    }
    $report.exitCode=$process.ExitCode
    if ($process.ExitCode -ne 0) { $report.result='BLOCKED'; $report.note+=' Runner returned a nonzero exit code.' }
    foreach ($file in $files) { Assert-RkHash (Join-Path $installed $file.path) $file.$Case }
} catch {
    $report.result='BLOCKED'; $report.note=$_.Exception.Message
    throw
} finally {
    if ($process -and !$process.HasExited) { $process.Kill(); $process.WaitForExit() }
    # Delete only this invocation's marked disposable copy. Preserve VM Steam's
    # registered original installation, even after a launch or assertion failure.
    try {
        if ($transaction) {
            Assert-RkTreeNoLinks $installed
            $writtenSettings=Join-Path $installed 'routekeeper.ini'
            if (Test-Path -LiteralPath $writtenSettings) { Copy-Item -LiteralPath $writtenSettings -Destination (Join-Path $stateRoot ('install-settings-'+$Case+'.ini')) -Force }
            Stop-RkDisposableInstall $transaction
        }
    } catch { $report.result='BLOCKED'; $report.cleanup=$_.Exception.Message }
    $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $evidence ($Case+'-'+$id+'.json'))
}
