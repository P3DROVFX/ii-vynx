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
               NO=0, WheelUp=0xd9, WheelDown=0xda, RightSuperQuote=0x1834,
               F13=0x68, F14=0x69, Undo=0x7a, Copy=0x7c, Paste=0x7d,
               Del=0x4c, Ins=0x49, Home=0x4a, End=0x4d, PgUp=0x4b, PgDn=0x4e,
               Left=0x50, Down=0x51, Up=0x52, Right=0x4f,
               Ctrl=0xe0, Shift=0xe1, Alt=0xe2, Super=0xe3, RShift=0xe5,
               Menu=0x65, Caps=0x39, VolUp=0xa9, VolDn=0xaa, Mute=0xa8,
               Play=0xae, Prev=0xac, Next=0xab, Stop=0xad, BriUp=0xbd, BriDn=0xbe,
               RGBToggle=0x7820, RGBMode=0x7821, RGBUp=0x7827,
               RGBDown=0x7828, RGBHue=0x7823, RGBHueDown=0x7824,
               RGBModeReverse=0x7822))
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
for i in range(6): KC[f'TO({i})'] = 0x5200+i
KC['OSL(4)'] = 0x5284
KC['OSM(SG)'] = 0x52aa
for i in range(5): KC[f'TD({i})'] = 0x5700+i

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
names = ['BASE','NAVEGAÇÃO','ACENTOS','NÚMEROS / SISTEMA','SÍMBOLOS','JOGOS FPS']
layout = [[[0]*7 for _ in range(8)] for _ in range(6)]
labels = [{} for _ in range(6)]

def setkey(layer, pos, key):
    r,c = POS[pos]; layout[layer][r][c] = code(key); labels[layer][pos] = key

base = {p:p for p in POS if p not in ['LShift','EXL↑','EXL↓','EXR↑','EXR↓','LE','LM','LI','RI','RM','RE']}
base.update({'LShift':'Shift','EXL↑':'Esc','EXL↓':'CG:Left','EXR↑':'Menu','EXR↓':'CG:Right',
             'LE':'TD(4)','LM':'Space','LI':'Super','RI':'Enter','RM':'TD(2)','RE':'MO(2)'})
for p,k in base.items(): setkey(0,p,k)
# ACENTOS falls through to BASE. The other functional layers
# leave unused letter positions disabled so they cannot inherit unrelated actions.
for layer in range(1,6):
    for p in POS:
        r,c=POS[p]
        layout[layer][r][c]=TR if layer==2 else 0
        labels[layer][p]='▽' if layer==2 else '—'

fixed = {p:base[p] for p in ['Tab','LShift','Ctrl','Alt','Bksp','EXL↑','EXL↓','EXR↑','EXR↓','LE','LM','LI','RI','RE']}
fixed['RM']='RShift'
fixed['LE']='MO(1)'
for layer in range(1,5):
    for p,k in fixed.items():setkey(layer,p,k)

# Every accent is a direct key. Preserve the user's Q/Z swap: â above A, à below.
for p,k in {'a':'á','e':'é','o':'ó','s':'ã','d':'ê','p':'õ','i':'í','u':'ú','c':'ç','q':'â','z':'à','l':'ô',
            'LE':'MO(3)','LM':'MO(4)','RI':'S:Enter',
            'EXL↑':'Prev','EXL↓':'Stop','EXR↑':'Next','EXR↓':'Play'}.items():setkey(2,p,k)

# F13/F14 reach Hyprland through keycodes 191/192, independent of XKB symbols.
# Left Up moves from E to W so Q/E can adjust the split ratio.
nav={'q':'F13','e':'F14','w':'Up','s':'Left','d':'Down','f':'Right',
     'i':'Up','j':'Left','k':'Down','l':'Right',
     'y':'PgUp','h':'PgDn','u':'Home','o':'End',
     'RI':'S:Enter','RM':'Super','RE':'MO(3)',
     # Preserve the live Vial edits captured in backup-20260907-145406.
     'r':'RightSuperQuote','z':'Undo','EXL↑':'WheelUp','EXL↓':'WheelDown',
     'EXR↑':'Paste','EXR↓':'Copy','n':'RGBToggle','m':'RGBModeReverse',
     ',':'RGBMode','.':'RGBHueDown','/':'RGBHue',
     # Preserve the user's manual Shift/disabled-thumb edits.
     'Tab':'Shift','LM':'NO','LI':'NO','g':'TO(5)'}
