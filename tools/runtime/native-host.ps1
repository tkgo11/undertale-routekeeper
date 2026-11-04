# Shared native host gate; importing this file never launches a process.
function Assert-RkNativeHost {
 if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Native Windows required; Linux/compatibility results do not approve execution.'}
 if([Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() -cne 'X64'){throw 'Native x64 Windows host required; ARM/emulation is unsupported.'}
 if($PSVersionTable.PSVersion.Major -notin @(5,7)){throw 'PowerShell5.1 or7 required.'}
 if(![Environment]::Is64BitProcess -or [Environment]::OSVersion.Version.Major -lt 10){throw '64-bit PowerShell on Windows10+ required. The official game runner remains x86.'}
 $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
 if(([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Use an unelevated current account.'}
 $local=[Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
 $homeDir=[Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
 if($env:LOCALAPPDATA -cne $local -or $env:USERPROFILE -cne $homeDir){throw 'Profile redirection is unsupported.'}
}
