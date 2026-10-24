extends SceneTree
## Full drawing academy regression: child draws actual paths on original
## animal art, must trace each of three templates, then decorates and earns stars.
const Canvas=preload("res://scripts/DrawingLessonCanvas.gd")
const Studio=preload("res://scripts/DrawingStudio.gd")
const Artist=preload("res://scripts/AnimalArt.gd")
const Store=preload("res://scripts/SaveData.gd")
const ChoiceArt=preload("res://scripts/ChoiceArt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.show_home()
	await process_frame
	var found_icon=false
	for node in _children(game):
		if node.get_script()==ChoiceArt and str(node.get("item_id"))=="drawing":
			found_icon=true
	if not found_icon:
		_fail("Animal drawing academy is missing an independent picture icon")
		return
	var old_collected=game.progress.data["collected"].duplicate(true)
	var old_lessons=game.progress.data["drawing_lessons"].duplicate(true)
	var old_color=game.progress.data["coloring_pages"].duplicate(true)
	if game.progress.replace_drawing_lesson("a_locked_animal",{"stage":3,"completed":true}):
		_fail("Locked animals must not allow a saved drawing")
		return
	game.progress.unlock("fox")
	game.progress.unlock("squirrel")
	game._go("drawing")
	await process_frame
	await process_frame
	var room=game.drawing_game
	if not is_instance_valid(room) or room.get_script()!=Studio or room.drawing.get_script()!=Canvas:
		_fail("Drawing academy did not open correctly")
		return
	room.select_animal("fox",false)
	await process_frame
	await process_frame
	var canvas=room.drawing
	if canvas.artist.get_script()!=Artist:
		_fail("Animal drawing must reference the ORIGINAL animal art")
		return
	if canvas.guides.size()!=3:
		_fail("Three progressive outlines are required, got "+str(canvas.guides.size()))
		return
	if canvas.can_advance():
		_fail("Cannot pass tracing simply by opening the page")
		return
	# Tap once never finishes a trace.
	canvas.start_stroke(canvas._screen(canvas.guides[0][0]))
	canvas.end_stroke()
	if canvas.can_advance():
		_fail("A single tap instantly passed the tracing level")
		return
	# Complete all three drawing stages via actual mouse-like freehand paths.
	for step in range(3):
		if canvas.stage!=step:
			_fail("Stages are not sequential")
			return
		var contour: PackedVector2Array=canvas.guides[step]
		canvas.start_stroke(canvas._screen(contour[0]))
		for i in range(1,contour.size()):
			canvas.drag_stroke(canvas._screen(contour[i]))
		canvas.end_stroke()
		if canvas.trace_coverage(step)<Canvas.REQUIRED_COVERAGE:
			_fail("Following genuine template path did not pass step "+str(step))
			return
		room.next_stage()
		if canvas.stage!=step+1:
			_fail("Completed drawing step did not unlock the next step")
			return
	if canvas.stage!=3:
		_fail("Free decoration did not unlock after three tracing steps")
		return
	canvas.set_color("#6989DA")
	canvas.set_mode("star")
	canvas.start_stroke(canvas._screen(Vector2(67,-102)))
	canvas.set_mode("heart")
	canvas.start_stroke(canvas._screen(Vector2(-67,91)))
	canvas.set_mode("paw")
	canvas.start_stroke(canvas._screen(Vector2(75,87)))
	if canvas.page.get("stamps",[]).size()!=3:
		_fail("Free decoration must support three different stamps")
		return
	canvas.set_mode("brush")
	canvas.start_stroke(canvas._screen(Vector2(-91,102)))
	canvas.drag_stroke(canvas._screen(Vector2(86,102)))
	canvas.end_stroke()
	room.next_stage()
	if not bool(canvas.page.get("completed",false)) or int(canvas.page.get("stars",0))<1:
		_fail("Completed drawing must earn at least one star")
		return
	var saved=game.progress.get_drawing_lesson("fox")
	if saved.get("strokes",[]).is_empty() or saved.get("stamps",[]).size()!=3:
		_fail("Artwork did not persist independently of coloring book")
		return
	if game.progress.data["coloring_pages"]!=old_color:
		_fail("New drawing game modified existing 30-color paintings")
		return
	var another=Store.new()
	another.load_save()
	if not bool(another.get_drawing_lesson("fox").get("completed",false)):
		_fail("Finished picture is not recovered after restarting")
		return
	room.select_animal("squirrel",false)
	if canvas.stage!=0 or bool(canvas.page.get("completed",false)):
		_fail("Squirrel inherited fox drawing progress")
		return
	room.select_animal("fox",false)
	if canvas.stage!=3 or not bool(canvas.page["completed"]):
		_fail("Returning to fox lost saved artwork")
		return
	room.reset_picture()
	if canvas.stage!=3:
		_fail("First reset tap should confirm, not erase artwork")
		return
	room.reset_picture()
	if canvas.stage!=0 or not canvas.page.get("strokes",[]).is_empty():
		_fail("Second reset should clear only that animal's drawing")
		return
	# 31 species: every character must have enough real vector geometry for 3 guides.
	for info in game.animals:
		canvas.setup(info,{})
		await process_frame
		await process_frame
		if canvas.guides.size()!=3:
			_fail("Missing three original-shape drawing guides for "+str(info["id"]))
			return
	game.progress.data["collected"]=old_collected
	game.progress.data["drawing_lessons"]=old_lessons
	game.progress.save()
	print("PASS: drawing icon, 31 animal outlines, 3 scored tracing steps, three stamps, stars, reset and per-animal persisted progress")
	game.queue_free()
	await process_frame
	quit(0)

func _children(node: Node) -> Array:
	var result: Array=[]
	for child in node.get_children():
		result.append(child)
		result.append_array(_children(child))
	return result

func _fail(message: String) -> void:
	push_error("DRAWING ACADEMY TEST FAILED: "+message)
	quit(1)
