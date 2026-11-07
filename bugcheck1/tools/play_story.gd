extends SceneTree
# Full New Game playthrough: narrator pick -> ink intro + creator -> Day 10 gate / taxi -> flat (flatmate, tour, PC,
# job search, dinner) -> bed -> Day 2 (PC invite, flatmate, directions, bus, interview) -> café -> end of the flow.
# The driver answers as a player would (typed fallback of every voice prompt, lesson / quiz taps, phone payments) and
# walks to the active quest marker when the story waits for the player. Logs every beat; reports stalls.
var t0 := 0
var last_beat_t := 0
var last_beat := ""
var beats: Array = []
var scene: Node = null
var stalls: Array = []
var moved := 0
func T() -> float: return (Time.get_ticks_msec() - t0) / 1000.0
func frames(n: int) -> void:
	for i in n: await process_frame
func _init() -> void: _run.call_deferred()
func _beat(b: String, who: String) -> void:
	beats.append([snappedf(T(), 0.1), who, b]); last_beat_t = Time.get_ticks_msec(); last_beat = who + ":" + b
	print("BEAT %7.1fs %-10s %s" % [T(), who, b])
func _watch_scene() -> void:
	var sd := root.get_node("StoryDirector")
	var sc: Variant = sd.get(&"intro_scene")
	if sc != null and is_instance_valid(sc) and sc != scene:
		scene = sc
		var who := str((sc as Node).get_script().resource_path.get_file().get_basename())
		print("SCENE %7.1fs %s" % [T(), who])
		if (sc as Node).has_signal(&"beat"): (sc as Node).connect(&"beat", func(b: String) -> void: _beat(b, who.replace("_scene", "")))
		if (sc as Node).has_signal(&"choices_shown"):
			(sc as Node).connect(&"choices_shown", func(_k: Array) -> void:
				await create_timer(0.6).timeout
				if is_instance_valid(sc): (sc as Node).call(&"pick_choice", 0))
