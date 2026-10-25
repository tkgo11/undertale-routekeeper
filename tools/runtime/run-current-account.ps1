# Opt-in SAME-ACCOUNT Windows smoke testing. No Sandbox or additional Windows account.
# Lower isolation: Steam cache/account history can change and is NOT reverted.
# NEVER run SAVE/RESET/TRUE RESET/ERASE/Genocide/Soulless scenarios with this harness.
param(
  [ValidateSet('Preflight','Run','Recover')][string]$Action='Preflight',
  [ValidateSet('original','patched')][string]$Case='original',
  [string]$Lab,[string]$PatchedData,[string]$SteamExe,[string]$GameInstall,
  [switch]$AcceptSteamAccountRisk,[switch]$CloudDisabledAndOffline,
  [ValidateRange(1,90)][int]$Minutes=30
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Windows required.' }
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$principal=[Security.Principal.WindowsPrincipal]::new($identity)
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Use your existing standard user session without elevation.' }
$home=[Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
$local=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
if (!$env:USERPROFILE.Equals($home,[StringComparison]::OrdinalIgnoreCase) -or
    !$env:LOCALAPPDATA.Equals($local,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected Windows profile environment.' }
$save=Join-Path $local 'UNDERTALE'
$sessionDir=Join-Path $local 'RoutekeeperCurrentSession'
$sessionFile=Join-Path $sessionDir 'session.json'
Assert-RkNoLinks $sessionDir
Assert-RkNoLinks $save
function Assert-Closed {
  if (@(Get-Process steam,UNDERTALE -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'Exit Steam and UNDERTALE completely before modifying or restoring protected files.'
  }
}
function Assert-Offline {
  if (@(Get-NetAdapter -ErrorAction Stop | Where-Object Status -eq 'Up').Count -gt 0) {
    throw 'Disconnect all active network adapters manually, after Steam Go Offline. The harness never changes host network settings.'
  }
}
function TreeDigest([string]$dir) {
  Assert-RkTreeNoLinks $dir
  $entries=@(Get-ChildItem -LiteralPath $dir -File -Recurse -Force | ForEach-Object {
    $_.FullName.Substring($dir.Length) + [char]9 + $_.Length + [char]9 +
      (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash + [char]10
  } | Sort-Object)
  $hash=[Security.Cryptography.SHA256]::Create()
  try {
    $bytes=[Text.Encoding]::UTF8.GetBytes(($entries -join ''))
    return ([BitConverter]::ToString($hash.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
  } finally { $hash.Dispose() }
}
function Persist($s) { $s | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $sessionFile }
function Restore-Session($s) {
  Assert-Closed
  Assert-Offline
  if ($s.schema -ne 1 -or $s.owner -ne $identity.User.Value -or $s.savePath -ne $save -or
      $s.id -notmatch '^[a-f0-9]{32}$') { throw 'Session identity failed. Do not relocate backups manually.' }
  $expectedBackup=Join-Path $local ('RoutekeeperOriginalSave-'+$s.id)
  $expectedTrial=Join-Path $local ('RoutekeeperTrialSave-'+$s.id)
  if ($s.protectedSave -ne $expectedBackup -or $s.trialSave -ne $expectedTrial) { throw 'Untrusted save restore paths.' }
  if ($s.gameInstall -and $s.installed) {
    $tx=@{Installed=$s.gameInstall;Backup=$s.gameBackup;Id=$s.id}
    $marker=Join-Path $tx.Installed '.routekeeper-disposable-install'
    if (!(Test-Path -LiteralPath $marker)) { throw 'Missing install marker. Keep recovery directories for review.' }
    Stop-RkDisposableInstall $tx
    $s.installed=$false;Persist $s
  }
  if ($s.originalPresent -and ($s.saveHidden -or $s.saveMovePending)) {
    Assert-RkNoLinks $s.protectedSave
    Assert-RkNoLinks $s.trialSave
    if (!(Test-Path -LiteralPath $s.protectedSave)) {
      if (!(Test-Path -LiteralPath $save) -or (TreeDigest $save) -ne $s.originalDigest) {
        throw 'Protected original save absent or changed. Verify private snapshot before manual recovery.'
      }
    } else {
      if ((TreeDigest $s.protectedSave) -ne $s.originalDigest) { throw 'Quarantined save hash changed.' }
      if (Test-Path -LiteralPath $save) {
        if (Test-Path -LiteralPath $s.trialSave) { throw 'Trial-save archive already exists.' }
        Move-Item -LiteralPath $save -Destination $s.trialSave
      }
      Move-Item -LiteralPath $s.protectedSave -Destination $save
    }
    $s.saveHidden=$false;$s.saveMovePending=$false;Persist $s
  } elseif (!$s.originalPresent -and (Test-Path -LiteralPath $save)) {
    if (Test-Path -LiteralPath $s.trialSave) { throw 'Trial-save archive already exists.' }
    Move-Item -LiteralPath $save -Destination $s.trialSave
  }
  $s.restored=$true;Persist $s
  Write-Host 'Original local saves and Steam game installation restored. Steam account cache/history NOT restored.'
}
if ($Action -eq 'Preflight') {
  Write-Host 'Current-account smoke test, without Windows Sandbox or a new account.'
  Write-Host 'Personal local saves are independently backed up and temporarily quarantined.'
  Write-Host 'Steam Cloud MUST be disabled before testing; Steam must be offline AND all adapters disconnected.'
  Write-Host 'Steam account-level persistent history cannot be guaranteed safe, even offline.'
  Write-Host 'LIMIT TO title, UI, controls and early combat; no saving, resetting or endings.'
  if (Test-Path -LiteralPath $sessionFile) { Write-Warning 'A prior session exists. Inspect and Recover before reuse.' }
  return
}
if ($Action -eq 'Recover') {
  Assert-Closed;Assert-Offline
  if (!(Test-Path -LiteralPath $sessionFile)) { throw 'No session to recover.' }
  Restore-Session (Get-Content -LiteralPath $sessionFile -Raw | ConvertFrom-Json)
  return
}
if (!$AcceptSteamAccountRisk -or !$CloudDisabledAndOffline) {
  throw 'Explicit acknowledgment of same-account risk, disabled Steam Cloud and Steam Offline Mode required.'
}
Assert-Closed;Assert-Offline
if (Test-Path -LiteralPath $sessionDir) { throw 'Prior session exists. Recover and review it before a new run.' }
foreach($name in @('Lab','PatchedData','SteamExe','GameInstall')) {
  if ([string]::IsNullOrWhiteSpace((Get-Variable $name).Value)) { throw "Missing parameter: $name" }
}
$Lab=(Resolve-Path -LiteralPath $Lab).Path
$PatchedData=(Resolve-Path -LiteralPath $PatchedData).Path
$SteamExe=(Resolve-Path -LiteralPath $SteamExe).Path
$GameInstall=(Resolve-Path -LiteralPath $GameInstall).Path
foreach($path in @($Lab,$PatchedData,$SteamExe,$GameInstall)) { Assert-RkNoLinks $path }
if (!(Test-RkWithin $Lab $home) -or !(Test-RkWithin $PatchedData $home)) { throw 'Lab and candidate must be private within the current user profile.' }
if ([IO.Path]::GetFileName($SteamExe) -ine 'steam.exe' -or [IO.Path]::GetFileName($GameInstall) -ine 'Undertale') {
  throw 'Expected official Steam.exe and registered Undertale game directory.'
}
if (!(Test-Path -LiteralPath (Join-Path $Lab '.routekeeper-disposable-runtime-lab'))) { throw 'Fresh private runtime lab not prepared.' }
$manifest=Join-Path (Split-Path (Split-Path $GameInstall -Parent) -Parent) 'appmanifest_391540.acf'
Assert-RkNoLinks $manifest
if (!(Test-Path -LiteralPath $manifest) -or (Get-Content -LiteralPath $manifest -Raw) -notmatch '"appid"\s+"391540"') {
  throw 'Steam library registration unavailable.'
}
$originalSha='b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'
$runnerSha='c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
Assert-RkHash (Join-Path $GameInstall 'UNDERTALE.exe') $runnerSha
Assert-RkHash (Join-Path $GameInstall 'data.win') $originalSha
$reg=Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\..\profiles\registry.json') -Raw | ConvertFrom-Json
$profile=@($reg | Where-Object { $_.OriginalSha256 -eq $originalSha -and $_.ExecutableSha256 -eq $runnerSha })
if ($profile.Count -ne 1) { throw 'No unique exact-build profile.' }
Assert-RkHash $PatchedData $profile[0].PatchedSha256
$original=Join-Path $Lab 'original'
$run=Join-Path $Lab ('runs\'+$Case)
$input=Get-Content -LiteralPath (Join-Path $Lab 'identity-private.json') -Raw | ConvertFrom-Json
if ((Get-RkInventoryDigest $input.files) -ne 'd0d633daad4d0c45a3f6761e9627ad7188853219ff96122b426d06b7a345932a') { throw 'ZIP inventory changed.' }
$files=@()
foreach($f in $input.files) {
  if (!$f.path.StartsWith('Undertale/')) { continue }
  $relative=$f.path.Substring(10)
  Assert-RkRelative $relative
  Assert-RkHash (Join-Path $original $f.path) $f.sha256
  $wanted=if ($Case -eq 'patched' -and $relative -eq 'data.win') { $profile[0].PatchedSha256 } else { $f.sha256 }
  if ($Case -eq 'patched' -and $relative -eq 'data.win') {
    Copy-Item -LiteralPath $PatchedData -Destination (Join-Path $run $relative) -Force
  }
  Assert-RkHash (Join-Path $run $relative) $wanted
  $files+=@{path=$relative;sha256=$wanted}
}
if ($files.Count -lt 210) { throw 'Incomplete game file inventory.' }
$id=[guid]::NewGuid().ToString('N')
$protected=Join-Path $local ('RoutekeeperOriginalSave-'+$id)
$trial=Join-Path $local ('RoutekeeperTrialSave-'+$id)
$hadOriginal=(Test-Path -LiteralPath $save)
$snapshot=Join-Path $Lab ('original-save-snapshot-'+$id)
$saveDigest=''
if ($hadOriginal) {
  Assert-RkTreeNoLinks $save
  Copy-Item -LiteralPath $save -Destination $snapshot -Recurse
  $saveDigest=TreeDigest $save
  if ((TreeDigest $snapshot) -ne $saveDigest) { throw 'Personal save snapshot verification failed.' }
}
New-Item -ItemType Directory -Path $sessionDir | Out-Null
$s=[pscustomobject]@{
  schema=1;owner=$identity.User.Value;id=$id;originalPresent=$hadOriginal;
  savePath=$save;protectedSave=$protected;trialSave=$trial;originalDigest=$saveDigest;
  snapshot=$snapshot;saveMovePending=$false;saveHidden=$false;installed=$false;
  gameInstall=$GameInstall;gameBackup=($GameInstall+'.routekeeper-vm-backup-'+$id);restored=$false
}
Persist $s
$report=[ordered]@{case=$Case;result='NOT_RUN';kind='CURRENT_ACCOUNT_SMOKE';id=$id;
  note='Observations only. Steam persistent history is NOT isolated. No gameplay success is inferred.'}
$gameProcess=$null
try {
  if ($hadOriginal) {
    $s.saveMovePending=$true;Persist $s
    Move-Item -LiteralPath $save -Destination $protected
    $s.saveHidden=$true;$s.saveMovePending=$false;Persist $s
  }
  $tx=Start-RkDisposableInstall $run $GameInstall $files $id
  $s.installed=$true;Persist $s
  Start-Process -FilePath $SteamExe -ArgumentList '-offline' | Out-Null
  $until=(Get-Date).AddSeconds(90)
  while (@(Get-Process steam -ErrorAction SilentlyContinue).Count -eq 0 -and (Get-Date) -lt $until) { Start-Sleep -Milliseconds 500 }
  if (@(Get-Process steam -ErrorAction SilentlyContinue).Count -eq 0) { throw 'Steam Offline client did not start.' }
  Start-Process -FilePath $SteamExe -ArgumentList '-applaunch 391540' | Out-Null
  $until=(Get-Date).AddSeconds(60)
  do {
    Start-Sleep -Milliseconds 500
    $gameProcess=Get-Process UNDERTALE -ErrorAction SilentlyContinue |
      Where-Object { $_.Path -and $_.Path.Equals((Join-Path $GameInstall 'UNDERTALE.exe'),[StringComparison]::OrdinalIgnoreCase) } |
      Select-Object -First 1
  } while (!$gameProcess -and (Get-Date) -lt $until)
  if (!$gameProcess) { throw 'Exact Steam runner did not launch.' }
  Write-Host 'SMOKE ONLY: title, UI, controls, early battles. Do NOT SAVE, RESET or complete an ending.'
  Write-Host 'Close UNDERTALE when finished; then EXIT STEAM while still offline.'
  $report.started=$true
  if (!$gameProcess.WaitForExit($Minutes*60000)) {
    $null=$gameProcess.CloseMainWindow()
    if (!$gameProcess.WaitForExit(10000)) { $gameProcess.Kill();$gameProcess.WaitForExit() }
  }
  $report.exitCode=$gameProcess.ExitCode
  if ($gameProcess.ExitCode -ne 0) { $report.result='BLOCKED';$report.reason='Game exited nonzero.' }
} catch {
  $report.result='BLOCKED';$report.reason=$_.Exception.Message
  Write-Warning $report.reason
} finally {
  if ($gameProcess -and !$gameProcess.HasExited) {
    $null=$gameProcess.CloseMainWindow()
    if (!$gameProcess.WaitForExit(10000)) { $gameProcess.Kill();$gameProcess.WaitForExit() }
  }
  Write-Host 'Exit Steam completely now, while offline. Restoration waits for Steam to stop.'
  $until=(Get-Date).AddSeconds(180)
  while (@(Get-Process steam,UNDERTALE -ErrorAction SilentlyContinue).Count -gt 0 -and (Get-Date) -lt $until) { Start-Sleep -Seconds 2 }
  try { Restore-Session $s }
  catch {
    $report.result='BLOCKED';$report.restore=$_.Exception.Message
    Write-Warning 'Restore incomplete! Stay offline; close Steam and execute -Action Recover. NEVER delete protected backups.'
  }
  $report.restored=[bool]$s.restored
  $dir=Join-Path $Lab 'evidence\current-account'
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $dir ($Case+'-'+$id+'.json'))
}
