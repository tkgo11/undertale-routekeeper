#!/usr/bin/env python3
"""Derive numeric golden fixtures from authorized original GML, never Core tables.

This executes a restricted conditional/assignment slice, not the GameMaker VM.
Only facts, hashes and small dialogue-slot categories leave the private directory.
"""
import argparse,ast,hashlib,itertools,json,re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--verify',action='store_true');a=p.parse_args()
sources={}
def read(name):
 s=(a.source/(name+'.gml')).read_text();sources[name]=hashlib.sha256(s.encode()).hexdigest();return s

def body(source,anchor):
 start=source.index('{',source.index(anchor));depth=1;end=start+1
 while depth:
  depth+=(source[end]=='{')-(source[end]=='}');end+=1
 return source[start+1:end-1]

def expression(s):
 s=re.sub(r'global.flag\[(\d+)\]',r'f\1',s).replace('scr_murderlv()','stage').replace('ossafe_file_exists("file0")','save').replace('ossafe_file_exists("undertale.ini")','1')
 s=s.replace('global.','').replace('&&',' and ').replace('||',' or ')
 tree=ast.parse(s,mode='eval')
 if any(not isinstance(n,(ast.Expression,ast.BoolOp,ast.And,ast.Or,ast.Compare,ast.Name,ast.Load,ast.Constant,ast.Eq,ast.NotEq,ast.Lt,ast.LtE,ast.Gt,ast.GtE,ast.UnaryOp,ast.USub,ast.BinOp,ast.Add,ast.Sub)) for n in ast.walk(tree)):raise ValueError('Unsupported original predicate')
 return s

def compile_slice(source):
 lines=[];indent=0
 for line in source.splitlines():
  line=line.strip()
  if not line:continue
  if line=='{':indent+=1;lines.append(' '*indent+'pass');continue
  if line=='}':indent-=1;continue
  if line.startswith('if ('):line='if '+expression(line[4:-1])+':'
  elif line=='else':line='else:'
  elif m:=re.fullmatch(r'(q|con|mrd|murderboy|qualify|d|requested|f56|murder|special_end|skip) = (.*);',line):line=m[1]+' = '+expression(m[2])
  elif m:=re.fullmatch(r'global.msg\[(\d+)\] = scr_gettext\("obj_mainend_(\d+)"\);',line):line=f'slots[{m[1]}] = {m[2]}'
  elif m:=re.fullmatch(r'ini_write_real\("([^"]+)", "([^"]+)", ([^;]+)\);',line):line=f'writes[{m[1]+"."+m[2]!r}] = '+expression(m[3])
  elif line=='scr_itemget(16);':line='requested = 1'
  elif m:=re.fullmatch(r'global.flag\[56\] = (\d+);',line):line='f56 = '+m[1]
  else:continue
  lines.append(' '*indent+line)
 return compile('\n'.join(lines),'<private original conditional slice>','exec')
def run(code,values):
 d=dict(values);d['slots']={};d['writes']={};exec(code,{'__builtins__':{}},d);return d
create=read('gml_Object_obj_mainend_Create_0');step=read('gml_Object_obj_mainend_Step_0')
selector=compile_slice(create[create.index('q = 20;'):create.index('if (q == 0 ||')])
blocks={n:compile_slice(body(step,f'if (con == {n}')) for n in [1,5,6,21,61]}
conditions=[]
opening=body(step,'if (con == 1)')
for predicate,key in re.findall(r'if \(([^\n]+)\)\s*\{\s*global.msg\[\d+\] = scr_gettext\("obj_mainend_(\d+)"\);',opening):
 key=int(key)
 if key in [169,177,186,195,204]:conditions.append((expression(predicate),{169:8,177:16,186:32,195:64,204:128}[key]))
def slot_kind(key):
 for lo,hi,name in [(169,172,'keepsake'),(177,180,'save'),(186,189,'armor'),(195,198,'healing'),(204,209,'composite'),(214,215,'late')]:
  if lo<=key<=hi:return name
 return 'base'
