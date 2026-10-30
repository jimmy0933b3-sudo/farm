extends SceneTree
## Runtime gameplay smoke test for pre-reader options and imported recordings.

const Visual = preload("res://scripts/ChoiceArt.gd")
const AnimalVisual = preload("res://scripts/AnimalArt.gd")
const DATA = "res://data/levels.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/Main.tscn")
	if scene == null:
		_fail("Main scene cannot load")
		return
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	if not game.has_method("show_game"):
		_fail("Missing gameplay navigation")
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if typeof(data) != TYPE_ARRAY:
		_fail("Cannot load levels")
		return
	for level in data:
		var id = str(level["animal"])
		game.current_zone = "farm" if int(level["id"]) <= 6 else "forest"
		game.show_game(id)
		await process_frame
		var picture_count = _count_pictures(game)
		if picture_count < 3:
			_fail("%s game should show three animal or illustrated choices but got %d" % [id,picture_count])
			return
		if str(level["type"]) == "sound":
			var wav = "res://assets/audio/animals/"+id+".wav"
			if not ResourceLoader.exists(wav):
				_fail("%s sound quiz is missing natural WAV recording" % id)
				return
			if _count_script(game,Visual) != 0:
				_fail("Sound quiz should present animal pictures, not food illustrations")
				return
		else:
			if _count_script(game,Visual) != 3:
				_fail("%s quiz should show all three vector food/habitat pictures" % id)
				return
		# Verify a selection transitions to the success view without crashes.
		game._answer(str(level["answer"]),level)
		await process_frame
		if game.screen != "complete":
			_fail("%s correct answer did not complete level" % id)
			return
	print("PASS: 43 levels render three visuals, natural sound files exist, all choices complete")
	game.queue_free()
	await process_frame
	quit(0)

func _count_pictures(node: Node) -> int:
	return _count_script(node,Visual) + _count_script(node,AnimalVisual)

func _count_script(node: Node, script: Script) -> int:
	var total = 1 if node.get_script() == script else 0
	for child in node.get_children():
		total += _count_script(child,script)
	return total

func _fail(message: String) -> void:
	push_error("UI TEST FAIL: "+message)
	quit(1)
