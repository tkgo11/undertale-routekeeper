# Native non-game validation. Never starts Steam/UNDERTALE or accesses real saves.
function Test-RkNativeDesktop([string]$Output) {
 if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Native Windows desktop required.'}
 $allowed=Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) 'RoutekeeperE2E'
 if(!(Test-RkWithin $Output $allowed)){throw 'Native test output must be in the private LocalAppData/RoutekeeperE2E namespace.'}
 Assert-RkNoLinks $Output
 if(Test-Path -LiteralPath $Output){throw 'Self-test output must be new.'}
 New-Item -ItemType Directory -Path $Output | Out-Null
 Assert-RkNativeSaveTree $Output
 $owner=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
 Initialize-RkPrivateRoot $Output $owner
 # Ordinary-user NTFS negative probes, only in the owned private directory.
 $file=Join-Path $Output 'native-file.txt';[IO.File]::WriteAllText($file,'SYNTHETIC ONLY')
 $alias=Join-Path $Output 'native-hardlink.txt'
 New-Item -ItemType HardLink -Path $alias -Target $file | Out-Null
 $refused=$false;try{Assert-RkNativeSaveTree $alias}catch{if($_.Exception.Message -like '*Hard-linked*'){$refused=$true}else{throw}}
 if(!$refused){throw 'Native hardlink guard did not reject a two-link file.'}
 [IO.File]::Delete($alias)
 Set-Content -LiteralPath $file -Stream 'rk_probe' -Value 'SYNTHETIC STREAM'
 $refused=$false;try{Assert-RkNativeSaveTree $file}catch{if($_.Exception.Message -like '*Named streams*'){$refused=$true}else{throw}}
 if(!$refused){throw 'Native alternate-stream guard did not reject its fixture.'}
 Remove-Item -LiteralPath $file -Stream 'rk_probe'
 $target=Join-Path $Output 'junction-target';New-Item -ItemType Directory -Path $target|Out-Null
 $junction=Join-Path $Output 'junction-alias';New-Item -ItemType Junction -Path $junction -Target $target|Out-Null
 $refused=$false;try{Assert-RkNativeSaveTree $junction}catch{if($_.Exception.Message -like '*Linked*'){$refused=$true}else{throw}}
 if(!$refused){throw 'Native reparse-point guard did not reject its junction.'}
 [IO.Directory]::Delete($junction)
 Assert-RkNativeSaveTree $Output
 Add-Type -AssemblyName System.Windows.Forms,System.Drawing
 Initialize-RkWindowInput
 Initialize-RkCapture
 $null=[RoutekeeperCapture]::SetProcessDPIAware()
 $process=Get-Process -Id $PID
 $exe=$process.Path;$hash=(Get-FileHash -LiteralPath $exe).Hash.ToLowerInvariant();$ticks=$process.StartTime.ToUniversalTime().Ticks
 $form=New-Object Windows.Forms.Form
 $form.AutoScaleMode=[Windows.Forms.AutoScaleMode]::None
 $form.Text='ROUTEKEEPER harmless API self-test';$form.ClientSize=New-Object Drawing.Size(640,480);$form.BackColor=[Drawing.Color]::Black;$form.KeyPreview=$true
 $observed=New-Object 'Collections.Generic.List[string]'
 $form.Add_KeyDown({param($sender,$event)$observed.Add('down:'+([int]$event.KeyCode))}.GetNewClosure())
 $form.Add_KeyUp({param($sender,$event)$observed.Add('up:'+([int]$event.KeyCode))}.GetNewClosure())
 $form.Add_Paint({param($sender,$event)$event.Graphics.FillRectangle([Drawing.Brushes]::White,32,32,576,6)} )
 try {
  $form.Show();$form.Activate();[Windows.Forms.Application]::DoEvents()
  $deadline=[DateTime]::UtcNow.AddSeconds(5)
  while([RkWindowInput]::GetForegroundWindow() -ne $form.Handle -and [DateTime]::UtcNow -lt $deadline){[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 20}
  $abort=Join-Path $Output 'abort.request'
  $null=Send-RkWindowKey $process $form.Handle $exe $hash $ticks 'down' 50 $abort
  [Windows.Forms.Application]::DoEvents()
  if(!$observed.Contains('down:40') -or !$observed.Contains('up:40')){throw 'Harmless target did not observe matching key-down/up.'}
  Save-RkWindowCapture $process $exe (Join-Path $Output 'window.png') $hash $form.Handle
  $other=New-Object Windows.Forms.Form
  try {
   $other.Text='ROUTEKEEPER focus-loss fixture';$other.Show();$other.Activate();[Windows.Forms.Application]::DoEvents()
   $deadline=[DateTime]::UtcNow.AddSeconds(3)
   while([RkWindowInput]::GetForegroundWindow() -ne $other.Handle -and [DateTime]::UtcNow -lt $deadline){[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 20}
   if([RkWindowInput]::GetForegroundWindow() -ne $other.Handle){throw 'Cannot establish owned focus-loss fixture; native test blocked.'}
   $refused=$false
   try{Send-RkWindowKey $process $form.Handle $exe $hash $ticks 'down' 50 $abort|Out-Null}catch{if($_.Exception.Message -like '*Focus/window owner changed*'){$refused=$true}else{throw}}
   if(!$refused){throw 'Native pre-dispatch focus guard failed.'}
  }finally{$other.Close();$other.Dispose()}
  [IO.File]::WriteAllText($abort,'OWNED TEST ABORT')
  $refused=$false
  try{Send-RkWindowKey $process $form.Handle $exe $hash $ticks 'down' 50 $abort|Out-Null}catch{if($_.Exception.Message -like '*Emergency abort requested*'){$refused=$true}else{throw}}
  if(!$refused){throw 'Native abort-file guard failed.'}
  [IO.File]::Delete($abort)
  # Test synthetic local transaction/recovery using existing shared functions.
  $save=Join-Path $Output 'synthetic-save';New-Item -ItemType Directory -Path $save | Out-Null
  [IO.File]::WriteAllText((Join-Path $save 'file0'),'SYNTHETIC ONLY')
  $owner=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
  $state=New-RkSaveTransaction (Join-Path $Output 'transaction') $save $owner 'original'
  Start-RkSaveTransaction $state
  Restore-RkSaveTransaction $state $state.root $save $owner
  if($state.phase -ne 'Restored'){throw 'Synthetic native recovery did not complete.'}
  $receipt=@{schema=1;kind='NATIVE_NON_GAME_SELFTEST';keyEvents=@($observed);localSyntheticRecovery='VERIFIED';capture='window.png';nativeGameplay='NOT_RUN';filesystemChecks=@('hardlink-refused','stream-refused','junction-refused');focusLossBlocked=$true;abortFileBlocked=$true;processMemoryIdentity='UNPROVEN';sourceSha=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'native-selftest.ps1')).Hash.ToLowerInvariant();inputSha=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'input-window.ps1')).Hash.ToLowerInvariant();captureSha=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'capture-client.ps1')).Hash.ToLowerInvariant()}
  Write-RkAtomicJson (Join-Path $Output 'receipt.json') $receipt
  return $receipt
 } finally {$form.Close();$form.Dispose()}
}
