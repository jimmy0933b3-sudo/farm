extends SceneTree
## Regression for mobile users: 8th farm slot accessible, full is not locked,
## farm scenery is ground-based and all selected residents can be removed.
const Landscape = preload("res://scripts/PrivateFarmLandscape.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_private_farm()
	await process_frame
	var farm=game.private_farm_game
	var existing: Array=game.progress.data["private_farm"].duplicate()
	for id in existing:
		game.progress.private_farm_remove(str(id))
	var ids: Array=[]
	for a in game.animals:
		if ids.size()<9:
			ids.append(str(a["id"]))
	for id in ids:
		game.progress.unlock(str(id))
	farm._sync_residents()
	farm._rebuild_cards()
	if farm.resident_list is ScrollContainer:
		_fail("Resident selector must not be a horizontal scrollbar")
		return
	if farm.resident_list.columns!=4:
		_fail("Resident selector must have four visible columns")
		return
	for i in range(8):
		var outcome=game.progress.private_farm_add_status(str(ids[i]),8)
		if outcome!="added":
			_fail("Failed to place an unlocked animal in slot %d: %s" % [i+1,outcome])
			return
	farm._sync_residents()
	farm._rebuild_cards()
	await process_frame
	if farm.resident_list.get_child_count()!=8:
		_fail("All 8 residents must have their own visible card")
		return
	var last_button=farm.resident_list.get_child(7)
	var last_rect: Rect2=last_button.get_global_rect()
	var first_rect: Rect2=farm.resident_list.get_child(0).get_global_rect()
	if last_rect.position.y <= first_rect.position.y:
		_fail("All 8 resident cards should occupy a 4x2 grid")
		return
	if last_rect.end.x>farm.resident_list.get_global_rect().end.x+2.0:
		_fail("8th resident button is clipped horizontally")
		return
	last_button.pressed.emit()
	if farm.active_id != str(ids[7]):
		_fail("8th animal cannot be selected")
		return
	if farm.remove_button.disabled:
		_fail("Remove button must be active when eighth resident selected")
		return
	# Reproduce the user's 9th animal report. It is collected, not locked.
	if game.progress.private_farm_add_status(str(ids[8]),8)!="full":
		_fail("Collected ninth animal must say farm full")
		return
	farm.place_animal(str(ids[8]))
	if not farm.info_label.text.contains("住滿"):
		_fail("Voice/label should explain 8-capacity, not lack of collection")
		return
	farm.remove_current()
	if game.progress.data["private_farm"].has(str(ids[7])):
		_fail("Removing the eighth animal had no effect")
		return
	farm.place_animal(str(ids[8]))
	if not game.progress.data["private_farm"].has(str(ids[8])):
		_fail("An open slot should now accept the ninth collected animal")
		return
	var landscape_count=0
	for node in farm.habitat.get_children():
		if node.get_script()==Landscape:
			landscape_count+=1
	if landscape_count!=1:
		_fail("Private Farm must use the new illustrated pastoral ground map")
		return
	for animal in farm.actors.values():
		var floor_y: float=animal.position.y+animal.size.y
		if floor_y<farm.habitat.size.y*0.62 or floor_y>farm.habitat.size.y+2.0:
			_fail("Animal appears off the farm's grassy ground")
			return
	for id in game.progress.data["private_farm"].duplicate():
		game.progress.private_farm_remove(str(id))
	for id in existing:
		game.progress.private_farm_add(str(id))
	print("PASS: grounded private farm, 4x2 selector, removable eighth animal, full-capacity voice and adding after removal")
	game.queue_free()
	await process_frame
	quit(0)

func _fail(msg: String) -> void:
	push_error("FARM CAPACITY / GROUND TEST FAILED: "+msg)
	quit(1)
