# bugcheck1 update: patches 0015-0019 only

Patches 0001-0014 are already in your build. Do not re-apply them.

1. Check: `git log --oneline | head -25`. The newest bugcheck commit must be
   "Crowd: walkers wait for green only at the kerb, never mid-crossing" (0014).
2. Apply the five new patches in order, from `bugcheck1/patches/` on branch `claude/laughing-bell-mxpuak`:
   ```
   git am -3 0015-*.patch 0016-*.patch 0017-*.patch 0018-*.patch 0019-*.patch
   ```
3. Your build also has your own "activationopt1a" changes. 0015 (map_dc/coronado/tests/coronado_layers.gd, `_pkg_added`)
   and 0018 (world_fx/breakables.gd `_rebuild`, furniture_layer.gd `_variant`) touch the same functions. If a patch
   does not apply cleanly, merge by hand and keep BOTH your timing spans and the patch's logic. Do not skip the patch.
   Stop and report if you are unsure.
4. No re-bake: 0015-0019 are runtime code only. If the 18 door-clearance cells (0008 / 0011) were already re-baked,
   nothing else needs baking. Never force a full re-bake.
5. Run `godot --headless --path . --import` once, then these tests (through `bugcheck1/tools/late_launch.gd`), all PASS:
   tests/world_fx/test_breakables.gd, tests/fuel/test_fuel.gd, tests/worker/test_tree_col.gd, tests/core/test_save.gd,
   tests/traffic/test_traffic.gd, tests/traffic/test_cityride.gd.
6. Build name: keep `…-bugcheck1` and add `-update3` (for example `…-activationopt1a-bugcheck1-update3-src6`).
   Raise `version/code` by 1, same package and signing key. Export the APK. Don't publish or release.

What the five patches do:
- 0015: block activation spread over frames (main stutter while driving)
- 0016: fuel station built in stages (70 ms freeze)
- 0017: open shops are no longer hidden by the street occluder (looked empty from the door)
- 0018: breakable props without GPU read-backs
- 0019: buildings drawn properly to 300 m (no shape change at 70 m)
