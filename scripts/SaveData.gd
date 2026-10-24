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
		"ocean_explore_session": {},
		"ocean_explore_runs": 0,
		"ocean_explore_previous": [],
		"ocean_found": [],
		"zoo_explore_session": {},
		"zoo_explore_runs": 0,
		"zoo_explore_previous": [],
		"zoo_found": [],
		"private_farm": [],
		"coloring_pages": {},
		"drawing_lessons": {},
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

func private_farm_add_status(animal_id: String, capacity: int = 16) -> String:
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

func private_farm_add(animal_id: String, capacity: int = 16) -> bool:
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
		if str(key)=="strokes_v2":
			continue
		var region=str(key)
		var hex=str(page[key])
		if region.length()>40 or region.is_empty() or hex.length()!=7 or not Color.html_is_valid(hex):
			continue
		cleaned[region]=hex
	# Stroke v2 is a collection of partial brush marks, not flat fill colors.
	# Keep old pieces for backwards compatibility but validate coordinates
	# and limit file size to avoid broken or unbounded save files.
	var source=page.get("strokes_v2",[])
	var valid_strokes: Array=[]
	var dot_count=0
	if source is Array:
		for stroke in source:
			if not stroke is Dictionary or valid_strokes.size()>=900:
				continue
			var region=str(stroke.get("region",""))
			var pigment=str(stroke.get("color",""))
			var dots=stroke.get("dots",[])
			if not region.begins_with("piece_") and not region.begins_with("snake_") and not region.begins_with("line_"):
				continue
			if region.length()>40 or not _valid_pigment(pigment) or not dots is Array:
				continue
			var saved_dots: Array=[]
			for dot in dots:
				if dot_count>=4800 or not dot is Array or dot.size()!=2:
					break
				if typeof(dot[0]) not in [TYPE_INT,TYPE_FLOAT] or typeof(dot[1]) not in [TYPE_INT,TYPE_FLOAT]:
					continue
				var x=float(dot[0])
				var y=float(dot[1])
				if not is_finite(x) or not is_finite(y) or absf(x)>260.0 or absf(y)>260.0:
					continue
				saved_dots.append([snappedf(x,0.5),snappedf(y,0.5)])
				dot_count+=1
			if not saved_dots.is_empty():
				valid_strokes.append({"region":region,"color":pigment,"dots":saved_dots})
	if not valid_strokes.is_empty():
		cleaned["strokes_v2"]=valid_strokes
	data["coloring_pages"][animal_id]=cleaned
	save()
	return true

func _valid_pigment(hex: String) -> bool:
	return hex.length()==7 and hex.begins_with("#") and Color.html_is_valid(hex)

func get_ocean_explore_session(order: Array) -> Dictionary:
	var session=data.get("ocean_explore_session",{})
	var valid=session is Dictionary
	if valid:
		valid=session.get("placement",null) is Array and session.get("found",null) is Array
	if valid:
		var positions: Array=session["placement"]
		var found: Array=session["found"]
		valid=positions.size()==order.size() and found.size()<order.size()
		if valid:
			for id in order:
				if positions.count(id)!=1:
					valid=false
			for i in range(found.size()):
				if found[i]!=order[i]:
					valid=false
	if not valid:
		var shuffled: Array=order.duplicate()
		shuffled.shuffle()
		if shuffled==data.get("ocean_explore_previous",[]):
			shuffled.reverse()
		session={"placement":shuffled,"found":[]}
		data["ocean_explore_session"]=session
		save()
	return session

func record_ocean_explore_found(id: String) -> void:
	var session: Dictionary=data.get("ocean_explore_session",{})
	if session.is_empty():
		return
	if not session["found"].has(id):
		session["found"].append(id)
	if not data["ocean_found"].has(id):
		data["ocean_found"].append(id)
	if not data["collected"].has(id):
		data["collected"].append(id)
	save()

func finish_ocean_explore(order: Array) -> void:
	var session: Dictionary=data.get("ocean_explore_session",{})
	if session.get("found",[])!=order:
		return
	data["ocean_explore_runs"]=int(data.get("ocean_explore_runs",0))+1
	data["ocean_explore_previous"]=session["placement"].duplicate()
	data["ocean_explore_session"]={}
	save()


