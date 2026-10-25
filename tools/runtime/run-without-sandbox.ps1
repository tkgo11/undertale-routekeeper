# Native Windows verification without Windows Sandbox.
# Requires a distinct, non-administrator RKTestOriginal/RKTestPatched local Windows account.
# Does not touch the primary user's Steam/game/save directories or Windows network settings.
param(
    [Parameter(Mandatory=$true)][string]$Lab,
    [Parameter(Mandatory=$true)][string]$PatchedData,
    [Parameter(Mandatory=$true)][ValidateSet('original','patched')][string]$Case,
    [switch]$AttestSeparateWindowsAccount,
    [switch]$AttestSteamOfflineAndCloudDisabled,
    [ValidateRange(1,240)][int]$Minutes=60
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'This harness requires native Windows.' }
if (!$AttestSeparateWindowsAccount -or !$AttestSteamOfflineAndCloudDisabled) {
    throw 'Explicit separate-account and Steam offline/Cloud-disabled attestations are required.'
}
$expectedUser=if ($Case -eq 'original') { 'RKTestOriginal' } else { 'RKTestPatched' }
$actualUser=([Security.Principal.WindowsIdentity]::GetCurrent().Name -split '\\')[-1]
if ($actualUser -cne $expectedUser -or $env:USERNAME -cne $expectedUser) {
    throw "Log in interactively as $expectedUser. Do not run against a personal Windows profile."
}
$actualHome=[Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
$actualLocal=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
if (-not $env:USERPROFILE.Equals($actualHome,[StringComparison]::OrdinalIgnoreCase) -or
    -not $env:LOCALAPPDATA.Equals($actualLocal,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'Untrusted USERPROFILE/LOCALAPPDATA environment override refused.'
}
if ($env:USERNAME -eq 'WDAGUtilityAccount') { throw 'Use the non-Sandbox test account.' }
$principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run as a standard local account, not an administrator.'
}
$Lab=(Resolve-Path -LiteralPath $Lab).Path
$PatchedData=(Resolve-Path -LiteralPath $PatchedData).Path
Assert-RkNoLinks $Lab
Assert-RkNoLinks $PatchedData
if (!(Test-RkWithin $Lab $env:USERPROFILE) -or !(Test-RkWithin $PatchedData $env:USERPROFILE)) {
    throw 'Private lab and candidate must both be under this disposable test account profile.'
}
if (!(Test-Path -LiteralPath (Join-Path $Lab '.routekeeper-disposable-runtime-lab') -PathType Leaf)) {
    throw 'A freshly prepared runtime lab is required.'
}
# Require manual disconnection; NEVER disable or change a host network adapter.
$active=@(Get-NetAdapter -ErrorAction Stop | Where-Object Status -eq 'Up')
if ($active.Count -gt 0) {
    throw 'Disconnect all Windows network adapters manually AFTER Steam is offline. Refusing any potential Cloud synchronization.'
}
$steamRoot=Join-Path $env:LOCALAPPDATA 'RKTestSteam'
$steam=Join-Path $steamRoot 'steam.exe'
$registered=Join-Path $steamRoot 'steamapps\common\Undertale'
$manifest=Join-Path $steamRoot 'steamapps\appmanifest_391540.acf'
foreach ($path in @($steamRoot,$steam,$registered,$manifest)) { Assert-RkNoLinks $path }
if (!(Test-Path -LiteralPath $steam -PathType Leaf) -or !(Test-Path -LiteralPath $manifest -PathType Leaf)) {
    throw 'Install owned Steam and UNDERTALE into this test account LocalAppData\RKTestSteam first.'
}
if (!(Test-Path -LiteralPath $registered -PathType Container)) { throw 'Registered game installation is missing.' }
$registration=Get-Content -LiteralPath $manifest -Raw
if ($registration -notmatch '"appid"\s+"391540"' -or $registration -notmatch '"installdir"\s+"Undertale"') {
    throw 'Incorrect Steam game registration.'
}
# The original test-install must already match the exact authorized Steam build.
$originalSha='b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'
$runnerSha='c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
Assert-RkHash (Join-Path $registered 'UNDERTALE.exe') $runnerSha
Assert-RkHash (Join-Path $registered 'data.win') $originalSha
if ($registration -notmatch '"buildid"\s+"4279148"') { throw 'Steam registration is not the pinned build.' }
$client=@(Get-Process steam -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.Equals($steam,[StringComparison]::OrdinalIgnoreCase) })
if ($client.Count -ne 1) { throw 'Only the dedicated test account Steam process is allowed; start it in Offline Mode.' }
if (Get-Process UNDERTALE -ErrorAction SilentlyContinue) { throw 'Close all UNDERTALE processes first.' }

