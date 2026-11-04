# Independent read-only file0 snapshot observer

`tools/save_observer.py` observes explicitly selected **disposable private file0
snapshots** below this repository's ignored `.research/` or `private-evidence/`.
It has no write, launch, process-memory or personal-save access feature. Never
copy a person's existing save into this namespace merely to use it as a fixture.

The mapping was independently checked against the legitimate exact original
`data.win` through the official UndertaleModCli. Three decompiled source hashes
are pinned in the observer; original GML stays private. `scr_load` and
`scr_levelup` also match the existing independent golden source hashes.
`scr_saveprocess` has SHA256
`ee143c6ef7113b6c481ea9380204d6a1c771901140cfcc3bcad1c59f4225993f`.
This does not repeat ROUTEKEEPER's own decision or state-read outputs.

| Saved fact | Zero-based line index |
|---|---|
| LV | 1 |
| Maximum HP capacity | 2 |
| EXP | 9 |
| Kill count | 11 |
| Saved flag i, i=0..511 | 30+i |
| Plot | 542 |
| Room | 547 |
| Saved time | 548 |

The exact layout has549 lines: a name,11 initial real fields,8 interleaved
item/phone pairs, weapon/armor,512 flags, plot,3 menu values, song/room/time.
The name and inventory are validated structurally but never emitted. The observer
checks all numeric fields, exact layout, expected snapshot digest, normal LV/EXP
threshold consistency and limited supported numeric domains. Unsupported/inconsistent
snapshots refuse rather than being silently normalized. Strict normal-progression
consistency may also refuse unusual legitimate snapshots; it does not prove they
were forged. A plausible fabricated snapshot with a freshly forged expected digest
is **not detectable** by this offline format observer. Snapshot authenticity and
live-state correspondence therefore remain UNVERIFIED even after success.

Current HP is not serialized in file0. Original `scr_load` sets HP=maxHP after
loading; this is a source fact, not an observation of live HP. Loading also resets
flags94 and360..364. Flag512 is outside this512-element saved block. Saved plot,
flag, LV and kill values must never be substituted for independent live effects,
enemy HP, an active encounter, route reachability or ending completion. No Forced
no-side-effect certification is provided. Gameplay, live state, routes and endings
remain UNVERIFIED/BLOCKED without additional observers and authorized execution.

Export the three named original code entries into a NEW private directory:

```powershell
.research/utmt-windows/UndertaleModCli.exe dump private-data/data.win -o .research/observer-source-new -c gml_Script_scr_load -c gml_Script_scr_saveprocess -c gml_Script_scr_levelup
python tools/save_observer.py --snapshot .research/DISPOSABLE/file0 --expected-sha256 SNAPSHOT_DIGEST_FROM_INDEPENDENT_RECEIPT --original private-data/data.win --sources .research/observer-source-new/CodeEntries
python tools/test_save_observer.py
```

The observer reports SAVED_STATE_OBSERVED for the bounded offline scope; never
PASS for authentic game behavior. Expected hashes must come from the separately
retained snapshot receipt. Do not compute a new expected hash after an unexpected
change just to make the check pass. Caller-supplied original/source files must be
the pinned legitimate versions; exported source hashes are checked on every call.
Tests use synthetic file0 fixtures and explicitly mocked source gates where noted;
they do not turn synthetic saves into authentic game evidence.
