extends SceneTree
# Pedestrian audit: 2 sampled minutes per spot. Both systems: crowd agents (npc/crowd_layer) + traffic-sim walkers.
# Per sample: on asphalt (rendered road mask), moving; idle-on-road = still for > 3 s while on asphalt.
const SPOTS := [["orange_4th", -1286.0, 2347.0], ["hotel_del", -1730.0, 3720.0], ["amber_ave", -1640.0, 3060.0], ["residential", -2095.0, 2380.0]]
const DUR := 120.0
## on the carriageway: inside a drivable road's half width (0.3 m kerb margin)
func _on(RA: RoadsAPI, p: Vector3) -> bool:
	var r: Dictionary = RA.road_at(p.x, p.z, 25.0)
	return not r.is_empty() and float(r.dist) < float(r.get("width", 0.0)) * 0.5 - 0.3
func _initialize() -> void: _run.call_deferred()
func _secs(s: float) -> void: await create_timer(s, true, false, true).timeout
func _run() -> void:
	var MM := root.get_node_or_null("MainMenu")
	var sc: Node = load("res://test_coronado.tscn").instantiate(); root.add_child(sc)
	for i in 30: await process_frame
	if MM and MM.get(&"is_open"): MM.close()
	paused = false
	var F: Node = null; var C: Node = null
	for n in sc.find_children("*", "Node3D", true, false):
		if n is CoronadoFurniture: F = n
		if n is CoronadoCrowd: C = n
	var TR := root.get_node("Traffic")
	var pl: Node3D = sc.player
	var RA: RoadsAPI = TR.S.R
	var lp: PackedVector3Array = RA.lane_points(RA.nearest_lane(-1286.0, 2347.0))
	print("CHECK on_road(lane point)=", _on(RA, lp[lp.size() / 2]), " on_road(+40m off)=", _on(RA, lp[lp.size() / 2] + Vector3(40, 0, 40)), " mask=", F.asphalt_within(lp[lp.size() / 2].x, lp[lp.size() / 2].z, 0.0))
	for spot in SPOTS:
		pl.global_position = Vector3(spot[1], CoronadoTerrain.height_at(spot[1], spot[2]) + 0.5, spot[2])
		await _secs(20.0)
		var st := {"crowd": {"n": 0, "road": 0, "road_pave": 0, "idle_road": 0, "idle_long": 0, "wait_road": 0}, "sim": {"n": 0, "road": 0, "road_walk": 0, "road_wait": 0, "road_cross": 0, "road_turn": 0, "idle_road": 0, "idle_long": 0, "cross_stall": 0}}
		var still := {}   # id -> [pos, seconds]
		var t := 0.0; var worst := 0.0; var worst_at := ""
		while t < DUR:
			await _secs(0.5); t += 0.5
			if C:
				for a in C.agents:
					var p: Vector3 = a.pos; var k := "c%d" % a.get_instance_id()
					var on: bool = _on(RA, p)
					var e: Array = still.get(k, [p, 0.0])
					e[1] = (float(e[1]) + 0.5) if p.distance_to(e[0]) < 0.15 else 0.0; e[0] = p; still[k] = e
					st.crowd.n += 1
					if on:
						st.crowd.road += 1
						if a.cur_seg >= 0 and C.seg_kind[a.cur_seg] == 0: st.crowd.road_pave += 1
						if int(a.state) == 2 or a.state == C.W_WAIT: st.crowd.wait_road += 1
						if float(e[1]) > 3.0: st.crowd.idle_road += 1
						if float(e[1]) > worst: worst = e[1]; worst_at = "crowd state=%d seg_kind=%d at %s" % [a.state, C.seg_kind[a.cur_seg] if a.cur_seg >= 0 else -1, p]
					if float(e[1]) > 30.0 and a.state != C.W_STAY: st.crowd.idle_long += 1
			if TR.S:
				for pd: Dictionary in TR.S.peds:
					var p: Vector3 = pd.pos; var k := "s%d" % int(pd.id)
					var on: bool = _on(RA, p)
					var e: Array = still.get(k, [p, 0.0])
					e[1] = (float(e[1]) + 0.5) if p.distance_to(e[0]) < 0.15 else 0.0; e[0] = p; still[k] = e
					st.sim.n += 1
					if on:
						st.sim.road += 1
						var sk := "road_" + str(pd.state).replace("wait_cross", "wait")
						if st.sim.has(sk): st.sim[sk] += 1
						if float(e[1]) > 3.0: st.sim.idle_road += 1
						if str(pd.state) == "cross" and float(e[1]) > 3.0: st.sim.cross_stall += 1
						if float(e[1]) > worst: worst = e[1]; worst_at = "sim state=%s at %s" % [pd.state, p]
					if float(e[1]) > 30.0: st.sim.idle_long += 1
		print("PEDS %s crowd=%s sim=%s worst_idle_on_road=%.1fs (%s)" % [spot[0], st.crowd, st.sim, worst, worst_at])
	quit(0)
