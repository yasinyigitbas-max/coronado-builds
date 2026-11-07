extends SceneTree
# Offline: which trees stand on a walking line (crowd walk graph, not crossings), on a park path (terrain class 15),
# or inside a building (a LOD0 roof triangle directly above the trunk). Writes TREE_SCAN_OUT (json) with the drops.
const WALK_R := 1.0     # trunk centre closer than this to a walk line = in the walking space (sidewalk ~1.5 m wide)
const ROOF_MIN := 2.2   # a roof at least this far above the trunk base
var segs := {}          # Vector2i(10 m) -> [[a, b]]
var roofs := {}         # Vector2i(5 m) -> [[p0, p1, p2, ymin]]
func _initialize() -> void: _run.call_deferred()
func _cell(p: Vector2, s: float) -> Vector2i: return Vector2i(floori(p.x / s), floori(p.y / s))
func _add_seg(a: Vector2, b: Vector2) -> void:
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * WALK_R; var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * WALK_R
	for cx in range(floori(lo.x / 10.0), floori(hi.x / 10.0) + 1):
		for cz in range(floori(lo.y / 10.0), floori(hi.y / 10.0) + 1):
			var k := Vector2i(cx, cz)
			if not segs.has(k): segs[k] = []
			segs[k].append([a, b])
func _walk_d(p: Vector2) -> float: return p.distance_to(_walk_q(p))
func _walk_q(p: Vector2) -> Vector2:
	var best := INF; var bq := Vector2.INF
	for s: Array in segs.get(_cell(p, 10.0), []):
		var q := Geometry2D.get_closest_point_to_segment(p, s[0], s[1])
		if p.distance_to(q) < best: best = p.distance_to(q); bq = q
	return bq
func _in_bld(p: Vector2, gy: float) -> bool:
	for tr: Array in roofs.get(_cell(p, 5.0), []):
		if float(tr[3]) > gy + ROOF_MIN and Geometry2D.point_is_inside_triangle(p, tr[0], tr[1], tr[2]): return true
	return false
func _on_road(rd: RoadsAPI, p: Vector2) -> bool:   # trunk (0.35 m) + furniture CLEAR (1.0 m) from the carriageway edge
	var r := rd.road_at(p.x, p.y, 25.0)
	return not r.is_empty() and float(r.dist) < float(r.width) * 0.5 + 1.35
