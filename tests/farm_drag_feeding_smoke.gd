extends SceneTree
## Real private farm gesture: basket picture -> an animal, with one stock
## deducted, actual happiness/sound, no old feeding button or modal.
const Rules=preload("res://scripts/GardenRules.gd")

func _initialize() -> void:
	call_deferred("_run")

func _touch(farm,point: Vector2,down: bool,index: int=1) -> void:
	var e=InputEventScreenTouch.new()
	e.index=index
	e.position=point
	e.pressed=down
	farm._input(e)

func _drag(farm,point: Vector2,index: int=1) -> void:
	var e=InputEventScreenDrag.new()
	e.index=index
	e.position=point
	farm._input(e)

func _mouse(farm,point: Vector2,down: bool) -> void:
	var e=InputEventMouseButton.new()
	e.button_index=MOUSE_BUTTON_LEFT
	e.position=point
	e.pressed=down
	farm._input(e)

func _mouse_drag(farm,point: Vector2) -> void:
	var e=InputEventMouseMotion.new()
	e.position=point
	farm._input(e)

func _animal_point(farm,id: String) -> Vector2:
	var actor=farm.actors[id]
	return farm.farm_view.get_global_rect().position+actor.position+actor.size*.5-Vector2(farm.camera_x,0)

func _run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var backup=game.progress.data.duplicate(true)
	game.progress.unlock("cow")
	game.progress.unlock("snake")
	game.progress.data["private_farm"]=["cow","snake"]
	game.progress.data["garden_inventory"]={"carrot":3,"cabbage":2,"pumpkin":1,"carnivorous_flower":1}
	game.progress.data["settings"]["ui_language"]="en"
	game.progress.save()
	game.show_private_farm()
	await process_frame
	await process_frame
	var farm=game.private_farm_game
	if farm.commands.get_child_count()!=4:
		_fail("Only wash, play, sleep and sound care actions should remain")
		return
	var expected_buttons=["Bath","Play","Rest","Sound"]
	for i in range(expected_buttons.size()):
		if farm.commands.get_child(i).text!=expected_buttons[i]:
			_fail("Private farm action buttons must have English labels")
			return
	if not farm.remove_button.text=="Remove":
		_fail("Remove button must be labeled in English")
		return
	for button in farm.commands.get_children():
		if "餵" in button.text or "食" in button.text:
			_fail("General feeding and vegetable feeding buttons must both be gone")
			return
	if is_instance_valid(farm.get_node_or_null("VegetablePicker")):
		_fail("Extra popup picker should not exist")
		return
	if farm.stock_strip.get_index()>=farm.farm_view.get_index():
		_fail("Drag basket needs to sit above the animals")
		return
	for id in ["carrot","cabbage","pumpkin","carnivorous_flower"]:
		if not farm.farm_inventory_tiles.has(id):
			_fail("All four crops must have stock illustration directly draggable")
			return
		if farm.farm_inventory_tiles[id].art.crop_id!=id:
			_fail("Stock illustrations are swapped for "+id)
			return
	for actor in farm.actors.values():
		actor.idle_timer=1000.0
		actor.walk_speed=0.0
	farm.focus_resident("cow")
	await process_frame
	var start=farm.farm_inventory_tiles["carrot"].get_global_rect().get_center()
	var cow_point=_animal_point(farm,"cow")
	if not farm.farm_view.get_global_rect().has_point(cow_point):
		_fail("Cow must be visible in scrolled farm view for food dropping")
		return
	var before=game.progress.care_stats("cow").duplicate(true)
	# Merely tapping a vegetable must not eat it.
	_touch(farm,start,true)
	_touch(farm,start,false)
	if int(game.progress.data["garden_inventory"]["carrot"])!=3 or farm.busy:
		_fail("Stock tap must not consume a vegetable")
		return
	# One gesture drags from basket to cow without choosing cow first.
	farm._set_resident("snake",false)
	_touch(farm,start,true,2)
	if farm.food_pointer!=2 or farm.food_crop!="carrot":
		_fail("Touching an in-stock crop must capture the drag from its picture")
		return
	_touch(farm,start,true,3)
	if farm.food_pointer!=2:
		_fail("Second finger must not steal the food drag")
		return
	_drag(farm,cow_point,2)
	if not farm.food_dragging or not farm.food_preview.visible:
		_fail("Floating vegetable should follow child's finger")
		return
	if farm.food_hover_id!="cow" or not farm.actors["cow"].selected:
		_fail("Moving food over the cow must target and highlight the actual cow")
		return
	_touch(farm,cow_point,false,2)
	if farm.food_pointer!=-1 or farm.food_preview.visible:
		_fail("Drag must release and hide floating vegetable")
		return
	if not farm.busy or farm.active_id!="cow" or farm.actors["cow"].reaction_action!="garden_feed":
		_fail("Dropping food on cow must directly trigger joyful animal feeding")
		return
	if farm.last_fed_crop!="carrot" or farm.actors["cow"].effects.crop_id!="carrot":
		_fail("Eating animation must use the actual crop from the basket")
		return
	if farm.actors["cow"].avatar.mood!="garden_happy" or farm.actors["cow"].heart_time<2.0:
		_fail("Fed cow should jump, smile and emit hearts")
		return
	if int(game.progress.data["garden_inventory"]["carrot"])!=2 or farm.farm_inventory_tiles["carrot"].count!=2:
		_fail("First stock drag must deduct exactly one carrot and refresh the illustrated basket")
		return
	if not farm.info_label.text.contains("3 → 2"):
		_fail("Feeding must confirm exact before and after stock count")
		return
	if int(game.progress.care_stats("cow")["happy"])<int(before["happy"]) or int(game.progress.care_stats("cow")["food"])<int(before["food"]):
		_fail("Fed cow must gain fullness and happiness")
		return
	if farm.food_pointer!=-1:
		_fail("Food pointer must reset after valid feed")
		return
	farm._on_reaction_finished("cow")
	# Every creature, including the snake, enjoys every game crop.
	farm.focus_resident("snake")
	await process_frame
	var snake_point=_animal_point(farm,"snake")
	var cabbage_start=farm.farm_inventory_tiles["cabbage"].get_global_rect().get_center()
	var cabbage_before=int(game.progress.data["garden_inventory"]["cabbage"])
	_touch(farm,cabbage_start,true,4)
	_drag(farm,snake_point,4)
	_touch(farm,snake_point,false,4)
	if int(game.progress.data["garden_inventory"]["cabbage"])!=cabbage_before-1 or not farm.busy:
		_fail("Snake must happily eat cabbage and deduct exactly one crop")
		return
	if farm.actors["snake"].avatar.mood!="garden_happy" or farm.actors["snake"].heart_time<2.0:
		_fail("Every animal must smile and show hearts after being fed")
		return
	farm._on_reaction_finished("snake")
	cabbage_before=int(game.progress.data["garden_inventory"]["cabbage"])
	# Dropping outside the animal's world should not consume.
	_touch(farm,cabbage_start,true,5)
	_drag(farm,Vector2(3,3),5)
	_touch(farm,Vector2(3,3),false,5)
	if int(game.progress.data["garden_inventory"]["cabbage"])!=cabbage_before:
		_fail("Dropping outside an animal must not consume crops")
		return
	# The imaginary carnivorous flower is a fourth illustrated game treat.
	var flower_start=farm.farm_inventory_tiles["carnivorous_flower"].get_global_rect().get_center()
	_touch(farm,flower_start,true,6)
	_drag(farm,snake_point,6)
	_touch(farm,snake_point,false,6)
	if int(game.progress.data["garden_inventory"]["carnivorous_flower"])!=0:
		_fail("Fantasy flower must be edible by any pet and deduct one from stock")
		return
	if not farm.busy or farm.actors["snake"].avatar.mood!="garden_happy":
		_fail("Fantasy flower should trigger an extra-happy face")
		return
	farm._on_reaction_finished("snake")
	# Mouse dragging is also supported: cow can eat another carrot.
	farm.focus_resident("cow")
	await process_frame
	cow_point=_animal_point(farm,"cow")
	_mouse(farm,start,true)
	_mouse_drag(farm,cow_point)
	_mouse(farm,cow_point,false)
	if int(game.progress.data["garden_inventory"]["carrot"])!=1 or farm.farm_inventory_tiles["carrot"].count!=1:
		_fail("Mouse drop onto animal must also deduct exactly one crop")
		return
	farm._on_reaction_finished("cow")
	_mouse(farm,start,true)
	_mouse_drag(farm,cow_point)
	_mouse(farm,cow_point,false)
	if int(game.progress.data["garden_inventory"]["carrot"])!=0 or farm.farm_inventory_tiles["carrot"].count!=0:
		_fail("Last vegetable must also be deducted exactly once")
		return
	farm._on_reaction_finished("cow")
	_mouse(farm,start,true)
	if farm.food_pointer!=-1 or not farm.info_label.text.contains("還沒收成"):
		_fail("Empty basket must not allow feeding, and should show a helpful hint")
		return
	if int(game.progress.data["garden_inventory"]["carrot"])!=0:
		_fail("Empty basket cannot fall below zero")
		return
	if int(game.progress.data["garden_feeds"].get("cow",0))<3:
		_fail("Successful drag feeds must persist their count")
		return
	game.progress.data=backup
	game.progress.save()
	print("PASS: drag directly from illustrated basket to roaming animal, exact -1, no general/popup feeding, touch & mouse, all-animals-eat, no off-target charges, empty basket, happy reaction and save")
	game.queue_free()
	await process_frame
	quit(0)

func _fail(reason: String) -> void:
	push_error("FARM FOOD DRAG FAILED: "+reason)
	quit(1)
