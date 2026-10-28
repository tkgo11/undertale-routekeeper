#!/usr/bin/env python3
"""Private native scene contracts. Never starts a process or synthesizes game state.

Windows native-gameplay.ps1 owns real launch/input/capture. Matching pixels proves
only the bounded scene contract; CopyFromScreen and internal state remain limited.
"""
import argparse
import configparser
from datetime import datetime
import json
from pathlib import Path
import sys

import screen_verify as s
import windows_e2e as e


def load_plan(path, case):
    path=s.no_links(path);data=s.load_json(path)
    if data.get('schema')!=1 or data.get('case')!=case or case not in ('original','patched'):
        raise e.StopRun('Native plan schema/case mismatch')
    s.token(data.get('id'));s.token(data.get('version'))
    if data.get('runnerSha256')!=e.lab.RUNNER_SHA or data.get('dataSha256')!=(e.lab.DATA_SHA if case=='original' else e.profile()['PatchedSha256']):
        raise e.StopRun('Native plan exact build mismatch')
    if data.get('scope')!='non-destructive-ui' or data.get('retries')!=0:
        raise e.StopRun('Only reviewed non-destructive UI plans; no retry or combat/history policy')
    scenes=data.get('scenes');steps=data.get('steps')
    if not isinstance(scenes,dict) or not 2<=len(scenes)<=80 or not isinstance(steps,list) or not 1<=len(steps)<=80:
        raise e.StopRun('Native plan must have bounded scenes/steps')
    images={};reference_bytes=0
    for name,ref in scenes.items():
        s.token(name)
        if not isinstance(ref.get('file'),str) or not ref['file'].startswith('references/') or not ref['file'].endswith('.png'):raise e.StopRun('Scene pixels must be private references/*.png')
        if ref.get('source')!='privately-authentic' or not isinstance(ref.get('reviewer'),str) or not ref['reviewer'].strip() or ref.get('scope')!='scene-navigation-only':
            raise e.StopRun('Native scene requires authentic private provenance and scoped review; no proxy fonts')
        image,raw=s.png(s.child(path.parent,ref.get('file')),ref.get('sha256'))
        reference_bytes+=len(raw)
        if reference_bytes>s.MAX_FILE:raise e.StopRun('Reference collection exceeds16MiB budget')
        if image.size!=(320,240):raise e.StopRun('Scene reference must be logical320x240')
        images[name]=image
    for step in steps:
        if step.get('scenario') not in ('startup','english','korean','settings','keyboard'):
            raise e.StopRun('Combat/Forced requires independent side-effect observers; no screenshot-only override')
        if case=='original' and step['scenario'] in ('korean','settings'):
            raise e.StopRun('Original baseline has no mod settings/Korean scenario')
        if step.get('before') not in scenes or step.get('after') not in scenes or step.get('action') not in ('checkpoint',*e.KEYS):
            raise e.StopRun('Unrecognized native step/action')
        for key,low,high in [('holdMs',50,500),('timeoutMs',100,15000),('maxFrames',2,100),('stableFrames',2,8)]:
            if type(step.get(key)) is not int or not low<=step[key]<=high:raise e.StopRun('Invalid bounded step '+key)
        setting=step.get('setting')
        if setting is not None:
            if case!='patched' or not isinstance(setting,dict) or setting.get('section')!='Guidance' or setting.get('key') not in ('schema','mode','locale','language','spoilers','target_route','target_neutral','target_epilogue','target_greeting') or not isinstance(setting.get('expected'),str) or len(setting['expected'])>32:
                raise e.StopRun('Unsupported bounded mod-setting observer')
        if step['stableFrames']>step['maxFrames']:raise e.StopRun('Unattainable stabilization bound')
        if step['action']!='checkpoint' and images[step['before']].tobytes()==images[step['after']].tobytes():
            raise e.StopRun('Input requires a distinct observable response; dispatch is insufficient')
    # Freeze the complete reviewed plan and pixels, not a mutable scene name.
    return data


def stage_plan(path, case, root):
    plan=load_plan(path,case);root=s.no_links(root)
    for ref in plan['scenes'].values():
        dest=s.child(root,ref['file']);dest.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
        raw=s.read(s.child(Path(path).parent,ref['file']),s.MAX_FILE)
        if s.digest(raw)!=ref['sha256']:raise e.StopRun('Reference changed during staging')
        s.put(dest,raw)
    s.put_json(root/'native-plan.json',plan)
    load_plan(root/'native-plan.json',case)
    return plan