$identity=Get-Content -LiteralPath (Join-Path $Lab 'identity-private.json') -Raw | ConvertFrom-Json
if ((Get-RkInventoryDigest $identity.files) -ne 'd0d633daad4d0c45a3f6761e9627ad7188853219ff96122b426d06b7a345932a') {
    throw 'Private inventory identity mismatch.'
}
$registry=Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\..\profiles\registry.json') -Raw | ConvertFrom-Json
$profiles=@($registry | Where-Object { $_.OriginalSha256 -eq $originalSha -and $_.ExecutableSha256 -eq $runnerSha })
if ($profiles.Count -ne 1) { throw 'No unique pinned compatibility profile.' }
$expectedPatched=$profiles[0].PatchedSha256
Assert-RkHash $PatchedData $expectedPatched
$original=Join-Path $Lab 'original'
Assert-RkHash (Join-Path $original 'Undertale\data.win') $originalSha
Assert-RkHash (Join-Path $original 'Undertale\UNDERTALE.exe') $runnerSha

$sessionRoot=Join-Path $env:LOCALAPPDATA 'RoutekeeperDirect'
$sessionFile=Join-Path $sessionRoot 'session.json'
$saveRoot=Join-Path $env:LOCALAPPDATA 'UNDERTALE'
Assert-RkNoLinks $sessionRoot
Assert-RkNoLinks $saveRoot
if (Test-Path -LiteralPath $sessionFile) {
    $session=Get-Content -LiteralPath $sessionFile -Raw | ConvertFrom-Json
    if ($session.schema -ne 1 -or $session.case -ne $Case -or $session.lab -ne $Lab -or $session.steamRoot -ne $steamRoot) {
        throw 'Cannot reuse a test profile for another case, Steam root or lab.'
    }
} else {
    if (Test-Path -LiteralPath $sessionRoot) { throw 'Existing unrecognized test session.' }
    if (Test-Path -LiteralPath $saveRoot) { throw 'Preexisting UNDERTALE saves: refusing to touch this profile.' }
    # No cached Steam Cloud/persistent-history data may predate this test session.
    $userdata=Join-Path $steamRoot 'userdata'
    Assert-RkNoLinks $userdata
    if (Test-Path -LiteralPath $userdata) {
        foreach ($account in Get-ChildItem -LiteralPath $userdata -Directory -Force) {
            $cache=Join-Path $account.FullName '391540'
            Assert-RkNoLinks $cache
            if ((Test-Path -LiteralPath $cache) -and @(Get-ChildItem -LiteralPath $cache -File -Recurse -Force).Count -gt 0) {
                throw 'Preexisting app391540 Steam cache: use a new, empty test profile.'
            }
        }
    }
    New-Item -ItemType Directory -Path $sessionRoot | Out-Null
    @{schema=1;case=$Case;lab=$Lab;steamRoot=$steamRoot} | ConvertTo-Json |
        Set-Content -LiteralPath $sessionFile
}

