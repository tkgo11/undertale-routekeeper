# Human-guided beta implementation readiness — 2026-11-04 UTC

Maintained source, data/binary provenance and component interactions were inspected
under independent scopes with root diff/inventory reconciliation and negative-path
checks. This bounded engineering audit is not native gameplay certification. Initial
development HEAD:
`e6cfaeb3281244961023ae19bd4af1e636395de1`. The commit containing this report identifies
its source snapshot; subsequent CI/review results must refer to that exact head.

The owner explicitly selected PUBLIC repository policy. GitHub already reported
public; the private draft input release remains private. Pinned `data.win` is an
ignored local compilation input, not a distributable. Public/fork authentic CI
remains disabled. Packages must exclude original/patched game assets, personal
saves and private runtime evidence. Packaging official compiler dependencies does
not authorize a public release.

## Requirement inventory

| Requirement | Current source/evidence | Remaining work or acceptance |
|---|---|---|
| Route engine and modes | Existing Core/Decisions/History reused; source-driven route/prerequisite catalog | Independent maintained-source scope reviews and affected regressions complete; preserve documented unsupported/UNKNOWN conditions |
| Native preparation | `human_beta.py` uses `runtime_lab.prepare_installed`, exact installed-file identities, shared Tool/compiler and a new sealed private workspace | Windows execution of authentic installed-copy preparation pending |
| Human launch/stop/recovery | `human-session.ps1`, `human-loop.ps1`, policy and existing native coordinator provide explicit Check/Prepare/Run/Recover/Cleanup; human loop dispatches no inputs | Windows protocol, process and filesystem fixtures PASS; genuine installed-game acceptance remains NOT_RUN |
| No developer installations | Pinned Python 3.12.10, Pillow 11.3.0, official CLI 0.9.2.0 plus corresponding source/notices bundled by `package_beta_dependencies.py`; synthetic packaging contracts and Linux construction evidence | Hosted physical interpreter/Pillow/compiler/Tool source closure and directory/ZIP checks PASS |
| Guided scenarios | Catalog v2: 82 scenarios, 434 steps; bilingual instructions; Core rules/objectives, Neutral 0..18, all 8 optional call goals, distinct Stay/Leave and RESET/TRUE RESET | Human execution remains NOT_STARTED/NOT_RUN unless recorded; target 6/goal 8 unresolved mapping stays UNKNOWN |
| Session contracts | Immutable revision chains, published head, exclusive writer, conflict/catalog/corruption refusal; bounded explicit interrupted-publication recovery | Recovery accepts only the exact verified unpublished next revision after review/consent; arbitrary repair/migration remains refused |
| Evidence | Bounded PNG validation/metadata stripping/review hashes, same-session duplicate refusal; process-only native receipts append separately | Windows capture/receipt integration acceptance pending; imported pixels never establish time/authenticity |
| Privacy | Local-only records, literal text redaction, reviewed-pixel opt-in, explicit deletion; native paths/backups stay private | Windows construction/redaction contracts PASS; interactive accessibility/DPI acceptance remains NOT_RUN |
| Issues and exports | Stable IDs/revisions, expected/actual/reproduction/severity; JSON/HTML/CSV; no automatic publishing | Automated redaction/report contracts PASS; explicit human sharing review remains required |
| Dashboard | Seven independent dimensions, per-session feature/build/language/configuration coverage | Cross-session coverage and comparable human result changes implemented; no whole-game certification inferred |
| Backup/watchdog | Existing journal/fence/identity/cache/network/guardian mechanisms reused by human session layer | Windows NTFS9 checks in each shell, Python guardian21 cases and PowerShell guardian12 checks per shell PASS; actual game recovery remains separate |
| Desktop/package | Ordinary-user bilingual WPF, per-monitor DPI, self-contained packaging and bounded dependency receipt | Hosted self-contained package/WPF construction PASS; interactive desktop and legitimate-game acceptance remain NOT_RUN |
| Audit/Qlty | Independent source scopes and concrete fixes reconciled with the exact inventory | Qlty aggregate92 is not issue-level clearance; details require unavailable login. No known unresolved P0/P1 remains in inspected source |
| GitHub gates | Latest read-only checks: main `protected=false`, repository rulesets `[]`; PR1 remains subject to exact-head CI/review checks | Fetch current checks after push; no required-review rules proven, and no blanket missing-approval blocker |

