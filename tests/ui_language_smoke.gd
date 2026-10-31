extends SceneTree
## Global bilingual button labels are reversible and persist across app launches.
const Language=preload("res://scripts/UiLanguage.gd")
const Save=preload("res://scripts/SaveData.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var root_scene=load("res://scenes/Main.tscn")
	var game=root_scene.instantiate()
	root.add_child(game)
	await process_frame
	var backup=game.progress.data.duplicate(true)
	var test_button=Button.new()
	test_button.text="返回"
	var nested=Label.new()
	nested.text="私人農場"
	test_button.add_child(nested)
	var regular=Label.new()
	regular.text="遊戲語音照舊"
	test_button.add_child(regular)
	Language.apply_to(test_button,"en")
	if test_button.text!="Back" or nested.text!="My Farm":
		_fail("English mode must translate button and nested icon-card captions")
		return
	if regular.text!="遊戲語音照舊":
		_fail("Normal narration and descriptive labels must not be translated")
		return
	Language.apply_to(test_button,"zh")
	if test_button.text!="返回" or nested.text!="私人農場":
		_fail("Switching back to Mandarin must restore every original caption")
		return
	game.progress.data["settings"]["ui_language"]="zh"
	game.show_settings()
	await process_frame
	game._set_ui_language("en")
	await process_frame
	if str(game.progress.data["settings"]["ui_language"])!="en":
		_fail("English button language did not update settings")
		return
	var settings_english=0
	for button in _buttons(game):
		if button.text=="Back":
			settings_english+=1
	if settings_english<1:
		_fail("Settings screen header must switch to Back in English")
		return
	game.show_private_farm()
	await process_frame
	game._apply_ui_language()
	var farm=game.private_farm_game
	var expected=["Bath","Play","Rest","Sound"]
	for i in range(4):
		if farm.commands.get_child(i).text!=expected[i]:
			_fail("Care action labels must be English: "+expected[i])
			return
	if farm.remove_button.text!="Remove":
		_fail("Private Farm remove button should use the English label")
		return
	game.show_home()
	await process_frame
	game._apply_ui_language()
	var english_name_found=false
	for button in _buttons(game):
		for child in button.get_children():
			if child is Label and child.text=="My Farm":
				english_name_found=true
	if not english_name_found:
		_fail("Picture-first home card captions must also translate to English")
		return
	game._set_ui_language("zh")
	await process_frame
	game.show_private_farm()
	await process_frame
	game._apply_ui_language()
	if farm!=null:
		farm=null
	if game.private_farm_game.commands.get_child(0).text!="洗澡":
		_fail("Mandarin mode must restore Chinese care labels")
		return
	if game.private_farm_game.remove_button.text!="移回圖鑑":
		_fail("Mandarin mode must restore Chinese remove label")
		return
	game.progress.data["settings"]["ui_language"]="en"
	game.progress.save()
	var loaded=Save.new()
	loaded.load_save()
	if str(loaded.data["settings"].get("ui_language",""))!="en":
		_fail("English language preference must survive saving and reload")
		return
	# Old saves without a language preference must automatically default to zh.
	loaded.data["settings"].erase("ui_language")
	loaded.save()
	var migrated=Save.new()
	migrated.load_save()
	if str(migrated.data["settings"].get("ui_language",""))!="zh":
		_fail("Old saves should migrate to Mandarin button labels without losing settings")
		return
	game.progress.data=backup
	game.progress.save()
	print("PASS: Chinese/English buttons, nested picture captions, all-park setting, private farm, persisted preference and legacy migration")
	game.queue_free()
	await process_frame
	quit(0)

func _buttons(node: Node) -> Array:
	var result=[]
	if node is Button:
		result.append(node)
	for child in node.get_children():
		result.append_array(_buttons(child))
	return result

func _fail(reason: String) -> void:
	push_error("UI LANGUAGE FAILED: "+reason)
	quit(1)
