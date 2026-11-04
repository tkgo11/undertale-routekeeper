# Offline Windows beta dependency package

`tools/package_beta_dependencies.py` adds the reviewed Windows x64 helper subset
to an existing self-contained Beta Tester publish directory. Package construction
may download public official artifacts. Normal use of the completed package does
not install or download Python, a .NET SDK, Visual Studio, compiler tools or any
UNDERTALE input. No administrator privileges are requested.

The maintained [compiler notices](../licenses/compiler/README.md) additionally
carry the actual CLI's transitive NuGet dependency licenses, package metadata and
native-library notices. Their provenance ledger binds package/source inputs and
published text hashes; the package verifier compares this complete notice subtree
with the maintained source. This is an attribution inventory, not legal approval.

```sh
dotnet publish src/RouteKeeper.Beta.Windows -c Release -r win-x64 --self-contained true -o artifacts/beta
python tools/package_beta_dependencies.py --output artifacts/beta
python tools/verify_beta_package.py artifacts/beta
```

Run the builder with Python3.12+ on a build machine. `--cache` selects an ordinary
local cache; the default is ignored `.research/beta-dependency-downloads`. Reusing
a verified cached artifact makes packaging offline. A wrong checksum/size or an
existing dependency output refuses; use a fresh publish directory rather than
overwriting or repairing a partially populated package. `--manifest` is intended
for explicitly reviewed build inputs, not runtime user configuration.

## Exact pinned inputs

The source-controlled `profiles/beta-dependencies.json` records public HTTPS URLs,
byte counts, SHA256 digests, versions, licenses and source commits for all inputs:

| Input | Version / source | Distribution |
|---|---|---|
| CPython Windows x64 embeddable |3.12.10 |Official python.org embed archive |
| Pillow Windows cp312 win_amd64 |11.3.0 |Official PyPI wheel and bundled license/notices |
| UndertaleModCli Windows x64 |0.9.2.0, commit03c7048438347799e0717b6e57a9358d000472e0 |Official self-contained compiler/library files, unchanged |
| UndertaleModTool corresponding CLI/library source |Same exact03c7048 commit |Preferred source subset and original build metadata |
| Underanalyzer source |4ff50a866b4c1a7acee8cebe6a56d6a48709b453 |Exact source at the compiler's submodule path |

Downloads use inherited proxy/CA trust with TLS verification, bounded reads,
exact expected lengths and content digests. No credentials or authentication
headers are requested, stored or emitted. Redirects remain restricted to approved
public HTTPS distribution hosts. Cached archives are rehashed before and after
extraction using the same open handle; malformed archives, links, path aliases,
traversal, reserved Windows names and excessive expanded payloads refuse.
These are best-effort path revalidation and cooperative local publication, not
hostile-parent-directory race isolation or a power-loss proof.

## Physical paths and interpreter isolation

The completed package contains:

- `python/python.exe`: physical embedded interpreter for the existing helpers.
- `python/pythonw.exe`: physical windowless interpreter for the external guardian.
- `compiler/UndertaleModCli.exe`: pinned helper process, invoked separately.
- `third-party-source/UndertaleModTool/UndertaleModCli/` and `UndertaleModLib/`:
  corresponding compiler/library source.
- `third-party-source/UndertaleModTool/Underanalyzer/`: exact submodule source,
  including its MPL2.0 license and project at `Underanalyzer/Underanalyzer.csproj`.
- `third-party-source/BUILDING.md`: exact source revisions, build commands,
  upstream references and the distribution-subset explanation.
- `licenses/beta-dependencies/`: verbatim Python, Pillow, GPLv3 compiler and
  MPL2.0 Underanalyzer notices, with upstream originals also retained.
- `profiles/beta-dependencies.json` and `beta-dependencies-complete.json`:
  reviewed input lock and final per-file size/hash receipt.

The embedded interpreter's reviewed `python312._pth` is:

```text
python312.zip
.
../tools
../integration/ui
../integration
import site
```

The upstream path file is preserved beside it as `python312._pth.upstream`.
Pillow and its wheel metadata live directly below `python/`. Isolated `_pth`
configuration avoids relying on a machine Python, registry entries or inherited
PYTHONPATH. Invocation-local PATH selection may support legacy helper subprocesses;
the launcher must pass the exact physical packaged interpreter/builder paths and
must not change global user/machine configuration. The existing shared Tool is
self-contained, so published operation must not invoke `dotnet build` or require
an SDK merely to execute it.

## Source and excluded upstream media

The official compiler ZIP includes optional editor scripts with UNDERTALE and
DELTARUNE border PNGs. Its full source ZIP also includes those scripts and game
illustrations such as `images/flowey.gif`. The beta package does **not** copy those
optional `Scripts/`, editor or image/media directories, and does not ship the raw
source/download archives. It copies the unmodified CLI executable/libraries,
runtime dependencies and their configuration/definition data. Exact CLI/library
source, root license/build metadata and matching Underanalyzer source are included
in the corresponding-source tree; no compiler binary or source implementation is
rewritten. The original publish workflow is preserved for build provenance.

`BUILDING.md` supplies `dotnet restore` and self-contained `dotnet publish` commands
against the included CLI project. Existing source project files retain exact
NuGet versions and the original build logic. The official binary is checked
independently; source ZIPs lack original Git metadata and packaging does not claim
a byte-identical reconstruction from those ZIPs alone.

The compiler's GPLv3 and Underanalyzer's MPL2.0 source/license duties remain
separate from ROUTEKEEPER's own source. No project-wide ROUTEKEEPER license is
invented by this package. Python, Pillow and the .NET runtime keep their own
bundled notices. All notices shipped in these official inputs are retained;
this technical file is not independent legal approval of upstream distributions.
No game executable, game data, extracted game textures/audio, save content or
private runtime evidence is a dependency payload.

## Publication and verification

All archives are verified before any selected payload is extracted. The nested
Python standard-library ZIP is also checked for safe paths, unexpected media,
deeper archives and CRC errors. New payloads are staged below the owned output,
then published into new dependency subdirectories. Completion appears only after
all required executable/source/license files, interpreter configuration and
per-file receipt hashes exist. Failure preserves evidence and leaves no completion
receipt; unknown files are never recursively deleted to make a retry succeed.

Synthetic tests use invented ZIP/wheel content and controlled HTTP responses:

```sh
python tools/test_beta_dependencies.py
```

They cover source/notices, interpreter paths, excluded optional game artwork,
cache corruption, links/traversal, nested archives, changed open archives,
missing licenses, malformed manifest/credentials, bounded/hash-checked downloads,
bad redirects and concurrent cache publication. They never launch an executable.
Linux package construction is not Windows runtime evidence. Windows CI must
add the actual packaged-interpreter/Pillow/compiler version probes, harmless
guardian/native filesystem fixtures and WPF construction checks before claiming
those executable contracts passed. Interactive GUI/gameplay remains a separate
human acceptance scope. This workflow does not publish a public release.
