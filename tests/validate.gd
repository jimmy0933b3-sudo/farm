extends SceneTree

func _initialize() -> void:
	var a = _read("res://data/animals.json")
	var l = _read("res://data/levels.json")
	if a.size() != 16 or l.size() != 16:
		push_error("Expected exactly 12 animals and 12 levels")
		quit(1)
		return
	var known = {}
	var farm_count = 0
	var forest_count = 0
	var care_count = 0
	for animal in a:
		var id = str(animal.get("id",""))
		if id.is_empty() or known.has(id):
			push_error("Invalid or duplicate animal ID: "+id)
			quit(1)
			return
		known[id] = animal
		if animal.get("zone") == "farm":
			farm_count += 1
		if animal.get("zone") == "forest":
			forest_count += 1
		if bool(animal.get("care",false)):
			care_count += 1
	if farm_count != 6 or forest_count != 10 or care_count != 6:
		push_error("Expected 6 farm + 10 forest + 6 care animals")
		quit(1)
		return
	for level in l:
		var id = str(level.get("animal",""))
		if not known.has(id):
			push_error("Level references missing animal: "+id)
			quit(1)
			return
		var answer = level.get("answer")
		var options = level.get("options",[])
		if not options.has(answer) or options.size() < 2:
			push_error("Level missing valid options/answer: "+str(level.get("id")))
			quit(1)
			return
	print("PASS: 16 animals, 16 valid levels, 2 habitats and 6 care animals")
	quit(0)

func _read(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var value = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(value) == TYPE_ARRAY:
		return value
	return []
