# Deterministic screens and deferred scoped review

This tool consumes existing PNGs. It never launches a process, dispatches input,
contacts a server, touches saves, or changes compatibility approval. Windows capture,
physical input, native drawing and gameplay are **NOT_RUN**. Same-account Steam
startup remains **NO-GO**; see [steam-safety.md](steam-safety.md). The new capture
helpers do not authorize using any retained launcher.

## Run the real offline workflow

Python3.12+ and the project's pinned Pillow11.3.0 are the only dependencies:

```sh
python -m pip install Pillow==11.3.0
python tools/test_screen_verify.py
# New ignored directory; never reuse an existing output:
python tools/screen_verify.py demo --output private-evidence/demo
python tools/screen_verify.py review-list --run private-evidence/demo/run
python tools/screen_verify.py report --run private-evidence/demo/run --output private-evidence/demo/review.html
python tools/screen_verify.py review-export --run private-evidence/demo/run --output private-evidence/demo/packet --confirm-private-images
python tools/screen_verify.py summary --run private-evidence/demo/run
```

These commands were exercised with owned synthetic pixels and the licensed Korean
preview font. Demo produces a single magenta-pixel discrepancy, a passing synthetic
file-integrity assertion and an explicitly unobservable native-font assertion.
The visual discrepancy needs judgment. The missing gameplay/font observer remains
unverified even if a reviewer accepts the visible rendering. A reviewer label in
this demonstration is synthetic test provenance, not an actual native image review.

`review-list` groups by scenario/reason and prints stable `reviewId` values. Record
an actual scoped decision using that ID (substitute the ID printed for your run):

```sh
python tools/screen_verify.py review --run private-evidence/demo/run --case REVIEW_ID --decision accepted --reviewer-type human --reviewer local-reviewer --request-id review-1
# A subsequent differing decision requires explicit acknowledgment of its predecessor:
python tools/screen_verify.py review --run private-evidence/demo/run --case REVIEW_ID --decision uncertain --reviewer-type ai --reviewer selected-model --request-id review-2 --supersedes review-1
```

Decision choices: `accepted`, `defect`, `uncertain`, `invalid`, `recapture`.
Human/AI provenance is declared locally, not authenticated/signed. There is no API
key or background inference. An AI's response must be deliberately recorded by an
operator and may concern only visual scope. No machine-readable AI response is
automatically trusted. Re-evaluate improved/recaptured evidence as a **new run**;
never modify prior files to make a review apply. A repeated identical request ID
is idempotent; inconsistent reuse or unacknowledged replacement refuses. Decisions
are new immutable numbered files with previous-record and summary hashes. Stale
writer locks, torn records, changed evidence and unexpected files fail closed.

Commands returning0 mean processing succeeded, **not** scenario PASS. Read the
JSON `result`, `scenarios`, individual `result`/`automaticResult`, and scope.
`verify --require-pass` returns1 if the aggregate is not PASS (2 for invalid input).
HTML embeds images and escaped JSON; no server, JavaScript, CDN, remote font or
network is needed. Create reports outside the sealed run tree, to a new filename.

## Components and verdict contracts

`tools/screen_verify.py` exposes independently tested functions for bounded/no-follow
IO, deterministic checks, capture-record validation, normalization, comparison,
structural features, temporal stabilization, aggregation, run sealing, append-only
review, export and reporting. Windows-specific acquisition remains in
`tools/runtime/capture-client.ps1`; the historical capture-game wrapper delegates
rather than maintaining duplicate interop. Scenario contracts live in
`tools/runtime/screen-contracts.json`; the existing eight smoke entries reference
its version and IDs. No existing gameplay rule, UI pixel, font, hook, profile or
native GML generated output changes.

| Verdict | Meaning |
|---|---|
| PASS | Entire *declared assertion scope* positively established, or explicit scoped visual acceptance with automatic verdict retained |
| FAIL | Deterministic contradiction, or a scoped review confirms a visual defect |
| NEEDS_REVIEW | Usable observations with insufficient interpretation, unsupported observer/method, uncertain image or unknown gameplay state |
| BLOCKED | Mandatory infrastructure/safety requirement prevents certification |
| NOT_RUN | Required assertion was not supplied/attempted |
| INVALID_EVIDENCE | Corrupt/missing/hash-mismatched/unsafe/incomplete evidence or invalid contract |

