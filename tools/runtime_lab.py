#!/usr/bin/env python3
"""Private, hash-pinned staging for the authorized Windows runtime. No installer gate override."""
import argparse,hashlib,json,re,shutil,stat,struct,zipfile
from pathlib import Path,PurePosixPath
ZIP_SHA='9c8fa123ede4bad7b39f70ddcd1a8fdfa397df89bb215b18b4635855df2f265d'
ZIP_SIZE=132054497
DATA_SHA='b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7'
RUNNER_SHA='c8c4191026bf5587a6fad120855b8b82ffb4fa0c3eaf10515be472ad84248e58'
INVENTORY_SHA='d0d633daad4d0c45a3f6761e9627ad7188853219ff96122b426d06b7a345932a'
MARKER='.routekeeper-disposable-runtime-lab'
def assert_no_links(path):
 # lstat detects NTFS reparse points (including junctions), not only symlinks.
 path=Path(path).absolute()
 for item in (path,*path.parents):
  try:info=item.lstat()
  except FileNotFoundError:continue
  if stat.S_ISLNK(info.st_mode) or getattr(info,'st_file_attributes',0)&getattr(stat,'FILE_ATTRIBUTE_REPARSE_POINT',1024):raise ValueError('Linked/reparse runtime path refused')
 return path

def inventory_digest(files):
 return hashlib.sha256(''.join(f"{f['path']}\t{f['size']}\t{f['sha256']}\n" for f in sorted(files,key=lambda f:f['path'])).encode()).hexdigest()
def digest(path):
 with Path(path).open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()
def safe_entries(z):
 seen=set();total=0
 if len(z.infolist())>4096:raise ValueError('Too many archive entries')
 for entry in z.infolist():
  name=entry.filename.replace('\\','/');p=PurePosixPath(name)
  if p.is_absolute() or any(x in ['..','.'] or ':' in x or x.endswith((' ','.')) for x in p.parts):raise ValueError('Unsafe archive path')
  if not p.parts or any(re.fullmatch(r'(CON|PRN|AUX|NUL|COM[1-9\u00b9\u00b2\u00b3]|LPT[1-9\u00b9\u00b2\u00b3])(?:\..*)?',x,re.I) for x in p.parts):raise ValueError('Reserved archive path')
  if any(ord(c)<32 or c in '<>\"|?*' for c in name):raise ValueError('Windows-invalid archive character')
  key=str(p).casefold()
  if key in seen:raise ValueError('Duplicate case-insensitive archive path')
  seen.add(key)
  if stat.S_ISLNK(entry.external_attr>>16) or entry.flag_bits&1:raise ValueError('Linked/encrypted entry')
  total+=entry.file_size
  if total>1024**3 or entry.file_size>256*1024**2:raise ValueError('Archive exceeds staging limits')
  yield entry,p

def inspect(archive,expected_sha=ZIP_SHA,expected_size=ZIP_SIZE,expected_data=DATA_SHA,expected_runner=RUNNER_SHA):
 archive=assert_no_links(archive)
 if archive.stat().st_size!=expected_size or digest(archive)!=expected_sha:raise ValueError('Runtime ZIP identity mismatch')
 rows=[]
 with zipfile.ZipFile(archive) as z:
  entries=list(safe_entries(z));files={str(p):e for e,p in entries if not e.is_dir()}
  for needed in ['Undertale/UNDERTALE.exe','Undertale/data.win','appmanifest_391540.acf']:
   if needed not in files:raise ValueError('Required runtime component missing')
  for name,entry in files.items():
   with z.open(entry) as stream:sha=hashlib.file_digest(stream,'sha256').hexdigest()
   rows.append(dict(path=name,size=entry.file_size,sha256=sha))
  index={r['path']:r for r in rows}
  if index['Undertale/data.win']['sha256']!=expected_data or index['Undertale/UNDERTALE.exe']['sha256']!=expected_runner:raise ValueError('Uninspected game build; do not patch')
  pe=z.read(files['Undertale/UNDERTALE.exe']);offset=struct.unpack_from('<I',pe,0x3c)[0]
  if pe[:2]!=b'MZ' or pe[offset:offset+4]!=b'PE\0\0':raise ValueError('Invalid PE signature')
  machine=struct.unpack_from('<H',pe,offset+4)[0]
  manifest=z.read(files['appmanifest_391540.acf']).decode('utf-8')
  # Deliberately omit LastOwner, LauncherPath, timestamps and other account metadata.
  def field(key):
   m=re.search(r'"'+key+r'"\s+"([^"\r\n]+)"',manifest)
   return m[1] if m else None
  identity=dict(platform='Windows',architecture={0x14c:'x86',0x8664:'x64'}.get(machine,'Unknown'),steamBuild=field('buildid'),depot='391541' if '"391541"' in manifest else None,depotManifest=field('manifest'),runnerSha256=expected_runner,dataSha256=expected_data,zipSha256=expected_sha,files=rows,status='InspectedOnly',runtime='NOT_RUN')
  if identity['architecture']!='x86':raise ValueError('Unexpected runner architecture')
  return identity

