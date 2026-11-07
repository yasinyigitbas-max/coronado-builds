#!/usr/bin/env python3
"""bugcheck1 baked delta (patches 0008-0034 bakes, made in the cloud session 7 Nov 2026).
Usage (from anywhere):  python3 apply_delta.py /path/to/project
Copies files/<path> over project/<path> and deletes the paths listed in GONE.txt.
Only files that differ from the coronado-data packs of actprobe1-src6 are included."""
import os, shutil, sys
here = os.path.dirname(os.path.abspath(__file__)); proj = sys.argv[1]
assert os.path.isfile(os.path.join(proj, 'project.godot')), 'not a Godot project folder: ' + proj
n = 0
for dp, dn, fns in os.walk(os.path.join(here, 'files')):
    for fn in fns:
        src = os.path.join(dp, fn); rel = os.path.relpath(src, os.path.join(here, 'files'))
        dst = os.path.join(proj, rel); os.makedirs(os.path.dirname(dst), exist_ok=True); shutil.copy2(src, dst); n += 1
g = 0
for rel in open(os.path.join(here, 'GONE.txt')).read().split():
    p = os.path.join(proj, rel)
    if os.path.exists(p): os.remove(p); g += 1
print('copied %d files, removed %d stale files' % (n, g))
