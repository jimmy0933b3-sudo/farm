extends SceneTree
## End-to-end forest treasure hunt without requiring Android device touches.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/Main.tscn")
	if scene == null:
		_fail("Main scene missing")
		return
	var game: Control=scene.instantiate()
	root.add_child(game)
	await process_frame
	game.show_zone("forest")
	await process_frame
	var entry_found=false
	for node in _all_children(game):
		if node is Button and str(node.text) == "":
			# Illustrated, blank-title button with ChoiceArt forest_explore.
			if _has_seek_picture(node):
				entry_found=true
	if not entry_found:
		_fail("Forest game entry button missing from forest zone")
		return
	game.show_forest_search()
	await process_frame
	var seek: Control=game.forest_game
	if not is_instance_valid(seek) or game.screen!="forest_search":
		_fail("Forest search screen didn't open")
		return
	if seek.spots.size()!=10 or seek.placement.size()!=10:
		_fail("Missing forest hideouts for 10 animals")
		return
	if seek.stage.size.x < 400 or seek.stage.size.y < 190:
		_fail("Forest interactive stage below acceptable 190px touch height")
		return
	if seek.current_target() != "rabbit":
		_fail("Unexpected first animal")
		return
	if seek.target_spot()<0:
		_fail("Rabbit is not hidden anywhere")
		return
	var wrong=(seek.target_spot()+1)%6
	seek.attempt_spot(wrong)
	if seek.round_index!=0 or seek.found.size()!=0:
		_fail("Wrong choice advanced round")
		return
	seek.attempt_spot(wrong)
	if not seek.spots[seek.target_spot()].hint:
		_fail("Two wrong attempts didn't reveal visual hint")
		return
	for round in range(10):
		var target=seek.current_target()
		var slot=seek.target_spot()
		if slot<0 or seek.spots[slot].revealed:
			_fail("Target doesn't have a hidden location: "+target)
			return
		seek.attempt_spot(slot)
		if not seek.spots[slot].revealed:
			_fail("Animal didn't appear after touch")
			return
		if not game.progress.data["forest_found"].has(target):
			_fail("Found animal wasn't persisted: "+target)
			return
		if not game.progress.data["collected"].has(target):
			_fail("Animal sticker wasn't unlocked: "+target)
			return
		await create_timer(1.75).timeout
	if game.screen!="forest_done":
		_fail("All ten animals were found but completion screen is missing")
		return
	game.show_forest_search()
	await process_frame
	seek=game.forest_game
	if seek.round_index!=0 or seek.found.size()!=0:
		_fail("Replay did not reset the current session")
		return
	if seek.placement.size()!=10:
		_fail("Replay lost a hideout")
		return
	print("PASS: forest entry, ten hideouts, hints, discovery, saved progress, completion, replay")
	game.queue_free()
	await process_frame
	quit(0)

func _all_children(node: Node) -> Array:
	var result: Array=[]
	for child in node.get_children():
		result.append(child)
		result.append_array(_all_children(child))
	return result

func _has_seek_picture(node: Node) -> bool:
	for child in _all_children(node):
		if child.get_script()!=null and str(child.get("item_id"))=="forest_explore":
			return true
	return false

func _fail(message: String) -> void:
	push_error("FOREST DISCOVERY TEST FAILED: "+message)
	quit(1)
