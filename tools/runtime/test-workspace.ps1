# Disposable TEST workspaces only. Never use this helper for game/save recovery.
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-windows.ps1')

function New-RkTestWorkspace {
    $base=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $root=Join-Path $base ('rk-test-'+[guid]::NewGuid().ToString('N'))
    Assert-RkNoLinks $root
    if(Test-Path -LiteralPath $root){throw 'Disposable test workspace already exists.'}
    [IO.Directory]::CreateDirectory($root) | Out-Null
    $token=[guid]::NewGuid().ToString('N')
    [IO.File]::WriteAllText((Join-Path $root '.rk-test-owner'),$token)
    return [pscustomobject]@{root=$root;base=$base;token=$token;manifest=$null}
}

function Assert-RkTestWorkspace($Workspace) {
    $root=[IO.Path]::GetFullPath($Workspace.root)
    $base=[IO.Path]::GetFullPath($Workspace.base)
    if(!(Test-RkWithin $root $base) -or $root.TrimEnd('\','/').Equals($base.TrimEnd('\','/'),[StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($root) -notmatch '^rk-test-[a-f0-9]{32}$'){
        throw 'Test workspace is outside its owned TEMP child.'
    }
    Assert-RkNoLinks $root
    $marker=Join-Path $root '.rk-test-owner'
    Assert-RkNoLinks $marker
    if(!(Test-Path -LiteralPath $marker -PathType Leaf) -or [IO.File]::ReadAllText($marker) -cne $Workspace.token){throw 'Test workspace ownership marker changed.'}
    Assert-RkTreeNoLinks $root
}

function Get-RkTestWorkspaceManifest($Workspace) {
    Assert-RkTestWorkspace $Workspace
    $root=$Workspace.root
    return @(Get-ChildItem -LiteralPath $root -Recurse -Force | Sort-Object FullName | ForEach-Object {
        $entry=$_
        $relative=$entry.FullName.Substring($root.Length+1)
        if($entry.PSIsContainer){'D'+"`t"+$relative}
        else{
            for($attempt=0;;$attempt++){
                $stream=$null;$hash=$null
                try{
                    $stream=[IO.File]::Open($entry.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
                    $hash=[Security.Cryptography.SHA256]::Create()
                    $digest=[BitConverter]::ToString($hash.ComputeHash($stream)).Replace('-','')
                    break
                }catch [IO.IOException]{if($attempt -ge 3){throw};Start-Sleep -Milliseconds 100}
                finally{if($hash){$hash.Dispose()};if($stream){$stream.Dispose()}}
            }
            'F'+"`t"+$relative+"`t"+$entry.Length+"`t"+$digest
        }
    })
}

function Complete-RkTestWorkspace($Workspace) {
    # Call only after all fixture assertions succeed. This is an invocation-local
    # cleanup seal, not proof against hostile writers or a game evidence receipt.
    if($null -ne $Workspace.manifest){throw 'Test workspace was already sealed.'}
    $Workspace.manifest=@(Get-RkTestWorkspaceManifest $Workspace)
}

function Remove-RkTestWorkspace($Workspace) {
    if($null -eq $Workspace.manifest){throw 'Unverified test workspace preserved.'}
    $current=@(Get-RkTestWorkspaceManifest $Workspace)
    if(($current -join "`n") -cne ($Workspace.manifest -join "`n")){throw 'Unknown or changed test files; preserve workspace.'}
    $files=@(Get-ChildItem -LiteralPath $Workspace.root -Recurse -Force -File)
    # Validate the entire tree before deleting anything. Do not clear attributes
    # of a hardlink or mutate named streams. Locked files get a bounded retry.
    foreach($file in $files){
        Assert-RkMutablePath $file.FullName
        for($attempt=0;;$attempt++){
            try{$handle=[IO.File]::Open($file.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None);$handle.Dispose();break}
            catch [IO.IOException]{if($attempt -ge 3){throw};Start-Sleep -Milliseconds 100}
        }
    }
    if((@(Get-RkTestWorkspaceManifest $Workspace) -join "`n") -cne ($Workspace.manifest -join "`n")){throw 'Test workspace changed during validation; preserve workspace.'}
    foreach($file in $files | Where-Object Name -ne '.rk-test-owner'){
        Assert-RkNoLinks $file.FullName
        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
    }
    foreach($directory in Get-ChildItem -LiteralPath $Workspace.root -Recurse -Force -Directory | Sort-Object { $_.FullName.Length } -Descending){
        Assert-RkNoLinks $directory.FullName
        [IO.Directory]::Delete($directory.FullName,$false)
    }
    Assert-RkNoLinks $Workspace.root
    Remove-Item -LiteralPath (Join-Path $Workspace.root '.rk-test-owner') -Force -ErrorAction Stop
    [IO.Directory]::Delete($Workspace.root,$false)
}
