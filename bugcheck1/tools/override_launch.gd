extends SceneTree
# Like late_launch.gd, but first mounts OVERRIDE_PCK (built from OVERRIDE_FILES "res_path=abs_path;...") on top of the packs.
func _initialize() -> void:
	var pck := OS.get_environment("OVERRIDE_PCK")
	var pk := PCKPacker.new(); pk.pck_start(pck)
	for e in OS.get_environment("OVERRIDE_FILES").split(";", false):
		var kv := e.split("=", true, 1); pk.add_file(kv[0], kv[1])
	pk.flush()
	print("OVERRIDE mounted=", ProjectSettings.load_resource_pack(pck, true))
	var t := OS.get_environment("LATE_TARGET")
	var scr = load(t)
	set_script(scr)
	if has_method("_initialize"): call("_initialize")
