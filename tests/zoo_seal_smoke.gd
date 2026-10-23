extends SceneTree
## Zoo Park shares the already-collected forest monkey, not a duplicate.
## Covers child navigation, six image cards, five new species, black-white
## finger coloring and automatic land/water separation for the new seal.
const Art=preload("res://scripts/AnimalArt.gd")
const ChoiceArt=preload("res://scripts/ChoiceArt.gd")
const SwimmingAnimal=preload("res://scripts/SwimmingAnimal.gd")
const Store=preload("res://scripts/SaveData.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_home()
	await process_frame
	var zoo_icons=0
	for node in _descendants(game):
		if node.get_script()==ChoiceArt and str(node.get("item_id"))=="zoo":
			zoo_icons+=1
	if zoo_icons!=1:
		_fail("There must be exactly one new Zoo Park picture icon")
		return
	var animals_by_id: Dictionary={}
	for a in game.animals:
		var id=str(a["id"])
		if animals_by_id.has(id):
			_fail("Animal ID duplicated: "+id)
			return
		animals_by_id[id]=a
	if animals_by_id.size()!=31:
		_fail("31 distinct species expected")
		return
	var zoo_ids=["camel","lion","tiger","elephant","monkey","hippo"]
	var zoo_new=0
	for id in zoo_ids:
		if not animals_by_id.has(id):
			_fail("Zoo animal missing: "+id)
			return
		if str(animals_by_id[id]["zone"])=="zoo":
			zoo_new+=1
	if zoo_new!=5 or str(animals_by_id["monkey"]["zone"])!="forest":
		_fail("Existing forest monkey must be reused by Zoo Park")
		return
	game._go("zoo")
	await process_frame
	if game.screen!="zoo" or game.current_zone!="zoo":
		_fail("Zoo picture icon did not open Zoo Park")
		return
	var cards=[]
	for node in _descendants(game):
		if node is Button:
			for child in _descendants(node):
				if child.get_script()==Art:
					cards.append(node)
					break
	if cards.size()!=6:
		_fail("Zoo Park must display exactly six animal picture cards, saw "+str(cards.size()))
		return
	# Tapping a shared-monkey card must return to Zoo Park, not Forest Park.
	var monkey_card: Button
	for card in cards:
		for child in _descendants(card):
			if child.get_script()==Art and str(child.animal_id)=="monkey":
				monkey_card=card
	if monkey_card==null:
		_fail("Missing shared monkey illustration in Zoo Park")
		return
	monkey_card.pressed.emit()
	await process_frame
	if game.screen!="animal" or game.current_zone!="zoo":
		_fail("Monkey card did not retain source Zoo Park")
		return
	game.show_zone(game.current_zone)
	await process_frame
	if game.screen!="zoo":
		_fail("Back from shared monkey leaves Zoo Park unexpectedly")
		return
	for id in ["camel","lion","tiger","elephant","hippo","seal"]:
		var info: Dictionary=animals_by_id[id]
		var view=Art.new()
		view.size=Vector2(440,440)
		root.add_child(view)
		view.setup(info)
		view.set_coloring(true,{})
		await process_frame
		if view.get_coloring_regions().size()<7:
			_fail("New original-art coloring shape missing: "+id)
			return
		view.queue_free()
	game.progress.unlock("seal")
	game.show_coloring()
	await process_frame
	game.coloring_game.select_animal("seal",false)
	await process_frame
	if str(game.coloring_game.selected_id)!="seal":
		_fail("Collected seal cannot enter coloring book")
		return
	game.show_private_farm()
	await process_frame
	var farm=game.private_farm_game
	var existing: Array=game.progress.data["private_farm"].duplicate()
	for id in existing:
		game.progress.private_farm_remove(str(id))
	farm._sync_residents()
	farm.place_animal("seal")
	await process_frame
	await process_frame
	if not farm.actors.has("seal") or farm.actors["seal"].get_script()!=SwimmingAnimal:
		_fail("New seal should swim only in the enlarged pond")
		return
	game.progress.private_farm_remove("seal")
	for id in existing:
		game.progress.private_farm_add(str(id))
	print("PASS: Zoo Park has six cards with one shared monkey, new five species, seal in coloring and pond")
	game.queue_free()
	await process_frame
	quit(0)

func _descendants(node: Node) -> Array:
	var arr: Array=[]
	for child in node.get_children():
		arr.append(child)
		arr.append_array(_descendants(child))
	return arr

func _fail(problem: String) -> void:
	push_error("ZOO + SEAL TEST FAILED: "+problem)
	quit(1)
