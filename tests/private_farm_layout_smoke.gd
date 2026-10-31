extends SceneTree
## Verify a full 32-resident private farm with a scrollable four-column card
## grid. The seventeenth collected species must say FULL, never LOCKED.
const Landscape=preload("res://scripts/PrivateFarmLandscape.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_private_farm()
	await process_frame
	await process_frame
	var farm=game.private_farm_game
	var existing: Array=game.progress.data["private_farm"].duplicate()
	var collected: Array=game.progress.data["collected"].duplicate()
	for resident in existing:
		game.progress.private_farm_remove(str(resident))
	var ids: Array=[]
	for animal in game.animals:
		if ids.size()<33:
			ids.append(str(animal["id"]))
	for id in ids:
		game.progress.unlock(str(id))
	farm._sync_residents()
	farm._rebuild_cards()
	if farm.CAPACITY!=32:
		_fail("Private Farm still uses an eight-resident cap")
		return
	if not is_instance_valid(farm.resident_scroll):
		_fail("Thirty-two residents require a vertical list")
		return
	if farm.resident_scroll.horizontal_scroll_mode!=ScrollContainer.SCROLL_MODE_DISABLED:
		_fail("Residents should scroll up and down, not sideways")
		return
	if farm.resident_list.columns!=4:
		_fail("Resident selection must have four columns")
		return
	for i in range(32):
		var outcome=game.progress.private_farm_add_status(str(ids[i]))
		if outcome!="added":
			_fail("Collected resident %d was refused: %s" % [i+1,outcome])
			return
	if game.progress.private_farm_add_status(str(ids[32]))!="full":
		_fail("Collected thirty-third resident should report FULL")
		return
	farm._sync_residents()
	farm._rebuild_cards()
	await process_frame
	await process_frame
	if farm.actors.size()!=32 or farm.resident_list.get_child_count()!=32:
		_fail("All thirty-two residents must be shown and moving")
		return
	var first=farm.resident_list.get_child(0)
	var last=farm.resident_list.get_child(31)
	if last.get_global_rect().position.y<=first.get_global_rect().position.y+first.size.y*6:
		_fail("Eight resident rows are not present")
		return
	if farm.resident_scroll.get_v_scroll_bar().max_value<=farm.resident_scroll.size.y+30:
		_fail("Last resident rows cannot be scrolled into view")
		return
	farm.resident_scroll.scroll_vertical=10000
	await process_frame
	if farm.resident_scroll.scroll_vertical<70:
		_fail("Finger scroll cannot reach the last resident row")
		return
	if last.get_global_rect().end.x>farm.resident_scroll.get_global_rect().end.x+2.0:
		_fail("The thirty-second resident card is clipped horizontally")
		return
	last.pressed.emit()
	if farm.active_id!=str(ids[31]):
		_fail("The thirty-second resident cannot be selected from the card")
		return
	if farm.remove_button.disabled:
		_fail("Remove button disabled for thirty-second resident")
		return
	farm.place_animal(str(ids[32]))
	if not farm.info_label.text.contains("32") or not farm.info_label.text.contains("住滿"):
		_fail("Capacity feedback still says eight animals or incorrectly says locked")
		return
	farm.remove_current()
	if game.progress.data["private_farm"].has(str(ids[31])):
		_fail("The thirty-second resident did not return to album")
		return
	farm.place_animal(str(ids[32]))
	if not game.progress.data["private_farm"].has(str(ids[32])):
		_fail("The thirty-third species cannot occupy a newly emptied slot")
		return
	var n_land=0
	for key in farm.actors.keys():
		var animal=farm.actors[key]
		if animal.position.x<0.0 or animal.position.x+animal.size.x>farm.world_width+2.0:
			_fail("A resident is outside the large farm")
			return
		if str(farm._animal(str(key)).get("zone",""))!="ocean":
			n_land+=1
			if animal.roaming_bounds.position.x>farm.world_width*0.6:
				_fail("Land animal incorrectly placed in water")
				return
	if n_land<20:
		_fail("Insufficient land residents for crowded meadow stress test")
		return
	var bg_count=0
	for item in farm.habitat.get_children():
		if item.get_script()==Landscape:
			bg_count+=1
	if bg_count!=1:
		_fail("Illustrated large farm landscape missing")
		return
	# The test must not change the player's original collected or farm data.
	for id in game.progress.data["private_farm"].duplicate():
		game.progress.private_farm_remove(str(id))
	for id in existing:
		game.progress.private_farm_add(str(id))
	game.progress.data["collected"]=collected
	game.progress.save()
	print("PASS: thirty-two farm residents, 4x8 vertically scrollable cards, #33 full, slot replacement and grass bounds")
	game.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error("FARM 32 RESIDENT TEST FAILED: "+message)
	quit(1)
