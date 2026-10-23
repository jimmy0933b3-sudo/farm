extends RefCounted
## Pure data access. Scenes and levels are configured in JSON for future expansion.

static func read_array(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing game data: " + path)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Invalid array: " + path)
		return []
	return parsed

static func get_animal(animals: Array, animal_id: String) -> Dictionary:
	for entry in animals:
		if str(entry.get("id", "")) == animal_id:
			return entry
	return {}

static func get_level(levels: Array, animal_id: String) -> Dictionary:
	for entry in levels:
		if str(entry.get("animal", "")) == animal_id:
			return entry
	return {}
