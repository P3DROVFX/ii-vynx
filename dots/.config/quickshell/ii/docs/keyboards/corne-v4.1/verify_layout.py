#!/usr/bin/env python3
"""Offline checks with libxkbcommon; does not generate keyboard events."""
import ctypes
import json
from pathlib import Path
import build_layout as b

P=ctypes.c_void_p
x=ctypes.CDLL('libxkbcommon.so.0')
for name,args,result in [
    ('xkb_context_new',[ctypes.c_int],P),
    ('xkb_keymap_new_from_string',[P,ctypes.c_char_p,ctypes.c_int,ctypes.c_int],P),
    ('xkb_state_new',[P],P),('xkb_state_unref',[P],None),
    ('xkb_keymap_unref',[P],None),('xkb_context_unref',[P],None),
    ('xkb_keymap_key_by_name',[P,ctypes.c_char_p],ctypes.c_uint),
    ('xkb_state_update_key',[P,ctypes.c_uint,ctypes.c_int],ctypes.c_int),
    ('xkb_state_key_get_utf8',[P,ctypes.c_uint,ctypes.c_char_p,ctypes.c_size_t],ctypes.c_int),
]:
    f=getattr(x,name);f.argtypes=args;f.restype=result
context=x.xkb_context_new(0)
keymap=x.xkb_keymap_new_from_string(context,(b.HERE/'corne-v4.1.xkb').read_bytes(),1,0)
assert keymap,'XKB did not compile'

hid={}
for keys,names in [('qwertyuiop',[f'AD{i:02}' for i in range(1,11)]),
                   ('asdfghjkl',[f'AC{i:02}' for i in range(1,10)]),
                   ('zxcvbnm',[f'AB{i:02}' for i in range(1,8)]),
                   ('1234567890',[f'AE{i:02}' for i in range(1,11)])]:
    hid.update({b.code(k):n for k,n in zip(keys,names)})
hid.update({0x2d:'AE11',0x2e:'AE12',0x2f:'AD11',0x30:'AD12',0x31:'BKSL',
            0x33:'AC10',0x34:'AC11',0x35:'TLDE',0x36:'AB08',0x37:'AB09',0x38:'AB10'})

def text_for(code,shift=False):
    s=x.xkb_state_new(keymap)
    try:
        mods=(code>>8)&31
        side=['RCTL','RTSH','RALT','RWIN'] if mods&16 else ['LCTL','LFSH','LALT','LWIN']
        for i,name in enumerate(side):
            if mods&(1<<i):x.xkb_state_update_key(s,x.xkb_keymap_key_by_name(keymap,name.encode()),1)
        if shift:x.xkb_state_update_key(s,x.xkb_keymap_key_by_name(keymap,b'LFSH'),1)
        buf=ctypes.create_string_buffer(32)
        x.xkb_state_key_get_utf8(s,x.xkb_keymap_key_by_name(keymap,hid[code&255].encode()),buf,32)
        return buf.value.decode()
    finally:x.xkb_state_unref(s)

def at(layer,pos):
    r,c=b.POS[pos];return b.layout[layer][r][c]

def resolve(active,pos):
    for layer in sorted(active|{0},reverse=True):
        v=at(layer,pos)
        if v!=1:return v
    return 0

def press(active,pos):
    v=resolve(active,pos)
    # Model an ordinary hold of the user's layer thumb; timing/double-tap
    # recognition is outside this offline layer-transition check.
    if v==b.code('TD(4)'):v=b.tap_dance[4][1]
    if 0x5220<=v<0x5226:active.add(v-0x5220)
    elif 0x5200<=v<0x5206:
        active.clear()
        if v!=0x5200:active.add(v-0x5200)
    return v

def release(active,action):
    # QMK releases the action captured on keydown, even after a TO layer switch.
    if 0x5220<=action<0x5226:active.discard(action-0x5220)