Implementation engineering gates passed for source9a105da in both push and PR CI.
The final follow-up commit must also pass its exact-head checks before
merge; current checks/reviews/protections are re-fetched immediately before merging.
Missing a human playthrough alone does not prevent completing a safe implementation.
Source presence, successful construction and process receipts do not substitute
for applicable automated Windows checks or independent engineering audit.
Interactive/native gameplay acceptance remains separately reported and must not
be fabricated from those checks. No extra merge
confirmation is needed if the user's already authorized conditions are all met.

Catalog implementation status describes completion of each declared source scope,
not a runtime verdict: 79 scenarios are COMPLETE; Forced, Neutral 6 and call-goal 8
remain PARTIAL for scoped enforcement or unresolved reachability. COMPLETE does not
promise every possible game interaction is covered. Automated gameplay stays
NOT_RUN, human results remain separately recorded, independent verification stays
NOT_RUN and compatibility stays InspectedOnly/UNKNOWN. Fixing prototype PARTIAL
metadata does not promote those evidence dimensions.

## Implemented safety and evidence contracts

The human session request binds the Beta session, scenario/step, original/patched
case, language/mode, selected Smoke/Gameplay/HighRisk scope, policy disclosure hash,
nonce and exact current app-process identity. Its explicit phrase expires after
five minutes. High-risk scenarios require their own additional scenario phrase.
Smoke permits at most 300 seconds and excludes gameplay; the overall cap is 7200
seconds including reserved safe-shutdown time. Human restrictions inside the
unmodified runner depend on the tester; the app cannot enforce every game action.

The coordinator retains mandatory native desktop, physical-network/offline,
Steam signature/registration/identity, registered-install/cache/history,
filesystem, save transaction and external watchdog checks. Unknown prerequisites
refuse. The human loop watches the parent/game/Steam identities, request hash,
network policy, deadline and unknown descendants. Stop and Pause/Break request the
existing guarded termination/restoration path. Reopening the checklist does not
resume a game. Optional continuation is a fresh explicitly consented Gameplay or
HighRisk launch using an earlier same-work/same-checklist trial archive. It requires
matching case/build/language/mode, completed restoration/fence, unchanged personal
baseline and sealed result/archive evidence. Prior HighRisk scope cannot be
downgraded. The archive is copied only after personal-save quarantine and rehashed;
no personal save import or automatic input replay occurs. Absent/changed evidence
refuses. Recovery targets an exact existing transaction; cleanup requires
verified restoration/fence and an unchanged owned copy. Unknown data is preserved.

Native summaries are bounded process/local-recovery observations:
`AutomatedObservation`, `PROCESS_ONLY_NOT_GAMEPLAY`, zero dispatched inputs and
`NOT_INDEPENDENTLY_VERIFIED` gameplay. They never promote human step results or
compatibility. A stop/exit event is not independent crash diagnosis. Optional
screenshots need separate capture consent and later pixel review; a guarded capture
refusal does not refocus the game or send input. The tester has a three-second
capture grace period to return focus manually; stop/emergency/network/identity
checks continue while pending. Screenshots stay UnverifiedClaim.
Steam startup or human actions may change achievements, permanent account history
or RemoteStorage queues. Verified local content restoration is not account/Cloud
restoration.

Portable session storage uses bounded immutable complete revisions and an atomic
published head with a cooperative writer lock. Exact hashes establish local
consistency, not hostile-editor authentication, power-loss proof or independent
truth. Bounded interrupted-publication recovery preserves the candidate/history
and requires matching reviewed hashes and explicit authorization. Missing,
changed-catalog or arbitrary corrupt history is not silently rolled back.

## Validation still to reconcile

Read [beta-tester.md](beta-tester.md) for current user flow and
[beta-dependencies.md](beta-dependencies.md) for pinned helper inputs, physical paths,
matching source/licenses, excluded optional game artwork and package construction.
A complete package needs its final dependency completion receipt, exact file hashes
and source/notices. No system Python, SDK, Visual Studio or compiler installation
is required for packaged operation. Building/rebuilding the package is a developer
task and has separate prerequisites.

WPF now exposes native preparation, disclosure/typed consent, bounded human launch,
stop, optional capture import/redaction, receipt import and explicit recovery/cleanup.
The Dashboard adds cross-session coverage and comparable human-result changes.
Optional Windows/display/DPI collection asks for consent; opaque pixel rectangles
operate on source coordinates and clear sharing review after changes. Use the exact
package and fresh CI results. Progress and test-results logs record test evidence
after integration stabilizes.
Linux construction and synthetic tests are never Windows native runtime evidence.
Historical native reports remain scoped historical evidence rather than new human
beta acceptance.

