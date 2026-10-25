extends SceneTree
## Insect adventure: six targets, swiping, helpful hint, resume and reshuffle.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var store=game.progress
	var saved=store.data.duplicate(true)
	store.data["insect_explore_session"]={}
	store.data["insect_explore_previous"]=[]
	store.data["insect_explore_runs"]=0
	store.data["insect_found"]=[]
	game.show_insect_search()
	await process_frame
	var bug=game.insect_game
	var ids=["rhinoceros_beetle","stag_beetle","butterfly","ladybug","bee","mantis"]
	if bug.spots.size()!=6 or bug.placement.size()!=6:
		_fail("Six insect hiding places missing")
		return
	for id in ids:
		if bug.placement.count(id)!=1:
			_fail("Missing/repeated insect "+id)
			return
	if bug.stage.WORLD_WIDTH<bug.stage.size.x*1.5:
		_fail("Garden is not panoramic")
		return
	bug.stage.pan_by(390.0)
	if bug.stage.camera_x<240.0:
		_fail("Insect map did not pan")
		return
	bug.stage.pan_by(-390.0)
	var wrong=(bug.target_spot()+1)%6
	bug.attempt_spot(wrong)
	bug.attempt_spot(wrong)
	if not bug.spots[bug.target_spot()].hint:
		_fail("Second wrong tap should show a friendly hint")
		return
	var first=bug.current_target()
	bug.attempt_spot(bug.target_spot())
	if not store.data["insect_found"].has(first) or not store.data["collected"].has(first):
		_fail("Found insect missing from shared collection")
		return
	var new_store=load("res://scripts/SaveData.gd").new()
	new_store.load_save()
	if not new_store.data["insect_explore_session"]["found"].has(first):
		_fail("In-progress insect discovery missing after save reload")
		return
	game.show_zone("insect")
	await process_frame
	game.show_insect_search()
	await process_frame
	bug=game.insect_game
	if bug.round_index!=1 or bug.found.size()!=1:
		_fail("Leaving the garden did not preserve insect search")
		return
	var old_placement=bug.placement.duplicate()
	for i in range(1,6):
		bug.attempt_spot(bug.target_spot())
		await create_timer(1.76).timeout
	if game.screen!="insect_done":
		_fail("Six insects did not complete game")
		return
	for id in ids:
		if not store.data["collected"].has(id):
			_fail("Insect not unlocked in animal album: "+id)
			return
	if int(store.data["insect_explore_runs"])!=1:
		_fail("Run count not persisted")
		return
	game.show_insect_search()
	await process_frame
	bug=game.insect_game
	if bug.round_index!=0 or bug.placement==old_placement:
		_fail("New game must restart and reshuffle hiding spots")
		return
	game.show_zone("insect")
	if game.screen!="insect":
		_fail("Insect completion must return to insect park")
		return
	store.data=saved
	store.save()
	print("PASS: six insect targets, panoramic drag, hint, collection, resume, replay and navigation")
	game.queue_free()
	await process_frame
	quit(0)
func _fail(reason: String) -> void:
	push_error("INSECT SEARCH FAILED: "+reason)
	quit(1)
