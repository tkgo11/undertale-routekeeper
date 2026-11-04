#!/usr/bin/env python3
"""Build the pinned offline Windows dependency subset; never fetch game inputs.

The official compiler executable/libraries are unchanged. Optional upstream
editor scripts/media are excluded because they include game border artwork.
Matching CLI/library/submodule source and build instructions accompany binaries.
"""
import argparse
from contextlib import contextmanager
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import stat
import urllib.parse
import urllib.request
import uuid
import zipfile

import runtime_lab

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / 'profiles/beta-dependencies.json'
DEFAULT_CACHE = ROOT / '.research/beta-dependency-downloads'
MAX_ARTIFACT_BYTES = 128 * 1024 * 1024
MAX_EXTRACTED_BYTES = 512 * 1024 * 1024
COMPONENTS = {'python', 'pillow', 'compiler', 'compiler-source', 'underanalyzer-source'}
CACHE_NAMES = {'python': 'python.zip', 'pillow': 'pillow.whl', 'compiler': 'utmt.zip',
               'compiler-source': 'utmt-source.zip', 'underanalyzer-source': 'underanalyzer-source.zip'}
PUBLIC_HOSTS = {'www.python.org', 'files.pythonhosted.org', 'github.com', 'api.github.com',
                'codeload.github.com', 'release-assets.githubusercontent.com', 'objects.githubusercontent.com'}
PYTHON_PATH = 'python312.zip\n.\n../tools\n../integration/ui\n../integration\nimport site\n'
MEDIA_SUFFIXES = {'.win', '.unx', '.ios', '.png', '.gif', '.jpg', '.jpeg', '.bmp', '.ogg', '.wav', '.mp3'}
FORBIDDEN_FILES = {'undertale.exe', 'deltarune.exe', 'steam_api.dll', 'steam_appid.txt',
                   'file0', 'file8', 'file9', 'undertale.ini'}
COMPILER_ROOT_FILES = {'LICENSE.txt', 'README.md', 'CONTRIBUTING.md', 'SECURITY.md', 'SCRIPTS.md', '.gitmodules'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def no_links(path):
    return runtime_lab.assert_no_links(Path(path))


def read(path, maximum=1024 * 1024):
    path = no_links(path)
    descriptor = os.open(path, os.O_RDONLY | getattr(os, 'O_NONBLOCK', 0) | getattr(os, 'O_NOFOLLOW', 0))
    with os.fdopen(descriptor, 'rb') as stream:
        info = os.fstat(stream.fileno())
        require(stat.S_ISREG(info.st_mode) and info.st_nlink == 1 and info.st_size <= maximum,
                'Regular, single-link bounded input required')
        data = stream.read(maximum + 1)
        require(len(data) <= maximum, 'Input exceeded byte budget')
        return data


def decode(raw):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, 'Duplicate JSON key')
            result[key] = value
        return result
    return json.loads(raw.decode('utf-8'), object_pairs_hook=unique)


def valid_url(url, allow_query=False):
    require(isinstance(url, str), 'Public dependency URL required')
    parsed = urllib.parse.urlsplit(url)
    require(parsed.scheme == 'https' and parsed.hostname in PUBLIC_HOSTS and
            parsed.username is None and parsed.password is None and parsed.port in (None, 443) and
            not parsed.fragment and (allow_query or not parsed.query),
            'Only approved public HTTPS dependency hosts without credentials are allowed')


class PublicDependencyRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Validate before urllib opens the next connection, including signed
        # public release-asset redirects. A final-URL check alone is too late.
        valid_url(newurl, allow_query=True)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def load_manifest(path=DEFAULT_MANIFEST):
    raw = read(path)
    manifest = decode(raw)
    require(isinstance(manifest, dict) and type(manifest.get('schema')) is int and manifest['schema'] == 1 and manifest.get('platform') == 'win-x64',
            'Unsupported dependency manifest')
    require(set(manifest) == {'schema', 'platform', 'pythonPath', 'pythonWindowlessPath', 'compilerPath',
                              'compilerSourceCommit', 'underanalyzerSourceCommit', 'artifacts'},
            'Unknown or missing dependency manifest fields')
    artifacts = manifest.get('artifacts')
    require(isinstance(artifacts, list) and len(artifacts) == len(COMPONENTS), 'Complete pinned dependency inventory required')
    ids = set()
    names = set()
    for artifact in artifacts:
        require(isinstance(artifact, dict), 'Dependency record must be an object')
        require(set(artifact) == {'id', 'filename', 'url', 'sha256', 'bytes', 'version', 'license', 'sourceCommit'},
                'Unknown or missing dependency fields')
        name = artifact['filename']
        require(artifact['id'] in COMPONENTS and artifact['id'] not in ids, 'Unknown/duplicate dependency ID')
        require(name == CACHE_NAMES[artifact['id']], 'Dependency cache filename differs from its canonical component')
        require(isinstance(name, str) and name and Path(name).name == name and '/' not in name and '\\' not in name and
                ':' not in name and not name.startswith('.') and name.casefold() not in names,
                'Unsafe or duplicate cache filename')
        require(type(artifact['bytes']) is int and 0 < artifact['bytes'] <= MAX_ARTIFACT_BYTES,
                'Invalid dependency size bound')
        digest = artifact['sha256']
        require(isinstance(digest, str) and len(digest) == 64 and all(c in '0123456789abcdef' for c in digest),
                'Lowercase exact dependency SHA256 required')
        require(isinstance(artifact['version'], str) and artifact['version'] and isinstance(artifact['license'], str) and artifact['license'],
                'Dependency version/license provenance required')
        expected_commit = (manifest.get('compilerSourceCommit') if artifact['id'] in {'compiler', 'compiler-source'} else
                           manifest.get('underanalyzerSourceCommit') if artifact['id'] == 'underanalyzer-source' else None)
        require(artifact['sourceCommit'] == expected_commit, 'Dependency source commit binding differs')
        valid_url(artifact['url'])
        ids.add(artifact['id'])
        names.add(name.casefold())
    require(ids == COMPONENTS, 'Dependency component set changed')
    require(manifest.get('pythonPath') == 'python/python.exe' and manifest.get('pythonWindowlessPath') == 'python/pythonw.exe' and
            manifest.get('compilerPath') == 'compiler/UndertaleModCli.exe', 'Physical packaged executable paths changed')
    require(manifest.get('compilerSourceCommit') == '03c7048438347799e0717b6e57a9358d000472e0' and
            manifest.get('underanalyzerSourceCommit') == '4ff50a866b4c1a7acee8cebe6a56d6a48709b453',
            'Reviewed compiler/submodule source commits changed')
    return manifest, hashlib.sha256(raw).hexdigest()


@contextmanager
def verified_archive(path, artifact):
    path = no_links(path)
    descriptor = os.open(path, os.O_RDONLY | getattr(os, 'O_NONBLOCK', 0) | getattr(os, 'O_NOFOLLOW', 0))
    with os.fdopen(descriptor, 'rb') as stream:
        before = os.fstat(stream.fileno())
        require(stat.S_ISREG(before.st_mode) and before.st_nlink == 1 and before.st_size == artifact['bytes'],
                'Dependency archive size/type/link mismatch')
        require(hashlib.file_digest(stream, 'sha256').hexdigest() == artifact['sha256'], 'Dependency archive checksum mismatch')
        stream.seek(0)
        with zipfile.ZipFile(stream) as archive:
            # Validate excluded entries too, before extracting any selected file.
            entries = list(runtime_lab.safe_entries(archive))
            yield archive, entries
        stream.seek(0)
        require(hashlib.file_digest(stream, 'sha256').hexdigest() == artifact['sha256'], 'Dependency archive changed during extraction')
        after = os.fstat(stream.fileno())
        current = no_links(path).stat()
        require((before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) ==
                (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns) ==
                (current.st_dev, current.st_ino, current.st_size, current.st_mtime_ns), 'Dependency pathname/handle changed')


