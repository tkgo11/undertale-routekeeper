# Checkpoints contain only saves created during this disposable session; never
# import a host/personal save. These remain inside the VM, outside host mappings.
param([Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]{1,40}$')][string]$Name,[switch]$Restore)
$ErrorActionPreference='Stop'
# Historical implementation remains in Git history. Shared synthetic filesystem
# and current guarded native transaction/watchdog helpers remain maintained.
throw 'RETIRED_LEGACY_RUNTIME: registered-install swaps and environment-name-only isolation are prohibited. Use the guarded human/native workflow; no operation was performed.'
