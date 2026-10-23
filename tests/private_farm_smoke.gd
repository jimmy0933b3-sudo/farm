extends SceneTree
## A full UI flow for a preschooler's personal animal farm.
const ChoiceArt = preload("res://scripts/ChoiceArt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_home()
	await process_frame
	var has_icon=false
	for node in _descendants(game):
		if node.get_script()==ChoiceArt and str(node.get("item_id"))=="private_farm":
			has_icon=true
	if not has_icon:
		_fail("Independent Private Farm icon missing")
		return
	game._go("private_farm")
	await process_frame
	if game.screen!="private_farm" or not is_instance_valid(game.private_farm_game):
		_fail("Private Farm icon does not open a real interaction scene")
		return
	var farm=game.private_farm_game
	if not farm.active_id.is_empty() and not game.progress.data["private_farm"].has(farm.active_id):
		_fail("Uncollected animal entered private farm")
		return
	if game.progress.private_farm_add("made_up_species"):
		_fail("Should refuse to add species not in collected set")
		return
	var original: Array=game.progress.data["private_farm"].duplicate()
	for id in original:
		game.progress.private_farm_remove(str(id))
	game.progress.unlock("cow")
	game.progress.unlock("guinea_pig")
	game.progress.unlock("snake")
	farm._rebuild_cards()
	farm.place_animal("cow")
	if game.progress.data["private_farm"].count("cow")!=1:
		_fail("Placed animal should be saved exactly once")
		return
	farm.place_animal("cow")
	if game.progress.data["private_farm"].count("cow")!=1:
		_fail("Placing twice duplicated the animal")
		return
	farm.place_animal("guinea_pig")
	farm.place_animal("snake")
	if game.progress.data["private_farm"].size()!=3:
		_fail("Three distinct collected residents should be placed")
		return
	farm._set_resident("cow",false)
	await process_frame
	var pet=farm.pet
	if not is_instance_valid(pet) or pet.size.x<200:
		_fail("Private Farm has no usable touch petting area")
		return
	var center=pet.size*0.5
	if not pet.begin_stroke(center):
		_fail("A real finger touch in the animal area must start petting")
		return
	pet.move_stroke(center+Vector2(45,0))
	pet.move_stroke(center+Vector2(-45,0))
	if pet.strokes!=1:
		_fail("Finger stroke did not make the animal happy")
		return
	pet.end_stroke()
	var before=int(game.progress.care_stats("cow")["food"])
	farm.interact("feed")
	if not farm.busy or not is_instance_valid(farm.care):
		_fail("Feeding did not show an animal reaction")
		return
	if int(game.progress.care_stats("cow")["food"])<before:
		_fail("Feeding decreased food")
		return
	await create_timer(1.95).timeout
	if farm.busy:
		_fail("Care animation never finished")
		return
	game.show_home()
	await process_frame
	game.show_private_farm()
	await process_frame
	farm=game.private_farm_game
	for id in ["cow","guinea_pig","snake"]:
		if not game.progress.data["private_farm"].has(id):
			_fail("Farm resident did not survive page recreation")
			return
	farm._set_resident("snake",false)
	farm.remove_current()
	if game.progress.data["private_farm"].has("snake"):
		_fail("Removed animal should return to the collection")
		return
	if not game.progress.data["collected"].has("snake"):
		_fail("Removing from farm must never lose the collectible animal")
		return
	for id in ["cow","guinea_pig"]:
		game.progress.private_farm_remove(id)
	for id in original:
		game.progress.private_farm_add(str(id))
	print("PASS: farm icon, unlocked-only choices, persistent residents, drag-to-pet, action animation, remove and replay")
	game.queue_free()
	await process_frame
	quit(0)

func _descendants(node: Node) -> Array:
	var all: Array=[]
	for child in node.get_children():
		all.append(child)
		all.append_array(_descendants(child))
	return all

func _fail(message: String) -> void:
	push_error("PRIVATE FARM TEST FAILED: "+message)
	quit(1)
