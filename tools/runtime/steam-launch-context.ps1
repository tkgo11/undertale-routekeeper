# Scoped support for Valve's documented direct/development launch context.
# Never launches Steam/game, initializes an SDK, asserts a license, or edits either
# the pristine archive tree or registered install. This is not execution consent.
# https://partner.steamgames.com/doc/api/steam_api#SteamAPI_RestartAppIfNecessary
function Get-RkSteamLaunchContextIdentity([string]$Work,[string]$GameInstall,
 [ValidateSet('original','patched')][string]$Case,
 [ValidateSet('active-session','original-baseline')][string]$SessionName='active-session') {
 if($SessionName -eq 'original-baseline' -and $Case -ne 'original'){throw 'Launch context case differs from its staging namespace.'}
 $workPath=[IO.Path]::GetFullPath($Work)
 $registered=[IO.Path]::GetFullPath($GameInstall)
 $pristine=Join-Path $workPath 'original/Undertale'
 $staged=Join-Path (Join-Path $workPath $SessionName) 'game'
 foreach($path in @($workPath,$registered,$pristine,$staged)){
  Assert-RkMutablePath $path
  if(!(Test-Path -LiteralPath $path -PathType Container)){throw 'Launch context requires existing verified directories.'}
 }
 foreach($pair in @(@($staged,$pristine),@($staged,$registered),@($pristine,$registered))){
  if((Test-RkWithin $pair[0] $pair[1]) -or (Test-RkWithin $pair[1] $pair[0])){throw 'Staged/pristine/registered launch paths overlap.'}
 }
 $runnerHash='c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
 $originalHash='b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'
 $candidateHash='4457dbf421230c596df0d2c27754e8e94293c03c8e1106c6c1b07b9552f2c96c'
 $dataHash=if($Case -eq 'original'){$originalHash}else{$candidateHash}
 foreach($path in @($pristine,$registered,$staged)){
  foreach($file in @('UNDERTALE.exe','data.win','steam_api.dll')){Assert-RkMutablePath (Join-Path $path $file)}
  Assert-RkHash (Join-Path $path 'UNDERTALE.exe') $runnerHash
  $expectedData=if($path -ceq $staged){$dataHash}else{$originalHash}
  Assert-RkHash (Join-Path $path 'data.win') $expectedData
 }
 $originalDll=Join-Path $pristine 'steam_api.dll'
 if(!(Test-Path -LiteralPath $originalDll -PathType Leaf)){throw 'Verified original Steam API DLL is required.'}
 $dllHash=(Get-FileHash -LiteralPath $originalDll -Algorithm SHA256).Hash.ToLowerInvariant()
 foreach($path in @($registered,$staged)){Assert-RkHash (Join-Path $path 'steam_api.dll') $dllHash}
 $metadata=Join-Path $staged 'steam_appid.txt'
 Assert-RkMutablePath $metadata
 return @{schema=1;kind='VALVE_DOCUMENTED_DIRECT_LAUNCH_CONTEXT';appId='391540';case=$Case;sessionName=$SessionName;
  stagedGame=$staged;pristineGame=$pristine;registeredGame=$registered;metadataPath=$metadata;
  runnerSha256=$runnerHash;dataSha256=$dataHash;steamApiSha256=$dllHash;
  license='NOT_ASSERTED_REQUIRES_OWNED_STEAM_LICENSE';runtime='NOT_RUN';accountIsolation='UNPROVEN'}
}
function Assert-RkSteamLaunchContext([string]$Work,[string]$GameInstall,
 [ValidateSet('original','patched')][string]$Case,
 [ValidateSet('active-session','original-baseline')][string]$SessionName='active-session') {
 $identity=Get-RkSteamLaunchContextIdentity $Work $GameInstall $Case $SessionName
 $metadata=$identity.metadataPath
 if(!(Test-Path -LiteralPath $metadata -PathType Leaf)){throw 'Exact staged Steam AppID metadata is missing.'}
 $bytes=[IO.File]::ReadAllBytes($metadata)
 $expected=[Text.Encoding]::ASCII.GetBytes('391540')
 if($bytes.Length -ne $expected.Length -or [Convert]::ToBase64String($bytes) -cne [Convert]::ToBase64String($expected)){
  throw 'Staged Steam AppID metadata must be exactly ASCII 391540; no other ID, BOM or whitespace is permitted.'
 }
 $identity.metadataSha256=(Get-FileHash -LiteralPath $metadata -Algorithm SHA256).Hash.ToLowerInvariant()
 return $identity
}
function New-RkSteamLaunchContext([string]$Work,[string]$GameInstall,
 [ValidateSet('original','patched')][string]$Case,
 [ValidateSet('active-session','original-baseline')][string]$SessionName='active-session') {
 $identity=Get-RkSteamLaunchContextIdentity $Work $GameInstall $Case $SessionName
 $metadata=$identity.metadataPath
 # An existing correct file can be independently Assert-ed but is never replaced
 # or silently adopted by creation. Differing/unknown metadata remains untouched.
 if(Test-Path -LiteralPath $metadata){throw 'Steam launch metadata already exists; creation never overwrites it.'}
 $bytes=[Text.Encoding]::ASCII.GetBytes('391540')
 $stream=[IO.File]::Open($metadata,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$stream.Write($bytes,0,$bytes.Length);$stream.Flush($true)}finally{$stream.Dispose()}
 return (Assert-RkSteamLaunchContext $Work $GameInstall $Case $SessionName)
}
