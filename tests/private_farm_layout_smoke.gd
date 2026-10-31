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
	if farm.get_child_count()!=2:
		_fail("Old two-part resident/available lists must be removed")
		return
	# The single roster row includes its counter, arrows, and the cards.
	# No secondary category/remove toolbar may steal room from the map.
	if farm.resident_scroll.get_parent().get_child_count()!=4:
		_fail("Farm roster should not have a separate remove-to-album toolbar")
		return
	var top_toolbar=farm.get_parent().get_child(0)
	if top_toolbar.get_child_count()!=5 or top_toolbar.get_child(1).text!="🌱 農田" or top_toolbar.get_child(2).text!="🏎️ 賽車場":
		_fail("Farm Garden/Racing buttons must be in the top toolbar without the title")
		return
	if farm.farm_view.is_ancestor_of(farm.info_label)==false:
		_fail("Farm feedback must overlay the world instead of taking a separate row")
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
	# Regression for the screenshot's overlapping controls and cut-off playfield.
	var stock_rect=farm.stock_strip.get_global_rect()
	var map_rect=farm.farm_view.get_global_rect()
	var action_rect=farm.commands.get_global_rect()
	if stock_rect.end.y>map_rect.position.y+2.0:
		_fail("Crop inventory overlaps the farm scenery")
		return
	if map_rect.end.y>action_rect.position.y+2.0:
		_fail("Farm scenery overlaps the bottom care controls")
		return
	if map_rect.size.y<190.0:
		_fail("Farm scenery became too short after stacking controls")
		return
	if action_rect.end.y>root.size.y+1.0:
		_fail("Bottom care controls overflow the landscape viewport")
		return
	farm._roster_jump("bird")
	await process_frame
	if farm.resident_scroll.scroll_horizontal<1000:
		_fail("Bird shortcut must jump forward inside the same animal roster")
		return
	farm._roster_jump("farm")
	await process_frame
	if farm.resident_scroll.scroll_horizontal>50:
		_fail("Farm shortcut must return to beginning of top roster")
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
	# Every resident must be visibly green, including pressed and hover states.
	# This catches the mixed green/yellow cards seen on the Android device.
	for id in ids:
		var card=farm.resident_cards[id]
		for state in ["normal","hover","pressed","hover_pressed"]:
			if not card.has_theme_stylebox_override(state):
				_fail("Resident card lacks explicit visual state: "+id+" / "+state)
				return
			var skin=card.get_theme_stylebox(state)
			if not skin is StyleBoxFlat or skin.bg_color.g<=skin.bg_color.r:
				_fail("Placed animal does not remain green: "+id+" / "+state)
				return
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
	var former_card=farm.resident_cards[removed_id]
	for state in ["normal","hover","pressed","hover_pressed"]:
		var old_skin=former_card.get_theme_stylebox(state)
		if not old_skin is StyleBoxFlat or old_skin.bg_color.g>=old_skin.bg_color.r:
			_fail("Returned animal card must switch back to beige: "+state)
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
	for state in ["normal","hover","pressed","hover_pressed"]:
		var green_skin=farm.resident_cards[removed_id].get_theme_stylebox(state)
		if not green_skin is StyleBoxFlat or green_skin.bg_color.g<=green_skin.bg_color.r:
			_fail("Re-placed animal did not turn green again: "+state)
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
