extends SceneTree
## Verify real multi-animal motion, tap/swipe on a small moving resident,
## care interaction, unlock-only membership and persistence after reopening.
const ChoiceArt = preload("res://scripts/ChoiceArt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_home()
	await process_frame
	var found=false
	for child in _descendants(game):
		if child.get_script()==ChoiceArt and str(child.get("item_id"))=="private_farm":
			found=true
	if not found:
		_fail("Missing separate Private Farm home picture icon")
		return
	game._go("private_farm")
	await process_frame
	var farm=game.private_farm_game
	if game.screen!="private_farm" or not is_instance_valid(farm):
		_fail("Private farm is not playable")
		return
	if game.progress.private_farm_add("made_up_species"):
		_fail("Locked or unknown species must not be allowed")
		return
	var original: Array=game.progress.data["private_farm"].duplicate()
	for id in original:
		game.progress.private_farm_remove(str(id))
	game.progress.unlock("cow")
	game.progress.unlock("guinea_pig")
	game.progress.unlock("snake")
	farm._sync_residents()
	farm._rebuild_cards()
	for id in ["cow","guinea_pig","snake"]:
		farm.place_animal(id)
	await process_frame
	if farm.actors.size()!=3:
		_fail("Farm must render three animals roaming simultaneously")
		return
	if game.progress.data["private_farm"].size()!=3:
		_fail("Farm resident choices were not saved")
		return
	for creature in farm.actors.values():
		if creature.size.x >= 155 or creature.size.y >= 155:
			_fail("Free-roaming animal should be small, not full screen")
			return
	var cow=farm.actors["cow"]
	cow.idle_timer=0.0
	cow.destination=cow.position+Vector2(65,0)
	var before: Vector2=cow.position
	cow._process(0.55)
	if before.distance_to(cow.position)<1.0:
		_fail("Farm residents should independently walk without a button")
		return
	var point: Vector2=cow.position+cow.size*0.5
	if not farm._start_touch(point):
		_fail("Touching the animal itself must select it")
		return
	if farm.active_id!="cow" or farm.touching_id!="cow":
		_fail("Touching a roaming cow should select the cow")
		return
	farm._move_touch(point+Vector2(23,0))
	farm._move_touch(point)
	if int(cow.strokes)!=1 or farm.pet_feedback_count<1:
		_fail("Direct stroking should trigger happy petting reaction")
		return
	if not bool(farm.hand.show_hand):
		_fail("Touchable animated hand must track direct petting")
		return
	farm._finish_touch()
	if not farm.touching_id.is_empty() or farm.hand.show_hand:
		_fail("Gesture capture must end on touch release")
		return
	var before_food=int(game.progress.care_stats("cow")["food"])
	farm.interact("feed")
	if farm.busy or cow.reaction_action=="feed" or int(game.progress.care_stats("cow")["food"])!=before_food:
		_fail("General feeding must no longer be available through care commands")
		return
	for button in farm.commands.get_children():
		if "餵" in button.text or "feed" in button.text:
			_fail("Old regular feeding and popup buttons must be removed")
			return
	farm.interact("wash")
	if not farm.busy or cow.reaction_action!="wash":
		_fail("Remaining care actions must still work without feeding button")
		return
	await create_timer(1.85).timeout
	if farm.busy:
		_fail("Animal should resume wandering after care reaction")
		return
	game.show_home()
	await process_frame
	game.show_private_farm()
	await process_frame
	farm=game.private_farm_game
	for id in ["cow","guinea_pig","snake"]:
		if not farm.actors.has(id):
			_fail("Saved roaming farm resident disappeared after navigation: "+id)
			return
	farm._set_resident("snake",false)
	farm.remove_current()
	if farm.actors.has("snake") or game.progress.data["private_farm"].has("snake"):
		_fail("Removed snake should leave the private farm")
		return
	if not game.progress.data["collected"].has("snake"):
		_fail("Removing a resident must not erase its unlocked sticker")
		return
	for id in ["cow","guinea_pig"]:
		game.progress.private_farm_remove(id)
	for id in original:
		game.progress.private_farm_add(str(id))
	print("PASS: multi-resident roaming, petting, no general feed button, preserved wash care and persistence")
	game.queue_free()
	await process_frame
	quit(0)

func _descendants(node: Node) -> Array:
	var nodes: Array=[]
	for child in node.get_children():
		nodes.append(child)
		nodes.append_array(_descendants(child))
	return nodes

func _fail(reason: String) -> void:
	push_error("PRIVATE FARM TEST FAILED: "+reason)
	quit(1)
