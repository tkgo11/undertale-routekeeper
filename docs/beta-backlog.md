# Human beta backlog

All tasks start **NOT_STARTED**. Automated contracts and source implementation
coverage do not complete these human tasks. Select the matching catalog scenario
and individual step in the Beta Tester; record PASS, FAIL, BLOCKED, NEEDS_REVIEW,
NOT_RUN or NOT_APPLICABLE with a concrete observation. Ordinary smoke consent
never authorizes a gameplay/high-risk task. Never delete personal history or cache
files to make a safety gate pass.

| ID | Priority | Catalog scenarios | Human task / acceptance |
|---|---|---|---|
| BETA-001 | P1 | `session-resume`, `session-corrupt`, `privacy-export`, `bug-report` | On unelevated Windows x64, verify first run, keyboard-only operation, high contrast, draft retention, explicit save/recovery, redaction, screenshot review and offline exports. No game needed. |
| BETA-002 | P1 | `supported-build`, `unsupported-build`, `patch-integrity`, `original-preservation` | Prepare a legitimate supported installation; compare original files before/after. Unknown builds, links and changed inputs must refuse without installation writes. Keep private diagnostics local. |
| BETA-003 | P1 | `patched-startup`, `clean-exit`, `crash`, `identity`, `watchdog`, `backup`, `interrupted-restore` | After harmless native checks and fresh consent, verify guarded human startup/stop, app interruption and exact recovery. Preserve originals, trial archives and unknown changes. A local restored receipt is never account-history restoration. |
| BETA-004 | P2 | `f10`, `english`, `korean`, `galmuri14`, `wrapping`, `cursor`, `focus`, `fullscreen`, `dpi`, `controller-input` | Inspect actual original/patched pixels, menu reopening, language selection, glyphs, wrapping, cursor/input/focus and display variations. Prior limited documented UI evidence does not complete new sessions. |
| BETA-005 | P2 | `language-persistence`, `mode-persistence`, `invalid-config`, `config-migration`, `off` | Verify current settings, restart persistence, legacy migration, defaults and invalid settings against expected source behavior. Record chosen and observed configuration separately. |
| BETA-006 | P1 | `movement`, `battle`, `act`, `fight`, `mercy`, `flee`, `inventory`, `warning-ack`, `warning-cancel`, `passive`, `active` | Execute supported human interactions and inspect warnings, acknowledgements, cancellation and return to normal gameplay. Human observations do not establish unseen internal state. |
| BETA-007 | P1 | `forced`, `unknown-state` | Exercise only source-supported protections under separate suitable scope; verify unsupported/unknown interventions refuse. Record supported cases independently. Forced is scoped and does not guarantee every ending. |
| BETA-008 | P2 | `neutral-0`…`neutral-18`, `call-goal-1`…`call-goal-8` | In separately authorized disposable progression, follow each grounded prerequisite and record the actual ending/call. The unresolved Neutral6/call-goal8 global combination stays UNKNOWN; a selector fixture is not a reachable playthrough. |
| BETA-009 | P2 | `route-pacifist`, `route-genocide`, `route-soulless-pacifist`, `route-soulless-genocide`, `epilogue-stay`, `epilogue-leave` | Verify prerequisites and ending observations independently. Existing permanent-history or unsupported-state gates may legitimately BLOCK execution; do not erase them or manufacture missing facts. |
| BETA-010 | P1 | `save-load`, `reset`, `true-reset`, `session-resume`, `unknown-files`, `links`, `locked-files` | Use separate scenario-specific high-risk consent for SAVE/RESET cases. Verify owned archive continuation, refusal of changed/unknown state and preservation across interruption. Never resume an old PID or rewind a newer personal baseline. |

## Issue classification and traceability

- **P0:** observed save loss, installation corruption or unintended irreversible
  account action. Stop the affected workflow and preserve all local copies.
- **P1:** safety/refusal/recovery failure or a major supported behavior failure.
- **P2:** bounded correctness, scenario, rendering, localization or report defect.
- **P3:** usability or documentation improvement with accepted behavior preserved.

Do not label an unverified report a confirmed defect. Record scenario/step,
configuration, exact app/game build, expected/actual behavior, reproduction,
severity, session/revision, issue ID/revision and reviewed evidence hashes. Keep
automated observations, human reports, synthetic fixtures and independent state
separate. Never include credentials, proprietary binaries, raw saves or unreviewed
pixels in a shared report. There is no automatic publication.

The follow-up workflow is:

`scenario/step → session/revision → issue/revision → reviewed evidence/hash →
reproducer → confirmed defect → focused fix PR/commit → regression → review → merge`.

Keep new fixes in focused PRs after the foundation is merged. A new candidate
receives new evidence; never overwrite an old failed run to make it pass. Human
playthroughs and a separately reviewed release checklist are required before any
claim of complete gameplay verification or a public release.
