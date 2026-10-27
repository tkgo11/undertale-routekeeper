#!/usr/bin/env python3
"""Bounded Windows orchestration policy, preparation and offline scenario driver.

Native actions are adapters, never implied by a synthetic result. Save recovery
belongs to current-account-state.ps1, not this module.
"""
import argparse
from datetime import datetime, timezone
import html
import json
import re
from pathlib import Path
import subprocess
import sys
import time
import uuid

import runtime_lab as lab
import screen_verify as screen

ROOT = Path(__file__).resolve().parents[1]
KEYS = {'up':38, 'down':40, 'left':37, 'right':39, 'confirm':90, 'cancel':88,
        'enter':13, 'settings':121, 'language':123, 'acknowledge':119}
POLICY = screen.load_json(ROOT/'tools/runtime/experimental-policy.json')
DISCLOSURE = POLICY['disclosure']
POLICY_VERSION = POLICY['id']


class StopRun(screen.EvidenceError):
    pass



def repository_head():
    """Read only commit identity, never credentials; no subprocess in DryRun."""
    git=ROOT/'.git'
    if not git.is_dir():return 'UNKNOWN_GIT_LAYOUT'
    value=screen.read(git/'HEAD',4096).decode('ascii').strip()
    if value.startswith('ref: '):
        reference=value[5:];path=screen.child(git,reference)
        if path.exists():value=screen.read(path,4096).decode('ascii').strip()
        else:
            packed=screen.read(git/'packed-refs',screen.MAX_JSON).decode('ascii')
            matches=[line.split(' ',1)[0] for line in packed.splitlines() if line.endswith(' '+reference)]
            if len(matches)!=1:raise StopRun('Repository commit identity unavailable')
            value=matches[0]
    if not re.fullmatch(r'[a-f0-9]{40}|[a-f0-9]{64}',value):raise StopRun('Malformed repository HEAD')
    return value

def profile():
    profiles = json.loads(screen.read(ROOT/'profiles/registry.json', screen.MAX_JSON))
    found = [p for p in profiles if p['OriginalSha256'] == lab.DATA_SHA and p['ExecutableSha256'] == lab.RUNNER_SHA]
    if len(found) != 1 or found[0]['Status'] not in ('InspectedOnly','VerifiedPatch'):
        raise StopRun('Unique known exact-build profile required; no synthetic approval')
    return found[0]


def plans():
    data = screen.load_json(ROOT/'tools/runtime/e2e-scenarios.json')
    if set(data['scenarios']) != set(screen.contracts()):
        raise StopRun('Smoke and E2E scenario registry drift')
    for name, plan in data['scenarios'].items():
        if plan['risk'] not in ('ui','combat') or not isinstance(plan['steps'], list) or not 1 <= len(plan['steps']) <= 20:
            raise StopRun('Unsupported/bounded scenario policy')
        sequences=[plan['steps']]
        if plan.get('originalSteps') is not None:sequences.append(plan['originalSteps'])
        for steps in sequences:
            if not isinstance(steps,list) or not 1<=len(steps)<=20:raise StopRun('Invalid bounded scenario steps')
            for step in steps:
                screen.token(step['scene']);hold=step.get('holdMs',50)
                if step['action'] not in ('checkpoint',*KEYS) or type(hold) is not int or not 50<=hold<=500:
                    raise StopRun('Unsupported or unbounded input')
    return data['scenarios']


def source_pins():
    files = ['tools/windows_e2e.py','tools/runtime/experimental-policy.json','tools/runtime/e2e-scenarios.json','tools/runtime/test-windows.ps1',
             'tools/runtime/input-window.ps1','tools/runtime/native-selftest.ps1','tools/runtime/experimental-session.ps1',
             'tools/runtime/capture-client.ps1','tools/runtime/safety.ps1',
             'tools/runtime/current-account-state.ps1','tools/runtime/current-account-windows.ps1',
             'profiles/registry.json']
    return {f:screen.hash_file(ROOT/f) for f in files}


def check_pins(pins):
    if pins != source_pins():
        raise StopRun('Harness/profile changed after preparation')


