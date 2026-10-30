# Actual helper/guardian integration using a harmless Python sleeper; no game/Steam.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'experimental-session.ps1')
. (Join-Path $PSScriptRoot 'input-window.ps1')
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$root=Join-Path $repo ('.research/windows-20261029-watchdog/ps-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root|Out-Null
$python=(Get-Command python -ErrorAction Stop).Source
$python=(& $python -c 'import os,sys;p,e=os.path.splitext(sys._base_executable);print(p+chr(119)+e)')
$hash=(Get-FileHash -LiteralPath $python).Hash.ToLowerInvariant()
$owned=@();$checks=0
function Check([bool]$Value,[string]$Message){if(!$Value){throw $Message};$script:checks++;Write-Host ('NATIVE_PASS '+$Message)}
function New-Sleeper {
 $process=New-Object Diagnostics.Process
 $process.StartInfo=New-Object Diagnostics.ProcessStartInfo
 $process.StartInfo.FileName=$python;$process.StartInfo.Arguments='-c "import time;time.sleep(90)"'
 $process.StartInfo.UseShellExecute=$false;$process.StartInfo.CreateNoWindow=$true
 if(!$process.Start()){throw 'Owned sleeper launch failed.'};$null=$process.Handle
 return $process
}
try {
 $target=New-Sleeper;$owned+=,$target
 $normal=Join-Path $root 'normal';New-Item -ItemType Directory -Path $normal|Out-Null
 Start-RkExternalWatchdog $target $normal $python $hash
 Check (Test-Path -LiteralPath (Join-Path $normal 'watchdog/ready.json')) 'separate guardian armed with native exact process identity'
 Update-RkExternalWatchdog
 Check ($script:RkWatchdog.sequence -eq 2) 'PowerShell controller heartbeat advances'
 $target.Kill();$null=$target.WaitForExit(5000)
 Complete-RkExternalWatchdog
 Check (!$script:RkWatchdog) 'guardian independently confirmed owned process exit'
 $target=New-Sleeper;$owned+=,$target
 $dead=Join-Path $root 'guardian-death';New-Item -ItemType Directory -Path $dead|Out-Null
 Start-RkExternalWatchdog $target $dead $python $hash
 $script:RkWatchdog.process.Kill();$null=$script:RkWatchdog.process.WaitForExit(5000)
 $guardianRefusal=$null
 try{Assert-RkExternalWatchdog}catch{$guardianRefusal=$_.Exception.Message}
 Check ($script:RkWatchdog.process.HasExited -and $guardianRefusal -like 'External watchdog *') 'guardian death refuses further controller input'
 $refused=$false;try{Assert-RkInputWindow $null ([IntPtr]::Zero) '' '' 0 ''}catch{
  Write-RkAtomicJson (Join-Path $dead 'input-refusal.json') @{message=$_.Exception.Message;expectedGuardianRefusal=$guardianRefusal;guardianExited=$script:RkWatchdog.process.HasExited}
  # An intervention receipt can appear immediately before the forced kill. Both
  # refusal states are valid, but the real input gate must propagate the exact
  # guardian refusal rather than a later null-process/Win32/parameter exception.
  $refused=$_.Exception.Message -ceq $guardianRefusal
 }
 Check $refused 'actual input ownership gate refuses dead guardian before native dispatch'
 # Deterministically reproduce a guardian killed between exclusive receipt file
 # creation and JSON publication. Empty stop evidence must remain a refusal.
 $originalGuardRoot=$script:RkWatchdog.root
 $publicationGap=Join-Path $root 'publication-gap';New-Item -ItemType Directory -Path $publicationGap|Out-Null
 $emptyStop=[IO.File]::Open((Join-Path $publicationGap 'stop.json'),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);$emptyStop.Dispose()
 $script:RkWatchdog.root=$publicationGap
 try {
  $gapRefusal=$null;try{Assert-RkExternalWatchdog}catch{$gapRefusal=$_.Exception.Message}
  Check ($gapRefusal -ceq 'External watchdog ended/stopped; no further input.') 'interrupted zero-byte stop publication refuses guardian readiness'
  $refused=$false;try{Assert-RkInputWindow $null ([IntPtr]::Zero) '' '' 0 ''}catch{$refused=$_.Exception.Message -ceq $gapRefusal}
  Check $refused 'real input gate preserves interrupted-publication guardian refusal'
 }finally{$script:RkWatchdog.root=$originalGuardRoot}
 $target.Kill();$null=$target.WaitForExit(5000)
 $refused=$false;try{Complete-RkExternalWatchdog}catch{$refused=$true}
 Check $refused 'guardian failure refuses automatic recovery'
 # A failed/intervening guardian receipt must fence the shared recovery path.
 function Assert-RkJournal {param($State,$Root,$Save,$Owner)}
 foreach($name in @('stop.json','failure.json','missing-result','unknown-descendants')){
  $case=Join-Path $root ('recovery-'+$name);New-Item -ItemType Directory -Path (Join-Path $case 'watchdog')|Out-Null
  if($name -eq 'unknown-descendants'){Write-RkAtomicJson (Join-Path $case 'watchdog/result.json') @{result='UNKNOWN_DESCENDANTS_PRESERVED';descendants=@(123)}}
  elseif($name -ne 'missing-result'){Write-RkAtomicJson (Join-Path $case ('watchdog/'+$name)) @{result='REFUSED'}}
  $refused=$false;try{Assert-RkE2eRecoveryReady @{} $case (Join-Path $case 'nonexistent-save') 'SYNTHETIC'}catch{$refused=$true}
  Check $refused ('ambiguous guardian recovery refused: '+$name)
 }
 Write-RkAtomicJson (Join-Path $root 'summary.json') @{schema=1;kind='HARMLESS_NATIVE_WATCHDOG';pass=$checks;fail=0;gameExecuted=$false;powerShell=$PSVersionTable.PSVersion.ToString()}
 Write-Host ('WATCHDOG_NATIVE '+$checks+' PASS; evidence '+$root)
} finally {
 foreach($process in $owned){$process.Refresh();if(!$process.HasExited){$process.Kill();$null=$process.WaitForExit(5000)}}
 # Evidence stays private; do not recursively remove unknown files.
}