Aggregation priority: any FAIL (including optional diagnostics), then mandatory
INVALID_EVIDENCE, BLOCKED, NEEDS_REVIEW, NOT_RUN, otherwise PASS. An empty scope is
NOT_RUN. Optional invalid/unattempted diagnostics are visible individually but do
not satisfy mandatory scope. A confirmed failure is never erased by similarity
or review. Visual reviews affect only `scope=visual`, retain `automaticResult`,
and cannot override invalid/blocked/failed/unattempted evidence. Nonvisual rows
never accept screenshot approval. Native imports always include a mandatory
same-account safety BLOCKED assertion; no JSON/operator flag removes it.

`file-sha256` streams files up to1GiB with bounded reads and handle revalidation;
it checks actual bytes against the declared pin. This establishes file
identity, not ownership, trusted provenance of a supplied pin, loaded process-memory
identity, source correctness, or installability. `configuration` checks a hashed
JSON observation's typed top-level value; it does not prove that the game applied
that value. Other observer kinds remain NEEDS_REVIEW: self-reported game flags,
input-dispatch receipts, screenshots and successful process launches cannot prove
HP/EXP/inventory, executed actions, event order, or permanent-history preservation.
No independent internal-state observer or input-dispatch adapter is implemented.

## Input manifest

The working `demo` writes a complete `input.json`; use it as an executable schema
example. Required top-level fields are `schema:1`, `kind:synthetic|native-import`,
`runId` (portable token), and1..256 assertions with unique portable IDs and one of
the eight registered scenario IDs. All referenced files are relative to the
manifest directory. All image/capture/config observations require SHA256 pins.
Optional `identities` accepts only sourceSha256/candidateSha256/runnerSha256/
generatedSha256. The private manifest may also carry original input receipts and
observation notes; they are not independent evidence and are not exported.

Visual rows contain `id`, `scenario`, `kind:visual`, `actual`, `actualSha256`,
`reference:{file,sha256,provenance}`, and `method`. Reference provenance requires
source, generatorVersion, sourceHashes, locale, font, scene and kind. Kinds are
synthetic, proxy, private-authentic and independently-reviewed. These declarations
are locally trusted provenance, **not cryptographic authenticity**. A mistaken
reference remains a credible source of false positives; pair it with independent
structural constraints. A mismatch never silently substitutes another reference.
Missing metadata yields INVALID_EVIDENCE, not fallback success.

Each scenario has mandatory named assertions. Omitting them creates explicit
NOT_RUN rows; renaming a visual row to impersonate a required gameplay assertion,
changing its kind or marking it optional refuses. Contracts intentionally keep
unobservable gameplay explicit; they are not evidence that a complete scenario can
currently pass. Settings persistence can establish file values, not account isolation.
A title frame cannot prove Steam history preservation. A Forced warning cannot
prove pre-effect attack refusal or unchanged combat state.

## Normalization and methods

Original bytes are preserved separately from normalized images. Only opaque,
single-frame PNG is supported, maximum16MiB/16,777,216pixels. All decoding and image
limits are checked; corrupt, animated, transparent/partial, unsupported and oversized
files refuse. Logical UI is320x240. Supported client scales are integers1..8;
every block must match its nearest-neighbor reconstruction. Noninteger scaling,
wrong aspect ratio, antialiased/resampled blocks or unsupported dimensions are
INVALID_EVIDENCE. Nothing is stretched to improve a score.

Letterboxing requires explicit `geometry:{content:[left,top,right,bottom],
cropVerified:true}`. Every excluded pixel must be black. The original capture and
rectangle are retained; black pixels alone do not *independently prove* a correct
crop. No automatic cropping, occlusion removal or ignored-region inference occurs.

- **exact:** per-channel equality inside optional `regions` rectangles, minus
  explicitly reasoned `ignore:[{rect,reason}]` rectangles. Counts changed logical
  pixels, ratio, changed bounding box, mean absolute channel difference; writes a
  magenta changed-pixel overlay. Empty masks and out-of-bounds regions refuse.
