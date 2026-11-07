#!/usr/bin/env python3
"""bugcheck1 0030: side-yard (+ shared rear) fences between neighbouring houses.
Inputs (all in the project): npc/data/homes.json (door, street normal n, optional footprint rect),
furniture/data/fence_bldg_mask.json (OSM building / garage footprints), furniture/data/fences_alleys.json (alleys).
Output: fences_alleys.json gets "side": [{"kind", "pts"}] (the runtime cuts them into 3 m pieces and drops pieces on
asphalt / driveways / inside buildings, like every other fence).
Rule (Coronado lots: open front yards, fenced side and back yards):
- neighbours = homes on the same street side (normals within ~30 deg, front lines within 10 m), next along the street
- the side fence runs down the middle of the gap between the two footprints (gap 1.2 .. 20 m), from 2 m behind the more
  recessed front facade to REAR m behind the deeper house (capped at MAX_DEPTH from the front), stopping 1.5 m short of
  an alley (the alley already has its own back fences)
- the two rear corners of each side fence are joined across the back of the lot when no alley runs within 8 m of it
Kind: Spanish / stucco styles -> stucco wall, others picket (wood)."""
import json, math, sys, os
P = sys.argv[1] if len(sys.argv) > 1 else "."
REAR, MAX_DEPTH, GAP_MIN, GAP_MAX = 7.0, 38.0, 1.2, 20.0
homes = json.load(open(os.path.join(P, "map_dc/coronado/npc/data/homes.json")))["homes"]
mask = json.load(open(os.path.join(P, "map_dc/coronado/furniture/data/fence_bldg_mask.json")))["polys"]
FA = os.path.join(P, "map_dc/coronado/furniture/data/fences_alleys.json")
fa = json.load(open(FA))
def sub(a, b): return (a[0] - b[0], a[1] - b[1])
def dot(a, b): return a[0] * b[0] + a[1] * b[1]
def seg_d(p, a, b):
    ab = sub(b, a); L = dot(ab, ab)
    t = 0.0 if L < 1e-9 else max(0.0, min(1.0, dot(sub(p, a), ab) / L))
    q = (a[0] + ab[0] * t, a[1] + ab[1] * t); return math.dist(p, q)
# polygon grid
G = 20.0; grid = {}
for i, pl in enumerate(mask):
    xs = [q[0] for q in pl]; zs = [q[1] for q in pl]
    for gx in range(int(math.floor(min(xs) / G)), int(math.floor(max(xs) / G)) + 1):
        for gz in range(int(math.floor(min(zs) / G)), int(math.floor(max(zs) / G)) + 1):
            grid.setdefault((gx, gz), []).append(i)
def poly_d(p, pl): return min(seg_d(p, pl[k], pl[(k + 1) % len(pl)]) for k in range(len(pl)))
def footprint(h):
    if h.get("rect"): return h["rect"]
    d = h["door"]; best = None; bd = 3.0
    for i in grid.get((int(math.floor(d[0] / G)), int(math.floor(d[1] / G))), []):
        dd = poly_d(d, mask[i])
        if dd < bd: bd = dd; best = mask[i]
    return best
H = []
for h in homes:
    if h["zone"] != "residential": continue
    fp = footprint(h)
    if fp is None: continue
    n = h["n"]; L = math.hypot(*n); n = (n[0] / L, n[1] / L); t = (-n[1], n[0])
    D = h["door"]
    ts = [dot(sub(q, D), t) for q in fp]; ns = [dot(sub(q, D), n) for q in fp]
    H.append(dict(h=h, D=D, n=n, t=t, fp=fp, spanish=("spanish" in h["basis"] or "stucco" in h["basis"])))
# alleys (2D polylines, half width)
alleys = [([(p[0], p[2]) for p in a["pts"]], float(a["w"]) * 0.5) for a in fa["alleys"]]
AG = 50.0; agrid = {}
for ai, (pts, hw) in enumerate(alleys):
    for p in pts: agrid.setdefault((int(math.floor(p[0] / AG)), int(math.floor(p[1] / AG))), set()).add(ai)
def alley_d(p):
    best = 1e9
    gx, gz = int(math.floor(p[0] / AG)), int(math.floor(p[1] / AG))
    for dx in (-1, 0, 1):
        for dz in (-1, 0, 1):
            for ai in agrid.get((gx + dx, gz + dz), ()):
                pts, hw = alleys[ai]
                for k in range(len(pts) - 1): best = min(best, seg_d(p, pts[k], pts[k + 1]) - hw)
    return best
