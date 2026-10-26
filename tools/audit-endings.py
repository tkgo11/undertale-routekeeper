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
 s=s.replace('global.flag[global.flag[200]]','regional').replace('global.monsterhp[myself]','hp')
 s=re.sub(r'global.flag\[(\d+)\]',r'f\1',s).replace('scr_murderlv()','stage').replace('ossafe_file_exists("file0")','save').replace('ossafe_file_exists("undertale.ini")','1')
 s=s.replace('global.','').replace('&&',' and ').replace('||',' or ')
 tree=ast.parse(s,mode='eval')
 if any(not isinstance(n,(ast.Expression,ast.BoolOp,ast.And,ast.Or,ast.Compare,ast.Name,ast.Load,ast.Constant,ast.Eq,ast.NotEq,ast.Lt,ast.LtE,ast.Gt,ast.GtE,ast.UnaryOp,ast.USub,ast.BinOp,ast.Add,ast.Sub,ast.Subscript)) for n in ast.walk(tree)):raise ValueError('Unsupported original predicate')
 return s

def compile_slice(source):
 lines=[];indent=0
 for line in source.splitlines():
  line=line.strip()
  if not line:continue
  line=line.replace('global.monsterhp[myself]','hp')
  if line=='{':indent+=1;lines.append(' '*indent+'pass');continue
  if line=='}':indent-=1;continue
  if line.startswith('if ('):line='if '+expression(line[4:-1])+':'
  elif line=='else':line='else:'
  elif m:=re.fullmatch(r'(q|con|mrd|murderboy|qualify|d|requested|f56|murder|special_end|skip) = (.*);',line):line=m[1]+' = '+expression(m[2])
  elif m:=re.fullmatch(r'global.msg\[(\d+)\] = scr_gettext\("obj_mainend_(\d+)"\);',line):line=f'slots[{m[1]}] = {m[2]}'
  elif m:=re.fullmatch(r'ini_write_real\("([^"]+)", "([^"]+)", ([^;]+)\);',line):line=f'writes[{m[1]+"."+m[2]!r}] = '+expression(m[3])
  elif m:=re.fullmatch(r'global.attacktype = (.*);',line):line='attacktype = '+expression(m[1])
  elif m:=re.fullmatch(r'turns -= (\d+);',line):line='turns -= '+m[1]
  elif m:=re.fullmatch(r'(?:global\.)?(xp|gold|inbattle|interact|regional|won|hp|prevhp|goodot|myplot|hitplot|d_con) ([-+]=|=) ([^();]+);',line.replace('global.flag[global.flag[200]]','regional')):line=m[1]+' '+m[2]+' '+expression(m[3])
  elif line=='room_goto(global.currentroom);':line='room_return = 1'
  elif line=='instance_destroy();':line='destroyed = 1'
  elif m:=re.fullmatch(r'global.lv = (\d+);',line):line='lv = '+m[1]
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
levelsource=read('gml_Script_scr_levelup');levelcode=compile_slice(levelsource[:levelsource.index('if (global.lv != currentlevel)')]);levels=[]
thresholds=[int(x) for x in re.findall(r'global.xp >= (\d+)',levelsource)]
for xp in sorted({0,1,*[v+d for v in thresholds for d in [-1,0,1]]}):levels.append([xp,run(levelcode,dict(xp=xp,lv=1))['lv']])
suppression=[]
for name,area,flag,deadline in [('gml_Object_obj_encounterer_tundra1_Create_0',1,203,100),('gml_Object_obj_encounterer_water1_Create_0',2,204,121)]:
 source=read(name);predicate=re.search(r'if \((global.flag\['+str(flag)+r'\] == 0 && global.plot > [0-9]+)\)',source)[1]
 code=compile_slice('if ('+predicate+')\n{\ninstance_destroy();\n}')
 for count,plot in itertools.product([0,1,16],[deadline-1,deadline,deadline+0.1,deadline+1]):
  v={f'f{flag}':count,'plot':plot,'destroyed':0};suppression.append([area,count,round(plot*10),run(code,v)['destroyed']])
