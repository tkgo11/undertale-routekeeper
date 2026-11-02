# Source-only coordinator expressions and journal identity; no game/Steam/UI.
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'safety.ps1')
. (Join-Path $PSScriptRoot 'current-account-state.ps1')
. (Join-Path $PSScriptRoot 'experimental-session.ps1')
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'experimental-session.ps1'),[ref]$tokens,[ref]$errors)
if($errors){throw 'Coordinator AST invalid'}
$session=$ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Invoke-RkGameSession'},$true)
$normalization=@($session.FindAll({param($node) $node -is [Management.Automation.Language.IfStatementAst] -and $node.Extent.Text -ceq 'if(![string]::IsNullOrWhiteSpace($Baseline)){$Baseline=Get-RkCanonicalExecutionPath $Baseline}'},$true))
if($normalization.Count -ne 1){throw 'Missing unique production baseline normalization'}
$checks=0
function Check([bool]$Value,[string]$Name){if(!$Value){throw $Name};$script:checks++;Write-Host ('PASS '+$Name)}
$repo=Split-Path (Split-Path $PSScriptRoot)
Push-Location -LiteralPath $repo
try {
 $relative='.research/session-path-fixture-'+[guid]::NewGuid().ToString('N')
 $expected=Get-RkCanonicalExecutionPath $relative
 $save=Join-Path $repo ('.research/independent-save-'+[guid]::NewGuid().ToString('N'))
 $state=[pscustomobject]@{schema=2;owner='SYNTHETIC';id=[guid]::NewGuid().ToString('N');savePath=$save;root=$expected;phase='Restored';originalPresent=$false;originalDigest='';case='original'}
 foreach($variant in @($relative,$expected.Replace('\','/'),$expected)){
  $Baseline=$variant
  Invoke-Expression $normalization[0].Extent.Text
  Check ($Baseline -ceq $expected) 'relative, slash absolute and native baseline normalize identically'
  Assert-RkJournal $state $Baseline $save 'SYNTHETIC'
  Check $true 'canonical baseline passes exact journal location identity'
 }
 $Baseline='';Invoke-Expression $normalization[0].Extent.Text
 Check ($Baseline -ceq '') 'empty baseline remains empty rather than authorizing current directory'
 $refused=$false;try{Assert-RkJournal $state ($expected+'-different') $save 'SYNTHETIC'}catch{$refused=$true}
 Check $refused 'different baseline directory still fails journal location gate'
 $state.phase='UNKNOWN';$refused=$false;try{Assert-RkJournal $state $expected $save 'SYNTHETIC'}catch{$refused=$true}
 Check $refused 'unknown journal phase still refuses'
 $firstRead=$session.Find({param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -ceq 'Read-RkJournal'},$true)
 Check ($normalization[0].Extent.EndOffset -lt $firstRead.Extent.StartOffset) 'normalization precedes baseline journal access'
 $diagnostics=@($session.FindAll({param($node) $node -is [Management.Automation.Language.ThrowStatementAst] -and ($node.Extent.Text -like '*runner exited/redirected*' -or $node.Extent.Text -like '*owned window/focus did not stabilize*')},$true))
 Check ($diagnostics.Count -eq 2) 'two owned launch/window failure diagnostics located'
 foreach($Case in @('original','patched')){
  foreach($diagnostic in $diagnostics){
   $message='';try{Invoke-Expression $diagnostic.Extent.Text}catch{$message=$_.Exception.Message}
   Check ($message.StartsWith($Case+' ')) 'failure diagnostic names the actual original or patched case'
  }
 }
} finally {Pop-Location}
Write-Host ('SESSION_PATHS '+$checks+' PASS; no process launch or filesystem mutation')
