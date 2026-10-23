extends SceneTree
## Coloring room end-to-end regression: collection gate, black line-art,
## independent fillable regions, persistent color, undo/reset and responsive UI.
const Canvas = preload("res://scripts/ColoringCanvas.gd")
const ChoiceArt = preload("res://scripts/ChoiceArt.gd")
const Store = preload("res://scripts/SaveData.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_home()
	await process_frame
	var home_icon=false
	for node in _descendants(game):
		if node.get_script()==ChoiceArt and str(node.get("item_id"))=="coloring":
			home_icon=true
	if not home_icon:
		_fail("New independent coloring home icon missing")
		return
	game._go("coloring")
	await process_frame
	if game.screen!="coloring":
		_fail("Coloring icon did not open the room")
		return
	var room=game.coloring_game
	var original_collected=game.progress.data["collected"].duplicate(true)
	var old_pages=game.progress.data["coloring_pages"].duplicate(true)
	if game.progress.color_animal_region("not_collected","body","#F26A72"):
		_fail("Uncollected animal must never be colorable")
		return
	game.progress.unlock("rabbit")
	game.progress.unlock("snake")
	game.progress.unlock("cow")
	room._rebuild_gallery()
	if room.gallery.get_child_count()<3:
		_fail("Newly collected animals missing from the gallery")
		return
	room.select_animal("rabbit",false)
	await process_frame
	var canvas=room.canvas
	if not is_instance_valid(canvas) or canvas.get_script()!=Canvas:
		_fail("No interactive coloring canvas")
		return
	for info in game.animals:
		canvas.setup(str(info["id"]),{})
		if canvas.parts.size()<5:
			_fail("Missing outlined and colorable pieces for "+str(info["id"]))
			return
		for id in canvas.colors.keys():
			if str(canvas.colors[id])!="#FFFFFF":
				_fail("Unpainted animal should be monochrome")
				return
	room.select_animal("rabbit",false)
	await process_frame
	var scale=minf(canvas.size.x/340.0,canvas.size.y/365.0)
	if scale<=0:
		_fail("Canvas size not laid out")
		return
	var spot=Vector2(canvas.size.x*.5,canvas.size.y*.58)+Vector2(0,64)*scale
	var region=canvas.region_at(spot)
	if region.is_empty():
		_fail("Cannot tap and fill the animal's body")
		return
	room.choose_color("#7189ED")
	canvas.paint_at(spot)
	if str(game.progress.get_coloring("rabbit").get(region,""))!="#7189ED":
		_fail("Tapping white line art did not save filled color")
		return
	if not room.history.size()==1:
		_fail("Coloring should add undo snapshot")
		return
	room.undo()
	if game.progress.get_coloring("rabbit").has(region):
		_fail("Undo did not restore original white paper")
		return
	canvas.drag_region=""
	canvas.paint_at(spot)
	room.select_animal("snake",false)
	if not game.progress.get_coloring("snake").is_empty():
		_fail("Different animal accidentally inherited rabbit paint")
		return
	room.select_animal("rabbit",false)
	if str(canvas.colors.get(region,""))!="#7189ED":
		_fail("Switching animal lost coloring progress")
		return
	var loaded=Store.new()
	loaded.load_save()
	if str(loaded.get_coloring("rabbit").get(region,""))!="#7189ED":
		_fail("Coloring progress was not persisted to disk")
		return
	room.reset_coloring()
	if game.progress.get_coloring("rabbit").is_empty():
		_fail("First reset tap should only request confirmation")
		return
	room.reset_coloring()
	if not game.progress.get_coloring("rabbit").is_empty():
		_fail("Second reset tap did not clear coloring")
		return
	room.undo()
	if str(game.progress.get_coloring("rabbit").get(region,""))!="#7189ED":
		_fail("Undo after reset should recover colored masterpiece")
		return
	game.progress.data["collected"]=original_collected
	game.progress.data["coloring_pages"]=old_pages
	game.progress.save()
	print("PASS: separate coloring icon, 18 outline animals, collection gate, region fill, undo, reset confirmation and save")
	game.queue_free()
	await process_frame
	quit(0)

func _descendants(node: Node) -> Array:
	var result: Array=[]
	for c in node.get_children():
		result.append(c)
		result.append_array(_descendants(c))
	return result

func _fail(msg: String) -> void:
	push_error("COLORING ROOM TEST FAILED: "+msg)
	quit(1)
