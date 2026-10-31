extends RefCounted
## Versioned, fail-safe local persistence. Offline time never decays pets.

const PATH = "user://animal_island_save.json"
const BAK = "user://animal_island_save.bak"
const TEMP = "user://animal_island_save.tmp"
const GardenRules=preload("res://scripts/GardenRules.gd")

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
		"insect_explore_session": {},
		"insect_explore_runs": 0,
		"insect_explore_previous": [],
		"insect_found": [],
		"private_farm": [],
		"garden_plots": [
			{"crop":"","planted_at":0,"ready_at":0},
			{"crop":"","planted_at":0,"ready_at":0},
			{"crop":"","planted_at":0,"ready_at":0},
			{"crop":"","planted_at":0,"ready_at":0},
			{"crop":"","planted_at":0,"ready_at":0},
			{"crop":"","planted_at":0,"ready_at":0},
			{"crop":"","planted_at":0,"ready_at":0},
			{"crop":"","planted_at":0,"ready_at":0},
			{"crop":"","planted_at":0,"ready_at":0},
			{"crop":"","planted_at":0,"ready_at":0}
		],
		"garden_inventory": {"carrot":0,"cabbage":0,"pumpkin":0,"carnivorous_flower":0},
		"garden_harvests": 0,
		"garden_feeds": {},
		"monster_found": [],
		"monster_plays": {},
		"bird_found": [],
		"bird_interactions": {},
		"bird_flight_records": {},
		"bird_flight_totals": {"races":0,"stars":0},
		"race_records": {},
		"race_totals": {"races":0,"stars":0},
		"coloring_pages": {},
		"drawing_lessons": {},
		"care": {},
		"settings": {"music": true, "sound": true, "speech": true, "reduce_motion": false,"ui_language":"zh"},
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
	# Non-destructive upgrades: keep six older crops and append four new plots.
	var plots: Array=data.get("garden_plots",[])
	while plots.size()<10:
		plots.append(GardenRules.empty_plot())
	data["garden_plots"]=plots
	var basket: Dictionary=data.get("garden_inventory",{})
	for crop in GardenRules.CROPS:
		var id=str(crop["id"])
		if not basket.has(id):
			basket[id]=0
	data["garden_inventory"]=basket
	var settings: Dictionary=data.get("settings",{})
	if str(settings.get("ui_language","zh")) not in ["zh","en"]:
		settings["ui_language"]="zh"
	if not settings.has("ui_language"):
		settings["ui_language"]="zh"
	data["settings"]=settings

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

## Every planting/harvesting/feeding change is saved as a whole.
## Optional timestamps allow deterministic game-lifecycle tests.
func garden_plant(index: int,id: String,epoch: int=-1) -> bool:
	var crop: Dictionary=GardenRules.crop_for(id)
	var plots: Array=data.get("garden_plots",[])
	if crop.is_empty() or index<0 or index>=plots.size():
		return false
	if not str(plots[index].get("crop","")).is_empty():
		return false
	var now=int(Time.get_unix_time_from_system()) if epoch<0 else epoch
	plots[index]={"crop":id,"planted_at":now,"ready_at":now+int(crop["seconds"])}
	data["garden_plots"]=plots
	save()
	return true

func garden_harvest(index: int,epoch: int=-1) -> bool:
	var plots: Array=data.get("garden_plots",[])
	if index<0 or index>=plots.size():
		return false
	var slot: Dictionary=plots[index]
	var id=str(slot.get("crop",""))
	var crop: Dictionary=GardenRules.crop_for(id)
	var now=int(Time.get_unix_time_from_system()) if epoch<0 else epoch
	if crop.is_empty() or now<int(slot.get("ready_at",0)):
		return false
	var basket: Dictionary=data.get("garden_inventory",{})
	basket[id]=clampi(int(basket.get(id,0))+int(crop["harvest"]),0,9999)
	data["garden_inventory"]=basket
	plots[index]=GardenRules.empty_plot()
	data["garden_plots"]=plots
	data["garden_harvests"]=int(data.get("garden_harvests",0))+1
	save()
	return true

func garden_can_feed(animal_id: String,crop_id: String) -> bool:
	var basket: Dictionary=data.get("garden_inventory",{})
	return data.get("private_farm",[]).has(animal_id) and \
		GardenRules.suitable(animal_id,crop_id) and int(basket.get(crop_id,0))>0

func garden_feed(animal_id: String,crop_id: String) -> bool:
	if not garden_can_feed(animal_id,crop_id):
		return false
	var basket: Dictionary=data.get("garden_inventory",{})
	basket[crop_id]=int(basket.get(crop_id,0))-1
	data["garden_inventory"]=basket
	var stats: Dictionary=care_stats(animal_id)
	stats["food"]=mini(100,int(stats.get("food",60))+18)
	stats["happy"]=mini(100,int(stats.get("happy",70))+25)
	data["care"][animal_id]=stats
	var fed: Dictionary=data.get("garden_feeds",{})
	fed[animal_id]=int(fed.get(animal_id,0))+1
	data["garden_feeds"]=fed
	save()
	return true

func record_bird_found(id: String) -> void:
	if not data["bird_found"].has(id):
		data["bird_found"].append(id)
	if not data["collected"].has(id):
		data["collected"].append(id)
	save()

func record_bird_interaction(id: String) -> void:
	var entries: Dictionary=data.get("bird_interactions",{})
	entries[id]=int(entries.get(id,0))+1
	data["bird_interactions"]=entries
	save()

