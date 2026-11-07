# bugcheck1: bug report (Coronado actprobe1 src6, 2026-11-07)

Checked in a cloud machine (Linux, Godot 4.7.2 headless, no GPU, no phone) with all 20 `coronado-data` packs mounted.
Line numbers refer to the released source.

## Health of the project
- First import: about 10,500 assets in 141 s. The only errors were `Nunito.ttf` / `game_theme.tres` on the very first import (normal); the second import was clean.
- **599/599 scripts compile, 126/126 scenes load.** With packs mounted, 44 harmless "invalid UID, using text path" warnings for shop prop scenes.
- Lint (`tools/lint/gdscan.py`): no duplicate functions or redeclared members.
- 103 tests: 66 pass on the release, 67 with patches 0001-0006 (see TEST_RESULTS.md). Most failures are outdated tests or need a GPU.

## Fixed (patches in `patches/`)
| # | Bug | Where | Fix |
|---|---|---|---|
| 0001 | `x is T and is_instance_valid(x)` throws on a freed object; `_pkg_off` stopped before `cellmerge.remove_prefix` | furniture_layer.gd:441, :457 + 12 more files | check `is_instance_valid` first |
| 0002 | Tree trunk colliders only built after moving > 2 m: walk / drive through palms (Hotel del 0/52 solid) | furniture_layer.gd:484 skipped `_drain_trunks` at :548 | drain on the idle path too → 281/281 solid |
| 0003 | `activation_<unix>.jsonl` never pruned, all zipped by Send logs | activation_timings.gd:45, perf_probe.gd session regex | session-stamped name, `.jsonl` pruned with the session |
| 0004 | Wardrobe Wear: no sentence for top/bottoms/shoes, script error after hiding the panel; wardrobe stuck | wardrobe.gd:101 → char_creator.gd:383 | sentences from CharLook.OUTFITS; never stuck |
| 0005 | CityRide taxi spawned upstream of the opposite carriageway / straight-line nearest point (2 km drives) | city_ride.gd:131 | same direction only, shortest real route, 15 ms cap |
| 0006 | Tree "S:" shadow batches had cast_shadow OFF, so they were drawn as extra full-detail trees | furniture_layer.gd:1097-1102, :1137 | not built while tree shadows are off |
| 0007 | Cars could never change lanes, so left turns from the wrong lane meant going round the block (+550 m median, up to +2.2 km) | traffic_sim.gd | lane changes, overtaking, going around stopped cars, kerb stops, smarter routing |
| 0008 | 10 shop doorways blocked by street props / tree trunks | furniture data rows | door clearance rule + cell package re-bake (VERSION 6) |

## Found, not fixed
- **4 NPC lines with no voice clip** (barista `greet`, `no_money`; passer-by `cafe`, `beach`): need recordings.
- **Bus frozen at Spreckels Park**: a bus waits forever for a player standing still at the taxi stand; buses skip the gridlock breaker.
- **Turn curves**: 624 of 10,235 turn connectors don't match their label (some straight diagonals), 781 kink > 60° (`conn_piece` fallback).
- **Car LODs**: baked bodies differ byte-for-byte from a fresh Linux rebuild; check `test_pb_carlods.gd` on the dev PC.
- **Map polish**: "buried poles / floating trees" from test_map_sanity are probably ray artefacts; check visually.
- Narrator `voice/narrator.gd:188` `bool(pl.get(&"seated"))` errors if a "player" node has no `seated` (tests only).

## Test harness notes
`godot -s test.gd` compiles a test before the autoloads (`I18n`, …) exist, and 21 tests are `extends Node` scenes,
so the check used `tools/late_launch.gd` (compiles the test after autoloads; Node tests are instantiated from their `.tscn`).
