extends SceneTree
## Original squirrel and fox must have different silhouettes, then all saved
## colors continue using the very same AnimalArt renderer as before.
const Art=preload("res://scripts/AnimalArt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _at(view: Control, world: Vector2) -> Vector2:
	var s=minf(view.size.x/220.0,view.size.y/220.0)
	return Vector2(view.size.x*.5,view.size.y*.52)+world*s

func _run() -> void:
	var infos=JSON.parse_string(FileAccess.get_file_as_string("res://data/animals.json"))
	var by_id={}
	for animal in infos:
		by_id[str(animal["id"])]=animal
	var art=Art.new()
	art.size=Vector2(440,440)
	root.add_child(art)
	await process_frame
	var hit_map={}
	var shape_counts={}
	for id in ["squirrel","fox"]:
		art.setup(by_id[id])
		art.set_coloring(true,{})
		await process_frame
		var shapes=art.get_coloring_regions()
		if shapes.size()<12:
			_fail(id+" silhouette lacks individually touchable shapes")
			return
		shape_counts[id]=shapes.size()
		hit_map[id]=[
			art.color_region_at(_at(art,Vector2(95,-81)))!="",
			art.color_region_at(_at(art,Vector2(130,58)))!=""
		]
		art.mood="happy"
		art.queue_redraw()
		await process_frame
	if hit_map["squirrel"]==hit_map["fox"]:
		_fail("Squirrel curled high tail and fox sideways brush tail still have the same hit silhouette")
		return
	if not hit_map["squirrel"][0] or hit_map["squirrel"][1]:
		_fail("Squirrel must have a HIGH curling tail, not the fox's pointed horizontal tail")
		return
	if hit_map["fox"][0] or not hit_map["fox"][1]:
		_fail("Fox must have a side brush tail, not the squirrel's high curling tail")
		return
	print("PASS: squirrel curls a high tail and has round ears; fox has pointed ears and a white side-tail tip")
	art.queue_free()
	await process_frame
	quit(0)

func _fail(msg: String) -> void:
	push_error("SQUIRREL FOX VISUAL TEST FAILED: "+msg)
	quit(1)
