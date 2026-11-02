"""Synthetic, disposable records exercise validation only; never real game proof."""
import copy
from datetime import datetime, timedelta, timezone
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw
import native_acquisition as a
import native_bootstrap as b
import screen_verify as s


def write_json(path, value):
    path.write_bytes(s.canonical(value))


def write(path, raw):
    path.write_bytes(raw)


class Acquisition(unittest.TestCase):
    def setUp(self):
        base = s.ROOT/'.research/acquisition-validator-tests'; base.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix='SYNTHETIC-NOT-GAME-', dir=base)
        self.addCleanup(temporary.cleanup); self.home = Path(temporary.name); self.root = self.home/'session'; self.root.mkdir()
        self.bootstrap = self.home/'bootstrap'; self.plan = self.home/'plan/native-plan.json'; self.review = self.home/'post-review.json'
        self.statement = 'SYNTHETIC TEST DELEGATION RECORD ONLY, NEVER REAL AUTHORIZATION OR GAME EVIDENCE'
        self.start = datetime(2026, 1, 1, tzinfo=timezone.utc)
        self.identity = dict(pid=42, startedTicks=a.ticks(self.time(0)), windowHandle=1234)
        self.session = dict(schema=2, id='synthetic-session', owner='SYNTHETIC', root=str(self.root), case='original', phase='Restored',
                            originalPresent=True, originalDigest=s.digest(b'F\tfile0\t9\t'+s.digest(b'SYNTHETIC').encode()+b'\n'), consentSession='synthetic-consent')
        (self.root/'snapshot').mkdir(); write(self.root/'snapshot/file0', b'SYNTHETIC')
        self.put('session.json', self.session)
        self.put('restored.json', {k:self.session[k] for k in ('schema','id','owner','originalPresent','originalDigest')})
        self.put('game-launch.json', dict(self.identity, id=self.session['id'], owner='SYNTHETIC', stage='Observed'))
        self.window = dict(self.identity, ownerPid=42, foreground=1234)
        self.put('window-observed.json', self.window)
        self.put('consent.json', dict(schema=1, session='synthetic-consent', scope='non-destructive-smoke', policy=a.e.POLICY_VERSION,
                    disclosureSha256=s.digest(a.e.DISCLOSURE.encode()), credentialsStored=False, accountIsolation='UNPROVEN',
                    network=dict(mode='OFFLINE_REQUIRED',accountHistory='NOT_RESTORED'), approval=dict(method='OWNER_CHAT_UI_DELEGATION', reviewMethod='AGENT_DELEGATED',
                    scope='non-destructive-ui-and-original-copy-recovery', statement=self.statement)))
        self.put('watchdog/result.json', dict(result='OWNED_PROCESS_EXITED', descendants=[]))
        boundary = dict(schema=1, id=self.session['id'], owner='SYNTHETIC', present=False, digest='')
        self.put('game-stop-boundary.json', boundary); self.put('trial-fence.json', boundary)
        self.capture('original.png', 1, 'intro')
        rows = []; previous = 'original.png'
        actions = ['confirm', 'enter', 'left', 'capture', 'right', 'capture']
        states = ['title', 'room', 'left', 'left', 'right', 'right']
        for seq, (action, state) in enumerate(zip(actions, states), 1):
            when = (seq-1)*4+2
            request = dict(schema=1, sequence=seq, action=action, captureSha256=s.hash_file(self.root/previous), reviewMethod='AGENT_DELEGATED',
                           reviewStatement='SYNTHETIC TEST PIXEL MEANING, NOT A REAL REVIEW', recordedUtc=self.time(when), holdMs=50)
            name = f'acquisition-request-{seq:03}.json'; self.put(name, request)
            dispatch = None
            if action != 'capture':
                dispatch = dict(kind='WINDOW_MESSAGE_DISPATCH', key=action, requestedHeldMs=50, heldMs=200,
                                startedUtc=self.time(when+.2), finishedUtc=self.time(when+.4), gameAction='UNPROVEN')
                if action in ('left','right'):
                    dispatch.update(kind='OWNED_FOREGROUND_KEY_DISPATCH', transport='SendInput-scancode-extended', releaseScope='GLOBAL_OS_KEYUP_FOR_OWN_INJECTED_KEY')
                self.put(f'input-intent-{seq}.json', dict(key=action, reviewSha256=s.hash_file(self.root/name), startedUtc=self.time(when+.1), state='ATTEMPTED_NOT_ACKNOWLEDGED'))
                self.put(f'input-dispatch-{seq}.json', dispatch)
            after = f'acquisition-{seq:03}.png'; self.capture(after, seq*4+1, state)
            rows.append(dict(sequence=seq, before=previous, after=after, reviewSha256=s.hash_file(self.root/name), dispatch=dispatch, response='UNREVIEWED_NOT_PASS'))
            previous = after
        self.put('acquisition-request-007.json', dict(schema=1, sequence=7, action='stop', captureSha256=s.hash_file(self.root/previous),
                    reviewMethod='AGENT_DELEGATED', reviewStatement='SYNTHETIC FINAL REVIEWED STOP ONLY', recordedUtc=self.time(26)))
        status = dict(schema=1, kind='AGENT_DELEGATED_CAPTURE_ACQUISITION', case='original', result='STOPPED_BY_REVIEWED_REQUEST', inputsAccepted='UNPROVEN',
                      **self.identity, nextSequence=7, capture=previous, captureSha256=s.hash_file(self.root/previous), steps=rows)
        self.put('acquisition-status.json', status)
        self.result = dict(schema=1, kind='EXPERIMENTAL_NATIVE_ACQUISITION', case='original', processObserved=True, originalSha256=a.e.lab.DATA_SHA,
                    runnerSha256=a.e.lab.RUNNER_SHA, candidateSha256=a.e.profile()['PatchedSha256'], harness=a.e.source_pins(), acquisition=status,
                    localRecovery='CONTENT_TREE_VERIFIED', localPhase='Restored', cleanupErrors=[], copyStable=True, cacheStable=True, registeredStable=True,
                    windowObservation=self.window, inputAttempts=4, inputsDispatched=4, result='NEEDS_REVIEW',gameplay='UNVERIFIED',
                    network=dict(mode='OFFLINE_REQUIRED',accountHistory='NOT_RESTORED'))
        self.seal()
        # The ordinary bootstrap intake still verifies every synthetic reference.
        data=self.home/'data.win'; write(data,b'SYNTHETIC DATA, NOT GAME')
        captures = {'intro':'original.png', 'title':'acquisition-001.png', 'room':'acquisition-002.png', 'left':'acquisition-003.png', 'right':'acquisition-005.png'}
        steps=[]; history=[]
        for role, seq, before, after, action in [('startup',1,'intro','title','confirm'),('english',2,'title','room','enter'),
                                               ('keyboard',3,'room','left','left'),('keyboard',5,'left','right','right')]:
            steps.append(dict(scenario=role,before=before,after=after,action=action,holdMs=50,timeoutMs=1000,maxFrames=4,stableFrames=2))
            dispatch=rows[seq-1]['dispatch']
            history.append(dict(source='native-dispatch-record',before=before,after=after,action=action,holdMs=50,startedUtc=dispatch['startedUtc'],finishedUtc=dispatch['finishedUtc']))
        # Capture copies live next to the recipe, exactly as a private operator intake.
        for relative in captures.values():
            write(self.home/relative,s.read(self.root/relative));write(self.home/(relative+'.json'),s.read(self.root/(relative+'.json')))
        recipe=self.home/'recipe.json';write_json(recipe,dict(schema=1,id='synthetic',version='v1',case='original',sourceProvenance='SYNTHETIC_NOT_GAME',startingState='SYNTHETIC_NOT_GAME',captures=captures,steps=steps,actionHistory=history))
        with patch.object(a.e.lab,'DATA_SHA',s.hash_file(data)):
            b.intake(recipe,data,self.bootstrap)
        # Restore exact-build identities without pretending these fixtures are genuine.
        for filename in ('bootstrap.json','proposed-plan.json'):
            item=s.load_json(self.bootstrap/filename);item['dataSha256']=a.e.lab.DATA_SHA;write_json(self.bootstrap/filename,item)
        manifest=s.load_json(self.bootstrap/'bootstrap.json');manifest['files']['proposed-plan.json']=s.hash_file(self.bootstrap/'proposed-plan.json');write_json(self.bootstrap/'bootstrap.json',manifest)
        write_json(self.bootstrap/'bootstrap-integrity.json',dict(sha256=s.hash_file(self.bootstrap/'bootstrap.json')))
        b.review(self.bootstrap,'SYNTHETIC-AGENT','r1','accepted',True,True,True,self.statement)
        b.export(self.bootstrap,'r1',self.plan.parent)
        self.chain=a.inspect_chain(self.root)
        behaviors={}
        for role,seq,before,after in [('startup',1,'intro','title'),('english',2,'title','room'),('left',3,'room','left'),('right',5,'left','right')]:
            row=rows[seq-1]
            item=dict(sequence=seq,beforeScene=before,afterScene=after,decision='accepted',pixelsReviewed=True,provenanceReviewed=True,
                    interpretation='SYNTHETIC TEST CLAIM ONLY, NOT AUTHENTIC GAMEPLAY REVIEW',beforeSha256=s.hash_file(self.root/row['before']),afterSha256=s.hash_file(self.root/row['after']))
            if role in ('left','right'):
                x1,x2=(100,70) if role=='left' else (70,110)
                item.update(stableSequence=seq+1,stableSha256=s.hash_file(self.root/rows[seq]['after']),sameRoom=True,backgroundUnchanged=True,
                            positionEvidence='SYNTHETIC blue marker position is measured independently',beforeActor=[x1,100,x1+10,110],afterActor=[x2,100,x2+10,110],actorColor=[103,164,224])
            behaviors[role]=item
        self.post=dict(schema=1,kind='LIVE_ACQUISITION_PIXEL_REVIEW',method='AGENT_DELEGATED',reviewerType='agent',reviewer='SYNTHETIC-REVIEWER',
                       delegationStatement=self.statement,decision='accepted',provenanceChecked=True,nonDestructiveActionsChecked=True,pixelsReviewed=True,
                       reviewedUtc=self.time(30),resultSha256=s.hash_file(self.root/'result.json'),chainSha256=self.chain['chainSha256'],planSha256=s.hash_file(self.plan),behaviors=behaviors)
        write_json(self.review,self.post)

    def time(self, seconds):
        return (self.start+timedelta(seconds=seconds)).isoformat().replace('+00:00','Z')

    def put(self,name,value):
        path=self.root/name;path.parent.mkdir(parents=True,exist_ok=True);write_json(path,value)

    def seal(self):
        self.put('result.json',self.result);self.put('result-integrity.json',dict(sha256=s.hash_file(self.root/'result.json')))

    def capture(self,name,when,state):
        image=Image.new('RGB',(640,480));draw=ImageDraw.Draw(image)
        if state=='intro':draw.rectangle((5,5,10,10),fill='red')
        elif state=='title':draw.rectangle((20,5,25,10),fill='white')
        else:
            x={'room':100,'left':70,'right':110}[state];draw.rectangle((x,100,x+9,109),fill=(103,164,224))
        write(self.root/name,s.png_bytes(image));self.put(name+'.json',dict(schema=1,method='CopyFromScreen',imageSha256=s.hash_file(self.root/name),clientSize=[640,480],foregroundBefore=True,foregroundAfter=True,
            pid=42,ownerPid=42,windowHandle=1234,runnerSha256=a.e.lab.RUNNER_SHA,expectedRunnerSha256=a.e.lab.RUNNER_SHA,processStartedUtc=self.time(0),startedUtc=self.time(when),finishedUtc=self.time(when+.001),dpi=192))

    def validate(self):return a.validate(self.root,self.review,self.plan,self.bootstrap)

    def test_synthetic_positive_never_claims_plan_replay_or_full_gameplay(self):
        self.assertIn('tools/native_bootstrap.py',self.result['harness'])
        self.assertIn('tools/native_acquisition.py',self.result['harness'])
        result=a.certify(self.root,self.review,self.plan,self.bootstrap)
        self.assertFalse(result['exportedPlanReplayed']);self.assertEqual(result['gameplay'],'UNVERIFIED')
        self.assertNotIn('allPlannedTransitionsObserved',result)
        self.assertEqual(a.verify(self.root,self.result['harness']),result)
        with self.assertRaises(s.EvidenceError):a.certify(self.root,self.review,self.plan,self.bootstrap)
        with patch.object(a.e,'verified_preparation',return_value={'harness':self.result['harness']}):
            self.assertEqual(a.e.check_baseline(self.root,self.home)['kind'],a.KIND)

    def test_each_chain_component_tamper_refused(self):
        for name in ('acquisition-request-003.json','input-intent-3.json','input-dispatch-3.json','acquisition-request-007.json',
                     'acquisition-003.png.json','restored.json','game-stop-boundary.json','watchdog/result.json','snapshot/file0','result-integrity.json'):
            path=self.root/name;raw=s.read(path)
            with self.subTest(name=name):
                write(path,b'{}' if path.suffix=='.json' else b'TAMPERED')
                with self.assertRaises((s.EvidenceError,KeyError,TypeError)):self.validate()
                write(path,raw)
        path=self.root/'acquisition-003.png';raw=s.read(path);write(path,s.png_bytes(Image.new('RGB',(640,480),'red')))
        with self.assertRaises(s.EvidenceError):self.validate()
        write(path,raw)

    def test_resealed_unsafe_runtime_claims_and_source_pins_refused(self):
        original=copy.deepcopy(self.result)
        for mutation in ({'localRecovery':'UNVERIFIED'},{'copyStable':False},{'inputsDispatched':3},{'harness':{}},{'kind':'EXPERIMENTAL_NATIVE_GAMEPLAY'}):
            self.result=dict(original,**mutation);self.seal()
            with self.subTest(mutation=mutation),self.assertRaises(s.EvidenceError):self.validate()
        self.result=original;self.seal()

    def test_missing_or_uncertain_pixel_review_and_false_positions_refused(self):
        for mutation in ({'decision':'uncertain'},{'method':'HUMAN'},{'chainSha256':'0'*64},{'pixelsReviewed':False},{'behaviors':{}},{'planSha256':'0'*64}):
            write_json(self.review,dict(self.post,**mutation))
            with self.subTest(mutation=mutation),self.assertRaises(s.EvidenceError):self.validate()
        post=copy.deepcopy(self.post);post['behaviors']['left']['afterActor']=[120,100,130,110];write_json(self.review,post)
        with self.assertRaises(s.EvidenceError):self.validate()
        post=copy.deepcopy(self.post);post['behaviors']['right']['stableSequence']=5;write_json(self.review,post)
        with self.assertRaises(s.EvidenceError):self.validate()

    def test_certificate_is_revalidated_and_harness_exact(self):
        a.certify(self.root,self.review,self.plan,self.bootstrap)
        with self.assertRaises(s.EvidenceError):a.verify(self.root,{})
        self.post['behaviors']['left']['interpretation']='CHANGED AFTER CERTIFICATE REVIEW';write_json(self.review,self.post)
        with self.assertRaises(s.EvidenceError):a.verify(self.root,self.result['harness'])


if __name__=='__main__':unittest.main()
