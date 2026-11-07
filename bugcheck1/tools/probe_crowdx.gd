extends SceneTree
# Crowd walk graph: where do signalled crossing segments (kind 1) start / end relative to the carriageway?
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var MM := root.get_node_or_null("MainMenu")
	var sc: Node = load("res://test_coronado.tscn").instantiate(); root.add_child(sc)
	for i in 600:
		await process_frame
		var C0: Node = null
		for n in sc.find_children("*", "Node3D", true, false): if n is CoronadoCrowd: C0 = n
		if C0 and C0.seg_kind.size() > 0: break
	var C: Node = null
	for n in sc.find_children("*", "Node3D", true, false): if n is CoronadoCrowd: C = n
	var RA := RoadsAPI.new(); RA.load_data()
	var n1 := 0; var sig := 0; var start_in := 0; var depth := []; var ex := []
	for s in C.seg_kind.size():
		if C.seg_kind[s] != 1: continue
		n1 += 1
		if C.seg_ctl[s] < 0: continue
		sig += 1
		for nd in [C.seg_a[s], C.seg_b[s]]:
			var p: Vector2 = C.node_xz[nd]
			var r: Dictionary = RA.road_at(p.x, p.y, 25.0)
			if r.is_empty(): continue
			var inside: float = float(r.width) * 0.5 - float(r.dist)
			if inside > 0.3:
				start_in += 1; depth.append(inside)
				if ex.size() < 5: ex.append([nd, p, r.name, snappedf(inside, 0.1)])
	depth.sort()
	print("CROWDX crossings=%d signalled=%d ends_inside_road=%d of %d (median %.1f m in, max %.1f m) ex=%s" % [n1, sig, start_in, sig * 2, depth[depth.size() / 2] if depth.size() else 0.0, depth[-1] if depth.size() else 0.0, ex])
	quit(0)