def obtain(artifact, cache, opener=None):
    cache = no_links(cache)
    cache.mkdir(parents=True, exist_ok=True)
    path = no_links(cache / artifact['filename'])
    if path.exists():
        with verified_archive(path, artifact):
            pass
        return path
    valid_url(artifact['url'])
    opener = opener or urllib.request.build_opener(PublicDependencyRedirect()).open
    temporary = no_links(cache / ('.' + artifact['filename'] + '.' + uuid.uuid4().hex + '.download'))
    request = urllib.request.Request(artifact['url'], headers={'User-Agent': 'ROUTEKEEPER-beta-dependency-builder/1'})
    try:
        with opener(request, timeout=30) as response, temporary.open('xb') as out:
            valid_url(response.geturl(), allow_query=True)
            length = response.headers.get('Content-Length')
            if length is not None:
                require(length.isdigit() and int(length) == artifact['bytes'], 'Dependency HTTP size differs from pin')
            total = 0
            digest = hashlib.sha256()
            while True:
                block = response.read(65536)
                if not block:
                    break
                total += len(block)
                require(total <= artifact['bytes'], 'Dependency download exceeded exact size budget')
                digest.update(block)
                out.write(block)
            require(total == artifact['bytes'] and digest.hexdigest() == artifact['sha256'], 'Dependency download checksum/size mismatch')
            out.flush()
            os.fsync(out.fileno())
        no_links(path)
        # A create-new link publishes without overwriting any concurrent cache
        # file. Both names are ours; remove only our temporary name afterwards.
        os.link(temporary, path, follow_symlinks=False)
        temporary.unlink()
        with verified_archive(path, artifact):
            pass
        return path
    finally:
        if temporary.exists():
            no_links(temporary)
            temporary.unlink()


def public_path(relative):
    require(isinstance(relative, PurePosixPath), 'Normalized dependency path required')
    name = relative.name.casefold()
    require(relative.suffix.casefold() not in MEDIA_SUFFIXES and name not in FORBIDDEN_FILES and
            relative.suffix.casefold() != '.pth' and not name.startswith('system_information_'),
            'Game/media/personal or startup-hook payload refused in dependency subset')


def write(path, data):
    path = no_links(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    no_links(path.parent)
    with path.open('xb') as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())


def inspect_nested(raw, name):
    require(name == 'python312.zip', 'Unexpected nested dependency archive')
    with zipfile.ZipFile(io.BytesIO(raw)) as archive:
        for entry, relative in runtime_lab.safe_entries(archive):
            public_path(relative)
            require(relative.suffix.casefold() not in {'.zip', '.whl', '.7z'}, 'Nested archive depth exceeded')
            if not entry.is_dir():
                # Read all stdlib members for actual CRC verification.
                with archive.open(entry) as stream:
                    while stream.read(65536):
                        pass


def extract(path, artifact, destination, mode):
    total = 0
    omitted = []
    with verified_archive(path, artifact) as (archive, entries):
        prefix = None
        if mode in ('compiler-source', 'underanalyzer-source'):
            roots = {relative.parts[0] for _, relative in entries}
            require(len(roots) == 1, 'Source archive must have one commit-root directory')
            prefix = next(iter(roots))
        for entry, relative in entries:
            if prefix is not None:
                relative = PurePosixPath(*relative.parts[1:])
                if not relative.parts:
                    continue
            keep = True
            if mode == 'compiler':
                keep = relative.parts[0] != 'Scripts'
            elif mode == 'compiler-source':
                keep = (relative.parts[0] in {'UndertaleModCli', 'UndertaleModLib'} or
                        len(relative.parts) == 1 and (relative.name in COMPILER_ROOT_FILES or relative.suffix in {'.props', '.targets'}) or
                        relative.as_posix() == '.github/workflows/publish_cli.yml')
            if not keep:
                if not entry.is_dir():
                    omitted.append(entry.filename)
                continue
            public_path(relative)
            target = no_links(destination.joinpath(*relative.parts))
            if entry.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            total += entry.file_size
            require(total <= MAX_EXTRACTED_BYTES, 'Dependency extracted subset exceeds budget')
            # Official pinned payloads are bounded; each is streamed except the
            # sole inspected nested stdlib ZIP, which is bounded by the same cap.
            if relative.suffix.casefold() in {'.zip', '.whl', '.7z'}:
                raw = archive.read(entry)
                inspect_nested(raw, relative.name)
                write(target, raw)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(entry) as source, target.open('xb') as output:
                    copied = 0
                    while True:
                        block = source.read(65536)
                        if not block:
                            break
                        copied += len(block)
                        require(copied <= entry.file_size, 'Archive member exceeded declared byte budget')
                        output.write(block)
                    require(copied == entry.file_size, 'Archive member truncated')
                    output.flush()
                    os.fsync(output.fileno())
    return omitted


