#!/usr/bin/env python3
"""Offline UI geometry/font renderer. This does not execute the GameMaker VM."""
from pathlib import Path
import argparse,json,sys,hashlib,struct,re
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from generate_font import chunk,stored_deflate
from PIL import Image,ImageDraw,__version__ as pillow_version
from generate import CAT,ROOT,localization
L=CAT['layout'];WHITE=(255,255,255,255);BLACK=(0,0,0,255);YELLOW=(255,255,0,255);RED=(255,0,0,255)
class Renderer:
    def __init__(self,language,native=None):
        self.lang=language; self.locale=localization.enabled()[language]; self.font=localization.font_sources()[self.locale["font"]]; self.line_height=self.font["lineHeight"]; self.image=Image.new('RGBA',(320,240),BLACK);self.draw=ImageDraw.Draw(self.image);self.runs=[]
        self.glyphs={}
        folder=ROOT/'assets/fonts'/self.locale['font'] if self.font['kind']!='native' else ROOT/'assets'
        atlas=Image.open(folder/'ui-font.png').convert('RGBA')
        for line in (folder/'ui-font.tsv').read_text(encoding='utf-8').splitlines():
            code,x,y,advance,offset=map(int,line.split())
            self.glyphs[code]=(advance,atlas.crop((x,y,x+24,y+18)),offset)
        self.metrics=json.loads((ROOT/'ui/english-metrics.json').read_text(encoding='utf-8'))['metrics']
        if self.font['kind']=='native' and native:
            metadata=json.loads((native/'glyphs.json').read_text(encoding='utf-8'))
            expected=json.loads((ROOT/'ui/english-metrics.json').read_text(encoding='utf-8'))['sourceHash']
            if metadata.get('SourceHash')!=expected:raise ValueError('Unverified native preview font source')
            page=Image.open(native/'page.png').convert('RGBA')
            for g in metadata['Glyphs']:
                self.glyphs[g['Code']]=(g['Advance'],page.crop((g['X'],g['Y'],g['X']+g['Width'],g['Y']+g['Height'])),g['Offset'])
        self.native=bool(native);self.native_path=native
    def width(self,text):
        if self.font['kind']=='native':return sum(self.metrics[str(ord(c))]['advance'] for c in text)
        return sum(self.glyphs[ord(c)][0] for c in text)
    def text(self,key):return CAT['text'][key][self.lang]
    def fit(self,text,width):
        if self.width(text)<=width:return text
        while text and self.width(text+'...')>width:text=text[:-1]
        return text+'...'
    def line(self,x,y,text,width,color=WHITE):
        text=self.fit(text,width);assert self.width(text)<=width
        self.runs.append((x,y,self.width(text),self.line_height,text))
        for char in text:
            advance,im,offset=self.glyphs[ord(char)];im=im.copy()
            if color!=WHITE:
                alpha=im.getchannel('A');im=Image.new('RGBA',im.size,color);im.putalpha(alpha)
            self.image.alpha_composite(im,(x+offset,y))
            x+=self.width(char)
        return text
    def wrap(self,text,width,lines):
        result=[]
        while text and len(result)<lines:
            take=0;space=0
            for n in range(1,len(text)+1):
                if self.width(text[:n])>width:break
                take=n
                if text[n-1]==' ':space=n
            take=max(1,take)
            if take<len(text) and space>0:take=space
            line=text[:take];text=text[take:].lstrip(' ')
            if len(result)==lines-1 and text:line+='...'
            result.append(self.fit(line,width))
        return result
    def paragraph(self,x,y,text,width,lines):
        for i,line in enumerate(self.wrap(text,width,lines)):self.line(x,y+i*self.line_height,line,width)
    def box(self,left,top,right,bottom):
        self.draw.rectangle((left,top,right-1,bottom-1),fill=WHITE)
        self.draw.rectangle((left+3,top+3,right-4,bottom-4),fill=BLACK)
    def heart(self,x,y):
        for j,row in enumerate(['01100110','11111111','11111111','01111110','00111100','00011000']):
            for i,p in enumerate(row):
                if p=='1':self.draw.point((x+i,y+j),fill=RED)
    def warning(self,code,enforced=False):
        self.box(L['warning_left'],L['warning_top'],L['warning_right'],L['warning_bottom'])
        self.paragraph(L['warning_x'],L['warning_y'],'* '+self.text('warn_'+str(code)),L['warning_width'],L['warning_lines'])
        self.line(L['warning_x'],L['warning_footer'],self.text('close_warning' if enforced else 'retry_warning'),264)
    def source_labels(self,name):
        source=(ROOT/'gml'/name).read_text(encoding='utf-8')
        keys=re.findall(r'scr_routekeeper_text\("([^"\n]+)"',source)
        return [localization.text(key,self.lang) for key in keys]
    def call_goals(self):return self.source_labels('greeting_label.gml')
    def menu(self,selection=0,options=None,neutral=False,neutral_settings=False,goal=0):
        self.box(L['menu_left'],L['menu_top'],L['menu_right'],L['menu_bottom']);self.line(28,24,self.text('title'),264)
        labels=['goal','ending_type' if neutral else 'epilogue','guidance','spoilers','language','journal','back']
        values=[self.text('pacifist'),self.text('either'),self.text('active'),self.text('minimal'),self.locale['name'],'','']
        if neutral:
            values[0]=self.text('neutral');values[1]=self.source_labels('neutral_label.gml')[0]
        if neutral_settings:
            labels=['ending_type','call_goal','back'];values=[values[1],self.call_goals()[goal],'']
        if options is not None:
            first=selection//7*7;rows=options[first:first+7]
        else:first=0;rows=[self.text(k) for k in labels]
        for row,label in enumerate(rows):
            y=L['row_y']+row*L['row_height'];chosen=(first+row==selection)
            if chosen:self.heart(27,y+4)
            color=YELLOW if chosen else WHITE
            self.line(L['row_x'],y,label,252 if options is not None else 94,color)
            if options is None:self.line(L['value_x'],y,values[row],152,color)
        self.line(28,L['footer_y'],self.text('navigation'),264)
    def languages(self,selection=0):
        self.box(L['menu_left'],L['menu_top'],L['menu_right'],L['menu_bottom'])
        self.line(28,24,self.text('language'),264)
        first=selection//L['visible_rows']*L['visible_rows']
        for index in range(first,min(first+L['visible_rows'],len(localization.enabled()))):
            row=Renderer(index,self.native_path);row.image=self.image;row.draw=self.draw
            y=L['row_y']+(index-first)*L['row_height']
            if index==selection:self.heart(27,y+4)
            row.line(L['row_x'],y,row.locale['name'],252,YELLOW if index==selection else WHITE)
            self.runs.extend(row.runs)
        self.line(28,L['footer_y'],self.text('navigation'),264)
    def hud(self,objective,progress=None):
        if progress is None:progress=self.text('progress_compact').replace('{met}','7').replace('{total}','17')
        self.box(16,L['hud_top'],304,L['hud_bottom']);self.line(L['hud_x'],L['hud_y'],'* '+objective,L['hud_width']);self.line(L['hud_progress_x'],L['hud_y'],progress,L['hud_progress_width'])
    def save(self,path):
        im=self.image.resize((640,480),Image.Resampling.NEAREST)
        pixels=list(im.getdata());palette=sorted(set(pixels));width,height=im.size
        if len(palette)>256:raise ValueError('Preview exceeds deterministic pixel palette')
        bits=next(b for b in [1,2,4,8] if len(palette)<=2**b);lookup={p:i for i,p in enumerate(palette)}
        scan=bytearray();per_byte=8//bits
        for row in range(height):
            scan.append(0)
            for x in range(0,width,per_byte):
                scan.append(sum(lookup[pixels[row*width+x+j]] << (8-bits*(j+1)) for j in range(per_byte) if x+j<width))
        png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',width,height,bits,3,0,0,0))
        png+=chunk(b'PLTE',bytes(c for p in palette for c in p[:3]))+chunk(b'tRNS',bytes(p[3] for p in palette))
        png+=chunk(b'IDAT',stored_deflate(scan))+chunk(b'IEND',b'')
        path.write_bytes(png)

