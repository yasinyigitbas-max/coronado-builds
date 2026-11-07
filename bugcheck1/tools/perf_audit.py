#!/usr/bin/env python3
"""PerfProbe run_*.csv audit: script time per frame, per-tag cost, hitch ranking (route phase only)."""
import csv, sys, collections, statistics as st
csv.field_size_limit(10**8)
path = sys.argv[1]
rows = list(csv.DictReader(open(path, newline='')))
# route phase: from the route_start / run_start mark on
start = next((i for i, r in enumerate(rows) if 'route_start' in r.get('events', '') or 'run_start' in r.get('events', '')), 0)
end = next((i for i, r in enumerate(rows) if 'route_done' in r.get('events', '')), len(rows))
load = rows[:start]; route = rows[start:end]
def f(r, k):
    try: return float(r.get(k) or 0)
    except ValueError: return 0.0
def pct(v, p):
    v = sorted(v); return v[min(len(v) - 1, int(len(v) * p))] if v else 0
def tags(r):
    out = {}
    for kv in (r.get('tags_ms') or '').split(';'):
        if '=' in kv:
            k, v = kv.split('=', 1)
            try: out[k] = float(v)
            except ValueError: pass
    return out
for name, seg in (('LOADING (menu -> spawn)', load), ('ROUTE (one lap)', route)):
    if not seg: continue
    fm = [f(r, 'frame_ms') for r in seg]; pm = [f(r, 'proc_ms') for r in seg]; ph = [f(r, 'phys_ms') for r in seg]
    print(f"== {name}: {len(seg)} frames, {f(seg[-1],'t_s')-f(seg[0],'t_s'):.0f} s")
    print(f"   frame_ms mean {st.mean(fm):.2f} p50 {pct(fm,.5):.2f} p99 {pct(fm,.99):.2f} max {max(fm):.0f} | >33 ms: {sum(x>33 for x in fm)}  >100 ms: {sum(x>100 for x in fm)}")
    print(f"   proc_ms (script) mean {st.mean(pm):.2f} p99 {pct(pm,.99):.2f} max {max(pm):.0f} | phys_ms mean {st.mean(ph):.2f} p99 {pct(ph,.99):.2f}")
# per-tag cost over the route
tot = collections.Counter(); mx = {}; big = collections.Counter(); per = collections.defaultdict(list)
for r in route:
    for k, v in tags(r).items():
        tot[k] += v; per[k].append(v); mx[k] = max(mx.get(k, 0), v)
        if v > 4.0: big[k] += 1
n = max(len(route), 1)
print("\n== TOP TAGS by total time over the lap (mean ms/frame, p99 over frames where it ran, max, frames > 4 ms)")
for k, v in tot.most_common(25):
    print(f"   {k:34s} mean {v/n:6.3f}  p99 {pct(per[k],.99):7.2f}  max {mx[k]:8.1f}  >4ms {big[k]}")
# hitches: dominant tag(s) of every frame > 50 ms in the route
print("\n== HITCHES (route frames > 50 ms): dominant tag counts")
dom = collections.Counter(); worst = []
for r in route:
    fm = f(r, 'frame_ms')
    if fm <= 50: continue
    t = tags(r)
    # leaf-ish dominant: largest tag that isn't a proc_ wrapper when a non-proc tag explains > 40 % of it
    top = sorted(t.items(), key=lambda kv: -kv[1])[:4]
    d = top[0][0] if top else '?'
    dom[d] += 1
    worst.append((fm, f(r, 't_s'), top, r.get('events', '')[:60]))
for k, c in dom.most_common(15): print(f"   {k:34s} {c}")
print("\n== WORST 15 ROUTE FRAMES")
for fm, t, top, ev in sorted(worst, key=lambda x: -x[0])[:15]:
    print(f"   {fm:7.0f} ms at t={t:6.1f}s  " + ", ".join(f"{k}={v:.0f}" for k, v in top) + (f"  [{ev}]" if ev else ""))
