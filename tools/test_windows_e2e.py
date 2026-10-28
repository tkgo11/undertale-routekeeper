"""Synthetic orchestration and trusted-preparation boundaries, never native gameplay."""
import copy
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import windows_e2e as e
import screen_verify as s


class E2eTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name).resolve()

    def test_full_synthetic_pipeline_all_scenarios_both_cases(self):
        with patch.object(subprocess,'Popen',side_effect=AssertionError('DryRun must not launch anything')):
            result=e.dry_run(self.root/'run')
        self.assertEqual(result['kind'],'SYNTHETIC_DRY_RUN')
        self.assertEqual(result['result'],'NEEDS_REVIEW')
        self.assertEqual(result['nativeGameplay'],'NOT_RUN')
        self.assertEqual([x['case'] for x in result['outcomes']],['original','patched'])
        for outcome in result['outcomes']:
            self.assertEqual(len(outcome['scenarios']),8)
        rows=e.Journal.read(self.root/'run')
        self.assertIn('INPUT_DISPATCHED',{r['state'] for r in rows})
        self.assertNotIn('settings',{r.get('key') for r in rows if r.get('case')=='original'})
        self.assertIn('RECOVERY_BOUNDARY_SIMULATED',{r['state'] for r in rows})
        self.assertTrue((self.root/'run/report.html').exists())
        visual=self.root/'run/patched-forced/verified'
        data=s.summarize(visual);case=next(r['reviewId'] for r in data['assertions'] if r['scope']=='visual')
        accepted=s.record_review(visual,case,'accepted','ai','synthetic-reviewer','review1')
        self.assertNotEqual(accepted['result'],'PASS')
        self.assertEqual(accepted['nativeGameplay'],'NOT_RUN')
        s.export_review(visual,self.root/'packet',True)

    def test_failure_paths_stop_baseline_before_patched(self):
        for failure in ('focus','identity','abort','crash','unknown-scene','timeout'):
            with self.subTest(failure=failure):
                result=e.dry_run(self.root/failure,failure)
                self.assertEqual(result['result'],'BLOCKED')
                self.assertEqual(len(result['outcomes']),1)
                rows=e.Journal.read(self.root/failure)
                self.assertEqual(rows[-2]['state'],'INPUT_RELEASED_PROCESS_STOP_REQUESTED')
                self.assertEqual(rows[-1]['state'],'RECOVERY_BOUNDARY_SIMULATED')

    def test_wrong_image_escalates_not_silent_success(self):
        result=e.dry_run(self.root/'wrong-image','bad-image')
        self.assertEqual(result['result'],'NEEDS_REVIEW')
        self.assertEqual(len(result['outcomes']),1)
        visual=s.summarize(self.root/'wrong-image/original-startup/verified')
        self.assertEqual(next(r['result'] for r in visual['assertions'] if r['scope']=='visual'),'NEEDS_REVIEW')
        self.assertEqual(next(r['metrics']['changed'] for r in visual['assertions'] if r['scope']=='visual'),1)

    def test_policy_session_binding_missing_consent(self):
        with self.assertRaises(e.StopRun):e.consent('session','nonce',None)
        receipt=e.consent('session','nonce',e.POLICY_VERSION)
        e.validate_consent(receipt,'session','nonce')
        self.assertNotIn('owner',receipt)
        for a,b in [('other','nonce'),('session','other')]:
            with self.assertRaises(e.StopRun):e.validate_consent(receipt,a,b)

    def test_watchdog_always_stops_owned_adapter(self):
        adapter=e.FakeAdapter(self.root);journal=e.Journal(self.root/'watch')
        ticks=iter([0,121])
        result=e.ScenarioRunner(adapter,journal,clock=lambda:next(ticks)).run(['startup'],'original')
        self.assertEqual(result['execution'],'BLOCKED')
        self.assertFalse(adapter.live);self.assertFalse(adapter.held)
        self.assertEqual(adapter.calls,[('stop',)])

    def test_held_inputs_released_after_injected_exception(self):
        adapter=e.FakeAdapter(self.root);journal=e.Journal(self.root/'key')
        def broken_key(key,hold):
            adapter.held.add(key);raise e.StopRun('synthetic failure between press/release')
        adapter.key=broken_key
        result=e.ScenarioRunner(adapter,journal).run(['startup','keyboard'],'original')
        self.assertEqual(result['execution'],'BLOCKED');self.assertFalse(adapter.held)

    def test_journal_corruption_and_existing_output(self):
        journal=e.Journal(self.root/'journal');journal.event('INITIAL');journal.event('NEXT')
        (journal.root/'events/000001.json').write_bytes(b'{}')
        with self.assertRaises((KeyError,e.StopRun)):e.Journal.read(journal.root)
        with self.assertRaises(FileExistsError):e.Journal(journal.root)

    def test_profile_and_harness_identity_refusal(self):
        expected=e.profile();self.assertEqual(expected['Status'],'InspectedOnly')
        with self.assertRaises(e.StopRun):e.check_pins({})
        pins=e.source_pins();e.check_pins(pins)
        pins['tools/windows_e2e.py']='0'*64
        with self.assertRaises(e.StopRun):e.check_pins(pins)

    def test_no_native_certification_on_linux(self):
        if sys.platform=='win32':self.skipTest('Non-Windows refusal only')
        (self.root/'receipt.json').write_bytes(s.canonical({'kind':'NATIVE_NON_GAME_SELFTEST'}))
        with self.assertRaises(e.StopRun):e.check_native_test(self.root)

    def test_scenario_bounds_and_registry(self):
        self.assertEqual(set(e.plans()),set(s.contracts()))
        original=e.plans();bad=copy.deepcopy(original)
        bad['keyboard']['steps'][0]['holdMs']=100000
        with patch.object(s,'load_json',return_value={'scenarios':bad}),patch.object(s,'contracts',return_value=original):
            with self.assertRaises(e.StopRun):e.plans()
        self.assertTrue(original['startup']['blockedReason'])
        self.assertTrue(original['forced']['blockedReason'])

    def test_required_assertion_contract_changes_invalidate_preparation(self):
        pins=e.source_pins()
        for name in ('tools/runtime/screen-contracts.json','tools/runtime/smoke-scenarios.json'):
            self.assertIn(name,pins)
        for name in pins:
            path=self.root/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(name.encode('utf-8'))
        with patch.object(e,'ROOT',self.root):
            original=e.source_pins();e.check_pins(original)
            file=self.root/'tools/runtime/screen-contracts.json'
            raw=file.read_bytes();file.write_bytes(b'CHANGED MANDATORY ASSERTIONS')
            with self.assertRaises(e.StopRun):e.check_pins(original)
            file.write_bytes(raw);e.check_pins(original)

    def test_prepare_refuses_reused_and_unknown_inputs(self):
        existing=self.root/'existing';existing.mkdir()
        with self.assertRaises(e.StopRun):e.prepare(self.root/'archive.zip',existing,self.root/'cli',self.root/'builder')
        with patch.object(e.lab,'prepare',side_effect=ValueError('Unknown archive')):
            with self.assertRaises(ValueError):e.prepare(self.root/'archive.zip',self.root/'new',self.root/'cli',self.root/'builder')

    def test_command_timeout_and_failure_retains_private_logs(self):
        with self.assertRaises(e.StopRun):e.bounded_command([sys.executable,'-c','raise SystemExit(7)'],self.root/'failed.log',2)
        self.assertTrue((self.root/'failed.log').exists())
        with self.assertRaises(e.StopRun):e.bounded_command([sys.executable,'-c','import time;time.sleep(10)'],self.root/'timeout.log',.1)

    def test_report_does_not_interpret_zero_exit_or_process_as_pass(self):
        data=e.dry_run(self.root/'report');payload,page=e.report(self.root/'report')
        self.assertEqual(payload,data)
        self.assertIn('SYNTHETIC_DRY_RUN',page)
        self.assertNotIn('NATIVE_RUNTIME_PASS',page)



    def test_synthetic_state_matching_cannot_teleport(self):
        adapter=e.FakeAdapter(self.root);adapter.launch('original')
        self.assertFalse(adapter.match('forced-warning'))
        self.assertEqual(adapter.current,'title')
        with self.assertRaises(e.StopRun):adapter.key('settings',50)
        adapter.stop();self.assertFalse(adapter.held)



    def test_native_probe_report_preserves_missing_baseline_and_unknown_state(self):
        from PIL import Image
        work=self.root/'probe';root=work/'active-session';root.mkdir(parents=True)
        raw=s.png_bytes(Image.new('RGB',(320,240),'black'));s.put(root/'original.png',raw)
        metadata=dict(schema=1,method='CopyFromScreen',imageSha256=s.digest(raw),clientSize=[320,240],foregroundBefore=True,foregroundAfter=True,pid=1,ownerPid=1,runnerSha256='a'*64,expectedRunnerSha256='a'*64,startedUtc='2026-01-01T00:00:00Z',finishedUtc='2026-01-01T00:00:01Z',dpi=96)
        s.put_json(root/'original.png.json',metadata)
        data=dict(kind='EXPERIMENTAL_ORIGINAL_STARTUP_PROBE',processObserved=True,result='BLOCKED',localRecovery='SYNTHETIC_TEST_RECEIPT',accountHistory='NOT_RESTORED')
        s.put_json(root/'result.json',data);s.put_json(root/'result-integrity.json',dict(sha256=s.hash_file(root/'result.json')))
        summary=e.ingest_probe(work)
        self.assertEqual(summary['result'],'BLOCKED')
        self.assertEqual(summary['scenarios']['forced'],'NOT_RUN')
        capture=next(r for r in summary['screenVerification']['assertions'] if r['scope']=='visual')
        self.assertEqual(capture['result'],'NEEDS_REVIEW')
        accepted=s.record_review(root/'screen-review',capture['reviewId'],'accepted','ai','synthetic','accept')
        self.assertNotEqual(accepted['result'],'PASS')
        self.assertTrue((root/'complete-report.html').exists())
        self.assertEqual(e.report(work)[0],e.report(root)[0])
        integrity=root/'result-integrity.json';original_integrity=integrity.read_bytes()
        integrity.write_bytes(b'{"sha256":"WRONG"}')
        with self.assertRaises(e.StopRun):e.report(work)
        integrity.write_bytes(original_integrity)
        (root/'complete-report.json').write_bytes(b'{}')
        with self.assertRaises(e.StopRun):e.report(root)

    def test_scheduler_result_seal_rejects_modified_success(self):
        e.dry_run(self.root/'sealed')
        (self.root/'sealed/result.json').write_bytes(b'{"result":"PASS"}')
        with self.assertRaises(e.StopRun):e.report(self.root/'sealed')


