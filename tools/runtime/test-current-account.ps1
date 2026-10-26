# Executable filesystem/failure tests. No actual profile, Steam or native API use.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
$count=0
function Check([bool]$value,[string]$name){if(!$value){throw $name};$script:count++;Write-Output ('OFFLINE_PASS '+$name)}
function Refuses([scriptblock]$operation,[string]$name){$failed=$false;try{& $operation}catch{$failed=$true};Check $failed $name}
# C# type/layout validation only. No kernel32 API is called here.
$nativeSource=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'current-account-windows.ps1') -Raw
$nativeDefinition=[regex]::Match($nativeSource,"(?s)Add-Type @'\r?\n(.*?)\r?\n'@").Groups[1].Value
if(!('RkNativeFiles' -as [type])){Add-Type -TypeDefinition $nativeDefinition}
Check ([Runtime.InteropServices.Marshal]::SizeOf([type][RkNativeFiles+Info]) -eq 52) 'native file-info layout compiles; API not invoked'
Check ([Runtime.InteropServices.Marshal]::SizeOf([type][RkNativeFiles+CaseInfo]) -eq 4) 'native case-info layout compiles; API not invoked'
$temp=Join-Path ([IO.Path]::GetTempPath()) ('rk-current-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
 foreach($case in @('normal','pending-before','pending-after','prepared-after','restore-gap','journal-truncated','snapshot-fallback','absent','empty','identical-trial')){
  $base=Join-Path $temp $case;New-Item -ItemType Directory -Path $base | Out-Null
  $save=Join-Path $base 'save';$root=Join-Path $base 'session'
  if($case -ne 'absent'){
   New-Item -ItemType Directory -Path (Join-Path $save 'empty') -Force | Out-Null
   if($case -ne 'empty'){Set-Content -LiteralPath (Join-Path $save 'file0') -Value 'SYNTHETIC ORIGINAL';Set-Content -LiteralPath (Join-Path $save 'system_information_963') -Value 'SYNTHETIC HISTORY'}
  }
  $s=New-RkSaveTransaction $root $save 'synthetic-owner' 'original'
  if($case -eq 'pending-before'){$s.phase='QuarantinePending';Save-RkJournal $s}
  elseif($case -in @('pending-after','prepared-after')){
   if($case -eq 'pending-after'){$s.phase='QuarantinePending';Save-RkJournal $s};Move-Item -LiteralPath $save -Destination (Join-Path $root 'protected-save')
  }else{
   Start-RkSaveTransaction $s
   New-Item -ItemType Directory -Path $save | Out-Null
   Set-Content -LiteralPath (Join-Path $save 'file0') -Value 'SYNTHETIC TRIAL'
   if($case -eq 'identical-trial'){Remove-Item -LiteralPath $save -Recurse -Force;Copy-Item -LiteralPath (Join-Path $root 'snapshot') -Destination $save -Recurse -Force}
   if($case -eq 'snapshot-fallback'){Remove-Item -LiteralPath (Join-Path $root 'protected-save') -Recurse -Force}
   if($case -eq 'journal-truncated'){Set-Content -LiteralPath (Join-Path $root 'session.json') -Value '{TRUNCATED';$s=Read-RkJournal $root}
   if($case -eq 'restore-gap'){$s.phase='Restoring';Save-RkJournal $s;Move-Item -LiteralPath $save -Destination (Join-Path $root 'trial-save')}
  }
  Restore-RkSaveTransaction $s $root $save 'synthetic-owner'
  Check ($s.phase -eq 'Restored') ('restore phase: '+$case)
  if($s.originalPresent){Check ((Get-RkTreeDigest $save) -ceq $s.originalDigest) ('original independent digest: '+$case)}else{Check (!(Test-Path -LiteralPath $save)) 'restore absence'}
  Restore-RkSaveTransaction $s $root $save 'synthetic-owner'
  Check ($s.phase -eq 'Restored') ('idempotent recovery: '+$case)
  Refuses {Restore-RkSaveTransaction $s $root $save 'different-owner'} ('different owner refused: '+$case)
 }
 $base=Join-Path $temp 'corruption';$save=Join-Path $base 'save';$root=Join-Path $base 'session'
 New-Item -ItemType Directory -Path $save -Force | Out-Null;Set-Content -LiteralPath (Join-Path $save 'file0') -Value 'SYNTHETIC ORIGINAL'
 $s=New-RkSaveTransaction $root $save 'owner' 'patched';Start-RkSaveTransaction $s
 Set-Content -LiteralPath (Join-Path $root 'protected-save/file0') -Value 'CORRUPT'
 Refuses {Restore-RkSaveTransaction $s $root $save 'owner'} 'corrupt protected copy never overwrites a save'
 $json=Join-Path $temp 'atomic.json';Write-RkAtomicJson $json @{text=([string][char]0xD55C+[char]0xAE00);sequence=1};Write-RkAtomicJson $json @{text=([string][char]0xD55C+[char]0xAE00);sequence=2}
 Check ((Get-Content -LiteralPath $json -Raw -Encoding UTF8 | ConvertFrom-Json).text -ceq ([string][char]0xD55C+[char]0xAE00)) 'UTF8 journal roundtrip'
 Check ((Get-Content -LiteralPath ($json+'.previous') -Raw -Encoding UTF8 | ConvertFrom-Json).sequence -eq 1) 'previous atomic journal retained'
 $source=Join-Path $temp 'input';New-Item -ItemType Directory -Path $source | Out-Null
 Set-Content -LiteralPath (Join-Path $source 'data.win') -Value 'SYNTHETIC DATA'
 $hash=(Get-FileHash -LiteralPath (Join-Path $source 'data.win')).Hash
 $files=@(@{path='data.win';original=$hash;patched=$hash})
 $destination=Join-Path $temp 'side-game'
 New-RkSideCopy $source $destination $files '' 'original'
 Check ((Get-FileHash -LiteralPath (Join-Path $destination 'data.win')).Hash -eq $hash) 'atomic side-copy publication'
 Refuses {New-RkSideCopy $source $destination $files '' 'original'} 'existing side-copy cannot be overwritten'
 $broken=Join-Path $temp 'broken-copy'
 Refuses {New-RkSideCopy $source $broken @($files[0],@{path='missing';original=$hash;patched=$hash}) '' 'original'} 'mid-copy failure injection'
 Check (!(Test-Path -LiteralPath $broken)) 'failed side-copy never published'
 Check ((Get-FileHash -LiteralPath (Join-Path $source 'data.win')).Hash -eq $hash) 'pristine source unchanged after copy failure'
 Refuses {New-RkSideCopy $source (Join-Path $source 'nested') $files '' 'original'} 'source/destination overlap refused'
 Refuses {New-RkSaveTransaction (Join-Path $source 'state') $source 'owner' 'original'} 'snapshot recursive overlap refused'
 $steam=Join-Path $temp 'Steam';New-Item -ItemType Directory -Path (Join-Path $steam 'userdata/1/391540/remote') -Force | Out-Null
 $before=Get-RkSteamCacheInventory $steam
 Set-Content -LiteralPath (Join-Path $steam 'userdata/1/391540/remote/file0') -Value 'CACHE CHANGE'
 Check (!(Test-RkCacheEqual $before (Get-RkSteamCacheInventory $steam))) 'Steam cache changes invalidate comparison'
 Check (Get-RkSteamCacheInventory $steam).appCacheFilesPresent 'ordinary cached saves also block initial smoke'
 Set-Content -LiteralPath (Join-Path $steam 'userdata/1/391540/remote/system_information_963') -Value 'HISTORY'
 Check (Get-RkSteamCacheInventory $steam).permanentHistoryPresent 'known Steam permanent history detected'
 $install=Join-Path $steam 'steamapps/common/Undertale';New-Item -ItemType Directory -Path $install -Force | Out-Null
 $manifest=Join-Path $steam 'steamapps/appmanifest_391540.acf';Set-Content -LiteralPath $manifest -Value '"appid" "391540" "installdir" "Undertale"'
 Assert-RkSteamRegistration $steam $install;Check $true 'default Steam library registered read-only'
 $other=Join-Path $temp 'other/steamapps/common/Undertale';New-Item -ItemType Directory -Path $other -Force | Out-Null
 Copy-Item -LiteralPath $manifest -Destination (Join-Path $temp 'other/steamapps/appmanifest_391540.acf')
 Refuses {Assert-RkSteamRegistration $steam $other} 'copied manifest does not register another library'
 Set-Content -LiteralPath (Join-Path $steam 'steamapps/libraryfolders.vdf') -Value ('"path" "'+(Join-Path $temp 'other')+'"')
 Assert-RkSteamRegistration $steam $other;Check $true 'registered secondary library accepted without write probe'
 Set-Content -LiteralPath $manifest -Value '"appid" "391540" "appid" "391540" "installdir" "Undertale"'
 Refuses {Assert-RkSteamRegistration $steam $install} 'duplicate app IDs fail closed'
 Check (!(Test-Path -LiteralPath (Join-Path $temp 'identical-trial/session/protected-save'))) 'identical trial cannot strand quarantine and block archival'
 $history=Join-Path $temp 'history';New-Item -ItemType Directory -Path $history | Out-Null
 $meta=@{runnerSha='runner';harnessSha='harness';steamSha='steam';gameInstall='registered';registeredDigest='digest';cacheBefore=@{apps=@();permanentHistoryPresent=$false}}
 $noSave=Join-Path $temp 'no-save'
 Refuses {Assert-RkOriginalSmoke $history $meta $noSave} 'patched trial requires original observations'
 $archive=Join-Path $history ('completed-'+('a'*32));New-Item -ItemType Directory -Path $archive | Out-Null
 $journal=@{case='original';phase='Restored';cacheStable=$true;registeredStable=$true;originalPresent=$false}
 foreach($key in $meta.Keys){$journal[$key]=$meta[$key]}
 Write-RkAtomicJson (Join-Path $archive 'session.json') $journal
 Write-RkAtomicJson (Join-Path $archive 'result.json') @{result='NOT_RUN';localPhase='Restored'}
 $observations=@('startup','english','keyboard','battle') | ForEach-Object {@{id=$_;status='PASS';method='OPERATOR_REPORTED';actual='Synthetic operator observation only'}}
 Write-RkAtomicJson (Join-Path $archive 'observations.json') $observations
 Assert-RkOriginalSmoke $history $meta $noSave;Check $true 'reported original prerequisites accepted without automatic approval'
 $meta.harnessSha='new-harness';Refuses {Assert-RkOriginalSmoke $history $meta $noSave} 'stale harness cannot qualify original comparison';$meta.harnessSha='harness'
 New-Item -ItemType Directory -Path $noSave | Out-Null
 Refuses {Assert-RkOriginalSmoke $history $meta $noSave} 'changed local baseline blocks comparison'
 Remove-Item -LiteralPath $noSave
 $observations[3].status='NOT_RUN';Write-RkAtomicJson (Join-Path $archive 'observations.json') $observations
 Refuses {Assert-RkOriginalSmoke $history $meta $noSave} 'missing original battle observation blocks comparison'
 $scriptText=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'run-current-account.ps1') -Raw
 $scriptText=[regex]::Replace($scriptText,'(?m)^\s*#.*$','')
 Check (!$scriptText.Contains('Start-RkDisposableInstall') -and !$scriptText.Contains('-applaunch')) 'registered game swap and Steam redirect fallback removed'
 Check ($scriptText.Contains("'observation.lock'") -and $scriptText.Contains("'session.lock'")) 'observation cannot deadlock on active run lock'
} finally {Remove-Item -LiteralPath $temp -Recurse -Force}
Write-Output ("OFFLINE_PASS "+$count+" current-account filesystem/failure checks; Windows/Steam/game NOT_RUN")
