extends SceneTree
## Long panoramic farm. Empty-ground drags move the world; animal touches
## never pan. Preserve the original 8 residents and 2 separate habitats.
const Swimming=preload("res://scripts/SwimmingAnimal.gd")
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.progress.unlock("cow")
	game.progress.unlock("seal")
	game.show_private_farm()
	await process_frame
	await process_frame
	var farm=game.private_farm_game
	if not is_instance_valid(farm.farm_view) or not is_instance_valid(farm.habitat):
		_fail("Farm must have a clipped viewport plus a larger world")
		return
	if farm.world_width<1550.0 or farm.habitat.size.x<farm.farm_view.size.x*1.8:
		_fail("New farm is not sufficiently wide to explore")
		return
	if not farm.farm_view.clip_contents:
		_fail("Scenery spills outside private farm viewport")
		return
	var initial=farm.camera_x
	farm._begin_world_gesture(Vector2(230,20))
	farm._drag_world_gesture(Vector2(40,20))
	farm._finish_touch()
	if farm.camera_x<initial+150:
		_fail("Dragging blank sky LEFT did not pan camera RIGHT")
		return
	var right_edge=farm.world_width-farm.farm_view.size.x
	farm.pan_by(9000)
	if absf(farm.camera_x-right_edge)>1:
		_fail("Cannot reach rightmost pond")
		return
	farm.pan_by(-9000)
	if farm.camera_x>1:
		_fail("Camera cannot return to the first meadow")
		return
	var original=game.progress.data["private_farm"].duplicate()
	for id in original:
		game.progress.private_farm_remove(str(id))
	farm._sync_residents()
	farm._rebuild_cards()
	farm.place_animal("cow")
	farm.place_animal("seal")
	await process_frame
	await process_frame
	var cow=farm.actors.get("cow")
	var seal=farm.actors.get("seal")
	if not is_instance_valid(cow) or not is_instance_valid(seal) or seal.get_script()!=Swimming:
		_fail("Old grass and sea animals cannot coexist in larger farm")
		return
	if cow.roaming_bounds.end.x>farm.world_width*.55 or seal.roaming_bounds.position.x<farm.world_width*.62:
		_fail("Grass/water animal bounds overlap")
		return
	farm.focus_resident("cow")
	var before=farm.camera_x
	var center=cow.position+cow.size*.5-Vector2(farm.camera_x,0)
	farm._begin_world_gesture(center)
	if farm.touching_id!="cow":
		_fail("Direct touch no longer selects resident in panned world")
		return
	farm._drag_world_gesture(center+Vector2(25,0))
	farm._drag_world_gesture(center)
	if cow.strokes<1:
		_fail("Stroking animal no longer creates joyful reaction")
		return
	if absf(farm.camera_x-before)>1:
		_fail("Petting a moving animal must NOT pan the farm")
		return
	farm._finish_touch()
	farm.focus_resident("seal")
	if farm.camera_x<300:
		_fail("Selecting sea animal should bring right-side pond into view")
		return
	for id in game.progress.data["private_farm"].duplicate():
		game.progress.private_farm_remove(str(id))
	for id in original:
		game.progress.private_farm_add(str(id))
	print("PASS: long panning farm, camera clamps, grass/pond separation, select and pet through camera")
	game.queue_free()
	await process_frame
	quit(0)
func _fail(why: String) -> void:
	push_error("FARM PAN TEST FAILED: "+why)
	quit(1)