for name in ['gml_Script_scr_monstersetup','gml_Script_scr_battlegroup','gml_Object_obj_loox_Step_0','gml_Object_obj_loox_Create_0','gml_Object_obj_vulkin_Create_0','gml_Object_obj_dummymonster_Destroy_0','gml_Object_obj_napstablook_Step_0','gml_Object_obj_maddummy_Alarm_7','gml_Object_obj_battlebomb_Destroy_0','gml_Object_obj_endflowey_Step_0','gml_Object_obj_dummytrigger_Step_0']:read(name)
attackbody=body(ratings,'if (turns >= 1)');attackcode=compile_slice('if (turns >= 1)\n{\n'+attackbody[:attackbody.index('if (global.attacktype >= 50)')]+'\n}');attackrows=[]
for turns in range(28):
 r=run(attackcode,dict(turns=turns,attacktype=0));attackrows.append([turns,r['turns'],r['attacktype']])
read('gml_Object_obj_mettatonex_Other_11');read('gml_Object_obj_ratingsmaster_Draw_0')
encounterRewards={}
setup=read('gml_Script_scr_monstersetup');groups=read('gml_Script_scr_battlegroup')
for obj,label in [('obj_loox','Loox'),('obj_vulkin','Vulkin')]:
 position=re.search(r'global.monsterinstance\[0\] = instance_create\([^;]*, '+obj+r'\);',groups).start()
 segment=groups[groups.rfind('    case ',0,position):position]
 monster=int(re.findall(r'global.monstertype\[0\] = (\d+);',segment)[-1])
 effect=body(setup,'if (global.monstertype[myself] == '+str(monster)+')')
 encounterRewards[label]=int(re.search(r'global.xpreward\[myself\] = (\d+);',effect)[1])
# Execute the original interaction entry predicate, not the legacy Alarm0
# weekday condition, for the optional post-friendship encounter.
art=read('gml_Object_obj_artclass_sign_Step_0')
artcode=compile_slice(body(art,'if (con == 0)'))
artrows=[]
for stage,resolved,end,letter,month,day,hour in itertools.product([0,11,12],[0,1,2],range(2),range(2),[9,10],[9,10],[7,8,20,21]):
 v=dict(murd=int(stage>=12),f281=resolved,f7=end,f8=letter,current_month=month,current_day=day,current_hour=hour,skip=0,con=0)
 artrows.append([stage,resolved,end,letter,month,day,hour,int(run(artcode,v)['con']==1)])
for obj,label in [('obj_jerry','Jerry'),('obj_sosorry','SoSorry'),('obj_napstablook','Napstablook')]:
 position=re.search(r'global.monsterinstance\[0\] = instance_create\([^;]*, '+obj+r'\);',groups).start()
 segment=groups[groups.rfind('    case ',0,position):position]
 monster=int(re.findall(r'global.monstertype\[0\] = (\d+);',segment)[-1])
 effect=body(setup,'if (global.monstertype[myself] == '+str(monster)+')')
 encounterRewards[label]=int(re.search(r'global.xpreward\[myself\] = (-?\d+);',effect)[1])
# So Sorry does not require a guessed damage/turn victory: repeated positive
# hits keep myplot from progressing to automatic spare, and hitplot10 makes
# the next hit force HP0. Execute original Step and Alarm6 numeric projections.
sorryStep=read('gml_Object_obj_sosorry_Step_0');sorryAlarm=read('gml_Object_obj_sosorry_Alarm_6')
hurt=body(sorryStep,'if (global.hurtanim[myself] == 2)')
hurtcode=compile_slice(hurt[:hurt.index('with (dmgwriter)')])
advancecode=compile_slice(sorryAlarm[:sorryAlarm.index('gg =')])
finish=body(sorryAlarm,'if (hitplot == 11)')
finish=re.sub(r'with \(obj_dmgwriter\)\s*\{.*?\}', '',finish,flags=re.S)
finishcode=compile_slice('if (hitplot == 11)\n{\n'+finish+'\n}')
state=dict(hp=1100,prevhp=1100,hitplot=0,myplot=0,p_mode=0,takedamage=35,d_con=0)
sorryHits=[]
for turn in range(1,12):
 state=run(hurtcode,state);state=run(advancecode,state);state=run(finishcode,state)
 sorryHits.append([turn,*[state[k] for k in ['hp','hitplot','myplot','d_con']]])
