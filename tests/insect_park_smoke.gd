extends SceneTree
## A fifth park with six distinct species, original art and correct navigation.
const ChoiceArt=preload("res://scripts/ChoiceArt.gd")
const Art=preload("res://scripts/AnimalArt.gd")
const Store=preload("res://scripts/SaveData.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_home()
	await process_frame
	var ids=["rhinoceros_beetle","stag_beetle","butterfly","ladybug","bee","mantis","dung_beetle"]
	var unique={}
	for a in game.animals:
		var id=str(a["id"])
		if unique.has(id):
			_fail("Duplicate ID: "+id)
			return
		unique[id]=a
	if unique.size()!=38:
		_fail("38 unique species expected")
		return
	var park_icon=0
	var misplaced=0
	for n in _children(game):
		if n.get_script()==ChoiceArt and str(n.item_id)=="insect": park_icon+=1
		if n.get_script()==ChoiceArt and str(n.item_id)=="insect_search": misplaced+=1
	if park_icon!=1 or misplaced!=0:
		_fail("Exactly one insect park home icon; no search icon on home")
		return
	game._go("insect")
	await process_frame
	if game.screen!="insect":
		_fail("Insect park did not open")
		return
	var has_search=false
	var visible={}
	for n in _children(game):
		if n.get_script()==ChoiceArt and str(n.item_id)=="insect_search": has_search=true
		if n.get_script()==Art: visible[str(n.animal_id)]=true
	if not has_search or visible.size()!=7:
		_fail("Expected seven insect cards and a nested search entrance")
		return
	for id in ids:
		if not visible.has(id) or not unique.has(id) or str(unique[id]["zone"])!="insect":
			_fail("Missing insect: "+id)
			return
		var art=Art.new()
		art.size=Vector2(400,400)
		root.add_child(art)
		art.setup(unique[id])
		art.set_coloring(true,{})
		await process_frame
		if art.get_coloring_regions().size()<7:
			_fail("Insect cannot be finger colored: "+id)
			return
		art.queue_free()
	var store=Store.new()
	store.data=store._fresh()
	store.data["collected"]=["cow","butterfly"]
	store.data["private_farm"]=["cow"]
	if not store.private_farm_add("butterfly",16) or store.data["private_farm"]!=["cow","butterfly"]:
		_fail("Insect must use the existing land resident system without losing previous guests")
		return
	game.show_animal("mantis","insect")
	await process_frame
	if game.current_zone!="insect":
		_fail("Insect card did not preserve park source")
		return
	game.show_zone("insect")
	if game.screen!="insect":
		_fail("Back from insect lost park")
		return
	print("PASS: insect park icon, seven distinct vector insects, paint masks, resident reuse and navigation")
	game.queue_free()
	await process_frame
	quit(0)
func _children(node: Node) -> Array:
	var items=[]
	for n in node.get_children():
		items.append(n)
		items.append_array(_children(n))
	return items
func _fail(reason: String) -> void:
	push_error("INSECT PARK FAILED: "+reason)
	quit(1)