def consent(session, nonce, accepted):
    screen.token(session); screen.token(nonce)
    if accepted != POLICY_VERSION:
        raise StopRun('Explicit per-session experimental consent is missing')
    return dict(schema=1,policy=POLICY_VERSION,session=session,nonce=nonce,
                recordedUtc=datetime.now(timezone.utc).isoformat(), disclosureSha256=screen.digest(DISCLOSURE.encode()),
                accountIsolation='UNPROVEN',scope='non-destructive-smoke', credentialsStored=False)


def validate_consent(record, session, nonce):
    if record.get('policy') != POLICY_VERSION or record.get('session') != session or record.get('nonce') != nonce or record.get('disclosureSha256') != screen.digest(DISCLOSURE.encode()) or record.get('scope') != 'non-destructive-smoke':
        raise StopRun('Consent belongs to a different session/policy')


def bounded_command(command, output, timeout=900):
    """Owned compiler/validator only; .NET builder already bounds child output."""
    with screen.no_links(output).open('xb') as log:
        process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
        started = time.monotonic()
        try:
            while process.poll() is None:
                if time.monotonic()-started > timeout or log.tell() > 16*1024*1024:
                    process.kill(); process.wait(timeout=10)
                    raise StopRun('Compiler timeout/output limit; private log retained')
                time.sleep(.1)
            if output.stat().st_size > 16*1024*1024:raise StopRun('Compiler output exceeded private log budget')
            if process.returncode:
                raise StopRun('Compiler failed; private diagnostic retained')
        finally:
            if process.poll() is None:
                process.kill(); process.wait(timeout=10)


def prepare(archive, output, cli, builder):
    output = screen.no_links(output)
    if output.exists():
        raise StopRun('Preparation output must be new; never overwrite a session')
    expected = profile()
    pins = source_pins()
    # Existing archive validator/extractor owns authenticity and all original files.
    lab.prepare(archive, output)
    candidate = output/'candidate.win'
    try:
        builder=screen.no_links(builder)
        if not builder.is_file():
            if builder != ROOT/'src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll':raise StopRun('Missing explicit builder')
            bounded_command(['dotnet','build','RouteKeeper.slnx','-c','Release'],output/'source-build-private.log')
        bounded_command(['dotnet',str(builder),'build',str(output/'original/Undertale/data.win'),
                         str(candidate),str(screen.no_links(cli)),str(ROOT)], output/'build-private.log')
        if screen.hash_file(candidate) != expected['PatchedSha256']:
            raise StopRun('Candidate differs from the pinned inspected profile; no automatic profile update')
        # Existing builder compiles, serializes, reloads and compares all declared
        # original resources before producing a receipt. Do not fabricate it.
        for kind in ('original','patched'):
            target = output/'runs'/kind/'data.win'
            if kind == 'patched':
                with candidate.open('rb') as source, target.open('wb') as destination:
                    import shutil
                    shutil.copyfileobj(source,destination)
            verify_copy(output,kind)
        lab.verify(output)
        check_pins(pins)
        payload = dict(schema=1,profile=expected['Id'],status=expected['Status'],harness=pins,
                       repositoryHead=repository_head(),originalSha256=lab.DATA_SHA,candidateSha256=expected['PatchedSha256'],runnerSha256=lab.RUNNER_SHA,
                       runtime='NOT_RUN',createdUtc=datetime.now(timezone.utc).isoformat())
        raw=screen.canonical(payload);screen.put(output/'prepared.json',raw)
        screen.put(output/'prepared.sha256',(screen.digest(raw)+'\n').encode())
        return payload
    except BaseException:
        # Keep original inputs and failed compiler evidence; an unsealed lab is
        # never launchable. Cleanup is an explicit separate decision.
        raise


def verify_copy(work,kind):
    expected = profile(); identity=lab.verify(work)
    tree=screen.no_links(Path(work)/'runs'/kind)
    files=[dict(f,path=f['path'][10:]) for f in identity['files'] if f['path'].startswith('Undertale/')]
    for file in files:
        if kind=='patched' and file['path']=='data.win':
            file['sha256']=expected['PatchedSha256'];file['size']=(Path(work)/'candidate.win').stat().st_size
    lab.verify_original_tree(tree,files)


