# Live private capture acquisition. Agent review is documentary, never human review.
function Assert-RkAcquisitionRequest($Request,[int]$Sequence,[string]$CaptureSha256) {
 if(($Request.schema -isnot [int] -and $Request.schema -isnot [long]) -or $Request.schema -ne 1 -or ($Request.sequence -isnot [int] -and $Request.sequence -isnot [long]) -or $Request.sequence -ne $Sequence -or $Request.captureSha256 -cne $CaptureSha256 -or $Request.reviewMethod -cne 'AGENT_DELEGATED' -or [string]::IsNullOrWhiteSpace($Request.reviewStatement) -or $Request.reviewStatement.Length -lt 10){throw 'Fresh scoped capture-bound agent review required.'}
 if($Request.action -notin @('capture','stop','up','down','left','right','confirm','cancel','enter','settings','language','acknowledge')){throw 'Unsupported acquisition action.'}
 $recorded=if($Request.recordedUtc -is [DateTime]){$Request.recordedUtc.ToUniversalTime()}else{[DateTime]::Parse($Request.recordedUtc).ToUniversalTime()}
 $age=([DateTime]::UtcNow-$recorded).TotalSeconds
 if($age -lt 0 -or $age -gt 30){throw 'Acquisition review expired.'}
 if($Request.action -notin @('capture','stop') -and (($Request.holdMs -isnot [int] -and $Request.holdMs -isnot [long]) -or $Request.holdMs -lt 50 -or $Request.holdMs -gt 500)){throw 'Bounded input hold required.'}
}
function Invoke-RkNativeAcquisition($Process,[string]$Runner,[string]$Root,[string]$Case,[string]$Abort,$SteamProcess,[string]$SteamExe,[long]$SteamTicks,[ref]$UnknownChildren) {
 $hash='c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
 $ticks=$Process.StartTime.ToUniversalTime().Ticks;$window=$Process.MainWindowHandle
 $watch=[Diagnostics.Stopwatch]::StartNew();$sequence=1;$rows=New-Object 'Collections.Generic.List[object]'
 $latest=$Case+'.png';$sha=(Get-FileHash -LiteralPath (Join-Path $Root $latest)).Hash.ToLowerInvariant()
 $sidecarSha=(Get-FileHash -LiteralPath ((Join-Path $Root $latest)+'.json')).Hash.ToLowerInvariant()
 $status=@{schema=1;kind='AGENT_DELEGATED_CAPTURE_ACQUISITION';pid=$Process.Id;windowHandle=$window.ToInt64();startedTicks=$ticks;case=$Case;nextSequence=$sequence;capture=$latest;captureSha256=$sha;result='WAITING_FOR_REVIEW';inputsAccepted='UNPROVEN';steps=@()}
 Write-RkAtomicJson (Join-Path $Root 'acquisition-status.json') $status
 try {
  while($watch.Elapsed.TotalSeconds -lt 240 -and $sequence -le 40){
   Update-RkExternalWatchdog;Assert-RkExperimentalNetwork
   Assert-RkInputWindow $Process $window $Runner $hash $ticks $Abort
   Assert-RkProcessIdentity @(Get-Process UNDERTALE -ErrorAction SilentlyContinue) $Process.Id $Runner $ticks
   Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $SteamProcess.Id $SteamExe $SteamTicks
   try{$children=@(Get-CimInstance Win32_Process -Filter ('ParentProcessId='+$Process.Id) -OperationTimeoutSec 5 -ErrorAction Stop)}catch{$UnknownChildren.Value=$true;throw}
   if($children.Count){$UnknownChildren.Value=$true;throw 'Unknown acquisition descendant; stop input.'}
   $path=Join-Path $Root ('acquisition-request-'+$sequence.ToString('D3')+'.json')
   Assert-RkNoLinks $path
   if(!(Test-Path -LiteralPath $path)){Start-Sleep -Milliseconds 100;continue}
   if((Get-Item -LiteralPath $path).Length -gt 16384){throw 'Acquisition request exceeds budget.'}
   $requestSha=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()
   $request=Get-Content -LiteralPath $path -Raw -Encoding UTF8|ConvertFrom-Json
   Assert-RkAcquisitionRequest $request $sequence $sha
   $currentImage=Join-Path $Root $latest
   Assert-RkNoLinks $currentImage;Assert-RkNoLinks ($currentImage+'.json')
   if((Get-FileHash -LiteralPath ($currentImage+'.json')).Hash.ToLowerInvariant() -cne $sidecarSha){throw 'Reviewed capture sidecar changed.'}
   $currentMetadata=Get-Content -LiteralPath ($currentImage+'.json') -Raw -Encoding UTF8|ConvertFrom-Json
   if((Get-FileHash -LiteralPath $currentImage).Hash.ToLowerInvariant() -cne $sha -or $currentMetadata.imageSha256 -cne $sha -or $currentMetadata.pid -ne $Process.Id -or $currentMetadata.windowHandle -ne $window.ToInt64()){throw 'Reviewed capture bytes or ownership changed.'}
   foreach($name in @(('input-intent-'+$sequence+'.json'),('input-dispatch-'+$sequence+'.json'),('acquisition-'+$sequence.ToString('D3')+'.png'),('acquisition-'+$sequence.ToString('D3')+'.png.json'))){
    $output=Join-Path $Root $name;Assert-RkNoLinks $output
    if(Test-Path -LiteralPath $output){throw 'Acquisition output already exists; no input or overwrite.'}
   }
   if((Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() -cne $requestSha){throw 'Acquisition review changed.'}
   if($request.action -eq 'stop'){$status.result='STOPPED_BY_REVIEWED_REQUEST';return $status}
   $before=$latest;$dispatch=$null
   if($request.action -ne 'capture'){
    Write-RkAtomicJson (Join-Path $Root ('input-intent-'+$sequence+'.json')) @{key=$request.action;reviewSha256=$requestSha;startedUtc=[DateTime]::UtcNow.ToString('o');state='ATTEMPTED_NOT_ACKNOWLEDGED'}
    $dispatch=Send-RkWindowKey $Process $window $Runner $hash $ticks $request.action $request.holdMs $Abort -AdditionalGuard {Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $SteamProcess.Id $SteamExe $SteamTicks}
    Write-RkAtomicJson (Join-Path $Root ('input-dispatch-'+$sequence+'.json')) $dispatch
   }
   Assert-RkProcessIdentity @(Get-Process steam -ErrorAction SilentlyContinue) $SteamProcess.Id $SteamExe $SteamTicks
   $latest='acquisition-'+$sequence.ToString('D3')+'.png'
   Save-RkWindowCapture $Process $Runner (Join-Path $Root $latest) $hash $window
   $sha=(Get-FileHash -LiteralPath (Join-Path $Root $latest)).Hash.ToLowerInvariant()
   $sidecarSha=(Get-FileHash -LiteralPath ((Join-Path $Root $latest)+'.json')).Hash.ToLowerInvariant()
   $rows.Add(@{sequence=$sequence;reviewSha256=$requestSha;before=$before;after=$latest;dispatch=$dispatch;response='UNREVIEWED_NOT_PASS'})
   $sequence++;$status.nextSequence=$sequence;$status.capture=$latest;$status.captureSha256=$sha;$status.steps=@($rows.ToArray())
   Write-RkAtomicJson (Join-Path $Root 'acquisition-status.json') $status
  }
  throw 'Acquisition bounded time/action budget expired.'
 }catch{$status.result='BLOCKED';$status.reason=$_.Exception.Message;throw}
 finally{$status.steps=@($rows.ToArray());Write-RkAtomicJson (Join-Path $Root 'acquisition-status.json') $status}
}
