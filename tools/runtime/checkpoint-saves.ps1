# Checkpoints contain only saves created during this disposable session; never
# import a host/personal save. These remain inside the VM, outside host mappings.
param([Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]{1,40}$')][string]$Name,[switch]$Restore)
$ErrorActionPreference='Stop'
if ($env:USERNAME -ne 'WDAGUtilityAccount') { throw 'Disposable Sandbox account required.' }
. (Join-Path $PSScriptRoot 'safety.ps1')
if (Get-Process UNDERTALE -ErrorAction SilentlyContinue) { throw 'Close UNDERTALE before checkpointing.' }
if (Get-NetAdapter | Where-Object Status -eq 'Up') { throw 'VM must remain offline.' }
$stateRoot='C:\RoutekeeperSession'
Assert-RkNoLinks $stateRoot
$state=Get-Content -LiteralPath (Join-Path $stateRoot 'session.json') -Raw | ConvertFrom-Json
if ($state.schema -ne 2 -or $state.case -notin @('original','patched')) { throw 'Unknown session.' }
$save=Join-Path $env:LOCALAPPDATA 'UNDERTALE'
$checkpoint=Join-Path $stateRoot ('checkpoints\'+$state.case+'\'+$Name)
Assert-RkNoLinks $save
Assert-RkNoLinks $checkpoint
if ($Restore) {
    if (Get-Process steam -ErrorAction SilentlyContinue) { throw 'Exit Steam completely while staying offline before restoring a fixture.' }
    # Steam SDK history reconciliation can override a local-only rewind. Do not
    # delete/rewrite even disposable client caches under an unverified protocol.
    Assert-RkNoLinks $state.steamRoot
    $userdata=Join-Path $state.steamRoot 'userdata'
    Assert-RkNoLinks $userdata
    if (Test-Path -LiteralPath $userdata) {
        foreach ($account in Get-ChildItem -LiteralPath $userdata -Directory -Force) {
            $cache=Join-Path $account.FullName '391540'
            Assert-RkNoLinks $cache
            if ((Test-Path -LiteralPath $cache) -and (Get-ChildItem -LiteralPath $cache -File -Recurse -Force -ErrorAction Stop)) { throw 'Steam app cache exists; local-only history restoration is unsupported. Use in-game LOAD or a fresh Sandbox.' }
        }
    }
    if (!(Test-Path -LiteralPath $checkpoint)) { throw 'Checkpoint missing.' }
    Assert-RkTreeNoLinks $checkpoint
    # Preserve the previous disposable history too; restoration is explicit and
    # confined to this VM. No claim about legitimate-playthrough provenance.
    if (Test-Path -LiteralPath $save) { Move-Item -LiteralPath $save -Destination (Join-Path $stateRoot ('before-restore-'+[guid]::NewGuid().ToString('N'))) }
    Copy-Item -LiteralPath $checkpoint -Destination $save -Recurse
} else {
    if (!(Test-Path -LiteralPath $save) -or (Test-Path -LiteralPath $checkpoint)) { throw 'Save missing or checkpoint already exists.' }
    New-Item -ItemType Directory -Path (Split-Path $checkpoint) -Force | Out-Null
    Assert-RkTreeNoLinks $save
    Copy-Item -LiteralPath $save -Destination $checkpoint -Recurse
}