def verified_preparation(work):
    work=screen.no_links(work)
    raw=screen.read(work/'prepared.json',screen.MAX_JSON)
    if screen.read(work/'prepared.sha256',128).decode().strip()!=screen.digest(raw):raise StopRun('Preparation seal mismatch')
    record=screen.decode_json(raw); expected=profile()
    if record['schema']!=1 or record['profile']!=expected['Id'] or record['candidateSha256']!=expected['PatchedSha256'] or record['runnerSha256']!=lab.RUNNER_SHA:
        raise StopRun('Preparation exact identity mismatch')
    check_pins(record['harness']);verify_copy(work,'original');verify_copy(work,'patched')
    return record


class Journal:
    """Append-only scheduler events; save journaling remains in the PS module."""
    def __init__(self,root):
        self.root=screen.no_links(root);self.root.mkdir(parents=True,exist_ok=False,mode=0o700)
        (self.root/'events').mkdir(mode=0o700);self.previous=None;self.sequence=0
    def event(self,state,**facts):
        self.sequence+=1
        row=dict(sequence=self.sequence,previous=self.previous,state=state,**facts)
        raw=screen.canonical(row);screen.put(self.root/'events'/f'{self.sequence:06}.json',raw)
        self.previous=screen.digest(raw)
    @staticmethod
    def read(root):
        directory=screen.no_links(Path(root)/'events');rows=[];previous=None
        for file in sorted(directory.iterdir()):
            if file.name!=f'{len(rows)+1:06}.json':raise StopRun('Scheduler journal gap/unexpected node')
            raw=screen.read(file,screen.MAX_JSON);row=screen.decode_json(raw)
            if row['previous']!=previous or row['sequence']!=len(rows)+1:raise StopRun('Scheduler journal corruption')
            rows.append(row);previous=screen.digest(raw)
        return rows


class FakeAdapter:
    """Explicit synthetic observations; no Windows/game/Steam subprocess."""
    kind='synthetic'
    def __init__(self,root,failure=None):
        self.root=Path(root);self.failure=failure;self.calls=[];self.live=False;self.held=set();self.current='title';self.language='en';self.titleSeen=False
    def guard(self):
        if self.failure in ('focus','identity','abort','crash'):raise StopRun('Synthetic '+self.failure)
    def launch(self,case):self.calls.append(('launch',case));self.live=True;self.current='title'
    def match(self,scene):
        self.guard()
        if scene=='overworld' and self.current=='title' and self.titleSeen:self.current='overworld'
        if scene=='title' and self.current=='title':self.titleSeen=True
        return self.current==scene and self.failure not in ('unknown-scene','timeout')
    def key(self,key,hold):
        self.guard();self.held.add(key);self.calls.append(('key',key))
        if key=='settings' and self.current=='overworld':self.current='settings-'+self.language
        elif key=='cancel' and self.current.startswith('settings-'):self.current='overworld'
        elif key=='language' and self.current.startswith('settings-'):
            self.language='ko' if self.language=='en' else 'en';self.current='settings-'+self.language
        elif key=='down' and self.current=='settings-ko':self.current='settings-ko-row1'
        elif key=='up' and self.current=='settings-ko-row1':self.current='settings-ko'
        elif key=='right' and self.current=='overworld':self.current='overworld-step'
        elif key=='left' and self.current=='overworld-step':self.current='overworld'
        elif key=='acknowledge' and self.current=='risk-warning':self.current='warning-acknowledged'
        else:raise StopRun('Synthetic model refused unsupported state/action')
        self.held.discard(key)
    def fixture(self,name):
        if name in ('battle','warnings','forced'):
            self.current={'battle':'ordinary-battle','warnings':'risk-warning','forced':'forced-warning'}[name]
    def capture(self,folder):
        self.guard();folder.mkdir(mode=0o700)
        scene='menu' if self.current.startswith('settings-') else ('warning' if 'warning' in self.current else 'hud')
        screen.generate_reference(folder/'reference',self.language,scene,0)
        ref=screen.load_json(folder/'reference/reference.json')
        image,raw=screen.png(folder/'reference/reference.png',ref['sha256'])
        if self.failure=='bad-image':image.putpixel((100,100),(255,0,255));raw=screen.png_bytes(image)
        screen.put(folder/'actual.png',raw)
        ref['file']='reference/reference.png'
        return dict(actual='actual.png',actualSha256=screen.digest(raw),reference=ref)
    def stop(self):self.held.clear();self.live=False;self.calls.append(('stop',))


