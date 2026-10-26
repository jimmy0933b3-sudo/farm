extends SceneTree
## Inspect the ACTUAL painted vector contours for every old insect and weevil.
## Shared body templates recolored in eight hues must not pass this test.
const Art=preload("res://scripts/AnimalArt.gd")
const INSECTS=["rhinoceros_beetle","stag_beetle","butterfly","ladybug",
	"bee","mantis","dung_beetle","weevil"]

func _initialize() -> void:
	call_deferred("_run")

func _screen(art: Control, local: Vector2) -> Vector2:
	var scale_value=minf(art.size.x/220.0,art.size.y/220.0)
	return Vector2(art.size.x*.5,art.size.y*.52)+local*scale_value

func _run() -> void:
	var animals=JSON.parse_string(FileAccess.get_file_as_string("res://data/animals.json"))
	var lookup: Dictionary={}
	for animal in animals:
		if str(animal.get("zone",""))=="insect":
			lookup[str(animal["id"])]=animal
	if lookup.size()!=8:
		_fail("Eight and only eight unique insect records are required")
		return
	var shape_signatures: Dictionary={}
	var art=Art.new()
	art.size=Vector2(440,440)
	root.add_child(art)
	await process_frame
	for id in INSECTS:
		if not lookup.has(id):
			_fail("Missing old/new insect ID "+id)
			return
		var info: Dictionary=lookup[id]
		if str(info.get("name","")).is_empty():
			_fail("Missing Chinese name for "+id)
			return
		art.setup(info)
		art.set_coloring(true,{})
		await process_frame
		var shapes: Array=art.get_coloring_regions()
		if shapes.size()<7:
			_fail("Unpaintable insect portrait "+id)
			return
		var signature: String=""
		var colored_cells: int=0
		# Finger-paint contours are the geometry rendered in all the cards,
		# care views, farm actors, racing karts and coloring room. Compare
		# actual vertices, NOT title, ID, palette or fallback emoji.
		for shape in shapes:
			var points: PackedVector2Array=shape.get("points",PackedVector2Array())
			if points.size()<3:
				_fail("Malformed insect polygon "+id)
				return
			signature+=str(points.size())+":"
			for p in points:
				signature+="%d,%d;" % [roundi(p.x*2.0),roundi(p.y*2.0)]
		for y in range(-12,13):
			for x in range(-12,13):
				if not art.color_region_at(_screen(art,Vector2(x*9.0,y*10.0))).is_empty():
					colored_cells+=1
		if colored_cells<20:
			_fail("Unrecognizable or empty insect silhouette "+id)
			return
		var geometry: int=signature.hash()
		if shape_signatures.has(geometry):
			_fail("Reused exact insect vector outline: "+id+" duplicates "+str(shape_signatures[geometry]))
			return
		shape_signatures[geometry]=id
	# The new weevil must have an actual long, individually paintable rostrum.
	art.setup(lookup["weevil"])
	art.set_coloring(true,{})
	await process_frame
	if art.color_region_at(_screen(art,Vector2(-7,-133))).is_empty():
		_fail("Weevil's curved long nose is not actually drawn and paintable")
		return
	if art.color_region_at(_screen(art,Vector2(85,-125)))!="":
		_fail("Weevil must not share stag beetle's enormous side pincers")
		return
	if shape_signatures.size()!=8:
		_fail("Insect icon fingerprints are not unique")
		return
	art.queue_free()
	await process_frame
	print("PASS: eight visibly distinct original insect silhouettes, detailed separate snout, unique paintable polygon fingerprints")
	quit(0)

func _fail(message: String) -> void:
	push_error("INSECT ICON AUDIT FAILED: "+message)
	quit(1)
