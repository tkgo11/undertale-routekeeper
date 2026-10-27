"""Localization data, migration, adversarial validation and contributor workflow tests.

Offline only: does not execute GameMaker, Steam or a game runner.
"""
import copy
import hashlib
import gzip
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import localization as loc

ROOT=loc.ROOT


class LocalizationTests(unittest.TestCase):
    def setUp(self):
        self.temporary=tempfile.TemporaryDirectory();self.addCleanup(self.temporary.cleanup)
        self.root=Path(self.temporary.name)
        for name in ['locales','integration/assets/font-source']:
            shutil.copytree(ROOT/name,self.root/name)
        for name in ['integration/generate_font.py','integration/ui/english-metrics.json','integration/assets/FONT-LICENSE.txt']:
            target=self.root/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/name,target)

    def change(self,name,action):
        path=self.root/name;data=loc.load(path);action(data);loc.write(path,data)

    def reject(self,name,action,pattern):
        self.change(name,action)
        with self.assertRaisesRegex(ValueError,pattern):loc.validate(self.root)

    def test_enabled_complete_locales(self):
        self.assertEqual([x['locale'] for x in loc.validate(self.root)],['en','ko'])

    def test_migration_preserves_every_extracted_pair(self):
        # Immutable pre-refactor own-mod wording, not generated from current catalog.
        for row in loc.load(ROOT/'tests/golden/localization-migration.json'):
            for tag in ['en','ko']:self.assertEqual(loc.text(row['id'],tag),row[tag],row['id'])
        self.assertEqual(loc.text('guidance.defeat_remaining_more_enemies_before_moving_on','en'),'Defeat {remaining} more enemies before moving on.')

    def test_duplicate_json_rejected(self):
        path=self.root/'duplicate.json';path.write_text('{"a":1,"a":2}',encoding='utf-8',newline='\n')
        with self.assertRaisesRegex(ValueError,'Duplicate'):loc.load(path)

    def test_missing_key(self):self.reject('locales/ko.json',lambda x:x.pop('ui.title'),'missing=')
    def test_obsolete_key(self):self.reject('locales/ko.json',lambda x:x.update({'obsolete.key':'text'}),'obsolete=')
    def test_empty_value(self):self.reject('locales/ko.json',lambda x:x.update({'ui.title':' '}),'empty=')
    def test_invalid_placeholder(self):self.reject('locales/ko.json',lambda x:x.update({'ui.type_number':'{number}'}),'Placeholder')
    def test_unsafe_escape(self):self.reject('locales/ko.json',lambda x:x.update({'ui.title':'a\\b'}),'escape')
    def test_warning_overflow(self):self.reject('locales/ko.json',lambda x:x.update({'ui.warn_20':'long '*100}),'Critical warning overflow')
    def test_missing_glyph_precise_code(self):self.reject('locales/en.json',lambda x:x.update({'ui.title':'é'}),r'U\+00E9')
    def test_font_license_permission(self):self.reject('locales/fonts.json',lambda x:x['galmuri14'].update(reviewed=False),'redistribution')
    def test_font_license_digest(self):self.reject('locales/fonts.json',lambda x:x['galmuri14'].update(licenseSha256='0'*64),'license digest')
    def test_font_ancestor_traversal(self):self.reject('locales/fonts.json',lambda x:x['galmuri14'].update(source='integration/assets/../../secrets.gz'),'Unsafe font path')
    def test_font_source_digest(self):self.reject('locales/fonts.json',lambda x:x['galmuri14'].update(sha256='0'*64),'checksum')
    def test_draft_not_enabled(self):self.reject('locales/languages.json',lambda x:x['languages'][1].update(status='draft'),'Draft')
    def test_unknown_metadata(self):self.reject('locales/languages.json',lambda x:x['languages'][0].update(script='exec'),'Unknown locale metadata')
    def test_shaping_not_claimed(self):self.reject('locales/languages.json',lambda x:x['languages'][0].update(shaping='automatic'),'Shaping')

    def test_option_and_progress_overflow(self):
        original=loc.load(self.root/'locales/ko.json')
        for key in ['ending.family','guidance.friend_s_call','ui.progress_compact']:
            data=dict(original);data[key]='Long label '*25+(' {met}/{total}' if key=='ui.progress_compact' else '')
            loc.write(self.root/'locales/ko.json',data)
            with self.subTest(key=key),self.assertRaisesRegex(ValueError,'overflow'):loc.validate(self.root)

    def test_metadata_and_text_bounds(self):
        with self.assertRaisesRegex(ValueError,'2048'):loc.unicode_check('a'*2049,'test')
        self.reject('locales/languages.json',lambda x:x['languages'][1].update(tag='en-'+('x-'*40)+'x'),'locale tag')

    def test_unicode_limits(self):
        for value in ['e\u0301','\u200b','\u202e','\U0001f600','\u0627','\u0915','\u1100','a\nb','a#b','a\t','\ua800','\u1820']:
            with self.subTest(value=repr(value)),self.assertRaises(ValueError):loc.unicode_check(value,'test')
        for value in ['é','가','漢','Deutsch','123']:loc.unicode_check(value,'supported scalar')

    def test_fallback_explicit_and_validated(self):
        self.change('locales/languages.json',lambda x:x['languages'][1].update(fallbackPolicy='fallback-en',enabled=False,status='draft'))
        self.change('locales/ko.json',lambda x:x.pop('ui.title'))
        result=loc.validate(self.root,tag='ko');self.assertEqual(result[0]['fallbackKeys'],['ui.title'])
        self.assertEqual(loc.text('ui.title','ko',self.root),'ROUTEKEEPER')
        self.assertNotIn('text_1.gml',loc.generated(self.root))

    def test_font_source_unicode_metrics(self):
        font=loc.font_module(self.root);glyphs=font.glyph_source()
        for code in [ord(c) for c in 'é가漢123']:
            self.assertIn(code,glyphs)
            advance,pixels,_=glyphs[code];self.assertGreater(advance,0)
            self.assertTrue(all(0<=x<24 and 0<=y<18 for x,y in pixels))
        with self.assertRaises(ValueError):loc.wrap('W',1,lambda s:len(s)*8)
        self.assertGreater(len(loc.wrap('Donaudampfschifffahrtsgesellschaft',50,lambda s:len(s)*8)),1)

    def test_registry_paging_and_stable_tags(self):
        original=loc.registry(self.root)
        for count in [1,2,3,5,10,19,32]:
            data=copy.deepcopy(original);data['languages']=data['languages'][:min(count,2)]
            while len(data['languages'])<count:
                item=copy.deepcopy(data['languages'][0]);item.update(tag='en-x-'+str(len(data['languages'])),name='English test');item.pop('legacyValue');data['languages'].append(item)
                loc.write(self.root/f"locales/{item['tag']}.json",loc.load(self.root/'locales/en.json'))
            loc.write(self.root/'locales/languages.json',data)
            sources=loc.generated(self.root);self.assertIn(f'return {count};',sources['locale_count.gml'])
            for selected in range(count):
                first=selected//7*7;self.assertIn(selected,range(first,min(first+7,count)))
                for delta in [-1,0,1]:self.assertTrue(0<=(selected+delta+count)%count<count)
                self.assertIn(f'argument0 == "{data["languages"][selected]["tag"]}"',sources['locale_index.gml'])
            if count==1:self.assertNotIn('argument0 == 1',sources['locale_legacy.gml'])

    def test_additional_registered_bitmap_font_needs_no_injection_edit(self):
        fonts=loc.load(self.root/'locales/fonts.json');fonts['demo']=dict(fonts['galmuri14'],resource='fnt_routekeeper_demo')
        loc.write(self.root/'locales/fonts.json',fonts)
        registry=loc.registry(self.root);item=dict(registry['languages'][1],tag='ko-x-font',name='한국어 시험',font='demo');item.pop('legacyValue')
        registry['languages'].append(item);loc.write(self.root/'locales/languages.json',registry)
        loc.write(self.root/'locales/ko-x-font.json',loc.load(self.root/'locales/ko.json'))
        self.assertEqual(len(loc.validate(self.root)),3)
        font=loc.font_module(self.root);self.assertEqual(font.build_fonts(),2);font.build_fonts(verify=True)
        manifest=loc.load(self.root/'integration/assets/fonts/manifest.json')
        self.assertEqual({x['resource'] for x in manifest},{'fnt_routekeeper','fnt_routekeeper_demo'})
        self.assertIn('return fnt_routekeeper_demo;',loc.generated(self.root)['locale_font.gml'])

    def test_bitmap_source_limits_before_unbounded_work(self):
        source=self.root/'integration/assets/font-source/routekeeper-korean.bdf.gz'
        source.write_bytes(gzip.compress(b' '*(16*1024*1024+1)))
        with self.assertRaisesRegex(ValueError,'exceeds 16MiB'):loc.validate(self.root)
        raw=b'STARTCHAR test\nENCODING 65\nDWIDTH 10 0\nBBX 1000000 1 0 0\nBITMAP\nFF\nENDCHAR\n'
        source.write_bytes(gzip.compress(raw))
        self.change('locales/fonts.json',lambda x:x['galmuri14'].update(sha256=hashlib.sha256(raw).hexdigest()))
        with self.assertRaisesRegex(ValueError,'glyph metadata'):loc.validate(self.root)

    def test_generated_font_output_links_fail_without_overwriting(self):
        font=loc.font_module(self.root);outside=self.root/'sentinel';outside.write_bytes(b'untouched')
        folder=self.root/'integration/assets/fonts/galmuri14';folder.mkdir(parents=True)
        target=folder/'ui-font.png'
        try:target.symlink_to(outside)
        except OSError:self.skipTest('Symlink creation is unavailable; native reparse behavior NOT_RUN')
        with self.assertRaisesRegex(ValueError,'Linked generated output'):font.build_fonts()
        self.assertEqual(outside.read_bytes(),b'untouched')
        self.assertFalse(list(folder.glob('.rk-generation-*')))

    def test_legacy_gml_quotes_are_not_json_escapes(self):
        self.assertEqual(loc.gml_string('English "demo"'),'"English " + chr(34) + "demo" + chr(34) + ""')
        self.assertEqual(loc.gml_string("friend's"),'"friend\'s"')
        self.assertNotIn('\\',loc.gml_string('He said "yes".'))

    def test_generated_translation_literals_match_data(self):
        sources=loc.generated(self.root)
        for i,language in enumerate(loc.enabled(self.root)):
            dictionary=loc.load(self.root/f"locales/{language['tag']}.json")
            for key,value in dictionary.items():
                statement=f'if (argument0 == {json.dumps(key)}) return {json.dumps(value,ensure_ascii=False)};'
                self.assertIn(statement,sources[f'text_{i}.gml'])
        self.assertEqual(sources,loc.generated(self.root))
        self.assertTrue(all('\r' not in value for value in sources.values()))

    def test_gameplay_and_settings_are_language_neutral(self):
        for path in (ROOT/'integration/gml').glob('*.gml'):
            if path.name.startswith(('text_','locale_')):continue
            self.assertNotIn('rk_language == 1',path.read_text(encoding='utf-8'),path.name)
        create=(ROOT/'integration/gml/controller_create.gml').read_text(encoding='utf-8')
        step=(ROOT/'integration/gml/controller_step.gml').read_text(encoding='utf-8')
        draw=(ROOT/'integration/gml/controller_draw.gml').read_text(encoding='utf-8')
        self.assertIn('scr_routekeeper_locale_legacy',create);self.assertIn('scr_routekeeper_locale_index(saved_locale)',create)
        self.assertIn('ini_write_string("Guidance", "locale"',step)
        self.assertIn('mod scr_routekeeper_locale_count()',step)
        self.assertIn('rk_menu_page == 5) options = scr_routekeeper_locale_count()',step)
        self.assertIn('rk_menu_page == 5) draw_set_font(scr_routekeeper_locale_font(index))',draw)
        self.assertIn('scr_routekeeper_warning_session(3, 0, "", 0)',step)

    @unittest.skipUnless(os.environ.get('ROUTEKEEPER_LOCALE_E2E')=='1','Enable ROUTEKEEPER_LOCALE_E2E=1 for isolated SDK contributor build')
    def test_contributor_add_translate_build_without_rule_edits(self):
        for name in ['src','tests','tools','integration','profiles']:
            shutil.copytree(ROOT/name,self.root/name,dirs_exist_ok=True,ignore=shutil.ignore_patterns('bin','obj','__pycache__'))
        for name in ['RouteKeeper.slnx','global.json','Directory.Build.props','NuGet.Config']:
            if (ROOT/name).exists():shutil.copyfile(ROOT/name,self.root/name)
        rules={str(p.relative_to(self.root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (self.root/'src').rglob('*.cs') if 'obj' not in p.parts and 'bin' not in p.parts}
        def run(*args):
            result=subprocess.run(args,cwd=self.root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',timeout=240)
            self.assertEqual(result.returncode,0,result.stdout[-4000:])
        run('python','tools/localization.py','add','--locale','en-x-demo','--name','English demo','--font','native-en')
        draft=loc.load(self.root/'locales/en-x-demo.json');self.assertTrue(all(v=='' for v in draft.values()))
        self.assertEqual(set(draft),set(loc.load(self.root/'locales/en.json')))
        demo=loc.load(self.root/'locales/en.json');demo['ui.title']='English \"demo\"'
        loc.write(self.root/'locales/en-x-demo.json',demo)
        def enable(data):data['languages'][-1].update(enabled=True,status='complete')
        self.change('locales/languages.json',enable)
        run('python','tools/localization.py','build')
        run('python','tools/localization.py','build','--verify')
        run('dotnet','run','--project','tests/RouteKeeper.Core.Tests','-c','Release','--no-build','--','--verify-locales')
        self.assertIn('English demo',(self.root/'integration/gml/locale_name.gml').read_text(encoding='utf-8'))
        self.assertTrue((self.root/'integration/gml/text_2.gml').is_file())
        self.assertEqual(rules,{str(p.relative_to(self.root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (self.root/'src').rglob('*.cs') if 'obj' not in p.parts and 'bin' not in p.parts})
        original=os.environ.get('ROUTEKEEPER_LOCALE_AUTHENTIC');cli=os.environ.get('ROUTEKEEPER_LOCALE_CLI')
        if original and cli:
            original=str(Path(original).resolve(strict=True));cli=str(Path(cli).resolve(strict=True))
            before=hashlib.sha256(Path(original).read_bytes()).hexdigest()
            self.assertEqual(before,'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7')
            fonts=loc.load(self.root/'locales/fonts.json');fonts['test-galmuri']=dict(fonts['galmuri14'],resource='fnt_routekeeper_demo')
            loc.write(self.root/'locales/fonts.json',fonts)
            run('python','tools/localization.py','add','--locale','ko-x-demo','--name','한국어 시험','--font','test-galmuri')
            loc.write(self.root/'locales/ko-x-demo.json',loc.load(self.root/'locales/ko.json'))
            self.change('locales/languages.json',enable)
            run('python','tools/localization.py','build')
            output=str(self.root/'private-candidate.win')
            run(cli,'load',original,'-s','integration/patch.csx','-o',output)
            environment=dict(os.environ,ROUTEKEEPER_ORIGINAL=original)
            result=subprocess.run([cli,'load',output,'-s','integration/verify.csx'],cwd=self.root,env=environment,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=240)
            # Compiler/decompiled diagnostics stay private; expose no original content.
            self.assertEqual(result.returncode,0,'Private authentic multi-locale resource verification failed')
            self.assertEqual(hashlib.sha256(Path(original).read_bytes()).hexdigest(),before)
            self.assertEqual(rules,{str(p.relative_to(self.root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (self.root/'src').rglob('*.cs') if 'obj' not in p.parts and 'bin' not in p.parts})
            print('OFFLINE_PASS four locales/two registered fonts authentic compile/serialize/reload/preservation; gameplay NOT_RUN')



if __name__=='__main__':unittest.main(verbosity=2)
