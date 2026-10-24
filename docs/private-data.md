# Private input handling and cleanup

The main repository is PRIVATE. Authorized input was retrieved from its draft
`dev-game-data` release using `gh release download`. No separate data repository
is used. Originals remain in ignored `private-data/`; private analysis and patched
outputs remain in ignored `.research/`. Neither path is a CI input or artifact.
LFS listed no tracked game data during initial inspection.

## Save safety

`RouteKeeper.Saves` inventories files by SHA-256 without writing them. It separates
`file0`, hidden-autosave `file9`, persistent Flowey encounter `file8`,
`undertale.ini`, and every
`system_information_*` file. It detects added, changed and removed permanent-history
files. The line parser preserves line-ending metadata but deliberately assigns no
unverified positional game-state meanings. It does not implement RESET/TRUE RESET
or modify saves. No personal save content should appear in reports.

Candidate save directories (must be confirmed on each supported installation):
Windows `%LOCALAPPDATA%/UNDERTALE`, macOS
`~/Library/Application Support/com.tobyfox.undertale`, Linux
`~/.config/UNDERTALE`. All three paths and the special persistence of `file8` are documented in
https://undertale.wiki/w/SAVE; Windows/macOS names are also corroborated by G3M's `src/models/game_modes.py`. Runtime path behavior remains unverified here.
G3M application storage helpers are not evidence for UNDERTALE's save directory.
Steam Cloud can restore removed files; inspect synchronization before any manual
save recovery. Permanent history is not ordinary progress.

## Cleanup procedure (explicit operator action)

1. Preserve any user-requested original backup outside the disposable workspace.
2. Delete local `private-data/`, `.research/` and `artifacts/` once inspection is
   finished; also delete temporary test directories that survive a failed test.
3. Inspect the main repository release asset list. To remove an authorized asset:
   `gh release delete-asset dev-game-data ASSET_NAME --repo tkgo11/undertale-routekeeper --yes`.
   This is a destructive command; it is not part of normal development or CI.
4. If LFS is used later, remove tracked proprietary paths, coordinate any required
   history rewrite with collaborators, and request provider-side LFS object removal.
   `git lfs prune` only cleans local cached objects.
5. Remove task workspace/cloud copies through the provider's task/environment
   controls, check ordinary Actions artifacts/releases for accidental exposure,
   and coordinate Steam Cloud cleanup separately if applicable.
6. Audit Git history, LFS, releases and CI artifacts before considering publication.

Deleting current files does not guarantee deletion from Git history, provider
backups, caches or retained snapshots. No deletion has been performed in this task.
