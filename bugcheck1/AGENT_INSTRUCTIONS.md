# bugcheck1: instructions for the build agent

You are turning the **bugcheck1** source fixes into a playable Android build of Coronado.
These are code and data-rule fixes found by a cloud bug check of the
`coronado-vulkan-mobile1-20261107` (actprobe1 src6) source. **Nothing here has been baked or
exported yet; that is your job.** Work through the steps in order. Stop and report if a check fails.
Don't work around a failed check.

## 0. Ground rules
- Engine: **Godot 4.7.2-stable official (build ed1daf0bf)** and its matching Android export templates. Don't use any other version.
- Base source: the release asset
  `coronado_b17int19_hud_onelap_rebake1_treevis1_mobilevk1_actprobe1_src6_source.tar.gz`
  from release `coronado-vulkan-mobile1-20261107`. The Godot project is `coronado-actprobe1-source/project/`.
- Follow `BUILD_AND_DEPENDENCIES.md` in that archive for the toolchain, the data packs and the speech plugin.
- **A re-bake is required and approved by Yasin**, but **bake only what changed** (Yasin's rule): door clearance changes the
  street furniture of 18 cells, and 0020 changes the car LOD meshes (12 car models); nothing else needs new bakes.
  Never force a full re-bake (no version bumps, no `--clean`).
- Don't upload, publish or create a release until Yasin says so. `tools/pack/publish_packs.sh` stays a dry run (no `--yes`).
- Don't change anything outside what these steps describe. If a patch does not apply cleanly, stop and report.

## 1. Prepare the source
1. Unpack the source archive, then restore the omitted baked directories exactly as `BUILD_AND_DEPENDENCIES.md` says
   (`dependencies/download_packs.py` + `dependencies/restore_baked.gd`).
2. In `project/`: `git init`, `git add -A`, then commit a baseline ("actprobe1 src6 as released").
3. Run a first headless import with the exact engine: `godot --headless --path . --import`.
   Errors about `Nunito.ttf` / `game_theme.tres` on the **first** import only are expected; a second `--import` must be clean.

## 2. Apply the patches
From `project/`, apply every file in `bugcheck1/patches/` **in number order** with `git am`:

```
git am /path/to/bugcheck1/patches/0001-*.patch
git am /path/to/bugcheck1/patches/0002-*.patch
...
git am /path/to/bugcheck1/patches/0031-*.patch
git am /path/to/bugcheck1/patches/0032-*.patch
git am /path/to/bugcheck1/patches/0033-*.patch
git am /path/to/bugcheck1/patches/0034-*.patch
```

| Patch | What it fixes | Files |
|---|---|---|
| 0001 | `x is T and is_instance_valid(x)` errors on freed objects (skipped cleanup when cells unload) | 14 scripts, one-line swaps |
| 0002 | Tree trunk colliders were never built while the player stood still / walked slowly | furniture_layer.gd |
| 0003 | Activation-timing logs never pruned (one file per launch, all in every Send logs zip) | debug/activation_timings.gd, debug/perf_probe.gd |
| 0004 | Wardrobe Wear crashed on top / bottoms / shoes and stayed stuck open | core/char_creator.gd, ui/wardrobe/wardrobe.gd |
| 0005 | CityRide taxi spawned on the wrong side / longest route (2 stands never got a taxi) | cityride/city_ride.gd |
| 0006 | Tree "S:" shadow batches drawn as extra visible full-detail trees (+15 draws at spawn) | furniture_layer.gd |
| 0007 | Traffic: lane changes, overtaking, going around stopped cars, kerb stops (no more "270 degree" right-right-right left turns) | traffic/traffic_sim.gd, cityride/city_ride.gd |
| 0008 | Door clearance: trees / street props removed from the 2 m in front of every shop door (10 doors were blocked) | furniture/door_clear.gd (new), furniture_layer.gd, perf/cell_pkg.gd |
| 0009 | Doors: Open works on the first tap (was dropped while the room loaded); package shops woken (were empty shells) | shops/interior/interiors_layer.gd, shops/shops_layer.gd, public/public_layer.gd |
| 0010 | Traffic: no lane change near a lane's start (1 junction-exit collision in test_traffic); lane test ignores intentional offsets | traffic/traffic_sim.gd, tests/traffic/test_traffic.gd |
| 0011 | Incremental re-bake: undoes 0008's `CellPkg.VERSION` bump; the game prints `DOOR_CLEAR_CELLS x_z,...` (the 18 changed cells) | perf/cell_pkg.gd, furniture_layer.gd |
| 0012 | Pedestrians walk on real sidewalks, turn corners, wait at the kerb (junction table key bug) | traffic/traffic_sim.gd |
| 0013 | No frozen buses (still player at a stand; bus locked in a junction box) | traffic/traffic_sim.gd |
| 0014 | Crowd walkers wait for green only at the kerb, never in the middle of a crossing | map_dc/coronado/npc/crowd_layer.gd |
| 0015 | Perf: a cell package going live mid-drive registers road / furniture / breakables / terrain one step per frame (phone hitch 30-40 ms) | map_dc/coronado/tests/coronado_layers.gd, furniture/furniture_layer.gd |
| 0016 | Perf: fuel station built in 4 stages 0.5 s apart (phone 71-74 ms frame) | vehicles/fuel/fuel_stations.gd |
| 0017 | Shops: the street occluder behind an open shop's front is left out while its room is loaded (shop looked empty from the door) | shops/shops_layer.gd, shops/interior/interiors_layer.gd, shops/interior/shop_interior.gd, tests/coronado_layers.gd |
| 0018 | Perf: breakable props merged from cached mesh data (no GPU read-back per prop: 58 ms at spawn, up to 15 ms mid-drive) | world_fx/breakables.gd, furniture/furniture_layer.gd |
| 0019 | Buildings: full block mesh drawn to 300 m, simplified boxes only from 300 m (buildings no longer change shape at 70 m) | perf/lod_bands.gd, buildings/coronado_buildings.gd |
| 0020 | Cars: near / far car meshes rebuilt without holes, black smears or missing wheels (needs the car LOD re-bake, step 4) | vehicles/car_models.gd, tools/red_bake_car_lods.gd, tests/brown/test_pb_carlods.gd |
| 0021 | Look + frame pacing: FSR 1.0 upscaling, MSAA 2x, debanding, AgX tone mapping + mild colour lift, physics catch-up 2 steps | project.godot, core/game_settings.gd, map_dc/coronado/tests/test_coronado.gd |
| 0022 | Export: Shader Baker on (Vulkan pipeline shaders compiled at export; export with `--rendering-method mobile`, not `--headless`) | export_presets.cfg |
| 0023 | Look: night glow (night only, off on Low); MSAA per preset; undoes 0021's FSR line (no FSR in the Mobile renderer) | world_fx/sun_sky.gd, core/game_settings.gd, project.godot |
| 0024 | Traffic: far cars no longer vanish in groups (lod_bands cap on the far-car batches); car lights end with their body | traffic/traffic.gd, world_fx/car_lights.gd |
| 0025 | Shops: the whole room is drawn while its door is open (portal cull off) | shops/interior/portal_cull.gd, shops/interior/interiors_layer.gd |
| 0026 | Parked cars: impostor lit and shaped like the car; parked batches not capped at 220 m (needs the car LOD re-bake) | vehicles/car_models.gd, vehicles/parked_cars.gd |
| 0027 | Terrain: smooth grass / sand / soil borders (4-texel majority class, light warp) | map_dc/coronado/terrain/terrain.gdshader |
| 0028 | Trees: 1524 moved ~1 m off the sidewalk walking lines; 570 removed (inside buildings, on park paths, no free spot); data only (trees.json) | map_dc/coronado/furniture/data/trees.json |
| 0029 | Facade kit: no roof edges (cornices, parapet caps; eaves already off). Needs the kit bake + package bake of 283 cells | map_dc/coronado/bldg_tex/facade/tools/facade_kit.gd |
| 0030 | Fences: 1474 side-yard + 541 shared rear fences between neighbouring houses (data + loader) | map_dc/coronado/furniture/fences_alleys.gd, furniture/data/fences_alleys.json |
| 0031 | Facade kit: no 3D window trim / shutters (they floated off the walls); kit tris 6.53 M -> 1.17 M. Kit + package bake | map_dc/coronado/bldg_tex/facade/tools/facade_kit.gd |
| 0032 | Kit bake: deletes the old kit_/kitn_ files of a block whose kit is now empty (14 blocks after 0029/0031 kept stale frames). Bake tool only | map_dc/coronado/bldg_tex/facade/tools/bake_kit.gd |
| 0033 | bake_cells `-- --all`: also rebakes merged prop/road cells of packaged chunks (verify_bakes checked them; 2 were stale since 0008). Bake tool only | tools/gray_bake/bake_cells.gd |
| 0034 | Home door cut into its cell package (was hidden behind the porch wall panel); home_layer crash guard. Package bake of 12 cells (already in baked_delta) | tools/gray_bake/bake_cellpkg.gd, home/home_layer.gd |

After applying all of them, run the import again (`--import`) so the new script gets its `.uid` / cache entries.

## 3. Name the build (so it can't be confused with any other build)
- `build_id.txt` and both `version/name` entries in `export_presets.cfg`: **`coronado-fix3`**
  (Yasin: a short name. The older long ids stay in the build history; this one is new and unique.)
- Raise `version/code` in the Android preset by 1 (it must stay an update of the same app; keep package
  `com.yasin.citygame.densecore` and Yasin's signing key so it installs **over** the existing game; never uninstall).
- APK file name: `coronado-fix3.apk`
- Suggested release tag when Yasin approves: `coronado-fix3`, prerelease, title **"Coronado fix3"**.

## 4. Re-bake ONLY the changed parts, then export
Only 0008 / 0011 (street furniture rows of 18 cells), 0020 / 0026 (car LOD meshes) and 0029 / 0031 (facade kit, the cell packages in KIT_CHANGED_CELLS_0029_0031.txt) change baked content. All other patches
(0001-0007, 0009, 0010, 0012-0019, 0021-0025, 0027) are runtime code / settings only.

00. Facade kit (0029 + 0031): `godot --headless --path . -s res://map_dc/coronado/bldg_tex/facade/tools/bake_kit.gd`, then
   `godot --headless --path . -s res://tools/gray_bake/kit_manifest.gd -- --verify=12` (expect `roof_edge_removed 28684` and
   `window_trim_removed 149888` and `stale_removed 28` (first run with 0032) in the BAKE line, kit tris ~1.17 M, and
   `VB kit checked=13 mismatches=0`). bake_kit MUST run after bake_world / restore of baked/ (as in export_baked.sh). Then add the cells of
   `bugcheck1/KIT_CHANGED_CELLS_0029_0031.txt` to the
   `--only=` list of the bake_cellpkg step below (together with the DOOR_CLEAR_CELLS), so their packages carry the new kits.
0. Car LODs (0020), incremental, car files only:
   ```
   godot --headless --path . -s res://tools/red_bake_car_lods.gd
   ```
   Expect for each of the 12 ids `BAKEPART carlods <id> rebake (...)` and `CARLOD <id> files 8 mismatches 0`
   (far meshes about 2.4k-4.4k triangles). It rewrites only `vehicles/models/lod/*.res` and `carlods.json`.
Run these steps from `project/` instead of the whole of `export_baked.sh` (same commands as in that script):

1. Furniture chunk merges + static furniture cells (these tools have no partial mode; they rewrite unchanged chunks
   byte-identical, so only the changed cells' files differ):
   ```
   godot --headless --path . res://tools/gray_bake/bake_world.tscn
   godot --headless --path . res://tools/gray_bake/bake_cells.tscn -- --all
   ```
   bake_cells now ends with `CELLBAKE furn chunks 0 road chunks 0 cells 0` and may exit with an abort (rc 134 / 3):
   that is expected, every cell is a package now (bake_cellpkg) so it has nothing to do.
   Expect in the log: `CoronadoFurniture: 28 props / trees removed from 201 door fronts (door clearance v1)` and
   `DOOR_CLEAR_CELLS -9_18,-18_32,-11_20,-14_25,-17_30,-17_31,-17_35,-18_34,-17_36,-18_33,-11_19,-16_35,-17_33,-19_33,-19_34,-16_37,-17_22,-13_22`
2. Cell packages for those 18 cells only (needs a renderer, like export_baked.sh):
   ```
   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . res://tools/gray_bake/bake_cellpkg.tscn -- --only=<the DOOR_CLEAR_CELLS list>
   ```
   Every other cell keeps its package and index entry (`CELLPKG skip c_x_z (not in --only)`).
3. Door cuts inside those packages (as export_baked.sh does after bake_cellpkg), then the gates:
   ```
   godot --headless --path . res://tools/worker/dcut_pkg.tscn -- --merge
   godot --headless --path . res://tools/gray_bake/verify_bakes.tscn
   ```
4. Export (0022: the shader baker needs a real Vulkan renderer, so NOT headless):
   `godot --path . --rendering-method mobile --export-debug Android /path/to/out/coronado-fix3.apk`
   (display-less Linux: `xvfb-run -a` in front, with a Vulkan driver). The log must show "Baking shaders".

**Data packs carry copies of `furniture/data/trees.json` (0028), `fences_alleys.json` (0030) and the facade kit scenes
(0029 / 0031)** and override the project
files when mounted: re-cut the packs from the patched project, or the game keeps the old trees / fences.
Then cut the content packs with `tools/pack/split_packs.py` exactly as for earlier builds (packs are content-addressed:
only the packs whose files changed get new names, so players re-download only those), and run
`tools/pack/publish_packs.sh OUT/packs VERSION OUT/app.apk` **without `--yes`** (dry run only) and report its output.

## 5. Checks that must pass before you hand the build back
Run each test headless with the restored packs. **Important:** run tests through a launcher that compiles them after
the autoloads exist. `godot -s test.gd` compiles a test before autoloads like `I18n` exist and fails it, and 21 tests
are `extends Node` scenes. The bug check used `bugcheck1/tools/late_launch.gd`:
`LATE_TARGET=res://tests/... godot --headless --path . -s /abs/path/late_launch.gd`

| Test | Expected |
|---|---|
| tests/worker/test_tree_col.gd | PASS (281/281 trunks solid) |
| tests/traffic/test_cityride.gd | PASS (3 trips arrive, 0 collisions / red runs) |
| tests/traffic/test_traffic.gd | PASS (0 collisions, 0 red runs, 0 pedestrian hits) |
| tests/rides/test_taxi.gd, tests/rides/test_hitchhike.gd | PASS |
| tests/traffic/test_scripted.gd, test_positions.gd, test_release.gd, test_car_mesh.gd | PASS |
| tests/minion/test_prop_collision.gd | `DOORWAYS ... blocked=0` (was 2-10); other lines unchanged |
| tests/core/test_save.gd, tests/core/test_story.gd | PASS, no "previously freed" errors |
| tests/ui/test_wardrobe.gd | finishes (no hang); only "rows from the creator choices" fails (outdated: men now have 5 tops) |
| tests/world_fx/test_breakables.gd, tests/fuel/test_fuel.gd | PASS |
| tests/brown/test_pb_carlods.gd, tests/brown/test_pb_carlods3.gd, tests/traffic/test_car_mesh.gd | PASS (after the car LOD re-bake) |
| `tools/gray_bake/verify_bakes.tscn` (part of export_baked.sh) | its usual PASS |

Known outdated tests that fail **before and after** these fixes are listed in `TEST_RESULTS.md`; don't "fix" them
in this build.

## 6. On the phone (Yasin)
Install over the existing app (same signer). Things to look at:
1. Walk into Paris & Me, Island Cork Sandals, Charles Shoe Company, Island Barber Shop, Laundry Lounge: nothing blocks the door.
2. Stand still next to palm trees (Hotel del, Orange Ave): you can't walk through them.
3. Wardrobe at home: change top, trousers and shoes, then Wear. It says each piece, saves and closes; it opens again.
4. Watch traffic downtown: cars move into the turn lane before junctions, pass slow cars, sometimes park at the kerb.
5. CityRide from Hotel del: a taxi arrives in about 1.5 minutes (was 4.5 minutes or never).
6. Send logs: the zip holds only the last 2 sessions' perf files.
7. Compare frame times with the previous actprobe1 run (same route): the tree fix (0006) should lower draw calls;
   0015 / 0016 should remove most > 50 ms frames while driving (block activation, fuel station).
8. Open Crownado Beach Coffee (or any shop) and look in from the door: the counter, machines, tables and staff are
   visible before you step in (0017).
9. Drive towards downtown from 300 m: buildings keep their shape and roof as you approach (0019); the switch to
   simple boxes now happens at 300 m instead of 70 m.
10. Watch traffic and parked cars from 10-100 m: no black holes, torn panels or missing wheels (0020).
11. At night (after ~20:00 game time): street lamps, lit windows and car lights have a soft glow; by day no glow
    (0023). If it is too strong / too weak: world_fx/sun_sky.gd GLOW_I (strength) and GLOW_THRESHOLD.

## 7. Not in this build (reported, not fixed)
- 4 NPC lines without voice clips (barista greet / no_money, passer-by cafe / beach): need recordings.
- A bus can wait forever for a player standing still at the Spreckels Park taxi stand (buses skip the gridlock breaker).
- About 6% of junction turn curves are straight diagonals and about 8% snap mid-turn (`conn_piece` fallback); a separate fix.
- Map-sanity "buried poles / floating trees" are probably measurement artefacts (the ray hits pole boxes / collision vs. drawn ground); check visually.