def verify_original_tree(original,files):
 assert_no_links(original)
 expected={f['path'] for f in files};actual=set()
 if not original.is_dir():raise ValueError('Pristine original directory missing')
 for path in original.rglob('*'):
  assert_no_links(path)
  if path.is_file():actual.add(path.relative_to(original).as_posix())
  elif not path.is_dir():raise ValueError('Unsupported node in pristine tree')
 if actual!=expected:raise ValueError('Pristine file set changed (missing or unlisted files)')
 for f in files:
  path=original/f['path']
  if path.stat().st_size!=f['size'] or digest(path)!=f['sha256']:raise ValueError('Pristine input changed: '+f['path'])

def remove_unpublished_work(work):
 # Only a newly created, unpublished lab owned by prepare. Never originals passed
 # by the caller. Windows cannot unlink the read-only bits we set on extraction.
 work=assert_no_links(work)
 for path in work.rglob('*'):
  assert_no_links(path)
  info=path.lstat()
  if stat.S_ISREG(info.st_mode):
   if info.st_nlink!=1:raise ValueError('Unpublished cleanup refused a hardlinked file')
   path.chmod(info.st_mode|stat.S_IRUSR|stat.S_IWUSR)
 shutil.rmtree(work)

def prepare(archive,work):
 work=assert_no_links(work)
 identity=inspect(archive)
 if work.exists():raise ValueError('Lab must be a new directory; never reuse a personal profile')
 work.mkdir(mode=0o700,parents=True);(work/MARKER).write_text('Disposable lab. Contains proprietary inputs; never publish.\n', encoding='utf-8', newline='\n')
 try:
  original=work/'original';original.mkdir()
  with zipfile.ZipFile(archive) as z:
   for entry,path in safe_entries(z):
    target=original.joinpath(*path.parts)
    if entry.is_dir():target.mkdir(parents=True,exist_ok=True);continue
    target.parent.mkdir(parents=True,exist_ok=True)
    with z.open(entry) as source,target.open('xb') as dest:shutil.copyfileobj(source,dest)
    target.chmod(0o400)
  # Revalidate what was actually extracted, including additions, before making
  # any runnable copy. A checked archive pathname can otherwise change later.
  verify_original_tree(original,identity['files'])
  for kind in ['original','patched']:
   shutil.copytree(original/'Undertale',work/'runs'/kind)
   for p in (work/'runs'/kind).rglob('*'):
    if p.is_file():p.chmod(0o600)
  (work/'evidence').mkdir();(work/'identity-private.json').write_text(json.dumps(identity,indent=2)+'\n', encoding='utf-8', newline='\n')
 except BaseException as failure:
  try:remove_unpublished_work(work)
  except (OSError,ValueError) as cleanup:failure.add_note('Unpublished cleanup incomplete; preserve private lab: '+type(cleanup).__name__)
  raise
 return identity

def verify(work,expected_inventory=INVENTORY_SHA):
 work=assert_no_links(work)
 assert_no_links(work/MARKER);assert_no_links(work/'identity-private.json')
 if not (work/MARKER).is_file():raise ValueError('Not a disposable runtime lab')
 identity=json.loads((work/'identity-private.json').read_text(encoding='utf-8'))
 if inventory_digest(identity['files'])!=expected_inventory:raise ValueError('Original inventory identity changed')
 verify_original_tree(work/'original',identity['files'])
 return identity

def main():
 p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest='command',required=True)
 a=sub.add_parser('prepare');a.add_argument('--zip',type=Path,required=True);a.add_argument('--work',type=Path,required=True)
 a=sub.add_parser('verify');a.add_argument('--work',type=Path,required=True)
 args=p.parse_args();j=prepare(args.zip,args.work) if args.command=='prepare' else verify(args.work)
 print(json.dumps({k:j[k] for k in ['platform','architecture','steamBuild','depot','depotManifest','dataSha256','runnerSha256','status','runtime']},indent=2))
if __name__=='__main__':main()
