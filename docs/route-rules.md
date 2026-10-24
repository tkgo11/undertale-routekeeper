# Route rules and evidence

Status: partial research-backed model, not complete ending coverage. Research checked
2026-10-24 using `curl -L https://undertale.wiki/w/True_Pacifist_Route` and
`curl -L https://undertale.wiki/w/Genocide_Route`; both returned article HTML in
this session. Python urllib requests were denied (403). Article text is an
external reference, not proof that a particular native variable or hook works.
See `compatibility.md` for binary evidence and integration limits.

## Implemented normalized conditions

[True Pacifist Route — Requirements](https://undertale.wiki/w/True_Pacifist_Route#Requirements)
identifies no EXP, the Papyrus and Undyne friendships, giving Undyne water,
prior defeat of Omega Flowey, the letter/Alphys date, and the True Lab. The
engine models these as observations; unobserved facts stay UNKNOWN. Existing
EXP, dead Papyrus/Undyne, or leaving collapsed Undyne without water invalidate
the *current state*, not every possible reload/reset. The engine does not
recommend or execute RESET and never rewrites save files.

`prior_neutral_completion` is an adapter contract for the persistent prerequisite
(the article specifically describes defeating Asgore/Omega Flowey). It must not
mean merely seeing any credits. The prior run need not itself be pacifist; the
current run must preserve its own requirements. Letter availability additionally
depends on current-run progress including Mettaton EX; a friendship flag alone
cannot prove availability.

`ObjectivePlanner` therefore gates hangout/date/lab actions on explicit verified
availability observations. Dependencies prevent Undyne before Papyrus, Alphys
before the required friendships and prior completion, and the True Lab before
Alphys. Unknown availability suppresses an action. This is a conservative planner;
it does not yet plan all travel, inventory, battle, or phone-call prerequisites.

[Genocide Route — Requirements](https://undertale.wiki/w/Genocide_Route#Requirements)
lists quotas of 20 Ruins, 16 Snowdin, 18 Waterfall, and 40 combined Hotland/CORE.
Quota counts alone are insufficient. Snowdrake has an ordering constraint;
Lesser Dog is required if encountered; named bosses/unique encounters are also
required. Toriel is an exception to a simplistic rule that every regional boss
must follow quota exhaustion: killing her can contribute to the Ruins count.
The implementation stores the quota reference and accepts explicit normalized
aborted/completed observations; it does **not** yet infer these from counts.

[Genocide Route — Ending](https://undertale.wiki/w/Genocide_Route#Ending)
describes exchanging the SOUL to restore the world, and altered subsequent
True Pacifist/Genocide endings despite a True Reset. `soul_sold` is read-only;
it distinguishes the modeled pacifist variants. Missing history remains UNKNOWN.
No guidance objective instructs the player to create or remove permanent history.

## Coverage and runtime contract

All catalog entries currently have `CompleteCoverage = false`. Satisfying the
implemented subset yields UNKNOWN, never a claim of complete reachability.
Neutral sub-endings are explicitly unclassified. Soulless Genocide variants,
Hard Mode, debug outcomes, full boss survival/event ordering, ordinary versus
True Reset persistence, and end-to-end actual endings remain unimplemented.

C# and generated GML consume the same declarative requirements. GML uses
`global.rk_*` normalized fields; unknown is -1, boolean facts are 0/1, and EXP
must be nonnegative. The generator neither invents native globals nor reads
save files. Invalid booleans/negative values produce UNKNOWN in both evaluators.

Tests execute the emitted GML subset through an independent parser/interpreter
across 6,000 deterministic randomized snapshots and compare its status to C#.
This checks emitted control-flow semantics, not a real GameMaker runtime.
Authentic-bytecode compilation/readback and gameplay tests are separate evidence.