class ScenarioRunner:
    def __init__(self,adapter,journal,deadline=120,clock=time.monotonic):
        self.adapter=adapter;self.journal=journal;self.clock=clock;self.deadline=clock()+deadline
    def checkpoint(self):
        if self.clock()>=self.deadline:raise StopRun('Global watchdog expired')
        self.adapter.guard()
    def run(self,names,case):
        registry=plans();results=[]
        try:
            self.checkpoint();self.adapter.launch(case);self.journal.event('PROCESS_STARTED',case=case,observationKind=self.adapter.kind)
            for name in names:
                plan=registry[name];self.checkpoint()
                steps=plan.get('originalSteps') if case=='original' else plan['steps']
                if steps is None:
                    results.append(dict(id=name,result='NOT_RUN',reason='Mod-only scenario absent from original official runner'));continue
                if self.adapter.kind=='synthetic':
                    self.adapter.fixture(name)
                    if plan['risk']=='combat':self.journal.event('SYNTHETIC_ENCOUNTER_FIXTURE',scenario=name,case=case)
                if self.adapter.kind!='synthetic' and plan.get('blockedReason'):
                    results.append(dict(id=name,result='BLOCKED',reason=plan['blockedReason']));continue
                self.journal.event('SCENARIO_START',scenario=name)
                folder=self.journal.root/(case+'-'+name)
                for index,step in enumerate(steps):
                    self.checkpoint()
                    if not self.adapter.match(step['scene']):raise StopRun('Unrecognized scene or bounded transition timeout; no exploratory input')
                    if step['action']!='checkpoint':
                        self.adapter.key(step['action'],step.get('holdMs',50))
                        self.journal.event('INPUT_DISPATCHED',case=case,scenario=name,key=step['action'],step=index,gameAction='UNPROVEN')
                capture=self.adapter.capture(folder)
                assertion=dict(id=name+'-visual',scenario=name,kind='visual',**capture)
                manifest=dict(schema=1,kind='synthetic' if self.adapter.kind=='synthetic' else 'native-import',runId=case+'-'+name,assertions=[assertion])
                screen.put_json(folder/'input.json',manifest)
                verification=screen.verify(folder/'input.json',folder/'verified')
                screen.report(folder/'verified',folder/'visual-review.html')
                results.append(dict(id=name,result=verification['result'],scope='complete-scenario',visualRun=f'{case}-{name}/verified'))
                self.journal.event('VERIFIED',scenario=name,result=verification['result'])
                if any(r['result'] in ('FAIL','INVALID_EVIDENCE') for r in verification['assertions']):raise StopRun('Confirmed failure/invalid evidence stops further inputs')
                if any(r.get('metrics',{}).get('changed',0)>0 for r in verification['assertions']):
                    self.journal.event('DEFERRED_VISUAL_REVIEW',case=case,scenario=name)
                    return dict(case=case,execution='NEEDS_REVIEW',scenarios=results,gameplay='NOT_RUN' if self.adapter.kind=='synthetic' else 'UNVERIFIED')
            return dict(case=case,execution='COMPLETED_SYNTHETIC' if self.adapter.kind=='synthetic' else 'OBSERVED_ONLY',scenarios=results,gameplay='NOT_RUN' if self.adapter.kind=='synthetic' else 'UNVERIFIED')
        except (StopRun,screen.EvidenceError,OSError) as error:
            self.journal.event('STOPPED',reason=str(error))
            return dict(case=case,execution='BLOCKED',reason=str(error),scenarios=results,gameplay='NOT_RUN' if self.adapter.kind=='synthetic' else 'UNVERIFIED')
        finally:
            self.adapter.stop();self.journal.event('INPUT_RELEASED_PROCESS_STOP_REQUESTED',case=case)


