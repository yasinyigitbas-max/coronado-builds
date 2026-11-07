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
