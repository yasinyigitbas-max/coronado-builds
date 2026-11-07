# bugcheck1 status (updated 2026-11-07 ~03:20 UTC)

| Patch | Status |
|---|---|
| 0001-0006 | Done. Full 103-test run: only intended changes (tree_col FAIL→PASS, wardrobe TIMEOUT→FAIL on an outdated check) |
| 0007 traffic lanes | Done. Soak 3 seeds: 0 collisions / red runs; 14/14 CityRide stands. Full run (84/103 done before stop): cityride FAIL→PASS, **test_traffic PASS→FAIL** (1 collision + lane-offset check) |
| 0008 door clearance | Done (live build: 0/198 doorways blocked). Needs re-bake |
| 0009 door open / empty shops | Done (probe: 5/5 doors open on first tap; package shops woken) |
| 0010 traffic fix for test_traffic | Written, **NOT yet tested** |

## Next steps (for the next session)
1. Re-run tests/traffic/test_traffic.gd with 0001-0010: expect 0 collisions, cars_on_lanes PASS.
2. Full 103-test run with 0001-0010; compare with TEST_RESULTS (release) table.
3. Turn-curve fix (straight / kinked connectors), only if Yasin asks.
4. Physics (basic / fuller), only when Yasin says "start physics".
5. Open the pull request bugcheck1 → main for Yasin to merge.

## New request (Yasin, 2026-11-07 03:1x UTC): one solid wall colour per building + no half doors / windows
Approved: re-bake. Hero locations (Hotel del Coronado, Village Cinema and other landmarks) keep their own look.
Findings so far (not fixed yet):
- Wall colour = `map_dc/coronado/bldg_tex/bldg_atlas.gdshader`: style tiles from `textures/styles.json` (bldg_style.py) +
  6 wall-texture sets from `facade/setmap.png` (R8, **2 m/px**, sampled 1 m inside each wall). Adjacent buildings share
  boundary pixels, so one building's walls can sample the neighbour's set → irregular multi-coloured buildings (likely cause).
- Plan: give each non-hero building ONE set + ONE solid wall colour from its building id (per-building attribute in
  the baked building / blockmerge chunks, or a building-id lookup instead of the 2 m setmap), hero list exempt;
  then re-bake (build_buildings.py → bake_chunks → blockmerge bake_blocks → vlit → kit → cellpkg via export_baked.sh).
- Doors / windows: scan facade kit placements (`facade/tools/facade_kit.gd`, kit_X_Z.scn) + shop prefabs for parts that
  overhang a wall end, cross a door cut, or are clipped by the roof / ground → list + fix the placement rules.

