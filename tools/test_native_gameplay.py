"""Independent synthetic native-contract/evidence mutations. No Windows/game execution."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from PIL import Image

import native_gameplay as n
import windows_e2e as e
import screen_verify as s


class NativeContracts(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name).resolve();(self.root/'references').mkdir()
        self.before=Image.new('RGB',(320,240),'black')
        self.after=self.before.copy();self.after.putpixel((32,40),(255,255,255))
        refs={}
        for name,image in [('before',self.before),('after',self.after)]:
            file='references/'+name+'.png';s.put(self.root/file,s.png_bytes(image))
            refs[name]=dict(source='privately-authentic',reviewer='SYNTHETIC_TEST_NOT_NATIVE',scope='scene-navigation-only',file=file,sha256=s.hash_file(self.root/file))
        self.plan=dict(schema=1,id='test-plan',version='v1',case='original',runnerSha256=e.lab.RUNNER_SHA,dataSha256=e.lab.DATA_SHA,
                       scope='non-destructive-ui',retries=0,scenes=refs,steps=[dict(scenario='startup',before='before',after='after',action='confirm',holdMs=50,timeoutMs=1000,maxFrames=5,stableFrames=2)])
        self.path=self.root/'plan.json';self.save()

    def save(self):
        self.path.write_text(json.dumps(self.plan),encoding='utf-8',newline='\n')

    def frame(self,name,image):
        p=self.root/name;s.put(p,s.png_bytes(image))
        s.put_json(Path(str(p)+'.json'),dict(schema=1,method='CopyFromScreen',imageSha256=s.hash_file(p),clientSize=list(image.size),foregroundBefore=True,foregroundAfter=True,pid=42,ownerPid=42,runnerSha256=e.lab.RUNNER_SHA,expectedRunnerSha256=e.lab.RUNNER_SHA,processStartedUtc='2026-01-01T00:00:00Z',startedUtc='2026-01-01T00:00:01Z',finishedUtc='2026-01-01T00:00:01.001Z',dpi=96))
        return p

    def test_valid_then_one_pixel_mutation_then_restored(self):
        frame=self.frame('good.png',self.after)
        self.assertEqual(n.match(self.path,'original','after',frame,42,'2026-01-01T00:00:00Z')['result'],'MATCH')
        wrong=self.after.copy();wrong.putpixel((100,100),(255,0,0))
        bad=self.frame('bad.png',wrong)
        result=n.match(self.path,'original','after',bad)
        self.assertEqual(result['result'],'NEEDS_REVIEW');self.assertEqual(result['metrics']['changed'],1)
        self.assertEqual(n.match(self.path,'original','after',frame)['result'],'MATCH')

    def test_native_client_subgrid_pixels_are_never_silently_downsampled(self):
        for name in ('before','after'):
            image=Image.new('RGB',(640,480),'black')
            image.putpixel((31 if name=='after' else 33,41),(255,255,255))
            file=self.root/self.plan['scenes'][name]['file'];file.write_bytes(s.png_bytes(image))
            self.plan['scenes'][name].update(space='client-pixels',sha256=s.hash_file(file))
            if name=='after':actual=image
        self.save();frame=self.frame('native-size.png',actual)
        with self.assertRaises(s.EvidenceError):s.normalize(actual)
        result=n.match(self.path,'original','after',frame)
        self.assertEqual(result['result'],'MATCH');self.assertFalse(result['geometry']['resampled'])
        s.put_json(self.root/'native-plan.json',self.plan)
        view=n.review_frame(self.root,self.plan,'original',frame.name,'after','english','client-review')
        self.assertEqual(next(a['result'] for a in view['assertions'] if a['scope']=='visual'),'NEEDS_REVIEW')
        comparison=next((self.root/'client-review').rglob('comparison.png'))
        self.assertEqual(s.png(comparison,s.hash_file(comparison))[0].size,(1920,480))
        with self.assertRaises(s.EvidenceError):s.normalize(actual,dict(space='client-pixels',content=[0,0,640,480]))

    def test_wrong_case_build_proxy_action_and_limits(self):
        for change in [lambda p:p.update(case='patched'),lambda p:p.update(runnerSha256='a'*64),
                       lambda p:p['scenes']['before'].update(source='synthetic'),
                       lambda p:p['steps'][0].update(action='save'),lambda p:p['steps'][0].update(scenario='forced'),
                       lambda p:p['steps'][0].update(maxFrames=True),lambda p:p.update(retries=1)]:
            original=copy.deepcopy(self.plan);change(self.plan);self.save()
            with self.assertRaises(e.StopRun):n.load_plan(self.path,'original')
            self.plan=original;self.save();n.load_plan(self.path,'original')

    def test_input_requires_actual_distinct_response(self):
        self.plan['scenes']['after']=copy.deepcopy(self.plan['scenes']['before']);self.save()
        with self.assertRaisesRegex(e.StopRun,'observable response'):n.load_plan(self.path,'original')

    def test_frame_identity_hash_metadata_and_geometry_mutations(self):
        frame=self.frame('capture.png',self.after)
        with self.assertRaisesRegex(e.StopRun,'process mismatch'):n.match(self.path,'original','after',frame,99)
        with self.assertRaisesRegex(e.StopRun,'start mismatch'):n.match(self.path,'original','after',frame,42,'WRONG')
        frame.write_bytes(b'CORRUPTED')
        with self.assertRaises(s.EvidenceError):n.match(self.path,'original','after',frame)
        scaled=self.after.resize((640,480),Image.Resampling.NEAREST)
        self.assertEqual(n.match(self.path,'original','after',self.frame('scaled.png',scaled))['result'],'MATCH')
        with self.assertRaises(s.EvidenceError):n.match(self.path,'original','after',self.frame('bad-scale.png',self.after.resize((480,360))))

    def test_reference_traversal_and_link_rejection(self):
        self.plan['scenes']['before']['file']='../outside.png';self.save()
        with self.assertRaises(e.StopRun):n.load_plan(self.path,'original')
        self.plan['scenes']['before']['file']='references/before.png';self.save()
        file=self.root/'references/before.png';file.unlink()
        try:file.symlink_to(self.root/'references/after.png')
        except OSError:self.skipTest('Native link privilege unavailable')
        with self.assertRaises(s.EvidenceError):n.load_plan(self.path,'original')

    def test_stage_and_changed_reference(self):
        work=self.root/'stage';work.mkdir();n.stage_plan(self.path,'original',work)
        self.assertEqual(n.load_plan(work/'native-plan.json','original'),self.plan)
        with self.assertRaises(s.EvidenceError):n.stage_plan(self.path,'original',work)
        (self.root/'references/before.png').write_bytes(b'CHANGED')
        with self.assertRaises(s.EvidenceError):n.load_plan(self.path,'original')

    def test_independent_settings_observer_never_gameplay(self):
        path=self.root/'routekeeper.ini';path.write_text('[settings]\nlocale=ko\n',encoding='utf-8',newline='\n')
        self.assertEqual(n.observe_settings(path,'settings','locale','ko')['result'],'PASS')
        self.assertEqual(n.observe_settings(path,'settings','locale','en')['result'],'FAIL')
        snapshot=self.root/'snapshots/routekeeper.ini';snapshot.parent.mkdir()
        captured=n.observe_settings(path,'settings','locale','ko',snapshot)
        path.write_text('[settings]\nlocale=en\n',encoding='utf-8',newline='\n')
        self.assertEqual(n.observe_settings(snapshot,'settings','locale','ko'),captured)

        with self.assertRaises(e.StopRun):n.observe_settings(self.root/'file0','x','y','z')

    def test_native_report_evidence_and_review_cannot_create_gameplay_pass(self):
        work=self.root/'session';work.mkdir();n.stage_plan(self.path,'original',work)
        # Use distinct before/after captures and source-independent transition pixels.
        before=self.frame('before.png',self.before);after=self.frame('after.png',self.after)
        metadata=s.load_json(Path(str(after)+'.json'));metadata.update(startedUtc='2026-01-01T00:00:02Z',finishedUtc='2026-01-01T00:00:02.001Z')
        Path(str(after)+'.json').write_text(json.dumps(metadata),encoding='utf-8',newline='\n')
        early_before=self.frame('before-first.png',self.before);early_after=self.frame('after-first.png',self.after)
        for p,t in [(early_before,'00:00:00.5'),(early_after,'00:00:01.5')]:
            meta=s.load_json(Path(str(p)+'.json'));meta.update(startedUtc='2026-01-01T'+t+'Z',finishedUtc='2026-01-01T'+t+'01Z')
            Path(str(p)+'.json').write_text(json.dumps(meta),encoding='utf-8',newline='\n')
        for p in [before,after,early_before,early_after]:
            for file in [p,Path(str(p)+'.json')]:s.put(work/file.name,s.read(file))
        observation=dict(kind='WINDOWS_GAMEPLAY_OBSERVATIONS',case='original',pid=42,processStartedUtc='2026-01-01T00:00:00Z',planSha256=s.hash_file(work/'native-plan.json'),execution='OBSERVED_TRANSITIONS',steps=[dict(index=0,before='before.png',after='after.png',beforeFrames=['before-first.png','before.png'],afterFrames=['after-first.png','after.png'],dispatch=dict(kind='WINDOW_MESSAGE_DISPATCH',key='confirm',startedUtc='2026-01-01T00:00:01.01Z',finishedUtc='2026-01-01T00:00:01.1Z',requestedHeldMs=50))])
        s.put_json(work/'native-observations.json',observation);s.put_json(work/'native-observations-integrity.json',dict(sha256=s.hash_file(work/'native-observations.json')))
        result=n.finalize(work)
        self.assertEqual(result['result'],'NEEDS_REVIEW');self.assertEqual(result['gameplay'],'UNVERIFIED')
        self.assertTrue((work/'review-0.html').exists())
        v=s.summarize(work/'review-0');review=next(a['reviewId'] for a in v['assertions'] if a['scope']=='visual')
        accepted=s.record_review(work/'review-0',review,'accepted','human','synthetic-reviewer','review1')
        self.assertNotEqual(accepted['result'],'PASS')
        self.assertEqual(n.finalize(work,write_review=False)['gameplay'],'UNVERIFIED')
        original=(work/'after.png').read_bytes();(work/'after.png').write_bytes(b'CHANGED AFTER REVIEW')
        with self.assertRaises(s.EvidenceError):n.finalize(work,write_review=False)
        (work/'after.png').write_bytes(original)
        observation['steps'][0]['afterFrames']=['after.png','after.png']
        (work/'native-observations.json').write_bytes(s.canonical(observation))
        (work/'native-observations-integrity.json').write_bytes(s.canonical(dict(sha256=s.hash_file(work/'native-observations.json'))))
        with self.assertRaisesRegex(e.StopRun,'duplicate'):n.finalize(work,write_review=False)

        (work/'native-observations.json').write_bytes(b'{}')
        with self.assertRaises(e.StopRun):n.finalize(work)

    def test_pending_mismatched_frame_preserves_comparison_queue(self):
        work=self.root/'pending';work.mkdir();n.stage_plan(self.path,'original',work)
        wrong=self.frame('wrong-scene.png',self.before)
        for file in [wrong,Path(str(wrong)+'.json')]:s.put(work/file.name,s.read(file))
        observation=dict(kind='WINDOWS_GAMEPLAY_OBSERVATIONS',case='original',pid=42,processStartedUtc='2026-01-01T00:00:00Z',planSha256=s.hash_file(work/'native-plan.json'),execution='BLOCKED',steps=[],pending=dict(frame=wrong.name,scene='after',scenario='startup'))
        s.put_json(work/'native-observations.json',observation);s.put_json(work/'native-observations-integrity.json',dict(sha256=s.hash_file(work/'native-observations.json')))
        result=n.finalize(work)
        self.assertEqual(result['result'],'BLOCKED');self.assertEqual(result['pendingReview'],'pending-review')
        self.assertEqual(len(list((work/'pending-review').rglob('comparison.png'))),1)
        self.assertEqual(len(list((work/'pending-review').rglob('expected.png'))),1)

    def test_forged_or_incomplete_baseline_refuses_before_preparation(self):
        summary=dict(observations=dict(kind='EXPERIMENTAL_NATIVE_GAMEPLAY',case='original',localRecovery='CONTENT_TREE_VERIFIED',copyStable=True,cacheStable=True,registeredStable=True),nativeReport=dict(allPlannedTransitionsObserved=True,steps=[dict(scenario='startup')]))
        with patch.object(e,'report',return_value=(summary,'')),patch.object(e,'verified_preparation',side_effect=AssertionError('No prepare for incomplete baseline')):
            with self.assertRaisesRegex(e.StopRun,'lacks'):e.check_baseline(self.root,self.root)


if __name__=='__main__':unittest.main()
