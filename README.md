# coronado-builds
Coronado content packs (binary only)

---

## 🛠️ bugcheck1: source fixes, NOT a playable build yet

> **This is not an APK and not a content pack.** bugcheck1 is a set of tested source fixes for the
> `coronado-vulkan-mobile1-20261107` (actprobe1 src6) build. It still has to be **re-baked and exported** (see
> [bugcheck1/AGENT_INSTRUCTIONS.md](bugcheck1/AGENT_INSTRUCTIONS.md)). When that build exists it will be released as
> **`coronado-bugcheck1-20261107`** with build id `…-mobilevk1-actprobe1-bugcheck1`. Every earlier release
> (`worker-b17int-*`, `brown-*`, `dc-grayfix*`, `coronado-vulkan-mobile1-*`) is unchanged.

| | |
|---|---|
| Base | `coronado-vulkan-mobile1-20261107` source (Godot 4.7.2, Mobile/Vulkan, actprobe1 timing build) |
| Status | Fixes written and tested headless (no GPU / phone); **waiting for re-bake + export** |
| Patches | [bugcheck1/patches/](bugcheck1/patches/) (apply in order with `git am`) |
| Bug report | [bugcheck1/REPORT.md](bugcheck1/REPORT.md) |
| Test results | [bugcheck1/TEST_RESULTS.md](bugcheck1/TEST_RESULTS.md) |
| Build steps for the agent | [bugcheck1/AGENT_INSTRUCTIONS.md](bugcheck1/AGENT_INSTRUCTIONS.md) |

### What changes for the player
- **Shop doors** are no longer blocked by trees / benches (Paris & Me, Island Cork Sandals, Charles Shoe Company,
  Island Barber Shop, Laundry Lounge + 5 empty units).
- **Trees are solid**: before, you could walk or drive through palms while standing still or walking slowly.
- **Wardrobe works**: changing top / trousers / shoes no longer gets the wardrobe stuck.
- **Smarter traffic**: cars change lanes before turns (no more turning right three times to go left), pass
  slow cars, go around stopped ones and sometimes park at the kerb. 0 collisions in simulation.
- **City Ride**: a taxi now reaches all 14 stands (2 never got one); typical wait about 100 s → about 50 s (Hotel del 4.5 min → 1.5 min).
- **Performance**: duplicate "shadow" trees are no longer drawn (15 fewer draw calls near spawn); traffic logic costs about 3% more sim time.
- **Logs**: timing logs no longer pile up on the phone.
- **Shops look furnished from the door** (0017): the counter, tables and staff were hidden until you stepped about
  a metre inside ([before / after](bugcheck1/img/0017_shop_doorway_before_after.png)).
- **No first-use shader stalls** (0022): shaders are compiled into the APK at export (Vulkan shader baker).
- **Distant traffic stays put, lights match** (0024); **shops drawn fully once the door opens** (0025); **parked cars
  look right from afar** (0026); **smooth grass / sand borders** ([before / after](bugcheck1/img/0027_surface_edges_before_after.png), 0027).
- **Trees off the sidewalks and out of buildings** (0028), **no floating roof edges** (0029), **fences between
  houses** ([before / after](bugcheck1/img/0030_side_fences_before_after.png), 0030).
- **Night glow** (0023): street lamps, windows and car lights glow softly at night (off by day and on Low).
- **Livelier picture** (0021): MSAA 2x, no sky banding, AgX colours ([tone mapping A/B](bugcheck1/img/0021_tonemap_filmic_agx_mild_strong.png)).
- **Cars look whole** (0020): the near and far car meshes had black smears, holes and missing wheels from the old
  simplifier; rebuilt with Godot's own LOD generator ([before / after](bugcheck1/img/0020_car_lods_before_after_sakura.png)).
- **Buildings keep their shape as you approach** (0019): the real building is drawn out to 300 m (was 70 m); the
  simplified boxes start only past 300 m ([before / after](bugcheck1/img/0019_mid_view_barbers_near_before_after.png)).
- **Fewer stutters while driving** (0015, 0016, from the Samsung + Redmi phone logs): city blocks that appear while
  you drive spread their setup over several frames (was 30-40 ms in one frame), and the 900 Orange Ave fuel station
  no longer costs a 70 ms frame. Street props (bins, signs, bollards) no longer copy their meshes back from the
  graphics chip one by one (0018).
