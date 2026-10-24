# Compatibility registry

`registry.json` contains analyzed exact file identities. Its only current profile is `InspectedOnly`: controller compilation and output reload have passed, but no game runner, platform provenance, Steam build/depot manifest or gameplay scenario has been verified. The installer must reject this status.

The experimental patched hash records the output of `integration/patch.csx` with UndertaleModCli 0.9.2.0 and current generated GML/font. It is evidence, not authorization for installation. A rebuild after changing GML/assets may legitimately produce a different output hash; update it only after rerunning roundtrip verification. Never promote a profile to `VerifiedPatch` based only on compilation or synthetic tests.