- **structure:** explicit `solid` RGB rectangular runs (borders/background) and
  an8x6 red-heart mask including holes. Pixel contracts, not generalized recognition.
  `features` declare ID/kind/rect/color; only those features are claimed. It cannot
  diagnose why a glyph region differs or recognize arbitrary game screens.
- **bounded-difference:** bounded masked pixel metrics, not a calibrated probability
  or a global confidence score. `policy` supplies version, maxRatio, optional
  channelTolerance, calibration filename and calibrationSha256. Calibration must
  match scenario/version and contain2..16 `samples` with file/sha256/classification
  positive|negative. Actual pinned fixture images are decoded and measured with
  the same reference/mask/tolerance; max positive must be<=threshold<min negative.
  Both classifications are required. This proves fixture separation only; it does
  not prove all real capture distributions. No perceptual/neural dependency added.
- **temporal:**2..64 pinned frames with strictly increasing elapsedMs, timeoutMs
  1..60000 and stableFrames2..32. Final consecutive in-bound frames must equal the
  reference; later instability or late capture prevents PASS. Every original frame
  is retained. Native frame sequences require each capture sidecar/hash as well.
  No fixed sleeps, automatic input dispatch or scheduler equivalence is inferred.

Mismatch, wrong cursor, suspected missing glyph, clipping, obstruction, changed
locale, unknown method or instability becomes NEEDS_REVIEW. These tools do not
label a changed white patch a missing character with unjustified certainty.
A real PNG/font contract can prove exact visible pixels/declared geometry; font
coverage and source metrics alone cannot prove every native rendering property.

## Reference generation and font boundary

```sh
python tools/screen_verify.py reference --locale ko --scene menu --selection 2 --output private-evidence/ko-menu
python tools/screen_verify.py reference --locale en --scene languages --selection 0 --output private-evidence/en-languages
python tools/screen_verify.py reference --locale ko --scene warning --output private-evidence/ko-warning
python tools/screen_verify.py reference --locale ko --scene hud --output private-evidence/ko-hud
```

These reuse `integration/ui/preview.py`, generated translations, registered licensed
font assets and original320x240 layout. Reference metadata includes source hashes,
font identity, scene parameters, glyph runs, used codepoints and line-height.
Run `python tools/localization.py validate` and `python integration/ui/test_ui.py`
for coverage/layout and run independent structural contracts for selected regions.
These shared-source expectations can share bugs with generated game UI.

English previews use a licensed **proxy** for original fnt_maintext outlines.
They are never automatic authoritative native English pixel PASS, even if equal.
Actual original font outlines/game art must remain private. Existing private font
export tooling may supply authentic evidence after its own source verification;
provide an explicitly provenance-tagged private reference. Independently reviewed
captures also need exact build/locale/font provenance. This tool does not silently
upgrade either a proxy or a manually tagged reference to independently proven truth.

## Windows integration without a new launcher

Existing capture requires a previously authorized valid session; it cannot start
Steam/game or bypass NO-GO. The helper pins the supplied official runner hash,
selects exactly one process at its expected path, checks window ownership/PID,
foreground before/after, stable client geometry/origin, process start identity and
DPI before/after. It writes an explicit PNG and adjacent `IMAGE.png.json` with
hash/timing/geometry/owner observations, but omits titles, absolute paths and desktop
origin. New files are exclusive, images/JSON flushed, and published without replacing
old evidence. Interruption between PNG and sidecar moves is detectable incomplete
evidence, not proof of NTFS power-loss atomicity. Windows execution remains NOT_RUN.
The Linux test compiles interop and parses PowerShell only; it calls no user32 API.

CopyFromScreen can still capture overlays/unrelated desktop pixels. Focus checks do
not prove no intervening races, unobstructed z-order, independent executable memory,
or guaranteed window-only privacy. Every native CopyFromScreen observation initially
needs review; it never passes based only on metadata. Missing/invalid ownership,
focus, DPI, timing, sidecar hashes or geometry yields INVALID_EVIDENCE.

