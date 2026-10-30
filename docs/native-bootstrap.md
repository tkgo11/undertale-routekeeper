# Private capture bootstrap and independent-observer boundary

`tools/native_bootstrap.py` processes **already acquired** original/patched private
captures. It never launches Steam/game, sends a key, changes saves or approves a
launch. Acquire captures only through an authorized session and the existing
capture helper. Its new `windowHandle` sidecar field records the actual checked
HWND. Older sidecars without HWND cannot be upgraded by guessing a value.

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
