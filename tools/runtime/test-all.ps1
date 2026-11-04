#requires -Version 7.0
# Safe repeatable non-game entry. Never starts Steam/UNDERTALE or touches personal saves.
param([string]$Output, [switch]$SkipDesktop)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$python=Join-Path $repo '.research/test-venv/Scripts/python.exe'
$sdk=Join-Path $repo '.research/dotnet'
if(!(Test-Path -LiteralPath $python -PathType Leaf)){throw 'Missing project-local .research/test-venv Python. Install the documented Python/Pillow prerequisites first.'}
if(Test-Path -LiteralPath (Join-Path $sdk 'dotnet.exe') -PathType Leaf){
 $env:DOTNET_ROOT=$sdk
 $env:PATH=$sdk+';'+$env:PATH
}
$env:PATH=(Split-Path $python)+';'+$env:PATH
$env:DOTNET_CLI_TELEMETRY_OPTOUT='1'
$arguments=@((Join-Path $repo 'tools/windows_test_suite.py'))
if($Output){$arguments+=@('--output',$Output)}
if($SkipDesktop){$arguments+='--skip-desktop'}
& $python @arguments
exit $LASTEXITCODE
