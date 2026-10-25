param([Parameter(Mandatory=$true)][string]$Lab,[Parameter(Mandatory=$true)][string]$PatchedData,[switch]$EnableSteamSetupNetworking)
$ErrorActionPreference = 'Stop'
$Lab = (Resolve-Path $Lab).Path
if (!(Test-Path (Join-Path $Lab '.routekeeper-disposable-runtime-lab'))) { throw 'Prepare a new lab with tools/runtime_lab.py first.' }
$originalHash = (Get-FileHash (Join-Path $Lab 'original\Undertale\data.win') -Algorithm SHA256).Hash.ToLowerInvariant()
if ($originalHash -ne 'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7') { throw 'Original data identity mismatch.' }
$registry = Get-Content (Join-Path $PSScriptRoot '..\..\profiles\registry.json') | ConvertFrom-Json
$expected = ($registry | Where-Object OriginalSha256 -eq $originalHash).PatchedSha256
if (!$expected -or (Get-FileHash $PatchedData -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) { throw 'Candidate hash does not match the current inspected profile.' }
Copy-Item $PatchedData (Join-Path $Lab 'runs\patched\data.win') -Force
Copy-Item (Join-Path $PSScriptRoot 'inside-sandbox.ps1') (Join-Path $Lab 'inside-sandbox.ps1')
$escaped = [System.Security.SecurityElement]::Escape($Lab)
$evidenceHost = Join-Path $Lab 'evidence'
New-Item -ItemType Directory -Path $evidenceHost -Force | Out-Null
$escapedEvidence = [System.Security.SecurityElement]::Escape($evidenceHost)
$network = if ($EnableSteamSetupNetworking) { "Enable" } else { "Disable" }
$configuration = @"
<Configuration>
  <Networking>$network</Networking><ClipboardRedirection>Disable</ClipboardRedirection>
  <PrinterRedirection>Disable</PrinterRedirection>
  <MappedFolders><MappedFolder><HostFolder>$escaped</HostFolder><SandboxFolder>C:\RoutekeeperLab</SandboxFolder><ReadOnly>true</ReadOnly></MappedFolder><MappedFolder><HostFolder>$escapedEvidence</HostFolder><SandboxFolder>C:\RoutekeeperEvidence</SandboxFolder><ReadOnly>false</ReadOnly></MappedFolder></MappedFolders>
  <LogonCommand><Command>powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\RoutekeeperLab\inside-sandbox.ps1</Command></LogonCommand>
</Configuration>
"@
$configuration | Set-Content (Join-Path $Lab 'routekeeper.wsb')
Start-Process WindowsSandbox.exe -ArgumentList ('"' + (Join-Path $Lab 'routekeeper.wsb') + '"')