assert state['hp']==0 and state['hitplot']==11 and state['myplot']==0 and state['d_con']==1
for name in ['gml_Object_obj_sosorry_Create_0','gml_Object_obj_sosorry_Alarm_10','gml_Object_obj_sosorry_Other_12','gml_Script_SCR_GAMESTART','gml_Script_scr_attackcalc','gml_Object_obj_targetchoice_Step_0','gml_Object_obj_gladdummy_Destroy_0','gml_Object_obj_dummytrigger_Create_0','gml_Object_obj_woshbody_Step_0']:read(name)
# These numeric projections keep source event order; they are not a whole VM.
# Battle settlement sets won BEFORE adding banked rewards, while the overworld
# sets inbattle=0 BEFORE applying the regional kill difference.
battle=read('gml_Object_obj_battlecontroller_Step_0')
assert battle.index('won = 1;')<battle.index('global.xp += global.xpreward[3];')
assert battle.index('if (won == 0)')<battle.index('won = 1;')
world=read('gml_Object_obj_mainchara_Step_0')
assert world.index('global.inbattle = 0;')<world.index('global.flag[global.flag[200]] += global.kills - global.flag[201];')
prefix=battle[:battle.index('                tlvl =')]
bankcode=compile_slice(prefix+'\n'+'}\n'*(prefix.count('{')-prefix.count('}')))
regioncode=compile_slice('if (global.inbattle == 1)\n{\n'+body(world,'if (global.inbattle == 1)')+'\n}')
settlement=[]
for xp,pending,won,regional,delta in itertools.product([0,1,9],[0,7,14],range(2),[0,16],[0,1,2]):
 v=dict(xp=xp,gold=10,xpreward=[0,0,0,pending],goldreward=[0,0,0,5],monster=[0,0,0],won=won,inbattle=1,regional=regional,kills=2+delta,f201=2,f200=203,f15=1,specialbattle=0)
 for event in 'BBBOOOBB':v=run(bankcode if event=='B' else regioncode,v)
 settlement.append([[xp,pending,won,regional,delta],[v[k] for k in ['xp','gold','won','inbattle','regional']]])
assert 'global.kills' not in read('gml_Object_obj_dummymonster_Destroy_0')
assert 'global.kills' not in read('gml_Object_obj_doodlebug_Destroy_0')
assert 'killed = 1' not in read('gml_Object_obj_napstablook_Step_0')
assert 'obj_endflowey' in body(step,'if (con == 11)')
for name in ['gml_Object_obj_artclass_sign_Create_0','gml_Object_obj_artclass_sign_Alarm_0','gml_Object_obj_sosorry_Destroy_0','gml_Object_obj_sosorry_Step_0','gml_Object_obj_encounterer_jerry_Create_0','gml_Object_obj_encounterer_jerry_Step_0','gml_Object_obj_encounterer_glyde_Create_0','gml_Object_obj_maddummy_Create_0','gml_Object_obj_maddummy_Other_13','gml_Object_obj_maddummy_Alarm_3','gml_Object_obj_napstablook_Destroy_0','gml_Object_obj_bara01_Step_0','gml_Object_obj_bara02_Step_0','gml_Object_obj_spiderb_Step_0','gml_Object_obj_spiderb_Alarm_6','gml_Object_obj_doorA_Alarm_2','gml_Object_obj_doorB_Alarm_2','gml_Script_scr_runaway','gml_Script_scr_load']:read(name)
# Standard win return dispatch cannot discard unbanked EXP: it requires won1,
# which the original settlement prefix sets while banking rewards synchronously.
exitSource=read('gml_Object_obj_battlecontroller_Other_10')
exitSource=exitSource.replace('instance_exists(OBJ_WRITER)','writer_exists').replace('OBJ_WRITER.halt','halt')
exitcode=compile_slice(exitSource);standardReturns=[]
for won,writer,halt in itertools.product(range(2),repeat=3):
 v=run(exitcode,dict(won=won,writer_exists=writer,halt=halt,room_return=0))
 standardReturns.append([won,writer,halt,v['room_return']])
# Syntactic counter-write inventory (all original resources), NOT a proof that
# every actor's death or nonstandard script return is reachable or reward-safe.
killSites=[]
for sourcePath in sorted(a.source.glob('*.gml')):
 text=sourcePath.read_text()
 if re.search(r'global\.kills\s*(?:\+=|-=|=(?!=)|\+\+)',text):
  read(sourcePath.stem);killSites.append(sourcePath.stem)
