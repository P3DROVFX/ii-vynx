#!/usr/bin/env python3
"""Build the six-layer Corne layout. Standard library only; never touches HID.

Matrix coordinates come from this Corne's Vial definition (8 rows x 7 columns).
QMK keycodes use the connected device's Vial protocol 6 numbering.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
TR = 1
KC = {chr(97+i): 4+i for i in range(26)}
KC.update({str((i+1) % 10): 0x1e+i for i in range(10)})
KC.update({f'F{i+1}': 0x3a+i for i in range(12)})
KC.update(dict(Esc=0x29, Tab=0x2b, Space=0x2c, Enter=0x28, Bksp=0x2a,
               Del=0x4c, Ins=0x49, Home=0x4a, End=0x4d, PgUp=0x4b, PgDn=0x4e,
               Left=0x50, Down=0x51, Up=0x52, Right=0x4f,
               Ctrl=0xe0, Shift=0xe1, Alt=0xe2, Super=0xe3, RShift=0xe5,
               Menu=0x65, Caps=0x39, VolUp=0xa9, VolDn=0xaa, Mute=0xa8,
               Play=0xae, Prev=0xac, Next=0xab, BriUp=0xbd, BriDn=0xbe,
               RGBToggle=0x7820, RGBMode=0x7821, RGBUp=0x7827,
               RGBDown=0x7828, RGBHue=0x7823))
KC.update({'-':0x2d, '=':0x2e, '[':0x2f, ']':0x30, '\\':0x31,
           ';':0x33, "'":0x1434, ',':0x36, '.':0x37, '/':0x38,
           '`':0x1435, '~':0x1635, '^':0x1623, '"':0x1634})
for symbol, key in zip('!@#$%&*()_+{}|:<>?', '123457890-=[]\\;,./'):
    KC[symbol] = 0x200 | KC[key]
for ch, key in {'á':'a','é':'e','í':'i','ó':'o','ú':'u','ç':',',
                'ã':'s','õ':'l','â':'q','ê':'f','ô':'p','à':'w','º':'m'}.items():
    KC[ch] = 0x1400 | KC[key]
KC['ª'] = 0x1600 | KC['m']
KC['°'] = 0x1600 | KC[';']
for i in range(6): KC[f'MO({i})'] = 0x5220+i
KC['TD(0)'] = 0x5700
KC['TD(1)'] = 0x5701

def code(s):
    if s in KC: return KC[s]
    # C, S, A, G stand for Ctrl, Shift, Alt, GUI/Super, respectively.
    mods, key = s.split(':')
    return sum({'C':0x100,'S':0x200,'A':0x400,'G':0x800}[x] for x in mods) | KC[key]

POS = {}
for r, names in enumerate([
    ['Tab','q','w','e','r','t'], ['LShift','a','s','d','f','g'],
    ['Ctrl','z','x','c','v','b']]):
    POS.update({name:(r,c) for c,name in enumerate(names)})
for r, names in enumerate([
    ['y','u','i','o','p','Bksp'], ['h','j','k','l',';',"'"],
    ['n','m',',','.','/','Alt']]):
    POS.update({name:(r+4,5-c) for c,name in enumerate(names)})
POS.update({'EXL↑':(0,6),'EXL↓':(1,6),'EXR↑':(4,6),'EXR↓':(5,6),
            'LE':(3,3),'LM':(3,4),'LI':(3,5),'RI':(7,5),'RM':(7,4),'RE':(7,3)})
names = ['BASE','NAV','NUM / SISTEMA','CÓDIGO','AGUDOS','TIL / CIRCUNFLEXO']
layout = [[[0]*7 for _ in range(8)] for _ in range(6)]
labels = [{} for _ in range(6)]

def setkey(layer, pos, key):
    r,c = POS[pos]; layout[layer][r][c] = code(key); labels[layer][pos] = key

base = {p:p for p in POS if p not in ['LShift','EXL↑','EXL↓','EXR↑','EXR↓','LE','LM','LI','RI','RM','RE']}
base.update({'LShift':'Shift','EXL↑':'Esc','EXL↓':'CG:Left','EXR↑':'Menu','EXR↓':'CG:Right',
             'LE':'MO(1)','LM':'Space','LI':'Super','RI':'Enter','RM':'MO(2)','RE':'RShift'})
for p,k in base.items(): setkey(0,p,k)
# Explicit base fallback prevents letters on accent layers from inheriting NAV/NUM.
for layer in range(1,6):
    for p,k in base.items(): setkey(layer,p,k)
    for p in ['LE','LM','LI','RI','RM','RE']:
        r,c=POS[p];layout[layer][r][c]=TR;labels[layer][p]='▽'

nav = {
    'q':'Home','w':'PgUp','e':'Up','r':'PgDn','t':'End',
    'a':'Del','s':'Left','d':'Down','f':'Right','g':'Super',
    'z':'Ctrl','x':'Alt','c':'Shift','v':'C:Left','b':'C:Right',
    'y':'Home','u':'PgUp','i':'Up','o':'PgDn','p':'End',
    'h':'Bksp','j':'Left','k':'Down','l':'Right',';':'Del',"'":'Ctrl',
    'n':'C:Left','m':'Ctrl',',':'Alt','.':'RShift','/':'C:Right',
    'EXL↑':'Home','EXL↓':'End','EXR↑':'PgUp','EXR↓':'PgDn',
    'LM':'Space','RI':'S:Enter','RM':'MO(3)','RE':'MO(5)'}
for p,k in nav.items():setkey(1,p,k)

for i,p in enumerate(['Tab','q','w','e','r','t','y','u','i','o','p','Bksp']):setkey(2,p,f'F{i+1}')
for i,p in enumerate(['a','s','d','f','g','h','j','k','l',';']):setkey(2,p,str((i+1)%10))
num = {'z':'Prev','x':'Play','c':'Next','v':'Mute','b':'G:F7',
       'n':'RGBToggle','m':'RGBMode',',':'RGBDown','.':'RGBUp','/':'RGBHue',
       'EXL↑':'VolUp','EXL↓':'VolDn','EXR↑':'BriUp','EXR↓':'BriDn',
       'LE':'MO(3)','LM':'MO(4)'}
for p,k in num.items():setkey(2,p,k)

# Paired delimiters under S/D/F and J/K/L; shifted digits on the top row.
symbols = {
    'q':'!','w':'@','e':'#','r':'$','t':'%',
    'a':'[','s':'{','d':'(','f':')','g':']',
    'z':'`','x':'~','c':'^','v':'\\','b':'|',
    'y':'^','u':'&','i':'*','o':'(','p':')',
    'h':'{','j':'}','k':'=','l':'+',';':'-',"'":'_',
    'n':'"','m':"'",',':'<','.':'>','/':'?',
    'EXL↑':';','EXL↓':':','EXR↑':'º','EXR↓':'ª',
    'Tab':'Tab','LShift':'Shift','Ctrl':'Ctrl','Bksp':'Bksp','Alt':'Alt',
    'LM':'Space','RI':'Enter'}
for p,k in symbols.items():setkey(3,p,k)
# On CODE thumbs do not inherit the NUM/NAV redirections.
for p,k in {'LE':'MO(1)','RM':'MO(2)','LI':'Super','RE':'RShift'}.items():setkey(3,p,k)

for p,ch in [('a','á'),('e','é'),('i','í'),('o','ó'),('u','ú'),('c','ç')]:setkey(4,p,ch)
for p,k in {'q':'à','s':'â','f':'ê','l':'ô','m':'º',';':'ª','EXR↑':'°'}.items():setkey(4,p,k)
for p,k in {'a':'TD(0)','e':'ê','o':'TD(1)','c':'ç','i':'í','u':'ú',
            'q':'à','s':'â','l':'ô','f':'ã','j':'õ','m':'º',';':'ª','EXR↑':'°',
            'd':'Shift','k':'RShift'}.items():setkey(5,p,k)
# Entry keys release using QMK's cached press action. Other thumbs stay useful.
for layer in [4,5]:
    for p,k in {'LE':'MO(1)','LM':'Space','LI':'Super','RI':'Enter','RM':'MO(2)','RE':'RShift'}.items():setkey(layer,p,k)

tap_dance = [[code('ã'),code('ã'),code('â'),code('â'),170],
             [code('õ'),code('õ'),code('ô'),code('ô'),170]] + [[0,0,0,0,200] for _ in range(30)]
combos = [[0,0,0,0,0] for _ in range(32)]
overrides = []
# NUM's four extra index keys remain a compact control area. A plain modifier
# selects another function without timing windows or sticky state. Activate only
# when the control key is pressed, and never re-register its original function.
for mods,negative,replacements in [
    (0x22,0xdd,['Prev','Next','Play','Mute']),
    (0x11,0xee,['PgUp','PgDn','CG:Left','CG:Right']),
    (0x44,0xbb,['Home','End','CSG:Left','CSG:Right']),
]:
    for trigger,replacement in zip(['VolUp','VolDn','BriUp','BriDn'],replacements):
        overrides.append([code(trigger),code(replacement),1<<2,mods,negative,mods,0x99])
overrides += [[0,0,65535,0,0,0,7] for _ in range(32-len(overrides))]
# No oneshot, Auto Shift, home-row mod-tap, layer-tap or typing-key combo.
target = {'layout':layout, 'labels':labels, 'positions':POS,'names':names,
          'tap_dance':tap_dance,'combo':combos,
          'key_override':overrides}

def build():
    (HERE/'layout.json').write_text(json.dumps(target,ensure_ascii=False,indent=2)+'\n')
    return target

if __name__ == '__main__':
    build()
    print('Generated layout.json: 6 layers, 46 physical keys, 2 accent-only tap dances')
