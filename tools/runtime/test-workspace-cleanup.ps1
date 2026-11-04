#requires -Version 5.1
# Actual Windows files only; no Steam/game/personal-save access.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'test-workspace.ps1')
$script:checks=0
function Check([bool]$Value,[string]$Message){if(!$Value){throw $Message};$script:checks++;Write-Host ('PASS '+$Message)}
function Refused([scriptblock]$Action){try{& $Action;return $false}catch{return $true}}
$active=@()
try {
    $workspace=New-RkTestWorkspace;$active+=,$workspace
    $file=Join-Path $workspace.root 'readonly.txt'
    [IO.File]::WriteAllText($file,'OWNED FIXTURE')
    [IO.File]::SetAttributes($file,[IO.FileAttributes]::ReadOnly)
    Complete-RkTestWorkspace $workspace
    Remove-RkTestWorkspace $workspace
    Check (!(Test-Path -LiteralPath $workspace.root)) 'read-only owned fixture cleaned'

    $workspace=New-RkTestWorkspace;$active+=,$workspace
    $file=Join-Path $workspace.root 'locked.txt';[IO.File]::WriteAllText($file,'LOCKED FIXTURE')
    Complete-RkTestWorkspace $workspace
    $lock=[IO.File]::Open($file,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    try{Check (Refused {Remove-RkTestWorkspace $workspace}) 'locked fixture refuses cleanup'}finally{$lock.Dispose()}
    Check (Test-Path -LiteralPath $file) 'locked failure preserves fixture'
    Remove-RkTestWorkspace $workspace
    Check (!(Test-Path -LiteralPath $workspace.root)) 'cleanup succeeds after lock release'

    $workspace=New-RkTestWorkspace;$active+=,$workspace
    Complete-RkTestWorkspace $workspace
    $unknown=Join-Path $workspace.root 'unexpected.txt';[IO.File]::WriteAllText($unknown,'UNKNOWN')
    Check (Refused {Remove-RkTestWorkspace $workspace}) 'unknown additional file refuses cleanup'
    Check ([IO.File]::ReadAllText($unknown) -ceq 'UNKNOWN') 'unknown additional file retained'
    [IO.File]::Delete($unknown);Remove-RkTestWorkspace $workspace

    $workspace=New-RkTestWorkspace;$active+=,$workspace
    $file=Join-Path $workspace.root 'changed.txt';[IO.File]::WriteAllText($file,'BEFORE')
    Complete-RkTestWorkspace $workspace;[IO.File]::WriteAllText($file,'AFTER')
    Check (Refused {Remove-RkTestWorkspace $workspace}) 'changed fixture refuses cleanup'
    Check ([IO.File]::ReadAllText($file) -ceq 'AFTER') 'changed fixture retained'
    [IO.File]::WriteAllText($file,'BEFORE');Remove-RkTestWorkspace $workspace

    $workspace=New-RkTestWorkspace;$active+=,$workspace
    Check (Refused {Remove-RkTestWorkspace $workspace}) 'unverified workspace preserved'
    Complete-RkTestWorkspace $workspace
    $originalRoot=$workspace.root;$workspace.root=[IO.Path]::GetTempPath()
    Check (Refused {Remove-RkTestWorkspace $workspace}) 'TEMP root deletion refused'
    $workspace.root=$originalRoot
    $marker=Join-Path $workspace.root '.rk-test-owner';[IO.File]::WriteAllText($marker,'OTHER OWNER')
    Check (Refused {Remove-RkTestWorkspace $workspace}) 'wrong ownership token refused'
    [IO.File]::WriteAllText($marker,$workspace.token);Remove-RkTestWorkspace $workspace

    $workspace=New-RkTestWorkspace;$active+=,$workspace
    $outside=New-RkTestWorkspace;$active+=,$outside
    $target=Join-Path $outside.root 'retained.txt';[IO.File]::WriteAllText($target,'OUTSIDE OWNED ROOT')
    $junction=Join-Path $workspace.root 'junction'
    New-Item -ItemType Junction -Path $junction -Target $outside.root | Out-Null
    Check (Refused {Complete-RkTestWorkspace $workspace}) 'junction refused before enumeration'
    Check ([IO.File]::ReadAllText($target) -ceq 'OUTSIDE OWNED ROOT') 'junction target untouched'
    [IO.Directory]::Delete($junction);Complete-RkTestWorkspace $workspace;Remove-RkTestWorkspace $workspace
    Complete-RkTestWorkspace $outside;Remove-RkTestWorkspace $outside

    $workspace=New-RkTestWorkspace;$active+=,$workspace
    $file=Join-Path $workspace.root 'original.txt';[IO.File]::WriteAllText($file,'HARDLINK FIXTURE')
    $link=Join-Path $workspace.root 'link.txt';New-Item -ItemType HardLink -Path $link -Target $file | Out-Null
    Complete-RkTestWorkspace $workspace
    Check (Refused {Remove-RkTestWorkspace $workspace}) 'hardlinked fixture refuses cleanup'
    Check (Test-Path -LiteralPath $file) 'hardlink failure preserves fixture'
    [IO.File]::Delete($link);$workspace.manifest=$null;Complete-RkTestWorkspace $workspace;Remove-RkTestWorkspace $workspace
    Write-Output (@{kind='WINDOWS_TEST_WORKSPACE_CLEANUP';result='PASS';checks=$script:checks;powerShellVersion=$PSVersionTable.PSVersion.ToString()}|ConvertTo-Json)
} catch {
    foreach($workspace in $active){if(Test-Path -LiteralPath $workspace.root){Write-Warning ('Failure evidence retained: '+$workspace.root)}}
    throw
}