HG = 60.0; hgrid = {}
for i, a in enumerate(H): hgrid.setdefault((int(math.floor(a["D"][0] / HG)), int(math.floor(a["D"][1] / HG))), []).append(i)
side = []; stats = dict(pairs=0, side_m=0.0, rear_m=0.0, skipped_gap=0, cut_alley=0)
for i, a in enumerate(H):
    # right-hand neighbour along the street (smallest positive t offset)
    best = None; bt = 1e9
    gx, gz = int(math.floor(a["D"][0] / HG)), int(math.floor(a["D"][1] / HG))
    for dx in (-1, 0, 1):
        for dz in (-1, 0, 1):
            for j in hgrid.get((gx + dx, gz + dz), ()):
                if j == i: continue
                b = H[j]
                if dot(a["n"], b["n"]) < 0.85: continue
                rel = sub(b["D"], a["D"])
                if abs(dot(rel, a["n"])) > 10.0: continue
                tt = dot(rel, a["t"])
                if 0.5 < tt < 45.0 and tt < bt: bt = tt; best = b
    if best is None: continue
    b = best
    D = a["D"]; n = a["n"]; t = a["t"]
    ta = [dot(sub(q, D), t) for q in a["fp"]]; na = [dot(sub(q, D), n) for q in a["fp"]]
    tb = [dot(sub(q, D), t) for q in b["fp"]]; nb = [dot(sub(q, D), n) for q in b["fp"]]
    gap = min(tb) - max(ta)
    if gap < GAP_MIN or gap > GAP_MAX: stats["skipped_gap"] += 1; continue
    tm = (max(ta) + min(tb)) * 0.5
    front = min(max(na), max(nb)) - 2.0
    rear = max(min(na), min(nb), max(na) - MAX_DEPTH) - REAR
    rear = max(rear, front - MAX_DEPTH)
    if front - rear < 4.0: continue
    def at(nn): return (D[0] + t[0] * tm + n[0] * nn, D[1] + t[1] * tm + n[1] * nn)
    # stop 1.5 m short of an alley behind
    nn = front; end = rear
    while nn > rear:
        if alley_d(at(nn)) < 1.5: end = nn + 0.5; stats["cut_alley"] += 1; break
        nn -= 1.0
    if front - end < 4.0: continue
    kind = "wall" if (a["spanish"] and b["spanish"]) else "picket"
    A0 = at(front); A1 = at(end)
    side.append({"kind": kind, "pts": [[round(A0[0], 2), round(A0[1], 2)], [round(A1[0], 2), round(A1[1], 2)]], "rear": [round(A1[0], 2), round(A1[1], 2)], "home": a["h"]["b"]})
    stats["pairs"] += 1; stats["side_m"] += front - end
    a.setdefault("rear_pts", []).append((tm, end)); b.setdefault("rear_pts_l", []).append(A1)
# rear fences: each home whose lot has a side fence on both sides and no alley behind -> join the two rear corners
for a in H:
    rp = a.get("rear_pts"); lp = a.get("rear_pts_l")
    if not rp or not lp: continue
    R = (a["D"][0] + a["t"][0] * rp[0][0] + a["n"][0] * rp[0][1], a["D"][1] + a["t"][1] * rp[0][0] + a["n"][1] * rp[0][1])
    Lp = lp[0]
    mid = ((R[0] + Lp[0]) * 0.5, (R[1] + Lp[1]) * 0.5)
    if math.dist(R, Lp) > 30.0 or alley_d(mid) < 8.0: continue
    side.append({"kind": "wall" if a["spanish"] else "picket", "pts": [[round(Lp[0], 2), round(Lp[1], 2)], [round(R[0], 2), round(R[1], 2)]], "home": a["h"]["b"]})
    stats["rear_m"] += math.dist(R, Lp)
for s in side: s.pop("rear", None)
fa["side"] = side
fa.setdefault("notes", [])
fa["notes"] = [x for x in fa["notes"] if "0030" not in x] + ["bugcheck1 0030: 'side' = side-yard / shared rear fences between neighbouring homes (bugcheck1/tools/side_fences.py)"]
json.dump(fa, open(FA, "w"), separators=(",", ":"))
stats["side_m"] = round(stats["side_m"]); stats["rear_m"] = round(stats["rear_m"])
print("SIDEFENCES homes used %d, fences %d" % (len(H), len(side)), stats)
