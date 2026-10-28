# Separate process guardian; no personal-save or Steam operations.
$script:RkWatchdog=$null
function Start-RkExternalWatchdog($Target,[string]$Root,[string]$Runner,[string]$Hash) {
 if($script:RkWatchdog){throw 'An external watchdog is already active.'}
 $folder=Join-Path $Root 'watchdog';Assert-RkNoLinks $folder
 if(Test-Path -LiteralPath $folder){throw 'Watchdog evidence already exists; do not reuse it.'}
 New-Item -ItemType Directory -Path $folder|Out-Null
 $controller=Get-Process -Id $PID -ErrorAction Stop
 $config=@{schema=1;timeoutSeconds=30;controller=@{pid=$PID;path=$controller.Path;ticks=$controller.StartTime.ToUniversalTime().Ticks;sha256=(Get-FileHash -LiteralPath $controller.Path).Hash.ToLowerInvariant()};target=@{pid=$Target.Id;path=$Runner;ticks=$Target.StartTime.ToUniversalTime().Ticks;sha256=$Hash}}
 Write-RkAtomicJson (Join-Path $folder 'config.json') $config
 Write-RkAtomicJson (Join-Path $folder 'heartbeat.json') @{sequence=0}
 $python=(Get-Command python -ErrorAction Stop).Source
 $pythonOutput=@(& $python -c 'import os,sys;p,e=os.path.splitext(sys._base_executable);print(p+chr(119)+e)')
 if($LASTEXITCODE -ne 0 -or $pythonOutput.Count -ne 1 -or !(Test-Path -LiteralPath $pythonOutput[0] -PathType Leaf)){throw 'Cannot resolve direct Python guardian executable.'}
 $python=$pythonOutput[0];Assert-RkNoLinks $python
 $arguments='"'+(Join-Path $PSScriptRoot 'watchdog.py')+'" --config "'+(Join-Path $folder 'config.json')+'"'
 $guardian=New-Object Diagnostics.Process
 $guardian.StartInfo=New-Object Diagnostics.ProcessStartInfo
 $guardian.StartInfo.FileName=$python;$guardian.StartInfo.Arguments=$arguments
 $guardian.StartInfo.UseShellExecute=$false;$guardian.StartInfo.CreateNoWindow=$true
 if(!$guardian.Start()){throw 'Independent guardian launch failed.'}
 # Windows PowerShell5.1 needs the native handle retained before exit to retain ExitCode.
 $null=$guardian.Handle
 $script:RkWatchdog=@{process=$guardian;root=$folder;sequence=0;abort=(Join-Path $Root 'abort.request')}
 $deadline=[DateTime]::UtcNow.AddSeconds(10)
 while(!(Test-Path -LiteralPath (Join-Path $folder 'ready.json'))){
  $guardian.Refresh()
  if($guardian.HasExited -or [DateTime]::UtcNow -ge $deadline){throw 'External watchdog did not arm; no input authorized.'}
  Start-Sleep -Milliseconds 50
 }
 Update-RkExternalWatchdog
}
function Assert-RkExternalWatchdog {
 if(!$script:RkWatchdog){return} # Harmless NativeTest deliberately has no game guardian.
 $guard=$script:RkWatchdog;$guard.process.Refresh()
 Assert-RkNoLinks $guard.root
 foreach($name in @('stop.json','failure.json','result.json')){
  if(Test-Path -LiteralPath (Join-Path $guard.root $name)){throw 'External watchdog ended/stopped; no further input.'}
 }
 if($guard.process.HasExited){throw 'External watchdog exited; no further input.'}
}
function Update-RkExternalWatchdog {
 Assert-RkExternalWatchdog
 if(!$script:RkWatchdog){return}
 $guard=$script:RkWatchdog
 if(Test-Path -LiteralPath $guard.abort){
  if(!(Test-Path -LiteralPath (Join-Path $guard.root 'abort.request'))){Write-RkAtomicJson (Join-Path $guard.root 'abort.request') @{requested=$true}}
  throw 'Emergency abort requested; no heartbeat extension.'
 }
 $guard.sequence++
 Write-RkAtomicJson (Join-Path $guard.root 'heartbeat.json') @{sequence=$guard.sequence}
}
function Complete-RkExternalWatchdog {
 if(!$script:RkWatchdog){return}
 $guard=$script:RkWatchdog
 try {
  if(!$guard.process.WaitForExit(6000)){throw 'External watchdog did not finish after owned process exit; preserve session.'}
  if($guard.process.ExitCode -ne 0 -or (Test-Path -LiteralPath (Join-Path $guard.root 'stop.json')) -or (Test-Path -LiteralPath (Join-Path $guard.root 'failure.json'))){throw 'External watchdog intervention/failure; automatic recovery refused.'}
  $receipt=Get-Content -LiteralPath (Join-Path $guard.root 'result.json') -Raw -Encoding UTF8|ConvertFrom-Json
  if($receipt.result -cne 'OWNED_PROCESS_EXITED'){throw 'External watchdog closure unverified; preserve session.'}
 }finally{$script:RkWatchdog=$null}
}
