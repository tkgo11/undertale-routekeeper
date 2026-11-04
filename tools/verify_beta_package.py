#!/usr/bin/env python3
"""Verify portable package closure, dependency hashes and absence of private inputs."""
import argparse
import hashlib
import os
from pathlib import Path, PurePosixPath
import re
import stat
import zipfile

import package_beta_dependencies as dependencies
import runtime_lab

REQUIRED = {
    'RouteKeeper.Beta.Windows.exe', 'RouteKeeper.Beta.Windows.dll',
    'RouteKeeper.Beta.dll', 'RouteKeeper.Tool.dll', 'RouteKeeper.Tool.exe', 'coreclr.dll',
    'profiles/registry.json', 'profiles/windows-game-files.json', 'profiles/beta-dependencies.json',
    'integration/patch.csx', 'integration/verify.csx', 'locales/languages.json', 'BETA-TESTER.md',
    'tools/human_beta.py', 'tools/windows_e2e.py', 'tools/runtime_lab.py', 'tools/screen_verify.py',
    'tools/runtime/human-session.ps1', 'tools/runtime/human-loop.ps1', 'tools/runtime/human-beta-policy.json',
    'python/python.exe', 'python/pythonw.exe', 'python/python312.dll', 'python/python312.zip',
    'python/python312._pth', 'compiler/UndertaleModCli.exe', 'compiler/UndertaleModCli.dll',
    'third-party-source/BUILDING.md', 'beta-dependencies-complete.json',
    'python/PIL/__init__.py', 'python/LICENSE.txt', 'python/pillow-11.3.0.dist-info/licenses/LICENSE',
    'compiler/LICENSE.txt', 'licenses/beta-dependencies/Python-LICENSE.txt',
    'licenses/beta-dependencies/Pillow-LICENSE.txt', 'licenses/beta-dependencies/UndertaleModTool-GPL-3.0.txt',
    'licenses/beta-dependencies/Underanalyzer-MPL-2.0.txt',
    'third-party-source/UndertaleModTool/UndertaleModCli/UndertaleModCli.csproj',
    'third-party-source/UndertaleModTool/UndertaleModLib/UndertaleModLib.csproj',
    'third-party-source/UndertaleModTool/Underanalyzer/Underanalyzer/Underanalyzer.csproj',
    'third-party-source/UndertaleModTool/LICENSE.txt',
    'third-party-source/UndertaleModTool/Underanalyzer/LICENSE',
}
MAX_FILES = 4096
MAX_BYTES = 1024**3
MAX_FILE_BYTES = 256*1024**2
PUBLIC_IMAGES = {'integration/assets/ui-font.png', 'integration/assets/fonts/galmuri14/ui-font.png'}
DEPENDENCY_ROOTS = ('python/', 'compiler/', 'third-party-source/', 'licenses/beta-dependencies/')


def validate(names):
    names = list(names)
    if len(names) > MAX_FILES:raise ValueError('Package file count exceeds budget')
    normalized = set()
    for name in names:
        path = PurePosixPath(name)
        if ('\\' in name or ':' in name or path.is_absolute() or
                any(part in ('', '.', '..') or part.endswith((' ', '.')) for part in name.split('/')) or
                any(ord(c)<32 or c in '<>"|?*' for c in name) or
                any(re.fullmatch(r'(CON|PRN|AUX|NUL|COM[1-9¹²³]|LPT[1-9¹²³])(?:\..*)?',part,re.I) for part in path.parts)):
            raise ValueError('Unsafe archive path')
        key = name.casefold()
        if key in normalized:raise ValueError('Duplicate/aliased archive path')
        normalized.add(key)
        if (path.suffix.casefold() in ('.win', '.unx', '.ios') or
                path.name.casefold() in ('undertale.exe', 'steam_api.dll', 'steam_appid.txt', 'file0', 'file8', 'file9', 'undertale.ini') or
                path.name.casefold().startswith('system_information_') or
                any(part.casefold() in ('private-data', '.research', 'private-evidence', 'sessions', 'candidates') for part in path.parts) or
                path.suffix.casefold() in ('.zip','.whl','.7z') and name!='python/python312.zip' or
                path.suffix.casefold() in dependencies.MEDIA_SUFFIXES and name not in PUBLIC_IMAGES):
            raise ValueError('Proprietary/personal runtime input in package')
        if name.startswith(DEPENDENCY_ROOTS):dependencies.public_path(path)
    if not REQUIRED.issubset(set(names)):
        raise ValueError('Missing package requirements: ' + ', '.join(sorted(REQUIRED - set(names))))
    if not any(name.startswith('licenses/') for name in names):raise ValueError('Missing third-party notices')
    return len(names)


