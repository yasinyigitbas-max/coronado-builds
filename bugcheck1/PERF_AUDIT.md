# CPU performance audit (bugcheck1, 2026-11-07)

**Scope:** CPU only (Yasin: the game is not GPU bound). Measured headless (no GPU) in the cloud, with all 20 data packs
mounted, on the game's own benchmark: `--perfroute --perfroute_menu --perfseed=1` (main menu → New game → loading
screen → one lap of Amber Ave / Orange Ave, about 4.5 min). PerfProbe CSV plus actprobe1 activation JSONL.
The cloud CPU is much faster than a phone, so **absolute ms here are lower than on the phone; the ranking carries over.**

## Steady state (every frame while playing): within budget
| | Lap, 4 runs |
|---|---|
| Script time per frame (PerfProbe `proc_ms`) | mean **3.3–3.7 ms** (budget 4), p99 9–10 ms (budget 8) |
| Physics | mean 0.27 ms, p99 1.7 ms |

Largest per-frame systems (mean ms/frame): traffic 0.73 (the bugcheck lane logic adds about 3%), buildings 0.70,
world 0.50, traffic visuals 0.46, crowd 0.41, crowd drawing 0.27. Nothing in the steady state threatens 60 fps.

## Hitches (single long frames), ranked
1. **Cell package activation while driving: worst, and it varies a lot.** `pkg.post_add` → `pkg.road_register` and
   `pkg.furniture_register` (furn.merge_register). Over 155 activations per lap, the first run cost 2.6 s + 1.8 s,
   with single frames of **330 ms / 216 ms**. Three later runs of the same lap cost 0.36 s + 0.19 s (worst 9 ms / 3 ms).
   It's the same work, 7–10× slower depending on machine state (memory or contention), so it's very likely to spike
   on a phone. The work: `surface_get_arrays()` read-back of the package road / props meshes, then `CellMerge.add` /
   `FarMerge.register` copying and hashing big vertex arrays, all on the main thread inside one activation frame.
   **Fix options (best first):**
   a. Spread it out: register one mesh surface per frame (queue in `coronado_layers._pkg_added` /
      `furniture_layer._pkg_on`), keeping the piece's own mesh visible until its cell merge is live. CellMerge already
      keeps a piece drawn until merged. No re-bake needed.
   b. Store the merge-ready arrays in the package at bake time (`arrs` / `cell_arrays` / `far_arrays` metas are already
      supported) so no read-back happens at runtime. Needs a cell-package re-bake (all cells: bigger packs).
   c. Move the read-back + transform into the existing CellMerge worker tasks (only the final ArrayMesh build stays
      on the main thread).
2. **Synchronous resource loads on the main thread:** `res_sync_load` 52–73 ms (public layer / furniture streaming,
   for example at t = 28.6 s). Use the threaded loader (`ResourceLoader.load_threaded_request`, like CellPkg already does).
3. **Public layer spikes:** `proc_public_layer` 46 ms once per lap: a public room build step over its slice budget.
4. **Loading screen:** one 3.2–3.6 s frame and about 12–30 frames > 100 ms while the world spawns. They're behind the
   loading screen, so not felt while playing; worth slicing only if the loading bar should animate smoothly.
5. Headless-only, ignore: `pkg_sync_load_headless` (CellPkg.HEADLESS_SYNC loads packages synchronously when
   there is no display; the phone uses the threaded path).

## Recommendations to lock a smooth 60 fps (CPU side)
1. Do 1a (spread package registration over frames) first: it's the only measured source of > 100 ms frames while playing.
2. Replace the remaining main-thread `load()` calls in streaming paths with threaded loads (item 2).
3. Cap per-frame work by a single shared budget (PerfProbe already reports the tags): the traffic sim already does
   this (SYNC_BUDGET_US); the building / furniture / public / interior layers each have their own budgets. A shared
   frame deadline keeps the sum under about 4 ms when several layers stream in the same frame.
4. Frame pacing: keep `physics_ticks_per_second` at 60 with `max_physics_steps_per_frame` 1–2, so a slow frame doesn't
   trigger a physics catch-up burst. Use V-Sync (mailbox / FIFO) with `Engine.max_fps = 60`.
5. Keep the bugcheck traffic lane logic (about +3% traffic CPU); the pedestrian fixes cost nothing measurable.

## Phone run that confirms it (Yasin)
Use the actprobe1 timing build (or bugcheck1 once built):
1. Cold start (swipe the app away first), New game, wait for spawn.
2. Tap **Start route** (bottom left), don't touch anything until the lap ends (about 4.5 min).
3. Tap **Send logs** and send me the zip. It holds `run_*.csv`, `spikes_*.csv` and `activation_*.jsonl`.

I compare `pkg.road_register` / `pkg.furniture_register` / `res_sync_load` against the numbers above. If the phone shows
the spikes, fix 1a is next (about 2–3 h including tests).

Tools: `bugcheck1/tools/perf_audit.py run_X.csv` prints this ranking for any PerfProbe CSV.

## Phone logs, 7 Nov 2026 (build `…-activationopt1a-bugcheck1-update2-src6`, one benchmark lap each)
| | Samsung (Adreno 740) | Redmi (Mali-G610) |
|---|---|---|
| Lap frames / time | 12,589 / 239 s | 15,140 / 238 s |
| Frame time mean / p50 / p99 | 19.0 / 17.1 / 50.5 ms | 15.7 / 14.6 / 43.1 ms |
| Script time (proc_ms) mean / p99 | 8.0 / 31.5 ms | 7.2 / 26.1 ms |
| Frames > 33 ms / > 50 ms / > 100 ms | 734 / 128 / 7 | 286 / 67 / 9 |

Most > 50 ms frames have a script spike (proc ~21 ms on average in the bad frames), not a GPU problem.

**What causes the > 50 ms frames (after the first 5 s of the lap)**
1. **Cell package going live mid-drive** (`bldg_add_tree`: 64 of 117 frames on the Samsung, 36 of 52 on the Redmi).
   The activation JSONL shows it is the registrations after `add_child` (not the add itself): furniture merge register
   up to 12–28 ms, road CellMerge register up to 12–14 ms, breakables geometry up to 15 ms, interior kit adoption
   up to 10 ms, all in one frame (30–40 ms per activation). **Fixed by 0015**: one step per frame.
2. Physics server (`phys_srv`, 24 / 7 frames): collider registration of the same packages. Not changed yet.
3. **Fuel station at 900 Orange Ave**: 71 ms (Samsung) / 74 ms (Redmi) in one frame at t ≈ 67 s.
   **Fixed by 0016**: built in 4 stages, 0.5 s apart.
4. `late_deferred` (call_deferred work) 30–54 ms on a few frames: the profiler does not say which call yet.
5. One-off driver stalls: Redmi `bld_far_swap` 251 ms (one far-mesh upload), Samsung `far_gate` 180 ms with
   draw / swap 130 ms. They are inside the graphics driver, not script. Watch whether they repeat.
6. Lap start (spawn cell activation, 93–98 ms: breakables first use 58 ms, road setup 18–41 ms) happens right after
   the loading screen, once.

**Next run:** same lap on the build with 0015–0017. Expect the `bldg_add_tree` frames and the fuel station frame to
drop out of the > 50 ms list. Tool: `bugcheck1/tools/act_route.py run_X.csv activation_X.jsonl` prints the lap-only
activation breakdown.
