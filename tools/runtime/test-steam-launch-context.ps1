# Disposable filesystem proposal tests. No Steam, game, SDK, account or save use.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'test-workspace.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'steam-launch-context.ps1')
$workspace=New-RkTestWorkspace
$verified=$false;$count=0
function ContextCheck([bool]$Value,[string]$Name){if(!$Value){throw $Name};$script:count++;Write-Host ('OFFLINE_PASS '+$Name)}
function ContextRefuses([scriptblock]$Action,[string]$Name){$refused=$false;try{& $Action|Out-Null}catch{$refused=$true};ContextCheck $refused $Name}
$fixtureHashes=@{}
# Test-scope identity injection: exact pinned expected identities must be requested,
# and the independently hashed synthetic fixture bytes must remain unchanged.
# Production never accepts injected identity parameters or alternate runner pins.
function Assert-RkHash([string]$Path,[string]$Expected){
 Assert-RkNoLinks $Path
 $full=[IO.Path]::GetFullPath($Path)
 if(!$fixtureHashes.ContainsKey($full) -or $fixtureHashes[$full].expected -cne $Expected -or
  (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash -cne $fixtureHashes[$full].actual){throw 'Synthetic pinned identity mismatch'}
}
function ContextFixture([string]$Name,[string]$Case='original'){
 $work=Join-Path $workspace.root $Name;$install=Join-Path $workspace.root ($Name+'-registered')
 $pristine=Join-Path $work 'original/Undertale';$staged=Join-Path $work 'active-session/game'
 foreach($path in @($work,$install,$pristine,$staged)){[IO.Directory]::CreateDirectory($path)|Out-Null}
 foreach($path in @($install,$pristine,$staged)){
  foreach($file in @('UNDERTALE.exe','data.win','steam_api.dll')){
   $target=Join-Path $path $file;[IO.File]::WriteAllText($target,('SYNTHETIC ONLY '+$file))
   $expected=switch($file){
    'UNDERTALE.exe' {'c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'}
    'data.win' {if($path -ceq $staged -and $Case -eq 'patched'){'4457dbf421230c596df0d2c27754e8e94293c03c8e1106c6c1b07b9552f2c96c'}else{'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'}}
    'steam_api.dll' {(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()}
   }
   $fixtureHashes[[IO.Path]::GetFullPath($target)]=@{expected=$expected;actual=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash}
  }
 }
 return @{work=$work;install=$install;pristine=$pristine;staged=$staged;metadata=(Join-Path $staged 'steam_appid.txt');case=$Case}
}
try{
 foreach($case in @('original','patched')){
  $f=ContextFixture $case $case
  $beforeOriginal=Get-RkTreeDigest $f.pristine;$beforeRegistered=Get-RkTreeDigest $f.install
  $context=New-RkSteamLaunchContext $f.work $f.install $case
  ContextCheck ($context.appId -ceq '391540' -and $context.runtime -ceq 'NOT_RUN' -and [IO.File]::ReadAllText($f.metadata) -ceq '391540') ($case+' creates exact own-AppID metadata only')
  $checked=Assert-RkSteamLaunchContext $f.work $f.install $case
  ContextCheck ($checked.metadataSha256 -ceq $context.metadataSha256) ($case+' independently rechecks metadata and pinned files')
  ContextRefuses {New-RkSteamLaunchContext $f.work $f.install $case} ($case+' create-new refuses even identical existing metadata')
  ContextCheck ((Get-RkTreeDigest $f.pristine) -ceq $beforeOriginal -and (Get-RkTreeDigest $f.install) -ceq $beforeRegistered) ($case+' pristine and registered trees unchanged')
 }
 foreach($bad in @('480','391540 ' ,"391540`n",'',"$([char]0xfeff)391540")){
  $f=ContextFixture ('bad-'+[guid]::NewGuid().ToString('N'))
  [IO.File]::WriteAllText($f.metadata,$bad,[Text.UTF8Encoding]::new($false))
  ContextRefuses {Assert-RkSteamLaunchContext $f.work $f.install 'original'} 'wrong/malformed AppID refused'
  ContextRefuses {New-RkSteamLaunchContext $f.work $f.install 'original'} 'existing differing metadata never overwritten'
  ContextCheck ([IO.File]::ReadAllText($f.metadata,[Text.UTF8Encoding]::new($false)) -ceq $bad.TrimStart([char]0xfeff)) 'existing file content preserved'
 }
 $f=ContextFixture 'missing';ContextRefuses {Assert-RkSteamLaunchContext $f.work $f.install 'original'} 'missing metadata cannot certify launch context'
 foreach($target in @('UNDERTALE.exe','data.win','steam_api.dll')){
  $f=ContextFixture ('tamper-'+$target);$null=New-RkSteamLaunchContext $f.work $f.install 'original'
  [IO.File]::AppendAllText((Join-Path $f.staged $target),'TAMPER')
  ContextRefuses {Assert-RkSteamLaunchContext $f.work $f.install 'original'} ('changed staged identity refused: '+$target)
 }
 $f=ContextFixture 'wrong-case';ContextRefuses {New-RkSteamLaunchContext $f.work $f.install 'patched'} 'original data cannot be certified as patched'
 ContextCheck (!(Test-Path -LiteralPath $f.metadata)) 'wrong-case refusal creates no launch metadata'
 $f=ContextFixture 'bad-before-create';[IO.File]::AppendAllText((Join-Path $f.staged 'UNDERTALE.exe'),'TAMPER')
 ContextRefuses {New-RkSteamLaunchContext $f.work $f.install 'original'} 'runner identity fails before creating context'
 ContextCheck (!(Test-Path -LiteralPath $f.metadata)) 'bad-runner refusal creates no launch metadata'
 $f=ContextFixture 'overlap';ContextRefuses {New-RkSteamLaunchContext $f.work $f.staged 'original'} 'registered/staged overlap refused'
 $f=ContextFixture 'hardlink';$alias=Join-Path $f.work 'appid-alias';[IO.File]::WriteAllText($alias,'391540');New-Item -ItemType HardLink -Path $f.metadata -Target $alias|Out-Null
 ContextRefuses {Assert-RkSteamLaunchContext $f.work $f.install 'original'} 'hardlinked metadata refused'
 [IO.File]::Delete($f.metadata);[IO.File]::Delete($alias)
 Complete-RkTestWorkspace $workspace;$verified=$true
 Write-Host ('OFFLINE_PASS launch-context proposal checks: '+$count+'; no Steam/game/SDK calls')
}finally{if($verified){Remove-RkTestWorkspace $workspace}else{Write-Warning ('Failed synthetic workspace retained: '+$workspace.root)}}