## Queued (Yasin, 2026-11-07 ~03:20 UTC), after the wall-colour / door-window work
C) **Pedestrian (NPC walker) logic**: walkers wander into streets, can't decide where to go, stand still (sometimes in
   the middle of a road). Goal: walkers path over ALL legally walkable areas (sidewalks, crosswalks, paths, plazas,
   parks), strongly prefer sidewalks / footways, cross only at crosswalks / corners, never idle on the carriageway,
   reroute themselves when blocked. Measure before/after (time on carriageway, idle-on-road count, stuck walkers,
   car-pedestrian conflicts) and sim cost. Code: traffic/traffic_sim.gd (_step_ped, _ped_turn, _ped_at_corner),
   map_dc/coronado/crowd/* (crowd layer walkers).
D) **Full performance audit + 60 fps plan**: CPU side headless (per-system frame cost, streaming / bake-miss hitches,
   PerfProbe tags, spikes, GC/allocation, physics), plus analysis of Yasin's phone PerfProbe / actprobe1 logs if
   provided. Deliver: ranked hitch list with causes + fixes (apply the safe ones as patches), and the phone test run
   needed to confirm a locked 60 fps (GPU cost can't be measured in the cloud).

## Saving rule (Yasin): save progress before the cloud machine can be flushed
After every finished step, and about every 20 min of work, commit + push to claude/laughing-bell-mxpuak (WIP allowed,
marked in STATUS.md). Check usage with the session tool; at "warning" level, push immediately and keep STATUS.md's next
step exact so a new session can continue.

## Note for D (Yasin, ~03:30 UTC): the game is NOT GPU bound, so focus on CPU-bound work only (main-thread scripts,
streaming / instancing / bake-miss fallbacks, physics, traffic / crowd sims, allocations, loading hitches). Yasin will
send phone PerfProbe / actprobe1 logs periodically: when one arrives, add it to the analysis (compare with the previous one).

## Update ~04:00 UTC
- test_traffic with 0001-0010: **PASS** (0 collisions, 0 red runs, lane dev 0.66 m).
- 32 affected / unfinished tests with 0001-0010: no regressions; prop_collision FAIL→PASS, cityride FAIL→PASS (vs 0001-0006).
- 0011: incremental bake (no VERSION bump; 18 changed cells printed as DOOR_CLEAR_CELLS). AGENT_INSTRUCTIONS step 4 rewritten.
- Wall colour (B, first half): **skipped by Yasin** ("may have been fixed before": bld_atlas_mat sets_on = 0 already). Street
  screenshots (software GL) showed one colour per building.
- NEXT: B second half (half / misaligned doors and windows scan), then C (pedestrians), then D (CPU perf audit).
- B second half (doors / windows): the WALL SHADER can't draw half windows / doors (build_buildings.py stretches every
  wall segment to whole bays `0..round(L/bw)` and whole floors; segments < 1.6 m get no windows; the door owns its whole
  bay). Remaining suspects are things laid OVER the wall: shop door cuts (CoronadoDoorCut) slicing a painted window,
  shop fronts covering part of a painted door, facade-kit trims (facade_kit.gd p_window_trim) not on the shader's bay
  grid. **Waiting for a screenshot / location from Yasin** before changing anything. Moving on to C (pedestrians).

## C (pedestrians), WIP ~04:45 UTC
Audit (tools/probe_peds.gd, 2 min per spot, "on road" = inside a drivable road's measured width):
- Traffic-sim walkers on the carriageway 10-30% of samples; standing still on the road up to 31-36 s.
- Cause 1 (fixed in WIP): short street pieces INSIDE big junctions (links between the halves of 4th St / Amber /
  C Ave) were part of the walker network: 37 of 52 on-road walkers at Orange & 4th walked "along" them through the box.
  Now a piece needs >= 4 m of sidewalk outside both junction set-backs.
- Cause 2 (fixed in WIP): corner trigger / turn target used a flat 4 m from the node centre (inside a 10-14 m wide
  cross street) -> _corner_s() = junction set-back - 1.5 m (cached).
- Crowd layer (npc/crowd_layer.gd): 6-13% on road, mostly legit crossings; some W_WAIT samples on the road at Hotel
  del / Amber (crossing segment starts inside the road?), to check.
NEXT: refine the audit (split crossing vs walking vs waiting), confirm the WIP patch, then crowd W_WAIT, then commit as 0012.
WIP patch: bugcheck1/patches/WIP-0012-pedestrians.patch (NOT for the build agent yet).

## C (pedestrians) ~05:40 UTC: patch 0012 committed (traffic-sim walkers)
Walking on the road 1327/485/235/138 -> 1/19/0/4 (Orange&4th / Hotel del / Amber / residential); waiting in the road
469/126 -> 0; standing still on the road 316/57 -> 0. Root cause = float vs int node keys in traffic_sim.gd (_node_all).
**Found for CARS too (not fixed, separate task, ~half a day):** the same key bug makes every car-lane junction set-back 0,
so lanes run to the junction centre and turns pivot there (likely the real cause of "cars can't turn corners").
Fixing it for cars deadlocks scripted rides (a car in a box can't book the next box, one booking per car) -> needs the
junction-booking rules reworked; ask Yasin.
NEXT: (1) re-run traffic/ride tests with final 0012; (2) crowd layer (npc/crowd_layer.gd): agents WAIT at signals already
inside the road at Hotel del (crossing segment start inside the carriageway?): probe probes/probe_crowdx.gd was killed by a
worker restart; re-run it; (3) then D (CPU perf audit).

## ~06:10 UTC: 0012 final + 0013
- 0012 (pedestrians) + 0013 (frozen buses): test_cityride, test_traffic, test_taxi, test_hitchhike, test_scripted,
  test_positions all PASS. Buses still run (bus_present 2, 13 stops served).
- NEXT: crowd layer W_WAIT-on-road check (probes/probe_crowdx.gd), then D (CPU perf audit).

## ~06:25 UTC: C (pedestrians) DONE: 0012 + 0013 + 0014
Crowd walkers (0014): standing still on the road 0 at all 4 audit spots (Hotel del was 61-122). NPC tests pass.
NEXT: D (CPU performance audit + 60 fps plan). Car junction rework (key bug for cars + one-booking rule) = separate,
waiting for Yasin.

## D (CPU perf audit) WIP ~06:55 UTC
Route (perf_route one lap, --perfroute_menu --perfseed=1, headless, packs mounted): script mean 3.65 ms (budget 4), p99 10.4.
- 69 of 74 hitches > 50 ms = cell package activation (proc_coronado_buildings): bldg_add_tree / pkg.post_add 200-380 ms,
  per actprobe1 JSONL: pkg.road_register 2.6 s total (peak 330 ms), pkg.furniture_register 1.8 s (peak 216 ms);
  add_child itself only 58 ms total. pkg_sync_load_headless = headless-only path (CellPkg.HEADLESS_SYNC), not on phone.
- The SAME route warm (OS file cache full) has NO hitch > 100 ms (max 67 ms): the spikes are main-thread DISK READS of
  pack data during activation (cold cache = phone-like). Instrumented warm runs: CellMerge.add < 5 ms, road register
  <= 17 ms, Baked.load_any <= 7 ms. NEXT: find which call reads from disk on the main thread (cold-cache run).

## ~07:00 UTC: D (CPU perf audit) DONE, see bugcheck1/PERF_AUDIT.md
Steady state within budget (script 3.3-3.7 ms mean). Only measured play-time hitch source = cell package activation
(road / furniture merge registration on the main thread, 7-10x variance between runs, up to 330 ms). Recommended fix 1a
(spread registration over frames, no re-bake) waits for Yasin's phone actprobe1 logs to confirm.
Queue empty. Waiting for Yasin: phone logs (perf), example screenshots (half doors / windows), go / no-go for the car
junction rework (key bug for cars + one-booking rule) and the turn-curve fix.

## Phone logs 7 Nov (Samsung + Redmi) → 0015-0017
- Analysed both laps (PERF_AUDIT.md "Phone logs"). Main stutter = package activation registrations in one frame.
- 0015 staged activation, 0016 staged fuel station, 0017 shop occluder hole (Yasin's screenshots).
- Tests with 0015-0017: test_breakables, test_tree_col, test_save, test_cityride, test_traffic (0 collisions),
  test_fuel PASS. test_prop_collision: blocked door count varies run to run on BOTH old and new code (old 1/1,
  new 4/2); every blocked door is in the 18 DOOR_CLEAR_CELLS waiting for the re-bake (old packages still have the
  props there). Probe: all live packages terrain-swapped + furniture-registered after spawn (same as before).
- 0017 rendered check (xvfb opengl3): doorway shows the furniture (was empty floor). img/0017_shop_doorway_before_after.png
- Next: cloud benchmark lap with 0015 to confirm no regression; then wait for the next phone logs.
- 0015 verified on cloud lap (pkg.activation peak 1.6 ms; script mean 3.72 ms; 0 script errors).
- phys_srv / late_deferred spikes: package-load GPU work on the main thread (engine limit). Separate render thread
  crashes (cloud, opengl3) -> not used. Documented in PERF_AUDIT.md.
- 0018 breakables without GPU read-back: identical arrays (0 mismatches), test_breakables / tree_col / save PASS.
- Next in queue: far / mid building views matching the near look (Yasin, after perf).

## Far / mid buildings (Yasin, after perf) → 0019 (step 1 of 2)
- Cause: full block mesh drawn only to 70 m; 70-300 m = LOD1 oriented boxes (+ kit details floating on them), 270 m+ =
  LOD2 chunk silhouettes (blobs), flat baked colours.
- 0019 (runtime, no bake): full mesh to 300 m, boxes 300-730 m, silhouettes from 670 m. Render cost unchanged / lower.
- Step 2 (needs a building re-bake, not started): regenerate the 300 m+ boxes / silhouettes from the real footprints
  with the near wall colours (per-building simplified prisms instead of chunk blobs).

## Cars (Yasin: "black empty parts") → 0020
- Quarter mesh (≤ 35 m) smeared dark texels over the bonnet; far mesh (35-140 m) torn, black panels, no wheels.
- Rebuilt with ImporterMesh.generate_lods (quarter ≈ 50 % level, far = body + wheels at ≈ 20 % level). Needs the
  car LOD re-bake (red_bake_car_lods.gd, car files only). test_pb_carlods (FAIL on release) / carlods3 / car_mesh PASS.

## Cheap look / pacing items 1-6 → 0021
- physics catch-up 2, debanding, FSR 1.0, MSAA 2x (reverses the 28 Oct GL-era removal), AgX + contrast 1.05 /
  saturation 1.10 (picked from rendered A/B). test_traffic / cityride / save / car_mesh PASS.
- Not yet: shader baking at export, night glow, per-item graphics switches, render scale (items 7-10).
- Item 7 → 0022: shader_baker/enabled=true in both Android presets. Export must run with --rendering-method mobile
  on a Vulkan machine (not --headless); not testable in the cloud (no Vulkan, no Android templates).
- Item 8 → 0023: night glow (SunSky._glow_apply), presets get glow / msaa; FSR line undone (Mobile renderer has no
  FSR: engine falls back to bilinear). Glow threshold not judgeable in GL Compatibility (clips at 1.0): tune on phone.
- Items 9, 10: skipped (Yasin).

## Story playthrough (New Game → end), 7 Nov
- bugcheck1/tools/play_story.gd: real StoryDirector.start_new(), answers like a player (typed fallback of each voice
  prompt, lesson / quiz taps, phone payments, CV, delivery), walks to the quest marker only in walk states. 3x speed.
- Clean run (with 0015-0023): flow finished, 127 beats, 0 stalls, 0 script errors, 413 s (driver answers instantly).
  Beats: bugcheck1/STORY_PLAYTHROUGH_BEATS.txt.
- Found: 12 story lines have no voice clip (caption only): directions / bus stop names / interview invite (built from
  live data), café fill-in-the-blank lines, and the static narrator line "Day 10. McCain Boulevard Gate, North Island
  Base.". Missing en strings: npc.narrator, home.item.bedroom (English fallback shown).

## Play-test round 2 (Yasin 7 Nov evening), items 1-4 → 0024-0027
- Redmi update5 lap: render scale was toggled to 1.00 during loading (4x pixels): GPU 8 → 15-17 ms. Not a regression.
  0018 breakables peak 58 → 1.2 ms, 0015 activation hitches 49 → 28 frames > 50 ms, fuel 74 → 43 ms.
- 0024 far-car batches + CarLights exempt from lod_bands' 220 m cap (measured from the batch centre); lights end with body.
- 0025 portal cull off while a shop door is open / latched.
- 0026 impostor normals outward, cabin from real vertices, painted roof edge; parked batches exempt from the cap.
  Car LOD re-bake required (test_pb_carlods FAIL with old bakes, PASS with new).
- 0027 terrain class borders smooth (4-texel majority), warp +-0.6 m.
- test_traffic / test_car_mesh / test_pb_carlods PASS; door flow OK on 6 shops.
- Item 5 → 0028 (trees.json): scan bugcheck1/tools/tree_scan.gd; 376 in buildings + 109 on paths + 85 sidewalk (no
  space) removed, 1524 moved ~1 m off the walk graph lines. test_tree_col PASS. Tree canopies look black from
  underneath (noted, not fixed).
- Item 6 in progress: kit roof edges (cornices + parapet cap) off (Yasin: remove eaves / roof edges entirely).
- Item 6 → 0029: kit roof edges off (Yasin). Kit bake here: 28684 removed, 7.29 M → 6.53 M tris, 283 cells' kits
  changed (KIT_CHANGED_CELLS_0029.txt). Rendered checks with --nocellpkg showed no regressions; floating rooftop
  boxes seen from a camera inside a building are a camera artifact. Packages for those cells need re-baking.
- Item 8 → 0030 side / rear fences (bugcheck1/tools/side_fences.py). Measured with an override pack
  (bugcheck1/tools/override_launch.gd): fences 18.5 → 48.4 km, tris 197k → 413k island-wide, setup +150 ms at load.
- FOUND: data packs override project trees.json / fences_alleys.json: packs must be re-cut (noted in instructions).
  With the real new trees.json: test_tree_col PASS (old trees.json via the same runtime path: FAIL 4/10 downtown).
- Item 7 (road lines) on hold: overhead renders show continuous markings; needs Yasin's screenshot / location.
- Noticed: floating white window frames (facade kit) beside some house walls; tree canopies black from below.
- 0031: 3D window trim / shutters off (149888 removed; kit 6.53 M → 1.17 M tris). Changed cells (0029+0031): 398,
  bugcheck1/KIT_CHANGED_CELLS_0029_0031.txt.
- CORRECTION: the 0029 render check above used the packs' OLD kit scenes (packs override project kit files too).
  Re-checked with an override pack holding the new kits (bugcheck1/tools/override_launch.gd, OVERRIDE_DIRS):
  floating roof-edge bars and window frames are gone.
