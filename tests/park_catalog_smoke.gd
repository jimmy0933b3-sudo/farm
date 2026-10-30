extends SceneTree
## All new park members must appear in the global sticker album and coloring room.
const Art=preload("res://scripts/AnimalArt.gd")
const ChoiceArt=preload("res://scripts/ChoiceArt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var original=game.progress.data.duplicate(true)
	var all: Array=game._all_friends()
	if game.animals.size()!=43 or game.birds.size()!=12 or game.monsters.size()!=12 or all.size()!=67:
		_fail("Global roster must contain 43 animals, 12 birds, 12 monsters")
		return
	var seen: Dictionary={}
	for friend in all:
		var id=str(friend.get("id",""))
		if seen.has(id):
			_fail("Duplicate global creature ID: "+id)
			return
		seen[id]=true
	for id in ["guinea_pig","dog","cat","golden_hamster","axolotl","bird_eagle","bird_owl_park","bird_osprey","monster_fire","monster_rainbow"]:
		if not seen.has(id):
			_fail("Missing new park friend: "+id)
			return
	game.show_home()
	await process_frame
	var cola_icon=false
	for node in _descendants(game):
		if node.get_script()==ChoiceArt and str(node.get("item_id"))=="cola":
			cola_icon=true
	if not cola_icon:
		_fail("Cola small-pet park needs a unique illustrated home tile")
		return
	game._go("cola")
	await process_frame
	if game.screen!="cola" or game.current_zone!="cola":
		_fail("Cola small-pet park must open from homepage")
		return
	var pets={}
	for node in _descendants(game):
		if node is Art:
			pets[str(node.animal_id)]=true
	if pets.size()!=4:
		_fail("Cola park must show exactly 4 pet icons, got "+str(pets.keys()))
		return
	for id in ["guinea_pig","dog","cat","golden_hamster"]:
		if not pets.has(id):
			_fail("Cola park pet missing: "+id)
			return
	game.show_zone("ocean")
	await process_frame
	var ocean_friends={}
	for node in _descendants(game):
		if node is Art:
			ocean_friends[str(node.animal_id)]=true
	if ocean_friends.size()!=8 or not ocean_friends.has("axolotl"):
		_fail("Ocean park should have eight friends, including freshwater axolotl")
		return
	game.show_ocean_search()
	await process_frame
	if game.ocean_game.ORDER.size()!=8 or game.ocean_game.spots.size()!=8:
		_fail("Underwater discovery must include axolotl as its eighth seek target")
		return
	game.progress.unlock("axolotl")
	game.progress.unlock("dog")
	game.progress.unlock("cat")
	game.progress.unlock("golden_hamster")
	game.progress.unlock("bird_eagle")
	game.progress.unlock("monster_fire")
	game.show_album()
	await process_frame
	var album_art={}
	for node in _descendants(game):
		if node is Art:
			album_art[str(node.animal_id)]=true
	if album_art.size()!=all.size():
		_fail("Global sticker album must show all 67 friends (locked included)")
		return
	for id in seen:
		if not album_art.has(id):
			_fail("Global album lacks "+id)
			return
	game.show_animal("bird_eagle")
	await process_frame
	if game.current_zone!="bird" or game.screen!="animal":
		_fail("A collected bird must open its own detail from the shared album")
		return
	game._return_to_friend_park("bird")
	await process_frame
	if game.screen!="bird_world":
		_fail("Bird detail should return to bird park")
		return
	game.show_coloring()
	await process_frame
	var room=game.coloring_game
	if room.animals.size()!=67 or room.gallery.get_child_count()!=67:
		_fail("Coloring gallery must display all 67 friends, including undiscovered ones")
		return
	for id in ["axolotl","dog","cat","golden_hamster","bird_eagle","bird_owl_park","bird_osprey","monster_fire","monster_rainbow"]:
		room.canvas.setup(id,{})
		await process_frame
		if room.canvas.get_regions().size()<5 or not room.canvas.avatar.coloring_mode:
			_fail("Creature is not a real stroke-coloring silhouette: "+id)
			return
	room.select_animal("bird_eagle",false)
	await process_frame
	if room.selected_id!="bird_eagle" or room.canvas.get_regions().size()<5:
		_fail("New birds should support opening actual coloring pages")
		return
	room.select_animal("monster_fire",false)
	await process_frame
	if room.selected_id!="monster_fire" or room.canvas.get_regions().size()<5:
		_fail("New monsters should support opening actual coloring pages")
		return
	room.select_animal("axolotl",false)
	await process_frame
	if room.selected_id!="axolotl" or room.canvas.get_regions().size()<5:
		_fail("New axolotl should support stroke coloring")
		return
	game.progress.data=original
	game.progress.save()
	game.show_home()
	await process_frame
	print("PASS: eight sea creatures, four cola pets, 67 unique shared album and coloring thumbnails, 9 paintable samples, saved unlocks")
	game.queue_free()
	await process_frame
	quit(0)

func _descendants(node: Node) -> Array:
	var result: Array=[]
	for child in node.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result

func _fail(message: String) -> void:
	push_error("GLOBAL PARK CATALOG FAILED: "+message)
	quit(1)