Future approved runner consumes this interface without redesign: capture through
Save-RkClientCapture, append explicit input-dispatch receipts separately, bind each
frame and sidecar hash, then invoke the offline engine. **Do not run the game now.**
For already-existing private frames, these Windows PowerShell commands launch only
Python; they are not permission for new capture/game execution:

```powershell
python tools/screen_verify.py prepare-import --capture private-evidence/existing.png --reference private-evidence/ko-menu --scenario korean --output private-evidence/imported
python tools/screen_verify.py verify --manifest private-evidence/imported/input.json --output private-evidence/import-run
python tools/screen_verify.py report --run private-evidence/import-run --output private-evidence/import-report.html
```

No account, VM, administrator, Steam authentication or additional installed game
component is needed for the offline engine. Do not change Cloud settings or clean
Steam caches. None of these commands certify local/remote account-history safety.

## Private storage, export and recovery

New run directories contain summary.json plus summary.sha256, manifest-private.json,
review/ID/{submitted-actual.bin,actual.png,normalized.png,expected.png,diff.png,
comparison.png,metadata.json}, optional capture-private.json/frame files, and
append-only decisions/*.json. Invalid cases may have only bounded rejected bytes
and metadata: absence of expected/decoded imagery is itself INVALID_EVIDENCE.
Summary seals the manifest and every evidence file, including metadata. New run
publication uses a private staging directory and rename; output reuse refuses.
A128MiB/4096-new-file write budget bounds a run, each JSON is<=1MiB and frame/assertion
counts are bounded. References/exports also stage and refuse replacement. Private
POSIX directories/files request0700/0600; Windows ACL inheritance is not independently
proven by these mode bits. Use an appropriate private local directory/ACL.

Portable paths reject traversal, reserved Windows names, unsupported characters,
links, ancestor links, reparse points, hardlinked files and special nodes. File
reads use O_NOFOLLOW where available, bounded consumption and handle stat checks.
These are best-effort defenses, **not hostile parent-directory TOCTOU elimination**,
a sandbox or authenticated storage. A local attacker who can rewrite the entire
run and all seals can forge provenance. Real NTFS crash/power-loss consistency,
Win32 semantics/PS5.1 and cross-platform capture remain NOT_RUN.

Run reading rechecks hashes and the exact evidence file set. Modified evidence,
extra files, duplicate JSON keys, review-chain gaps or stale lock refuse. Do not
repair by overwriting hashes/decisions. Preserve the directory; reverify original
inputs into a new run. Interrupted unpublished stages can be inspected and removed
only from task-owned private directories. Never delete saves or Steam files.
No provider backups/history deletion guarantee is made.

Exports require explicit `--confirm-private-images`. They contain reencoded
pixels (PNG ancillary metadata removed), allowlisted scenario/assertion IDs,
objective metrics, limited reference kind/locale/font/scene, build hashes and a
narrow AI question. They exclude manifest notes, executable paths, PIDs, window
titles, reviewer names, save content and opaque binary/sidecar files. **Pixels are
not automatically redacted**; review them locally before choosing any external
recipient. `review-export` writes locally and performs no upload. AI judgment is
visual evidence, never authority to change route logic, protections or profiles.

## Actual verification and limitations

44 synthetic tests exercise equality,1-pixel differences, cursor/glyph/layout/
background/locale/obstruction cases, exact/masked/calibrated/structural/temporal
methods, proxy English, missing references/frames, scale/aspect/bars/blur, corrupt/
truncated/transparent/oversized/fake-type images, metadata/focus/identity/timing,
path traversal/ancestor links/hardlinks, duplicate IDs/JSON, write budgets, stale
locks, immutable output, modified sealed evidence, repeated/conflicting decisions,
visual approval with deterministic FAIL/unknown gameplay, full CLI/import/demo,
private HTML and sanitized local packet. The full demo produces NEEDS_REVIEW even
after visual acceptance. Test fixtures use owned geometry/registered OFL fonts;
no original game art or private screenshots are committed.

No native Windows screenshot, original/patched runner, actual English/Korean
rendering, physical input, Steam, GameMaker scheduler or gameplay was exercised.
NO-GO and InspectedOnly are unchanged. This infrastructure is useful now for
synthetic/preexisting evidence; it is not release or runtime compatibility approval.
