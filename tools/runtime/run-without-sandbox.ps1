# Native Windows verification without Windows Sandbox.
# Requires a distinct, non-administrator RKTestOriginal/RKTestPatched local Windows account.
# Does not touch the primary user's Steam/game/save directories or Windows network settings.
param(
    [Parameter(Mandatory=$true)][string]$Lab,
    [Parameter(Mandatory=$true)][string]$PatchedData,
    [Parameter(Mandatory=$true)][ValidateSet('original','patched')][string]$Case,
    [switch]$AttestSeparateWindowsAccount,
    [switch]$AttestSteamOfflineAndCloudDisabled,
    [ValidateRange(1,240)][int]$Minutes=60
)
$ErrorActionPreference='Stop'
# Historical implementation remains in Git history. Shared synthetic filesystem
# and current guarded native transaction/watchdog helpers remain maintained.
throw 'RETIRED_LEGACY_RUNTIME: registered-install swaps and environment-name-only isolation are prohibited. Use the guarded human/native workflow; no operation was performed.'
