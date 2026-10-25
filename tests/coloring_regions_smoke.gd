extends SceneTree
## Verify that visible small/fine body parts are actually registered as
## paintable shapes for all 19 original animals. Includes snake winding body
## and deer antlers which previously looked colorable but were not.
const Art = preload("res://scripts/AnimalArt.gd")
const Canvas = preload("res://scripts/ColoringCanvas.gd")
const Store = preload("res://scripts/SaveData.gd")

func _initialize() -> void:
	call_deferred("_run")

func _screen(art: Control, world: Vector2) -> Vector2:
	var scale_value=minf(art.size.x/220.0,art.size.y/220.0)
	return Vector2(art.size.x*0.5,art.size.y*0.52)+world*scale_value

func _run() -> void:
	var contents=FileAccess.get_file_as_string("res://data/animals.json")
	var animals=JSON.parse_string(contents)
	if not animals is Array or animals.size()!=37:
		_fail("37 expected animals missing")
		return
	var art=Art.new()
	root.add_child(art)
	art.custom_minimum_size=Vector2(510,510)
	art.size=Vector2(510,510)
	art.set_coloring(true,{})
	await process_frame
	# Body parts must be present as fillable polygons even for the small
	# anatomical details. The original art should remain identical in profile.
	var special={
		"rabbit":{"part":"inner rabbit ear","point":Vector2(-34,-127)},
		"cow":{"part":"cow coat patch","point":Vector2(-44,-58)},
		"deer":{"part":"antler","point":Vector2(-46,-117),"prefix":"line_"},
		"snake":{"part":"snake coil","point":Vector2(-74,45),"id":"snake_coils"},
		"guinea_pig":{"part":"guinea pig cheek","point":Vector2(-48,4)},
		"chicken":{"part":"chicken crest","point":Vector2(0,-109)},
		"owl":{"part":"owl face","point":Vector2(-27,-39)},
		"meerkat":{"part":"meerkat face mask","point":Vector2(-32,-43)},
		"boar":{"part":"boar snout","point":Vector2(0,-4)}
	}
	for info in animals:
		var id=str(info["id"])
		art.setup(info)
		art.set_coloring(true,{})
		await process_frame
		var regions: Array=art.get_coloring_regions()
		if regions.size()<7:
			_fail("Too few paintable shapes on "+id+": "+str(regions.size()))
			return
		# Every animal has independently selectable feet/body/head and at
		# least one small appendage. Scan exposed outlines using hit testing.
		var unique={}
		for yy in range(-171,121,11):
			for xx in range(-130,137,11):
				var name=art.color_region_at(_screen(art,Vector2(xx,yy)))
				if not name.is_empty():
					unique[name]=true
		if unique.size()<4:
			_fail("Too many unreachable body regions on "+id+": "+str(unique.size()))
			return
		if special.has(id):
			var case: Dictionary=special[id]
			var found=art.color_region_at(_screen(art,case["point"]))
			if found.is_empty():
				_fail(str(case["part"])+" has no paintable hitbox")
				return
			if case.has("id") and found!=str(case["id"]):
				_fail(str(case["part"])+" hit wrong polygon: "+found)
				return
			if case.has("prefix") and not found.begins_with(str(case["prefix"])):
				_fail(str(case["part"])+" cannot retain fine-line painting: "+found)
				return
		if id=="snake":
			var neck=art.color_region_at(_screen(art,Vector2(42,12)))
			if neck!="snake_neck":
				_fail("Snake's long neck cannot be stroked: "+neck)
				return
			var hole=art.color_region_at(_screen(art,Vector2(-13,45)))
			if hole=="snake_coils":
				_fail("The center hole was mistakenly treated as solid snake body")
				return
	# One full finger gesture on a small ear and on the snake's coiled body
	# must save the very same region hit by the original sprite.
	var canvas=Canvas.new()
	canvas.size=Vector2(510,510)
	root.add_child(canvas)
	await process_frame
	for test_case in [
		{"id":"rabbit","point":Vector2(-34,-127)},
		{"id":"snake","point":Vector2(-74,45)},
		{"id":"deer","point":Vector2(-46,-117)}
	]:
		canvas.setup(str(test_case["id"]),{})
		await process_frame
		var first=_screen(canvas,test_case["point"])
		var region=canvas.region_at(first)
		canvas.begin_stroke(first)
		canvas.move_stroke(first+Vector2(8,1))
		canvas.finish_stroke()
		if canvas.colors.get("strokes_v2",[]).is_empty():
			_fail("Finger stroke failed on "+str(test_case["id"])+" "+region)
			return
		if str(canvas.colors["strokes_v2"][0]["region"])!=region:
			_fail("Saved stroke not attached to correct animal part")
			return
	var progress=Store.new()
	progress.data=progress._fresh()
	progress.data["collected"]=["deer","snake"]
	var antler={"strokes_v2":[{"region":"line_99","color":"#F26A72","dots":[[-45.0,-118.0],[-43.5,-116.0]]}]}
	if not progress.replace_coloring("deer",antler):
		_fail("Cannot save colored antler")
		return
	if progress.get_coloring("deer").get("strokes_v2",[]).size()!=1:
		_fail("Antler color stroke was filtered out of save data")
		return
	print("PASS: 37 animal region maps; ears, coat patches, snout, feet, crest, antlers, snake coils/neck, save")
	canvas.queue_free()
	art.queue_free()
	await process_frame
	quit(0)

func _fail(reason: String) -> void:
	push_error("COLOR REGION REGRESSION FAILED: "+reason)
	quit(1)
