extends SceneTree
## End-to-end: six plots -> planting -> watering -> harvest -> save -> farm feeding.
const Rules=preload("res://scripts/GardenRules.gd")
const Store=preload("res://scripts/SaveData.gd")
const CropArt=preload("res://scripts/CropArt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var backup: Dictionary=game.progress.data.duplicate(true)
	game.progress.data["garden_plots"]=[]
	for i in range(6):
		game.progress.data["garden_plots"].append(Rules.empty_plot())
	game.progress.data["garden_inventory"]={"carrot":0,"cabbage":0,"pumpkin":0}
	game.progress.data["garden_harvests"]=0
	game.progress.data["garden_feeds"]={}
	game.progress.save()
	game.show_home()
	await process_frame
	game._go("garden")
	await process_frame
	if game.screen!="garden" or game.garden_game.plot_buttons.size()!=6:
		_fail("Garden home icon must lead to six separately playable plots")
		return
	var garden=game.garden_game
	if Rules.CROPS.size()!=3 or garden.seed_buttons.size()!=3 or garden.plot_images.size()!=6:
		_fail("Three unique illustrated vegetable choices and six plots required")
		return
	for art in garden.plot_images:
		if not art is CropArt:
			_fail("Every plot needs an original crop illustration")
			return
	garden.select_seed("pumpkin")
	garden.press_plot(5)
	if str(game.progress.data["garden_plots"][5].get("crop",""))!="pumpkin":
		_fail("Touching empty soil must plant the selected pumpkin seed")
		return
	var planted_at=int(game.progress.data["garden_plots"][5]["planted_at"])
	garden.press_plot(5)
	if not bool(game.progress.data["garden_plots"][5].get("watered",false)):
		_fail("Touching a growing crop should water it")
		return
	var now=10000000
	if game.progress.garden_plant(0,"fake",now):
		_fail("Unknown seeds cannot be planted")
		return
	if game.progress.garden_plant(6,"carrot",now):
		_fail("Out-of-range plot index should be rejected")
		return
	for i in range(5):
		var id=str(Rules.CROPS[i%3]["id"])
		if not game.progress.garden_plant(i,id,now):
			_fail("Six independent plots should all be plantable")
			return
	if game.progress.garden_plant(0,"carrot",now):
		_fail("Growing plants cannot be overwritten")
		return
	if game.progress.garden_harvest(0,now+4):
		_fail("Plants cannot be harvested before they are ripe")
		return
	if not game.progress.garden_water(0,now+4):
		_fail("Watering should accelerate growth once")
		return
	if game.progress.garden_water(0,now+5):
		_fail("A plot cannot be watered twice")
		return
	if int(game.progress.data["garden_plots"][0]["ready_at"])>=now+int(Rules.CROPS[0]["seconds"]):
		_fail("Watering must shorten the remaining growth time")
		return
	for i in range(5):
		if not game.progress.garden_harvest(i,now+120):
			_fail("Ripe vegetables should go into the basket")
			return
	if game.progress.garden_harvest(0,now+121):
		_fail("Harvesting the same plant twice must not duplicate produce")
		return
	var basket: Dictionary=game.progress.data["garden_inventory"]
	if int(basket.get("carrot",0))!=4 or int(basket.get("cabbage",0))!=4 or int(basket.get("pumpkin",0))!=2:
		_fail("Harvest yields and vegetable stock should match exactly")
		return
	if not game.progress.data["garden_plots"][0].get("crop","").is_empty():
		_fail("Harvested plots should become available again")
		return
	var reload=Store.new()
	reload.load_save()
	if int(reload.data.get("garden_inventory",{}).get("carrot",0))!=4:
		_fail("Harvested vegetables must survive save/reload")
		return
	if str(reload.data.get("garden_plots",[])[5].get("crop",""))!="pumpkin":
		_fail("Unharvested growing plots must survive save/reload")
		return
	game.progress.unlock("cow")
	game.progress.unlock("snake")
	game.progress.data["private_farm"]=["cow","snake"]
	game.progress.save()
	game.show_private_farm()
	await process_frame
	var farm=game.private_farm_game
	if not farm.actors.has("cow") or not farm.veg_buttons.has("carrot"):
		_fail("Private farm should show the chosen cow and vegetable picker")
		return
	farm._set_resident("cow",false)
	var before: Dictionary=game.progress.care_stats("cow").duplicate()
	if not farm.feed_garden("carrot"):
		_fail("Cow should accept a harvested carrot")
		return
	if not farm.busy or farm.last_fed_crop!="carrot":
		_fail("Animal feeding must trigger the dedicated joyful reaction")
		return
	var cow=farm.actors["cow"]
	if cow.reaction_action!="garden_feed" or cow.avatar.mood!="garden_happy" or cow.heart_time<2.0:
		_fail("Eating garden produce must display happy face and animated hearts")
		return
	cow._process(.24)
	if cow.avatar.position.y>=0.0 and not farm.reduce_motion:
		_fail("Happy garden feeding should make the animal bounce joyfully")
		return
	if cow.effects.action!="garden_feed" or cow.effects.crop_id!="carrot":
		_fail("Food animation must depict the actual vegetable used")
		return
	if not game.sound.last_spoken_text.contains("開心"):
		_fail("Animal needs a cheerful Mandarin voice when it eats")
		return
	if int(game.progress.data["garden_inventory"]["carrot"])!=3:
		_fail("One consumed carrot must remove exactly one from the basket")
		return
	if int(game.progress.care_stats("cow")["happy"])<int(before["happy"]) or int(game.progress.care_stats("cow")["food"])<int(before["food"]):
		_fail("Vegetable feeding must improve fullness and happiness")
		return
	if farm.feed_garden("carrot"):
		_fail("Repeated taps during the eating animation cannot double-charge stock")
		return
	farm._on_reaction_finished("cow")
	farm._set_resident("snake",false)
	var cabbage_before=int(game.progress.data["garden_inventory"]["cabbage"])
	if farm.feed_garden("cabbage"):
		_fail("Meat-eating animals must not be fed inappropriate vegetables")
		return
	if int(game.progress.data["garden_inventory"]["cabbage"])!=cabbage_before:
		_fail("Rejected animal treats must never deduct vegetables")
		return
	var reloaded=Store.new()
	reloaded.load_save()
	if int(reloaded.data["garden_inventory"]["carrot"])!=3 or int(reloaded.data["garden_feeds"].get("cow",0))<1:
		_fail("Consumed stock and feeding achievements must remain saved")
		return
	game.progress.data=backup
	game.progress.save()
	game.show_home()
	await process_frame
	print("PASS: 3 original vegetables, 6 plots, water, growth, one-time harvest, offline stock, safe feed, cheerful face/voice and durable save")
	game.queue_free()
	await process_frame
	quit(0)

func _fail(reason: String) -> void:
	push_error("GARDEN FAILED: "+reason)
	quit(1)
