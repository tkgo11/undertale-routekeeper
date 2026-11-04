"""Synthetic complete portable package contracts; no native or game execution."""
import hashlib
import json
import os
import shutil
import unittest
from unittest.mock import patch
import zipfile

import test_beta_dependencies as fixtures
import verify_beta_package as package


class Package(unittest.TestCase):
    def setUp(self):
        fixture=fixtures.Dependencies(methodName='runTest');fixture.setUp();self.addCleanup(fixture.doCleanups)
        self.root=fixture.root;self.output=fixture.output
        self.receipt=fixture.bundle()
        self.manifest=fixture.manifest
        self.manifest_hash=hashlib.sha256(fixture.profile.read_bytes()).hexdigest()
        for name in package.REQUIRED:
            path=self.output/name
            if not path.exists():path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(b'SYNTHETIC PACKAGE FILE')
        for name in ('windows-game-files.json','registry.json'):
            shutil.copyfile(package.dependencies.ROOT/'profiles'/name,self.output/'profiles'/name)
        shutil.copytree(package.dependencies.ROOT/'licenses/compiler',self.output/'licenses/compiler')
        self.lock=patch.object(package.dependencies,'load_manifest',return_value=(self.manifest,self.manifest_hash));self.lock.start();self.addCleanup(self.lock.stop)

    def archive(self):
        path=self.root/'portable.zip'
        with zipfile.ZipFile(path,'w') as archive:
            for item in self.output.rglob('*'):
                if item.is_file():archive.write(item,item.relative_to(self.output).as_posix())
        return path

    def test_complete_directory_and_archive_receipt_hashes(self):
        self.assertGreater(package.verify(self.output),len(package.REQUIRED))
        self.assertEqual(package.verify(self.output),package.verify(self.archive()))

    def test_compiler_notices_missing_changed_extra_or_metadata_refused(self):
        source=self.output/'licenses/compiler/roslyn-LICENSE.txt';original=source.read_bytes()
        cases=('missing','changed','extra','provenance')
        for case in cases:
            with self.subTest(case=case):
                metadata=self.output/'licenses/compiler/provenance.json';saved=metadata.read_bytes()
                extra=self.output/'licenses/compiler/unreviewed.txt'
                if case=='missing':source.unlink()
                elif case=='changed':source.write_bytes(original+b'ALTERED')
                elif case=='extra':extra.write_bytes(b'UNREVIEWED NOTICE')
                else:metadata.write_bytes(b'{}')
                for package_path in (self.output,self.archive()):
                    with self.assertRaisesRegex(ValueError,'Compiler notice'):package.verify(package_path)
                source.write_bytes(original);metadata.write_bytes(saved);extra.unlink(missing_ok=True)

    def test_missing_required_or_notices(self):
        files=[*package.REQUIRED,'licenses/NOTICE.md']
        self.assertEqual(package.validate(files),len(files))
        with self.assertRaises(ValueError):package.validate(files[1:])
        with self.assertRaises(ValueError):package.validate(n for n in package.REQUIRED if not n.startswith('licenses/'))

    def test_private_runtime_inputs_aliases_and_raw_archives_refused(self):
        for extra in ('data.win','UNDERTALE.exe','steam_api.dll','file0','System_Information_963','.research/a.txt',
                      'sessions/state.json','../escape','C:/escape','a\\b','/root','integration/../escape',
                      'routekeeper.beta.dll','RouteKeeper.Beta.Windows.exe.','NUL.txt','raw.zip','compiler/art.png','game-audio.ogg','private-shot.png'):
            with self.subTest(extra=extra),self.assertRaises(ValueError):package.validate([*package.REQUIRED,'licenses/NOTICE.md',extra])

    def test_changed_missing_extra_dependency_refused_directory_and_zip(self):
        original=self.output/'python/python.exe'
        original.write_bytes(b'TAMPERED')
        for path in (self.output,self.archive()):
            with self.subTest(path=path.name),self.assertRaises(ValueError):package.verify(path)

    def test_unlisted_dependency_refused(self):
        (self.output/'compiler/unlisted.dll').write_bytes(b'UNLISTED')
        with self.assertRaisesRegex(ValueError,'exact subtree'):package.verify(self.output)

    def test_duplicate_receipt_path_or_wrong_lock_refused(self):
        receipt=self.output/'beta-dependencies-complete.json'
        data=json.loads(receipt.read_text(encoding='utf-8'));data['files'].append(data['files'][0])
        receipt.write_text(json.dumps(data),encoding='utf-8',newline='\n')
        with self.assertRaises(ValueError):package.verify(self.output)
        (self.output/'profiles/beta-dependencies.json').write_bytes(b'{}')
        with self.assertRaisesRegex(ValueError,'lock'):package.verify(self.output)

    def test_unsafe_directory_entry_not_ignored(self):
        path=self.archive()
        with zipfile.ZipFile(path,'a') as archive:archive.writestr('../outside/','')
        with self.assertRaises(ValueError):package.verify(path)

    def test_archive_noncanonical_separators_refused(self):
        path=self.archive()
        with zipfile.ZipFile(path,'a') as archive:archive.writestr('nested//alias.txt',b'ALIAS')
        with self.assertRaisesRegex(ValueError,'Noncanonical'):package.verify(path)

    @unittest.skipIf(os.name=='nt','POSIX link fixture')
    def test_linked_directory_and_archive_ancestor_refused(self):
        link=self.root/'linked';link.symlink_to(self.output,target_is_directory=True)
        with self.assertRaises(ValueError):package.verify(link)
        file=self.output/'unknown';file.symlink_to(self.output/'RouteKeeper.Beta.dll')
        with self.assertRaises(ValueError):package.verify(self.output)

    def test_hardlinked_payload_refused(self):
        os.link(self.output/'RouteKeeper.Beta.dll',self.output/'hardlink.dll')
        with self.assertRaises(ValueError):package.verify(self.output)

    def test_original_game_resource_hash_refused_even_if_renamed(self):
        game=self.output/'profiles/windows-game-files.json'
        data=json.loads(game.read_text(encoding='utf-8'));raw=b'SYNTHETIC PROPRIETARY BYTE CONTROL'
        data['files'][0]['sha256']=hashlib.sha256(raw).hexdigest()
        encoded=json.dumps(data).encode();game.write_bytes(encoded)
        (self.output/'innocent.dll').write_bytes(raw)
        with patch.object(package.runtime_lab,'GAME_MANIFEST_SHA',hashlib.sha256(encoded).hexdigest()),self.assertRaisesRegex(ValueError,'game resource'):package.verify(self.output)

    def test_renamed_patched_candidate_hash_refused(self):
        raw=b'SYNTHETIC PRIVATE PATCHED CANDIDATE'
        registry=[dict(OriginalSha256='0'*64,PatchedSha256=hashlib.sha256(raw).hexdigest(),ExecutableSha256='1'*64)]
        encoded=json.dumps(registry).encode();(self.output/'profiles/registry.json').write_bytes(encoded)
        (self.output/'renamed-candidate.bin').write_bytes(raw)
        reader=package.dependencies.read
        def reviewed(path,maximum=1024*1024):
            if path==package.dependencies.ROOT/'profiles/registry.json':return encoded
            return reader(path,maximum)
        with patch.object(package.dependencies,'read',side_effect=reviewed),self.assertRaisesRegex(ValueError,'game resource'):package.verify(self.output)

    def test_changed_packaged_registry_refused(self):
        (self.output/'profiles/registry.json').write_bytes(b'[]')
        with self.assertRaisesRegex(ValueError,'registry'):package.verify(self.output)

    def test_public_font_image_must_match_reviewed_generated_bytes(self):
        path=self.output/'integration/assets/ui-font.png';path.parent.mkdir(parents=True,exist_ok=True)
        path.write_bytes(b'SYNTHETIC UNKNOWN PRIVATE PIXELS')
        with self.assertRaisesRegex(ValueError,'public image'):package.verify(self.output)

    def test_interpreter_path_tampering_refused_even_with_updated_receipt(self):
        path=self.output/'python/python312._pth';path.write_bytes(b'../../outside\nimport site\n')
        receipt=self.output/'beta-dependencies-complete.json';data=json.loads(receipt.read_text(encoding='utf-8'))
        row=next(r for r in data['files'] if r['path']=='python/python312._pth');row.update(bytes=path.stat().st_size,sha256=hashlib.sha256(path.read_bytes()).hexdigest())
        receipt.write_text(json.dumps(data),encoding='utf-8',newline='\n')
        with self.assertRaisesRegex(ValueError,'interpreter'):package.verify(self.output)


if __name__=='__main__':unittest.main()