func _run() -> void:
	var t := JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/furniture/data/trees.json")) as Dictionary
	var rows: Array = t.trees
	# walk graph (crowd_layer WKG1 layout)
	var b := FileAccess.get_file_as_bytes("res://map_dc/coronado/npc/data/walk_graph.bin")
	var nn := b.decode_u32(4); var ns := b.decode_u32(8); var np := b.decode_u32(12)
	var o := 16 + nn * 8
	var p0s := []; var nps := []; var kinds := []
	for i in ns:
		kinds.append(b[o + 8]); p0s.append(b.decode_u32(o + 20)); nps.append(b.decode_u32(o + 24)); o += 32
	var pts := b.slice(o, o + np * 12).to_float32_array()
	var nseg := 0
	for i in ns:
		if int(kinds[i]) == 1: continue   # crossings: trees never stand there anyway; skip
		var p0: int = p0s[i]; var n: int = nps[i]
		for j in n - 1:
			var a := Vector2(pts[(p0 + j) * 3], pts[(p0 + j) * 3 + 2]); var c := Vector2(pts[(p0 + j + 1) * 3], pts[(p0 + j + 1) * 3 + 2])
			_add_seg(a, c); nseg += 1
	print("SCAN walk pieces %d (kinds %s)" % [nseg, str(kinds.reduce(func(acc, k): acc[k] = acc.get(k, 0) + 1; return acc, {}))])
	# building roofs from the LOD0 chunk meshes
	var idx := JSON.parse_string(FileAccess.get_file_as_string("res://map_dc/coronado/buildings/chunks/index.json")) as Dictionary
	var nroof := 0; var nch := 0
	for f in DirAccess.get_files_at("res://map_dc/coronado/buildings/chunks"):
		if not f.ends_with(".scn"): continue
		var ps := load("res://map_dc/coronado/buildings/chunks/" + f) as PackedScene
		if ps == null: continue
		var root := ps.instantiate() as Node3D; nch += 1
		for mi in root.find_children("*LOD0*", "MeshInstance3D", true, false):
			var m: Mesh = (mi as MeshInstance3D).mesh
			if m == null: continue
			var xf: Transform3D = root.transform * (mi as MeshInstance3D).transform
			for s in m.get_surface_count():
				var a := m.surface_get_arrays(s); var V: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
				var I: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(V.size()))
				for ti in range(0, I.size(), 3):
					var v0 := xf * V[I[ti]]; var v1 := xf * V[I[ti + 1]]; var v2 := xf * V[I[ti + 2]]
					var nrm := (v1 - v0).cross(v2 - v0)
					if nrm.length() < 1e-4 or absf(nrm.normalized().y) < 0.35: continue   # walls
					var q0 := Vector2(v0.x, v0.z); var q1 := Vector2(v1.x, v1.z); var q2 := Vector2(v2.x, v2.z)
					var lo := q0.min(q1).min(q2); var hi := q0.max(q1).max(q2)
					var ym := minf(v0.y, minf(v1.y, v2.y))
					for cx in range(floori(lo.x / 5.0), floori(hi.x / 5.0) + 1):
						for cz in range(floori(lo.y / 5.0), floori(hi.y / 5.0) + 1):
							var k := Vector2i(cx, cz)
							if not roofs.has(k): roofs[k] = []
							roofs[k].append([q0, q1, q2, ym])
					nroof += 1
		root.free()
	print("SCAN building chunks %d, roof triangles %d" % [nch, nroof])
	CoronadoTerrain.ensure_loaded()
	var drops := []; var moves := []; var n_walk := 0; var n_path := 0; var n_bld := 0; var n_move := 0
	var rd := CoronadoSurface.roads()
	for i in rows.size():
		var r: Array = rows[i]
		var p := Vector2(float(r[0]), float(r[1]))
		var gy: float = CoronadoTerrain.height_at(p.x, p.y)
		var why := ""
		if _in_bld(p, gy): why = "inside a building (roof above the trunk)"; n_bld += 1
		if why == "" and CoronadoTerrain.class_at(p.x, p.y) == 15: why = "on a park / footway path"; n_path += 1
		if why == "":
			var q := _walk_q(p)
			var d := p.distance_to(q)
			if d < WALK_R:
				# move it just out of the walking space, on the side it already stands (else the other side); drop if neither is free
				var dir := (p - q).normalized() if d > 0.05 else Vector2.RIGHT.rotated(float(i))
				var moved := false
				for sg in [1.0, -1.0]:
					var npos: Vector2 = q + dir * float(sg) * (WALK_R + 0.1)
					var gy2: float = CoronadoTerrain.height_at(npos.x, npos.y)
					if _walk_d(npos) >= WALK_R and not _in_bld(npos, gy2) and not _on_road(rd, npos) and CoronadoTerrain.class_at(npos.x, npos.y) != 15:
						moves.append({"i": i, "row": r, "to": [snappedf(npos.x, 0.05), snappedf(npos.y, 0.05)], "why": "moved %.2f m off the sidewalk walking line" % p.distance_to(npos)})
						moved = true; n_move += 1; break
				if not moved: why = "on the sidewalk walking line (%.2f m), no free spot beside it" % d; n_walk += 1
		if why != "": drops.append({"i": i, "row": r, "why": why})
	print("SCAN trees %d: inside buildings %d, on paths %d, sidewalk: moved %d, dropped %d (no free spot) -> drop total %d" % [rows.size(), n_bld, n_path, n_move, n_walk, drops.size()])
	var f := FileAccess.open(OS.get_environment("TREE_SCAN_OUT"), FileAccess.WRITE); f.store_string(JSON.stringify({"drops": drops, "moves": moves})); f.close()
	quit(0)