# Verify and stage only allowlisted game files. Never expose the supplied account manifest.
$id=[guid]::NewGuid().ToString('N')
$stage=Join-Path $Lab ('direct-runs\'+$Case+'-'+$id)
$evidence=Join-Path $Lab 'evidence\direct-windows'
$files=@()
$transaction=$null
$process=$null
$cleanupOk=$true
$report=[ordered]@{case=$Case;mode='NATIVE_WINDOWS_SEPARATE_ACCOUNT';result='NOT_RUN';runId=$id;
    claim='Observations only; gameplay and save/ending scenarios need explicit operator verification.'}
try {
    New-Item -ItemType Directory -Path $stage -Force | Out-Null
    New-Item -ItemType Directory -Path $evidence -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $stage '.routekeeper-direct-stage') -Value $id
    foreach ($file in $identity.files) {
        if (!$file.path.StartsWith('Undertale/')) { continue }
        $relative=$file.path.Substring(10)
        Assert-RkRelative $relative
        $source=Join-Path $original $file.path
        Assert-RkHash $source $file.sha256
        $destination=Join-Path $stage $relative
        New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination
        if ($Case -eq 'patched' -and $relative -eq 'data.win') {
            Copy-Item -LiteralPath $PatchedData -Destination $destination -Force
        }
        $digest=if ($Case -eq 'patched' -and $relative -eq 'data.win') { $expectedPatched } else { $file.sha256 }
        Assert-RkHash $destination $digest
        $files+=@{path=$relative;sha256=$digest}
    }
    if ($files.Count -lt 210) { throw 'Incomplete approved game inventory.' }
    $transaction=Start-RkDisposableInstall $stage $registered $files $id
    foreach ($file in $files) { Assert-RkHash (Join-Path $registered $file.path) $file.sha256 }
    # Exact Steam launch preserves Steam ownership checks. No emulator/DRM bypass.
    Start-Process -FilePath $steam -ArgumentList '-applaunch 391540' | Out-Null
    $until=(Get-Date).AddSeconds(45)
    do {
        Start-Sleep -Milliseconds 500
        $process=Get-Process UNDERTALE -ErrorAction SilentlyContinue |
            Where-Object { $_.Path -and $_.Path.Equals((Join-Path $registered 'UNDERTALE.exe'),[StringComparison]::OrdinalIgnoreCase) } |
            Select-Object -First 1
    } while (!$process -and (Get-Date) -lt $until)
    if (!$process) {
        $report.result='BLOCKED'
        $report.reason='Exact official Steam runner did not launch.'
    } else {
        $report.started=$true
        $report.runnerSha256=$runnerSha
        $report.dataSha256=if ($Case -eq 'patched') { $expectedPatched } else { $originalSha }
        $report.windowHandle=$process.MainWindowHandle.ToString()
        Write-Host 'Use this session for manual title/UI/battle/save testing. Close the game when finished.'
        if (!$process.WaitForExit($Minutes*60000)) {
            $report.timeout=$true
            Write-Warning 'Test time limit reached; the game will be closed before the original installation is restored.'
        }
        $process.Refresh()
        if (!$process.HasExited) {
            $null=$process.CloseMainWindow()
            if (!$process.WaitForExit(10000)) { $process.Kill();$process.WaitForExit() }
        }
        $report.exitCode=$process.ExitCode
        if ($process.ExitCode -ne 0) { $report.result='BLOCKED';$report.reason='Runner exited nonzero.' }
    }
} catch {
    $report.result='BLOCKED'
    $report.reason=$_.Exception.Message
    throw
} finally {
    if ($process -and !$process.HasExited) { $process.Kill();$process.WaitForExit() }
    try {
        if ($transaction) {
            foreach ($file in $files) { Assert-RkHash (Join-Path $registered $file.path) $file.sha256 }
            Stop-RkDisposableInstall $transaction
        }
    } catch {
        $cleanupOk=$false
        $report.result='BLOCKED';$report.cleanup=$_.Exception.Message
        Write-Warning 'Original test installation needs review; never delete the backup manually.'
    }
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence ($Case+'-'+$id+'.json'))
    # On restoration failure retain the staged files and VM-owned backup for recovery.
    # Otherwise remove only our own marked staging tree; never personal saves or Steam files.
    if ($cleanupOk -and (Test-Path -LiteralPath (Join-Path $stage '.routekeeper-direct-stage')) -and
        (Get-Content -LiteralPath (Join-Path $stage '.routekeeper-direct-stage') -Raw).Trim() -eq $id) {
        Assert-RkTreeNoLinks $stage
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
}
