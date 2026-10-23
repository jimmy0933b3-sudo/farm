extends RefCounted
## Versioned, fail-safe local persistence. Offline time never decays pets.

const PATH = "user://animal_island_save.json"
const BAK = "user://animal_island_save.bak"
const TEMP = "user://animal_island_save.tmp"

var data: Dictionary = {}

func _fresh() -> Dictionary:
	return {
		"schema_version": 1,
		"collected": [],
		"completed": [],
		"forest_found": [],
		"care": {},
		"settings": {"music": true, "sound": true, "speech": true, "reduce_motion": false},
		"last_screen": "home"
	}

func load_save() -> void:
	data = _fresh()
	var result = _read(PATH)
	if result.is_empty():
		result = _read(BAK)
	if result.is_empty():
		return
	for key in data.keys():
		if result.has(key) and typeof(result[key]) == typeof(data[key]):
			data[key] = result[key]
	if int(data.get("schema_version", 0)) != 1:
		data["schema_version"] = 1

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	if typeof(parsed.get("collected", null)) != TYPE_ARRAY:
		return {}
	if typeof(parsed.get("care", null)) != TYPE_DICTIONARY:
		return {}
	return parsed

func save() -> void:
	var file = FileAccess.open(TEMP, FileAccess.WRITE)
	if file == null:
		push_error("Unable to open temporary save file")
		return
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if _read(TEMP).is_empty():
		push_error("Save verification failed")
		return
	var old_path = ProjectSettings.globalize_path(PATH)
	var new_path = ProjectSettings.globalize_path(TEMP)
	if FileAccess.file_exists(PATH):
		DirAccess.copy_absolute(old_path, ProjectSettings.globalize_path(BAK))
	var err = DirAccess.rename_absolute(new_path, old_path)
	if err != OK:
		push_error("Could not commit save: " + str(err))

func unlock(animal_id: String) -> void:
	if not data["collected"].has(animal_id):
		data["collected"].append(animal_id)
		save()

func complete(level_id: int, animal_id: String) -> void:
	if not data["completed"].has(level_id):
		data["completed"].append(level_id)
	unlock(animal_id)
	save()

func mark_forest_found(animal_id: String) -> void:
	if not data["forest_found"].has(animal_id):
		data["forest_found"].append(animal_id)
	unlock(animal_id)
	save()

func care_stats(animal_id: String) -> Dictionary:
	if not data["care"].has(animal_id):
		data["care"][animal_id] = {"food": 60, "clean": 75, "happy": 70}
	return data["care"][animal_id]

func care_for(animal_id: String, action: String) -> void:
	var stats = care_stats(animal_id)
	match action:
		"feed":
			stats["food"] = mini(100, int(stats["food"]) + 25)
		"wash":
			stats["clean"] = mini(100, int(stats["clean"]) + 25)
		"play":
			stats["happy"] = mini(100, int(stats["happy"]) + 25)
		"sleep":
			stats["happy"] = mini(100, int(stats["happy"]) + 10)
	data["care"][animal_id] = stats
	save()

func toggle_setting(key: String) -> bool:
	var settings: Dictionary = data["settings"]
	settings[key] = not bool(settings.get(key, true))
	save()
	return bool(settings[key])
