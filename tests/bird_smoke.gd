extends SceneTree
## Eight bird species -> two habitat discovery -> album -> flight contest -> saved result.
const BirdArt=preload("res://scripts/BirdArt.gd")
const Store=preload("res://scripts/SaveData.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var main=load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var previous: Dictionary=main.progress.data.duplicate(true)
	if main.birds.size()!=8:
		_fail("Expected eight original birds")
		return
	var expected=["鴛鴦","小水鴨","八哥","麻雀","水雉","五色鳥","夜鷺","家燕"]
	var ids: Dictionary={}
	for index in range(main.birds.size()):
		var bird: Dictionary=main.birds[index]
		if str(bird.get("name",""))!=expected[index] or str(bird.get("zone",""))!="bird":
			_fail("Bird catalog has incorrect species or names: "+str(index))
			return
		if ids.has(str(bird["id"])):
			_fail("Duplicate bird ID")
			return
		ids[str(bird["id"])]=true
	main.show_home()
	await process_frame
	main._go("bird")
	await process_frame
	if main.screen!="bird_world" or main.bird_world.bird_buttons.size()!=4:
		_fail("Bird World must appear from the home menu with four wetland birds")
		return
	var world=main.bird_world
	for habitat in ["wetland","woodland"]:
		world.choose_area(habitat)
		await process_frame
		if world.bird_buttons.size()!=4 or world.scenery.habitat!=habitat:
			_fail("Two bird habitats must each render four species")
			return
	world.choose_area("wetland")
	world.discover("bird_mandarin")
	if not main.progress.data["bird_found"].has("bird_mandarin") or not main.progress.data["collected"].has("bird_mandarin"):
		_fail("Discovering a bird must save a sticker and count as collected")
		return
	world.interact("flap")
	if world.flap_time<=0.0 or int(main.progress.data["bird_interactions"].get("bird_mandarin",0))<1:
		_fail("Touching bird controls must animate wings and persist interaction")
		return
	var reload=Store.new()
	reload.load_save()
	if not reload.data.get("bird_found",[]).has("bird_mandarin"):
		_fail("Bird collection lost after save/reload")
		return
	main.show_bird_album()
	await process_frame
	if main.screen!="bird_album" or main.bird_album.birds.size()!=8:
		_fail("Bird album must show all eight entries")
		return
	main.show_bird_flight_lobby()
	await process_frame
	if main.screen!="bird_flight_lobby":
		_fail("Bird race lobby did not open")
		return
	var lobby=main.bird_flight_lobby
	if lobby.COURSES.size()!=2 or lobby.options.size()<1:
		_fail("Two real flight courses or a beginner racer are missing")
		return
	lobby.select_bird("bird_mandarin")
	lobby.choose_course("forest")
	lobby.start()
	await process_frame
	if main.screen!="bird_flight_game":
		_fail("Bird flight race did not start")
		return
	var race=main.bird_flight_game
	if race.course_id!="forest" or race.rival_birds.size()!=3 or not race.my_bird is BirdArt:
		_fail("Sky race must render four birds and preserve chosen route")
		return
	# World items approach from the right: all racers must face their direction
	# of travel, while ordinary encyclopedia portraits remain unchanged.
	if not race.my_bird.facing_right or race.my_bird.horizontal_draw_scale()!=-1.0:
		_fail("Player bird must face right when the sky race moves forward")
		return
	for rival in race.rival_birds:
		if not rival.facing_right or rival.horizontal_draw_scale()!=-1.0:
			_fail("AI birds must face the same direction of travel as the player")
			return
	var encyclopedia_bird=BirdArt.new()
	encyclopedia_bird.setup(main.birds[0])
	if encyclopedia_bird.facing_right or encyclopedia_bird.horizontal_draw_scale()!=1.0:
		_fail("Bird portraits outside the race must retain their original facing")
		return
	if race.track.course!="forest" or race.track.lane_y(0)>=race.track.lane_y(1):
		_fail("Three altitude lanes need distinct layout")
		return
	race.countdown=0.0
	race.move_altitude(-1)
	if race.lane!=0:
		_fail("Up button must change altitude")
		return
	race.move_altitude(1)
	if race.lane!=1:
		_fail("Down button must change altitude")
		return
	race.boost()
	if race.boost_time<=0.0 or race.boost_cooldown<=0.0:
		_fail("Boost button must work and cool down")
		return
	race._apply_swipe(race.start_touch+Vector2(0,-80))
	if race.lane!=0:
		_fail("Swipe up must fly upward")
		return
	race.move_altitude(1)
	race.distance=race.FINISH_DISTANCE-1.0
	race._process(.1)
	await process_frame
	if main.screen!="bird_flight_result":
		_fail("Bird finish must show result screen")
		return
	if int(main.progress.data.get("bird_flight_totals",{}).get("races",0))!=int(previous.get("bird_flight_totals",{}).get("races",0))+1:
		_fail("Flight results must be recorded separately from kart races")
		return
	if main.progress.data["private_farm"]!=previous["private_farm"]:
		_fail("Bird racing must not modify farm residents")
		return
	main.progress.data=previous
	main.progress.save()
	main.show_bird_world()
	await process_frame
	if main.screen!="bird_world":
		_fail("Flight results cannot navigate back to Bird World")
		return
	print("PASS: 8 unique birds, two habitats, discovery, bird gallery, 4-player sky flight, controls, two courses and saved result")
	main.queue_free()
	await process_frame
	quit(0)

func _fail(message: String) -> void:
	push_error("BIRD WORLD SMOKE FAIL: "+message)
	quit(1)