def report(run):
    run=screen.no_links(run)
    if (run/'complete-report.json').exists():
        raw=screen.read(run/'complete-report.json',screen.MAX_JSON)
        if screen.read(run/'complete-report.sha256',128).decode().strip()!=screen.digest(raw):raise StopRun('Probe report integrity mismatch')
        payload=screen.decode_json(raw);rows=[]
        payload['currentVisualReview']=screen.summarize(run/'screen-review')
    else:
        rows=Journal.read(run);raw=screen.read(run/'result.json',screen.MAX_JSON)
        if screen.read(run/'result.sha256',128).decode().strip()!=screen.digest(raw):raise StopRun('Scheduler result integrity mismatch')
        payload=screen.decode_json(raw)
    text='<!doctype html><meta charset="utf-8"><title>Private Windows E2E report</title><h1>ROUTEKEEPER E2E — '+html.escape(payload['kind'])+'</h1><pre>'+html.escape(json.dumps(payload,ensure_ascii=False,indent=2))+'</pre><h2>Scheduler journal</h2><pre>'+html.escape(json.dumps(rows,ensure_ascii=False,indent=2))+'</pre>'
    for outcome in payload.get('outcomes',[]):
        for scenario in outcome['scenarios']:
            if 'visualRun' in scenario:
                name=scenario['visualRun'].removesuffix('/verified')+'/visual-review.html'
                screen.child(run,name)
                text+='<p><a href="'+html.escape(name,quote=True)+'">'+html.escape(outcome['case']+' / '+scenario['id'])+'</a></p>'
    return payload,text


def dry_run(output,failure=None):
    journal=Journal(output);session=uuid.uuid4().hex;nonce=uuid.uuid4().hex
    receipt=consent(session,nonce,POLICY_VERSION);validate_consent(receipt,session,nonce)
    journal.event('PREPARED',kind='SYNTHETIC_ONLY',proprietaryData=False)
    journal.event('PREFLIGHT_SIMULATED',nativeWindows='NOT_RUN');journal.event('CONSENT_SIMULATED',policy=POLICY_VERSION)
    outcomes=[]
    for case in ('original','patched'):
        adapter=FakeAdapter(output,failure)
        outcome=ScenarioRunner(adapter,journal).run(list(plans()),case);outcomes.append(outcome)
        if outcome['execution']!='COMPLETED_SYNTHETIC':break
    journal.event('RECOVERY_BOUNDARY_SIMULATED',localRestoration='NOT_NATIVE',accountRestoration='UNPROVEN')
    result=dict(schema=1,kind='SYNTHETIC_DRY_RUN',repositoryHead=repository_head(),session=session,outcomes=outcomes,
                result='BLOCKED' if any(x['execution']=='BLOCKED' for x in outcomes) else 'NEEDS_REVIEW',
                nativeGameplay='NOT_RUN',localRecovery='SIMULATED_BOUNDARY_ONLY',accountHistory='NOT_RESTORED')
    screen.put_json(Path(output)/'result.json',result)
    screen.put(Path(output)/'result.sha256',(screen.digest(screen.read(Path(output)/'result.json'))+'\n').encode())
    _,page=report(output);screen.put(Path(output)/'report.html',page.encode())
    return result



def check_native_test(work):
    work=screen.no_links(work);receipt=screen.load_json(work/'receipt.json')
    if sys.platform!='win32':raise StopRun('Native validation cannot be certified on this platform')
    if receipt.get('kind')!='NATIVE_NON_GAME_SELFTEST' or receipt.get('localSyntheticRecovery')!='VERIFIED' or not all(k in receipt.get('keyEvents',[]) for k in ('down:40','up:40')):raise StopRun('Native self-test receipt incomplete')
    for field,name in [('sourceSha','native-selftest.ps1'),('inputSha','input-window.ps1'),('captureSha','capture-client.ps1')]:
        if receipt.get(field)!=screen.hash_file(ROOT/'tools/runtime'/name):raise StopRun('Native helper changed since test')
    sidecar=screen.load_json(work/'window.png.json')
    image,_=screen.png(work/'window.png',sidecar['imageSha256']);screen.capture_status(sidecar,image)
    logical,_=screen.normalize(image)
    features=[dict(id='white-bar',kind='solid',rect=[16,16,304,19],color=[255,255,255]),
              dict(id='black-field',kind='solid',rect=[40,50,280,200],color=[0,0,0])]
    if not all(r['matches'] for r in screen.structure(logical,features)):raise StopRun('Native test window capture geometry/obstruction mismatch')
    return dict(result='PASS',scope='NATIVE_NON_GAME_CAPTURE_AND_MESSAGES_ONLY',nativeGameplay='NOT_RUN',overlayIsolation='UNPROVEN')


