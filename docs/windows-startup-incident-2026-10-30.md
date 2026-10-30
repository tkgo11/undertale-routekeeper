# Original Windows startup incident, 2026-10-30 KST

The original side-copy runner really started. An unexpected descendant caused
the external guardian to stop that exact process before a verified window or
capture was obtained. Later Steam logs recorded `steam://run/391540` and a launch
of the registered original installation. No game keys were sent by the harness.
Neither startup rendering nor navigation was verified; patched execution did
not run. Private process identities, logs and reports remain ignored locally.

The runner contains `SteamAPI_RestartAppIfNecessary`. The observed redirect is
consistent with its documented behavior, but no SDK call trace was collected.
[Valve's API reference](https://partner.steamgames.com/doc/api/steam_api#SteamAPI_RestartAppIfNecessary)
explains that a direct launch can relaunch the registered library executable;
waiting for a Steam process alone cannot establish a valid side-copy context.

Two independent coordinator defects made this failure worse: guardian closure
threw before owned-Steam shutdown, and successful report generation made a failed
probe return exit code zero. Stop stages must be independent, preserve every
failure and still attempt identity-checked normal shutdown of the owned client.
Any failed boundary continues to forbid automatic save recovery. Failed probe
completion must return nonzero after preserving its report; a completed startup
capture is only NEEDS_REVIEW, never a gameplay PASS.

## Recovery boundary

The two independent original-save trees matched the journal; the personal save
destination was absent. Automatic restoration remained refused because of the
guardian intervention. The owner separately authorized manual original-copy
recovery, requiring disconnected physical links, stopped Steam/game processes,
matching backup digests and an absent destination. That recovery uses a verified
new staging tree and a non-overwriting same-volume rename, retains the two
backups and original failure journals, and records a separate manual receipt.
Approval or a copied backup alone does not certify restoration. The final
destination must independently match the original digest. Steam account state
is never restored or inferred from local content recovery.

No new test may start while this recovery is unresolved. Choosing a different
Work directory does not resolve a quarantined personal save or authorize a retry.

## Scoped direct-copy launch context

Valve documents exact-app `steam_appid.txt` metadata for direct/development
testing. The helper accepts only the real UNDERTALE AppID `391540`,
exactly six ASCII bytes, in a disposable staged game copy. It pins the original
runner/data or patched data, compares the untouched original Steam API DLL,
rejects overlapping pristine/registered/staged paths and never replaces existing
metadata. It changes no registered installation, DLL, authentication or ownership
implementation. A legitimate same-user Steam session and an owned license are
still required; metadata does not assert a license or prove successful loading.

The coordinator creates and checks this context before save quarantine, and
checks it again immediately before launch. Policy v3 discloses this scope and
requires fresh runtime consent before execution. Its filesystem tests cannot certify native
Steam launch, prevent every redirect or establish account isolation. Unknown
descendants remain preserved and continue to block recovery. No guard may be
removed merely to allow the game to launch.

Diagnostic child output is routed to the operator transcript rather than the
structured probe return stream. Otherwise child JSON could turn a successful
probe into a mixed output array and incorrectly fail completion classification.
The completion regression exercises noisy diagnostics with a structured fixture;
it does not certify game rendering or input acceptance.
