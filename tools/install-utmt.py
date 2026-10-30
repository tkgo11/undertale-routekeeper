#!/usr/bin/env python3
"""Fetch a pinned official CLI release into a private developer tool directory."""
import argparse
import hashlib
from pathlib import Path
import platform
import stat
import subprocess
import tempfile
import zipfile

VERSION = '0.9.2.0'
ASSETS = {
    ('Linux', 'x86_64'): ('UTMT_CLI_v0.9.2.0-Ubuntu.zip', 'd182f00c0e5ced8d9252aa1f796374cfee077a3889a658e70b68685f9cd559c7'),
    ('Windows', 'AMD64'): ('UTMT_CLI_v0.9.2.0-Windows.zip', 'e7573e45d107be34f81f955c6e4afc3c7c8f2628e5a6f307a871e3825b3dfb40'),
    ('Darwin', 'arm64'): ('UTMT_CLI_v0.9.2.0-macOS.zip', '03042fa77f93e9b7fcb06592b77fb8369876e6d6fff7680a63dc0fa2df5444ef'),
    ('Darwin', 'x86_64'): ('UTMT_CLI_v0.9.2.0-macOS-x86.zip', '8c210151736d828a6fa47bcf86e1365c20d1f2d587a0341274490e6026c09ee6'),
}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, required=True)
    args = parser.parse_args()
    asset, expected = ASSETS[(platform.system(), platform.machine())]
    destination = args.directory.resolve()
    if destination.exists():
        raise SystemExit('FAIL: tool destination must be new')
    with tempfile.TemporaryDirectory(prefix='routekeeper-utmt-') as temporary:
        subprocess.run(['gh', 'release', 'download', VERSION, '--repo', 'UnderminersTeam/UndertaleModTool', '--pattern', asset, '--dir', temporary], check=True)
        archive = Path(temporary) / asset
        with archive.open('rb') as stream:
            actual = hashlib.file_digest(stream, 'sha256').hexdigest()
        if actual != expected:
            raise SystemExit('FAIL: official CLI archive checksum mismatch')
        with zipfile.ZipFile(archive) as zipped:
            for item in zipped.infolist():
                path = (destination / item.filename).resolve()
                if not path.is_relative_to(destination) or stat.S_ISLNK(item.external_attr >> 16):
                    raise SystemExit('FAIL: unsafe CLI archive entry')
            zipped.extractall(destination)
    executable = destination / ('UndertaleModCli.exe' if platform.system() == 'Windows' else 'UndertaleModCli')
    executable.chmod(executable.stat().st_mode | stat.S_IXUSR)
    subprocess.run([str(executable), '--version'], check=True)
    print('PASS: official CLI archive verified; upstream license remains in tool directory')

if __name__ == '__main__':
    main()
