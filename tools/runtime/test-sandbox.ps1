# Cross-platform offline checks. Optional private staging dispatch is MOCKED;
# neither WindowsSandbox.exe nor a Steam/game process is launched by this test.
param([string]$Lab,[string]$PatchedData)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
function Check([bool]$Value,[string]$Label) { if (!$Value) { throw $Label }; Write-Output ('OFFLINE_PASS '+$Label) }
foreach ($file in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1') {
    $tokens=$null; $errors=$null
    $null=[Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
    Check (!$errors) ('AST '+$file.Name)
}
# Compile the capture interop declaration without calling any Windows API.
$capture=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'capture-game.ps1') -Raw
$declaration=[regex]::Match($capture,"(?s)Add-Type @'\r?\n(.*?)\r?\n'@").Groups[1].Value
Check ($declaration.Length -gt 0) 'capture interop declaration found'
Add-Type -TypeDefinition $declaration
$rect=New-Object RoutekeeperCapture+Rect
$point=New-Object RoutekeeperCapture+Point
Check ($rect.Right -eq 0 -and $point.X -eq 0) 'capture interop structs compile; APIs not invoked'
$temporary=Join-Path ([IO.Path]::GetTempPath()) ('rk-harness-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporary | Out-Null
try {
    $child=Join-Path $temporary 'child'; New-Item -ItemType Directory -Path $child | Out-Null
    Check (Test-RkWithin $child $temporary) 'child path containment'
    Check (!(Test-RkWithin ($temporary+'-other') $temporary)) 'sibling-prefix path refused'
    foreach ($relative in @('../outside','a/../outside','a//b','C:/outside','/outside')) {
        $refused=$false; try { Assert-RkRelative $relative } catch { $refused=$true }
        Check $refused ('unsafe relative path refused: '+$relative)
    }
    $file=Join-Path $child 'synthetic.txt'; Set-Content -LiteralPath $file -Value 'SYNTHETIC ONLY'
    $hash=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
    Assert-RkHash $file $hash
    Set-Content -LiteralPath $file -Value 'MUTATED'
    $refused=$false; try { Assert-RkHash $file $hash } catch { $refused=$true }
    Check $refused 'mutated input refused'
    Assert-RkTreeNoLinks $temporary
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        $link=Join-Path $child 'linked-directory'
        New-Item -ItemType SymbolicLink -Path $link -Target $temporary | Out-Null
        $refused=$false; try { Assert-RkTreeNoLinks $temporary } catch { $refused=$true }
        Check $refused 'linked child tree refused without recursion'
        Remove-Item -LiteralPath $link
    }
    $game=Join-Path $temporary 'game'; $installed=Join-Path $temporary 'installed'
    New-Item -ItemType Directory -Path $game,$installed | Out-Null
    Set-Content -LiteralPath (Join-Path $game 'synthetic.bin') -Value 'CANDIDATE'
    Set-Content -LiteralPath (Join-Path $installed 'original.bin') -Value 'PRISTINE'
    $files=@(@{path='synthetic.bin'})
    $transaction=Start-RkDisposableInstall $game $installed $files 'synthetic-success'
    Check ((Test-Path -LiteralPath (Join-Path $installed 'synthetic.bin')) -and (Test-Path -LiteralPath (Join-Path $transaction.Backup 'original.bin'))) 'original retained during disposable install'
    $refused=$false; try { $null=Start-RkDisposableInstall $game $installed $files 'nested' } catch { $refused=$true }
    Check $refused 'nested install refused before moving the active copy'
    Stop-RkDisposableInstall $transaction
    $refused=$false; try { Stop-RkDisposableInstall $transaction } catch { $refused=$true }
    Check ($refused -and (Test-Path -LiteralPath (Join-Path $installed 'original.bin'))) 'duplicate cleanup cannot delete the restored original'
    Check ((Get-Content -LiteralPath (Join-Path $installed 'original.bin') -Raw).Trim() -eq 'PRISTINE') 'disposable uninstall restores registered VM original'
    $refused=$false
    try { $null=Start-RkDisposableInstall $game $installed @(@{path='synthetic.bin'},@{path='missing.bin'}) 'synthetic-failure' } catch { $refused=$true }
    Check ($refused -and (Test-Path -LiteralPath (Join-Path $installed 'original.bin')) -and !(Test-Path -LiteralPath (Join-Path $installed 'synthetic.bin'))) 'partial-copy failure rolls back'
    $transaction=Start-RkDisposableInstall $game $installed $files 'synthetic-lost-marker'
    Remove-Item -LiteralPath (Join-Path $installed '.routekeeper-disposable-install') -Force
    $refused=$false; try { Stop-RkDisposableInstall $transaction } catch { $refused=$true }
    Check ($refused -and (Test-Path -LiteralPath $transaction.Backup) -and (Test-Path -LiteralPath $installed)) 'lost marker preserves both directories'
    $session=@{schema=2;case='original';steamRoot='synthetic-root'}
    Assert-RkSession $session 'original' 'synthetic-root'
    Check $true 'same-case disposable session accepted'
    $refused=$false; try { Assert-RkSession $session 'patched' 'synthetic-root' } catch { $refused=$true }
    Check $refused 'cross-case reuse refuses shared Steam history'
    $refused=$false; try { Assert-RkSession $session 'original' 'different-root' } catch { $refused=$true }
    Check $refused 'changed Steam root refused'
    $originalUser=$env:USERNAME
    try {
        $env:USERNAME='ROUTEKEEPER_OFFLINE'
        $refused=$false; try { & (Join-Path $PSScriptRoot 'inside-sandbox.ps1') } catch { $refused=$_.Exception.Message -eq 'Refusing to use a normal Windows account or its saves.' }
        Check $refused 'normal account cannot enter harness'
    } finally { $env:USERNAME=$originalUser }
} finally { Remove-Item -LiteralPath $temporary -Recurse -Force }
if ($Lab -or $PatchedData) {
    if (!$Lab -or !$PatchedData) { throw 'Both private staging arguments are required.' }
    $global:RkMockDispatch=$false
    function Start-Process { param([string]$FilePath,[object]$ArgumentList) Check ($FilePath -eq 'WindowsSandbox.exe') 'mocked Sandbox dispatch'; $global:RkMockDispatch=$true }
    try { & (Join-Path $PSScriptRoot 'launch-windows-sandbox.ps1') -Lab $Lab -PatchedData $PatchedData }
    finally { Remove-Item Function:Start-Process }
    Check $global:RkMockDispatch 'private host staging completed without execution'
    [xml]$xml=Get-Content -LiteralPath (Join-Path $Lab 'routekeeper.wsb') -Raw
    $maps=@($xml.Configuration.MappedFolders.MappedFolder)
    Check ($maps.Count -eq 2 -and $maps[0].ReadOnly -eq 'true' -and $maps[1].ReadOnly -eq 'false') 'read-only input and separate evidence mapping'
    Check ($maps[0].HostFolder -eq (Join-Path $Lab 'sandbox-input')) 'whole host lab is not mapped'
    Check (!(Test-Path -LiteralPath (Join-Path $Lab 'sandbox-input\identity-private.json'))) 'private inventory/account manifest not mapped'
    Check (!(Test-Path -LiteralPath (Join-Path $Lab 'sandbox-input\appmanifest_391540.acf'))) 'supplied account manifest excluded from payload'
}