def oracle(v):
 d=run(selector,v);q=d['q'];phone=run(blocks[5],d)
 if q==0:
  if phone['con']==6:ending=1
  else:
   # Identify this branch by its first original message assignment, not Core rules.
   friend_branch=body(body(step,'if (con == 5'),'if (global.kills >= 1')
   marker=re.search(r'global.msg\[(\d+)\] = scr_gettext\("obj_mainend_(\d+)"\);',friend_branch)
   befriended=phone['slots'].get(int(marker[1]))==int(marker[2])
   ending=(5 if v['f425']==1 else 4) if befriended else (3 if v['f425']==1 else 2)
 elif q==1:ending=9 if v['f350']==1 and v['f67']==1 else 8 if v['f350']==1 else 7 if v['f67']==1 else 6
 elif q==2:ending=11 if v['f67']==1 else 10
 elif q==3:ending=13 if v['f67']==1 else 12
 elif q==4:ending=14
 elif q==5:ending=17 if run(blocks[61],d)['slots'][15]==1074 else 16
 elif q==6:ending=15
 elif q==7:ending=18
 else:raise ValueError('Debug fallback excluded')
 mask=sum(bit for predicate,bit in conditions if eval(predicate,{'__builtins__':{}},v))
 if q==0 and phone['con']==6 and run(blocks[6],d)['slots'].get(35)==524:mask|=1
 if q==1:
  marker=run(blocks[21],d)['slots'].get(13)
  if marker==691:mask|=2
  if marker==695:mask|=4
 slots=run(blocks[1],dict(v,q=q))['slots']
 return [ending,q,mask,[slot_kind(slots.get(i,0)) for i in range(2,9)]]
rows=[]
for t,pap,u,m in itertools.product(range(2),repeat=4):
 for kills,friend,stage in itertools.product([0,1,4,5,9,10,19,20,21,56,57,58,95],[0,1,3,4],[0,12]):
  v=dict(f45=4*t,f67=pap,f350=u,f425=m,kills=kills,f389=friend,stage=stage,f493=10,haveit=1,save=0,armor=4,f260=0,lv=1)
  rows.append([[t,pap,u,m,kills,friend,stage,10,1,0,4,0,1],*oracle(v)])
# Every opening combination independently exercises overwrites (including q7).
for have,save,armor,healing,lv,pap in itertools.product(range(2),range(2),[4,12],range(2),[1,2],range(2)):
 v=dict(f45=0,f67=pap,f350=0,f425=0,kills=pap,f389=0,stage=0,f493=0,haveit=have,save=save,armor=armor,f260=healing,lv=lv)
 rows.append([[0,pap,0,0,pap,0,0,0,have,save,armor,healing,lv],*oracle(v)])
murder=read('gml_Script_scr_murderlv');murdercode=compile_slice(murder[:murder.index('return mrd;')]);requirements=[(202,20),(45,4),(52,1),(53,1),(54,1),(57,2),(203,16),(67,1),(81,1),(252,1),(204,18),(251,1),(350,1),(402,1),(397,1),(205,40),(425,1)]
murderrows=[]
base={f'f{k}':v for k,v in requirements};base.update(f26=0,f27=0)
for key,value in requirements+[(27,0)]:
 for actual in sorted({max(0,value-1),value,value+1}):
  v=dict(base);v['f'+str(key)]=actual;result=run(murdercode,v)['mrd'];murderrows.append([[v['f'+str(k)] for k,_ in requirements]+[v['f27']],result])
ratings=read('gml_Object_obj_mettatonex_Step_0');ratingcode=compile_slice(body(body(ratings,'if (global.mnfight == 1)'),'if (talked == 0)')[:body(body(ratings,'if (global.mnfight == 1)'),'if (talked == 0)').index('if (qualify == 0)')])
ratingrows=[]
for turn,score in itertools.product([0,18,19,20],[9999,10000,10001,11999,12000,12001]):ratingrows.append([turn,score,run(ratingcode,dict(turns=turn,ratings=score,qualify=0))['qualify']])
letter=read('gml_Object_obj_undyne_lettercall_Create_0');lettercode=compile_slice(letter[:letter.index('if (d == 1)')]);letterrows=[]
for won,friend,kills,plot,phase in itertools.product([0,1,2],[2,3,4],[0,1],[198,198.1,199],[0,7,8,10]):
 v=dict(won=won,f389=friend,kills=kills,plot=plot,f493=phase)
 letterrows.append([won,friend,kills,int(round(plot*10)),phase,1-run(lettercode,v)['d']])
