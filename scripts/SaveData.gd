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
		"forest_explore_session": {},
		"forest_explore_runs": 0,
		"forest_explore_previous": [],
		"private_farm": [],
		"coloring_pages": {},
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

func get_forest_explore_session(order: Array) -> Dictionary:
	var session = data.get("forest_explore_session",{})
	# Extend previous valid sessions on new species releases without losing finds.
	if session is Dictionary and session.get("placement",null) is Array and session.get("found",null) is Array:
		var previous_positions: Array=session["placement"]
		var previous_found: Array=session["found"]
		if previous_positions.size()>0 and previous_positions.size()<order.size():
			var previous_order: Array=order.slice(0,previous_positions.size())
			var compatible: bool=true
			for id in previous_order:
				if previous_positions.count(id)!=1:
					compatible=false
			for i in range(previous_found.size()):
				if i>=previous_order.size() or previous_found[i]!=previous_order[i]:
					compatible=false
			if compatible:
				var expanded: Array=previous_positions.duplicate()
				var extra: Array=order.slice(previous_positions.size(),order.size())
				extra.shuffle()
				expanded.append_array(extra)
				session={"placement":expanded,"found":previous_found.duplicate()}
				data["forest_explore_session"]=session
				save()
	var valid=session is Dictionary
	if valid:
		valid=session.get("placement",null) is Array and session.get("found",null) is Array
	if valid:
		var positions: Array=session["placement"]
		var previous_found: Array=session["found"]
		valid=positions.size()==order.size() and previous_found.size()<order.size()
		if valid:
			for id in order:
				if positions.count(id)!=1:
					valid=false
			for i in range(previous_found.size()):
				if previous_found[i]!=order[i]:
					valid=false
	if not valid:
		var positions: Array=order.duplicate()
		positions.shuffle()
		if positions==data.get("forest_explore_previous",[]):
			positions.reverse()
		session={"placement":positions,"found":[]}
		data["forest_explore_session"]=session
		save()
	return session

func private_farm_add_status(animal_id: String, capacity: int = 8) -> String:
	if not data["collected"].has(animal_id):
		return "locked"
	var residents: Array = data["private_farm"]
	if residents.has(animal_id):
		return "already"
	if residents.size() >= capacity:
		return "full"
	residents.append(animal_id)
	save()
	return "added"

func private_farm_add(animal_id: String, capacity: int = 8) -> bool:
	# Keep old callers compatible without conflating 'locked' and 'full'.
	return private_farm_add_status(animal_id,capacity) in ["added","already"]

func private_farm_remove(animal_id: String) -> void:
	var residents: Array=data["private_farm"]
	residents.erase(animal_id)
	save()

func record_forest_explore_found(animal_id: String) -> void:
	var session: Dictionary = data.get("forest_explore_session",{})
	if session.is_empty():
		return
	var discovered: Array = session.get("found",[])
	if not discovered.has(animal_id):
		discovered.append(animal_id)
	if not data["forest_found"].has(animal_id):
		data["forest_found"].append(animal_id)
	if not data["collected"].has(animal_id):
		data["collected"].append(animal_id)
	save()

func finish_forest_explore(order: Array) -> void:
	var session: Dictionary=data.get("forest_explore_session",{})
	if session.get("found",[])!=order:
		return
	data["forest_explore_runs"]=int(data.get("forest_explore_runs",0))+1
	data["forest_explore_previous"]=session.get("placement",[]).duplicate()
	data["forest_explore_session"]={}
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

func get_coloring(animal_id: String) -> Dictionary:
	if not data["collected"].has(animal_id):
		return {}
	var all_pages: Dictionary=data.get("coloring_pages",{})
	var page=all_pages.get(animal_id,{})
	return page.duplicate(true) if page is Dictionary else {}

func color_animal_region(animal_id: String, region: String, hex: String) -> bool:
	if not data["collected"].has(animal_id):
		return false
	if region.is_empty() or region.length()>40:
		return false
	if hex.length()!=7 or not hex.begins_with("#") or not Color.html_is_valid(hex):
		return false
	var pages: Dictionary=data["coloring_pages"]
	if not pages.has(animal_id) or not pages[animal_id] is Dictionary:
		pages[animal_id]={}
	pages[animal_id][region]=hex
	save()
	return true

func replace_coloring(animal_id: String, page: Dictionary) -> bool:
	if not data["collected"].has(animal_id):
		return false
	var cleaned: Dictionary={}
	for key in page.keys():
		var region=str(key)
		var hex=str(page[key])
		if region.length()>40 or region.is_empty() or hex.length()!=7 or not Color.html_is_valid(hex):
			continue
		cleaned[region]=hex
	data["coloring_pages"][animal_id]=cleaned
	save()
	return true
