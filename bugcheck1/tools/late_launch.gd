extends SceneTree
# Launcher: compiles the real test only after autoloads are registered.
#  - SceneTree test: swapped onto this SceneTree, its _init runs on set_script; _initialize called manually.
#  - Node test: a sibling .tscn of the same name is instantiated if present, else the script itself, added under root.
func _initialize() -> void:
	var t := OS.get_environment("LATE_TARGET")
	var scr = load(t)
	if scr == null or not (scr as GDScript).can_instantiate():
		printerr("LATE_LAUNCH: cannot compile ", t); quit(3); return
	if (scr as GDScript).get_instance_base_type() == &"SceneTree":
		print("LATE_LAUNCH mode=scenetree")
		set_script(scr)
		if has_method("_initialize"): call("_initialize")
		return
	var tscn := t.get_basename() + ".tscn"
	var n: Node
	if ResourceLoader.exists(tscn):
		print("LATE_LAUNCH mode=scene ", tscn); n = (load(tscn) as PackedScene).instantiate()
	else:
		print("LATE_LAUNCH mode=node"); n = scr.new()
	root.add_child.call_deferred(n)
