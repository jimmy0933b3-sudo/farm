extends SceneTree
## Check the ACTUAL text passed to Mandarin TTS in headless Godot.
## Every insect species should be called 昆蟲 in its zone, quiz, reward and
## care instructions. Animal screens must still say 動物.
const ALL_BUGS=["rhinoceros_beetle","stag_beetle","butterfly","ladybug","bee","mantis","dung_beetle","weevil"]

func _initialize() -> void:
	call_deferred("_run")

func _said(sound: Node, expected: String, disallowed: String = "") -> bool:
	var actual: String=sound.last_spoken_text
	return actual.contains(expected) and (disallowed.is_empty() or not actual.contains(disallowed))

func _has_button(node: Node, caption: String) -> bool:
	if node is Button and (node as Button).text==caption:
		return true
	for child in node.get_children():
		if _has_button(child,caption):
			return true
	return false

func _run() -> void:
	var game=load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var store=game.progress
	var backup=store.data.duplicate(true)
	var sound=game.sound
	game.show_zone("insect")
	await process_frame
	if not _said(sound,"點一隻昆蟲","點一隻動物"):
		_fail("Insect park speaks about animals: "+sound.last_spoken_text)
		return
	for id in ALL_BUGS:
		var info=game._animal(id)
		if str(info.get("zone",""))!="insect":
			_fail("Test insect missing from data: "+id)
			return
		game.show_animal(id,"insect")
		await process_frame
		if not _said(sound,str(info["name"])):
			_fail("Insect description missing correct name: "+id)
			return
		if not _has_button(game,"聽聽昆蟲介紹"):
			_fail("Insect detail button incorrectly advertises animal sound: "+id)
			return
		game._pet(id)
		if not _said(sound,"昆蟲身上","動物身上"):
			_fail("Insect petting narration refers to animal: "+id)
			return
		game.show_game(id)
		await process_frame
		var level=game.levels.filter(func(x): return str(x.get("animal",""))==id)[0]
		if not _said(sound,str(level["prompt"])) or sound.last_spoken_text.contains("適合動物"):
			_fail("Insect quiz uses incorrect prompt: "+id+": "+sound.last_spoken_text)
			return
		game._repeat_game_prompt(level)
		if not _said(sound,str(level["prompt"])):
			_fail("Replay of insect question lost the correct prompt: "+id)
			return
		game._answer(str(level["answer"]),level)
		await process_frame
		if game.screen!="complete" or not _said(sound,"昆蟲貼紙","動物貼紙"):
			_fail("Insect reward narration uses animal sticker: "+id+": "+sound.last_spoken_text)
			return
		if not _has_label(game,"獲得一張可愛的昆蟲貼紙"):
			_fail("Insect reward visual label still says animal: "+id)
			return
	game.show_insect_complete()
	await process_frame
	if not _said(sound,"八位昆蟲朋友") or sound.last_spoken_text.contains("駱駝") or sound.last_spoken_text.contains("河馬"):
		_fail("Insect adventure completion still plays zoo dialogue: "+sound.last_spoken_text)
		return
	game.show_album()
	await process_frame
	if not _said(sound,"動物和昆蟲朋友"):
		_fail("Shared album forgot insect friends")
		return
	game.show_coloring()
	await process_frame
	if not _said(sound,"幫昆蟲上色"):
		_fail("Coloring instructions omit insects")
		return
	game.coloring_game.select_animal("stag_beetle")
	if not _said(sound,"鍬形蟲"):
		_fail("Coloring selection did not name the selected insect")
		return
	game.coloring_game.repeat_guide()
	if sound.last_spoken_text.contains("按住動物"):
		_fail("Coloring guide still mislabels insects")
		return
	game.show_drawing()
	await process_frame
	if not _said(sound,"昆蟲也可以畫"):
		_fail("Drawing academy intro is animal-only")
		return
	game.drawing_game.select_animal("mantis")
	game.drawing_game.choose_tool("star")
	if not _said(sound,"這位朋友的輪廓","動物的輪廓"):
		_fail("Insect drawing tool still says animal outline")
		return
	game.show_private_farm()
	await process_frame
	if not _said(sound,"螳螂、糞金龜和象鼻蟲在草地"):
		_fail("Farm introduction still claims every insect flies")
		return
	var farm=game.private_farm_game
	for id in ["bee","mantis","dung_beetle"]:
		farm.place_animal(id)
		if not _said(sound,str(game._animal(id)["name"])):
			_fail("Farm insect welcome speech mislabels "+id)
			return
		farm._set_resident(id,true)
		if not _said(sound,str(game._animal(id)["name"])):
			_fail("Farm selected insect speech mislabels "+id)
			return
	# Non-insect animals must retain their existing terminology.
	game.show_zone("farm")
	if not _said(sound,"點一隻動物","點一隻昆蟲"):
		_fail("Farm park speech incorrectly changed to insect terminology")
		return
	game.show_game("pig")
	if not _said(sound,"適合動物的食物"):
		_fail("Animal quiz lost original animal wording")
		return
	var pig_level=game.levels.filter(func(x): return str(x.get("animal",""))=="pig")[0]
	game._answer(str(pig_level["answer"]),pig_level)
	if not _said(sound,"動物貼紙","昆蟲貼紙"):
		_fail("Animal reward incorrectly says insect sticker")
		return
	store.data=backup
	store.save()
	print("PASS: eight insects and normal animals; insect narration for park, pet, games, repeat, reward, adventure, album, coloring, drawing and farm")
	game.queue_free()
	await process_frame
	quit(0)

func _has_label(node: Node, caption: String) -> bool:
	if node is Label and (node as Label).text.contains(caption):
		return true
	for child in node.get_children():
		if _has_label(child,caption):
			return true
	return false

func _fail(why: String) -> void:
	push_error("INSECT NARRATION FAILED: "+why)
	quit(1)