def build_instructions(manifest):
    return ("# Corresponding compiler source and offline beta dependencies\n\n"
            "Compiler binary: official UndertaleModCli0.9.2.0 Windows x64 distribution.\n"
            "Compiler/UndertaleModLib source commit: " + manifest['compilerSourceCommit'] + ".\n"
            "Underanalyzer source commit: " + manifest['underanalyzerSourceCommit'] + ".\n\n"
            "The source tree below UndertaleModTool contains the exact CLI and library source,\n"
            "root license/build metadata and the exact Underanalyzer submodule at its expected\n"
            "UndertaleModTool/Underanalyzer path. The unrelated editor, its optional Scripts\n"
            "and image/media assets are intentionally omitted; no compiler executable/library\n"
            "was modified. The original CLI publish workflow is retained as a source reference.\n\n"
            "To modify/build the compiler (developers only), install the .NET10 SDK and, from\n"
            "third-party-source/UndertaleModTool, run:\n\n"
            "    dotnet restore UndertaleModCli/UndertaleModCli.csproj\n"
            "    dotnet publish UndertaleModCli/UndertaleModCli.csproj -c Debug -r win-x64 --self-contained true -p:PublishSingleFile=false -o rebuilt-cli\n\n"
            "NuGet versions/build inputs are declared in the unmodified project files. The\n"
            "official binary is pinned independently; source ZIPs lack original Git metadata\n"
            "and no byte-identical rebuild claim is made. To obtain the complete upstream\n"
            "repository including unrelated editor components, use the exact public source\n"
            "commit URLs in profiles/beta-dependencies.json; no access key is required.\n\n"
            "The GPLv3 compiler is invoked as a separate helper process. Its GPLv3 license and\n"
            "the MPL2.0 Underanalyzer license accompany the preferred source form here.\n"
            "Python and Pillow retain their own bundled licenses, including third-party\n"
            "notices shipped in the Pillow wheel. Existing licenses/dotnet notices accompany\n"
            "the shared .NET runtimes. This file does not assign a license to ROUTEKEEPER\n"
            "or represent an independent legal approval of upstream distributions.\n\n"
            "End users run the packaged app, python/python.exe, python/pythonw.exe and\n"
            "compiler/UndertaleModCli.exe directly. They do not need an SDK, Python install,\n"
            "Visual Studio or administrator privileges. Runtime use is offline; downloads\n"
            "occur only when building this package. No game binaries/assets/saves are supplied.\n")


