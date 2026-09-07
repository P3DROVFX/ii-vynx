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
    if 0x5220<=v<0x5226:active.add(v-0x5220)
    return v

try:
    count=0
    for symbol in 'abcdefghijklmnopqrstuvwxyz0123456789!@#$%&*()_+{}|:<>?^~`\'"-=[]{}/\\;,.áéíóúçãõâêôàºª°':
        assert text_for(b.code(symbol))==symbol,(symbol,text_for(b.code(symbol)))
        count+=1
    for symbol in 'áéíóúçãõâêôà':
        assert text_for(b.code(symbol),True)==symbol.upper(),symbol
        count+=1
    for pos,ch in [('LM','Space'),('LI','Super'),('RE','RShift'),('RI','Enter'),('RM','MO(2)'),('Ctrl','Ctrl'),('LShift','Shift')]:
        assert at(0,pos)==b.code(ch)
    for pos in 'abcdefghijklmnopqrstuvwxyz':assert at(0,pos)==b.code(pos)
    assert at(1,'RI')==0x0228, 'NAV+Enter must send Shift+Enter directly'
    assert at(1,'g')==b.code('Super'), 'Keep the NAV Super duplicate on G'
    assert at(1,'h')==b.code('Bksp'), 'Keep nearby Backspace on NAV+H'
    assert at(1,'LM')==b.code('Space'), 'NAV+Space must produce a normal space'
    assert at(1,'RE')==b.code('MO(5)'), 'NAV+right thumb Shift must open TIL'
    assert at(5,'d')==b.code('Shift') and at(5,'k')==b.code('RShift')
    assert [at(2,p) for p in ['Tab','q','w','e','r','t','y','u','i','o','p','Bksp']]==[b.code(f'F{i}') for i in range(1,13)]
    assert [at(2,p) for p in ['a','s','d','f','g','h','j','k','l',';']]==[b.code(str(i%10)) for i in range(1,11)]
    for pos,key in [('s','Left'),('d','Down'),('f','Right'),('e','Up'),('j','Left'),('k','Down'),('l','Right'),('i','Up')]:
        assert at(1,pos)==b.code(key)
    for sequence,layer,pos,want in [
        (['LE'],1,'j','Left'),(['RM'],2,'a','1'),
        (['LE','RM'],3,'d','('),(['RM','LE'],3,'d','('),
        (['RM','LM'],4,'a','á'),(['LE','RE'],5,'e','ê')]:
        active=set();actions=[press(active,p) for p in sequence]
        assert max(active)==layer and resolve(active,pos)==b.code(want)
        # Both release orders end at BASE using QMK's cached press actions.
        for release in [actions,actions[::-1]]:
            state=active.copy()
            for action in release:state.discard(action-0x5220)
            assert not state
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
        assert layers==4 and options==0x99 and suppressed==mods
        assert mods&negative==0 and mods|negative==255
        assert trigger==b.code(['VolUp','VolDn','BriUp','BriDn'][i%4])
        wanted=[['Prev','Next','Play','Mute'],['PgUp','PgDn','CG:Left','CG:Right'],
                ['Home','End','CSG:Left','CSG:Right']][i//4][i%4]
        assert replacement==b.code(wanted)
    print(f'PASS: {count} character/uppercase cases; 6 layer entry sequences and release orders;')
    print('plain typing/thumb keys, preserved F/numbers, mirrored arrows, 12 NUM overrides,')
    print('no hold-tap/oneshot/combos/macros assigned.')
finally:
    x.xkb_keymap_unref(keymap);x.xkb_context_unref(context)
