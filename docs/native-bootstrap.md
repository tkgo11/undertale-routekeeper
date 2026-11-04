# Private capture bootstrap and independent-observer boundary

`tools/native_bootstrap.py` processes **already acquired** original/patched private
captures. It never launches Steam/game, sends a key, changes saves or approves a
launch. Acquire captures only through an authorized session and the existing
capture helper. Its new `windowHandle` sidecar field records the actual checked
HWND. Older sidecars without HWND cannot be upgraded by guessing a value.

The current native adapter uses foreground `SendInput` scan codes for every
whitelisted key. Direction keys use extended scan codes; confirm/cancel/Enter/
settings/language/acknowledgement use nonextended scan codes. The previous
directions-only/HWND-message split is historical. PID/start/path/hash,
HWND/foreground, Steam identity and emergency
guards apply before down and throughout the bounded hold; already held direction
keys are refused. After an accepted OS down, matching OS key-up always runs in
cleanup, including after focus/process loss. That release affects global OS key
state and can reach the new foreground; it is not HWND-targeted. No additional
down is sent after guard failure. Receipts distinguish this transport and keep
`gameAction=UNPROVEN`; only observed game response can establish acceptance.

An intake recipe contains `schema:1`, `id`, `version`, `case`, a `captures` object
mapping scene identifiers to relative PNG paths, `sourceProvenance` and
`startingState` operator accounts, `actionHistory`, and `steps` in
the existing native-plan format. Each `actionHistory` entry has `before`, `after`,
`action`, `holdMs`, `startedUtc`, `finishedUtc`, and
`source=operator-observation` or `native-dispatch-record`; these must agree with
the corresponding proposed step and fall between its before/after captures.
Keep the complete observed trace, dispatch receipts and operator observations in
that private recipe, including additional fields when available.
These are retained operator claims, not proof that GameMaker accepted input.
Include starting-state requirements and scene meanings in the recipe for review.
No-input `checkpoint` steps may wait up to 60000ms for an observed transition,
such as the original intro reaching the title. Input steps remain limited to
15000ms, and the native controller's 300s global budget remains unchanged.
The original build has no Korean/mod settings scenarios. SAVE, RESET, combat,
Forced and endings remain unsupported. The native validator still owns final
exported plan acceptance and refuses unsupported actions/limits.

```powershell
python tools/native_bootstrap.py intake --recipe PRIVATE/recipe.json --data PRIVATE/data.win --output .research/bootstrap-new
python tools/native_bootstrap.py review --root .research/bootstrap-new --reviewer HUMAN --request-id review1 --decision accepted --provenance-checked --non-destructive-actions-checked
python tools/native_bootstrap.py export --root .research/bootstrap-new --request-id review1 --output .research/contracts-new
python tools/native_gameplay.py validate --plan .research/contracts-new/native-plan.json --case original
```

`PRIVATE` represents actual operator-selected private paths, never bundled sample
gameplay assets. No authentic captures or reviews are supplied by this repository.
Outputs are restricted below ignored `.research/` or `private-evidence/`.
Intake checks the actual data file against the exact supported profile, capture
hashes, native dimensions, runner/PID/start/HWND consistency, timestamps and action
bounds. It retains raw PNGs without scaling and freezes every sidecar, recipe and
proposal hash. A pending proposal deliberately fails native plan validation.

Review is an explicit accountable **human claim** after examining the pixels,
source session, starting state, action meanings and history. Both provenance and
safe-action confirmation are required before export. Review records and exports
are new files, never overwritten. Export rechecks all frozen bytes and binds the
chosen review hash. These local hashes detect accidental or unreviewed changes;
they are not signatures, remote attestation, overlay isolation or proof against a
malicious editor forging the entire bundle. Scene labels alone authenticate
nothing. Even accepted/exported references leave gameplay and loaded bytecode
UNVERIFIED and the original baseline NOT_RUN. Native execution gates still apply.

When the owner explicitly delegates review authority, `review` also accepts
`--delegated-agent-review --delegation-statement "EXACT OWNER STATEMENT"` with
the actual agent name in `--reviewer`. The exact bounded statement is retained;
the record says `reviewerType=agent`, `method=AGENT_DELEGATED`, and exports say
`OWNER_DELEGATED_AGENT_LOCAL_CLAIM`. This is documentary delegated authority,
not a human review or independent authentication. The reviewer must still inspect
the actual pixels, provenance, starting state and each proposed action/history,
then explicitly confirm provenance and non-destructive actions. Metadata passing
intake never supplies these judgments. Human review remains the default; a
delegation statement without the explicit agent flag is refused. Review/export
immutability, exact evidence hashes, native plan validation and all execution
gates remain unchanged. Delegated review cannot certify combat or endings.

## Read-only state observations

The existing `native_gameplay.py settings` observer independently reads the mod INI
file; it does not observe applied settings, HP, LV, EXP, enemy HP, encounter state,
kills or progression flags. Disk `data.win` identity does not prove the bytecode
loaded by a running process. The separate [file0 snapshot observer](save-observer.md)
now reads source-backed saved LV/EXP/kills/flags/maxHP from an explicitly selected
disposable snapshot. These are saved values, not live observations. Current HP
is not serialized, and no source-backed live-memory layout is verified.
A guessed offset or ROUTEKEEPER's own decision output would not be independent
evidence. Those live assertions remain UNVERIFIED; combat, Forced
side effects, route transitions and endings remain BLOCKED. A safe future observer
needs exact-build source provenance, a verified read-only mapping, coherent live
sampling and tests rejecting stale/falsified/inconsistent observations.

`python tools/test_native_bootstrap.py` uses disposable synthetic images/data under
`.research/windows-20261029-bootstrap/`. Its tests exercise refusal, immutable
review/export and native pixel preservation. They never establish authentic game
provenance, real Windows capture, gameplay, ownership or account restoration.

## Reviewed live acquisition baseline

`python tools/native_acquisition.py inspect --root PRIVATE_SESSION` validates the
complete stopped original acquisition, every capture-bound request and dispatch,
process/window provenance, watchdog natural exit and local recovery evidence.
A separately written post-pixel review and exported authentic bootstrap plan are
required by `certify --root PRIVATE_SESSION --review PRIVATE_REVIEW --plan
PRIVATE_PLAN --bootstrap PRIVATE_BOOTSTRAP`. Certification creates a new immutable
`live-baseline-review.json`; it does not edit the runtime receipt or claim that the
exported plan was replayed. The certificate records AGENT_DELEGATED authority and
only the observed startup, English UI and both movement directions. Marker-pixel
position, unchanged background and later input-free captures corroborate the
explicit movement review; a dispatched key or arbitrary image difference cannot
certify movement. Internal game state and Steam account isolation remain unproven.

The patched launch gate recomputes the entire chain and review/export linkage on
every check. The original and patched preparation must have identical current
harness pins, including the validator and bootstrap dependency. Historical runtime
pins are never rewritten; changed code requires a fresh original acquisition.
The existing static-plan replay path remains separate and retains its checks.