Interactive acceptance covers keyboard-only/Narrator, 100/125/150/200% DPI,
English/Korean switching, resize/scroll, interruption/resume, all-step aggregation,
publication recovery/corruption refusal, optional screenshot review/redaction,
redacted report exports and deletion on disposable records. Separately scoped
legitimate-game acceptance covers exact-copy preparation, original/patched start,
normal stop, emergency stop, watchdog/controller interruption, recovery refusal and
verified local restoration. Route/prerequisite/end-state tests require explicit
risk scope; UNKNOWN conditions remain UNKNOWN. Do not upload private evidence to CI.

## Defect and review traceability

Use `scenario/step → session/revision → issue/revision → evidence/hash → confirmed
reproducer → fix commit → regression command → candidate SHA`. Severity is
P0=data loss/irreversible hazard, P1=major correctness/safety, P2=bounded functional
defect, P3=usability/documentation. A human claim is not automatically a confirmed
source defect. Automated regression PASS is not authentic gameplay PASS.

Previously confirmed corrections remain traceable in the maintained tests/logs:
certificate filename/directory normalization, delayed Snowdin projection, private
fork job gating, interrupted restoration, stale summary/review reopening,
preparation source pins, Steam identity during native input, stabilization interval
ordering, published-head rollback refusal, exact screenshot review and PNG bounds
before WPF decode. Retain those regressions while completing new integration.

## Hosted fixture corrections

Candidate01c5f96 passed Linux CI. macOS ARM/Intel correctly rejected the
preview test's `/var` temporary-directory alias; the fixture now canonicalizes
only its own disposable path. Windows PowerShell5.1 uses different JSON spacing,
so the duplicate-field negative fixture had not actually mutated its input. Its
replacement now tolerates JSON whitespace and separately asserts that mutation
occurred. Production link and strict-JSON guards are unchanged. Corrected source9a105da passed all4 operating-system jobs in both push and PR CI.
The final follow-up head still receives its own checks before merging.

## Hosted package and beta handoff

Source `9a105dac3a72e1a9a25a8a9cc91765d1138d81e4` passed push run
[41813553745](https://github.com/tkgo11/undertale-routekeeper/actions/runs/41813553745)
and PR run
[41813978334](https://github.com/tkgo11/undertale-routekeeper/actions/runs/41813978334).
Each has4 successful OS jobs and1 intentionally skipped public authentic job.
Windows exercised PowerShell5.1/7, native disposable NTFS/guardian checks, actual
packaged Python/Pillow/compiler probes and the WPF construction/redaction/history
smoke. No Steam/game or private resources were used by those jobs.

The actual hosted Windows artifact was downloaded and independently checked against
GitHub's archive digest, then its inner ZIP was checked with the maintained package
verifier:1314files,139544188bytes, SHA256
`49aac2f8fe1c0275a18af397528dabe9bc721884fecbe6811ec74a0dad5b0c58`.
Artifact name: `routekeeper-beta-win-x64`; retention:7days. Select the final successful
head's artifact in Actions for handoff. These checks verify packaging and construction;
real interactive desktop/game acceptance remains NOT_RUN.

Use the [structured human backlog](beta-backlog.md) after handoff. Eight original
review threads were independently dispositioned with concrete tests/source and
resolved. No release or profile promotion is included.

The final human-protocol correction rejects root arrays before PowerShell can
enumerate them into an apparent object. Object requests/commands are unchanged.
Two new refusal regressions bring the portable protocol suite to54; independent
source review and21 E2E/source-pin checks pass. New exact-head Windows5.1/7 and
package results are required; preparation seals intentionally invalidate when
this executed helper changes.

The final recovery UI now enumerates retained native reference IDs independently
of checklist storage. Deleting a checklist no longer hides its native recovery
path: preparation can load its retained reference with no current checklist.
Recovery still uses the exact owned trial and shared coordinator; imports require
the matching surviving checklist. Corrupt references stay visible/refused, and
unknown/private files are preserved. Portable actual-reference regression and
independent source review pass; the Windows construction smoke additionally tests
checklist deletion, orphan selection/identity and refused import. Exact-head
Windows smoke must pass before merge.
