#!/usr/bin/env python3
"""Data-only localization validation, generation, templates and offline previews."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import stat
import subprocess
import sys
import unicodedata

ROOT = Path(__file__).resolve().parents[1]
TAG = re.compile(r'[a-z]{2,3}(?:-[a-z0-9]{1,8})*\Z')
PLACEHOLDER = re.compile(r'\{([a-z_]+)\}')


def load(path):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result: raise ValueError('Duplicate JSON key: ' + key)
            result[key] = value
        return result
    return json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=unique)


def write(path, value):
    font_module().publish(path,(json.dumps(value,ensure_ascii=False,indent=2,sort_keys=True)+'\n').encode('utf-8'))


def registry(root=ROOT):
    value = load(root/'locales/languages.json')
    if value.get('schema') != 1 or value.get('fallback') != 'en': raise ValueError('Unsupported locale registry')
    seen = set()
    for item in value['languages']:
        if not isinstance(item.get('enabled'),bool) or not isinstance(item.get('name'),str):raise ValueError('Invalid locale metadata types')
        if (not isinstance(item['tag'],str) or len(item['tag'])>63 or not TAG.fullmatch(item['tag'])) or item['tag'] in seen: raise ValueError('Invalid/duplicate locale tag')
        seen.add(item['tag'])
        if set(item)-{'tag','name','enabled','status','font','legacyValue','direction','shaping','fallbackPolicy'}: raise ValueError('Unknown locale metadata')
        if item['direction'] != 'ltr' or item['shaping'] != 'none': raise ValueError('Shaping/bidi are not verified')
        if item['fallbackPolicy'] not in ('strict','fallback-en'): raise ValueError('Unknown fallback policy')
        if item['status'] not in ('draft','complete'): raise ValueError('Unknown translation status')
        if item['enabled'] and item['status'] != 'complete': raise ValueError('Draft locale cannot be enabled')
        if item.get('legacyValue') is not None and (item['tag'],item['legacyValue']) not in [('en',0),('ko',1)]: raise ValueError('Legacy values are reserved')
    enabled = [x for x in value['languages'] if x['enabled']]
    if not enabled or enabled[0]['tag'] != 'en' or len(enabled)>32: raise ValueError('English first; at most32 enabled locales')
    if any(x['tag']=='ko' for x in enabled) and enabled[1]['tag']!='ko': raise ValueError('Preserve legacy Korean index1')
    return value


def enabled(root=ROOT): return [x for x in registry(root)['languages'] if x['enabled']]


def text(key, language=0, root=ROOT):
    languages = enabled(root)
    tag = language if isinstance(language,str) else languages[language]['tag'] if 0<=language<len(languages) else 'en'
    base = load(root/'locales/en.json')
    dictionary = load(root/f'locales/{tag}.json') if any(x['tag']==tag for x in languages) else base
    return dictionary.get(key) or base[key]


def unicode_check(value, where):
    if not isinstance(value,str) or not value.strip(): raise ValueError(where+': empty/non-string translation')
    if len(value)>2048:raise ValueError(where+': text exceeds 2048-character bound')
    if unicodedata.normalize('NFC',value) != value: raise ValueError(where+': use NFC normalization')
    for char in value:
        n=ord(char); category=unicodedata.category(char)
        if n>0xffff or category[0]=='C' or category in ('Mn','Mc','Me','Zl','Zp') or unicodedata.bidirectional(char) in ('R','AL','AN'):
            raise ValueError(f'{where}: unsupported U+{n:04X} (control/non-BMP/combining/bidi)')
        scalar_scripts=((0x20,0x7e),(0xa0,0x24f),(0x370,0x52f),(0x1e00,0x1eff),(0x2000,0x206f),(0x2190,0x22ff),(0x2500,0x25ff),(0x2e80,0x30ff),(0x31f0,0x31ff),(0x3400,0x4dbf),(0x4e00,0x9fff),(0xac00,0xd7a3),(0xf900,0xfaff),(0xff01,0xff60))
        if not any(first<=n<=last for first,last in scalar_scripts):
            raise ValueError(f'{where}: script/layout is unverified U+{n:04X}')
        if char in ('\\','#'): raise ValueError(where+': legacy escape/newline syntax is unsupported')


def font_sources(root=ROOT):
    fonts=load(root/'locales/fonts.json')
    for key, f in fonts.items():
        if not re.fullmatch('[a-z][a-z0-9_-]*',key): raise ValueError('Invalid font ID')
        if f.get('kind')=='native':
            if key!='native-en' or f.get('resource')!='fnt_maintext' or f.get('baseline')!=14 or f.get('lineHeight')!=16:raise ValueError('Unverified native font')
            continue
        if f.get('kind')!='bdf' or not re.fullmatch(r'fnt_routekeeper[a-zA-Z0-9_]*',f.get('resource','')):raise ValueError('Unsupported font kind/resource')
        if f.get('license') not in ('OFL-1.1','MIT','CC0-1.0') or not f.get('reviewed'): raise ValueError('Font requires reviewed redistribution permission: '+key)
        for field in ('source','licenseFile'):
            relative=Path(f[field])
            if relative.is_absolute() or '..' in relative.parts or '\\' in f[field]:raise ValueError('Unsafe font path')
            path=root/relative
            if not path.is_relative_to(root/'integration/assets') and not path.is_relative_to(root/'locales/fonts'): raise ValueError('Font path outside permitted asset directories')
            if any(p.is_symlink() or (p.exists() and getattr(p.lstat(),'st_file_attributes',0)&stat.FILE_ATTRIBUTE_REPARSE_POINT) for p in [path,*path.parents]): raise ValueError('Linked font input refused')
            if not path.is_file(): raise ValueError('Missing font input '+str(path))
        if hashlib.sha256((root/f['licenseFile']).read_bytes()).hexdigest()!=f['licenseSha256']:raise ValueError('Font license digest mismatch')
        if type(f['baseline']) is not int or type(f['lineHeight']) is not int or not 1<=f['baseline']<=f['lineHeight']<=18: raise ValueError('Unsupported font metrics')
    if len({f['resource'] for f in fonts.values()})!=len(fonts):raise ValueError('Duplicate font resource')
    return fonts


def font_module(root=ROOT):
    spec=importlib.util.spec_from_file_location('rk_font',root/'integration/generate_font.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module


def validate(root=ROOT, tag=None):
    languages=enabled(root);base=load(root/'locales/en.json');context=load(root/'locales/context.json');fonts=font_sources(root)
    if set(base)!=set(context):raise ValueError('Canonical/context key drift')
    for key,value in base.items():
        if not re.fullmatch(r'[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+',key):raise ValueError('Invalid semantic text ID '+key)
        if set(PLACEHOLDER.findall(value))!=set(context[key]['placeholders']):raise ValueError('Canonical placeholder/context drift '+key)
        if set(context[key].get('optionalPlaceholders',[]))-set(context[key]['placeholders']):raise ValueError('Invalid optional placeholder '+key)
    selected=languages if tag is None else [x for x in registry(root)['languages'] if x['tag']==tag]
    if not selected:raise ValueError('Unknown locale')
    font=font_module(root)
    results=[]
    for locale in selected:
        dictionary=load(root/f"locales/{locale['tag']}.json")
        missing=sorted(set(base)-set(dictionary));obsolete=sorted(set(dictionary)-set(base));empty=sorted(k for k,v in dictionary.items() if not isinstance(v,str) or not v.strip())
        if obsolete or empty or (missing and (locale['enabled'] or locale['fallbackPolicy']!='fallback-en')):raise ValueError(f"{locale['tag']}: missing={missing}; obsolete={obsolete}; empty={empty}")
        if locale['font'] not in fonts:raise ValueError('Unregistered font '+locale['font'])
        glyphs=font.glyph_source(locale['font']) if locale['font']!='native-en' else None
        for key in base:
            value=dictionary.get(key,base[key])
            unicode_check(value,locale['tag']+':'+key)
            actual=set(PLACEHOLDER.findall(value));expected=set(context[key]['placeholders']);optional=set(context[key].get('optionalPlaceholders',[]))
            if actual-expected or expected-optional-actual or '{' in PLACEHOLDER.sub('',value) or '}' in PLACEHOLDER.sub('',value):raise ValueError('Placeholder mismatch '+locale['tag']+':'+key)
            expanded=PLACEHOLDER.sub(lambda m:'99999' if m[1] in ('remaining','met','total','index','button') else 'mettaton',value)
            codes=[ord(c) for c in expanded]
            absent=sorted({c for c in codes if c<32 or c>126} if glyphs is None else set(codes)-set(glyphs))
            if absent:raise ValueError(locale['tag']+':'+key+': missing glyphs '+','.join(f'U+{c:04X}' for c in absent))
            if glyphs:
                for code in set(codes):
                    advance,ink,offset=glyphs[code]
                    if not 0<=advance<=24 or not -24<=offset<=24 or any(not (0<=x<24 and 0<=y<fonts[locale['font']]['lineHeight']) for x,y in ink):raise ValueError(f'Invalid/clipped font metrics U+{code:04X}')
            # Critical warnings must wrap within the original three-line box.
            widths=lambda s:sum((glyphs[ord(c)][0] if glyphs else font.native_advance(ord(c))) for c in s)
            lines=wrap('* '+expanded if key.startswith('ui.warn_') else expanded,264,widths)
            if key.startswith('ui.warn_') and len(lines)>3:raise ValueError('Critical warning overflow '+locale['tag']+':'+key)
            if key in ('ui.navigation','ui.pad_navigation','ui.close_warning','ui.retry_warning') and widths(expanded)>264:raise ValueError('Instruction overflow '+key)
            if key.startswith('ui.') and key.split('.')[1] in ('goal','variant','guidance','spoilers','language','journal','back','ending_type','epilogue','call_goal') and widths(expanded)>94:raise ValueError('Menu label overflow '+key)
            if context[key].get('layout')=='menu_option' and widths(expanded)>252:raise ValueError('Menu option overflow '+key)
            if key=='ui.progress_compact' and widths(value.replace('{met}','17').replace('{total}','17'))>52:raise ValueError('HUD progress overflow '+key)
            if key in ('ui.pad_close_warning','ui.pad_retry_warning') and widths(expanded)+widths(': ')+64>264:raise ValueError('Controller footer overflow '+key)
            if key.startswith('input.') and widths(expanded)>64:raise ValueError('Controller label overflow '+key)
            if key.startswith('guidance.') and len(lines)>4:raise ValueError('Objective overflow '+locale['tag']+':'+key)
        unicode_check(locale['name'],locale['tag']+':name')
        if glyphs is None and any(ord(c)>126 for c in locale['name']):raise ValueError('Native font cannot draw locale name')
        if glyphs and any(ord(c) not in glyphs for c in locale['name']):raise ValueError('Locale self-name lacks glyphs')
        if widths(locale['name'])>152:raise ValueError('Locale self-name overflows menu value')
        results.append({'locale':locale['tag'],'strings':len(dictionary),'fallbackKeys':missing,'font':locale['font'],'status':'OFFLINE_VALIDATED'})
    return results


def wrap(text,width,measure):
    lines=[]
    while text:
        take=0;space=0
        for n in range(1,len(text)+1):
            if measure(text[:n])>width:break
            take=n
            if text[n-1]==' ':space=n
        if not take:raise ValueError('Glyph wider than layout')
        if take<len(text) and space:take=space
        lines.append(text[:take]);text=text[take:].lstrip(' ')
    return lines


def gml_string(value):
    # GML1 non-YYC strings have no JSON-style backslash escape. Translation
    # controls/backslashes are rejected; a quote is emitted as builtin chr(34).
    return ' + chr(34) + '.join('"'+part+'"' for part in value.split('"'))


def generated(root=ROOT):
    languages=enabled(root);base=load(root/'locales/en.json');files={}
    # Short dispatch script; each locale has its own bounded code resource.
    dispatch='// Generated from locales; unknown locale/key falls back to English.\n'
    for i,locale in enumerate(languages):
        dispatch+=f'if (argument1 == {i}) return scr_routekeeper_text_{i}(argument0);\n'
        dictionary=load(root/f"locales/{locale['tag']}.json")
        body='// Generated translation dictionary; no gameplay rules.\n'
        for key in sorted(base):body+=f'if (argument0 == {json.dumps(key)}) return {gml_string(dictionary.get(key) or base[key])};\n'
        body+=('return "";\n' if i==0 else 'return scr_routekeeper_text_0(argument0);\n')
        files[f'text_{i}.gml']=body
    files['text.gml']=dispatch+'return scr_routekeeper_text_0(argument0);\n'
    files['locale_count.gml']=f'// Generated locale count.\nreturn {len(languages)};\n'
    for name,field,fallback in [('locale_tag','tag','en'),('locale_name','name','English')]:
        files[name+'.gml']='// Generated registry.\n'+''.join(f'if (argument0 == {i}) return {gml_string(l[field])};\n' for i,l in enumerate(languages))+f'return {gml_string(fallback)};\n'
    files['locale_index.gml']='// Generated tag lookup.\n'+''.join(f'if (argument0 == {json.dumps(l["tag"])}) return {i};\n' for i,l in enumerate(languages))+'return 0;\n'
    files['locale_legacy.gml']='// Generated old settings migration.\n'+''.join(f'if (argument0 == {l["legacyValue"]}) return {i};\n' for i,l in enumerate(languages) if 'legacyValue' in l)+'return 0;\n'
    sources=font_sources(root)
    files['locale_font.gml']='// Generated font selection.\n'+''.join(f'if (argument0 == {i}) return {sources[l["font"]]["resource"]};\n' for i,l in enumerate(languages))+'return fnt_maintext;\n'
    files['locale_line_height.gml']='// Generated locale line height.\n'+''.join(f'if (argument0 == {i}) return {sources[l["font"]]["lineHeight"]};\n' for i,l in enumerate(languages))+'return 16;\n'
    return files


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('command',choices=['add','validate','build','preview','coverage']);p.add_argument('--locale');p.add_argument('--name');p.add_argument('--font',default='galmuri14');p.add_argument('--verify',action='store_true');p.add_argument('--output',type=Path);a=p.parse_args()
    if a.command=='add':
        if not a.locale or (len(a.locale)>63 or not TAG.fullmatch(a.locale)) or not a.name:raise ValueError('Supply a valid --locale and --name')
        value=registry();path=ROOT/f'locales/{a.locale}.json'
        if path.exists() or any(x['tag']==a.locale for x in value['languages']):raise ValueError('Locale already exists')
        value['languages'].append(dict(tag=a.locale,name=unicodedata.normalize('NFC',a.name),enabled=False,status='draft',font=a.font,direction='ltr',shaping='none',fallbackPolicy='strict'))
        write(path,{key:'' for key in load(ROOT/'locales/en.json')})
        write(ROOT/f'locales/templates/{a.locale}.context.json',{key:dict(source=text,**load(ROOT/'locales/context.json')[key]) for key,text in load(ROOT/'locales/en.json').items()})
        write(ROOT/'locales/languages.json',value);print('Created disabled draft; translate, mark complete and enable before build.');return
    if a.command=='coverage':
        base=load(ROOT/'locales/en.json')
        for l in registry()['languages']:
            d=load(ROOT/f"locales/{l['tag']}.json");print(l['tag'],sum(bool(d.get(k)) for k in base),'/',len(base),'enabled='+str(l['enabled']))
        return
    print(json.dumps(validate(tag=a.locale if a.command=='validate' else None),ensure_ascii=False))
    if a.command=='validate':return
    if a.command=='preview':
        sys.path.insert(0,str(ROOT/'integration/ui'))
        from preview import Renderer
        locale=next((i for i,x in enumerate(enabled()) if x['tag']==a.locale),None)
        if locale is None:raise ValueError('Preview requires an enabled validated locale')
        target=a.output or ROOT/'artifacts'/('locale-preview-'+a.locale);target.mkdir(parents=True,exist_ok=True)
        for scenario in ['menu','warning','progress','languages']:
            r=Renderer(locale)
            if scenario=='menu':r.menu()
            elif scenario=='warning':r.warning(20,True)
            elif scenario=='languages':r.languages(locale)
            else:r.hud(text('ui.no_objective',locale))
            r.save(target/(scenario+'.png'))
        write(target/'evidence.json',{'kind':'OFFLINE_PREVIEW','gameplay':'NOT_RUN','locale':a.locale,'englishOutlines':'Galmuri proxy; native English advance metrics','font':enabled()[locale]['font'],'warningLayout':'validated without truncating critical text'})
        print('OFFLINE_PREVIEW; gameplay NOT_RUN',target);return
    paths=generated()
    target=ROOT/'integration/gml'
    for name,source in paths.items():
        file=target/name
        font_module().publish(file,source.encode('utf-8'),verify=a.verify)
    for file in target.glob('text_[0-9]*.gml'):
        if file.name not in paths:
            if a.verify:raise ValueError('Obsolete locale output '+file.name)
            file.unlink()
    font=font_module();font.build_fonts(verify=a.verify)
    if not a.verify:
        subprocess.run(['dotnet','build','RouteKeeper.slnx','-c','Release'],cwd=ROOT,check=True)
        for project,option in [('Core','--emit-native'),('Neutral','--emit-gml'),('Decisions','--emit-adapters')]:
            subprocess.run(['dotnet','run','--project',f'tests/RouteKeeper.{project}.Tests','-c','Release','--no-build','--',option,'integration/gml'],cwd=ROOT,check=True)
        subprocess.run([sys.executable,'integration/ui/generate.py'],cwd=ROOT,check=True)
    if a.verify:
        for project,option,path in [('Core','--verify-gml','integration/gml/route_evaluate.gml'),('Neutral','--verify-gml','integration/gml'),('Decisions','--verify-adapters','integration/gml')]:
            subprocess.run(['dotnet','run','--project',f'tests/RouteKeeper.{project}.Tests','-c','Release','--no-build','--',option,path],cwd=ROOT,check=True)
        subprocess.run([sys.executable,'integration/ui/generate.py','--verify'],cwd=ROOT,check=True)
    print('PASS deterministic localization '+('freshness' if a.verify else 'build')+'; gameplay NOT_RUN')

if __name__=='__main__':
    try:main()
    except (ValueError,KeyError,TypeError,subprocess.CalledProcessError) as error:raise SystemExit('FAIL '+str(error))