def check_compiler_notices(names, hashes):
    # These maintained notices are outside the generated dependency receipt.
    # Compare both the complete file set and bytes, including provenance/README.
    root=runtime_lab.assert_no_links(dependencies.ROOT/'licenses/compiler')
    expected={}
    for source in root.rglob('*'):
        runtime_lab.assert_no_links(source)
        info=source.lstat()
        if stat.S_ISDIR(info.st_mode):continue
        if not stat.S_ISREG(info.st_mode) or info.st_nlink!=1 or info.st_size>1024*1024:raise ValueError('Invalid maintained compiler notice input')
        name='licenses/compiler/'+source.relative_to(root).as_posix()
        expected[name]=(info.st_size,runtime_lab.digest(source))
        if len(expected)>128:raise ValueError('Compiler notice inventory exceeds budget')
    if not expected or {n for n in names if n.startswith('licenses/compiler/')}!=set(expected):raise ValueError('Compiler notice subtree differs from reviewed source')
    if any(hashes[name]!=identity for name,identity in expected.items()):raise ValueError('Compiler notice hash/size differs from reviewed source')


def check_receipt(names, read, hashes):
    check_compiler_notices(names, hashes)
    manifest_raw = read('profiles/beta-dependencies.json', 1024*1024)
    expected_manifest, manifest_hash = dependencies.load_manifest()
    if hashlib.sha256(manifest_raw).hexdigest()!=manifest_hash:raise ValueError('Dependency lock differs from reviewed source')
    receipt=dependencies.decode(read('beta-dependencies-complete.json', 1024*1024))
    expected=dict(schema=1,kind='PINNED_OFFLINE_BETA_DEPENDENCIES',manifestSha256=manifest_hash,
                  platform='win-x64',pythonPath=expected_manifest['pythonPath'],pythonWindowlessPath=expected_manifest['pythonWindowlessPath'],
                  compilerPath=expected_manifest['compilerPath'],inputs=expected_manifest['artifacts'],
                  sourceCommits=dict(compiler=expected_manifest['compilerSourceCommit'],underanalyzer=expected_manifest['underanalyzerSourceCommit']),
                  nativeRuntime='NOT_RUN',gameplay='NOT_RUN',automaticUpload=False)
    if not isinstance(receipt,dict) or any(receipt.get(k)!=v for k,v in expected.items()):raise ValueError('Invalid dependency completion receipt')
    rows=receipt.get('files')
    if not isinstance(rows,list) or not 1<=len(rows)<=MAX_FILES:raise ValueError('Dependency receipt file budget')
    seen=set()
    for row in rows:
        if not isinstance(row,dict) or set(row)!={'path','bytes','sha256'}:raise ValueError('Invalid dependency receipt row')
        name=row['path']
        if not isinstance(name,str) or name not in names or not name.startswith(DEPENDENCY_ROOTS) or name in seen:raise ValueError('Unlisted/duplicate dependency receipt path')
        if type(row['bytes']) is not int or row['bytes']<0 or row['bytes']>MAX_FILE_BYTES or not isinstance(row['sha256'],str):raise ValueError('Invalid dependency receipt identity')
        if hashes[name]!=(row['bytes'],row['sha256']):raise ValueError('Dependency payload hash/size mismatch: '+name)
        seen.add(name)
    if seen!={n for n in names if n.startswith(DEPENDENCY_ROOTS)}:raise ValueError('Dependency receipt does not cover exact subtree')
    if read('python/python312._pth',4096)!=dependencies.PYTHON_PATH.encode():raise ValueError('Packaged interpreter paths differ')
    game_manifest=read('profiles/windows-game-files.json',1024*1024)
    if hashlib.sha256(game_manifest).hexdigest()!=runtime_lab.GAME_MANIFEST_SHA:raise ValueError('Installed-game metadata manifest differs')
    for name in PUBLIC_IMAGES & names:
        source=dependencies.ROOT/name
        if hashes[name][1]!=runtime_lab.digest(source):raise ValueError('Generated public image differs from reviewed source')
    registry_raw=read('profiles/registry.json',1024*1024)
    reviewed_registry=dependencies.read(dependencies.ROOT/'profiles/registry.json')
    if registry_raw!=reviewed_registry:raise ValueError('Packaged build registry differs from reviewed source')
    private_hashes={r['sha256'] for r in dependencies.decode(game_manifest)['files']}
    for profile in dependencies.decode(registry_raw):
        private_hashes.update(profile[key] for key in ('OriginalSha256','PatchedSha256','ExecutableSha256') if profile.get(key))
    if any(digest in private_hashes for _,digest in hashes.values()):raise ValueError('Known original game resource bytes in package')


