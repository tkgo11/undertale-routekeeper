# SDK rollForward compatibility for global.json. Pure function; no processes launched.
# For latestPatch, .NET SDK must remain in the same major.minor.feature band.
function Test-RkSdkAllowed([string]$Actual,[string]$Pinned,[string]$RollForward) {
    if($Actual -cnotmatch '^[0-9]+\.[0-9]+\.[0-9]+$' -or $Pinned -cnotmatch '^[0-9]+\.[0-9]+\.[0-9]+$'){
        throw 'Malformed .NET SDK version or global.json SDK pin.'
    }
    try {
        $actualVersion=[version]::Parse($Actual)
        $pinnedVersion=[version]::Parse($Pinned)
    } catch {throw 'Invalid .NET SDK version or global.json SDK pin.'}
    if($RollForward -ceq 'disable'){return $actualVersion.Equals($pinnedVersion)}
    if($RollForward -cne 'latestPatch'){throw 'Unsupported global.json SDK rollForward policy.'}
    return ($actualVersion.Major -eq $pinnedVersion.Major -and
            $actualVersion.Minor -eq $pinnedVersion.Minor -and
            [math]::Floor($actualVersion.Build/100) -eq [math]::Floor($pinnedVersion.Build/100) -and
            $actualVersion.Build -ge $pinnedVersion.Build)
}