def ingest_probe(work):
    root=screen.no_links(Path(work)/'active-session');raw=screen.read(root/'result.json',screen.MAX_JSON)
    if screen.load_json(root/'result-integrity.json').get('sha256')!=screen.digest(raw):raise StopRun('Native probe result integrity mismatch')
    probe=screen.decode_json(raw)
    if probe.get('kind')!='EXPERIMENTAL_ORIGINAL_STARTUP_PROBE':raise StopRun('Unknown probe report')
    assertions=[dict(id='startup-behavior',scenario='startup',kind='unobservable')]
    if (root/'original.png').exists():
        sidecar=screen.load_json(root/'original.png.json')
        assertions.append(dict(id='startup-visual',scenario='startup',kind='visual',method='capture-only',actual='original.png',actualSha256=sidecar['imageSha256'],capture='original.png.json',captureSha256=screen.hash_file(root/'original.png.json')))
    manifest=dict(schema=1,kind='native-import',runId='original-probe',assertions=assertions,
                  identities={k:probe[field] for k,field in [('sourceSha256','originalSha256'),('candidateSha256','candidateSha256'),('runnerSha256','runnerSha256')] if field in probe})
    screen.put_json(root/'screen-input.json',manifest)
    visual=screen.verify(root/'screen-input.json',root/'screen-review')
    screen.report(root/'screen-review',root/'visual-review.html')
    summary=dict(kind=probe['kind'],repositoryHead=repository_head(),result='BLOCKED',observations=probe,
                 screenVerification=visual,accountHistory='NOT_RESTORED',
                 scenarios={name:('BLOCKED' if name=='startup' else 'NOT_RUN') for name in plans()})
    screen.put_json(root/'complete-report.json',summary)
    screen.put(root/'complete-report.sha256',(screen.digest(screen.read(root/'complete-report.json'))+'\n').encode())
    text='<!doctype html><meta charset="utf-8"><title>Private experimental probe</title><h1>Original startup probe — no gameplay PASS</h1><a href="visual-review.html">Private visual evidence</a><pre>'+html.escape(json.dumps(summary,ensure_ascii=False,indent=2))+'</pre>'
    screen.put(root/'complete-report.html',text.encode())
    return summary

def main():
    parser=argparse.ArgumentParser(description=__doc__);sub=parser.add_subparsers(dest='command',required=True)
    p=sub.add_parser('prepare');p.add_argument('--archive',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--cli',type=Path,required=True);p.add_argument('--builder',type=Path,required=True)
    p=sub.add_parser('ingest-probe');p.add_argument('--work',type=Path,required=True)
    p=sub.add_parser('check-native-test');p.add_argument('--work',type=Path,required=True)
    p=sub.add_parser('verify-prepared');p.add_argument('--work',type=Path,required=True)
    p=sub.add_parser('dry-run');p.add_argument('--output',type=Path,required=True);p.add_argument('--failure',choices=('focus','identity','abort','crash','unknown-scene','timeout','bad-image'))
    p=sub.add_parser('report');p.add_argument('--run',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    try:
        if args.command=='prepare':data=prepare(args.archive,args.output,args.cli,args.builder)
        elif args.command=='verify-prepared':data=verified_preparation(args.work)
        elif args.command=='check-native-test':data=check_native_test(args.work)
        elif args.command=='ingest-probe':data=ingest_probe(args.work)
        elif args.command=='dry-run':data=dry_run(args.output,args.failure)
        else:data,page=report(args.run);screen.put(args.output,page.encode())
        print(json.dumps(data,ensure_ascii=False,indent=2));return 0
    except (OSError,ValueError,KeyError,TypeError) as error:
        print(json.dumps(dict(result='BLOCKED',reason=str(error),nativeGameplay='NOT_RUN')),file=sys.stderr);return 2


if __name__=='__main__':raise SystemExit(main())
