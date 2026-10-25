#!/usr/bin/env python3
"""Offline UI geometry/font renderer. This does not execute the GameMaker VM."""
from pathlib import Path
import argparse,json,sys,hashlib,struct
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from generate_font import chunk,stored_deflate
from PIL import Image,ImageDraw,__version__ as pillow_version
from generate import CAT,ROOT
L=CAT['layout'];WHITE=(255,255,255,255);BLACK=(0,0,0,255);YELLOW=(255,255,0,255);RED=(255,0,0,255)
class Renderer:
    def __init__(self,language,native=None):
        self.lang=language; self.line_height=18 if language else 16; self.image=Image.new('RGBA',(320,240),BLACK);self.draw=ImageDraw.Draw(self.image);self.runs=[]
        self.glyphs={}
        atlas=Image.open(ROOT/'assets/ui-font.png').convert('RGBA')
        for line in (ROOT/'assets/ui-font.tsv').read_text().splitlines():
            code,x,y,advance,offset=map(int,line.split())
            self.glyphs[code]=(advance,atlas.crop((x,y,x+24,y+18)),offset)
        self.metrics=json.loads((ROOT/'ui/english-metrics.json').read_text())['metrics']
        if language==0 and native:
            metadata=json.loads((native/'glyphs.json').read_text())
            expected=json.loads((ROOT/'ui/english-metrics.json').read_text())['sourceHash']
            if metadata.get('SourceHash')!=expected:raise ValueError('Unverified native preview font source')
            page=Image.open(native/'page.png').convert('RGBA')
            for g in metadata['Glyphs']:
                self.glyphs[g['Code']]=(g['Advance'],page.crop((g['X'],g['Y'],g['X']+g['Width'],g['Y']+g['Height'])),g['Offset'])
        self.native=bool(native)
    def width(self,text):
        if self.lang==0:return sum(self.metrics.get(str(ord(c)),{'advance':self.glyphs[ord(c)][0]})['advance'] for c in text)
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
        for i,line in enumerate(self.wrap(text,width,lines)):self.line(x,y+i*18,line,width)
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
    def menu(self,selection=0,options=None):
        self.box(L['menu_left'],L['menu_top'],L['menu_right'],L['menu_bottom']);self.line(28,24,'ROUTEKEEPER',264)
        labels=['goal','variant','guidance','spoilers','language','journal','back']
        values=[self.text('pacifist'),self.text('either'),self.text('active'),self.text('minimal'),'한국어' if self.lang else 'English','','']
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
    def hud(self,objective,progress='7/17'):
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
    for lang in range(2):
        for kind in ['menu','warning','protected','hud','targets']:
            r=Renderer(lang,args.native_font)
            if kind=='menu':r.menu(2)
            elif kind in ['warning','protected']:r.warning(11,kind=='protected')
            elif kind=='targets':r.menu(3,[r.text(k) for k in ['pacifist','soulless_pacifist','genocide','neutral','soulless_genocide']])
            else:r.hud('Explore the next area.' if not lang else '다음 지역을 탐험하세요.')
            r.save(args.output/f'{kind}-{lang}.png')
    manifest={'pillowVersion':pillow_version,'kind':'OFFLINE_PREVIEW','gameplay':'NOT_RUN','nativeEnglishOutlines':bool(args.native_font),'layoutSha256':hashlib.sha256((ROOT/'ui/catalog.json').read_bytes()).hexdigest(),'fontAtlasSha256':hashlib.sha256((ROOT/'assets/ui-font.png').read_bytes()).hexdigest()}
    (args.output/'evidence.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('PASS offline previews generated; native English outlines='+str(bool(args.native_font))+'; gameplay NOT_RUN')
if __name__=='__main__':main()
