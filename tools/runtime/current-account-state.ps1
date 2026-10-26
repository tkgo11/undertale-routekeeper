# Filesystem-only current-account journal and recovery. No Steam/Windows API calls.
function Get-RkTreeDigest([string]$Directory) {
    Assert-RkTreeNoLinks $Directory
    $root=[IO.Path]::GetFullPath($Directory).TrimEnd([IO.Path]::DirectorySeparatorChar)
    [string[]]$rows=@(Get-ChildItem -LiteralPath $root -Recurse -Force | ForEach-Object {
        $relative=$_.FullName.Substring($root.Length+1).Replace('\','/')
        if ($_.PSIsContainer) { 'D'+"`t"+$relative+"`n" }
        else { 'F'+"`t"+$relative+"`t"+$_.Length+"`t"+(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()+"`n" }
    })
    [Array]::Sort($rows,[StringComparer]::Ordinal)
    $hash=[Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($hash.ComputeHash([Text.Encoding]::UTF8.GetBytes(($rows -join ''))))).Replace('-','').ToLowerInvariant() }
    finally { $hash.Dispose() }
}
function Write-RkAtomicJson([string]$Path,$Value) {
    Assert-RkNoLinks $Path
    $temporary=$Path+'.new-'+[guid]::NewGuid().ToString('N')
    $bytes=[Text.Encoding]::UTF8.GetBytes(($Value|ConvertTo-Json -Depth 12))
    $stream=[IO.File]::Open($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $stream.Write($bytes,0,$bytes.Length);$stream.Flush($true) } finally { $stream.Dispose() }
    try {
        if (Test-Path -LiteralPath $Path) { Assert-RkNoLinks ($Path+'.previous');[IO.File]::Replace($temporary,$Path,($Path+'.previous')) }
        else { [IO.File]::Move($temporary,$Path) }
    } finally { if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force} }
}
function Read-RkJournal([string]$Root) {
    # Fall back only to an intact previous atomic revision, never to guessed paths.
    foreach($name in @('session.json','session.json.previous')) {
        $path=Join-Path $Root $name
        Assert-RkNoLinks $path
        if(Test-Path -LiteralPath $path){try{return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)}catch{}}
    }
    throw 'No intact session journal. Preserve all directories; automatic recovery refused.'
}
function Assert-RkJournal($State,[string]$Root,[string]$Save,[string]$Owner) {
    if($State.schema -ne 2 -or $State.owner -cne $Owner -or $State.id -notmatch '^[a-f0-9]{32}$' -or $State.savePath -cne $Save){throw 'Session identity mismatch.'}
    if($State.root -cne $Root -or $State.phase -notin @('Prepared','QuarantinePending','Running','Restoring','Restored')){throw 'Session location or phase mismatch.'}
    Assert-RkNoLinks $Root;Assert-RkNoLinks $Save
    if((Test-RkWithin $Root $Save) -or (Test-RkWithin $Save $Root)){throw 'Session/save overlap refused.'}
    if($State.originalPresent -and $State.originalDigest -notmatch '^[a-f0-9]{64}$'){throw 'Original identity missing.'}
}
function Save-RkJournal($State) { Write-RkAtomicJson (Join-Path $State.root 'session.json') $State }
function New-RkSaveTransaction([string]$Root,[string]$Save,[string]$Owner,[string]$Case,[hashtable]$Metadata=@{}) {
    if((Test-RkWithin $Root $Save) -or (Test-RkWithin $Save $Root)){throw 'Snapshot/session/save overlap refused.'}
    if(Test-Path -LiteralPath $Root){throw 'Existing session; recover/archive it first.'}
    Assert-RkNoLinks $Root;Assert-RkNoLinks $Save
    New-Item -ItemType Directory -Path $Root | Out-Null
    $had=Test-Path -LiteralPath $Save
    $digest=''
    if($had){
        $digest=Get-RkTreeDigest $Save
        Copy-Item -LiteralPath $Save -Destination (Join-Path $Root 'snapshot') -Recurse -Force
        if((Get-RkTreeDigest (Join-Path $Root 'snapshot')) -cne $digest -or (Get-RkTreeDigest $Save) -cne $digest){throw 'Snapshot verification failed before quarantine.'}
    }
    $s=[pscustomobject]@{schema=2;owner=$Owner;root=$Root;savePath=$Save;id=[guid]::NewGuid().ToString('N');case=$Case;phase='Prepared';originalPresent=[bool]$had;originalDigest=$digest;cacheStable=$false;registeredStable=$false}
    foreach($key in $Metadata.Keys){$s | Add-Member NoteProperty $key $Metadata[$key]}
    Save-RkJournal $s
    return $s
}
function Start-RkSaveTransaction($State) {
    $State.phase='QuarantinePending';Save-RkJournal $State
    $protected=Join-Path $State.root 'protected-save'
    if(Test-Path -LiteralPath $protected){throw 'Protected save already exists.'}
    if($State.originalPresent){
        if((Get-RkTreeDigest $State.savePath) -cne $State.originalDigest){throw 'Original changed after snapshot; refusing quarantine.'}
        Move-Item -LiteralPath $State.savePath -Destination $protected
    } elseif(Test-Path -LiteralPath $State.savePath){throw 'Unexpected save appeared before launch.'}
    $State.phase='Running';Save-RkJournal $State
}
function Restore-RkSaveTransaction($State,[string]$Root,[string]$Save,[string]$Owner) {
    Assert-RkJournal $State $Root $Save $Owner
    $snapshot=Join-Path $Root 'snapshot';$protected=Join-Path $Root 'protected-save';$trial=Join-Path $Root 'trial-save'
    foreach($path in @($snapshot,$protected,$trial)){Assert-RkNoLinks $path}
    if($State.phase -eq 'Prepared' -and !(Test-Path -LiteralPath $protected)){
        if($State.originalPresent -and (!(Test-Path -LiteralPath $Save) -or (Get-RkTreeDigest $Save) -cne $State.originalDigest)){throw 'Prepared original changed; no quarantine was committed.'}
        if(!$State.originalPresent -and (Test-Path -LiteralPath $Save)){throw 'Unexpected save in unstarted session.'}
    } else {
        # Presence + verified digest resolves crashes between a rename and journal.
        if($State.originalPresent -and !(Test-Path -LiteralPath $protected) -and (Test-Path -LiteralPath $Save) -and (Get-RkTreeDigest $Save) -ceq $State.originalDigest){
            if((Test-Path -LiteralPath $protected) -and (Get-RkTreeDigest $protected) -cne $State.originalDigest){throw 'Protected original changed; preserve evidence.'}
        } else {
            if($State.originalPresent){
                if(!(Test-Path -LiteralPath $snapshot) -or (Get-RkTreeDigest $snapshot) -cne $State.originalDigest){throw 'Independent snapshot is missing or corrupt.'}
                if((Test-Path -LiteralPath $protected) -and (Get-RkTreeDigest $protected) -cne $State.originalDigest){throw 'Protected original changed; do not overwrite it.'}
            }
            $State.phase='Restoring';Save-RkJournal $State
            if(Test-Path -LiteralPath $Save){
                if(Test-Path -LiteralPath $trial){throw 'Ambiguous trial archive; preserving both trees.'}
                Assert-RkTreeNoLinks $Save;Move-Item -LiteralPath $Save -Destination $trial
            }
            if($State.originalPresent){
                if(Test-Path -LiteralPath $protected){Move-Item -LiteralPath $protected -Destination $Save}
                else {
                    $stage=Join-Path $Root ('restore-stage-'+[guid]::NewGuid().ToString('N'))
                    Copy-Item -LiteralPath $snapshot -Destination $stage -Recurse -Force
                    if((Get-RkTreeDigest $stage) -cne $State.originalDigest){throw 'Recovery-stage verification failed.'}
                    Move-Item -LiteralPath $stage -Destination $Save
                }
            }
        }
    }
    if($State.originalPresent){if((Get-RkTreeDigest $Save) -cne $State.originalDigest){throw 'Restored original digest mismatch.'}}
    elseif(Test-Path -LiteralPath $Save){throw 'Originally absent saves were not restored to absence.'}
    $State.phase='Restored';Save-RkJournal $State
}
function Get-RkSteamCacheInventory([string]$SteamRoot) {
    # Read/hash only; never copy, delete or rewind Steam account-level caches.
    $userdata=Join-Path $SteamRoot 'userdata';Assert-RkNoLinks $userdata
    $rows=@();$permanent=$false;$appFiles=$false
    if(Test-Path -LiteralPath $userdata){
        foreach($account in Get-ChildItem -LiteralPath $userdata -Directory -Force){
            Assert-RkNoLinks $account.FullName
            $app=Join-Path $account.FullName '391540';Assert-RkNoLinks $app
            if(Test-Path -LiteralPath $app){
                Assert-RkTreeNoLinks $app
                if(Get-ChildItem -LiteralPath $app -Recurse -Force -File){$appFiles=$true}
                if(Get-ChildItem -LiteralPath $app -Recurse -Force -File | Where-Object Name -like 'system_information_*'){$permanent=$true}
                $rows+=@{account=$account.Name;digest=(Get-RkTreeDigest $app)}
            }
            $candidates=@(Get-ChildItem -LiteralPath $account.FullName -Directory -Force | Where-Object Name -like '*cloud*')
            $config=Join-Path $account.FullName 'config';Assert-RkNoLinks $config
            if(Test-Path -LiteralPath $config){$candidates+=@(Get-ChildItem -LiteralPath $config -Force | Where-Object Name -like '*cloud*')}
            foreach($candidate in $candidates){
                Assert-RkNoLinks $candidate.FullName
                $digest=if($candidate.PSIsContainer){Get-RkTreeDigest $candidate.FullName}else{(Get-FileHash -LiteralPath $candidate.FullName).Hash.ToLowerInvariant()}
                $rows+=@{account=($account.Name+':'+$candidate.FullName.Substring($account.FullName.Length));digest=$digest}
                if($candidate.PSIsContainer -and (Get-ChildItem -LiteralPath $candidate.FullName -Recurse -Force -File | Where-Object Name -like 'system_information_*')){$permanent=$true}
            }
        }
    }
    return @{apps=$rows;appCacheFilesPresent=$appFiles;permanentHistoryPresent=$permanent;coverage='APP391540_AND_NAMED_ACCOUNT_CLOUD_CACHES_ONLY; SDK/server/opaque metadata unknown'}
}
function Test-RkCacheEqual($Before,$After) {
    if($After.permanentHistoryPresent -or @($Before.apps).Count -ne @($After.apps).Count){return $false}
    foreach($app in $Before.apps){$match=@($After.apps | Where-Object account -CEQ $app.account);if($match.Count -ne 1 -or $match[0].digest -cne $app.digest){return $false}}
    return $true
}
function New-RkSideCopy([string]$Original,[string]$Destination,$Files,[string]$Candidate,[string]$Case) {
    if((Test-RkWithin $Destination $Original) -or (Test-RkWithin $Original $Destination)){throw 'Source/destination overlap refused.'}
    if(Test-Path -LiteralPath $Destination){throw 'Run copy already exists.'}
    $stage=$Destination+'.partial-'+[guid]::NewGuid().ToString('N')
    Assert-RkNoLinks $stage;Assert-RkNoLinks $Original
    New-Item -ItemType Directory -Path $stage | Out-Null
    try {
        foreach($file in $Files){
            Assert-RkRelative $file.path
            $source=Join-Path $Original $file.path;Assert-RkHash $source $file.original
            $target=Join-Path $stage $file.path
            New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination $target
            if($Case -eq 'patched' -and $file.path -ceq 'data.win'){Copy-Item -LiteralPath $Candidate -Destination $target -Force}
            Assert-RkHash $target $file.$Case
        }
        [IO.Directory]::Move($stage,$Destination)
    } catch {
        # Only this invocation's unpublished private stage; original/Steam paths
        # are never destinations, renamed or deleted by the side-copy protocol.
        if(Test-Path -LiteralPath $stage){Assert-RkTreeNoLinks $stage;Remove-Item -LiteralPath $stage -Recurse -Force}
        throw
    }
}

