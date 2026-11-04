"""Synthetic package/download contracts; never Windows runtime or game evidence."""
import copy
import hashlib
import io
import json
import os
import subprocess
import sys
from pathlib import Path
import stat
import tempfile
import unittest
import urllib.request
import zipfile

import package_beta_dependencies as package


def zipped(files):
    output = io.BytesIO()
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        for name, data in files.items():
            archive.writestr(name, data)
    return output.getvalue()


class Response(io.BytesIO):
    def __init__(self, data, url='https://www.python.org/synthetic.zip', reported_length=None):
        super().__init__(data)
        self.url = url
        self.headers = {'Content-Length': str(len(data) if reported_length is None else reported_length)}

    def geturl(self):
        return self.url


class Dependencies(unittest.TestCase):
    def test_redirect_target_is_rejected_before_another_connection(self):
        handler = package.PublicDependencyRedirect()
        request = urllib.request.Request('https://github.com/synthetic')
        for target in ('http://github.com/untrusted', 'https://127.0.0.1/private',
                       'https://user:secret@github.com/private', 'https://evil.example/payload'):
            with self.subTest(target=target), self.assertRaises(ValueError):
                handler.redirect_request(request, None, 302, 'Found', {}, target)
        redirected = handler.redirect_request(request, None, 302, 'Found', {},
            'https://release-assets.githubusercontent.com/synthetic?signature=public-token')
        self.assertEqual(redirected.host, 'release-assets.githubusercontent.com')

    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='rk-beta-dependencies-SYNTHETIC-')
        self.addCleanup(temporary.cleanup)
        # Resolve only the test system-temp alias, not any production input.
        self.root = Path(temporary.name).resolve()
        self.cache = self.root / 'cache'
        self.cache.mkdir()
        self.output = self.root / 'published'
        self.output.mkdir()
        (self.output / 'RouteKeeper.Beta.Windows.exe').write_bytes(b'SYNTHETIC APP, NEVER EXECUTED')
        self.manifest, _ = package.load_manifest()
        self.manifest = copy.deepcopy(self.manifest)
        compiler = 'UnderminersTeam-UndertaleModTool-03c7048/'
        analyzer = 'UnderminersTeam-Underanalyzer-4ff50a8/'
        self.payloads = {
            'python': zipped({'python.exe': b'SYNTHETIC PYTHON', 'pythonw.exe': b'SYNTHETIC WINDOWLESS', 'python312.dll': b'SYNTHETIC DLL',
                             'python312.zip': zipped({'encodings/__init__.pyc': b'SYNTHETIC STDLIB'}),
                             'python312._pth': b'python312.zip\n.\n#import site\n', 'LICENSE.txt': b'SYNTHETIC PYTHON LICENSE'}),
            'pillow': zipped({'PIL/__init__.py': b'__version__="11.3.0"\n',
                             'pillow-11.3.0.dist-info/licenses/LICENSE': b'SYNTHETIC PILLOW LICENSE'}),
            'compiler': zipped({'UndertaleModCli.exe': b'SYNTHETIC COMPILER', 'UndertaleModCli.dll': b'SYNTHETIC CLI DLL',
                               'LICENSE.txt': b'SYNTHETIC GPL', 'Scripts/UTDR Scripts/Borders/bg_border_ruins.png': b'FORBIDDEN OPTIONAL MEDIA'}),
            'compiler-source': zipped({compiler + 'LICENSE.txt': b'SYNTHETIC GPL SOURCE',
                                      compiler + '.gitmodules': b'[submodule "Underanalyzer"]\npath=Underanalyzer\n',
                                      compiler + 'UndertaleModCli/UndertaleModCli.csproj': b'<Project/>',
                                      compiler + 'UndertaleModLib/UndertaleModLib.csproj': b'<Project/>',
                                      compiler + 'images/flowey.gif': b'FORBIDDEN OPTIONAL GAME ART',
                                      compiler + 'UndertaleModTool/Scripts/UTDR Scripts/Borders/bg_border_ruins.png': b'FORBIDDEN OPTIONAL MEDIA'}),
            'underanalyzer-source': zipped({analyzer + 'LICENSE': b'SYNTHETIC MPL2',
                                           analyzer + 'Underanalyzer/Underanalyzer.csproj': b'<Project/>'})
        }
        for artifact in self.manifest['artifacts']:
            self.put(artifact['id'], self.payloads[artifact['id']])
        self.profile = self.root / 'manifest.json'
        self.save_manifest()

    def artifact(self, id):
        return next(row for row in self.manifest['artifacts'] if row['id'] == id)

    def put(self, id, raw):
        artifact = self.artifact(id)
        artifact.update(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
        (self.cache / artifact['filename']).write_bytes(raw)

    def save_manifest(self):
        self.profile.write_text(json.dumps(self.manifest), encoding='utf-8', newline='\n')

    def bundle(self):
        self.save_manifest()
        # A cache-only packaging run must make no network request at all.
        def no_network(*args, **kwargs):
            raise AssertionError('Unexpected network during synthetic cached packaging')
        return package.bundle(self.output, self.cache, self.profile, no_network)

    def test_manifest_exact_physical_paths_and_complete_provenance(self):
        manifest, _ = package.load_manifest()
        self.assertEqual(manifest['pythonPath'], 'python/python.exe')
        self.assertEqual(manifest['pythonWindowlessPath'], 'python/pythonw.exe')
        self.assertEqual(manifest['compilerPath'], 'compiler/UndertaleModCli.exe')
        self.assertEqual({row['id'] for row in manifest['artifacts']}, package.COMPONENTS)
        self.assertTrue(all(row['bytes'] <= package.MAX_ARTIFACT_BYTES for row in manifest['artifacts']))

    def test_cached_offline_bundle_preserves_source_notices_and_excludes_game_art(self):
        receipt = self.bundle()
        self.assertEqual(receipt['nativeRuntime'], 'NOT_RUN')
        self.assertEqual(receipt['gameplay'], 'NOT_RUN')
        self.assertFalse(receipt['automaticUpload'])
        self.assertEqual((self.output / 'python/python312._pth').read_text(encoding='utf-8'), package.PYTHON_PATH)
        self.assertIn('#import site', (self.output / 'python/python312._pth.upstream').read_text(encoding='utf-8'))
        self.assertFalse((self.output / 'compiler/Scripts').exists())
        self.assertFalse((self.output / 'third-party-source/UndertaleModTool/images').exists())
        self.assertTrue((self.output / 'third-party-source/UndertaleModTool/Underanalyzer/Underanalyzer/Underanalyzer.csproj').is_file())
        self.assertIn('dotnet publish', (self.output / 'third-party-source/BUILDING.md').read_text(encoding='utf-8'))
        self.assertIn('source commit', (self.output / 'third-party-source/BUILDING.md').read_text(encoding='utf-8'))
        self.assertEqual((self.output / 'licenses/beta-dependencies/Underanalyzer-MPL-2.0.txt').read_bytes(), b'SYNTHETIC MPL2')
        for row in receipt['files']:
            raw = (self.output / row['path']).read_bytes()
            self.assertEqual(hashlib.sha256(raw).hexdigest(), row['sha256'])
            self.assertEqual(len(raw), row['bytes'])
            self.assertNotIn(b'FORBIDDEN OPTIONAL', raw)
        self.assertTrue((self.output / 'beta-dependencies-complete.json').is_file())
        self.assertFalse(list(self.output.glob('.beta-dependencies-*')))

    def test_existing_outputs_never_reused_or_overwritten(self):
        self.bundle()
        before = (self.output / 'python/python.exe').read_bytes()
        with self.assertRaises(ValueError):
            self.bundle()
        self.assertEqual((self.output / 'python/python.exe').read_bytes(), before)

    def test_corrupt_cached_archive_refuses_before_publication(self):
        path = self.cache / self.artifact('compiler')['filename']
        path.write_bytes(path.read_bytes() + b'CHANGED')
        with self.assertRaises(ValueError):
            self.bundle()
        self.assertFalse((self.output / 'compiler').exists())
        self.assertFalse((self.output / 'beta-dependencies-complete.json').exists())

    def test_archive_path_traversal_rejected_even_in_omitted_scripts(self):
        self.put('compiler', zipped({'Scripts/../../escape.txt': b'NO ESCAPE'}))
        with self.assertRaises(ValueError):
            self.bundle()
        self.assertFalse((self.root / 'escape.txt').exists())
        self.assertFalse((self.output / 'beta-dependencies-complete.json').exists())

    def test_archive_symlink_is_rejected(self):
        raw = io.BytesIO()
        with zipfile.ZipFile(raw, 'w') as archive:
            link = zipfile.ZipInfo('Scripts/linked')
            link.create_system = 3
            link.external_attr = (stat.S_IFLNK | 0o777) << 16
            archive.writestr(link, '../outside')
        self.put('compiler', raw.getvalue())
        with self.assertRaises(ValueError):
            self.bundle()

    def test_nested_stdlib_archive_is_validated(self):
        with self.assertRaises(ValueError):
            package.inspect_nested(zipped({'data.win': b'SYNTHETIC GAME NAME'}), 'python312.zip')
        with self.assertRaises(ValueError):
            package.inspect_nested(zipped({'inner.zip': zipped({'x': b'x'})}), 'python312.zip')
        with self.assertRaises(ValueError):
            package.inspect_nested(zipped({'../escape': b'x'}), 'python312.zip')

    def test_selected_compiler_source_game_payload_and_startup_hooks_refuse(self):
        with self.assertRaises(ValueError):
            package.public_path(package.PurePosixPath('UndertaleModLib/data.win'))
        with self.assertRaises(ValueError):
            package.public_path(package.PurePosixPath('PIL/startup.pth'))
        with self.assertRaises(ValueError):
            package.public_path(package.PurePosixPath('steam_api.dll'))

    def test_mutation_after_archive_verification_is_detected(self):
        artifact = self.artifact('pillow')
        path = self.cache / artifact['filename']
        with self.assertRaises(ValueError):
            with package.verified_archive(path, artifact):
                with path.open('ab') as out:
                    out.write(b'UNEXPECTED LATE MUTATION')

    def test_missing_source_or_license_never_publishes_completion(self):
        prefix = 'UnderminersTeam-Underanalyzer-4ff50a8/'
        self.put('underanalyzer-source', zipped({prefix + 'Underanalyzer/Underanalyzer.csproj': b'<Project/>'}))
        with self.assertRaises(ValueError):
            self.bundle()
        self.assertFalse((self.output / 'beta-dependencies-complete.json').exists())

    def test_manifest_rejects_credentials_duplicate_ids_and_source_mismatch(self):
        original = copy.deepcopy(self.manifest)
        mutations = [lambda m: m['artifacts'][0].update(url='https://user:password@www.python.org/synthetic.zip'),
                     lambda m: m['artifacts'][0].update(url='http://www.python.org/synthetic.zip'),
                     lambda m: m['artifacts'][0].update(url='https://www.python.org/synthetic.zip?token=SYNTHETIC_NOT_ALLOWED'),
                     lambda m: m['artifacts'][0].update(bytes=True),
                     lambda m: m['artifacts'][0].update(filename='../outside.zip'),
                     lambda m: m['artifacts'][1].update(id='python'),
                     lambda m: m['artifacts'][2].update(sourceCommit='0' * 40)]
        for mutate in mutations:
            self.manifest = copy.deepcopy(original)
            mutate(self.manifest)
            self.save_manifest()
            with self.subTest(manifest=self.manifest['artifacts'][0]['id']), self.assertRaises(ValueError):
                package.load_manifest(self.profile)

    def test_download_is_bounded_checksummed_and_has_no_authentication_header(self):
        artifact = copy.deepcopy(self.artifact('python'))
        cache = self.root / 'new-cache'
        calls = []
        def opener(request, timeout):
            self.assertEqual(timeout, 30)
            self.assertNotIn('Authorization', request.headers)
            calls.append(request.full_url)
            return Response(self.payloads['python'])
        result = package.obtain(artifact, cache, opener)
        self.assertEqual(result.read_bytes(), self.payloads['python'])
        self.assertEqual(len(calls), 1)
        self.assertEqual(result.stat().st_nlink, 1)
        self.assertFalse(list(cache.glob('*.download')))

    def test_download_wrong_size_hash_and_redirect_refuse(self):
        artifact = self.artifact('python')
        cases = [lambda: Response(self.payloads['python'] + b'EXCESS'),
                 lambda: Response(self.payloads['python'][:-1] + b'X'),
                 lambda: Response(self.payloads['python'], url='http://www.python.org/not-https.zip'),
                 lambda: Response(self.payloads['python'], url='https://untrusted.example/not-approved.zip')]
        for index, response in enumerate(cases):
            cache = self.root / ('bad-cache-' + str(index))
            with self.subTest(index=index), self.assertRaises(ValueError):
                package.obtain(artifact, cache, lambda *args, **kwargs: response())
            self.assertFalse((cache / artifact['filename']).exists())

    @unittest.skipUnless(hasattr(os, 'mkfifo'), 'POSIX special-node fixture')
    def test_metadata_and_cached_archive_fifo_refuse_without_blocking(self):
        fifo = self.root / 'not-a-regular-input'
        os.mkfifo(fifo)
        # A subprocess timeout keeps a regression from hanging the test suite.
        for operation in ('read', 'archive'):
            code = ("import sys;sys.path.insert(0,sys.argv[1]);import package_beta_dependencies as p;"
                    "path=sys.argv[2];"
                    + ("p.read(path)" if operation == 'read' else
                       "p.verified_archive(path,dict(bytes=1,sha256='0'*64)).__enter__()"))
            with self.subTest(operation=operation):
                result = subprocess.run([sys.executable, '-c', code, str(package.ROOT / 'tools'), str(fifo)],
                                        capture_output=True, timeout=5, check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(b'ValueError', result.stderr)
                self.assertNotIn(b'Traceback', result.stdout)

    def test_concurrent_cache_file_is_never_overwritten(self):
        artifact = self.artifact('python')
        cache = self.root / 'contended-cache'
        cache.mkdir()
        def opener(*args, **kwargs):
            (cache / artifact['filename']).write_bytes(b'UNRELATED CONCURRENT FILE')
            return Response(self.payloads['python'])
        with self.assertRaises(FileExistsError):
            package.obtain(artifact, cache, opener)
        self.assertEqual((cache / artifact['filename']).read_bytes(), b'UNRELATED CONCURRENT FILE')

    @unittest.skipIf(__import__('os').name == 'nt', 'POSIX symlink fixture; actual Windows guards are tested by native suites')
    def test_output_and_cache_link_ancestors_refuse(self):
        outside = self.root / 'outside'
        outside.mkdir()
        link = self.root / 'linked'
        link.symlink_to(outside, target_is_directory=True)
        with self.assertRaises(ValueError):
            package.bundle(link, self.cache, self.profile)
        with self.assertRaises(ValueError):
            package.obtain(self.artifact('python'), link)
        self.assertEqual(list(outside.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
