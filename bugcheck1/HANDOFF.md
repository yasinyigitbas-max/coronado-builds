# Handoff: cloud session → Yasin's PC (7 Nov 2026)

Read this first. You are continuing the work of a cloud Claude Code session that had no Android SDK. Everything it
made is on branch `claude/laughing-bell-mxpuak` of `yasinyigitbas-max/coronado-builds`, folder `bugcheck1/`.

## Yasin's standing rules
- Yasin is not very technical: plain language, short answers.
- Before starting anything: list the planned actions with ETAs, ranked cheapest first, and wait for the OK.
- Put answers to Yasin's questions under the matching task in the task list as well (they get lost in the log).
- Build name: `coronado-fix3` (simple names only).
- Bake only the changed parts, never a full re-bake.
- Physics work only when Yasin says "start physics" (basic or fuller).
- Never ask Yasin to paste secrets (keystore etc.) into the chat.

## State
- Code fixes: patches `bugcheck1/patches/0001-0034` (0001-0014 were already applied on the PC project earlier;
  `AGENT_UPDATE.md` lists 0015-0034 with what each does). Engine: Godot 4.7.2, Mobile renderer (Vulkan).
- Bakes: **all done and verified in the cloud** (kit_manifest --verify=12: 0 mismatches; verify_bakes: ok, every
  `mismatches=0`). Result = `bugcheck1/baked_delta/`: 1259 files that differ from the current coronado-data packs
  plus `GONE.txt` (40 stale files to delete). Do NOT re-bake; just apply it.
- Bake tool fixes made on the way (already in the delta): 0032 (kit bake left stale kit files of now-empty blocks),
  0033 (`bake_cells -- --all`), 0034 (player's home door cut into its cell package).
- Note: `dcut_pkg --merge` reports `doors=0`; the packages already carry their shop door cuts from bake_cellpkg
  (its log shows the cuts), so this was judged harmless. Only re-check if Yasin reports a shop door hole missing.

## What is left (Yasin approved all 3 steps: "you can do all 3 steps")
1. Get the files: `git fetch origin claude/laughing-bell-mxpuak` and check out that branch (or `git am` patches
   0015-0034 onto the PC project if it is a separate repo; see AGENT_UPDATE.md).
2. Apply the bakes: `python3 bugcheck1/baked_delta/apply_delta.py <path to project/>`
   (expect `copied 1259 files, removed 28 or more stale files`).
3. Optional quick gate (from project/): `godot --headless --path . res://tools/gray_bake/verify_bakes.tscn`
   → `VB verify ok=true`, no `mismatches=[1-9]`.
4. Re-cut the content packs (the packs override project files, so phones would otherwise keep the old ones):
   ```
   godot --headless --rendering-method mobile --path . --export-pack AndroidPack OUT/full.pck
   python3 tools/pack/split_packs.py OUT/full.pck OUT/packs coronado-fix3
   cp OUT/packs/pack_manifest.json core/boot/pack_manifest.json
   ```
5. Build the APK `coronado-fix3` with that manifest inside (export preset "Android", `--rendering-method mobile`
   because of 0022's shader baker, see AGENT_INSTRUCTIONS.md).
6. Upload: `tools/pack/publish_packs.sh OUT/packs coronado-fix3 OUT/coronado-fix3.apk` (dry run first: it lists the
   parts it would upload). The `--yes` run uploads only the changed pack parts to release `coronado-data` AND creates
   a prerelease `coronado-fix3` with the APK. Tell Yasin what it will upload and confirm once before `--yes`.
7. Ask Yasin to test on the phones; the checks to ask for are in AGENT_INSTRUCTIONS.md ("phone checks").

## Closed / skipped
- Road lines (item 7), kerb/grass/back-path idea, items 9-10: skipped by Yasin.
- Not fixed, noted only: tree canopies look black from below; "soil inside buildings" needs a screenshot.
