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
- **A re-bake is required and approved by Yasin** (door clearance changes the street furniture, so the cell packages must be rebuilt).
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
git am /path/to/bugcheck1/patches/0010-*.patch
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
| 0008 | Door clearance: trees / street props removed from the 2 m in front of every shop door (10 doors were blocked); `CellPkg.VERSION` 5 → 6 | furniture/door_clear.gd (new), furniture_layer.gd, perf/cell_pkg.gd |
| 0009 | Doors: Open works on the first tap (was dropped while the room loaded); package shops woken (were empty shells) | shops/interior/interiors_layer.gd, shops/shops_layer.gd, public/public_layer.gd |
| 0010 | Traffic: no lane change near a lane's start (1 junction-exit collision in test_traffic); lane test ignores intentional offsets | traffic/traffic_sim.gd, tests/traffic/test_traffic.gd |

After applying all of them, run the import again (`--import`) so the new script gets its `.uid` / cache entries.

## 3. Name the build (so it can't be confused with any other build)
- `build_id.txt` and both `version/name` entries in `export_presets.cfg`:
  `brown-perfrescue12-hud-onelap-rebake1-treevis1-mobilevk1-actprobe1-bugcheck1`
- Raise `version/code` in the Android preset by 1 (it must stay an update of the same app; keep package
  `com.yasin.citygame.densecore` and Yasin's signing key so it installs **over** the existing game; never uninstall).
- APK file name: `coronado_..._actprobe1_bugcheck1.apk`
- Suggested release tag when Yasin approves: `coronado-bugcheck1-20261107`, prerelease, title
  **"Coronado bugcheck1: bug fixes + smarter traffic (experimental)"**.

## 4. Re-bake and export
Run the full pipeline from `project/` (it bakes everything in the right order and then exports):

```
tools/gray_bake/export_baked.sh /path/to/godot-4.7.2 /path/to/out/coronado_bugcheck1.apk
```

Why everything: 0008 changes the furniture rows, which changes the furniture chunk bakes (`furn_chunk_*`), the static
FurnCells (`bake_cells`), the walk-in door cuts and **every** cell package (`bake_cellpkg`; `CellPkg.VERSION` 6 makes
every old package invalid on purpose). `bake_cellpkg` needs a real renderer (`xvfb-run ... --rendering-driver opengl3`)
as the script already does.

Expected in the bake / game log: `CoronadoFurniture: 28 props / trees removed from 201 door fronts (door clearance v1)`.

Then cut the content packs with `tools/pack/split_packs.py` exactly as for earlier builds, and run
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
| tests/traffic/test_traffic.gd | PASS (0 collisions, 0 red runs). **Not yet re-run after 0010: run it first; if it fails, report and stop.** |
| tests/rides/test_taxi.gd, tests/rides/test_hitchhike.gd | PASS |
| tests/traffic/test_scripted.gd, test_positions.gd, test_release.gd, test_car_mesh.gd | PASS |
| tests/minion/test_prop_collision.gd | `DOORWAYS ... blocked=0` (was 2-10); other lines unchanged |
| tests/core/test_save.gd, tests/core/test_story.gd | PASS, no "previously freed" errors |
| tests/ui/test_wardrobe.gd | finishes (no hang); only "rows from the creator choices" fails (outdated: men now have 5 tops) |
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
7. Compare frame times with the previous actprobe1 run (same route): the tree fix (0006) should lower draw calls.

## 7. Not in this build (reported, not fixed)
- 4 NPC lines without voice clips (barista greet / no_money, passer-by cafe / beach): need recordings.
- A bus can wait forever for a player standing still at the Spreckels Park taxi stand (buses skip the gridlock breaker).
- About 6% of junction turn curves are straight diagonals and about 8% snap mid-turn (`conn_piece` fallback); a separate fix.
- Car LOD bakes differ byte-for-byte from a fresh rebuild on Linux; check `tests/brown/test_pb_carlods.gd` on Yasin's PC.
- Map-sanity "buried poles / floating trees" are probably measurement artefacts (the ray hits pole boxes / collision vs. drawn ground); check visually.