for p,k in nav.items():setkey(1,p,k)

for i,p in enumerate(['Tab','q','w','e','r','t','y','u','i','o','p','Bksp']):setkey(3,p,f'F{i+1}')
for i,p in enumerate(['a','s','d','f','g','h','j','k','l',';']):setkey(3,p,str((i+1)%10))
num={'EXL↑':'VolUp','EXL↓':'VolDn','EXR↑':'BriUp','EXR↓':'BriDn',
     'b':'G:F7',
     'n':'RGBToggle','m':'RGBMode',',':'RGBDown','.':'RGBUp','/':'RGBHue'}
for p,k in num.items():setkey(3,p,k)

# Keep the previous symbol positions and remove redundant punctuation copies.
symbols={'q':'!','w':'@','e':'#','r':'$','t':'%',
         'y':'^','u':'&','i':'*',
         'a':'[','s':'{','d':'(','f':')','g':']',
         'j':'}','k':'=','l':'+',';':'-',"'":'_',
         'z':'`','x':'~','c':'°','v':'\\','b':'|',
         'n':'"','m':"'",',':'<','.':'>','/':'?',
         'EXL↑':';','EXL↓':':','EXR↑':'º','EXR↓':'ª',
         'Bksp':'Del'}
for p,k in symbols.items():setkey(4,p,k)

# A complete, latched game layer: no fallthrough into typing-layer gestures.
# The requested Space position replaces the former exit position, so the right
# layer thumb exits instead. Both shifts and all gameplay keys are plain keys.
game=base.copy()
game.update({'LE':'Space','LM':'Ctrl','LI':'Shift',
             'RI':'Enter','RM':'RShift','RE':'TO(0)',
             'EXL↓':'NO','EXR↑':'Esc','EXR↓':'NO',
             'y':'Tab','u':'q','i':'Up','o':'e','p':'r',
             'h':'f','j':'Left','k':'Down','l':'Right',';':'g',"'":'v',
             'n':'1','m':'2',',':'3','.':'4','/':'5'})
for p,k in game.items():setkey(5,p,k)

# TD(2) is the user's existing right Shift dance, moved with its physical key.
# Entries 0/1/3 retain the user's settings as unassigned configurations. All
# layer-2 accents are direct. TD(4) preserves the user's latest layer-1 thumb
# dance, including its Shift+Super one-shot double tap.
tap_dance = [[code('á'),code('á'),code('ã'),code('ã'),200],
             [code('ó'),code('ó'),code('õ'),code('õ'),220],
             [code('RShift'),code('RShift'),code('OSL(4)'),0,220],
             [code('é'),code('é'),code('ê'),code('ê'),220],
             [0,code('MO(1)'),code('OSM(SG)'),0,180]] + [[0,0,0,0,200] for _ in range(27)]
combos = [[0,0,0,0,0] for _ in range(32)]
overrides = []
# Layer 3's four extra index keys remain a compact control area. A plain modifier
# selects another function without timing windows or sticky state. Activate only
# when the control key is pressed, and never re-register its original function.
for mods,negative,replacements in [
    (0x22,0xdd,['Prev','Next','Play','Mute']),
    (0x11,0xee,['PgUp','PgDn','CG:Left','CG:Right']),
    (0x44,0xbb,['Home','End','CSG:Left','CSG:Right']),
]:
    for trigger,replacement in zip(['VolUp','VolDn','BriUp','BriDn'],replacements):
        overrides.append([code(trigger),code(replacement),1<<3,mods,negative,mods,0x99])
overrides += [[0,0,65535,0,0,0,7] for _ in range(32-len(overrides))]
# The user's one-shots are confined to TD(2)/TD(4); no Auto Shift, home-row mod-tap,
# layer-tap or typing-key combo. The game layer never uses Tap Dance.
target = {'layout':layout, 'labels':labels, 'positions':POS,'names':names,
          'tap_dance':tap_dance,'combo':combos,
          'key_override':overrides}

def build():
    (HERE/'layout.json').write_text(json.dumps(target,ensure_ascii=False,indent=2)+'\n')
    return target

if __name__ == '__main__':
    build()
    print('Generated layout.json: arrows, direct accents, preserved Shift TD(2), latched FPS layer 5')
