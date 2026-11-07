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
