# Runtime availability investigation

The authorized dev-game-data release still contains only data.win, file0, file8,
file9 and undertale.ini. Workspace/home/opt/tmp searches found no matching
UNDERTALE executable, runner, appmanifest_391540.acf, game.unx or game.ios.
No unauthorized game executable was downloaded.

For this exact uploaded input, provide the matching legitimate Steam game folder,
including UNDERTALE.exe and external media, plus steamapps/appmanifest_391540.acf
and, if available, the installed depot manifest. The runner's architecture must
be measured from its executable; it cannot be inferred from data.win. A different
Linux/macOS depot needs its own original data/runner and separate exact profile.
ExecutableInspector can read PE/ELF/Mach-O architectures without approving a game.
It was checked against the four official compiler-host executables as header
fixtures; those files are not UNDERTALE runtime evidence.

A virtual-display path is feasible: locally extracted Debian Xvfb started and an
OpenGL 4.6 Mesa context was created. The MIT-licensed alternative runner OpenGM
was built from inspected upstream source with its pinned submodules. Its authentic
input conversion then stopped at missing external `abc_123_a.ogg`. No ROUTEKEEPER
GML gameplay or official-runner startup was executed. Supplying silence or stubbing
missing built-ins would be an instrumented emulator test, not Steam compatibility.

OpenGM's own README warns that UNDERTALE breaks in many places. Even a later
successful alternative-runner test must remain separate from official runner
validation. No profile was promoted to VerifiedPatch.

Next runtime scenarios: original and patched startup; EN/KR rendering; all settings
and pad/keyboard paths; room transitions; battle timing; warning acknowledgement;
water and quota protection; each supported Forced refusal; save/reload/RESET;
actual endings and persistent-history invariance. Use private disposable saves.