def verify(path):
    path=runtime_lab.assert_no_links(path)
    hashes={};total=0
    if path.is_dir():
        paths={};nodes=0
        for item in path.rglob('*'):
            nodes+=1
            if nodes>MAX_FILES*2:raise ValueError('Package node budget exceeded')
            runtime_lab.assert_no_links(item)
            info=item.lstat()
            if stat.S_ISDIR(info.st_mode):continue
            if not stat.S_ISREG(info.st_mode) or info.st_nlink!=1:raise ValueError('Regular single-link package input required')
            name=item.relative_to(path).as_posix();paths[name]=item
            total+=info.st_size
            if len(paths)>MAX_FILES or info.st_size>MAX_FILE_BYTES or total>MAX_BYTES:raise ValueError('Package byte/file budget exceeded')
        count=validate(paths)
        for name,item in paths.items():
            hashes[name]=(item.stat().st_size,runtime_lab.digest(item))
        def read(name,maximum):return dependencies.read(paths[name],maximum)
        check_receipt(set(paths),read,hashes)
        return count
    descriptor=os.open(path,os.O_RDONLY|getattr(os,'O_NONBLOCK',0)|getattr(os,'O_NOFOLLOW',0))
    with os.fdopen(descriptor,'rb') as stream:
        info=os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_nlink!=1 or info.st_size>MAX_BYTES:raise ValueError('Package archive type/link/size refused')
        return verify_archive(stream)


def verify_archive(stream):
    hashes={};total=0
    with zipfile.ZipFile(stream) as archive:
        entries=list(runtime_lab.safe_entries(archive))
        for entry,relative in entries:
            expected=relative.as_posix()+('/' if entry.is_dir() else '')
            if entry.filename!=expected:raise ValueError('Noncanonical package archive path')
        files={str(relative):entry for entry,relative in entries if not entry.is_dir()}
        count=validate(files)
        for name,entry in files.items():
            total+=entry.file_size
            if entry.file_size>MAX_FILE_BYTES or total>MAX_BYTES:raise ValueError('Package archive byte budget exceeded')
            digest=hashlib.sha256();copied=0
            with archive.open(entry) as source:
                while block:=source.read(65536):
                    copied+=len(block)
                    if copied>entry.file_size:raise ValueError('Archive member exceeds declared size')
                    digest.update(block)
            if copied!=entry.file_size:raise ValueError('Truncated package member')
            hashes[name]=(copied,digest.hexdigest())
        def read(name,maximum):
            if files[name].file_size>maximum:raise ValueError('Package metadata byte budget exceeded')
            with archive.open(files[name]) as source:raw=source.read(maximum+1)
            if len(raw)>maximum:raise ValueError('Package metadata grew beyond budget')
            return raw
        check_receipt(set(files),read,hashes)
        return count


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('path',type=Path)
    arguments=parser.parse_args()
    print('PASS portable Beta package closure, dependency hashes and private-input policy:',verify(arguments.path))
