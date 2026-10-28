# Same-account Steam startup safety

## Current E2E hardening continuation

See [e2e-hardening.md](e2e-hardening.md) for the corrected Work/report resolver,
optimization-independent prerequisites, native UI contract adapter and explicit
scenario/evidence matrix. Owner-authorized policy v2 extends implementation beyond
the earlier original-only probe; default legacy Run stays NO-GO. Cloud started no
Steam/game. Native Windows and real gameplay verification remain NOT_RUN; combat,
Forced and endings remain blocked without independent observers/authentication and
appropriate safe starting states. Historical original-only descriptions below are
superseded implementation boundaries, never evidence of native success.


Reviewed 2026-10-27 (KST). **NO-GO for default Run and account-safety approval.**
No Steam client, UNDERTALE executable or compatibility-layer game was started.

## Separately authorized experimental boundary

The current owner explicitly accepts account-history risk for a distinct opt-in
experiment. [windows-e2e.md](windows-e2e.md) documents the new test-windows entry
point: native non-game validation, exact preparation, hard cache/history/path/
identity gates, fresh disclosure consent and independent local backups precede an
original-only startup probe. It sends no gameplay input into an unrecognized scene
and never advances to patched execution without a real original baseline. Default
run-current-account Run remains code-disabled. Risk consent is not account isolation
or safety approval. No game/Steam was executed in Cloud; all native behavior is NOT_RUN.
Existing SDK/history analysis below remains valid. No history/cache deletion or
Cloud setting changes are authorized by this policy.

## Direct source and API evidence

The exact b718f822 input's `gml_Script_SCR_GAMESTART` first checks
`steam_initialised()`. If Steam reports system_information_962 or963, it writes
corresponding LOCAL history. With963 present it also removes local962 and, if the
Steam962 existence query succeeds, requests `steam_file_delete` for962.
This occurs during startup, before player SAVE/RESET or an ending. The original
block is preserved by the patch; disabling or faking it would invalidate a test.

Valve's [ISteamRemoteStorage](https://partner.steamgames.com/doc/api/ISteamRemoteStorage)
documentation states:

- FileDelete deletes from local storage and propagates deletion to Cloud.
- FileExists checks existence; it is not a promise that no pending/local account
  metadata exists outside a caller's manually observed cache inventory.
- FileForget removes remote storage but leaves API-accessible local data. It is
  destructive and is NOT an isolation solution.
- IsCloudEnabledForAccount and IsCloudEnabledForApp query synchronization settings.
  Neither is documented as a read-only filesystem sandbox.
- SetCloudEnabledForApp changes the user's setting and must only follow their
  explicit request. ROUTEKEEPER never calls it.

The [Steam Cloud overview](https://partner.steamgames.com/doc/features/cloud)
describes before/after session synchronization, separate API/Auto-Cloud mechanisms,
and per-user isolation. It does not offer an application-side throwaway namespace
for the SAME app and SAME user or guaranteed rollback of SDK deletion queues.
No supported interface establishing that guarantee was found. This is absence of
a proven solution, not a claim that every conceivable isolation mechanism is
mathematically impossible.

The exact GameMaker-to-Steam wrapper/client/cache behavior for this runner and
steam_api.dll remains a native-platform unknown. Mapping a GameMaker call to the
documented Steam operation is corroborating evidence, not a trace of an executed
SDK call. Offline Mode and disabled Cloud must not be upgraded into proof that
FileExists is false or deletion cannot persist locally for later synchronization.

## Enforced policy

`tools/runtime/run-current-account.ps1 -Action Run` now ALWAYS refuses before
loading helpers, checking OS/profile, opening files, staging/quarantining saves or
starting any process. AcceptSteamAccountRisk, CloudDisabledAndOffline, original/
patched choice and RestartForSettings cannot override this gate.
Reopening it requires a reviewed source change with new evidence, not a JSON flag,
environment variable or operator attestation.

Preflight remains read-only with respect to game/save/cache content. Recover,
Archive and Cleanup remain available ONLY for valid preexisting sessions, retaining
all original identity/network/process/integrity guards. Do not delete a cache or
permanent file to obtain a pass. Local content restoration is not account rollback.
Legacy Sandbox/dedicated-user launchers are historical, unvalidated alternatives;
they must not be used as a workaround for this NO-GO or during this task.

## Minimal operator actions allowed now

From an ordinary Windows account at the repository root:

```powershell
# No game/Steam process is started by these scripts:
powershell.exe -NoProfile -File tools/runtime/test-current-account.ps1
pwsh -NoProfile -File tools/runtime/test-current-account.ps1
pwsh -NoProfile -File tools/runtime/test-sandbox.ps1
# Prints the read-only readiness explanation; optional genuine paths are in
# runtime-validation.md. This is NOT a launch or account-isolation approval.
powershell.exe -NoProfile -File tools/runtime/run-current-account.ps1 -Action Preflight
```

These are synthetic helper/AST/interop tests. They do not exercise every Win32
case-info/ACL/hardlink/ADS gate. Native non-game filesystem API validation in
disposable directories remains required. Do not use personal save folders as
fixtures. No new account, Sandbox, VM or elevation is required for these checks.

For an existing interrupted session, keep Cloud/network off, close Steam and the
game manually and follow the exact Recover instructions in runtime-validation.md.
Never guess paths from a damaged journal. Refusal means preserve evidence; it is
not permission to clear files or force restoration. If no session exists, no
recovery operation is needed.

## Smallest evidence that could support reconsideration

All of the following are needed; none is supplied by offline tests:

1. A legitimate, documented mechanism or independently verifiable proof that this
   exact official runner/SDK/client cannot read or change the same account's
   permanent history, local RemoteStorage state or deferred deletion/upload queue
   during the proposed session AND subsequent reconnect. Local cache sampling and
   setting checkboxes alone do not suffice.
2. Native Windows PS5.1/7 and ordinary-user API/filesystem results: links/reparse/
   hardlinks/streams/case/ACL handling, immutable snapshots, failed/partial staging,
   interruption/recovery fences and process identity, using disposable data.
3. A reviewed restriction to non-destructive original-first scenarios and honest
   operator expected/actual evidence. This cannot turn native startup into full
   ending compatibility, a VerifiedPatch promotion or release approval.

If1 cannot be established under the user's constraints, keep NO-GO. Do not replace
Steam APIs, change app identity, modify original history handling, ask credentials,
clear personal state, require a VM or manufacture a safe result.

The2026-10-27 offline follow-up tightens runtime-lab file-set/extraction verification
and source-builder paths only. It establishes no Steam/account isolation and does
not reopen Run or authorize any operator action. See offline-audit-2026-10-27.md.