func _st() -> String: return str(scene.get(&"state")) if scene != null and is_instance_valid(scene) else ""
func _run() -> void:
	var sg := root.get_node("SaveGame"); sg.dir = "user://play_story"; sg.autosave_enabled = false
	root.get_node("GameSettings").dir = "user://play_story_settings"
	for i in sg.get_max_slots(): sg.delete_slot(i)
	var cc := root.get_node("CharCreator"); cc.audio_enabled = false
	root.add_child(load("res://test_coronado.tscn").instantiate())
	await frames(10)
	var mm := root.get_node_or_null("MainMenu")
	if mm and mm.get(&"is_open") and mm.has_method(&"close"): mm.close()
	paused = false
	await create_timer(8.0).timeout
	t0 = Time.get_ticks_msec(); last_beat_t = t0
	var sd := root.get_node("StoryDirector")
	var flow_done := [false]
	sd.intro_flow_finished.connect(func() -> void: flow_done[0] = true; _beat("intro_flow_finished", "story"))
	Engine.time_scale = 3.0
	print("PLAY start_new")
	sd.start_new()
	var ink_seen := false
	var wrong_tried := false
	var still_since := Time.get_ticks_msec(); var last_state := ""
	var last_pos := Vector3.INF
	while not flow_done[0]:
		await process_frame
		_watch_scene()
		var st := _st()
		if st != last_state: last_state = st; still_since = Time.get_ticks_msec(); print("STATE %7.1fs %s" % [T(), st])
		if Time.get_ticks_msec() - last_beat_t > 420000:
			stalls.append([snappedf(T(), 1), last_beat, st]); print("STALL %7.1fs no beat for 420 s (last %s, state %s, prompt %s)" % [T(), last_beat, st, CoreSvc.voice_prompt_open()])
			break
		if T() > 5400.0: print("PLAY overall timeout"); break
		# narrator pick / ink comic
		for n in root.get_children():
			if n is NarratorPick and not n.has_meta(&"pp"):
				n.set_meta(&"pp", true); await create_timer(1.0).timeout
				if is_instance_valid(n): n.choose("m"); _beat("narrator_picked", "intro")
			if n.get_script() and str(n.get_script().resource_path).ends_with("ink_intro.gd") and not n.has_meta(&"pp"):
				n.set_meta(&"pp", true); ink_seen = true
				n.page_started.connect(func(i: int) -> void: _beat("ink_page_%d" % (i + 1), "ink"))
				n.finished.connect(func() -> void: _beat("ink_finished", "ink"))
		# voice prompt: the typed fallback, the expected line
		if CoreSvc.voice_prompt_open():
			var exp: PackedStringArray = root.get_node("Voice").get(&"_expected")
			var t := exp[0] if exp.size() else ""
			await create_timer(0.3).timeout
			CoreSvc.submit_typed(t); await frames(3); continue
		# the taxi's job question reuses the creator panel outside the creator (VocHint + Next -> mic, or an option grid)
		var spv = cc.get(&"_panel")
		if not bool(cc.get(&"running")) and spv and is_instance_valid(spv) and spv.visible:
			if spv.find_child("VocHint", true, false):
				await create_timer(0.4).timeout; cc._nav.emit(1); await frames(3); continue
			if spv.find_child("OptionsScroll", true, false):
				await create_timer(0.4).timeout
				var vi2: int = cc.vocation_ids().find("cashier"); cc.choose("vocation", maxi(vi2, 0)); cc._nav.emit(1); await frames(3); continue
		# character creator (interrogation office)
		if bool(cc.get(&"running")):
			if cc.get(&"_name_edit") != null and is_instance_valid(cc._name_edit) and cc._name_edit.is_visible_in_tree() and cc._name_edit.text == "":
				await create_timer(0.5).timeout; cc.type_name("ada"); await create_timer(0.3).timeout; cc.type_done(); continue
			var sp = cc.get(&"_panel")
			if sp and is_instance_valid(sp) and sp.visible:
				var stp: int = int(cc.get(&"step"))
				await create_timer(0.4).timeout
				if stp >= 0 and stp < cc.STEPS.size() and str(cc.STEPS[stp]) == "vocation" and sp.find_child("OptionsScroll", true, false):
					var vi: int = cc.vocation_ids().find("cashier"); cc.choose("vocation", maxi(vi, 0))
				cc._nav.emit(1); await frames(3); continue
		# phone: payments, grammar lessons, quizzes
		var ph: Node = root.get_node("Phone")
		if int(ph.get(&"pay_id")) != 0:
			await create_timer(0.4).timeout
			if int(ph.get(&"pay_id")) != 0: ph.call(&"confirm_payment"); _beat("qr_paid", "phone")
			continue
		var ag: Node = ph.get(&"apps")
		if ag and ag.has_method(&"current_step") and bool(ph.get(&"is_open")) and ph.get(&"current") == &"grammar" and not (ag.get(&"g_seq") as Dictionary).is_empty():
			await create_timer(0.3).timeout
			var gst: Dictionary = ag.current_step()
			if str(gst.get("type", "")) == "quiz": ag._answer(int(gst.answer))
			ag.grammar_next(); await frames(2); continue
		var ls := root.get_node("Lessons"); var p = ls.panel
		if p and is_instance_valid(p) and p.get(&"step_index") >= 0:
			var lst: Dictionary = p.current()
			await create_timer(0.3).timeout
			if is_instance_valid(p) and p.current() == lst:
				if String(lst.get("type", "")) == "quiz":
					if not p.quiz_answered: p.answer(int(lst.answer))
				else: p.next()
			continue
		if scene == null or not is_instance_valid(scene): continue
		# scene-specific player actions (what the player does with the controls)
		if st == "apply_wait":
			await create_timer(0.8).timeout
			var rows: Array = (load("res://ui/phone/jobs_app.gd") as GDScript).call(&"relevant_jobs")
			var r: Dictionary = rows[0] if rows.size() else {"job": "cashier", "site": ""}
			var J := root.get_node("Jobs")
			if J.has_method(&"open_cv_app") and not J.open_cv_app(str(r.job), str(r.site)): J.apply_from_app(str(r.job), str(r.site))
			await create_timer(1.0).timeout
			J.submit_cv({"name": "Ada", "age": 27, "vocation": str(r.job), "years": 2, "drive": false, "skills": ["learn_fast"], "skill_lines": ["I can learn fast."]}, str(r.job), str(r.site))
			root.get_node("GameState").set_flag(&"cv_done", true); J.emit_signal(&"cv_submitted", str(r.job))
			if ph.has_method(&"close"): ph.close()
			await frames(30); continue
		if st == "order_app":
			await create_timer(1.0).timeout
			var D := root.get_node("Delivery")
			for pl_: Dictionary in D.places:
				if D.is_open(pl_) and not pl_.get("items", []).is_empty():
					D.select_place(str(pl_.key)); D.add_item(str(pl_.items[0].id), 1); break
			D.checkout(); await frames(30); continue
		if st == "dinner_pickup":
			await create_timer(2.0).timeout
			var D2 := root.get_node_or_null("Delivery")
			if D2 and not (D2.get(&"orders") as Array).is_empty(): D2.call(&"receive_all")
			continue
		if st == "pc_wait":
			await create_timer(0.8).timeout
			if _st() == "pc_wait": scene.home.use_pc(CoreSvc.player())
			continue
		if st == "bed_wait" and scene.get(&"actions") and not scene.actions.busy:
			await create_timer(0.8).timeout
			if _st() == "bed_wait": scene.actions.do_action("bed", "sleep")
			continue
		if st == "bus_board":
			await create_timer(0.8).timeout
			var bp_: Node3D = scene.get(&"board_point")
			if bp_ and is_instance_valid(bp_):
				root.get_node("SaveGame").place_player(bp_.global_position + Vector3(0, 0.3, 0), 0.0)
				await create_timer(0.6).timeout
				root.get_node("Interact").use_current(); await create_timer(0.6).timeout
				if _st() == "bus_board": print("NOTE %7.1fs bus: Use at the door did not board" % T())
			continue
		if scene.get(&"pick_open"):
			await create_timer(0.4).timeout
			if scene.get(&"pick_open"):
				var good: Array = scene.get(&"pick_good")
				scene.picked.emit(good[0] if good.size() else 0)
			continue
		if st == "walk_stop" and not (scene.get(&"trip") as Dictionary).is_empty():
			await create_timer(1.0).timeout
			var bp: Vector3 = scene.trip.board_pos
			root.get_node("SaveGame").place_player(bp + Vector3(0, CoronadoTerrain.height_at(bp.x, bp.z) + 0.3, 0) + (CoronadoPlaces.spawn_position("home") - bp).normalized() * 4.0, 0.0)
			moved += 1; await create_timer(1.0).timeout; continue
		if st == "walk_site":
			await create_timer(1.0).timeout
			var sx: Vector2 = scene.site_xz()
			root.get_node("SaveGame").place_player(Vector3(sx.x, CoronadoTerrain.height_at(sx.x, sx.y) + 0.3, sx.y + 3.0), 0.0)
			moved += 1; await create_timer(1.0).timeout; continue
		if st == "walk_cafe" and not (scene.get(&"cafe") as Dictionary).is_empty():
			await create_timer(1.0).timeout
			var d2: Vector2 = ShopsData.door(scene.cafe, 2.2)
			root.get_node("SaveGame").place_player(Vector3(d2.x, CoronadoTerrain.height_at(d2.x, d2.y) + 0.3, d2.y), 0.0)
			moved += 1; await create_timer(1.0).timeout; continue
		# generic: the story has waited > 4 s with an active quest marker the player is not at -> walk there
		# (only in states where the story waits for the player to WALK; never during talks, rides, lessons or the bus)
		if Time.get_ticks_msec() - still_since > 4000 and (st.begins_with("walk") or st in ["ordered", "at_stop", "bed_wait", "home", "idle"]):
			var OB := root.get_node("Objectives")
			var g: Vector2 = OB.goal()
			var pl := CoreSvc.player()
			if g.is_finite() and pl and Vector2(pl.global_position.x, pl.global_position.z).distance_to(g) > 2.5:
				root.get_node("SaveGame").place_player(Vector3(g.x, CoronadoTerrain.height_at(g.x, g.y) + 0.3, g.y), 0.0)
				moved += 1; print("MOVE %7.1fs state=%s -> quest marker %s (%s)" % [T(), st, g, OB.active])
				still_since = Time.get_ticks_msec(); await create_timer(1.0).timeout
				var I := root.get_node("Interact")
				if I.get(&"current") != null and is_instance_valid(I.current): print("      Interact current %s" % I.current.name)
	Engine.time_scale = 1.0
	print("PLAY end at %.1fs  flow_finished=%s  beats=%d  moves=%d  stalls=%s" % [T(), flow_done[0], beats.size(), moved, stalls])
	var gs := root.get_node("GameState")
	print("PLAY flags: cafe_done=%s flatmate_pending=%s day2_pending=%s job=%s money=%s" % [gs.get_flag(&"cafe_done", false), gs.get_flag(&"flatmate_pending", false), gs.get_flag(&"day2_pending", false), root.get_node("Jobs").call(&"current_job") if root.get_node("Jobs").has_method(&"current_job") else "?", root.get_node("Economy").get(&"money")])
	quit(0)