for name in ['gml_Object_obj_mettatonb_quiz_Step_0','gml_Object_obj_mettatonb_second_Step_0','gml_Object_obj_mettatonb_third_Step_0','gml_Object_obj_battlebomb_Step_0','gml_Object_obj_heart_Step_0','gml_Object_obj_woshbody_Step_0']:read(name)
# Resolve actors through actual encounter cases, never guessed monster IDs.
zeroExpActors=[]
for match in re.finditer(r'case (\d+):([\s\S]*?)(?=\n    case |\n})',groups):
 section=match[2]
 actor=re.search(r'instance_create\([^;]*\b(obj_mettatonb_(?:quiz|second|third)|obj_battlebomb)\)',section)
 if not actor:continue
 enemy=int(re.search(r'global.monstertype\[0\] = (\d+)',section)[1])
 stats=body(setup,f'if (global.monstertype[myself] == {enemy})')
 values=[int(re.search(r'global.'+key+r'\[myself\] = (-?\d+)',stats)[1]) for key in ['monsterhp','monsterdef','xpreward']]
 own=[read(p.stem) for p in sorted(a.source.glob('gml_Object_'+actor[1]+'_*.gml'))]
 zeroExpActors.append([int(match[1]),enemy,*values,int(any('killed = 1;' in text for text in own)),int('scr_monsterdefeat(' in read('gml_Object_'+actor[1]+'_Destroy_0'))])
# Own-event closure is narrower than arbitrary cross-instance/global dispatch.
bombOwn=[read(p.stem) for p in sorted(a.source.glob('gml_Object_obj_battlebomb_*.gml'))]
assert all(value.strip()=='0' for text in bombOwn for value in re.findall(r'\bkilled\s*=\s*([^;]+);',text))
# Hash source evidence without exporting original dialogue, media or saves.
for name in ['gml_Object_obj_mainchara_Step_0','gml_Script_scr_monsterdefeat','gml_Script_scr_steps','gml_Object_obj_battler_Create_0','gml_Object_obj_torielboss_Alarm_10','gml_Object_obj_torielboss_Destroy_0','gml_Object_obj_papyrusboss_Alarm_10','gml_Object_obj_undyneboss_Step_0','gml_Object_obj_mettatonex_Alarm_6','gml_Object_obj_lesserdoge_Destroy_0','gml_Object_obj_lesserdoge_Other_5','gml_Object_obj_asgore_finalintro_Create_0','gml_Script_scr_namingscreen','gml_Object_obj_intromenu_Create_0','gml_Object_obj_credits_short_Create_0','gml_Object_obj_truechara_Step_0','gml_Object_obj_endmyroom_Create_0','gml_Object_obj_the_end_really_Create_0','gml_Script_scr_storagecheck','gml_Object_obj_gameshake_Create_0','gml_Object_obj_nothingness_event_Step_0']:read(name)
a.output.parent.mkdir(parents=True,exist_ok=True)
result={'schema':1,'kind':'ORIGINAL_SOURCE_CONDITIONAL_SLICE','runtime':'NOT_RUN','domain':'Neutral selector cases include counterfactual snapshots; selection is not a reachability proof','inputSha256':'b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7','sourceSha256':sources,'neutralColumns':['tDead','pDead','uDead','mDead','totalKills','friendship','murderStage','alphys','carried','saveExists','armor','healingUsed','level'],'neutral':rows,'murderFlagOrder':[k for k,_ in requirements]+[27],'murder':murderrows,'ratings':ratingrows,'letter':letterrows,'snowman':snowrows,'finale':finalrows,'trueReset':resetrows,'levels':levels,'suppression':suppression,'attackWrap':attackrows,'encounterRewards':encounterRewards,'artClubGate':artrows,'settlement':settlement,'soSorryHits':sorryHits,'standardReturns':standardReturns,'killWriteSites':killSites,'zeroExpActors':zeroExpActors}
serialized=json.dumps(result,separators=(',',':')).replace('],[[','],\n[[').replace('],[','],\n[')+'\n'
if a.verify:
 if a.output.read_text()!=serialized:raise SystemExit('FAIL original golden fixture/source hash drift')
else:a.output.write_text(serialized)
print(f'PASS original-derived fixtures: Neutral={len(rows)}, murder={len(murderrows)}, ratings={len(ratingrows)}; no dialogue text exported')