try:
    count=0
    for symbol in 'abcdefghijklmnopqrstuvwxyz0123456789!@#$%&*()_+{}|:<>?^~`\'"-=[]{}/\\;,.áéíóúçãõâêôàºª°':
        assert text_for(b.code(symbol))==symbol,(symbol,text_for(b.code(symbol)))
        count+=1
    for symbol in 'áéíóúçãõâêôà':
        assert text_for(b.code(symbol),True)==symbol.upper(),symbol
        count+=1
    for pos,ch in [('LE','TD(4)'),('LM','Space'),('LI','Super'),('RE','MO(2)'),('RI','Enter'),('RM','TD(2)'),('Ctrl','Ctrl'),('LShift','Shift')]:
        assert at(0,pos)==b.code(ch)
    for pos in 'abcdefghijklmnopqrstuvwxyz':assert at(0,pos)==b.code(pos)
    assert at(1,'RI')==0x0228, 'Layer 1+Enter must send Shift+Enter directly'
    assert at(1,'LM')==at(1,'LI')==0, 'Preserve manually disabled layer-1 thumbs'
    assert at(1,'Tab')==b.code('Shift'), 'Preserve manual Shift on the Tab position'
    assert at(1,'RM')==b.code('Super'), 'Layer 1 Super must be on the central right thumb'
    assert at(0,'EXR↑')==b.code('Menu')
    for layer,mapping in [(1,{'EXL↑':'WheelUp','EXL↓':'WheelDown','EXR↑':'Paste','EXR↓':'Copy'}),
                          (2,{'EXL↑':'Prev','EXL↓':'Stop','EXR↑':'Next','EXR↓':'Play'})]:
        for pos,key in mapping.items():assert at(layer,pos)==b.code(key), 'Preserve manual extra-key edits'
    assert at(2,'LM')==b.code('MO(4)'), 'Layer 2 then Space keeps the symbol-layer gesture'
    # The user moved this existing TD with Shift; preserve its entire definition.
    assert b.tap_dance[2]==[0xe5,0xe5,0x5284,0,220]
    assert b.tap_dance[4]==[0,0x5221,0x52aa,0,180]
    for pos,want in [('a','á'),('e','é'),('o','ó'),('s','ã'),('d','ê'),('p','õ'),
                     ('c','ç'),('i','í'),('u','ú'),('q','â'),('z','à'),('l','ô')]:
        assert at(2,pos)==b.code(want), 'Accents must use direct keys, without Tap Dance'
        assert text_for(at(2,pos))==want
        assert text_for(at(2,pos),True)==want.upper()
    assert [(layer,pos) for layer in range(6) for pos in b.POS if 0x5700<=at(layer,pos)<0x5800]==[(0,'LE'),(0,'RM')]
    for symbol in '!@#$%&*()_+{}|:<>?^~`\'"-=[]{}/\\;ºª°':
        assert b.code(symbol) in [at(layer,p) for layer in (0,4) for p in b.POS], f'Symbol unavailable: {symbol}'
    # No hidden modifier positions or replacement Backspaces among layer-1 letters.
    for pos in 'abcdefghijklmnopqrstuvwxyz':
        if pos=='g':
            assert at(1,pos)==b.code('TO(5)')
            continue
        if pos in ('q','e'):
            assert at(1,pos)=={'q':0x68,'e':0x69}[pos], 'Split ratio uses dedicated F13/F14 without modifiers or dead keys'
            continue
        if pos in ('r','z','n','m'):
            assert at(1,pos)==b.code({'r':'RightSuperQuote','z':'Undo','n':'RGBToggle','m':'RGBModeReverse'}[pos])
            continue
        assert at(1,pos) in [0]+[b.code(k) for k in ['Left','Down','Up','Right','Home','End','PgUp','PgDn']]
    for layer in range(1,5):
        for pos,key in [('Ctrl','Ctrl'),('LShift','Shift'),('Alt','Alt')]:
            assert at(layer,pos)==b.code(key),(layer,pos)
        assert at(layer,'LI')==b.code('NO' if layer==1 else 'Super'),(layer,'LI')
        assert at(layer,'RM')==b.code('Super' if layer==1 else 'RShift'),(layer,'RM')
    assert at(1,'Bksp')==b.code('Bksp') and at(2,'RI')==b.code('S:Enter')
    assert [at(3,p) for p in ['Tab','q','w','e','r','t','y','u','i','o','p','Bksp']]==[b.code(f'F{i}') for i in range(1,13)]
    assert [at(3,p) for p in ['a','s','d','f','g','h','j','k','l',';']]==[b.code(str(i%10)) for i in range(1,11)]
    assert at(3,'b')==b.code('G:F7'), 'Backlight must be reachable without a third thumb key'
    for pos,key in [('s','Left'),('d','Down'),('f','Right'),('w','Up'),('j','Left'),('k','Down'),('l','Right'),('i','Up')]:
        assert at(1,pos)==b.code(key)
    for sequence,layer,pos,want in [
        (['LE'],1,'j','Left'),(['RE'],2,'c','ç'),
        (['LE','RE'],3,'a','1'),(['RE','LE'],3,'a','1'),
        (['RE','LM'],4,'d','('),(['LE'],1,'RI','S:Enter')]:
        active=set();actions=[press(active,p) for p in sequence]
        assert max(active)==layer and resolve(active,pos)==b.code(want)
        # Both release orders end at BASE using QMK's cached press actions.
        for release_order in [actions,actions[::-1]]:
            state=active.copy()
            for action in release_order:release(state,action)
            assert not state
    # Game entry stays latched after releasing either entry key first. The former
    # MO(1) key is now Space, and releasing it must never exit the game layer.
    for reverse in (False,True):
        active=set();actions=[press(active,p) for p in ['LE','g']]
        assert active=={5}
        for action in actions[::-1] if reverse else actions:release(active,action)
        assert active=={5}, 'Game mode must stay active after releasing its entry keys'
        held=[press(active,p) for p in ['w','LE','LM','LI']]
        assert held==[b.code(k) for k in ['w','Space','Ctrl','Shift']]
        for action in held:release(active,action)
        assert active=={5}, 'Gameplay keys must not change layers'
        assert press(active,'RE')==b.code('TO(0)') and not active
        assert resolve(active,'LE')==b.code('TD(4)') and resolve(active,'RM')==b.code('TD(2)')
    for pos in 'qwertasdfgzxcvb':assert at(5,pos)==b.code(pos)
    for pos in b.POS:
        value=at(5,pos)
        assert value!=1, 'Game mode must not inherit typing-layer actions'
        assert value<256 or (pos=='RE' and value==b.code('TO(0)')), (pos,hex(value))
        assert value not in (b.code('Super'),0xe7), 'No Super key in game mode'
    for pos,key in [('i','Up'),('j','Left'),('k','Down'),('l','Right'),('RM','RShift')]:
        assert at(5,pos)==b.code(key)
    assert [at(5,p) for p in ['n','m',',','.','/']]==[b.code(str(i)) for i in range(1,6)]
    for layer in b.layout:
        for row in layer:
            for value in row:
                assert not 0x2000<=value<0x5000,'Unexpected mod-tap/layer-tap'
                assert not 0x5280<=value<0x52c0,'Unexpected oneshot'
                assert not 0x7700<=value<0x7780,'Unexpected macro dependency'
    assert not any(any(c) for c in b.combos)
    # Overrides must be confined to NUM, enabled, and exclude unrelated mods.
    assert len([o for o in b.overrides if o[-1]&128])==12
    for i,o in enumerate(b.overrides[:12]):
        trigger,replacement,layers,mods,negative,suppressed,options=o
        assert layers==8 and options==0x99 and suppressed==mods
        assert mods&negative==0 and mods|negative==255
        assert trigger==b.code(['VolUp','VolDn','BriUp','BriDn'][i%4])
        wanted=[['Prev','Next','Play','Mute'],['PgUp','PgDn','CG:Left','CG:Right'],
                ['Home','End','CSG:Left','CSG:Right']][i//4][i%4]
        assert replacement==b.code(wanted)
    print(f'PASS: {count} character/uppercase cases; 6 layer entry sequences and release orders;')
    print('layer 1 arrows, 12 direct layer-2 accents / 24 lowercase-uppercase cases; stable modifiers;')
    print('preserved Shift TD(2), F/numbers, both arrow clusters, Q/E split ratio, 12 layer-3 overrides;')
    print('latched FPS entry/exit, immediate gameplay keys, preserved manual TD(2)/TD(4);')
    print('no mod-tap/layer-tap/combos/macros; no Tap Dance or Super in game mode.')
finally:
    x.xkb_keymap_unref(keymap);x.xkb_context_unref(context)
