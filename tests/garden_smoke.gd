extends SceneTree
## End-to-end: six raised 3D beds, timed growth without watering, harvest and animal feeding.
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
	for crop in Rules.CROPS:
		var id=str(crop["id"])
		if not garden.inventory_tiles.has(id) or not garden.inventory_tiles[id].art is CropArt:
			_fail("Every vegetable must have a real illustrated basket counter")
			return
		if garden.inventory_tiles[id].count!=0 or not garden.inventory_tiles[id].compact or garden.inventory_tiles[id].caption.visible:
			_fail("Fresh garden basket must show compact icon-only stock at zero")
			return
	garden.select_seed("pumpkin")
	garden.press_plot(5)
	if str(game.progress.data["garden_plots"][5].get("crop",""))!="":
		_fail("Empty soil must wait for dragging a seed rather than planting on accidental tap")
		return
	# The planting gesture itself is verified in garden_drag_smoke.gd.
	if not game.progress.garden_plant(5,"pumpkin",int(Time.get_unix_time_from_system())):
		_fail("Garden rules must accept a valid pumpkin seed")
		return
	garden._refresh()
	var planted_at=int(game.progress.data["garden_plots"][5]["planted_at"])
	var original_ready=int(game.progress.data["garden_plots"][5]["ready_at"])
	garden.press_plot(5)
	if game.progress.has_method("garden_water") or int(game.progress.data["garden_plots"][5]["ready_at"])!=original_ready:
		_fail("Watering must be removed; tapping a growing crop cannot shorten its countdown")
		return
	if not garden.plot_beds[5] is Control or garden.plot_images[5].show_soil:
		_fail("Plots must display separate 3D raised beds without oval soil overlays")
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
	if int(game.progress.data["garden_plots"][0]["ready_at"])!=now+int(Rules.CROPS[0]["seconds"]):
		_fail("Planting must start the complete countdown immediately without watering")
		return
	if Rules.stage(game.progress.data["garden_plots"][0],now+120)!=3:
		_fail("Vegetables must ripen automatically at the end of the countdown")
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
	garden._refresh()
	if garden.inventory_tiles["carrot"].quantity.text!="× 4" or garden.inventory_tiles["pumpkin"].count!=2:
		_fail("Harvest must visibly increase illustrated stock, not just hidden save data")
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
	if not farm.actors.has("cow") or not farm.farm_inventory_tiles.has("carrot"):
		_fail("Private farm should show cow and visible draggable illustrated vegetable basket")
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
	if farm.farm_inventory_tiles["carrot"].count!=3 or farm.farm_inventory_tiles["carrot"].quantity.text!="× 3":
		_fail("Farm basket must visibly decrease immediately after vegetable feeding")
		return
	if not farm.info_label.text.contains("4 → 3") or farm.farm_inventory_tiles["carrot"].quantity.text!="× 3":
		_fail("Feeding confirmation and directly draggable basket must show one deduction")
		return
	if int(game.progress.care_stats("cow")["happy"])<int(before["happy"]) or int(game.progress.care_stats("cow")["food"])<int(before["food"]):
		_fail("Vegetable feeding must improve fullness and happiness")
		return
	if farm.feed_garden("carrot"):
		_fail("Repeated taps during the eating animation cannot double-charge stock")
		return
	farm._on_reaction_finished("cow")
	if farm.busy:
		_fail("After eating, farm must accept another vegetable drag")
		return
	if not farm.feed_garden("carrot"):
		_fail("A second separate feeding should be allowed after the previous one finishes")
		return
	if int(game.progress.data["garden_inventory"]["carrot"])!=2 or farm.farm_inventory_tiles["carrot"].count!=2:
		_fail("Every additional vegetable treat must deduct and refresh exactly one unit")
		return
	if not farm.info_label.text.contains("3 → 2"):
		_fail("Second feeding confirmation must use the latest remaining stock")
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
	if int(reloaded.data["garden_inventory"]["carrot"])!=2 or int(reloaded.data["garden_feeds"].get("cow",0))<2:
		_fail("Consumed stock and feeding achievements must remain saved")
		return
	game.show_garden()
	await process_frame
	if game.garden_game.inventory_tiles["carrot"].count!=2:
		_fail("Garden stock must agree with farm stock after two consumed treats")
		return
	# Validate one-tap collection and automatic growth without watering.
	var current=int(Time.get_unix_time_from_system())
	if not game.progress.garden_plant(0,"carrot",current):
		_fail("Freshly harvested plot should accept a new seed")
		return
	if not game.progress.garden_plant(1,"cabbage",current):
		_fail("Freshly harvested second plot should accept a seed")
		return
	if game.garden_game.has_method("water_all"):
		_fail("The garden must not offer watering controls")
		return
	if int(game.progress.data["garden_plots"][0]["ready_at"])!=current+int(Rules.CROPS[0]["seconds"]):
		_fail("New crop must start its unmodified timer automatically")
		return
	for index in [0,1]:
		var plot: Dictionary=game.progress.data["garden_plots"][index]
		plot["ready_at"]=current-1
		game.progress.data["garden_plots"][index]=plot
	game.garden_game.harvest_all()
	if game.garden_game.inventory_tiles["carrot"].count!=4 or game.garden_game.inventory_tiles["cabbage"].count!=6:
		_fail("Harvest-all must update the same persisted inventory counters")
		return
	game.progress.data=backup
	game.progress.save()
	game.show_home()
	await process_frame
	print("PASS: 6 isometric beds, 3 timed vegetables, no watering, one-time harvest, stock, happy feed and durable save")
	game.queue_free()
	await process_frame
	quit(0)

func _fail(reason: String) -> void:
	push_error("GARDEN FAILED: "+reason)
	quit(1)
