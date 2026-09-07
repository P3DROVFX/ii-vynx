#!/usr/bin/env python3
"""Exclude only this Corne from keyd; run with administrator authentication."""
import datetime
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

path = Path('/etc/keyd/default.conf')
original = path.read_bytes()
expected = '05911f5b4ae18103a7bb4ce2b5f0520a3133bbbd3cab2f8c6aa99c4924eec31b'
if hashlib.sha256(original).hexdigest() != expected:
    raise SystemExit('keyd config changed: review it before applying this correction.')
updated = original.replace(b'[ids]\n*\n',
    b'[ids]\n*\n# Corne Vial uses its own firmware and per-device XKB map.\n-4653:0004\n', 1)
assert updated != original
if os.geteuid() != 0:
    raise SystemExit('Administrator authentication is required to edit /etc/keyd/default.conf.')
fd, temporary = tempfile.mkstemp(prefix='.corne-', dir=path.parent)
try:
    with os.fdopen(fd, 'wb') as output:
        output.write(updated)
        output.flush()
        os.fsync(output.fileno())
    subprocess.run(['/usr/local/bin/keyd', 'check', temporary], check=True)
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup = path.with_name(f'default.conf.before-corne-{stamp}.bak')
    shutil.copy2(path, backup)
    stat = path.stat()
    os.chown(temporary, stat.st_uid, stat.st_gid)
    os.chmod(temporary, stat.st_mode & 0o7777)
    os.replace(temporary, path)
    subprocess.run(['/usr/local/bin/keyd', 'reload'], check=True)
    print(f'Corne excluded from keyd. Backup: {backup}')
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
