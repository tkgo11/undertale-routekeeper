"""Synthetic contracts only. No native capture, input, Steam or gameplay execution."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw
import screen_verify as v


class ScreenTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.image = Image.new('RGB', (320, 240), 'black')
        d = ImageDraw.Draw(self.image)
        d.rectangle((16, 16, 303, 219), outline='white', width=3)
        d.rectangle((40, 46, 45, 55), fill='white')  # owned synthetic glyph
        self.file('actual.png', self.image)
        self.file('expected.png', self.image)
        self.a = dict(id='korean-visual', scenario='korean', kind='visual', actual='actual.png', actualSha256=self.sha('actual.png'),
                      reference=dict(file='expected.png', sha256=self.sha('expected.png'), provenance=dict(
                          source='owned synthetic pixels', generatorVersion='fixture-v1', sourceHashes={'fixture':'a'*64},
                          locale='ko', font='galmuri14', scene='menu', kind='synthetic')))
        self.manifest = dict(schema=1, kind='synthetic', runId='fixture', assertions=[self.a])

    def file(self, name, image):
        (self.root/name).write_bytes(v.png_bytes(image))

    def sha(self, name):
        return v.digest((self.root/name).read_bytes())

    def run_case(self, manifest=None, output='run'):
        (self.root/'input.json').write_bytes(v.canonical(manifest or self.manifest))
        return v.verify(self.root/'input.json', self.root/output)

    def visual(self, data):
        return next(r for r in data['assertions'] if r['scope'] == 'visual')

    def changed(self, action):
        action(ImageDraw.Draw(self.image))
        self.file('actual.png', self.image)
        self.a['actualSha256'] = self.sha('actual.png')

    def test_identical_visual_not_gameplay(self):
        data = self.run_case()
        self.assertEqual(self.visual(data)['result'], 'PASS')
        self.assertEqual(data['result'], 'NOT_RUN')  # missing font/runtime evidence
        self.assertEqual(data['nativeGameplay'], 'NOT_RUN')

    def test_one_pixel(self):
        self.changed(lambda d:d.point((100, 100), fill='white'))
        r = self.visual(self.run_case())
        self.assertEqual(r['result'], 'NEEDS_REVIEW')
        self.assertEqual(r['metrics']['changed'], 1)
        self.assertEqual(r['metrics']['bbox'], [100, 100, 101, 101])

    def test_missing_glyph_clipping_background_obstruction_locale(self):
        for reason, box, color in [('glyph',(40,46,45,55),'black'), ('clipping',(16,16,40,25),'black'),
                                   ('background',(80,80,120,120),'blue'), ('overlay',(0,0,319,70),'green'),
                                   ('locale',(80,50,90,58),'white')]:
            with self.subTest(reason=reason):
                self.image = Image.open(self.root/'expected.png').convert('RGB')
                self.changed(lambda d:d.rectangle(box, fill=color))
                self.assertEqual(self.visual(self.run_case(output=reason))['result'], 'NEEDS_REVIEW')

    def test_wrong_reference_is_not_pass(self):
        self.file('wrong.png', Image.new('RGB', (320,240),'white'))
        self.a['reference']['file']='wrong.png'; self.a['reference']['sha256']=self.sha('wrong.png')
        self.assertEqual(self.visual(self.run_case())['result'], 'NEEDS_REVIEW')

    def test_proxy_english_never_authoritative_pass(self):
        for kind in ('proxy','synthetic'):
            self.a['reference']['provenance'].update(kind=kind, locale='en', font='native-en')
            self.assertEqual(self.visual(self.run_case(output=kind))['result'], 'NEEDS_REVIEW')

    def test_missing_reference_metadata(self):
        del self.a['reference']['provenance']['font']
        self.assertEqual(self.visual(self.run_case())['result'], 'INVALID_EVIDENCE')

    def test_scaling(self):
        for scale in (1,2,3,8):
            with self.subTest(scale=scale):
                image = self.image.resize((320*scale,240*scale),Image.Resampling.NEAREST)
                logical, meta = v.normalize(image)
                self.assertEqual(logical.tobytes(), self.image.tobytes())
                self.assertEqual(meta['scale'],scale)
        for size in ((480,360),(640,479),(321,240),(640,240),(160,120),(3200,2400)):
            with self.subTest(size=size), self.assertRaises(v.EvidenceError):
                v.normalize(self.image.resize(size))

    def test_resampling_blur_refused(self):
        with self.assertRaises(v.EvidenceError):
            v.normalize(self.image.resize((640,480),Image.Resampling.BILINEAR))

    def test_explicit_letterbox(self):
        boxed = Image.new('RGB',(640,520));boxed.paste(self.image.resize((640,480),Image.Resampling.NEAREST),(0,20))
        logical,_ = v.normalize(boxed, dict(content=[0,20,640,500],cropVerified=True))
        self.assertEqual(logical.tobytes(),self.image.tobytes())
        with self.assertRaises(v.EvidenceError):v.normalize(boxed,dict(content=[0,20,640,500]))
        boxed.putpixel((0,0),(255,255,255))
        with self.assertRaises(v.EvidenceError):v.normalize(boxed,dict(content=[0,20,640,500],cropVerified=True))

    def test_transparency_corrupt_missing_oversize(self):
        for name, raw in [('corrupt.png',b'not png'),('partial.png',v.png_bytes(self.image)[:40]),
                          ('alpha.png',v.png_bytes(Image.new('RGBA',(320,240),(0,0,0,0))))]:
            (self.root/name).write_bytes(raw)
            with self.subTest(name=name),self.assertRaises(v.EvidenceError):v.png(self.root/name,self.sha(name))
        with self.assertRaises(v.EvidenceError):v.png(self.root/'missing.png','a'*64)
        with patch.object(v,'MAX_PIXELS',10),self.assertRaises(v.EvidenceError):v.png(self.root/'actual.png',self.sha('actual.png'))
        with patch.object(v,'MAX_FILE',10):
            # Default args are fixed, so explicit read exercises byte ceiling.
            with self.assertRaises(v.EvidenceError):v.read(self.root/'actual.png',10)

    def test_missing_screenshot_and_hash_mutation(self):
        for name, sha in [('missing.png','a'*64),('actual.png','0'*64)]:
            self.a.update(actual=name, actualSha256=sha)
            self.assertEqual(self.visual(self.run_case(output=name+'run'))['result'],'INVALID_EVIDENCE')

    def test_masks(self):
        other=self.image.copy();other.putpixel((100,100),(255,0,0))
        metrics,_=v.compare(other,self.image,ignore=[dict(rect=[100,100,101,101],reason='calibrated animation')])
        self.assertEqual(metrics['changed'],0)
        with self.assertRaises(v.EvidenceError):v.compare(other,self.image,ignore=[dict(rect=[0,0,320,240],reason='ignore everything')])
        with self.assertRaises(v.EvidenceError):v.compare(other,self.image,regions=[[0,0,321,240]])
        with self.assertRaises(v.EvidenceError):v.compare(other,self.image,ignore=[dict(rect=[0,0,1,1])])

    def test_cursor_structure(self):
        image=Image.new('RGB',(320,240))
        rows=['01100110','11111111','11111111','01111110','00111100','00011000']
        for y,row in enumerate(rows):
            for x,c in enumerate(row):
                if c=='1':image.putpixel((27+x,50+y),(255,0,0))
        features=[dict(id='cursor',kind='heart',rect=[27,50,35,56],color=[255,0,0])]
        self.assertTrue(v.structure(image,features)[0]['matches'])
        self.assertFalse(v.structure(image,[dict(features[0],rect=[27,70,35,76])])[0]['matches'])
        with self.assertRaises(v.EvidenceError):v.structure(image,[dict(features[0],kind='AI-guess')])

    def test_temporal_order_timeout_animation(self):
        other=Image.new('RGB',(320,240),'red')
        self.assertEqual(v.temporal([(0,other),(50,self.image),(100,self.image)],self.image,1000,2)[0],'PASS')
        for frames in [[(0,self.image),(50,self.image),(100,other)],[(0,self.image),(50,other),(100,self.image)],[(0,other),(2000,self.image)],[(0,other),(50,other)]]:
            self.assertEqual(v.temporal(frames,self.image,1000,2)[0],'NEEDS_REVIEW')
        for frames in [[(1,self.image),(1,self.image)],[(2,self.image),(1,self.image)],[(True,self.image),(2,self.image)]]:
            with self.assertRaises(v.EvidenceError):v.temporal(frames,self.image,1000,2)

    def test_temporal_package_preserves_frames(self):
        self.a.update(method='temporal',frames=[dict(file='actual.png',sha256=self.sha('actual.png'),elapsedMs=0),dict(file='actual.png',sha256=self.sha('actual.png'),elapsedMs=50)],timeoutMs=1000,stableFrames=2)
        data=self.run_case(); r=self.visual(data)
        self.assertEqual(r['result'],'PASS')
        self.assertTrue((self.root/'run/review'/r['reviewId']/'frame-01.png').exists())

    def test_paths_links_hardlinks(self):
        with self.assertRaises(v.EvidenceError):v.no_links('//server/share/evidence')
        for name in ('../actual.png','/tmp/a','x\\a','x//a','x/./a','CON.png','a:stream','a./x'):
            with self.subTest(name=name),self.assertRaises(v.EvidenceError):v.child(self.root,name)
        target=self.root/'linked'
        try:target.symlink_to(self.root,target_is_directory=True)
        except OSError as error:self.skipTest('Symlink creation unavailable: '+str(error))
        with self.assertRaises(v.EvidenceError):v.read(target/'actual.png')
        with self.assertRaises(v.EvidenceError):v.verify(target/'input.json',self.root/'out')
        import os
        try:os.link(self.root/'actual.png',self.root/'hard.png')
        except OSError as error:self.skipTest('Hardlink creation unavailable: '+str(error))
        with self.assertRaises(v.EvidenceError):v.read(self.root/'hard.png')

    def test_existing_outputs_untouched(self):
        self.run_case()
        before=v.read(self.root/'run/summary.json')
        with self.assertRaises(v.EvidenceError):self.run_case()
        self.assertEqual(v.read(self.root/'run/summary.json'),before)

    def test_dedup_retains_identities(self):
        self.changed(lambda d:d.point((100,100),fill='white'))
        self.manifest['assertions'].append(dict(self.a,id='second-visual'))
        data=self.run_case()
        rows=[r for r in data['assertions'] if r['scope']=='visual']
        self.assertEqual(len(rows),2)
        self.assertEqual(len(list((self.root/'run/review').iterdir())),1)

    def test_duplicate_assertion_rejected(self):
        self.manifest['assertions'].append(copy.deepcopy(self.a))
        with self.assertRaises(v.EvidenceError):self.run_case()

    def test_json_duplicate_and_nonfinite(self):
        for raw in (b'{"a":1,"a":2}',b'{"a":NaN}',b'[]',b'{'):
            (self.root/'bad.json').write_bytes(raw)
            with self.assertRaises(v.EvidenceError):v.load_json(self.root/'bad.json')

    def test_deterministic_failure_dominates_review(self):
        self.changed(lambda d:d.point((100,100),fill='white'))
        self.manifest['assertions'].append(dict(id='original',scenario='korean',kind='file-sha256',file='actual.png',expected='0'*64))
        data=self.run_case()
        case=self.visual(data)['reviewId']
        data=v.record_review(self.root/'run',case,'accepted','human','reviewer','decision1')
        self.assertEqual(data['result'],'FAIL')
        self.assertEqual(self.visual(data)['result'],'PASS')
        self.assertEqual(self.visual(data)['automaticResult'],'NEEDS_REVIEW')
        self.assertIn('Unexpected layout',self.visual(data)['automaticReason'])
        self.assertEqual(data['nativeGameplay'],'NOT_RUN')

    def test_unknown_gameplay_not_visual_approval(self):
        self.manifest['assertions'].append(dict(id='korean-font',scenario='korean',kind='unobservable'))
        data=self.run_case();case=self.visual(data)['reviewId']
        data=v.record_review(self.root/'run',case,'accepted','ai','chosen-model','review1')
        self.assertEqual(data['result'],'NEEDS_REVIEW')
        self.assertEqual(next(r for r in data['assertions'] if r['id']=='korean-font')['result'],'NEEDS_REVIEW')

    def test_append_review_history_and_conflicts(self):
        data=self.run_case();case=self.visual(data)['reviewId'];run=self.root/'run'
        v.record_review(run,case,'accepted','human','r','id1')
        v.record_review(run,case,'accepted','human','r','id1')
        self.assertEqual(len(list((run/'decisions').iterdir())),1)
        with self.assertRaises(v.EvidenceError):v.record_review(run,case,'defect','ai','r','id1')
        with self.assertRaises(v.EvidenceError):v.record_review(run,case,'defect','ai','r','id2')
        data=v.record_review(run,case,'defect','ai','r','id2','id1')
        self.assertEqual(self.visual(data)['result'],'FAIL')
        self.assertEqual(len(list((run/'decisions').iterdir())),2)
        (run/'decisions/000001.json').write_bytes(b'{}')
        with self.assertRaises((v.EvidenceError,KeyError)):v.summarize(run)

    def test_tampered_evidence_after_review(self):
        data=self.run_case();case=self.visual(data)['reviewId'];run=self.root/'run'
        v.record_review(run,case,'accepted','human','r','id1')
        (run/'review'/case/'actual.png').write_bytes(b'modified')
        with self.assertRaises(v.EvidenceError):v.summarize(run)
        with self.assertRaises(v.EvidenceError):v.export_review(run,self.root/'export',True)

    def test_report_and_sanitized_export_full_workflow(self):
        self.changed(lambda d:d.point((100,100),fill='white'))
        self.manifest['privateComment']='private C:/Users/example SteamID secret'
        data=self.run_case();case=self.visual(data)['reviewId'];run=self.root/'run'
        v.report(run,self.root/'report.html')
        html=(self.root/'report.html').read_text(encoding='utf-8')
        self.assertIn('data:image/png;base64,',html)
        self.assertNotIn('https://',html)
        with self.assertRaises(v.EvidenceError):v.export_review(run,self.root/'noexport')
        v.export_review(run,self.root/'export',True)
        packet=(self.root/'export/packet.json').read_text(encoding='utf-8')
        self.assertNotIn('secret',packet);self.assertNotIn('Users',packet)
        self.assertEqual(json.loads(packet)['cases'][0]['comparisonScope'][0]['method'],'exact')
        self.assertIn('Unexpected layout',json.loads(packet)['cases'][0]['automaticReasons'][0])
        self.assertEqual(json.loads(packet)['cases'][0]['referenceSourceHashes'],[['a'*64]])
        self.assertEqual(json.loads(packet)['cases'][0]['files']['actual.png'],v.digest(v.read(self.root/'export'/case/'actual.png')))
        v.record_review(run,case,'uncertain','ai','offline-reader','ai1')
        data=v.record_review(run,case,'accepted','human','local-reader','human1','ai1')
        self.assertEqual(self.visual(data)['result'],'PASS')
        self.assertEqual(data['result'],'NOT_RUN')

    def test_native_import_blocked_and_capture_focus(self):
        self.manifest['kind']='native-import'
        metadata=dict(schema=1,method='CopyFromScreen',imageSha256=self.sha('actual.png'),clientSize=[320,240],foregroundBefore=True,foregroundAfter=True,ownerPid=1,pid=1,runnerSha256='a'*64,expectedRunnerSha256='a'*64,startedUtc='2026-01-01T00:00:00Z',finishedUtc='2026-01-01T00:00:01Z',dpi=96)
        (self.root/'capture.json').write_bytes(v.canonical(metadata));self.a['capture']='capture.json';self.a['captureSha256']=self.sha('capture.json')
        data=self.run_case()
        self.assertEqual(self.visual(data)['result'],'NEEDS_REVIEW');self.assertEqual(data['result'],'BLOCKED')
        metadata['foregroundAfter']=False
        with self.assertRaises(v.EvidenceError):v.capture_status(metadata,self.image)
        metadata['foregroundAfter']=True;metadata['ownerPid']=2
        with self.assertRaises(v.EvidenceError):v.capture_status(metadata,self.image)

    def test_scenario_contracts_match_existing_ids(self):
        smoke=json.loads((v.ROOT/'tools/runtime/smoke-scenarios.json').read_text(encoding='utf-8'))
        self.assertEqual(set(v.contracts()),{r['id'] for r in smoke})
        self.a['mandatory']=False
        with self.assertRaises(v.EvidenceError):self.run_case()
        self.a['mandatory']=True
        for reserved in ('english-font','korean-safety'):
            self.manifest['assertions']=[self.a,dict(id=reserved,scenario='korean',kind='unobservable')]
            with self.assertRaises(v.EvidenceError):self.run_case(output=reserved)

    def test_configuration_only_and_self_claims(self):
        (self.root/'settings.json').write_bytes(b'{"locale":"ko"}')
        a=dict(id='persisted',kind='configuration',file='settings.json',sha256=self.sha('settings.json'),key='locale',expected='ko')
        self.assertEqual(v.deterministic(a,self.root)['result'],'PASS')
        a['expected']='en';self.assertEqual(v.deterministic(a,self.root)['result'],'FAIL')
        self.assertEqual(v.deterministic(dict(id='HP',kind='internal-state',actual=20,expected=20,independent=True),self.root)['result'],'NEEDS_REVIEW')

    def test_all_verdict_aggregation(self):
        for state in v.VERDICTS:
            self.assertEqual(v.aggregate([dict(result='PASS'),dict(result=state)]),state)
        self.assertEqual(v.aggregate([dict(result='FAIL',mandatory=False),dict(result='PASS')]),'FAIL')
        self.assertEqual(v.aggregate([]),'NOT_RUN')

    def test_cli_roundtrip_and_reference(self):
        output=self.root/'ref'
        v.generate_reference(output,'ko','menu',2)
        ref=v.load_json(output/'reference.json')
        self.assertEqual(ref['provenance']['kind'],'synthetic')
        v.generate_reference(self.root/'en','en','menu',0)
        self.assertEqual(v.load_json(self.root/'en/reference.json')['provenance']['kind'],'proxy')
        (self.root/'input.json').write_bytes(v.canonical(self.manifest))
        proc=subprocess.run([sys.executable,str(v.ROOT/'tools/screen_verify.py'),'verify','--manifest',str(self.root/'input.json'),'--output',str(self.root/'cli-run')],capture_output=True,text=True)
        self.assertEqual(proc.returncode,0,proc.stderr)
        self.assertEqual(json.loads(proc.stdout)['nativeGameplay'],'NOT_RUN')


    def test_calibration_measures_real_fixture_separation(self):
        negative=self.image.copy();ImageDraw.Draw(negative).rectangle((0,0,100,100),fill='red')
        self.file('negative.png',negative)
        calibration=dict(scenario='korean',version='threshold-v1',samples=[
            dict(file='expected.png',sha256=self.sha('expected.png'),classification='positive'),
            dict(file='negative.png',sha256=self.sha('negative.png'),classification='negative')])
        (self.root/'calibration.json').write_bytes(v.canonical(calibration))
        self.a.update(method='bounded-difference',policy=dict(version='threshold-v1',maxRatio=0.001,calibration='calibration.json',calibrationSha256=self.sha('calibration.json')))
        self.changed(lambda d:d.point((100,100),fill='white'))
        data=self.run_case()
        self.assertEqual(self.visual(data)['result'],'PASS')
        self.assertEqual(self.visual(data)['calibration']['positiveRatios'],[0])
        folder=self.root/'run/review'/self.visual(data)['reviewId']
        self.assertEqual(v.read(folder/'calibration-01.png'),v.read(self.root/'negative.png'))
        self.assertEqual(v.load_json(folder/'calibration-private.json'),calibration)
        self.a['policy']['maxRatio']=1
        self.assertEqual(self.visual(self.run_case(output='badcal'))['result'],'INVALID_EVIDENCE')

    def test_unlisted_evidence_and_summary_tamper(self):
        self.run_case();run=self.root/'run'
        (run/'extra.png').write_bytes(b'extra')
        with self.assertRaises(v.EvidenceError):v.summarize(run)
        (run/'extra.png').unlink()
        (run/'summary.json').write_bytes(b'{}')
        with self.assertRaises(v.EvidenceError):v.summarize(run)

    def test_invalid_evidence_cannot_be_reviewed_accepted(self):
        self.a['actualSha256']='0'*64
        data=self.run_case();case=self.visual(data)['reviewId']
        self.assertTrue((self.root/'run/review'/case/'submitted-actual.bin').exists())
        with self.assertRaises(v.EvidenceError):v.record_review(self.root/'run',case,'accepted','human','r','id1')

    def test_capture_constraints(self):
        base=dict(schema=1,method='CopyFromScreen',imageSha256=self.sha('actual.png'),clientSize=[320,240],foregroundBefore=True,foregroundAfter=True,ownerPid=1,pid=1,runnerSha256='a'*64,expectedRunnerSha256='a'*64,startedUtc='2026-01-01T00:00:00Z',finishedUtc='2026-01-01T00:00:01Z',dpi=96)
        for change in [dict(clientSize=[640,480]),dict(finishedUtc='2025-01-01T00:00:00Z'),dict(finishedUtc='2026-01-01T00:01:00Z'),dict(dpi=0),dict(expectedRunnerSha256='b'*64),dict(pid=True),dict(clientSize=[320.0,240]),dict(imageSha256=int('1'*64)),dict(runnerSha256=int('1'*64),expectedRunnerSha256=int('1'*64))]:
            with self.subTest(change=change),self.assertRaises(v.EvidenceError):v.capture_status(dict(base,**change),self.image)
        (self.root/'actual.png.json').write_bytes(v.canonical(base))
        v.generate_reference(self.root/'ref','ko','menu',0)
        v.prepare_import(self.root/'actual.png',self.root/'ref','korean',self.root/'import')
        data=v.verify(self.root/'import/input.json',self.root/'import-run')
        self.assertEqual(data['result'],'BLOCKED')

    def test_reproducible_evidence_and_demo(self):
        first=self.run_case(output='one');second=self.run_case(output='two')
        self.assertEqual(first,second)
        self.assertEqual(v.read(self.root/'one/summary.json'),v.read(self.root/'two/summary.json'))
        data=v.demo(self.root/'demo')
        self.assertEqual(data['result'],'NEEDS_REVIEW')
        self.assertEqual(self.visual(data)['metrics']['changed'],1)

    def test_source_capture_contract_and_no_go_unchanged(self):
        source=(v.ROOT/'tools/runtime/capture-client.ps1').read_text(encoding='utf-8')
        for value in ('GetWindowThreadProcessId','GetDpiForWindow','foregroundBefore','foregroundAfter','ImageFormat]::Png','Assert-RkHash $Executable $ExpectedRunnerSha256','overlayIsolation='):
            self.assertIn(value,source)
        self.assertEqual(source.count('Assert-RkHash $process.Path $ExpectedRunnerSha256'),2)
        source=(v.ROOT/'tools/runtime/run-current-account.ps1').read_text(encoding='utf-8')
        self.assertIn('NO-GO',source)



    def test_budget_partial_publication_cleanup(self):
        with patch.object(v,'MAX_RUN_BYTES',100),self.assertRaises(v.EvidenceError):
            self.run_case()
        self.assertFalse((self.root/'run').exists())
        self.assertFalse(list(self.root.glob('.screen-*')))

    def test_unknown_method_and_bad_schema(self):
        self.a['method']='unsupported-AI-probability'
        self.assertEqual(self.visual(self.run_case())['result'],'NEEDS_REVIEW')
        self.manifest['schema']=2
        with self.assertRaises(v.EvidenceError):self.run_case(output='bad')

    def test_oversized_png_header_and_unsupported_jpeg(self):
        import io
        import struct
        import zlib
        raw=bytearray(v.png_bytes(self.image))
        raw[16:24]=struct.pack('>II',100000,100000)
        raw[29:33]=struct.pack('>I',zlib.crc32(raw[12:29]) & 0xffffffff)
        (self.root/'bomb.png').write_bytes(raw)
        with self.assertRaises(v.EvidenceError):v.png(self.root/'bomb.png',self.sha('bomb.png'))
        stream=io.BytesIO();self.image.save(stream,format='JPEG')
        (self.root/'fake.png').write_bytes(stream.getvalue())
        with self.assertRaises(v.EvidenceError):v.png(self.root/'fake.png',self.sha('fake.png'))

    def test_unsafe_output_ancestor_and_review_lock(self):
        alias=self.root/'alias'
        try:alias.symlink_to(self.root,target_is_directory=True)
        except OSError as error:self.skipTest('Symlink creation unavailable: '+str(error))
        with self.assertRaises(v.EvidenceError):self.run_case(output='alias/run')
        data=self.run_case();case=self.visual(data)['reviewId']
        v.put(self.root/'run/.review-lock',b'prior interrupted writer')
        with self.assertRaises(v.EvidenceError):v.record_review(self.root/'run',case,'accepted','human','r','id1')
        self.assertEqual(v.read(self.root/'run/.review-lock'),b'prior interrupted writer')



    def test_native_temporal_duplicate_receipt_refused(self):
        base=dict(schema=1,method='CopyFromScreen',imageSha256=self.sha('actual.png'),clientSize=[320,240],foregroundBefore=True,foregroundAfter=True,ownerPid=1,pid=1,runnerSha256='a'*64,expectedRunnerSha256='a'*64,startedUtc='2026-01-01T00:00:00Z',finishedUtc='2026-01-01T00:00:00.010Z',dpi=96)
        (self.root/'capture.json').write_bytes(v.canonical(base))
        self.manifest['kind']='native-import'
        self.a.update(capture='capture.json',captureSha256=self.sha('capture.json'),method='temporal',timeoutMs=1000,stableFrames=2,
                      frames=[dict(file='actual.png',sha256=self.sha('actual.png'),capture='capture.json',captureSha256=self.sha('capture.json'),elapsedMs=i*50) for i in range(2)])
        self.assertEqual(self.visual(self.run_case())['result'],'INVALID_EVIDENCE')

    def test_require_pass_exit_not_success_from_visual(self):
        (self.root/'input.json').write_bytes(v.canonical(self.manifest))
        proc=subprocess.run([sys.executable,str(v.ROOT/'tools/screen_verify.py'),'verify','--manifest',str(self.root/'input.json'),'--output',str(self.root/'cli-fail'),'--require-pass'],capture_output=True,text=True)
        self.assertEqual(proc.returncode,1)
        self.assertEqual(json.loads(proc.stdout)['result'],'NOT_RUN')



    def test_game_sized_file_identity_streaming(self):
        path=self.root/'synthetic-data.win'
        with path.open('wb') as stream:stream.truncate(17*1024*1024)
        expected=v.hashlib.sha256(bytes(17*1024*1024)).hexdigest()
        a=dict(id='data',kind='file-sha256',file=path.name,expected=expected)
        self.assertEqual(v.deterministic(a,self.root)['result'],'PASS')
        with self.assertRaises(v.EvidenceError):v.hash_file(path,1024)



    def test_export_strips_embedded_profile_and_text(self):
        import io
        from PIL.PngImagePlugin import PngInfo
        stream=io.BytesIO();metadata=PngInfo();metadata.add_text('private','private-account-label')
        exif=Image.Exif();exif[0x010e]='private-account-exif'
        self.image.save(stream,format='PNG',pnginfo=metadata,icc_profile=b'private-account-profile',exif=exif)
        (self.root/'actual.png').write_bytes(stream.getvalue());self.a['actualSha256']=self.sha('actual.png')
        data=self.run_case();case=self.visual(data)['reviewId']
        v.export_review(self.root/'run',self.root/'export',True)
        for name in ('actual.png','normalized.png','comparison.png'):
            raw=v.read(self.root/'export'/case/name)
            with Image.open(io.BytesIO(raw)) as image:
                self.assertNotIn('icc_profile',image.info)
                self.assertNotIn('private',image.info)
                self.assertNotIn('exif',image.info)
        with Image.open(self.root/'run/review'/case/'actual.png') as original:
            self.assertIn('icc_profile',original.info)
            self.assertIn('exif',original.info)



    def test_post_publication_failure_preserves_original_error_and_evidence(self):
        with patch.object(v,'summarize',side_effect=v.EvidenceError('post-publication validation failure')):
            with self.assertRaisesRegex(v.EvidenceError,'post-publication validation failure'):
                self.run_case()
        self.assertTrue((self.root/'run/summary.json').exists())
        self.assertFalse(list(self.root.glob('.screen-*')))
        self.assertEqual(v.summarize(self.root/'run')['nativeGameplay'],'NOT_RUN')



    def test_hash_metadata_requires_strings_not_numeric_coercion(self):
        number=int('1'*64)
        self.assertFalse(v.valid_sha(number))
        self.assertFalse(v.valid_sha(None))
        self.assertFalse(v.valid_sha(True))
        self.assertTrue(v.valid_sha('1'*64))
        self.a['reference']['provenance']['sourceHashes']={'numeric':number,'string':'a'*64}
        self.assertEqual(self.visual(self.run_case())['result'],'INVALID_EVIDENCE')
        self.a['reference']['provenance']['sourceHashes']={'valid':'a'*64}
        self.manifest['identities']={'candidateSha256':number}
        with self.assertRaises(v.EvidenceError):self.run_case(output='bad-identity')
        self.assertFalse((self.root/'bad-identity').exists())

    def test_review_cannot_supersede_nonexistent_or_change_request_binding(self):
        data=self.run_case();case=self.visual(data)['reviewId'];run=self.root/'run'
        with self.assertRaises(v.EvidenceError):v.record_review(run,case,'accepted','human','r','id1','nonexistent')
        self.assertEqual(list((run/'decisions').iterdir()),[])
        v.record_review(run,case,'accepted','human','r','id1')
        with self.assertRaises(v.EvidenceError):v.record_review(run,case,'accepted','human','r','id1','nonexistent')
        v.record_review(run,case,'uncertain','human','r','id2','id1')
        repeated=v.record_review(run,case,'uncertain','human','r','id2','id1')
        self.assertEqual(repeated['decisions'],2)



    def test_deterministic_assertions_execute_before_visual_analysis(self):
        self.manifest['assertions'].append(dict(id='original',scenario='korean',kind='file-sha256',file='actual.png',expected='0'*64))
        observed=[];original_deterministic=v.deterministic;original_visual=v.visual
        def deterministic(*args,**kwargs):
            observed.append('deterministic');return original_deterministic(*args,**kwargs)
        def visual(*args,**kwargs):
            observed.append('visual');return original_visual(*args,**kwargs)
        with patch.object(v,'deterministic',side_effect=deterministic),patch.object(v,'visual',side_effect=visual):
            data=self.run_case()
        self.assertEqual(observed,['deterministic','visual'])
        self.assertEqual(data['result'],'FAIL')


if __name__=='__main__':unittest.main()
