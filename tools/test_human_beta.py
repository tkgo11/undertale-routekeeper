"""Synthetic installed-copy preparation; never launches a runner/compiler/Steam."""
import hashlib
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import human_beta as h
import runtime_lab as lab


class HumanPreparationTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name).resolve();self.source=self.root/'installed';self.source.mkdir()
        self.work=self.root/'new-work';self.compiler=self.root/'compiler';self.builder=self.root/'builder.exe'
        self.compiler.write_bytes(b'SYNTHETIC COMPILER');self.builder.write_bytes(b'SYNTHETIC BUILDER')
        self.original={'UNDERTALE.exe':b'SYNTHETIC RUNNER','data.win':b'SYNTHETIC ORIGINAL','audio/theme.ogg':b'SYNTHETIC AUDIO'}
        for name,raw in self.original.items():
            path=self.source/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(raw)
        self.candidate=b'SYNTHETIC PATCHED'
        self.sha=lambda raw:hashlib.sha256(raw).hexdigest()
        self.identity=dict(schema=2,kind='HUMAN_BETA_INSTALLED_COPY',files=[dict(path='Undertale/'+name,size=len(raw),sha256=self.sha(raw)) for name,raw in self.original.items()])
        self.profile=dict(Id='synthetic-only',Status='InspectedOnly',PatchedSha256=self.sha(self.candidate))
        for item in (patch.object(lab,'installed_identity',return_value=self.identity),patch.object(h.e,'profile',return_value=self.profile),patch.object(h.e,'source_pins',return_value={'synthetic':'pin'}),patch.object(h.e,'repository_head',return_value='synthetic-head')):
            item.start();self.addCleanup(item.stop)

    def compile(self,command,log,timeout=900):
        self.assertEqual(timeout,900)
        self.assertEqual(command[0],str(self.builder))
        self.assertEqual(command[1],'build')
        self.assertEqual(Path(command[2]).read_bytes(),self.original['data.win'])
        self.assertEqual(command[4],str(self.compiler))
        log.write_bytes(b'SYNTHETIC MOCKED BUILD')
        Path(command[3]).write_bytes(self.candidate)

    def run_prepare(self,compiler=None):
        with patch.object(h.e,'bounded_command',side_effect=compiler or self.compile):
            return h.prepare(self.source,self.work,self.compiler,self.builder)

    def assert_unsealed(self):
        self.assertFalse((self.work/'prepared.json').exists())
        self.assertFalse((self.work/'prepared.sha256').exists())

    def test_exact_copy_positive_preserves_source_and_seals_not_run(self):
        before={p.relative_to(self.source): (p.read_bytes(),p.stat().st_mode,p.stat().st_mtime_ns) for p in self.source.rglob('*') if p.is_file()}
        record=self.run_prepare()
        self.assertEqual(record['runtime'],'NOT_RUN')
        self.assertEqual(record['inputKind'],'READ_ONLY_INSTALLED_COPY')
        for name,(raw,mode,modified) in before.items():
            path=self.source/name
            self.assertEqual((path.read_bytes(),path.stat().st_mode,path.stat().st_mtime_ns),(raw,mode,modified))
            self.assertEqual((self.work/'original/Undertale'/name).read_bytes(),raw)
            self.assertEqual((self.work/'runs/original'/name).read_bytes(),raw)
            self.assertEqual((self.work/'runs/patched'/name).read_bytes(),self.candidate if name.as_posix()=='data.win' else raw)
        raw=(self.work/'prepared.json').read_bytes()
        self.assertEqual(json.loads(raw),record)
        self.assertEqual((self.work/'prepared.sha256').read_text(encoding='utf-8'),self.sha(raw)+'\n')

    def test_unknown_missing_changed_source_refused_before_work_creation(self):
        for mode in ('extra','missing','changed'):
            with self.subTest(mode=mode):
                path=self.source/'data.win'
                if mode=='extra':(self.source/'unknown.dll').write_bytes(b'UNLISTED')
                elif mode=='missing':path.unlink()
                else:path.write_bytes(b'CHANGED')
                with patch.object(h.e,'bounded_command') as command,self.assertRaises(ValueError):h.prepare(self.source,self.work,self.compiler,self.builder)
                command.assert_not_called();self.assertFalse(self.work.exists())
                (self.source/'unknown.dll').unlink(missing_ok=True);path.write_bytes(self.original['data.win'])

    def test_existing_output_never_clobbered(self):
        self.work.mkdir();sentinel=self.work/'candidate.win';sentinel.write_bytes(b'KEEP')
        with self.assertRaises(ValueError):self.run_prepare()
        self.assertEqual(sentinel.read_bytes(),b'KEEP')

    def test_overlapping_output_never_created(self):
        self.work=self.source/'work'
        with self.assertRaisesRegex(ValueError,'overlap'):self.run_prepare()
        self.assertFalse(self.work.exists())

    def test_linked_source_or_output_ancestor_refused(self):
        alias=self.root/'alias';alias.symlink_to(self.source,target_is_directory=True)
        original=self.source;self.source=alias
        with self.assertRaises(ValueError):self.run_prepare()
        self.source=original;self.work=alias/'work'
        with self.assertRaises(ValueError):self.run_prepare()
        self.assertFalse((original/'work').exists())

    def test_bad_candidate_keeps_pristine_patched_data_unsealed(self):
        def build(*args):
            self.compile(*args);(self.work/'candidate.win').write_bytes(b'WRONG')
        with self.assertRaises(ValueError):self.run_prepare(build)
        self.assertEqual((self.work/'runs/patched/data.win').read_bytes(),self.original['data.win']);self.assert_unsealed()

    def test_candidate_link_refused_without_touching_target(self):
        sentinel=self.root/'outside';sentinel.write_bytes(self.candidate)
        def build(*args):
            (self.work/'candidate.win').symlink_to(sentinel)
        with self.assertRaises(ValueError):self.run_prepare(build)
        self.assertEqual(sentinel.read_bytes(),self.candidate);self.assert_unsealed()

    def test_patched_target_link_or_hardlink_refused(self):
        for hard in (False,True):
            with self.subTest(hard=hard):
                self.work=self.root/('work-hard' if hard else 'work-link')
                sentinel=self.root/('outside-hard' if hard else 'outside-link');sentinel.write_bytes(self.original['data.win'])
                def build(*args):
                    self.compile(*args);target=self.work/'runs/patched/data.win';target.unlink()
                    if hard:os.link(sentinel,target)
                    else:target.symlink_to(sentinel)
                with self.assertRaises(ValueError):self.run_prepare(build)
                self.assertEqual(sentinel.read_bytes(),self.original['data.win']);self.assert_unsealed()

    def test_compiler_failure_retained_without_seal_or_source_change(self):
        def failure(*args):raise h.e.StopRun('synthetic compiler failure')
        with self.assertRaisesRegex(ValueError,'compiler failure'):self.run_prepare(failure)
        self.assert_unsealed();self.assertEqual((self.source/'data.win').read_bytes(),self.original['data.win'])

    def test_source_or_tool_changes_during_build_block_seal(self):
        for changed in (self.source/'data.win',self.builder):
            with self.subTest(changed=changed.name):
                self.work=self.root/('changed-'+changed.name)
                def build(*args):self.compile(*args);changed.write_bytes(b'CHANGED BY SYNTHETIC MOCK')
                with self.assertRaises(ValueError):self.run_prepare(build)
                self.assert_unsealed()
                (self.source/'data.win').write_bytes(self.original['data.win']);self.builder.write_bytes(b'SYNTHETIC BUILDER')

    def test_bounded_exclusive_copy_rejects_truncation_growth_and_hash_mismatch(self):
        source=self.root/'copy-source';source.write_bytes(b'AB')
        for size,digest in ((1,self.sha(b'A')),(3,self.sha(b'ABC')),(2,'0'*64)):
            target=self.root/('copy-'+str(size))
            with self.subTest(size=size),self.assertRaises(ValueError):lab.copy_exact_file(source,target,size,digest)
        target=self.root/'existing';target.write_bytes(b'KEEP')
        with self.assertRaises(FileExistsError):lab.copy_exact_file(source,target,2,self.sha(b'AB'))
        self.assertEqual(target.read_bytes(),b'KEEP')

    def test_oversized_source_and_candidate_refused_without_read(self):
        source=self.source/'data.win'
        with source.open('wb') as stream:stream.truncate(256*1024*1024+1)
        with self.assertRaises(ValueError):self.run_prepare()
        self.assertFalse(self.work.exists())
        source.write_bytes(self.original['data.win'])
        def build(*args):
            self.compile(*args)
            with (self.work/'candidate.win').open('wb') as stream:stream.truncate(256*1024*1024+1)
        with self.assertRaises(ValueError):self.run_prepare(build)
        self.assert_unsealed()

    def test_source_changed_during_copy_is_never_sealed(self):
        original_copy=lab.copy_exact_file
        def changed(source,target,size,digest):
            if target.name=='data.win':
                source.write_bytes(b'SOURCE CHANGED DURING COPY')
            return original_copy(source,target,size,digest)
        with patch.object(lab,'copy_exact_file',side_effect=changed),self.assertRaises(ValueError):self.run_prepare()
        self.assert_unsealed()

    def test_oversized_and_special_metadata_refused(self):
        metadata=self.root/'metadata'
        with metadata.open('wb') as stream:stream.truncate(1024*1024+1)
        with self.assertRaisesRegex(ValueError,'type/size'):lab.read_metadata(metadata)
        if hasattr(os,'mkfifo'):
            fifo=self.root/'metadata-pipe';os.mkfifo(fifo)
            with self.assertRaisesRegex(ValueError,'type/size'):lab.read_metadata(fifo)

    def test_candidate_hardlink_refused(self):
        sentinel=self.root/'outside-candidate';sentinel.write_bytes(self.candidate)
        def build(*args):os.link(sentinel,self.work/'candidate.win')
        with self.assertRaises(ValueError):self.run_prepare(build)
        self.assertEqual(sentinel.read_bytes(),self.candidate);self.assert_unsealed()


if __name__=='__main__':unittest.main()