function Assert-RkSteamRegistration([string]$ClientRoot,[string]$GameInstall) {
    $common=Split-Path $GameInstall;$steamapps=Split-Path $common;$library=Split-Path $steamapps
    if([IO.Path]::GetFileName($common) -ine 'common' -or [IO.Path]::GetFileName($steamapps) -ine 'steamapps'){throw 'Unexpected Steam library layout.'}
    $manifest=Join-Path $steamapps 'appmanifest_391540.acf';Assert-RkNoLinks $manifest
    $text=Get-Content -LiteralPath $manifest -Raw -Encoding UTF8
    $ids=[regex]::Matches($text,'"appid"\s+"([^"\r\n]+)"');$dirs=[regex]::Matches($text,'"installdir"\s+"([^"\r\n]+)"')
    if($ids.Count -ne 1 -or $ids[0].Groups[1].Value -cne '391540' -or $dirs.Count -ne 1){throw 'Ambiguous app registration.'}
    $dir=$dirs[0].Groups[1].Value;Assert-RkRelative $dir
    if($dir.Contains('/') -or $dir.Contains('\') -or $dir -ine [IO.Path]::GetFileName($GameInstall)){throw 'App install directory mismatch.'}
    $roots=@([IO.Path]::GetFullPath($ClientRoot));$file=Join-Path $ClientRoot 'steamapps/libraryfolders.vdf';Assert-RkNoLinks $file
    if(Test-Path -LiteralPath $file){
        $vdf=Get-Content -LiteralPath $file -Raw -Encoding UTF8
        foreach($match in [regex]::Matches($vdf,'"path"\s+"([^"\r\n]+)"')){$roots+=[IO.Path]::GetFullPath($match.Groups[1].Value.Replace('\\','\'))}
    }
    if(!@($roots | Where-Object { $_.TrimEnd([IO.Path]::DirectorySeparatorChar).Equals($library.TrimEnd([IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase) }).Count){throw 'This Steam client has not registered the supplied library.'}
}

function Assert-RkOriginalSmoke([string]$Parent,$Metadata,[string]$Save) {
    # Operator observations are prerequisites, never automatic gameplay approval.
    $found=$false
    foreach($archive in Get-ChildItem -LiteralPath $Parent -Directory -Force | Where-Object Name -match '^completed-[a-f0-9]{32}$') {
        Assert-RkTreeNoLinks $archive.FullName
        $journal=Read-RkJournal $archive.FullName
        if($journal.case -ne 'original' -or $journal.phase -ne 'Restored' -or !$journal.cacheStable -or !$journal.registeredStable){continue}
        if($journal.runnerSha -cne $Metadata.runnerSha -or $journal.harnessSha -cne $Metadata.harnessSha -or $journal.steamSha -cne $Metadata.steamSha -or $journal.gameInstall -cne $Metadata.gameInstall -or $journal.registeredDigest -cne $Metadata.registeredDigest){continue}
        if(!(Test-RkCacheEqual $journal.cacheBefore $Metadata.cacheBefore)){continue}
        if([bool](Test-Path -LiteralPath $Save) -ne [bool]$journal.originalPresent){continue}
        if($journal.originalPresent -and (Get-RkTreeDigest $Save) -cne $journal.originalDigest){continue}
        $result=Get-Content -LiteralPath (Join-Path $archive.FullName 'result.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        if($result.result -eq 'BLOCKED' -or $result.localPhase -ne 'Restored'){continue}
        $observations=Get-Content -LiteralPath (Join-Path $archive.FullName 'observations.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        $valid=$true
        foreach($required in @('startup','english','keyboard','battle')){
            $entry=@($observations | Where-Object id -eq $required)
            if($entry.Count -ne 1 -or $entry[0].status -ne 'PASS' -or $entry[0].method -ne 'OPERATOR_REPORTED' -or [string]::IsNullOrWhiteSpace($entry[0].actual)){$valid=$false}
        }
        if($valid){$found=$true;break}
    }
    if(!$found){throw 'Patched comparison requires an archived, locally restored original smoke with explicit startup/English/keyboard/battle observations and identical harness/client/install/save/cache baselines.'}
}
