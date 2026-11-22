# Console front end for the shared human-guided controller.
function Get-RkHumanCliScenario([string]$Name,[string]$Case) {
 switch -CaseSensitive ($Name) {
  'startup' {
   if($Case -ceq 'original'){return @{scenario='supported-build';step='runner';risk='NonDestructive';scope='Smoke'}}
   return @{scenario='patched-startup';step='exercise';risk='NonDestructive';scope='Smoke'}
  }
  'menu' {return @{scenario='f10';step='exercise';risk='NonDestructive';scope='Smoke'}}
  'movement' {return @{scenario='movement';step='exercise';risk='Gameplay';scope='Gameplay'}}
  default {throw 'Choose startup, menu or movement.'}
 }
}
function Get-RkHumanBytesHash([byte[]]$Bytes) {
 $hasher=[Security.Cryptography.SHA256]::Create()
 try{return ([BitConverter]::ToString($hasher.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant()}
 finally{$hasher.Dispose()}
}
function Get-RkHumanTextHash([string]$Text) { Get-RkHumanBytesHash ([Text.Encoding]::UTF8.GetBytes($Text)) }
function Read-RkHumanCliPhrase([string]$Expected) {
 Write-Host ('Enter exactly: '+$Expected)
 if([Console]::ReadLine() -cne $Expected){throw 'The approval phrase did not match. Start a new trial to retry.'}
}
function New-RkHumanCliRequest($Scenario,[string]$Case,[string]$Language,[string]$Mode,[int]$Seconds,[bool]$Capture,[bool]$Connected) {
 if([Console]::IsInputRedirected -or [Console]::IsOutputRedirected){throw 'Play requires an interactive Windows console for direct consent.'}
 if($Seconds -lt 60 -or $Seconds -gt 7200 -or ($Scenario.scope -ceq 'Smoke' -and $Seconds -gt 300)){throw 'Deadline outside the selected scope.'}
 if($Scenario.scenario -ceq 'f10' -and $Case -cne 'patched'){throw 'The F10 menu scenario requires the patched copy.'}
 $policy=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'human-beta-policy.json') -Raw -Encoding UTF8|ConvertFrom-Json
 $nonce=[guid]::NewGuid().ToString('N')
 $phrase='AUTHORIZE HUMAN BETA '+$nonce
 Write-Host $policy.disclosure
 Write-Host ('Scope {0}; {1}/{2}; {3} copy; {4} / {5}; {6}s; screenshots {7}; connected {8}.' -f $Scenario.scope,$Scenario.scenario,$Scenario.step,$Case,$Language,$Mode,$Seconds,$Capture,$Connected)
 Write-Host 'Mandatory harmless desktop diagnostics run before launch. During play, use only the selected action. Do not SAVE or RESET.'
 Read-RkHumanCliPhrase $phrase
 $networkPhrase=$null;$networkHash=$null
 if($Connected){
  $disclosure=Get-RkNetworkRiskDisclosure -HumanBeta
  if([string]::IsNullOrWhiteSpace($disclosure)){throw 'Connected-network disclosure is missing.'}
  Write-Host $disclosure
  $networkPhrase='ACCEPT CONNECTED NETWORK RISK '+$nonce
  Read-RkHumanCliPhrase $networkPhrase
  $networkHash=Get-RkHumanTextHash $disclosure
 }
 $process=Get-Process -Id $PID
 $path=$process.Path;Assert-RkNoLinks $path
 return @{
  schema=1;kind='HUMAN_BETA_CLI_REQUEST';id=[guid]::NewGuid().ToString('N');betaSession=[guid]::NewGuid().ToString('N')
  scenario=$Scenario.scenario;step=$Scenario.step;nonce=$nonce;captureConsent=$Capture;diagnosticConsent=$true
  case=$Case;scope=$Scenario.scope;risk=$Scenario.risk;phrase=$phrase;language=$Language;mode=$Mode;maximumSeconds=$Seconds
  issuedUtc=[DateTime]::UtcNow.ToString('o');policy=$policy.id;disclosureSha256=(Get-RkHumanTextHash $policy.disclosure)
  connectedNetworkPhrase=$networkPhrase;connectedNetworkDisclosureSha256=$networkHash
  parent=@{pid=$PID;ticks=$process.StartTime.ToUniversalTime().Ticks;path=$path;sha256=(Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
 }
}
function Write-RkHumanNewJson([string]$Path,$Value,[switch]$PassHash) {
 Assert-RkNoLinks $Path
 $temporary=$Path+'.new-'+[guid]::NewGuid().ToString('N')
 $bytes=[Text.Encoding]::UTF8.GetBytes(($Value|ConvertTo-Json -Depth 8))
 $stream=[IO.File]::Open($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try {
  try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
  [IO.File]::Move($temporary,$Path)
 }finally{if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force}}
 if($PassHash){Get-RkHumanBytesHash $bytes}
}
function Invoke-RkHumanCliCommand([string]$Action,[string]$Work,[string]$Session) {
 if($Session -cnotmatch '^human-[a-f0-9]{32}$'){throw 'Use the exact trial identifier printed by Play.'}
 $id=$Session.Substring(6)
 $requestFile=Join-Path $Work "requests/request-$id.json"
 Assert-RkNoLinks $requestFile
 if(!(Test-Path -LiteralPath $requestFile -PathType Leaf) -or (Get-Item -LiteralPath $requestFile).Length -gt 65536){throw 'Bounded CLI request not found.'}
 $request=ConvertFrom-RkHumanJson (Get-Content -LiteralPath $requestFile -Raw -Encoding UTF8) 'Request'
 if($request.kind -cne 'HUMAN_BETA_CLI_REQUEST' -or $request.id -cne $id){throw 'Trial does not match a CLI request.'}
 $root=Join-Path $Work $Session
 $statusPath=Join-Path $root 'human-status.json';Assert-RkNoLinks $statusPath
 $status=$null
 if(Test-Path -LiteralPath $statusPath -PathType Leaf){
  if((Get-Item -LiteralPath $statusPath).Length -gt 65536){throw 'Status exceeds its byte budget.'}
  $status=Get-Content -LiteralPath $statusPath -Raw -Encoding UTF8|ConvertFrom-Json
  if($status.schema -ne 1 -or $status.session -cne $id -or $status.betaSession -cne $request.betaSession -or
     $status.state -cnotin @('RUNNING_HUMAN','RESTORING','RESTORED','BLOCKED','RECOVERY_REQUIRED')){throw 'Status belongs to a different or unknown trial.'}
 }
 if($Action -ceq 'Status'){
  [pscustomobject]@{session=$Session;state=$(if($status){$status.state}else{'NO_STATUS_RECEIPT'});gameplay='NOT_INDEPENDENTLY_VERIFIED';accountHistory='NOT_RESTORED'}|ConvertTo-Json -Compress
  return
 }
 if($status -and $status.state -cne 'RUNNING_HUMAN'){throw 'Trial is already closing or finished.'}
 Assert-RkHumanParent $request
 if(!$status){
  if($Action -cne 'Stop'){throw 'Wait for RUNNING_HUMAN before requesting a capture.'}
  Write-RkHumanNewJson ($requestFile+'.stop.json') @{schema=1;session=$id;action='stop'}
 }else{
  if($Action -ceq 'Capture' -and $request.captureConsent -ne $true){throw 'Play did not authorize optional screenshots.'}
  $sequence=$status.nextSequence
  if(($sequence -isnot [int] -and $sequence -isnot [long]) -or $sequence -lt 1 -or $sequence -gt 1000){throw 'Unknown command sequence.'}
  Write-RkHumanNewJson (Join-Path $root ('human-command-'+$sequence.ToString('D6')+'.json')) @{schema=1;session=$id;sequence=$sequence;action=$Action.ToLowerInvariant()}
 }
 Write-Output ($Action.ToUpperInvariant()+'_REQUESTED')
}
