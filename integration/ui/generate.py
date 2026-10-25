#!/usr/bin/env python3
"""Shared geometry, localization and navigation for native GML and offline previews."""
import json,argparse
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CAT=json.loads((ROOT/'ui/catalog.json').read_text())
def sources():
    text='// Generated from ui/catalog.json.\n'
    for key,values in CAT['text'].items():
        text+=f'if (argument0 == "{key}") {{ if (argument1 == 1) return {json.dumps(values[1],ensure_ascii=False)}; return {json.dumps(values[0])}; }}\n'
    text+='return "";\n'
    layout='// Generated logical 320x240 geometry; native GUI output scales by two.\n'
    for key,value in CAT['layout'].items():layout+=f'global.rk_ui_{key} = {value};\n'
    nav='// Generated single-step wrap navigation; count must be positive.\nif (argument2 < 1) return 0;\nvar next; next = argument0 + argument1;\nif (next < 0) return argument2 - 1;\nif (next >= argument2) return 0;\nreturn next;\n'
    return {'ui_catalog.gml':text,'ui_layout.gml':layout,'ui_nav.gml':nav}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--verify',action='store_true');args=p.parse_args()
    for name,data in sources().items():
        path=ROOT/'gml'/name
        if args.verify:
            if path.read_text()!=data:raise SystemExit('Stale UI source '+name)
        else:path.write_text(data)
    print('PASS shared UI source '+('verified' if args.verify else 'generated'))