def main():
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--native-font',type=Path);args=p.parse_args();args.output.mkdir(parents=True,exist_ok=True)
    for lang,_ in enumerate(localization.enabled()):
        for kind in ['menu','warning','protected','hud','targets','neutral','call-settings','call-goals','save-warning','languages']:
            r=Renderer(lang,args.native_font)
            if kind=='languages':r.languages(lang)
            elif kind=='menu':r.menu(2)
            elif kind in ['warning','protected']:r.warning(11,kind=='protected')
            elif kind=='neutral':r.menu(1,neutral=True)
            elif kind=='call-settings':r.menu(1,neutral=True,neutral_settings=True,goal=5)
            elif kind=='call-goals':r.menu(8,r.call_goals())
            elif kind=='save-warning':r.warning(13,True)
            elif kind=='targets':r.menu(3,[r.text(k) for k in ['pacifist','soulless_pacifist','genocide','neutral','soulless_genocide']])
            else:r.hud(r.text('no_objective'))
            r.save(args.output/f'{kind}-{lang}.png')
    manifest={'pillowVersion':pillow_version,'kind':'OFFLINE_PREVIEW','gameplay':'NOT_RUN','nativeEnglishOutlines':bool(args.native_font),'layoutSha256':hashlib.sha256((ROOT/'ui/catalog.json').read_bytes()).hexdigest(),'fontAtlasSha256':hashlib.sha256((ROOT/'assets/ui-font.png').read_bytes()).hexdigest()}
    (args.output/'evidence.json').write_text(json.dumps(manifest,indent=2)+'\n', encoding='utf-8', newline='\n')
    print('PASS offline previews generated; native English outlines='+str(bool(args.native_font))+'; gameplay NOT_RUN')
if __name__=='__main__':main()
