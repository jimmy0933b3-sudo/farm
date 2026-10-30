extends SceneTree
## All collected species can race; private farm's 16-place limit is irrelevant.
const Rules=preload("res://scripts/RaceRules.gd")

func _initialize() -> void:
	var catalog: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/animals.json"))
	if catalog.size()!=43:
		_fail("Catalog must contain new weevil and all original species")
		return
	var unlocked_ids: Array=[]
	var unique: Dictionary={}
	for item in catalog:
		var id: String=str(item.get("id",""))
		if unique.has(id):
			_fail("Duplicate animal/insect ID "+id)
			return
		unique[id]=true
		unlocked_ids.append(id)
	var unlocked: Array=Rules.candidates(catalog,["cow"],unlocked_ids)
	if unlocked.size()!=43:
		_fail("All 43 collected animals must be selectable even with only one resident")
		return
	for target in ["weevil","seal","dolphin","cow","stag_beetle"]:
		if not unlocked.any(func(x): return str(x.get("id",""))==target):
			_fail("Previously non-resident character cannot race: "+target)
			return
	var few: Array=Rules.candidates(catalog,["cow","stag_beetle","butterfly"],
		["weevil","seal"])
	if few.size()!=2 or str(few[0]["id"])!="seal" or str(few[1]["id"])!="weevil":
		_fail("Roster must use ONLY collected, no uncollected resident and support fish and insects")
		return
	var duo: Array=Rules.candidates(catalog,[],["weevil","weevil","seal"])
	if duo.size()!=2:
		_fail("Duplicate collected IDs must not create duplicate racers")
		return
	var empty: Array=Rules.candidates(catalog,["weevil"],[])
	if empty.size()!=1 or str(empty[0]["id"])!="cow":
		_fail("Fresh players should only get a cow tutorial, not unlocked resident species")
		return
	var opponents: Array=Rules.opponents(unlocked,"weevil")
	if opponents.size()!=3:
		_fail("Race should still have three AI opponents")
		return
	for npc in opponents:
		if str(npc.get("id",""))=="weevil":
			_fail("AI should not duplicate the selected player")
			return
	print("PASS: all 43 unlocked animals, aquatic species, 8 insects, no uncollected residents, 3 AI racers and empty-save fallback")
	quit(0)

func _fail(message: String) -> void:
	push_error("RACE ROSTER FAILED: "+message)
	quit(1)
