param([Parameter(Mandatory=$true)][string]$Lab,[Parameter(Mandatory=$true)][string]$PatchedData,[switch]$EnableSteamSetupNetworking)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
$Lab = (Resolve-Path -LiteralPath $Lab).Path
Assert-RkNoLinks $Lab
Assert-RkNoLinks $PatchedData
if (!(Test-Path -LiteralPath (Join-Path $Lab '.routekeeper-disposable-runtime-lab'))) { throw 'Prepare a new lab with tools/runtime_lab.py first.' }
$originalHash = 'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'
$runnerHash = 'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
$registry = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\..\profiles\registry.json') -Raw | ConvertFrom-Json
$profiles = @($registry | Where-Object OriginalSha256 -eq $originalHash)
if ($profiles.Count -ne 1 -or !$profiles[0].PatchedSha256) { throw 'Ambiguous or missing inspected profile.' }
$expected = $profiles[0].PatchedSha256
Assert-RkHash $PatchedData $expected
$identity = Get-Content -LiteralPath (Join-Path $Lab 'identity-private.json') -Raw | ConvertFrom-Json
if ((Get-RkInventoryDigest $identity.files) -ne 'd0d633daad4d0c45a3f6761e9627ad7188853219ff96122b426d06b7a345932a') { throw 'Original runtime inventory identity mismatch.' }
$original = Join-Path $Lab 'original'
Assert-RkHash (Join-Path $original 'Undertale\data.win') $originalHash
Assert-RkHash (Join-Path $original 'Undertale\UNDERTALE.exe') $runnerHash
# Map only an allowlisted payload, not the whole host lab or its private evidence.
$payload = Join-Path $Lab 'sandbox-input'
if (Test-Path -LiteralPath $payload) { throw 'Sandbox payload exists; use a newly prepared lab.' }
New-Item -ItemType Directory -Path $payload | Out-Null
$manifest = @()
foreach ($file in $identity.files) {
    if (!$file.path.StartsWith('Undertale/')) { continue }
    $relative = $file.path.Substring(10)
    Assert-RkRelative $relative
    $source = Join-Path $original $file.path
    Assert-RkHash $source $file.sha256
    foreach ($kind in @('original','patched')) {
        $destination = Join-Path $payload ('runs\' + $kind + '\' + $relative)
        New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination
        if ($kind -eq 'patched' -and $relative -eq 'data.win') { Copy-Item -LiteralPath $PatchedData -Destination $destination -Force }
    }
    $manifest += @{ path=$relative; original=$file.sha256; patched=$(if ($relative -eq 'data.win') { $expected } else { $file.sha256 }) }
}
if ($manifest.Count -lt 3) { throw 'Incomplete runtime allowlist.' }
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $payload 'files.json')
Set-Content -LiteralPath (Join-Path $payload '.routekeeper-disposable-runtime-lab') -Value 'Disposable authorized runtime payload. Never publish.'
foreach ($script in @('inside-sandbox.ps1','safety.ps1','checkpoint-saves.ps1','capture-game.ps1')) { Copy-Item -LiteralPath (Join-Path $PSScriptRoot $script) -Destination $payload }
$evidenceHost = Join-Path $Lab ('evidence\sandbox-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $evidenceHost | Out-Null
$escaped = [Security.SecurityElement]::Escape($payload)
$escapedEvidence = [Security.SecurityElement]::Escape($evidenceHost)
$network = if ($EnableSteamSetupNetworking) { 'Enable' } else { 'Disable' }
$configuration = @"
<Configuration>
  <Networking>$network</Networking><ClipboardRedirection>Disable</ClipboardRedirection>
  <PrinterRedirection>Disable</PrinterRedirection>
  <MappedFolders><MappedFolder><HostFolder>$escaped</HostFolder><SandboxFolder>C:\RoutekeeperInput</SandboxFolder><ReadOnly>true</ReadOnly></MappedFolder><MappedFolder><HostFolder>$escapedEvidence</HostFolder><SandboxFolder>C:\RoutekeeperEvidence</SandboxFolder><ReadOnly>false</ReadOnly></MappedFolder></MappedFolders>
  <LogonCommand><Command>powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\RoutekeeperInput\inside-sandbox.ps1</Command></LogonCommand>
</Configuration>
"@
$configuration | Set-Content -LiteralPath (Join-Path $Lab 'routekeeper.wsb')
Start-Process WindowsSandbox.exe -ArgumentList ('"' + (Join-Path $Lab 'routekeeper.wsb') + '"')
