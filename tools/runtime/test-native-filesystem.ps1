#requires -Version 5.1
# Real Windows NTFS/API validation, without Steam, UNDERTALE, GUI, or personal saves.
# Only touches a new disposable directory beneath the current process TEMP path.
param([string]$Work)

$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'current-account-windows.ps1')

if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){
    throw 'This test requires native Windows; synthetic tests are separate.'
}
$base=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
if(!$Work){$Work=Join-Path $base ('rk-native-fs-'+[guid]::NewGuid().ToString('N'))}
$Work=[IO.Path]::GetFullPath($Work)
if($Work.Equals($base,[StringComparison]::OrdinalIgnoreCase) -or !(Test-RkWithin $Work $base)){
    throw 'Native filesystem test must use a unique directory beneath the process TEMP root.'
}
Assert-RkNoLinks $Work
if(Test-Path -LiteralPath $Work){throw 'Native filesystem test output already exists; refuse reuse.'}
New-Item -ItemType Directory -Path $Work | Out-Null

# Preserve this private, synthetic-only directory on any failure for inspection.
$verified=$false
try {
    Assert-RkNativeSaveTree $Work
    $file=Join-Path $Work 'native-file.txt'
    [IO.File]::WriteAllText($file,'SYNTHETIC NTFS TEST ONLY')

    $hardlink=Join-Path $Work 'native-hardlink.txt'
    New-Item -ItemType HardLink -Path $hardlink -Target $file | Out-Null
    $refused=$false
    try {Assert-RkNativeSaveTree $file}
    catch {if($_.Exception.Message -like '*Hard-linked*'){$refused=$true}else{throw}}
    if(!$refused){throw 'Actual NTFS hardlink guard failed.'}
    [IO.File]::Delete($hardlink)

    Set-Content -LiteralPath $file -Stream 'rk_probe' -Value 'SYNTHETIC STREAM'
    $refused=$false
    try {Assert-RkNativeSaveTree $file}
    catch {if($_.Exception.Message -like '*Named streams*'){$refused=$true}else{throw}}
    if(!$refused){throw 'Actual NTFS named-stream guard failed.'}
    Remove-Item -LiteralPath $file -Stream 'rk_probe'

    $target=Join-Path $Work 'junction-target'
    New-Item -ItemType Directory -Path $target | Out-Null
    $junction=Join-Path $Work 'junction-alias'
    New-Item -ItemType Junction -Path $junction -Target $target | Out-Null
    $refused=$false
    try {Assert-RkNativeSaveTree $junction}
    catch {if($_.Exception.Message -like '*Linked*'){$refused=$true}else{throw}}
    if(!$refused){throw 'Actual NTFS junction guard failed.'}
    [IO.Directory]::Delete($junction)

    $locked=[IO.File]::Open($file,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    try {
        $refused=$false
        try {$other=[IO.File]::OpenRead($file);$other.Dispose()}catch{$refused=$true}
        if(!$refused){throw 'Native exclusive file locking was not enforced.'}
    } finally {$locked.Dispose()}

    Assert-RkNativeSaveTree $Work

    # Exercise the production save transaction code with disposable bytes.
    $save=Join-Path $Work 'synthetic-save'
    New-Item -ItemType Directory -Path $save | Out-Null
    [IO.File]::WriteAllText((Join-Path $save 'file0'),'INDEPENDENT ORIGINAL')
    $original=Get-RkTreeDigest $save
    $owner='SYNTHETIC_NATIVE_FS_TEST'
    $tx=New-RkSaveTransaction (Join-Path $Work 'transaction') $save $owner 'original'
    Start-RkSaveTransaction $tx
    Restore-RkSaveTransaction $tx $tx.root $save $owner
    if($tx.phase -ne 'Restored' -or (Get-RkTreeDigest $save) -cne $original){
        throw 'Native filesystem save transaction did not preserve original data.'
    }
    # After completion, a later unrelated edit must not be silently undone.
    [IO.File]::WriteAllText((Join-Path $save 'file0'),'UNRECOGNIZED LATER CHANGE')
    $refused=$false
    try {Restore-RkSaveTransaction $tx $tx.root $save $owner}
    catch {if($_.Exception.Message -like '*changed after restoration*'){$refused=$true}else{throw}}
    if(!$refused -or [IO.File]::ReadAllText((Join-Path $save 'file0')) -cne 'UNRECOGNIZED LATER CHANGE'){
        throw 'Restored original overwrote later personal-style changes.'
    }

    # Simulate an interrupted Restoring phase, using real NTFS renames.
    $interruptedSave=Join-Path $Work 'interrupted-save'
    New-Item -ItemType Directory -Path $interruptedSave | Out-Null
    [IO.File]::WriteAllText((Join-Path $interruptedSave 'file0'),'VERIFIED OLD CONTENT')
    $interruptedDigest=Get-RkTreeDigest $interruptedSave
    $interrupted=New-RkSaveTransaction (Join-Path $Work 'interrupted-transaction') $interruptedSave $owner 'original'
    Start-RkSaveTransaction $interrupted
    New-Item -ItemType Directory -Path $interruptedSave | Out-Null
    [IO.File]::WriteAllText((Join-Path $interruptedSave 'file0'),'DISPOSABLE TRIAL CONTENT')
    $interrupted.phase='Restoring'
    Save-RkJournal $interrupted
    [IO.Directory]::Move($interruptedSave,(Join-Path $interrupted.root 'trial-save'))
    Restore-RkSaveTransaction $interrupted $interrupted.root $interruptedSave $owner
    if($interrupted.phase -ne 'Restored' -or (Get-RkTreeDigest $interruptedSave) -cne $interruptedDigest){
        throw 'Native interrupted restoration did not recover the original.'
    }
    Restore-RkSaveTransaction $interrupted $interrupted.root $interruptedSave $owner

    Write-Output (@{
        kind='WINDOWS_NATIVE_FILESYSTEM_ONLY'
        result='PASS'
        osVersion=[Environment]::OSVersion.VersionString
        powerShellVersion=$PSVersionTable.PSVersion.ToString()
        checks=@('native-path-api','hardlink-refusal','named-stream-refusal','junction-refusal',
                 'exclusive-file-lock','local-save-restore','reject-later-changes',
                 'interrupted-restoration','restoration-idempotency')
        nativeDesktop='NOT_RUN'
        nativeGameplay='NOT_RUN'
        steamAccount='NOT_TOUCHED'
        personalSaves='NOT_TOUCHED'
    } | ConvertTo-Json -Depth 5)
    $verified=$true
} finally {
    if($verified){
        Assert-RkTreeNoLinks $Work
        Remove-Item -LiteralPath $Work -Recurse -Force
    }else{
        Write-Warning ('Synthetic-only native filesystem evidence preserved: '+$Work)
    }
}
