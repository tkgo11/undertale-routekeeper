#!/usr/bin/env python3
"""Real xdelta/ZIP roundtrip on synthetic FORM only; optional upstream parser check."""
import argparse,hashlib,json,pathlib,struct,subprocess,sys,tempfile,zipfile
p=argparse.ArgumentParser();p.add_argument('--tool',required=True);p.add_argument('--xdelta',required=True);p.add_argument('--upstream',type=pathlib.Path);a=p.parse_args()
tool=str(pathlib.Path(a.tool).resolve());program=['dotnet',tool] if tool.endswith('.dll') else [tool];xdelta=str(pathlib.Path(a.xdelta).resolve())
def invoke(*args):return subprocess.run([*program,*map(str,args)],capture_output=True,text=True,check=True).stdout
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
with tempfile.TemporaryDirectory(prefix='routekeeper-g3m-test-') as directory:
 root=pathlib.Path(directory);original=root/'data.win';candidate=root/'candidate.win'
 payload=b'ROUTEKEEPER SYNTHETIC FIXTURE ONLY\0'*10000
 def form(data):
  body=b'GEN8'+struct.pack('<I',2)+b'\x00\x10'+b'TEST'+struct.pack('<I',len(data))+data
  return b'FORM'+struct.pack('<I',len(body))+body
 original.write_bytes(form(payload));candidate.write_bytes(form(payload[:100]+b'CHANGED'+payload[107:]))
 identity=json.loads(invoke('inspect',original));i=identity['Identity']
 profile=dict(Id='synthetic-only',Status='VerifiedPatch',Platform='Synthetic',Architecture='test',OriginalSize=i['Size'],OriginalSha256=i['Sha256'],OriginalMd5=i['Md5'],BytecodeVersion=i['BytecodeVersion'],StructuralSha256=identity['StructuralSha256'],PatchedSha256=digest(candidate),GameDataRelativePath='data.win')
 assets=root/'assets';(assets/'profiles').mkdir(parents=True);registry=assets/'profiles/registry.json';registry.write_text(json.dumps([profile]), encoding='utf-8', newline='\n')
 archive=root/'routekeeper.zip';invoke('g3m-package',original,candidate,xdelta,archive,'Synthetic','test',assets)
 with zipfile.ZipFile(archive) as z:
  assert sorted(z.namelist())==['mod_config.json','payload/routekeeper.xdelta'];config=json.loads(z.read('mod_config.json'));patch=z.read('payload/routekeeper.xdelta')
 leaf=config['files'][0];assert leaf['target_hash']=='sha256:'+digest(original);assert leaf['source_hash']=='sha256:'+hashlib.sha256(patch).hexdigest();assert len(patch)<len(payload)//10
 assert leaf['target']=='${game_path}/data.win';assert config['config_version']=='2.0.0'
 if a.upstream:
  sys.path.insert(0,str((a.upstream/'src').resolve()))
  from utils.mod.config import parse_mod_config
  parse_mod_config(config);print('PASS current upstream G3M parser accepts generated config')
 second=root/'second.zip';invoke('g3m-package',original,candidate,xdelta,second,'Synthetic','test',assets);assert archive.read_bytes()==second.read_bytes()
 profile['Status']='InspectedOnly';registry.write_text(json.dumps([profile]), encoding='utf-8', newline='\n');refused=root/'refused.zip'
 r=subprocess.run([*program,'g3m-package',str(original),str(candidate),'missing-xdelta',str(refused),'Synthetic','test',str(assets)],capture_output=True);assert r.returncode!=0 and not refused.exists()
 assert original.read_bytes()==form(payload);assert not list(root.glob('.routekeeper-g3m-*'))
 print('PASS synthetic G3M delta encode/decode, source/target hash pins, deterministic ZIP, private-data exclusion, unverified refusal and temporary cleanup; gameplay NOT_RUN')
