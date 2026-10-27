#!/usr/bin/env python3
"""Shared geometry, localization and navigation for native GML and offline previews."""
import json
import argparse
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT.parent/'tools'))
import localization  # noqa: E402 - tools path must be registered first.
CAT=json.loads((ROOT/'ui/catalog.json').read_text(encoding='utf-8'))
CAT['text']={k[3:]:[localization.text(k,i) for i,_ in enumerate(localization.enabled())] for k in localization.load(ROOT.parent/'locales/en.json') if k.startswith('ui.')}
def sources():
    text='// Generated locale-independent UI lookup.\nreturn scr_routekeeper_text("ui." + argument0, argument1);\n'
    layout='// Generated logical 320x240 geometry; native GUI output scales by two.\n'
    for key,value in CAT['layout'].items():layout+=f'global.rk_ui_{key} = {value};\n'
    nav='// Generated single-step wrap navigation; count must be positive.\nif (argument2 < 1) return 0;\nvar next; next = argument0 + argument1;\nif (next < 0) return argument2 - 1;\nif (next >= argument2) return 0;\nreturn next;\n'
    return {'ui_catalog.gml':text,'ui_layout.gml':layout,'ui_nav.gml':nav}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--verify',action='store_true');args=p.parse_args()
    for name,data in sources().items():
        path=ROOT/'gml'/name
        if args.verify:
            if path.read_text(encoding='utf-8')!=data:raise SystemExit('Stale UI source '+name)
        else:path.write_text(data, encoding='utf-8', newline='\n')
    print('PASS shared UI source '+('verified' if args.verify else 'generated'))
