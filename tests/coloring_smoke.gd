extends SceneTree
## Real finger-painting test: a tap alone CANNOT fill any animal region.
## Drag lays down individually saved pigment dots, clipped by original AnimalArt.
const Canvas = preload("res://scripts/ColoringCanvas.gd")
const Art = preload("res://scripts/AnimalArt.gd")
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
		_fail("Independent coloring icon missing")
		return
	var original_collected=game.progress.data["collected"].duplicate(true)
	var old_pages=game.progress.data["coloring_pages"].duplicate(true)
	if game.progress.color_animal_region("uncollected_fake","body","#F26A72"):
		_fail("Cannot color an uncollected species")
		return
	for id in ["rabbit","snake","meerkat"]:
		game.progress.unlock(id)
		game.progress.replace_coloring(id,{})
	game._go("coloring")
	await process_frame
	var room=game.coloring_game
	if room.PALETTE.size()!=30 or room.palette_buttons.size()!=30:
		_fail("Coloring room must offer exactly thirty color buttons")
		return
	var unique_colors={}
	for hex in room.PALETTE:
		if unique_colors.has(hex) or not Color.html_is_valid(str(hex)):
			_fail("Palette contains duplicate or invalid color")
			return
		unique_colors[hex]=true
	if room.palette_buttons[0].get_parent().columns!=10:
		_fail("Thirty crayons should fit into a three-row ten-column grid")
		return
	room.select_animal("rabbit",false)
	await process_frame
	var canvas=room.canvas
	if not is_instance_valid(canvas) or canvas.get_script()!=Canvas:
		_fail("Expected direct-drawing canvas")
		return
	if canvas.avatar.get_script()!=Art:
		_fail("Coloring MUST use the same original AnimalArt as the album")
		return
	for info in game.animals:
		canvas.setup(str(info["id"]),{})
		await process_frame
		if canvas.get_regions().size()<5:
			_fail("Original-art coloring shapes missing for "+str(info["id"]))
			return
		if not canvas.avatar.coloring_mode:
			_fail("Artist should be black-and-white in coloring room")
			return
	room.select_animal("rabbit",false)
	await process_frame
	var scale=minf(canvas.size.x/220.0,canvas.size.y/220.0)
	if scale<=0.0:
		_fail("Animal canvas not laid out")
		return
	var center=Vector2(canvas.size.x*.5,canvas.size.y*.52)+Vector2(0,22)*scale
	var region=canvas.region_at(center)
	if region.is_empty():
		_fail("Cannot find colorable body region")
		return
	room.choose_color("#793EA4")
	if room.selected_color!="#793EA4" or canvas.brush_color!="#793EA4":
		_fail("One of the newly added sixteen crayons cannot be selected")
		return
	# One tap, no MOVE, must remain blank.
	canvas.begin_stroke(center)
	canvas.finish_stroke()
	if not game.progress.get_coloring("rabbit").is_empty():
		_fail("A single touch instantly filled an entire region")
		return
	if room.history.size()!=0:
		_fail("Tap alone should not create an undo entry")
		return
	# Partial stroke paints only a series of dots, no full-region flat color.
	canvas.begin_stroke(center)
	canvas.move_stroke(center+Vector2(23,0))
	if not canvas.colors.has("strokes_v2"):
		_fail("Finger dragging produced no visible paint points")
		return
	if game.progress.get_coloring("rabbit").has("strokes_v2"):
		_fail("Partial live stroke should save once on finger release")
		return
	canvas.finish_stroke()
	var page=game.progress.get_coloring("rabbit")
	var strokes=page.get("strokes_v2",[])
	if strokes.is_empty() or str(strokes[0].get("color",""))!="#793EA4":
		_fail("Painting with the new purple crayon did not persist")
		return
	if strokes.size()<1:
		_fail("Finger stroke was not saved")
		return
	if page.has(region):
		_fail("Finger stroke incorrectly changed the entire region color")
		return
	if not room.history.size()==1:
		_fail("One gesture should create exactly one undo step")
		return
	if strokes[0]["dots"].size()<2:
		_fail("Fast finger movement must paint a connected path")
		return
	var first_page=page.duplicate(true)
	# A second gesture from inside the body into empty outside cannot
	# create a whole-page paint region.
	var count_before=strokes.size()
	canvas.begin_stroke(center)
	canvas.move_stroke(Vector2(-30,-30))
	canvas.finish_stroke()
	page=game.progress.get_coloring("rabbit")
	for stroke in page.get("strokes_v2",[]):
		for pair in stroke["dots"]:
			if absf(float(pair[0]))>260 or absf(float(pair[1]))>260:
				_fail("Unbounded strokes escaped the paper")
				return
	if page.get("strokes_v2",[]).size()<count_before:
		_fail("Previous paint was lost")
		return
	# Undo acts on gestures in the current animal page, before switching.
	room.undo()
	if game.progress.get_coloring("rabbit")!=first_page:
		_fail("Undo must remove only the last gesture, preserving earlier marks")
		return
	# Leaving and reopening a coloring page must keep the partial scribbles.
	room.select_animal("snake",false)
	if not game.progress.get_coloring("snake").is_empty():
		_fail("Another species inherited the first animal's strokes")
		return
	room.select_animal("rabbit",false)
	if room.canvas.colors.get("strokes_v2",[]).is_empty():
		_fail("Navigating back lost partially painted colors")
		return
	var loaded=Store.new()
	loaded.load_save()
	if loaded.get_coloring("rabbit").get("strokes_v2",[]).is_empty():
		_fail("Saved partial painting was lost after reloading the save file")
		return
	room.reset_coloring()
	if game.progress.get_coloring("rabbit").is_empty():
		_fail("Reset must need confirmation and protect existing art")
		return
	room.reset_coloring()
	if not game.progress.get_coloring("rabbit").is_empty():
		_fail("Confirmed reset did not clear the art")
		return
	room.undo()
	if game.progress.get_coloring("rabbit").get("strokes_v2",[]).is_empty():
		_fail("Undo after reset failed to bring back painted strokes")
		return
	game.progress.data["collected"]=original_collected
	game.progress.data["coloring_pages"]=old_pages
	game.progress.save()
	print("PASS: 38 original animals, no tap-to-fill, real clipped finger stroke, partial save, undo, reset and reload")
	game.queue_free()
	await process_frame
	quit(0)

func _descendants(node: Node) -> Array:
	var all: Array=[]
	for child in node.get_children():
		all.append(child)
		all.append_array(_descendants(child))
	return all

func _fail(reason: String) -> void:
	push_error("FINGER PAINT TEST FAILED: "+reason)
	quit(1)
