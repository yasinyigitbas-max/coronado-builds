import json,sys,collections,csv
csv.field_size_limit(10**8)
run,act=sys.argv[1],sys.argv[2]
f0=f1=None
for r in csv.DictReader(open(run,newline='')):
    ev=r.get('events','')
    if f0 is None and 'route_start' in ev: f0=int(r['frame'])
    if 'route_done' in ev: f1=int(r['frame'])
print("route frames",f0,f1)
sp={}
for l in open(act):
    try:r=json.loads(l)
    except:continue
    if r.get('type')=='span': sp[r['id']]=r
kids=collections.defaultdict(list)
for r in sp.values(): kids[r.get('parent')].append(r)
fr=lambda r:r.get('perfprobe_frame',-1)
inr=[r for r in sp.values() if f0<=fr(r)<=(f1 or 1e9)]
tops=collections.Counter(); peaks=collections.Counter(); cnt=collections.Counter()
for r in inr:
    if r.get('parent',0)==0 or r['parent'] not in sp:
        tops[r['tag']]+=r['wall_us']; peaks[r['tag']]=max(peaks[r['tag']],r['wall_us']); cnt[r['tag']]+=1
print("top-level spans during the lap: total ms, calls, peak ms")
for k,v in tops.most_common(12): print(f"  {k:32s} {v/1000:8.1f} {cnt[k]:6d} {peaks[k]/1000:7.1f}")
ex=collections.Counter(); exn=collections.Counter(); expk=collections.Counter()
for r in inr:
    ex[r['tag']]+=r.get('exclusive_wall_us',0); exn[r['tag']]+=1; expk[r['tag']]=max(expk[r['tag']],r.get('exclusive_wall_us',0))
print("exclusive (own) time by tag during the lap: total ms, calls, peak ms")
for k,v in ex.most_common(16): print(f"  {k:32s} {v/1000:8.1f} {exn[k]:6d} {expk[k]/1000:7.1f}")
big=sorted([r for r in inr if r['tag']=='pkg.activation'],key=lambda r:-r['wall_us'])[:3]
def tree(r,d):
    for c in sorted(kids.get(r['id'],[]),key=lambda c:-c['wall_us']):
        if c['wall_us']>=1500: print("   "*d+f"{c['tag']} {c['wall_us']/1000:.1f}"); tree(c,d+1)
for a in big: print(f" worst activation {a['key']} {a['wall_us']/1000:.1f} ms frame {fr(a)}"); tree(a,1)
