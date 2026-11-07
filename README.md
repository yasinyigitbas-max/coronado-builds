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
