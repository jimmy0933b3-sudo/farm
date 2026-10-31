extends SceneTree
## One top scroll strip for ALL 67 species: no separate resident/available rows.
## A tap places; a second tap returns the creature to the same exact card.
const Landscape=preload("res://scripts/PrivateFarmLandscape.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var saved=game.progress.data.duplicate(true)
	game.progress.data["private_farm"]=[]
	game.progress.save()
	game.show_private_farm()
	await process_frame
	await process_frame
	var farm=game.private_farm_game
	var ids: Array=game._all_friends().map(func(info): return str(info["id"]))
	if ids.size()!=67 or farm.animals.size()!=67 or farm.CAPACITY!=67:
		_fail("Private farm must include all 67 animals, birds and monsters")
		return
	if not farm.resident_list is HBoxContainer or farm.resident_list.get_child_count()!=67:
		_fail("Exactly one permanent, horizontal top roster with 67 cards is required")
		return
	if farm.available_list!=null or farm.available_scroll!=null:
		_fail("Old two-part resident/available lists must be removed")
		return
	if farm.resident_scroll.vertical_scroll_mode!=ScrollContainer.SCROLL_MODE_DISABLED or farm.resident_scroll.horizontal_scroll_mode!=ScrollContainer.SCROLL_MODE_AUTO:
		_fail("Top list must only scroll sideways")
		return
	if farm.resident_scroll.get_global_rect().position.y>=farm.farm_view.get_global_rect().position.y:
		_fail("Animal roster must be ABOVE the farm playground")
		return
	if farm.resident_scroll.get_h_scroll_bar().max_value<=farm.resident_scroll.size.x+300:
		_fail("Entire roster must be genuinely swipeable with a finger")
		return
	# Even uncollected birds and monsters belong to the selectable roster.
	for id in ["bird_mandarin","bird_owl_park","bird_eagle","bird_osprey","monster_fire","monster_rainbow"]:
		if not ids.has(id):
			_fail("Cross-park species missing: "+id)
			return
		if game.progress.private_farm_add_status(id)!="added":
			_fail("All catalogue species must be placeable without collection gating")
			return
	# Remove initial residents and fill the full farm with every species.
	game.progress.data["private_farm"]=[]
	for id in ids:
		var result=game.progress.private_farm_add_status(id)
		if result!="added":
			_fail("Cannot place full roster species "+id+": "+result)
			return
	if game.progress.private_farm_add_status("unknown_new_species")!="locked":
		_fail("Only 67 known IDs are allowed in the resident list")
		return
	farm._sync_residents()
	farm._rebuild_cards()
	await process_frame
	await process_frame
	if farm.actors.size()!=67 or farm.resident_list.get_child_count()!=67:
		_fail("All 67 species must roam and keep their top list cards")
		return
	for id in ids:
		if not farm.actors.has(id):
			_fail("Resident missing actor sprite "+id)
			return
	if not farm.actors["bird_eagle"].is_flying:
		_fail("Bird species should fly rather than crawl in private farm")
		return
	var first_card=farm.resident_list.get_child(0)
	var last_card=farm.resident_list.get_child(66)
	if last_card.get_global_rect().position.x<=first_card.get_global_rect().position.x+3000:
		_fail("Single roster must span horizontally instead of creating rows")
		return
	farm.resident_scroll.scroll_horizontal=999999
	await process_frame
	if farm.resident_scroll.scroll_horizontal<=300:
		_fail("Cannot swipe to last species")
		return
	var offset=farm.resident_scroll.scroll_horizontal
	var removed_id=str(ids[66])
	# Tapping a resident tile returns that animal, but keeps its tile in place.
	last_card.pressed.emit()
	await process_frame
	await process_frame
	if game.progress.data["private_farm"].has(removed_id) or farm.actors.has(removed_id):
		_fail("Tap on resident picture must return that animal")
		return
	if farm.resident_list.get_child_count()!=67 or farm.resident_scroll.scroll_horizontal<offset-100:
		_fail("Returned animal must stay in its original top card without scroll reset")
		return
	# Clicking the same tile again immediately places the animal back.
	farm.resident_list.get_child(66).pressed.emit()
	await process_frame
	if not game.progress.data["private_farm"].has(removed_id) or farm.resident_list.get_child_count()!=67:
		_fail("Returned creature must remain accessible for immediate re-placement")
		return
	if game.progress.data["private_farm"].size()!=67:
		_fail("All 67 residents should be placeable simultaneously")
		return
	for key in farm.actors:
		var animal=farm.actors[key]
		if animal.position.x<0.0 or animal.position.x+animal.size.x>farm.world_width+2.0:
			_fail("One or more of 67 residents escaped the extended farm")
			return
	var bg_count=0
	for item in farm.habitat.get_children():
		if item.get_script()==Landscape:
			bg_count+=1
	if bg_count!=1:
		_fail("Expanded farm must retain one original landscape")
		return
	game.progress.data=saved
	game.progress.save()
	print("PASS: all 67 species in one thumb-scrollable top roster, 67 simultaneous actors, last card remove/re-add without disappearing or losing scroll, birds fly")
	game.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error("PRIVATE FARM ALL SPECIES FAILED: "+message)
	quit(1)
