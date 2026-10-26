# Pure filesystem guards shared by host staging and the disposable VM harness.
function Assert-RkNoLinks([string]$Path) {
    $current = [IO.Path]::GetFullPath($Path)
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked runtime path refused.' }
        }
        $parent = [IO.Path]::GetDirectoryName($current)
        if ($parent -eq $current) { break }
        $current = $parent
    }
}
function Test-RkWithin([string]$Path,[string]$Root) {
    $full = [IO.Path]::GetFullPath($Path)
    $base = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar)
    return $full.Equals($base,[StringComparison]::OrdinalIgnoreCase) -or $full.StartsWith($base + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
function Assert-RkHash([string]$Path,[string]$Expected) {
    Assert-RkNoLinks $Path
    if (!(Test-Path -LiteralPath $Path -PathType Leaf) -or (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Expected.ToLowerInvariant()) { throw 'Runtime file identity mismatch.' }
}
function Assert-RkRelative([string]$Path) {
    if ([IO.Path]::IsPathRooted($Path) -or $Path.Contains(':') -or $Path -match '(^|[\\/])([.]{1,2}|)([\\/]|$)') { throw 'Unsafe runtime relative path.' }
    foreach($component in ($Path -split '[\\/]')){
        if($component -match '[\x00-\x1f<>:"|?*]' -or $component -match '[. ]$' -or $component -match '^(CON|PRN|AUX|NUL|COM[1-9\u00b9\u00b2\u00b3]|LPT[1-9\u00b9\u00b2\u00b3])([.]|$)'){throw 'Windows-aliased or reserved runtime path refused.'}
    }
}

function Assert-RkTreeNoLinks([string]$Path) {
    Assert-RkNoLinks $Path
    $queue = [Collections.Generic.Queue[string]]::new()
    $queue.Enqueue($Path)
    while ($queue.Count) {
        $directory = $queue.Dequeue()
        foreach ($item in Get-ChildItem -LiteralPath $directory -Force) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked runtime tree refused.' }
            if ($item.PSIsContainer) { $queue.Enqueue($item.FullName) }
        }
    }
}
function Get-RkInventoryDigest($Files) {
    [string[]]$rows = @($Files | ForEach-Object { $_.path + "`t" + $_.size + "`t" + $_.sha256 + "`n" })
    [Array]::Sort($rows,[StringComparer]::Ordinal)
    $hash = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($hash.ComputeHash([Text.Encoding]::UTF8.GetBytes(($rows -join ''))))).Replace('-','').ToLowerInvariant() }
    finally { $hash.Dispose() }
}
# Filesystem-only transaction; callers establish VM/Steam/hash gates first.
# These functions are exercised on synthetic temp directories outside Windows.
function Stop-RkDisposableInstall($Transaction) {
    $installed=$Transaction.Installed
    $marker=Join-Path $installed '.routekeeper-disposable-install'
    Assert-RkNoLinks $installed
    Assert-RkNoLinks $Transaction.Backup
    Assert-RkNoLinks $marker
    if (!(Test-Path -LiteralPath $marker) -or (Get-Content -LiteralPath $marker -Raw).Trim() -ne $Transaction.Id) { throw 'Disposable install marker lost; preserving both directories for review.' }
    Assert-RkTreeNoLinks $installed
    Remove-Item -LiteralPath $installed -Recurse -Force
    if (Test-Path -LiteralPath $Transaction.Backup) { Move-Item -LiteralPath $Transaction.Backup -Destination $installed }
}
function Start-RkDisposableInstall([string]$Game,[string]$Installed,$Files,[string]$Id) {
    Assert-RkNoLinks $Game
    Assert-RkNoLinks $Installed
    if (Test-Path -LiteralPath (Join-Path $Installed '.routekeeper-disposable-install')) { throw 'Existing disposable installation; refusing nested replacement.' }
    $prefix=[IO.Path]::GetFileName($Installed)+'.routekeeper-vm-backup-'
    if (Get-ChildItem -LiteralPath (Split-Path $Installed) -Force | Where-Object { $_.Name.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) }) { throw 'Stale VM backup detected; start a fresh Sandbox or review it first.' }
    $transaction=@{Installed=$Installed; Backup=($Installed+'.routekeeper-vm-backup-'+$Id); Id=$Id}
    if (Test-Path -LiteralPath $transaction.Backup) { throw 'VM original backup already exists; refusing overwrite.' }
    if (Test-Path -LiteralPath $Installed) { Move-Item -LiteralPath $Installed -Destination $transaction.Backup }
    try {
        New-Item -ItemType Directory -Path $Installed | Out-Null
        Set-Content -LiteralPath (Join-Path $Installed '.routekeeper-disposable-install') -Value $Id
        foreach ($file in $Files) {
            Assert-RkRelative $file.path
            $source=Join-Path $Game $file.path
            Assert-RkNoLinks $source
            $target=Join-Path $Installed $file.path
            New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination $target
        }
        return $transaction
    } catch {
        $marker=Join-Path $Installed '.routekeeper-disposable-install'
        if (Test-Path -LiteralPath $marker) { Stop-RkDisposableInstall $transaction }
        elseif (!(Test-Path -LiteralPath $Installed) -and (Test-Path -LiteralPath $transaction.Backup)) { Move-Item -LiteralPath $transaction.Backup -Destination $Installed }
        throw
    }
}
function Assert-RkSession($State,[string]$Case,[string]$SteamRoot) {
    if ($State.schema -ne 2 -or $State.case -notin @('original','patched')) { throw 'Unknown disposable session.' }
    if ($State.case -ne $Case) { throw 'Use a fresh Sandbox for another case; local save stashes do not isolate Steam cached history.' }
    if ($State.steamRoot -ne $SteamRoot) { throw 'Steam location changed within a disposable session.' }
}
