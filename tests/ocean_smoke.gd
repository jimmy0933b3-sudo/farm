extends SceneTree
const ChoiceArt=preload("res://scripts/ChoiceArt.gd")
const Swimming=preload("res://scripts/SwimmingAnimal.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_home()
	await process_frame
	var home_explore=false
	for node in _children(game):
		if node.get_script()==ChoiceArt and str(node.get("item_id"))=="ocean":
			home_explore=true
	if home_explore:
		_fail("Ocean search should be inside Ocean Park, not a separate home tile")
		return
	game._go("ocean_park")
	await process_frame
	var park_entry=false
	for node in _children(game):
		if node.get_script()==ChoiceArt and str(node.get("item_id"))=="ocean":
			park_entry=true
	if not park_entry:
		_fail("Ocean Park missing seek-and-find entrance")
		return
	game.show_ocean_search()
	await process_frame
	if game.screen!="ocean_search":
		_fail("Ocean icon did not open game")
		return
	var ocean=game.ocean_game
	if ocean.spots.size()!=7 or ocean.placement.size()!=7:
		_fail("Not exactly seven findable sea creatures")
		return
	ocean.stage.pan_by(530.0)
	if ocean.stage.camera_x<240.0:
		_fail("Ocean map cannot be swiped")
		return
	ocean.stage.pan_by(-530.0)
	var wrong=(ocean.target_spot()+1)%7
	ocean.attempt_spot(wrong)
	ocean.attempt_spot(wrong)
	if not ocean.spots[ocean.target_spot()].hint:
		_fail("Ocean hint not visible")
		return
	var first=ocean.current_target()
	ocean.attempt_spot(ocean.target_spot())
	if not game.progress.data["ocean_found"].has(first):
		_fail("Ocean find was not saved")
		return
	game.show_home()
	await process_frame
	game.show_ocean_search()
	await process_frame
	ocean=game.ocean_game
	if ocean.round_index!=1:
		_fail("Ocean session did not resume")
		return
	var previous=int(game.progress.data["ocean_explore_runs"])
	for n in range(1,7):
		ocean.attempt_spot(ocean.target_spot())
		await create_timer(1.73).timeout
	if game.screen!="ocean_done" or int(game.progress.data["ocean_explore_runs"])!=previous+1:
		_fail("Seven finds did not complete")
		return
	for id in ["clownfish","sea_turtle","dolphin","octopus","seahorse","pufferfish","seal"]:
		if not game.progress.data["collected"].has(id):
			_fail("Ocean species is not collected: "+id)
			return
	game.show_private_farm()
	await process_frame
	var farm=game.private_farm_game
	for resident in game.progress.data["private_farm"].duplicate():
		game.progress.private_farm_remove(str(resident))
	game.progress.unlock("cow")
	farm._sync_residents()
	farm._rebuild_cards()
	farm.place_animal("cow")
	farm.place_animal("clownfish")
	farm.place_animal("octopus")
	await process_frame
	await process_frame
	if farm.actors.size()!=3:
		_fail("Farm cannot hold land + ocean species")
		return
	if farm.actors["clownfish"].get_script()!=Swimming:
		_fail("Ocean fish is not swimming")
		return
	if farm.actors["octopus"].get_script()!=Swimming:
		_fail("Octopus is not swimming")
		return
	for id in farm.actors.keys():
		var actor=farm.actors[id]
		if str(farm._animal(str(id)).get("zone",""))=="ocean":
			if actor.roaming_bounds.position.x < farm.habitat.size.x*.61:
				_fail("Ocean swimmer left pond")
				return
		elif actor.roaming_bounds.end.x>farm.habitat.size.x*.59:
			_fail("Land animal reached water")
			return
	var swimmer=farm.actors["clownfish"]
	var point=swimmer.position+swimmer.size*0.5
	if not farm._start_touch(point):
		_fail("Cannot pet swimmer")
		return
	farm._move_touch(point+Vector2(23,0))
	farm._move_touch(point)
	if swimmer.strokes<1:
		_fail("Swimming petting reaction broken")
		return
	farm._finish_touch()
	game.show_coloring()
	await process_frame
	game.coloring_game.select_animal("clownfish",false)
	await process_frame
	if game.coloring_game.canvas.get_regions().size()<5:
		_fail("Sea creature coloring not possible")
		return
	print("PASS: ocean finds, resuming, collection, pond-only swimming, land separation and petting")
	game.queue_free()
	await process_frame
	quit(0)
func _children(node: Node) -> Array:
	var a: Array=[]
	for child in node.get_children():
		a.append(child)
		a.append_array(_children(child))
	return a
func _fail(message: String) -> void:
	push_error("OCEAN TEST FAILED: "+message)
	quit(1)
