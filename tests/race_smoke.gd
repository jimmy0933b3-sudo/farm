extends SceneTree
## Integration: Private Farm -> choose an actual animal/insect -> race -> saved results.
const Rules=preload("res://scripts/RaceRules.gd")
const Store=preload("res://scripts/SaveData.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main=load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var previous: Dictionary=main.progress.data.duplicate(true)
	main.progress.unlock("cow")
	main.progress.unlock("rhinoceros_beetle")
	main.progress.unlock("stag_beetle")
	main.progress.data["private_farm"]=["cow","rhinoceros_beetle","stag_beetle"]
	main.progress.save()
	main.show_private_farm()
	await process_frame
	var farm=main.private_farm_game
	if not farm.racing_requested.has_connections():
		_fail("Farm race icon not connected to parent navigation")
		return
	farm.racing_requested.emit()
	await process_frame
	if main.screen!="race_lobby":
		_fail("Farm entry button did not open kart lobby")
		return
	var lobby=main.race_lobby
	if lobby.options.size()!=3 or lobby.selected_id!="cow":
		_fail("Lobby must show the current farm residents")
		return
	lobby.choose_animal("stag_beetle")
	lobby.choose_track("flower")
	lobby.start()
	await process_frame
	if main.screen!="race_game":
		_fail("Cannot enter racing game")
		return
	var race=main.race_game
	if race.racer.get("id")!="stag_beetle" or race.race_track.get("id")!="flower":
		_fail("Chosen beetle or race track was lost")
		return
	if race.ai_karts.size()!=3 or race.player_kart==null:
		_fail("Three AI racers plus actual animal kart are required")
		return
	race.move_lane(-1)
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
	race.distance=race.FINISH_DISTANCE-1.0
	race._process(0.1)
	await process_frame
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
