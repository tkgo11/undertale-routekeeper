# Owned synthetic files and mocked APIs only. Never starts Steam/game or dispatches input.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'native-acquisition.ps1')
$checks=0
function Check([bool]$Value,[string]$Name){if(!$Value){throw $Name};$script:checks++;Write-Host ('PASS '+$Name)}
function Put([string]$Path,[string]$Text){[IO.File]::WriteAllText($Path,$Text,[Text.UTF8Encoding]::new($false))}
function Write-RkAtomicJson([string]$Path,$Value){Put $Path ($Value|ConvertTo-Json -Depth 12)}
function Assert-RkNoLinks {}
function Assert-RkExperimentalNetwork {}
function Assert-RkInputWindow {}
function Assert-RkProcessIdentity {}
function Get-Process {param($Name,$ErrorAction) return @()}
function Get-CimInstance {param($ClassName,$Filter,$OperationTimeoutSec,$ErrorAction) return @()}
function Send-RkWindowKey {$script:keyCalls++;throw 'Synthetic key stub must never be called'}
function Save-RkWindowCapture {throw 'Synthetic capture stub must never be called'}
function Update-RkExternalWatchdog {
 if($script:tamper -eq 'image'){Put (Join-Path $script:root 'original.png') 'CHANGED'}
 if($script:tamper -eq 'owner'){$script:metadata.pid=999;Write-RkAtomicJson (Join-Path $script:root 'original.png.json') $script:metadata}
 if($script:tamper -eq 'metadataHash'){$script:metadata.imageSha256='b'*64;Write-RkAtomicJson (Join-Path $script:root 'original.png.json') $script:metadata}
 $script:tamper=''
}
$base=Join-Path (Join-Path $PSScriptRoot '../../.research') ('native-acquisition-regression-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $base|Out-Null
$game=[pscustomobject]@{Id=456;StartTime=[DateTime]::UtcNow;MainWindowHandle=[IntPtr]1}
$steam=[pscustomobject]@{Id=123}
$cases=@('image','owner','metadataHash','input-intent-1.json','input-dispatch-1.json','acquisition-001.png','acquisition-001.png.json','valid-stop')
foreach($case in $cases){
 $script:root=Join-Path $base $case
 New-Item -ItemType Directory -Path $root|Out-Null
 Put (Join-Path $root 'original.png') 'SYNTHETIC ORIGINAL FRAME'
 $sha=(Get-FileHash -LiteralPath (Join-Path $root 'original.png')).Hash.ToLowerInvariant()
 $script:metadata=@{pid=456;windowHandle=1;imageSha256=$sha}
 Write-RkAtomicJson (Join-Path $root 'original.png.json') $metadata
 $request=@{schema=1;sequence=1;captureSha256=$sha;reviewMethod='AGENT_DELEGATED';reviewStatement='SYNTHETIC scene review for refusal regression only';recordedUtc=[DateTime]::UtcNow.ToString('o');action=$(if($case -eq 'valid-stop'){'stop'}else{'enter'});holdMs=100}
 Write-RkAtomicJson (Join-Path $root 'acquisition-request-001.json') $request
 $script:tamper=if($case -in @('image','owner','metadataHash')){$case}else{''}
 $sentinel=if($case -notin @('image','owner','metadataHash','valid-stop')){Join-Path $root $case}else{$null}
 if($sentinel){Put $sentinel 'UNKNOWN CONTENT MUST SURVIVE'}
 $script:keyCalls=0;$refused=$false;$reason='';$unknown=$false;$result=$null
 try{$result=Invoke-RkNativeAcquisition $game 'SYNTHETIC' $root 'original' '' $steam 'SYNTHETIC' 1 ([ref]$unknown)}catch{$refused=$true;$reason=$_.Exception.Message}
 if($case -eq 'valid-stop'){Check (!$refused -and $result.result -ceq 'STOPPED_BY_REVIEWED_REQUEST') 'untampered capture accepts bounded stop request'}
 else{
  Check $refused ($case+' refuses before dispatch')
  $expected=if($sentinel){'Acquisition output already exists'}elseif($case -in @('owner','metadataHash')){'Reviewed capture sidecar changed'}else{'Reviewed capture bytes or ownership changed'}
  Check ($reason.StartsWith($expected)) ($case+' rejected by intended safeguard')
 }
 Check ($keyCalls -eq 0) ($case+' sends no key')
 if($sentinel){Check ((Get-Content -LiteralPath $sentinel -Raw) -ceq 'UNKNOWN CONTENT MUST SURVIVE') ($case+' preserves unknown output')}
}
Write-Host ('NATIVE_ACQUISITION '+$checks+' PASS; owned synthetic evidence '+$base)
