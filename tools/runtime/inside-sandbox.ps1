# Official Steam launch only. All mutable game/save state stays inside the VM.
param([string]$Lab='C:\RoutekeeperInput',[string]$SteamRoot='C:\Program Files (x86)\Steam',
    [ValidateSet('original','patched')][string]$Case='original',[switch]$OfflineReady,
    [switch]$Interactive,[ValidateRange(1,240)][int]$Minutes=30)
$ErrorActionPreference='Stop'
# Historical implementation remains in Git history. Shared synthetic filesystem
# and current guarded native transaction/watchdog helpers remain maintained.
throw 'RETIRED_LEGACY_RUNTIME: registered-install swaps and environment-name-only isolation are prohibited. Use the guarded human/native workflow; no operation was performed.'
