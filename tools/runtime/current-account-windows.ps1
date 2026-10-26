# Windows-only observation gates. Never change networking or registered Steam files.
function Initialize-RkNativeChecks {
 if('RkNativeFiles' -as [type]){return}
 Add-Type @'
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public static class RkNativeFiles {
 [StructLayout(LayoutKind.Sequential)] public struct Info {
  public uint Attributes; public System.Runtime.InteropServices.ComTypes.FILETIME Creation,Access,Write;
  public uint Volume,SizeHigh,SizeLow,Links,IndexHigh,IndexLow;
 }
 [StructLayout(LayoutKind.Sequential)] public struct CaseInfo { public uint Flags; }
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
 public static extern SafeFileHandle CreateFile(string path,uint access,uint share,IntPtr security,uint creation,uint flags,IntPtr template);
 [DllImport("kernel32.dll",SetLastError=true)] public static extern bool GetFileInformationByHandle(SafeFileHandle h,out Info value);
 [DllImport("kernel32.dll",SetLastError=true)] public static extern bool GetFileInformationByHandleEx(SafeFileHandle h,int kind,out CaseInfo value,uint size);
}
'@
}
function Assert-RkMutablePath([string]$Path) {
 Assert-RkNoLinks $Path
 Initialize-RkNativeChecks
 $current=[IO.Path]::GetFullPath($Path)
 while($current){
  if(Test-Path -LiteralPath $current){
   $item=Get-Item -LiteralPath $current -Force
   $handle=[RkNativeFiles]::CreateFile($current,128,7,[IntPtr]::Zero,3,33554432,[IntPtr]::Zero)
   try {
    if($handle.IsInvalid){throw 'Cannot inspect mutable path with ordinary user permissions.'}
    if($item.PSIsContainer){
     $info=New-Object RkNativeFiles+CaseInfo
     if(![RkNativeFiles]::GetFileInformationByHandleEx($handle,23,[ref]$info,4)){throw 'Case-sensitivity inspection unavailable; mutable path refused.'}
     if($info.Flags -band 1){throw 'Case-sensitive mutable directories are unsupported.'}
    }else{
     $info=New-Object RkNativeFiles+Info
     if(![RkNativeFiles]::GetFileInformationByHandle($handle,[ref]$info) -or $info.Links -ne 1){throw 'Hard-linked or uninspectable mutable file refused.'}
     if(@(Get-Item -LiteralPath $current -Stream * -ErrorAction Stop | Where-Object Stream -ne ':$DATA').Count){throw 'Named streams cannot be independently snapshotted; refusing mutation.'}
    }
   } finally {$handle.Dispose()}
  }
  $current=[IO.Path]::GetDirectoryName($current)
 }
}
function Assert-RkNativeSaveTree([string]$Path){
 Assert-RkMutablePath $Path
 if(Test-Path -LiteralPath $Path){Assert-RkTreeNoLinks $Path;foreach($entry in Get-ChildItem -LiteralPath $Path -Recurse -Force){Assert-RkMutablePath $entry.FullName}}
}
function Assert-RkProcessesClosed {
 if(@(Get-Process steam,steamwebhelper,UNDERTALE -ErrorAction SilentlyContinue).Count){throw 'Exit Steam and UNDERTALE completely; no personal files are changed until both stop.'}
}
function Assert-RkNetworkOffline {
 if(@(Get-NetAdapter -IncludeHidden -ErrorAction Stop | Where-Object Status -eq 'Up').Count){throw 'Disconnect all adapters manually after Steam Go Offline. This tool never changes host networking.'}
}
function Assert-RkSteamClient([string]$Exe) {
 Assert-RkNoLinks $Exe
 if([IO.Path]::GetFileName($Exe) -ine 'steam.exe'){throw 'Expected the official Steam client executable.'}
 $signature=Get-AuthenticodeSignature -LiteralPath $Exe
 if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'CN=Valve (Corp\.?|Corporation)(,|$)'){throw 'Steam client publisher/signature could not be verified. Preflight it before disconnecting; do not bypass this gate.'}
}
function Initialize-RkPrivateRoot([string]$Path,[string]$Owner){
 Assert-RkMutablePath $Path
 if(!(Test-Path -LiteralPath $Path)){New-Item -ItemType Directory -Path $Path | Out-Null}
 $acl=Get-Acl -LiteralPath $Path
 if($acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne $Owner){throw 'Runtime workspace is not owned by the current user.'}
 $acl.SetAccessRuleProtection($true,$false)
 foreach($oldRule in @($acl.Access)){$acl.RemoveAccessRuleSpecific($oldRule)}
 foreach($sid in @($Owner,'S-1-5-18')){
  $rule=[Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.SecurityIdentifier]::new($sid),'FullControl','ContainerInherit,ObjectInherit','None','Allow')
  $acl.AddAccessRule($rule)
 }
 Set-Acl -LiteralPath $Path -AclObject $acl
}