def match(path, case, scene, frame, expected_pid=None, expected_start=None):
    plan=load_plan(path,case)
    if scene not in plan['scenes']:raise e.StopRun('Unknown requested scene')
    ref=plan['scenes'][scene]
    meta=s.load_json(Path(str(frame)+'.json'))
    image,_=s.png(frame,meta['imageSha256']);s.capture_status(meta,image)
    if meta['runnerSha256']!=e.lab.RUNNER_SHA:raise e.StopRun('Frame runner mismatch')
    if expected_pid is not None and meta['pid']!=expected_pid:raise e.StopRun('Frame process mismatch')
    if expected_start is not None and meta.get('processStartedUtc')!=expected_start:raise e.StopRun('Frame process start mismatch')
    actual,geometry=s.normalize(image)
    expected,_=s.png(s.child(Path(path).parent,ref['file']),ref['sha256'])
    metrics,_=s.compare(actual,expected)
    return dict(result='MATCH' if metrics['changed']==0 else 'NEEDS_REVIEW',scene=scene,
                frameSha256=meta['imageSha256'],sidecarSha256=s.hash_file(Path(str(frame)+'.json')),
                metrics=metrics,geometry=geometry,scope='EXACT_PRIVATE_SCENE_PIXELS_ONLY',
                overlayIsolation='UNPROVEN',gameplay='UNVERIFIED')


def observe_settings(path, section, key, expected, snapshot=None):
    # An ordinary mod settings file is independent of its displayed menu text.
    # Never substitute these values for HP/EXP/vanilla route flags.
    path=s.no_links(path)
    if path.name!='routekeeper.ini':raise e.StopRun('Only read-only ROUTEKEEPER settings observation is supported')
    raw=s.read(path,65536)
    parser=configparser.ConfigParser(interpolation=None,strict=True)
    parser.read_string(raw.decode('utf-8-sig'))
    actual=parser.get(section,key,fallback=None)
    if snapshot is not None:s.put(s.no_links(snapshot),raw)
    return dict(result='PASS' if actual==expected else 'FAIL',scope='MOD_SETTING_FILE_ONLY',
                expected=expected,actual=actual,sha256=s.digest(raw),gameplay='UNVERIFIED')


def review_frame(root,plan,case,frame,scene,scenario,label):
    ref=plan['scenes'][scene];sidecar=s.load_json(s.child(root,frame+'.json'))
    reference=dict(file=ref['file'],sha256=ref['sha256'],provenance=dict(source='private-reviewed-scene-contract',
                   generatorVersion=plan['version'],sourceHashes={'plan':s.hash_file(root/'native-plan.json'),'pixels':ref['sha256']},
                   locale=ref.get('locale','unknown'),font=ref.get('font','unverified-native-font'),scene=scene,kind='private-authentic'))
    manifest=dict(schema=1,kind='native-import',runId=label,assertions=[dict(
        id=scenario+'-visual',scenario=scenario,kind='visual',method='exact',reference=reference,
        actual=frame,actualSha256=sidecar['imageSha256'],capture=frame+'.json',
        captureSha256=s.hash_file(s.child(root,frame+'.json')))])
    s.put_json(root/(label+'.json'),manifest)
    verification=s.verify(root/(label+'.json'),root/label)
    s.report(root/label,root/(label+'.html'))
    return verification


