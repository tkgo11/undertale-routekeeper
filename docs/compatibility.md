# Compatibility registry

**No runtime-supported build yet.** Never approve a build from its displayed
version or filename. profiles/registry.json is machine-readable; additional
hook/source evidence is in docs/integration-research.md.

| Exact inspected input | Evidence | Verification | Installer policy |
|---|---|---|---|
| provided-b718f822 | 62,921,978 bytes, SHA-256 b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7, MD5 5903fc5cb042a728d4ad8ee9e949c6eb | FORM, bytecode 16, GMS1 non-YYC, 6,272 code resources, 336 rooms; real patch compile/save/reload verified | InspectedOnly: REFUSED |
| Current Steam Windows | Depot 391541 exists; no matching runner/manifest supplied | NOT_RUN | REFUSED |
| Current Steam macOS | Depot 391542 exists; no game.ios/runner supplied | NOT_RUN | REFUSED |
| Current Steam Linux | Depot 391544 exists; no game.unx/runner supplied | NOT_RUN | REFUSED |

The uploaded file's OS, architecture, Steam build/depot and nominal release
provenance remain unknown. SteamDB's public branch lists build 4279148; this does
not link that build to the supplied hash. Current registry status is diagnostic,
even though the development GML patch can be compiled for that exact input.

Expected experimental output SHA-256:
`b7f2b83f93446a5d62da50db69172bc93f128fe07b312ce111c62ce9b0787dfb`.
Structural input SHA-256:
`665a035018ffd7008e7320bfc511ac752ee47baf72b2de080b524c354086c1aa`.
Full source/output hashes and bytecode identity remain independently checked.

## New or modified build workflow

1. Inspect read-only using `RouteKeeper.Tool inspect` and `integration/analyze.csx`.
2. Compare FORM chunks with `RouteKeeper.Tool diff`. Changed offsets can follow
   inserted resources; a layout difference is not automatically a semantic change.
3. Privately inspect changed scripts, events and hooks using pinned UndertaleModLib;
   current tooling reports selected hook hashes, not a complete semantic diff.
4. Add a distinct profile with its exact identity and an unverified status.
5. Bind verified variables only, compile to a separate new output, reload it and
   check code/resource differences and save invariance.
6. Exercise startup, UI, controls, battles, transitions, save/reload and relevant
   ending scenarios on the matching legitimate runner before considering
   VerifiedPatch. Record platform, architecture and Steam metadata separately.

Unknown/modified inputs have no automatic fallback patch path. An already patched
input is rejected by development patch generation as well as exact-profile
validation. No released G3M package currently exists.