func get_zoo_explore_session(order: Array) -> Dictionary:
	# Resume the active round, not just collected animals. Existing monkeys
	# found in Forest Park remain the same ID and share a single sticker.
	var session=data.get("zoo_explore_session",{})
	var valid=session is Dictionary
	if valid:
		valid=session.get("placement",null) is Array and session.get("found",null) is Array
	if valid:
		var positions: Array=session["placement"]
		var found: Array=session["found"]
		valid=positions.size()==order.size() and found.size()<order.size()
		if valid:
			for id in order:
				if positions.count(id)!=1:
					valid=false
			for i in range(found.size()):
				if found[i]!=order[i]:
					valid=false
	if not valid:
		var shuffled: Array=order.duplicate()
		shuffled.shuffle()
		if shuffled==data.get("zoo_explore_previous",[]):
			shuffled.reverse()
		session={"placement":shuffled,"found":[]}
		data["zoo_explore_session"]=session
		save()
	return session

func record_zoo_explore_found(id: String) -> void:
	var session: Dictionary=data.get("zoo_explore_session",{})
	if session.is_empty():
		return
	if not session["found"].has(id):
		session["found"].append(id)
	if not data["zoo_found"].has(id):
		data["zoo_found"].append(id)
	if not data["collected"].has(id):
		data["collected"].append(id)
	save()

func finish_zoo_explore(order: Array) -> void:
	var session: Dictionary=data.get("zoo_explore_session",{})
	if session.get("found",[])!=order:
		return
	data["zoo_explore_runs"]=int(data.get("zoo_explore_runs",0))+1
	data["zoo_explore_previous"]=session["placement"].duplicate()
	data["zoo_explore_session"]={}
	save()


func get_drawing_lesson(animal_id: String) -> Dictionary:
	if not data["collected"].has(animal_id):
		return {}
	var page=data.get("drawing_lessons",{}).get(animal_id,{})
	return page.duplicate(true) if page is Dictionary else {}

func replace_drawing_lesson(animal_id: String, page: Dictionary) -> bool:
	# Never unlock uncollected species; limit local artwork size and reject
	# malformed JSON to protect existing saves. Do not touch coloring_pages.
	if not data["collected"].has(animal_id):
		return false
	var cleaned={
		"stage":clampi(int(page.get("stage",0)),0,3),
		"strokes":[],
		"stamps":[],
		"completed":bool(page.get("completed",false)),
		"stars":clampi(int(page.get("stars",0)),0,3)}
	var total=0
	var source=page.get("strokes",[])
	if source is Array:
		for stroke in source:
			if not stroke is Dictionary or cleaned["strokes"].size()>=400: continue
			var phase=clampi(int(stroke.get("stage",0)),0,3)
			var ink=str(stroke.get("color","#F36F78"))
			if not _valid_pigment(ink): continue
			var points=stroke.get("points",[])
			if not points is Array: continue
			var result=[]
			for pair in points:
				if total>=3000: break
				if not pair is Array or pair.size()!=2: continue
				if typeof(pair[0]) not in [TYPE_INT,TYPE_FLOAT] or typeof(pair[1]) not in [TYPE_INT,TYPE_FLOAT]: continue
				var x=float(pair[0])
				var y=float(pair[1])
				if not is_finite(x) or not is_finite(y) or absf(x)>145.0 or absf(y)>156.0: continue
				result.append([snappedf(x,.5),snappedf(y,.5)])
				total+=1
			if not result.is_empty():
				cleaned["strokes"].append({"stage":phase,"color":ink,"points":result})
	var stickers=page.get("stamps",[])
	if stickers is Array:
		for stamp in stickers:
			if not stamp is Dictionary or cleaned["stamps"].size()>=70: continue
			var kind=str(stamp.get("kind",""))
			var ink=str(stamp.get("color","#F2D25A"))
			var at=stamp.get("pos",[])
			if kind not in ["star","heart","paw"] or not _valid_pigment(ink): continue
			if not at is Array or at.size()!=2: continue
			if typeof(at[0]) not in [TYPE_INT,TYPE_FLOAT] or typeof(at[1]) not in [TYPE_INT,TYPE_FLOAT]: continue
			var x=float(at[0])
			var y=float(at[1])
			if not is_finite(x) or not is_finite(y) or absf(x)>145 or absf(y)>156: continue
			cleaned["stamps"].append({"kind":kind,"color":ink,"pos":[snappedf(x,.5),snappedf(y,.5)]})
	data["drawing_lessons"][animal_id]=cleaned
	save()
	return true