def finalize(root, write_review=True):
    root=s.no_links(root);raw=s.read(root/'native-observations.json',s.MAX_JSON)
    if s.load_json(root/'native-observations-integrity.json').get('sha256')!=s.digest(raw):raise e.StopRun('Native observations seal mismatch')
    data=s.decode_json(raw)
    if data.get('kind')!='WINDOWS_GAMEPLAY_OBSERVATIONS' or data.get('case') not in ('original','patched'):
        raise e.StopRun('Unknown native observation scope')
    plan_path=s.child(root,'native-plan.json');plan=load_plan(plan_path,data['case'])
    if data.get('planSha256')!=s.hash_file(plan_path):raise e.StopRun('Plan changed during execution')
    steps=data.get('steps',[])
    if not isinstance(steps,list) or len(steps)>len(plan['steps']):raise e.StopRun('Unexpected step count')
    results=[];previous_end=None
    for index,row in enumerate(steps):
        step=plan['steps'][index]
        if row.get('index')!=index:raise e.StopRun('Native step order mismatch')
        times={}
        for phase,scene in [('before',step['before']),('after',step['after'])]:
            sequence=row.get(phase+'Frames')
            if not isinstance(sequence,list) or len(sequence)!=step['stableFrames'] or len(set(sequence))!=len(sequence) or sequence[-1]!=row[phase]:raise e.StopRun('Missing/duplicate stabilization frames')
            previous=None;first=None
            for item in sequence:
                observed_frame=s.child(root,item)
                observed_match=match(plan_path,data['case'],scene,observed_frame,data['pid'],data['processStartedUtc'])
                meta=s.load_json(Path(str(observed_frame)+'.json'))
                start=datetime.fromisoformat(meta['startedUtc'].replace('Z','+00:00'));end=datetime.fromisoformat(meta['finishedUtc'].replace('Z','+00:00'))
                if observed_match['result']!='MATCH' or (previous is not None and start<=previous):raise e.StopRun('Unstable/replayed native sequence')
                first=start if first is None else first;previous=end
            if (previous-first).total_seconds()*1000>step['timeoutMs']:raise e.StopRun('Stabilization exceeds timeout')
            frame=s.child(root,row[phase])
            observed=match(plan_path,data['case'],scene,frame,data['pid'],data['processStartedUtc'])
            metadata=s.load_json(Path(str(frame)+'.json'))
            times[phase]=[datetime.fromisoformat(metadata[k].replace('Z','+00:00')) for k in ('startedUtc','finishedUtc')]
            if observed['result']!='MATCH':raise e.StopRun('Native recorded transition disagrees with independent pixels')
        if times['after'][0]<times['before'][1] or (previous_end is not None and times['before'][0]<previous_end):raise e.StopRun('Stale/reordered transition frames')
        previous_end=times['after'][1]
        if step['action']!='checkpoint':
            dispatch=row.get('dispatch',{})
            if dispatch.get('kind')!='WINDOW_MESSAGE_DISPATCH' or dispatch.get('key')!=step['action']:
                raise e.StopRun('Missing corresponding bounded input dispatch')
            try:
                start=datetime.fromisoformat(dispatch['startedUtc'].replace('Z','+00:00'))
                end=datetime.fromisoformat(dispatch['finishedUtc'].replace('Z','+00:00'))
                ordered=times['before'][1]<=start<=end<=times['after'][0] and 0<=(end-start).total_seconds()<=2
            except (KeyError,ValueError,TypeError) as error:raise e.StopRun('Missing trustworthy input timing') from error
            if not ordered or dispatch.get('requestedHeldMs')!=step['holdMs']:raise e.StopRun('Input/capture timing or hold mismatch')
        if step.get('setting'):
            observation=row.get('setting',{})
            saved=observe_settings(root/('settings-'+str(index))/'routekeeper.ini',step['setting']['section'],step['setting']['key'],step['setting']['expected'])
            if observation!=saved:raise e.StopRun('Settings snapshot differs from observation')
            if observation.get('scope')!='MOD_SETTING_FILE_ONLY' or observation.get('result')!='PASS':raise e.StopRun('Settings persistence assertion not established')

        # Existing verifier owns immutable evidence, metrics and scoped review.
        verification=review_frame(root,plan,data['case'],row['after'],step['after'],step['scenario'],'review-'+str(index)) if write_review else s.summarize(root/('review-'+str(index)))
        results.append(dict(scenario=step['scenario'],step=index,result=verification['result'],
                            transition='PIXELS_OBSERVED',review='review-'+str(index),gameplay='UNVERIFIED'))
    pending=data.get('pending')
    if pending is not None:
        if pending.get('scene') not in plan['scenes'] or pending.get('scenario') not in e.plans():raise e.StopRun('Invalid pending scene evidence')
        if write_review:review_frame(root,plan,data['case'],pending['frame'],pending['scene'],pending['scenario'],'pending-review')
        else:s.summarize(root/'pending-review')
    complete=len(steps)==len(plan['steps']) and data.get('execution')=='OBSERVED_TRANSITIONS'
    return dict(kind='NATIVE_SCENE_TRANSITIONS',case=data['case'],result='NEEDS_REVIEW' if complete else 'BLOCKED',
                steps=results,pendingReview='pending-review' if pending else None,allPlannedTransitionsObserved=complete,gameplay='UNVERIFIED',
                independentInternalState='UNAVAILABLE',windowsNative='OBSERVATIONS_REQUIRE_OPERATOR_PROVENANCE')


def main():
    p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest='command',required=True)
    q=sub.add_parser('validate');q.add_argument('--plan',type=Path,required=True);q.add_argument('--case',choices=('original','patched'),required=True)
    q=sub.add_parser('stage');q.add_argument('--plan',type=Path,required=True);q.add_argument('--case',choices=('original','patched'),required=True);q.add_argument('--root',type=Path,required=True)
    q=sub.add_parser('match');q.add_argument('--plan',type=Path,required=True);q.add_argument('--case',choices=('original','patched'),required=True);q.add_argument('--scene',required=True);q.add_argument('--frame',type=Path,required=True);q.add_argument('--pid',type=int);q.add_argument('--started')
    q=sub.add_parser('finalize');q.add_argument('--root',type=Path,required=True)
    q=sub.add_parser('settings');q.add_argument('--file',type=Path,required=True);q.add_argument('--section',required=True);q.add_argument('--key',required=True);q.add_argument('--expected',required=True);q.add_argument('--snapshot',type=Path)
    a=p.parse_args()
    try:
        if a.command=='validate':data=load_plan(a.plan,a.case)
        elif a.command=='stage':data=stage_plan(a.plan,a.case,a.root)
        elif a.command=='match':data=match(a.plan,a.case,a.scene,a.frame,a.pid,a.started)
        elif a.command=='settings':data=observe_settings(a.file,a.section,a.key,a.expected,a.snapshot)
        else:data=finalize(a.root)
        print(json.dumps(data,ensure_ascii=True));return 0
    except (OSError,ValueError,KeyError,TypeError,configparser.Error) as error:
        print(json.dumps(dict(result='BLOCKED',reason=str(error))),file=sys.stderr);return 2


if __name__=='__main__':raise SystemExit(main())
