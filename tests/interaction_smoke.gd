extends SceneTree
## Simulate a finger stroke and all four care actions in a real scene.
## Guard against recreating CareScene and replaying the welcome voice.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/Main.tscn")
	if scene == null:
		_fail("Main scene is missing")
		return
	var game: Control = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.show_animal("cow")
	await process_frame
	var pet: Control = game.petting_area
	if not is_instance_valid(pet) or pet.size.x < 200.0:
		_fail("Pettable animal does not have a correctly sized touch surface")
		return
	var center = pet.size * 0.5
	if not pet.begin_stroke(center):
		_fail("Finger press on the animal was ignored")
		return
	pet.move_stroke(center+Vector2(45,0))
	pet.move_stroke(center+Vector2(-45,0))
	if int(pet.strokes) != 1:
		_fail("Dragging across animal should trigger petting exactly once")
		return
	if str(pet.avatar.get("mood")) != "happy":
		_fail("The stroked animal did not react with a happy expression")
		return
	if not bool(pet.hand.show_hand) or not bool(pet.hand.celebrating):
		_fail("Visible hand and reaction hearts were not displayed")
		return
	pet.end_stroke()
	if pet.dragging:
		_fail("Finger drag did not end")
		return
	game.show_care("cow")
	await process_frame
	var stage: Control = game.care_stage
	if not is_instance_valid(stage):
		_fail("Care animation scene is missing")
		return
	var welcome_count = int(game.care_intro_count)
	if welcome_count != 1:
		_fail("Care page should greet exactly once on initial entry")
		return
	for action in ["feed","wash","play","sleep"]:
		var before: Dictionary = game.progress.care_stats("cow").duplicate(true)
		game._care_action(action)
		if not is_instance_valid(stage) or game.care_stage != stage:
			_fail(action+" rebuilt the care page")
			return
		if game.screen != "care" or int(game.care_intro_count) != welcome_count:
			_fail(action+" retriggered the welcome introduction")
			return
		if not bool(stage.animating):
			_fail(action+" did not start the animation")
			return
		if str(stage.action) != action:
			_fail(action+" played an incorrect animation")
			return
		var after: Dictionary = game.progress.care_stats("cow")
		var stat = {"feed":"food","wash":"clean","play":"happy","sleep":"happy"}[action]
		if int(after[stat]) <= int(before[stat]) and int(before[stat]) < 100:
			_fail(action+" did not change the animal care state")
			return
		await create_timer(1.95).timeout
		if bool(stage.animating):
			_fail(action+" animation did not end")
			return
		for b in game.care_action_buttons:
			if b.disabled:
				_fail("Care buttons remained disabled after "+action)
				return
	print("PASS: touch stroke follows hand, animal smiles, four care reactions persist and welcome is not replayed")
	game.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error("INTERACTION TEST FAILED: "+message)
	quit(1)
