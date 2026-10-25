import hashlib,io,json,struct,tempfile,unittest,zipfile
from pathlib import Path
from runtime_lab import safe_entries,inspect,verify,MARKER,inventory_digest
class ArchiveTests(unittest.TestCase):
 def archive(self,names):
  f=io.BytesIO()
  with zipfile.ZipFile(f,'w') as z:
   for name in names:z.writestr(name,b'x')
  f.seek(0);return zipfile.ZipFile(f)
 def test_traversal_and_windows_names(self):
  for name in ['../outside','/outside','C:/outside','foo\\..\\outside','NUL.txt','foo./bar','a/COM1','bad?.dll','bad\nfile']:
   with self.subTest(name=name),self.assertRaises(ValueError):list(safe_entries(self.archive([name])))
 def test_case_collision(self):
  for names in [['Game/DATA.win','game/data.win'],['game/a','game//a']]:
   with self.assertRaises(ValueError):list(safe_entries(self.archive(names)))
 def test_symlink(self):
  f=io.BytesIO()
  with zipfile.ZipFile(f,'w') as z:
   entry=zipfile.ZipInfo('link');entry.external_attr=(0o120777<<16);z.writestr(entry,'../target')
  f.seek(0)
  with zipfile.ZipFile(f) as z,self.assertRaises(ValueError):list(safe_entries(z))
 def fixture(self,root):
  (root/MARKER).write_text('synthetic lab')
  game=root/'original'/'Game';game.mkdir(parents=True)
  (game/'data.win').write_bytes(b'SYNTHETIC ONLY')
  identity={'files':[{'path':'Game/data.win','size':14,'sha256':hashlib.sha256(b'SYNTHETIC ONLY').hexdigest()}]}
  (root/'identity-private.json').write_text(json.dumps(identity))
  return game
 def test_original_mutation(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);game=self.fixture(root)
   self.assertEqual(len(verify(root,inventory_digest(json.loads((root/'identity-private.json').read_text())['files']))['files']),1)
   (game/'data.win').write_bytes(b'MUTATED SOURCE')
   with self.assertRaises(ValueError):verify(root,inventory_digest(json.loads((root/'identity-private.json').read_text())['files']))
 def test_linked_original_parent(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);game=self.fixture(root);outside=root/'moved-game'
   game.rename(outside)
   try:game.symlink_to(outside,target_is_directory=True)
   except OSError as error:self.skipTest('Symlink creation unavailable: '+str(error))
   with self.assertRaises(ValueError):verify(root,inventory_digest(json.loads((root/'identity-private.json').read_text())['files']))
 def test_inventory_cannot_repin_modified_originals(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);self.fixture(root)
   # An edited inventory cannot redefine which build is pristine.
   with self.assertRaisesRegex(ValueError,'inventory identity'):verify(root)
 def test_identity_and_account_redaction(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'input.zip';pe=bytearray(132);pe[:2]=b'MZ';struct.pack_into('<I',pe,0x3c,128);pe.extend(b'\x4c\x01');pe[128:132]=b'PE\0\0'
   data=b'SYNTHETIC ONLY'
   with zipfile.ZipFile(p,'w') as z:
    z.writestr('Undertale/UNDERTALE.exe',pe);z.writestr('Undertale/data.win',data)
    z.writestr('appmanifest_391540.acf','"buildid" "123" "391541" { "manifest" "456" } "LastOwner" "synthetic-account"')
   sha=lambda b:hashlib.sha256(b).hexdigest()
   j=inspect(p,sha(p.read_bytes()),p.stat().st_size,sha(data),sha(pe))
   self.assertEqual((j['architecture'],j['steamBuild'],j['depotManifest']),('x86','123','456'))
   self.assertNotIn('synthetic-account',json.dumps(j));self.assertEqual(j['status'],'InspectedOnly')
   with self.assertRaises(ValueError):inspect(p,'0'*64,p.stat().st_size)
if __name__=='__main__':unittest.main(verbosity=2)
