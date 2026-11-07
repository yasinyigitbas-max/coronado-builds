# bugcheck1 update: patches 0015-0029 only

Patches 0001-0014 are already in your build. Do not re-apply them.

1. Check: `git log --oneline | head -25`. The newest bugcheck commit must be
   "Crowd: walkers wait for green only at the kerb, never mid-crossing" (0014).
2. Apply the thirteen new patches in order (if your build already has 0015-0023, apply only 0024-0027), from `bugcheck1/patches/` on branch `claude/laughing-bell-mxpuak`:
   ```
   git am -3 0015-*.patch 0016-*.patch 0017-*.patch 0018-*.patch 0019-*.patch 0020-*.patch 0021-*.patch 0022-*.patch 0023-*.patch 0024-*.patch 0025-*.patch 0026-*.patch 0027-*.patch 0028-*.patch 0029-*.patch
   ```
3. Your build also has your own "activationopt1a" changes. 0015 (map_dc/coronado/tests/coronado_layers.gd, `_pkg_added`)
   and 0018 (world_fx/breakables.gd `_rebuild`, furniture_layer.gd `_variant`) touch the same functions. If a patch
   does not apply cleanly, merge by hand and keep BOTH your timing spans and the patch's logic. Do not skip the patch.
   Stop and report if you are unsure.
4. Re-bake ONLY the car LOD meshes (0020 + 0026): `godot --headless --path . -s res://tools/red_bake_car_lods.gd`.
   **Required**: without it the old torn far car meshes (black panels) stay in the game. Run it again after 0026 even if
   you ran it for 0020 (0026 changes the impostor). `tests/brown/test_pb_carlods.gd` PASS proves the bake is current.
   Expect `CARLOD <id> files 8 mismatches 0` for all 12 cars; it rewrites only vehicles/models/lod/. 0015-0019 are
   runtime code only, 0021 is settings / code only. If the 18 door-clearance cells (0008 / 0011) were already re-baked, nothing else needs baking.
   Never force a full re-bake.
5. Run `godot --headless --path . --import` once, then these tests (through `bugcheck1/tools/late_launch.gd`), all PASS:
   tests/world_fx/test_breakables.gd, tests/fuel/test_fuel.gd, tests/worker/test_tree_col.gd, tests/core/test_save.gd,
   tests/traffic/test_traffic.gd, tests/traffic/test_cityride.gd, tests/brown/test_pb_carlods.gd,
   tests/brown/test_pb_carlods3.gd, tests/traffic/test_car_mesh.gd.
6. **Export WITH the shader baker (0022), not headless.** 0022 turns on `shader_baker/enabled` in both Android presets.
   The bake only runs when the export itself uses a Vulkan renderer of the same kind as the phone, so:
   ```
   godot --path . --rendering-method mobile --export-debug Android /path/to/out/coronado-fix3.apk
   ```
   - Do NOT pass `--headless` (no renderer = no bake). The machine needs a GPU / Vulkan driver; on a display-less Linux
     box use `xvfb-run -a` in front with a Vulkan driver installed (e.g. mesa).
   - Check the export log: it must show **"Baking shaders"** and must NOT show
     `The editor is currently using a different renderer than what the target platform will use` or
     `"Shader Baker" is not supported when using the Compatibility renderer`. If you see either, stop and report.
   - Expect the export to take longer (several minutes for the bake) and the APK to grow a few MB.
7. Testers: do NOT tap the debug "Scale 0.5" button during a perf lap (it switches to full resolution; the 17:26 Redmi lap
   ran at 4x the pixels because of it).
8. Build name: **`coronado-fix3`** (in `build_id.txt` and both `version/name` entries of `export_presets.cfg`;
   APK file `coronado-fix3.apk`).
   Raise `version/code` by 1, same package and signing key. Export the APK. Don't publish or release.

What the five patches do:
- 0015: block activation spread over frames (main stutter while driving)
- 0016: fuel station built in stages (70 ms freeze)
- 0017: open shops are no longer hidden by the street occluder (looked empty from the door)
- 0018: breakable props without GPU read-backs
- 0019: buildings drawn properly to 300 m (no shape change at 70 m)
- 0020: car meshes without holes, black smears or missing wheels (near and far versions)
- 0022: shader baker at export (no first-use shader stalls on the phone)
- 0024: far traffic cars no longer vanish in groups; car lights end where their car's body ends
- 0025: a shop's whole room is drawn while its door is open (no portal culling from outside)
- 0026: parked-car impostor lit and shaped right (no dark roof slab); parked-car batches not capped at 220 m (re-bake car LODs)
- 0029: facade kit without roof edges (cornices / parapet caps). BAKE: bake_kit.gd + kit_manifest --verify=12, then
  bake_cellpkg --only=<the 283 cells in bugcheck1/KIT_CHANGED_CELLS_0029.txt>, then dcut_pkg --merge + verify_bakes
  (same commands as AGENT_INSTRUCTIONS step 4). Only those cells; never a full re-bake.
- 0028: trees off sidewalks / out of buildings and park paths (trees.json data; the furniture bake bake_world refreshes
  the cached tree placement, no cell package re-bake)
- 0027: smooth grass / sand / soil borders (no zigzag edges)
- 0023: night glow (fades in with darkness, off on the Low preset); MSAA follows the preset (High / Medium 2x, Low off);
  undoes 0021's FSR line (the Mobile renderer has no FSR)
- 0021: MSAA 2x, debanding, AgX tone mapping + mild colour lift, physics catch-up capped at 2 steps (its FSR line has no
  effect on Mobile and is undone by 0023)
  (if 0021 conflicts in project.godot, keep your other settings and only change these six lines)