class RoutingAndPrerequisiteTests(unittest.TestCase):
    setUp = E2eTests.setUp
    # Independent filesystem layouts; no process creation by the report resolver.
    def test_public_and_direct_dry_run_paths(self):
        work=self.root/'public';work.mkdir()
        e.dry_run(work/'execution')
        self.assertEqual(e.resolve_report(work),work/'execution')
        self.assertEqual(e.report(work)[0],e.report(work/'execution')[0])
        (work/'active-session').mkdir()
        with self.assertRaises(e.StopRun):e.report(work)

    def test_missing_partial_mixed_and_linked_reports(self):
        with self.assertRaises(e.StopRun):e.report(self.root)
        (self.root/'result.sha256').write_text('0'*64,encoding='utf-8',newline='\n')
        with self.assertRaises((e.StopRun,OSError)):e.report(self.root)
        (self.root/'result.sha256').unlink()
        real=self.root/'real';e.dry_run(real)
        alias=self.root/'alias'
        try:alias.symlink_to(real,target_is_directory=True)
        except OSError:self.skipTest('Native link privilege unavailable')
        with self.assertRaises(s.EvidenceError):e.report(alias)

    def test_probe_public_path_resolution(self):
        E2eTests.test_native_probe_report_preserves_missing_baseline_and_unknown_state(self)
        # The preceding test deliberately corrupts the report. Correct routing
        # must still reject the corruption rather than finding another run.
        with self.assertRaises(e.StopRun):e.report(self.root/'probe')
        self.assertEqual(e.resolve_report(self.root/'probe'),self.root/'probe/active-session')

    def test_prerequisites_do_not_disappear_under_optimization(self):
        import os
        for flag in ([],['-O']):
            for expression in ("e.prerequisites((3,11,9),'11.3.0')", "e.prerequisites((3,12,0),'99.0')", "e.prerequisites((True,12,0),'11.3.0')"):
                code="import sys;sys.path.insert(0,'tools');import windows_e2e as e;"+expression
                result=subprocess.run([sys.executable,*flag,'-c',code],cwd=e.ROOT,env=dict(os.environ,PYTHONOPTIMIZE='1'),capture_output=True,text=True)
                self.assertNotEqual(result.returncode,0)
                self.assertIn('required',result.stderr)
        self.assertEqual(e.prerequisites()['kind'],'PREREQUISITES_ONLY')


if __name__=='__main__':unittest.main()