def bundle(output, cache=DEFAULT_CACHE, manifest_path=DEFAULT_MANIFEST, opener=None):
    output = no_links(output)
    require(output.is_dir() and (output / 'RouteKeeper.Beta.Windows.exe').is_file(), 'Existing published beta output required')
    no_links(output / 'RouteKeeper.Beta.Windows.exe')
    destinations = ['python', 'compiler', 'third-party-source', 'licenses/beta-dependencies', 'beta-dependencies-complete.json']
    for relative in destinations:
        require(not no_links(output / relative).exists(), 'Dependency output already exists; use a fresh publish directory')
    manifest, manifest_hash = load_manifest(manifest_path)
    package_manifest = no_links(output / 'profiles/beta-dependencies.json')
    if package_manifest.exists():
        require(hashlib.sha256(read(package_manifest)).hexdigest() == manifest_hash,
                'Published dependency manifest differs; publish a fresh matching package')
    artifacts = {artifact['id']: artifact for artifact in manifest['artifacts']}
    inputs = {name: obtain(artifact, cache, opener) for name, artifact in artifacts.items()}
    stage = no_links(output / ('.beta-dependencies-' + uuid.uuid4().hex))
    stage.mkdir()
    omitted = {}
    omitted['compiler'] = extract(inputs['compiler'], artifacts['compiler'], stage / 'compiler', 'compiler')
    extract(inputs['python'], artifacts['python'], stage / 'python', 'python')
    extract(inputs['pillow'], artifacts['pillow'], stage / 'python', 'pillow')
    source = stage / 'third-party-source/UndertaleModTool'
    omitted['compiler-source'] = extract(inputs['compiler-source'], artifacts['compiler-source'], source, 'compiler-source')
    extract(inputs['underanalyzer-source'], artifacts['underanalyzer-source'], source / 'Underanalyzer', 'underanalyzer-source')
    required = ['python/python.exe', 'python/pythonw.exe', 'python/python312.dll', 'python/python312.zip',
                'python/python312._pth', 'python/PIL/__init__.py', 'python/LICENSE.txt',
                'python/pillow-11.3.0.dist-info/licenses/LICENSE', 'compiler/UndertaleModCli.exe',
                'compiler/UndertaleModCli.dll', 'compiler/LICENSE.txt',
                'third-party-source/UndertaleModTool/UndertaleModCli/UndertaleModCli.csproj',
                'third-party-source/UndertaleModTool/UndertaleModLib/UndertaleModLib.csproj',
                'third-party-source/UndertaleModTool/Underanalyzer/Underanalyzer/Underanalyzer.csproj',
                'third-party-source/UndertaleModTool/LICENSE.txt', 'third-party-source/UndertaleModTool/Underanalyzer/LICENSE']
    for relative in required:
        require(no_links(stage / relative).is_file(), 'Missing dependency payload: ' + relative)
    # Preserve the upstream isolated path file, then create the reviewed local-only
    # paths. Ignore machine PATH/PYTHONPATH/registry; PIL lives directly under '.'.
    (stage / 'python/python312._pth').rename(stage / 'python/python312._pth.upstream')
    write(stage / 'python/python312._pth', PYTHON_PATH.encode('utf-8'))
    notice_files = {
        'Python-LICENSE.txt': 'python/LICENSE.txt',
        'Pillow-LICENSE.txt': 'python/pillow-11.3.0.dist-info/licenses/LICENSE',
        'UndertaleModTool-GPL-3.0.txt': 'compiler/LICENSE.txt',
        'Underanalyzer-MPL-2.0.txt': 'third-party-source/UndertaleModTool/Underanalyzer/LICENSE'
    }
    for destination, source_path in notice_files.items():
        write(stage / 'licenses/beta-dependencies' / destination, read(stage / source_path))
    write(stage / 'third-party-source/BUILDING.md', build_instructions(manifest).encode('utf-8'))
    rows = []
    for path in sorted(stage.rglob('*')):
        no_links(path)
        if path.is_file():
            require(path.stat().st_nlink == 1, 'Linked packaged dependency refused')
            with path.open('rb') as stream:
                digest = hashlib.file_digest(stream, 'sha256').hexdigest()
            rows.append(dict(path=path.relative_to(stage).as_posix(), bytes=path.stat().st_size, sha256=digest))
    receipt = dict(schema=1, kind='PINNED_OFFLINE_BETA_DEPENDENCIES', manifestSha256=manifest_hash,
                   platform='win-x64', pythonPath=manifest['pythonPath'], pythonWindowlessPath=manifest['pythonWindowlessPath'],
                   compilerPath=manifest['compilerPath'], sourceCommits=dict(compiler=manifest['compilerSourceCommit'], underanalyzer=manifest['underanalyzerSourceCommit']),
                   inputs=manifest['artifacts'], omittedOptionalUpstreamFiles=omitted, files=rows,
                   nativeRuntime='NOT_RUN', gameplay='NOT_RUN', automaticUpload=False)
    # Publish owned subtrees without reusing output. A receipt appears last; a
    # failed partial publication remains visible and must not pass package checks.
    for relative in destinations[:-1]:
        destination = no_links(output / relative)
        require(not destination.exists(), 'Dependency destination changed during publication')
        destination.parent.mkdir(parents=True, exist_ok=True)
        no_links(destination.parent)
        (stage / relative).rename(destination)
    # Remove only empty directories created by this invocation before publishing
    # completion. An unexpected file keeps the receipt absent and fails closed.
    for directory in sorted((p for p in stage.rglob('*') if p.is_dir()), key=lambda p: len(p.parts), reverse=True):
        no_links(directory).rmdir()
    stage.rmdir()
    raw_manifest = read(manifest_path)
    require(hashlib.sha256(raw_manifest).hexdigest() == manifest_hash, 'Dependency manifest changed during packaging')
    if not package_manifest.exists():
        write(package_manifest, raw_manifest)
    write(output / 'beta-dependencies-complete.json', (json.dumps(receipt, indent=2) + '\n').encode('utf-8'))
    return receipt


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--cache', type=Path, default=DEFAULT_CACHE)
    parser.add_argument('--manifest', type=Path, default=DEFAULT_MANIFEST)
    args = parser.parse_args()
    result = bundle(args.output, args.cache, args.manifest)
    print('PASS pinned offline beta dependency subset:', len(result['files']), 'files; Windows runtime/gameplay NOT_RUN')
