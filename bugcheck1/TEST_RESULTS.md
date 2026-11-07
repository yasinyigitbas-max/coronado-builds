# Test results (release vs. patches 0001-0006, headless, packs mounted)

| Test | Released code | With my 2 fixes | Notes |
|---|---|---|---|
| tests/brown/test_b9_caption.gd | TIMEOUT | TIMEOUT | Outdated test: captions are now RichTextLabel, test types them as Label |
| tests/brown/test_b9_compile_shop_interior.gd | PASS | PASS |  |
| tests/brown/test_b9_day2_lines.gd | FAIL | FAIL | Outdated test: flat is now built from the door Use button (worker-b17int-10) |
| tests/brown/test_b9_home_windows.gd | TIMEOUT | TIMEOUT | Outdated test: flat built from the door Use button |
| tests/brown/test_b9_npc.gd | PASS | PASS |  |
| tests/brown/test_b9_sigfix.gd | PASS | PASS |  |
| tests/brown/test_b9_ui.gd | PASS | PASS |  |
| tests/brown/test_map_sanity.gd | TIMEOUT | TIMEOUT | Needs >4 min; with 25 min: real map polish findings (buried poles, floating trees, 4 route steps, 2 NPC overlaps) |
| tests/brown/test_pb_carlods.gd | FAIL | FAIL | Unconfirmed: baked car LODs differ byte-for-byte from a fresh rebuild; marker carlods.json not shipped |
| tests/brown/test_pb_carlods3.gd | FAIL | FAIL | carlods.json marker missing (optional file; game falls back correctly) |
| tests/cars/test_car_arches.gd | FAIL | FAIL | Unconfirmed: hood/arch geometry checks fail for volt_s, sakura, taxi (same rebuild question as car LODs) |
| tests/cars/test_car_hooks.gd | PASS | PASS |  |
| tests/cars/test_cars_drive.gd | FAIL | FAIL | Car stopped 6 m short of a wall (kerb/furniture in between); test wording; not a bug |
| tests/core/test_calendar.gd | PASS | PASS |  |
| tests/core/test_char_creator.gd | FAIL | FAIL | Outdated test: creator now starts with a name step |
| tests/core/test_i18n.gd | FAIL | FAIL | Outdated test: "café" is now real content; typed answers only count after fallback |
| tests/core/test_letter_clips.gd | PASS | PASS |  |
| tests/core/test_main_menu.gd | PASS | PASS |  |
| tests/core/test_packs.gd | PASS | PASS |  |
| tests/core/test_pause.gd | PASS | PASS |  |
| tests/core/test_save.gd | PASS | PASS |  |
| tests/core/test_settings.gd | PASS | PASS |  |
| tests/core/test_story.gd | PASS | PASS |  |
| tests/door/test_door_rules.gd | PASS | PASS |  |
| tests/economy/test_economy.gd | PASS | PASS |  |
| tests/fuel/test_fuel.gd | PASS | PASS |  |
| tests/intro/test_day1_food.gd | FAIL | FAIL | Outdated test: flat built from the door Use button |
| tests/intro/test_day2.gd | TIMEOUT | TIMEOUT | Outdated test: flat built from the door Use button |
| tests/intro/test_flatmate.gd | FAIL | FAIL | Outdated test: flat built from the door Use button |
| tests/intro/test_gate_taxi.gd | PASS | PASS |  |
| tests/intro/test_ink_caption.gd | PASS | PASS |  |
| tests/intro/test_interview.gd | PASS | PASS |  |
| tests/intro/test_sofa_voice.gd | PASS | PASS |  |
| tests/jobs/test_cv_apply.gd | PASS | PASS |  |
| tests/jobs/test_cv_flow_lessons.gd | FAIL | FAIL | Unclear: CV form not counted complete in the test; needs a look |
| tests/jobs/test_job_picker.gd | PASS | PASS |  |
| tests/jobs/test_job_sites.gd | PASS | PASS |  |
| tests/jobs/test_jobs.gd | PASS | PASS |  |
| tests/jobs/test_mail_flow.gd | PASS | PASS |  |
| tests/lessons/test_lessons.gd | PASS | PASS |  |
| tests/media/test_media_apps.gd | PASS | PASS |  |
| tests/minigames/test_home_dreams.gd | TIMEOUT | TIMEOUT | Outdated test: needs the flat (door Use button) |
| tests/minion/test_caption_voice.gd | FAIL | FAIL | REAL: 4 NPC dialogue lines have no voice clip |
| tests/minion/test_front_doors.gd | PASS | PASS |  |
| tests/minion/test_prop_collision.gd | FAIL | FAIL | REAL: 1-2 shop doorways blocked by street-furniture colliders |
| tests/minion/test_public_layer_freed_room.gd | PASS | PASS |  |
| tests/minion2/test_day2_story9.gd | TIMEOUT | TIMEOUT | Outdated test: flat built from the door Use button |
| tests/minion2/test_home_furniture.gd | PASS | PASS |  |
| tests/minion2/test_npc_glow.gd | PASS | PASS |  |
| tests/minion2_pb/test_cv_lock.gd | PASS | PASS |  |
| tests/minion2_pb/test_taxi_age.gd | PASS | PASS |  |
| tests/perf/test_resident_stream.gd | FAIL | FAIL | Outdated test: waits 4 frames, world now builds riprap/golf over many frames |
| tests/player/test_car_collision.gd | FAIL | FAIL | Test design: traffic keeps moving visually after physics pause; parked check unclear |
| tests/player/test_no_drop.gd | PASS | PASS |  |
| tests/player/test_player_systems.gd | FAIL | FAIL | Mostly outdated (first-person start, 4-part body); swim lean unconfirmed |
| tests/radio/test_radio.gd | FAIL | FAIL | Credits doc not in source archive; "next segment" unconfirmed |
| tests/rides/test_hitchhike.gd | PASS | PASS |  |
| tests/rides/test_taxi.gd | PASS | PASS |  |
| tests/talk/test_talk_anim.gd | PASS | PASS |  |
| tests/test_roads.gd | FAIL | FAIL | Needs a file only on the dev PC; 183 poles off kerb unconfirmed |
| tests/traffic/test_car_mesh.gd | PASS | PASS |  |
| tests/traffic/test_cityride.gd | FAIL | FAIL | REAL: taxi to Hotel del spawns on the wrong side, never arrives |
| tests/traffic/test_positions.gd | PASS | PASS |  |
| tests/traffic/test_release.gd | PASS | PASS |  |
| tests/traffic/test_scripted.gd | PASS | PASS |  |
| tests/traffic/test_signal_stuck.gd | PASS | PASS |  |
| tests/traffic/test_traffic.gd | PASS | PASS |  |
| tests/ui/test_drone.gd | PASS | PASS |  |
| tests/ui/test_hud_layout.gd | PASS | PASS |  |
| tests/ui/test_jobs_app.gd | TIMEOUT | TIMEOUT | Environment: screenshot needs a GPU |
| tests/ui/test_map_pan.gd | PASS | PASS |  |
| tests/ui/test_minimap_landmarks.gd | PASS | PASS |  |
| tests/ui/test_phone_hud.gd | FAIL | FAIL | Minor/unconfirmed: caption panel style changed |
| tests/ui/test_route.gd | FAIL | FAIL | Minor/unconfirmed: near target pin vs arrow |
| tests/ui/test_use_circles.gd | TIMEOUT | TIMEOUT | Environment (screenshot) + test fake player lacks "seated" (narrator.gd:188) |
| tests/ui/test_use_reveal.gd | PASS | PASS |  |
| tests/ui/test_wardrobe.gd | TIMEOUT | TIMEOUT | REAL: wardrobe Wear crashes (no sentence for top/bottoms/shoes) |
| tests/voice/test_voice.gd | FAIL | FAIL | REAL (same as caption_voice): barista greeting has no voice clip |
| tests/voice/test_voice_reasons.gd | PASS | PASS |  |
| tests/worker/test_3a.gd | PASS | PASS |  |
| tests/worker/test_3b.gd | PASS | PASS |  |
| tests/worker/test_b17i7.gd | TIMEOUT | TIMEOUT | Environment: screenshot needs a GPU |
| tests/worker/test_bikes.gd | PASS | PASS |  |
| tests/worker/test_car_lights.gd | TIMEOUT | TIMEOUT | Environment: screenshot needs a GPU |
| tests/worker/test_dtnight.gd | PASS | PASS |  |
| tests/worker/test_fences.gd | PASS | PASS |  |
| tests/worker/test_flashlight.gd | PASS | PASS |  |
| tests/worker/test_gold_captions.gd | PASS | PASS |  |
| tests/worker/test_lamp_bulbs.gd | FAIL | FAIL | Probably environment: 0 lamps rendered headless |
| tests/worker/test_npc_three.gd | PASS | PASS |  |
| tests/worker/test_pack_size.gd | PASS | PASS |  |
| tests/worker/test_pool_ground.gd | TIMEOUT | TIMEOUT | Environment: screenshot / nothing audited headless |
| tests/worker/test_powerlines.gd | PASS | PASS |  |
| tests/worker/test_roof_fade.gd | PASS | PASS |  |
| tests/worker/test_skyline.gd | PASS | PASS |  |
| tests/worker/test_spreckels.gd | PASS | PASS |  |
| tests/worker/test_street_dressing.gd | PASS | PASS |  |
| tests/worker/test_street_fill.gd | FAIL | FAIL | Outdated test: StreetFill is off by default (needs --streetfill) |
| tests/worker/test_tree_col.gd | FAIL | PASS | REAL, FIXED: tree colliders not built while standing still |
| tests/world_fx/test_ambience.gd | PASS | PASS |  |
| tests/world_fx/test_breakables.gd | PASS | PASS |  |
| tests/world_fx/test_night_lights.gd | FAIL | FAIL | Minor/unconfirmed: expects exactly 3 child nodes |
| tests/world_fx/test_sun_weather.gd | PASS | PASS |  |
