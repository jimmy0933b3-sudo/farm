extends SceneTree
## Integration: Private Farm -> choose an actual animal/insect -> race -> saved results.
const Rules=preload("res://scripts/RaceRules.gd")
const Store=preload("res://scripts/SaveData.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main=load("res://scenes/Main.tscn").instantiate()
	print("RACE PHASE 1: var main=load('res://scenes/Main.tscn').instantiate()")
	root.add_child(main)
	await process_frame
	var previous: Dictionary=main.progress.data.duplicate(true)
	main.progress.unlock("cow")
	main.progress.unlock("rhinoceros_beetle")
	main.progress.unlock("stag_beetle")
	main.progress.data["private_farm"]=["cow","rhinoceros_beetle","stag_beetle"]
	main.progress.save()
	main.show_private_farm()
	print("RACE PHASE 2: main.show_private_farm()")
	await process_frame
	var farm=main.private_farm_game
	if not farm.racing_requested.has_connections():
		_fail("Farm race icon not connected to parent navigation")
		return
	farm.racing_requested.emit()
	print("RACE PHASE 3: farm.racing_requested.emit()")
	await process_frame
	if main.screen!="race_lobby":
		_fail("Farm entry button did not open kart lobby")
		return
	var lobby=main.race_lobby
	if lobby.options.size()!=3 or lobby.selected_id!="cow":
		_fail("Lobby must show the current farm residents")
		return
	var selected_track: Button=lobby.track_buttons[0]
	var other_track: Button=lobby.track_buttons[1]
	if not _readable_button(selected_track) or not _readable_button(other_track):
		_fail("Track button labels must have dark text on a light background")
		return
	var selected_style: StyleBoxFlat=selected_track.get_theme_stylebox("normal") as StyleBoxFlat
	var other_style: StyleBoxFlat=other_track.get_theme_stylebox("normal") as StyleBoxFlat
	if selected_style.border_color==other_style.border_color:
		_fail("Selected track needs a visible border, without fading unselected labels")
		return
	for card in lobby.grid.get_children():
		if not _readable_button(card) or card.modulate!=Color.WHITE:
			_fail("Character labels and icons should stay fully visible when unselected")
			return
	lobby.choose_animal("stag_beetle")
	lobby.choose_track("flower")
	lobby.start()
	print("RACE PHASE 4: lobby.start()")
	await process_frame
	if main.screen!="race_game":
		_fail("Cannot enter racing game")
		return
	var race=main.race_game
	print("RACE PHASE 5: var race=main.race_game")
	if race.racer.get("id")!="stag_beetle" or race.race_track.get("id")!="flower":
		_fail("Chosen beetle or race track was lost")
		return
	if race.ai_karts.size()!=3 or race.player_kart==null:
		_fail("Three AI racers plus actual animal kart are required")
		return
	if race.countdown_remaining<=0.0 or race.countdown_label==null:
		_fail("Kid-friendly 3-2-1-GO countdown is missing")
		return
	var waiting_distance: float=race.distance
	race._process(0.1)
	print("RACE PHASE 7: race._process(0.1)")
	if race.distance!=waiting_distance or race.countdown_label.text not in ["3","2"]:
		_fail("Start countdown must pause driving before GO")
		return
	if race.soundfx==null or not race.soundfx.sounds.has("star"):
		_fail("Race should supply offline sound effects")
		return
	if race.effects==null:
		_fail("Race particle effects are missing")
		return
	if race.track.lane_center_at(0,race.track.size.y*.7)>=race.track.lane_center_at(1,race.track.size.y*.7):
		_fail("Curved road lane centers must stay in order")
		return
	if race.track.lane_center_at(1,race.track.size.y*.1)>=race.track.lane_center_at(2,race.track.size.y*.1):
		_fail("Curved road upper lanes must stay separated")
		return
	if race.track.race_distance!=0.0:
		_fail("Race road must not start moving before countdown")
		return
	if race.track.lane_center_at(1,race.track.size.y*.3)<=0.0:
		_fail("Racing track must provide actual visible lane geometry")
		return
	if race.player_kart.avatar==null or race.player_kart.title_label==null:
		_fail("Actual species portrait and name should be visible inside kart")
		return
	if lobby.track_previews.size()!=3 or lobby.showcase_kart==null:
		_fail("Illustrated track cards and large driver preview are missing")
		return
	var controls: HBoxContainer=race.get_child(2) as HBoxContainer
	if controls==null or controls.get_child_count()!=3:
		_fail("Three racing controls must remain visible")
		return
	for button in controls.get_children():
		if not _readable_button(button) or button.custom_minimum_size.y<64.0:
			_fail("Racing buttons need legible high-contrast labels and large touch targets")
			return
	var disabled_style: StyleBoxFlat=race.boost_button.get_theme_stylebox("disabled") as StyleBoxFlat
	if disabled_style==null or race.boost_button.get_theme_color("font_disabled_color").get_luminance()>0.45:
		_fail("Boost cooldown label must remain readable when disabled")
		return
	race.move_lane(-1)
	print("RACE PHASE 6: race.move_lane(-1)")
	if race.lane!=0:
		_fail("Left button must change lane")
		return
	race.move_lane(1)
	if race.lane!=1:
		_fail("Right button must change lane")
		return
	if Rules.lane_after_swipe(1,78.0)!=2 or Rules.lane_after_swipe(1,-81.0)!=0:
		_fail("Swipe thresholds incorrect")
		return
	race.accelerate()
	if race.boost_seconds<=0.0 or race.boost_cooldown<=0.0:
		_fail("Boost button does not work")
		return
	race._take_item("star")
	race._take_item("shield")
	var old_hits: int=race.collisions
	race._take_item("bump")
	if race.collisions!=old_hits:
		_fail("Shield should protect from obstacle")
		return
	race.shield_seconds=0.0
	race._take_item("bump")
	if race.collisions!=old_hits+1:
		_fail("Bumping a hay bale should gently slow the kart")
		return
	var old_collected: Array=main.progress.data["collected"].duplicate()
	var old_residents: Array=main.progress.data["private_farm"].duplicate()
	var old_races: int=int(main.progress.data["race_totals"].get("races",0))
	race.countdown_remaining=0.0
	race.distance=race.FINISH_DISTANCE-1.0
	race._process(0.1)
	await process_frame
	print("RACE PHASE 8: verifying race finish")
	if main.screen!="race_result" or int(main.progress.data["race_totals"]["races"])!=old_races+1:
		_fail("Finish must show results and increment saved race count")
		return
	if main.progress.data["collected"]!=old_collected or main.progress.data["private_farm"]!=old_residents:
		_fail("Racing must never rewrite collections or farm residents")
		return
	var record: Dictionary=main.progress.data["race_records"].get("stag_beetle",{})
	if int(record.get("races",0))<1 or int(record.get("stars",0))<1:
		_fail("Played beetle's stars/trophies were not recorded")
		return
	var restored=Store.new()
	print("RACE PHASE 9: var restored=Store.new()")
	restored.load_save()
	if int(restored.data["race_totals"]["races"])!=old_races+1:
		_fail("Race statistics did not persist across restart")
		return
	main.show_private_farm()
	await process_frame
	if main.screen!="private_farm":
		_fail("Results cannot return to private farm")
		return
	main.progress.data=previous
	main.progress.save()
	print("PASS: farm entry, 7-insect shared roster, three tracks, swipe/buttons, AI, powerups, saved podium and return")
	main.queue_free()
	await process_frame
	quit(0)

func _fail(reason: String) -> void:
	push_error("RACE SMOKE FAILED: "+reason)
	quit(1)

func _readable_button(button: Button) -> bool:
	var normal_style: StyleBoxFlat=button.get_theme_stylebox("normal") as StyleBoxFlat
	if normal_style==null:
		return false
	return button.get_theme_color("font_color").get_luminance()<0.35 and normal_style.bg_color.get_luminance()>0.65
