extends SceneTree
## Real touchscreen + mouse gesture regression: one dragged seed plants many plots.
const Rules=preload("res://scripts/GardenRules.gd")
const Art=preload("res://scripts/CropArt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _touch(garden: Control,point: Vector2,pressed: bool,index: int=7) -> void:
	var e=InputEventScreenTouch.new()
	e.index=index
	e.position=point
	e.pressed=pressed
	garden._input(e)

func _move(garden: Control,point: Vector2,index: int=7) -> void:
	var e=InputEventScreenDrag.new()
	e.index=index
	e.position=point
	garden._input(e)

func _mouse(garden: Control,point: Vector2,pressed: bool) -> void:
	var e=InputEventMouseButton.new()
	e.button_index=MOUSE_BUTTON_LEFT
	e.position=point
	e.pressed=pressed
	garden._input(e)

func _mouse_move(garden: Control,point: Vector2) -> void:
	var e=InputEventMouseMotion.new()
	e.position=point
	garden._input(e)

func _plot(game,idx: int) -> String:
	return str(game.progress.data["garden_plots"][idx].get("crop",""))

func _run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var original: Dictionary=game.progress.data.duplicate(true)
	game.progress.data["garden_plots"]=[]
	for i in range(6):
		game.progress.data["garden_plots"].append(Rules.empty_plot())
	game.progress.data["garden_inventory"]={"carrot":0,"cabbage":0,"pumpkin":0}
	game.progress.save()
	game.show_garden()
	await process_frame
	var garden=game.garden_game
	if garden.seed_buttons.size()!=3 or garden.plot_buttons.size()!=6:
		_fail("All three draggable seed images and six target plots required")
		return
	for crop in Rules.CROPS:
		var tile=garden.inventory_tiles[str(crop["id"])]
		if not tile.compact or tile.caption.visible or not tile.art is Art:
			_fail("Vegetable inventory must be compact picture plus number only")
			return
		if tile.custom_minimum_size.y>42 or tile.custom_minimum_size.x>90:
			_fail("Vegetable inventory must fit in slim top bar")
			return
	if garden.inventory_tiles["carrot"].count!=0:
		_fail("Starting basket count must remain zero")
		return
	if garden.has_method("water_all") or game.progress.has_method("garden_water"):
		_fail("No watering button or watering action must remain")
		return
	for i in range(6):
		if garden.plot_buttons[i].custom_minimum_size.x>=180.0 or garden.plot_buttons[i].custom_minimum_size.y>=136.0:
			_fail("Raised soil plots must be smaller than old flat cards")
			return
		if not garden.plot_beds[i] is Control or garden.plot_images[i].show_soil:
			_fail("Each plot needs separate isometric raised soil and a soil-free plant overlay")
			return
	if not garden.seed_buttons.all(func(btn): return btn.text.is_empty()):
		_fail("Seed buttons must use drawings alone, not instructional text")
		return
	var carrot=garden.seed_buttons[0].get_global_rect().get_center()
	var p0=garden.plot_buttons[0].get_global_rect().get_center()
	var p2=garden.plot_buttons[2].get_global_rect().get_center()
	if p0.distance_to(p2)<60:
		_fail("Plots must have room for dragging")
		return
	# A simple tap only selects a seed, it cannot accidentally plant.
	garden.press_plot(0)
	if _plot(game,0)!="":
		_fail("Tapping empty dirt should not plant without dragging")
		return
	_touch(garden,carrot,true)
	if garden.pointer_id!=7 or garden.drag_crop!="carrot":
		_fail("Touch-down on carrot must begin a seed gesture")
		return
	# Unrelated second finger must not hijack the first crop.
	_touch(garden,garden.seed_buttons[2].get_global_rect().get_center(),true,8)
	_move(garden,p0)
	if not garden.drag_active or not garden.drag_preview.visible:
		_fail("Moving a crop icon must show its floating preview")
		return
	_move(garden,p2)
	_touch(garden,p2,false)
	for i in range(3):
		if _plot(game,i)!="carrot":
			_fail("One fast continuous swipe must plant all top-row plots, including the crossed middle plot")
			return
	if garden.pointer_id!=-1 or garden.drag_preview.visible or garden.drag_planted_count!=3:
		_fail("Swipe should finish cleanly and plant each encountered plot exactly once")
		return
	# A second seed gesture plants bottom row, never replacing the first.
	var pumpkin=garden.seed_buttons[2].get_global_rect().get_center()
	var p3=garden.plot_buttons[3].get_global_rect().get_center()
	var p5=garden.plot_buttons[5].get_global_rect().get_center()
	_touch(garden,pumpkin,true,9)
	_move(garden,p3,9)
	_move(garden,p5,9)
	_touch(garden,p5,false,9)
	for i in range(3,6):
		if _plot(game,i)!="pumpkin":
			_fail("Dragging pumpkin across multiple other fields should plant each empty field")
			return
	for i in range(3):
		if _plot(game,i)!="carrot":
			_fail("Planting another vegetable must never overwrite previous crops")
			return
	if garden.drag_planted_count!=3:
		_fail("Only new plots should count toward planted fields")
		return
	# Another attempt over full fields cannot double-seed or spend stock.
	var cabbage=garden.seed_buttons[1].get_global_rect().get_center()
	_touch(garden,cabbage,true,10)
	_move(garden,p0,10)
	_move(garden,p5,10)
	_touch(garden,p5,false,10)
	if garden.drag_planted_count!=0:
		_fail("Swipe across occupied fields should not plant or replace anything")
		return
	for id in ["carrot","cabbage","pumpkin"]:
		if int(game.progress.data["garden_inventory"].get(id,-1))!=0:
			_fail("Sowing unlimited free seeds must not consume harvested produce")
			return
	# Desktop mouse drag works identically. Free plot 3 via ordinary harvest.
	var plot: Dictionary=game.progress.data["garden_plots"][3]
	plot["ready_at"]=int(Time.get_unix_time_from_system())-1
	game.progress.data["garden_plots"][3]=plot
	if not game.progress.garden_harvest(3,int(Time.get_unix_time_from_system())):
		_fail("A ready crop must still be harvestable")
		return
	var before=int(game.progress.data["garden_inventory"]["pumpkin"])
	var seed= garden.seed_buttons[1].get_global_rect().get_center()
	_mouse(garden,seed,true)
	_mouse_move(garden,p3)
	_mouse(garden,p3,false)
	if _plot(game,3)!="cabbage" or garden.pointer_id!=-1:
		_fail("Desktop mouse drag must plant crop and release pointer")
		return
	if int(game.progress.data["garden_inventory"]["pumpkin"])!=before:
		_fail("Planting does not consume harvested inventory")
		return
	if not garden.hint_label.text.contains("× 1"):
		_fail("One-field drag should show a compact icon and quantity")
		return
	var loaded=game.progress.data["garden_plots"].duplicate(true)
	game.progress.save()
	var store=load("res://scripts/SaveData.gd").new()
	store.load_save()
	if str(store.data["garden_plots"][1]["crop"])!="carrot" or str(store.data["garden_plots"][3]["crop"])!="cabbage":
		_fail("Plots planted with swipes must survive application reload")
		return
	if loaded.size()!=6:
		_fail("Saved field count cannot change after dragging")
		return
	game.progress.data=original
	game.progress.save()
	print("PASS: raised smaller beds, icon-only seeds, no watering, slim stock, touch multi-plot and mouse drags and saved crop state")
	game.queue_free()
	await process_frame
	quit(0)

func _fail(reason: String) -> void:
	push_error("GARDEN DRAG FAILED: "+reason)
	quit(1)
