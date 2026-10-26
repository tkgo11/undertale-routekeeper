#!/usr/bin/env python3
"""Authentic read-only exporter regressions. Uses disposable input copies; no game runner."""
import argparse,hashlib,json,os,shutil,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
EXPECTED='b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'
def digest(path):
 with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);p.add_argument('--cli',required=True);a=p.parse_args()
 original=a.input.resolve(strict=True)
 if digest(original)!=EXPECTED:raise ValueError('Uninspected exporter input')
 private=ROOT/'.research';private.mkdir(exist_ok=True)
 with tempfile.TemporaryDirectory(prefix='preview-export-audit-',dir=private) as tmp:
  work=Path(tmp);source=work/'input.win';shutil.copyfile(original,source)
  def invoke(folder,expected):
   env=dict(os.environ,ROUTEKEEPER_PREVIEW_FONT=str(folder))
   r=subprocess.run([a.cli,'load',str(source),'-s',str(ROOT/'integration/export-preview-font.csx')],env=env,capture_output=True,text=True)
   if (r.returncode==0)!=expected:raise RuntimeError('Exporter acceptance mismatch; source is not printed')
   if digest(source)!=EXPECTED or digest(original)!=EXPECTED:raise RuntimeError('Exporter modified an input')
  good=work/'new';invoke(good,True)
  before={p.name:digest(p) for p in good.iterdir()}
  invoke(good,False)
  assert before=={p.name:digest(p) for p in good.iterdir()}
  print('PASS new private export and existing-output refusal; authentic inputs unchanged')
  # Contains("/.research/") alone accepted an unrelated repository's folder.
  outside=ROOT/'artifacts'/'.research'/'must-not-create-preview'
  if outside.exists():raise RuntimeError('Unrelated preexisting audit destination')
  invoke(outside,False);assert not outside.exists()
  print('PASS export cannot escape the actual repository private directory')
  for name in ['page.png','glyphs.json']:
   folder=work/('linked-'+name);folder.mkdir()
   try:(folder/name).symlink_to(source)
   except OSError:print('NOT_RUN native link privilege unavailable: '+name);continue
   invoke(folder,False)
   print('PASS linked '+name+' refused without modifying disposable/pristine input')
  folder=work/'alias'
  try:folder.symlink_to(good,target_is_directory=True)
  except OSError:print('NOT_RUN native directory-link privilege unavailable')
  else:invoke(folder,False);print('PASS linked export ancestor refused')
 print('PASS authentic exporter regression; game/native Windows NOT_RUN')
if __name__=='__main__':main()
