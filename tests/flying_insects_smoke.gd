extends SceneTree
## Flying insects use sky bounds and remain selectable. The two beetles must
## not share the same top-of-head silhouette when drawn or finger-colored.
const Art=preload("res://scripts/AnimalArt.gd")

func _initialize() -> void:
	call_deferred("_run")

func _screen(view: Control, point: Vector2) -> Vector2:
	var factor=minf(view.size.x/220.0,view.size.y/220.0)
	return Vector2(view.size.x*.5,view.size.y*.52)+point*factor

func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var progress=game.progress
	var snapshot=progress.data.duplicate(true)
	var insects=["rhinoceros_beetle","stag_beetle","butterfly","ladybug","bee"]
	var starters=["cow","seal","mantis","dung_beetle"]
	progress.data["collected"]=(starters+insects).duplicate()
	progress.data["private_farm"]=[]
	progress.save()
	game.show_private_farm()
	await process_frame
	await process_frame
	var farm=game.private_farm_game
	for id in starters+insects:
		farm.place_animal(id)
	await process_frame
	await process_frame
	if farm.actors.size()!=9:
		_fail("Mixed water grass and insect residents missing")
		return
	var cow=farm.actors["cow"]
	var seal=farm.actors["seal"]
	var mantis=farm.actors["mantis"]
	var dung=farm.actors["dung_beetle"]
	if cow.get("is_flying") or seal.get("is_flying") or mantis.get("is_flying") or dung.get("is_flying"):
		_fail("Original ground and pond residents must not fly")
		return
	if cow.roaming_bounds.position.y<farm.habitat.size.y*.45:
		_fail("Cow no longer lives in grass")
		return
	if seal.roaming_bounds.position.y<farm.habitat.size.y*.45:
		_fail("Seal no longer lives in pond")
		return
	if not dung.pushes_dung or mantis.pushes_dung or dung.size.x<=mantis.size.x:
		_fail("Dung beetle must roll a ball; mantis should crawl")
		return
	if mantis.roaming_bounds!=cow.roaming_bounds or dung.roaming_bounds!=cow.roaming_bounds:
		_fail("Mantis and dung beetle should crawl in grass")
		return
	var roll_before: float=dung.avatar.dung_ball_angle
	dung.idle_timer=0.0
	dung.destination=dung._clamp_to_field(dung.position+Vector2(90,0))
	dung._process(0.7)
	if dung.avatar.dung_ball_angle<=roll_before:
		_fail("Dung ball did not rotate when beetle moved")
		return
	dung.perform("sleep")
	roll_before=dung.avatar.dung_ball_angle
	dung._process(0.3)
	if absf(dung.avatar.dung_ball_angle-roll_before)>0.001:
		_fail("Dung ball should stop rolling when beetle sleeps")
		return
	dung.reaction_time=0.0
	dung.reaction_action=""
	var centers=[]
	for id in insects:
		var actor=farm.actors[id]
		if not actor.is_flying:
			_fail("Flying insect flag was ignored: "+id)
			return
		var area: Rect2=actor.roaming_bounds
		if area.end.y>farm.habitat.size.y*.47 or area.position.y>=cow.roaming_bounds.position.y:
			_fail("Flying insect not fully confined to sky: "+id)
			return
		if actor.position.y<area.position.y-1 or actor.position.y+actor.size.y>area.end.y+1:
			_fail("Insect starts outside sky: "+id)
			return
		for center in centers:
			if actor.position.distance_to(center)<actor.size.x*1.05:
				_fail("Two insect sprites overlap at their initial position")
				return
		centers.append(actor.position)
		actor.idle_timer=0.0
		actor.destination=actor._clamp_to_field(actor.position+Vector2(70,20))
		var before=actor.position
		actor._process(0.55)
		if before.distance_to(actor.position)<2.0:
			_fail("Insect does not fly independently: "+id)
			return
		farm.focus_resident(id)
		var touch=actor.position+actor.size*.5
		if not farm._start_touch(touch):
			_fail("Insect not touchable in the sky: "+id)
			return
		farm._move_touch(touch+Vector2(23,0))
		farm._move_touch(touch)
		if actor.strokes<1:
			_fail("Flying insect lost stroking reactions: "+id)
			return
		farm._finish_touch()
		if not actor.perform("feed"):
			_fail("Flying insect lost care actions: "+id)
			return
		actor.reaction_time=0.0
		actor.reaction_action=""
		actor.is_touched=false
	var infos={}
	for a in game.animals:
		infos[str(a["id"])]=a
	var artist=Art.new()
	artist.size=Vector2(440,440)
	root.add_child(artist)
	await process_frame
	var silhouettes=[]
	for id in ["rhinoceros_beetle","stag_beetle"]:
		artist.setup(infos[id])
		artist.set_coloring(true,{})
		await process_frame
		if artist.get_coloring_regions().size()<7:
			_fail("Beetle paintable pieces missing: "+id)
			return
		var top=artist.color_region_at(_screen(artist,Vector2(0,-111)))!=""
		var left=artist.color_region_at(_screen(artist,Vector2(-83,-112)))!=""
		var right=artist.color_region_at(_screen(artist,Vector2(83,-112)))!=""
		silhouettes.append([top,left,right])
	if silhouettes[0]==silhouettes[1]:
		_fail("Beetles still have indistinguishable horns/mandibles")
		return
	if not silhouettes[0][0] or silhouettes[0][1] or silhouettes[0][2]:
		_fail("Rhinoceros beetle requires one tall CENTRAL horn")
		return
	if silhouettes[1][0] or not silhouettes[1][1] or not silhouettes[1][2]:
		_fail("Stag beetle requires two OUTWARD pincers")
		return
	progress.data=snapshot
	progress.save()
	print("PASS: nine mixed residents, five flyers and two crawlers in sky, motion, touch, petting, care, beetle silhouettes, preserved save")
	game.queue_free()
	artist.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error("FLYING INSECTS TEST FAILED: "+message)
	quit(1)
