extends SceneTree
## Zoo seek-and-find end to end: tap/drag, wrong-answer hint, autosave,
## reuse shared forest monkey, resume and replay a shuffled six-animal tour.
const ChoiceArt=preload("res://scripts/ChoiceArt.gd")
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_home()
	await process_frame
	for n in _children(game):
		if n.get_script()==ChoiceArt and str(n.get("item_id"))=="zoo_search":
			_fail("Zoo find-animal belongs INSIDE zoo park, not home")
			return
	game._go("zoo")
	await process_frame
	if game.screen!="zoo":
		_fail("Zoo Park is not available from home")
		return
	var has_seek=false
	for n in _children(game):
		if n.get_script()==ChoiceArt and str(n.get("item_id"))=="zoo_search":
			has_seek=true
	if not has_seek:
		_fail("Zoo Park must show a colorful find-animal entrance")
		return
	game.show_zoo_search()
	await process_frame
	if game.screen!="zoo_search" or not is_instance_valid(game.zoo_game):
		_fail("Zoo exploration did not open")
		return
	var zoo=game.zoo_game
	var order=["camel","lion","tiger","elephant","monkey","hippo"]
	if zoo.spots.size()!=6 or zoo.placement.size()!=6:
		_fail("Zoo map does not have exactly six hiding places")
		return
	for species in order:
		if zoo.placement.count(species)!=1:
			_fail("Zoo map contains missing or repeated species: "+species)
			return
	if zoo.stage.WORLD_WIDTH<=zoo.stage.size.x*1.5:
		_fail("Zoo map is not wider than its viewport")
		return
	zoo.stage.pan_by(410.0)
	if zoo.stage.camera_x<250.0:
		_fail("Zoo map must pan with child's finger")
		return
	zoo.stage.pan_by(-410.0)
	var bad=(zoo.target_spot()+1)%6
	zoo.attempt_spot(bad)
	zoo.attempt_spot(bad)
	if not zoo.spots[zoo.target_spot()].hint:
		_fail("Two missed hiding places should show a visible hint")
		return
	var first=zoo.current_target()
	zoo.attempt_spot(zoo.target_spot())
	if not game.progress.data["zoo_found"].has(first):
		_fail("Discovered zoo animal not added to saved list")
		return
	if not game.progress.data["collected"].has(first):
		_fail("Discovered zoo animal not unlocked in shared sticker book")
		return
	game.show_zone("zoo")
	await process_frame
	game.show_zoo_search()
	await process_frame
	zoo=game.zoo_game
	if zoo.round_index!=1 or zoo.found.size()!=1:
		_fail("Interrupted zoo session did not resume with previous find")
		return
	var old_runs=int(game.progress.data["zoo_explore_runs"])
	for idx in range(1,6):
		zoo.attempt_spot(zoo.target_spot())
		await create_timer(1.75).timeout
	if game.screen!="zoo_done":
		_fail("Zoo search did not reach completed screen after six finds")
		return
	if int(game.progress.data["zoo_explore_runs"])!=old_runs+1:
		_fail("Completed zoo exploration was not saved")
		return
	for id in order:
		if not game.progress.data["collected"].has(id):
			_fail("Zoo animals must be playable in album and coloring: "+id)
			return
	if game.progress.data["collected"].count("monkey")!=1:
		_fail("Shared forest and zoo monkey was duplicated in collection")
		return
	game.show_zoo_search()
	await process_frame
	if game.zoo_game.round_index!=0 or game.zoo_game.spots.size()!=6:
		_fail("Zoo search cannot be replayed after finishing")
		return
	print("PASS: zoo find six, inside park, swipe, hint, autosave, resume, shared monkey, completion and replay")
	game.queue_free()
	await process_frame
	quit(0)

func _children(node: Node) -> Array:
	var result: Array=[]
	for child in node.get_children():
		result.append(child)
		result.append_array(_children(child))
	return result

func _fail(msg: String) -> void:
	push_error("ZOO SEARCH TEST FAILED: "+msg)
	quit(1)
