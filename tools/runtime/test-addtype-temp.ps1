#requires -Version 5.1
# Reproduce legacy compiler TEMP failures without touching system TEMP permissions.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'test-workspace.ps1')
$workspace=New-RkTestWorkspace
$verified=$false
function Invoke-RkCompileFixture([string]$TemporaryPath) {
    $command='$ErrorActionPreference="Stop"; $ProgressPreference="SilentlyContinue"; [Console]::OutputEncoding=[Text.UTF8Encoding]::new($false); try { Add-Type -TypeDefinition "public static class RkTempCompileFixture { public static int Value() { return 42; } }"; if([RkTempCompileFixture]::Value() -ne 42){throw "Wrong compiled result"}; Write-Output "COMPILED_42" } catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }'
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $info.Arguments='-NoProfile -NonInteractive -EncodedCommand '+[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    $info.StandardOutputEncoding=[Text.Encoding]::UTF8;$info.StandardErrorEncoding=[Text.Encoding]::UTF8
    if($TemporaryPath){$info.EnvironmentVariables['TEMP']=$TemporaryPath;$info.EnvironmentVariables['TMP']=$TemporaryPath}
    $process=[Diagnostics.Process]::Start($info)
    try {
        $output=$process.StandardOutput.ReadToEndAsync();$errorOutput=$process.StandardError.ReadToEndAsync()
        if(!$process.WaitForExit(15000)){$process.Kill();$process.WaitForExit();throw 'Owned compiler fixture exceeded timeout.'}
        return [pscustomobject]@{exitCode=$process.ExitCode;output=$output.Result.Trim();error=$errorOutput.Result.Trim()}
    }finally{$process.Dispose()}
}
try {
    $baseline=Invoke-RkCompileFixture ''
    if($baseline.exitCode -ne 0 -or $baseline.output -cne 'COMPILED_42'){throw ('Current user TEMP compilation failed: '+$baseline.error)}
    Write-Host 'PASS PowerShell5.1 current user TEMP compiles harmless C#'
    $invalid=Join-Path $workspace.root 'not-a-directory';[IO.File]::WriteAllText($invalid,'DISPOSABLE INVALID TEMP FIXTURE')
    $failure=Invoke-RkCompileFixture $invalid
    if($failure.exitCode -eq 0 -or !$failure.error){throw 'Invalid TEMP fixture did not reproduce compiler failure.'}
    Write-Host 'PASS controlled invalid process TEMP fails C# compilation'
    $private=Join-Path $workspace.root 'private-compiler-temp';[IO.Directory]::CreateDirectory($private)|Out-Null
    $repaired=Invoke-RkCompileFixture $private
    if($repaired.exitCode -ne 0 -or $repaired.output -cne 'COMPILED_42'){throw ('Private process TEMP compilation failed: '+$repaired.error)}
    Write-Host 'PASS process-only private TEMP restores harmless C# compilation'
    Write-Output (@{kind='WINDOWS_POWERSHELL51_COMPILER_TEMP';result='PASS';checks=3;historicalSystemTempFailure='NOT_REPRODUCED';controlledFailure=$failure.error;systemSettings='UNCHANGED'}|ConvertTo-Json)
    Complete-RkTestWorkspace $workspace;$verified=$true
}finally{
    if($verified){Remove-RkTestWorkspace $workspace}
    else{Write-Warning ('Compiler fixture failure evidence retained: '+$workspace.root)}
}