text=read('gml_Script_SCR_TEXT');normal=compile_slice(text[text.index('    case 226:')+len('    case 226:'):text.index('    case 227:')].replace('break;',''))
first=compile_slice(body(text[text.index('    case 227:'):],'if (global.choice == 0)'))
snow=read('gml_Object_obj_nicesnowman_Alarm_0');geno=compile_slice(body(snow,'if (scr_murderlv() >= 2)'));snowrows=[]
for stage,state,taken,stored,carried,space in itertools.product([0,1,2,12],[0,1,2,4,5],[0,2,3],range(2),range(2),range(2)):
 v=dict(stage=stage,f56=state,f253=taken,haveit=carried,haveit2=stored,noroom=1-space,requested=0)
 if stage>=2:r=run(geno,v)
 elif state==0:r=run(first,v)
 else:r=run(normal,v)
 snowrows.append([stage,state,taken,stored,carried,space,r.get('requested',0)])
finalintro=read('gml_Object_obj_asgore_finalintro_Create_0')
finalcode=compile_slice(finalintro[finalintro.index('special_end = 0;'):finalintro.index('if (skip == 0 && murder == 0)')]);finalrows=[]
for phase,stage in itertools.product([0,10,11,12,13],[0,11,12,15,16]):finalrows.append([phase,stage,run(finalcode,dict(f493=phase,murder=1 if stage>=16 else 0))['special_end']])
reset=read('gml_Script_scr_namingscreen');resetcode=compile_slice(body(reset,'if (truereset > 0)'));resetrows=[]
for sk,won,cp,ch in itertools.product([0,1,2],repeat=4):resetrows.append([[sk,won,cp,ch],run(resetcode,dict(sk=sk,Won=won,CP=cp,CH=ch))['writes']])
# Hash source evidence without exporting original dialogue, media or saves.
for name in ['gml_Object_obj_mainchara_Step_0','gml_Script_scr_monsterdefeat','gml_Script_scr_steps','gml_Object_obj_battler_Create_0','gml_Object_obj_torielboss_Alarm_10','gml_Object_obj_torielboss_Destroy_0','gml_Object_obj_papyrusboss_Alarm_10','gml_Object_obj_undyneboss_Step_0','gml_Object_obj_mettatonex_Alarm_6','gml_Object_obj_lesserdoge_Destroy_0','gml_Object_obj_lesserdoge_Other_5','gml_Object_obj_asgore_finalintro_Create_0','gml_Script_scr_namingscreen','gml_Object_obj_intromenu_Create_0','gml_Object_obj_credits_short_Create_0','gml_Object_obj_truechara_Step_0','gml_Object_obj_endmyroom_Create_0','gml_Object_obj_the_end_really_Create_0','gml_Script_scr_storagecheck','gml_Object_obj_gameshake_Create_0','gml_Object_obj_nothingness_event_Step_0']:read(name)
a.output.parent.mkdir(parents=True,exist_ok=True)
result={'schema':1,'kind':'ORIGINAL_SOURCE_CONDITIONAL_SLICE','runtime':'NOT_RUN','domain':'Neutral selector cases include counterfactual snapshots; selection is not a reachability proof','inputSha256':'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7','sourceSha256':sources,'neutralColumns':['tDead','pDead','uDead','mDead','totalKills','friendship','murderStage','alphys','carried','saveExists','armor','healingUsed','level'],'neutral':rows,'murderFlagOrder':[k for k,_ in requirements]+[27],'murder':murderrows,'ratings':ratingrows,'letter':letterrows,'snowman':snowrows,'finale':finalrows,'trueReset':resetrows}
serialized=json.dumps(result,separators=(',',':')).replace('],[[','],\n[[').replace('],[','],\n[')+'\n'
if a.verify:
 if a.output.read_text()!=serialized:raise SystemExit('FAIL original golden fixture/source hash drift')
else:a.output.write_text(serialized)
print(f'PASS original-derived fixtures: Neutral={len(rows)}, murder={len(murderrows)}, ratings={len(ratingrows)}; no dialogue text exported')
