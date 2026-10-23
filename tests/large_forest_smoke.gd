extends SceneTree
## Verifies the independent home icon, wide pannable world and resume.
const ChoiceArt = preload("res://scripts/ChoiceArt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_home()
	await process_frame
	var home_explore=false
	for child in _descendants(game):
		if child.get_script() == ChoiceArt and str(child.get("item_id"))=="forest_explore":
			home_explore=true
	if home_explore:
		_fail("Large forest should be nested inside Forest Park, not another home icon")
		return
	game._go("forest")
	await process_frame
	var inner_explore=false
	for child in _descendants(game):
		if child.get_script()==ChoiceArt and str(child.get("item_id"))=="forest_explore":
			inner_explore=true
	if not inner_explore:
		_fail("Forest Park missing illustrated large-forest discovery entry")
		return
	game.show_forest_search()
	await process_frame
	if game.screen!="forest_search" or not is_instance_valid(game.forest_game):
		_fail("Forest home icon did not directly launch the game")
		return
	var seek=game.forest_game
	var map=seek.stage
	if map.WORLD_WIDTH <= map.size.x*1.7:
		_fail("Forest world must be substantially wider than the viewport")
		return
	if seek.spots.size()!=12 or seek.placement.size()!=12:
		_fail("Six real hideouts must appear in the large map")
		return
	var initial: float=map.camera_x
	map.pan_by(620.0)
	if map.camera_x <= initial+200.0:
		_fail("Map did not pan horizontally")
		return
	map.pan_by(-620.0)
	if map.camera_x > 2.0:
		_fail("Map cannot return to the start")
		return
	var wrong=(seek.target_spot()+1)%6
	seek.attempt_spot(wrong)
	seek.attempt_spot(wrong)
	if not seek.spots[seek.target_spot()].hint:
		_fail("Second missed location should show a picture hint")
		return
	var id=seek.current_target()
	seek.attempt_spot(seek.target_spot())
	if not game.progress.data["forest_found"].has(id):
		_fail("Discovery not persisted")
		return
	game.show_home()
	await process_frame
	game.show_zone("forest")
	await process_frame
	game.show_forest_search()
	await process_frame
	seek=game.forest_game
	if seek.round_index!=1 or seek.found.size()!=1:
		_fail("Unfinished forest adventure did not resume")
		return
	if not seek.spots[seek.placement.find(id)].revealed:
		_fail("Previously discovered animal not visible on resumed map")
		return
	var previous_runs=int(game.progress.data["forest_explore_runs"])
	for current in range(1,12):
		seek.attempt_spot(seek.target_spot())
		await create_timer(1.73).timeout
	if game.screen!="forest_done":
		_fail("Twelve discoveries did not finish the adventure")
		return
	if int(game.progress.data["forest_explore_runs"])!=previous_runs+1:
		_fail("Completed run count not saved")
		return
	game.show_forest_search()
	await process_frame
	seek=game.forest_game
	if seek.round_index!=0 or seek.found.size()!=0:
		_fail("Replay should generate a fresh session")
		return
	print("PASS: large map, nested Forest Park discovery, panning, hints, persisted resume, 12 finds and replay")
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
	push_error("LARGE FOREST TEST FAILED: "+message)
	quit(1)
