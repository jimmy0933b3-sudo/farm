extends SceneTree
## Monster park end-to-end regression: find -> save -> interact -> gallery -> kart.
const MonsterArt=preload("res://scripts/MonsterArt.gd")
const SaveStore=preload("res://scripts/SaveData.gd")
const Rules=preload("res://scripts/RaceRules.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var main=load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var backup: Dictionary=main.progress.data.duplicate(true)
	if main.monsters.size()!=12:
		_fail("Monster catalog must contain exactly twelve unique friends")
		return
	var ids={}
	for info in main.monsters:
		var id=str(info.get("id",""))
		if ids.has(id) or str(info.get("zone",""))!="monster":
			_fail("Monster IDs must be unique and separate from animals")
			return
		ids[id]=true
	main.show_monster_world()
	await process_frame
	if main.screen!="monster_world" or main.monster_game.monster_buttons.size()!=4:
		_fail("Monster park must open with four clickable rainbow-forest friends")
		return
	var world=main.monster_game
	for area in ["rainbow","candy","sky"]:
		world.choose_zone(area)
		await process_frame
		if world.monster_buttons.size()!=4:
			_fail("Monster area "+area+" must have exactly four different friends")
			return
	world.choose_zone("rainbow")
	world.discover("monster_fire")
	await process_frame
	if not main.progress.data["monster_found"].has("monster_fire") or not main.progress.data["collected"].has("monster_fire"):
		_fail("Finding a monster must unlock it in the shared collection")
		return
	world.play("ability")
	if world.power_fx==null or world.power_fx.monster_id!="monster_fire":
		_fail("Monster ability must trigger a visible original visual effect")
		return
	if int(main.progress.data["monster_plays"].get("monster_fire",0))<1:
		_fail("Monster ability play count is not saved")
		return
	var copy=SaveStore.new()
	copy.load_save()
	if not copy.data.get("monster_found",[]).has("monster_fire"):
		_fail("Monster collection was not persisted to disk")
		return
	main.show_monster_album()
	await process_frame
	if main.screen!="monster_album" or main.monster_album.monsters.size()!=12:
		_fail("Monster gallery must display all twelve friends")
		return
	main.show_race_lobby(true)
	await process_frame
	if main.screen!="race_lobby" or not main.race_lobby.monsters_only_mode:
		_fail("Monster kart lobby must open in monster-only mode")
		return
	var lobby=main.race_lobby
	if lobby.track_previews.size()!=Rules.TRACKS.size() or Rules.TRACKS.size()!=5:
		_fail("Both new monster race tracks must have track preview cards")
		return
	lobby.choose_filter(false)
	if not lobby.options.any(func(info): return str(info.get("id",""))=="monster_fire"):
		_fail("Collected monsters must appear among all unlocked kart racers")
		return
	lobby.choose_filter(true)
	lobby.choose_animal("monster_fire")
	lobby.choose_track("cosmic")
	lobby.start()
	await process_frame
	if main.screen!="race_game" or str(main.race_game.race_track.get("id",""))!="cosmic":
		_fail("Star-sky monster race did not start")
		return
	var kart=main.race_game.player_kart
	if not kart.avatar is MonsterArt:
		_fail("Monster karts must use distinct monster artwork, not an animal fallback")
		return
	if main.race_game.track.track_id!="cosmic":
		_fail("Star-sky track visuals were lost")
		return
	main.progress.data=backup
	main.progress.save()
	main.show_monster_world()
	await process_frame
	if main.screen!="monster_world":
		_fail("Race navigation cannot return to monster world")
		return
	print("PASS: 12 original monsters, three habitats, saved discovery, ability, gallery and cross-roster monster kart on five tracks")
	main.queue_free()
	await process_frame
	quit(0)

func _fail(reason: String) -> void:
	push_error("MONSTER PARK FAILED: "+reason)
	quit(1)