func record_bird_flight(result: Dictionary) -> void:
	var id=str(result.get("bird_id",""))
	var route=str(result.get("course_id",""))
	if id.is_empty() or route not in ["lake","forest","mountain","night"]:
		return
	# A child can try the mandarin duck before collecting anyone.
	if not data["bird_found"].has(id) and id!="bird_mandarin":
		return
	var records: Dictionary=data.get("bird_flight_records",{})
	var entry: Dictionary=records.get(id,{"races":0,"wins":0,"stars":0,"best_place":4})
	entry["races"]=int(entry.get("races",0))+1
	entry["wins"]=int(entry.get("wins",0))+(1 if int(result.get("place",4))==1 else 0)
	entry["stars"]=int(entry.get("stars",0))+int(result.get("stars_earned",0))
	entry["best_place"]=mini(int(entry.get("best_place",4)),clampi(int(result.get("place",4)),1,4))
	records[id]=entry
	data["bird_flight_records"]=records
	var totals: Dictionary=data.get("bird_flight_totals",{"races":0,"stars":0})
	totals["races"]=int(totals.get("races",0))+1
	totals["stars"]=int(totals.get("stars",0))+int(result.get("stars_earned",0))
	data["bird_flight_totals"]=totals
	save()

func record_monster_found(id: String) -> void:
	if not data["monster_found"].has(id):
		data["monster_found"].append(id)
	if not data["collected"].has(id):
		data["collected"].append(id)
	save()

func record_monster_play(id: String) -> void:
	var plays: Dictionary=data.get("monster_plays",{})
	plays[id]=int(plays.get(id,0))+1
	data["monster_plays"]=plays
	save()

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

func private_farm_add_status(animal_id: String, capacity: int = 32) -> String:
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

func private_farm_add(animal_id: String, capacity: int = 32) -> bool:
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


func get_insect_explore_session(order: Array) -> Dictionary:
	var session=data.get("insect_explore_session",{})
	# Extend valid six- or seven-target sessions without discarding already found rounds.
	if session is Dictionary and session.get("placement",null) is Array and session.get("found",null) is Array:
		var old_positions: Array=session["placement"]
		var old_found: Array=session["found"]
		if old_positions.size()>0 and old_positions.size()<order.size():
			var old_order: Array=order.slice(0,old_positions.size())
			var compatible=true
			for id in old_order:
				if old_positions.count(id)!=1:
					compatible=false
			for i in range(old_found.size()):
				if i>=old_order.size() or old_found[i]!=old_order[i]:
					compatible=false
			if compatible:
				var extended: Array=old_positions.duplicate()
				extended.append_array(order.slice(old_positions.size(),order.size()))
				session={"placement":extended,"found":old_found.duplicate()}
				data["insect_explore_session"]=session
				save()
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
		if shuffled==data.get("insect_explore_previous",[]):
			shuffled.reverse()
		session={"placement":shuffled,"found":[]}
		data["insect_explore_session"]=session
		save()
	return session

func record_insect_explore_found(id: String) -> void:
	var session: Dictionary=data.get("insect_explore_session",{})
	if session.is_empty():
		return
	if not session["found"].has(id):
		session["found"].append(id)
	if not data["insect_found"].has(id):
		data["insect_found"].append(id)
	if not data["collected"].has(id):
		data["collected"].append(id)
	save()

func finish_insect_explore(order: Array) -> void:
	var session: Dictionary=data.get("insect_explore_session",{})
	if session.get("found",[])!=order:
		return
	data["insect_explore_runs"]=int(data.get("insect_explore_runs",0))+1
	data["insect_explore_previous"]=session["placement"].duplicate()
	data["insect_explore_session"]={}
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

## Racing is additive and does not alter collected animals, residents or care.
func record_race(result: Dictionary) -> void:
	var id: String=str(result.get("animal_id",""))
	var track: String=str(result.get("track_id",""))
	if id.is_empty() or track not in ["farm","flower","rainbow","candy","cosmic"]:
		return
	if not data["collected"].has(id) and not data["private_farm"].has(id):
		# Existing offline saves can still race after a fresh install: the game
		# does not silently unlock a species by adding a race result.
		if id!="cow":
			return
	var records: Dictionary=data["race_records"]
	var entry: Dictionary=records.get(id,{"races":0,"wins":0,"stars":0,"best_place":4,"tracks":{}})
	entry["races"]=clampi(int(entry.get("races",0))+1,0,999999)
	entry["wins"]=clampi(int(entry.get("wins",0))+(1 if int(result.get("place",4))==1 else 0),0,999999)
	entry["stars"]=clampi(int(entry.get("stars",0))+int(result.get("stars_earned",0)),0,999999)
	entry["best_place"]=mini(int(entry.get("best_place",4)),clampi(int(result.get("place",4)),1,4))
	var tracks: Dictionary=entry.get("tracks",{})
	tracks[track]=int(tracks.get(track,0))+1
	entry["tracks"]=tracks
	records[id]=entry
	data["race_records"]=records
	var totals: Dictionary=data["race_totals"]
	totals["races"]=clampi(int(totals.get("races",0))+1,0,999999)
	totals["stars"]=clampi(int(totals.get("stars",0))+int(result.get("stars_earned",0)),0,999999)
	data["race_totals"]=totals
	save()
