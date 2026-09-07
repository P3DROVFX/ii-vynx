#!/usr/bin/env python3
"""Read, back up, export and apply the Corne layout via official Vial raw HID.

No QMK firmware flashing, macro writes, unlocks, simulated typing or shell IPC.
Run `python3 device_layout.py snapshot|apply|verify` from any directory.
Apply only accepts the device identity captured by this task's backup.
"""
import datetime
import importlib.util
import json
import struct
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
READER = HERE.parents[2] / 'scripts/typing/vial_keyboard.py'
spec = importlib.util.spec_from_file_location('vial_reader', READER)
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
EXPECTED_UID = 0x4589d8fac72a3689
# Field widths from Vial's qmk_settings.json (IDs exposed by this firmware).
SETTINGS_WIDTH = {1:1,2:2,3:1,4:2,5:1,6:2,7:2,8:1,9:2,10:2,11:2,
                  12:2,13:2,14:2,15:2,16:2,17:2,18:2,19:2,20:1,21:4}

def dynamic(k, op):
    entries=[]
    for i in range(32):
        result=k.send([0xfe,13,op,i])
        if result[0] != 0: raise RuntimeError(f'Dynamic read failed: {op}/{i}')
        entries.append(list(struct.unpack('<3H4B' if op==5 else '<5H',result[1:11])))
    return entries

def snapshot(k):
    ident=k.send([0xfe,0])
    protocol,uid=struct.unpack('<IQ',ident[:12])
    if (protocol,uid)!=(6,EXPECTED_UID):raise RuntimeError('Unexpected keyboard identity')
    definition=k.definition()
    if definition['matrix'] != {'rows':8,'cols':7} or k.layer_count()!=6:
        raise RuntimeError('Unexpected matrix/layer count')
    flat=k.keymap(8,7,6)
    size=struct.unpack('>H',k.send([0x0d])[1:3])[0]
    raw=b''
    for off in range(0,size,28):
        n=min(28,size-off)
        raw+=k.send([0x0e,off>>8,off&255,n])[4:4+n]
    ids=[];cur=0
    while True:
        vals=struct.unpack('<16H',k.send([0xfe,9,cur&255,cur>>8]))
        ids += [x for x in vals if x!=65535]
        if 65535 in vals:break
        cur=max(vals)
    return {'uid':uid,'vial_protocol':protocol,'via_protocol':struct.unpack('>H',k.send([1])[1:3])[0],
            'layout':[[flat[(l*8+r)*7:(l*8+r+1)*7] for r in range(8)] for l in range(6)],
            'definition':definition,'layout_options':k.layout_options(),
            'macro_hex':raw.hex(),'macro_count':k.send([0x0c])[1],
            'tap_dance':dynamic(k,1),'combo':dynamic(k,3),'key_override':dynamic(k,5),
            'settings_raw':{str(i):k.send([0xfe,10,i&255,i>>8]).hex() for i in ids}}

def macro_export(raw, count):
    # Preserve the existing ASCII and simple key-action macros in a .vil export.
    result=[]
    for macro in raw.split(b'\0')[:count]:
        actions=[];i=0
        while i<len(macro):
            if macro[i]==1:
                op=macro[i+1]
                if op not in (1,2,3):raise ValueError('Unsupported macro escape; raw backup is intact')
                actions.append([{1:'down',2:'up',3:'tap'}[op],hex(macro[i+2])])
                i+=3
            else:
                end=macro.find(b'\1',i)
                if end<0:end=len(macro)
                actions.append(['text',macro[i:end].decode('ascii')]);i=end
        result.append(actions)
    return result

def export_vil(s, path):
    fields=('uid','vial_protocol','via_protocol','layout','layout_options','tap_dance','combo')
    v={name:s[name] for name in fields}
    v.update(version=1,encoder_layout=[[] for _ in range(6)],
             macro=macro_export(bytes.fromhex(s['macro_hex']),s['macro_count']),
             settings={i:int.from_bytes(bytes.fromhex(raw)[1:1+SETTINGS_WIDTH[int(i)]],'little')
                       for i,raw in s['settings_raw'].items()})
    keys=['trigger','replacement','layers','trigger_mods','negative_mod_mask','suppressed_mods','options']
    v['key_override']=[dict(zip(keys,entry)) for entry in s['key_override']]
    path.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n')

def check(actual, desired):
    for name in ('layout','tap_dance','combo','key_override'):
        if actual[name] != desired[name]:raise RuntimeError(f'Readback mismatch: {name}')

def main():
    action=sys.argv[1] if len(sys.argv)>1 else 'snapshot'
    if action not in ('snapshot','apply','verify'):raise SystemExit('Use snapshot, apply or verify')
    node,_=reader.find_device()
    if node is None:raise SystemExit('Corne unavailable')
    k=reader.Keyboard(node)
    try:
        before=snapshot(k)
        if action in ('snapshot','apply'):
            backup=HERE/('backup-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
            backup.with_suffix('.json').write_text(json.dumps(before,ensure_ascii=False,indent=2)+'\n')
            export_vil(before,backup.with_suffix('.vil'))
            print('Backup:',backup.with_suffix('.vil'))
        if action=='snapshot':return
        desired=json.loads((HERE/'layout.json').read_text())
        if action=='apply':
            # Configure unused features first, then layers, with BASE last.
            for name,getop,setop in [('tap_dance',1,2),('combo',3,4),('key_override',5,6)]:
                for i,(old,new) in enumerate(zip(before[name],desired[name])):
                    if old==new:continue
                    data=struct.pack('<3H4B' if name=='key_override' else '<5H',*new)
                    k.send(bytes([0xfe,13,setop,i])+data)
                if dynamic(k,getop)!=desired[name]:raise RuntimeError(f'{name} write rejected')
            changed=0
            for l in [5,4,3,2,1,0]:
                for r in range(8):
                    for c in range(7):
                        value=desired['layout'][l][r][c]
                        if value==before['layout'][l][r][c]:continue
                        k.send([5,l,r,c,value>>8,value&255]);changed+=1
            print('Changed key assignments:',changed)
        actual=snapshot(k)
        check(actual,desired)
        if actual['macro_hex']!=before['macro_hex'] or actual['settings_raw']!=before['settings_raw']:
            raise RuntimeError('Unexpected macro/settings change')
        (HERE/'verified-device.json').write_text(json.dumps(actual,ensure_ascii=False,indent=2)+'\n')
        export_vil(actual,HERE/'corne-ii-p3drovfx.vil')
        print('Verified: 336 matrix entries, 32 tap dances, 32 combos, 32 overrides; macros/settings preserved')
    finally:k.close()

if __name__=='__main__':main()
