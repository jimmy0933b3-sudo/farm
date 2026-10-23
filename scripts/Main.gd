extends Control
## A playable first version: exploration, animal interactions, three quiz mechanics,
## collecting, four care actions and automatic offline progress persistence.

const Data = preload("res://scripts/GameData.gd")
const Store = preload("res://scripts/SaveData.gd")
const AnimalArt = preload("res://scripts/AnimalArt.gd")
const ChoiceArt = preload("res://scripts/ChoiceArt.gd")
const Backdrop = preload("res://scripts/Backdrop.gd")
const Synth = preload("res://scripts/Synth.gd")

var animals: Array = []
var levels: Array = []
var progress
var sound
var screen: String = "home"
var current_zone: String = "farm"
var selected_animal: String = "cow"
var mistake_count: int = 0
var feedback_label: Label
var answer_buttons: Array = []
var adult_unlocked: bool = false

func _ready() -> void:
	animals = Data.read_array("res://data/animals.json")
	levels = Data.read_array("res://data/levels.json")
	progress = Store.new()
	progress.load_save()
	sound = Synth.new()
	sound.name = "Audio"
	add_child(sound)
	sound.enabled = bool(progress.data["settings"].get("sound", true))
	sound.speech_enabled = bool(progress.data["settings"].get("speech", true))
	var saved_screen = str(progress.data.get("last_screen","home"))
	match saved_screen:
		"farm", "forest":
			show_zone(saved_screen)
		"care":
			show_care()
		"album":
			show_album()
		_:
			show_home()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and progress != null:
		progress.save()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACK:
			get_viewport().set_input_as_handled()
			if screen == "home":
				return
			if screen == "animal" or screen == "game" or screen == "complete":
				show_zone(current_zone)
			else:
				show_home()

func _switch(name: String, bg: String = "home") -> VBoxContainer:
	sound.stop_speaking()
	screen = name
	if name in ["home","farm","forest","care","album"]:
		progress.data["last_screen"] = name
		progress.save()
	for node in get_children():
		if node != sound:
			remove_child(node)
			node.queue_free()
	var art = Backdrop.new()
	art.scene_type = bg
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(art)
	move_child(art, 0)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)
	return layout

func _label(value: String, font_size: int = 28, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, color: Color = Color("#344658")) -> Label:
	var label = Label.new()
	label.text = value
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(title: String, action: Callable, color: Color = Color("#FFF7E7"), minimum: Vector2 = Vector2(165, 66)) -> Button:
	var button = Button.new()
	button.text = title
	button.custom_minimum_size = minimum
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", Color("#344658"))
	button.add_theme_color_override("font_hover_color", Color("#344658"))
	button.add_theme_color_override("font_pressed_color", Color("#344658"))
	button.add_theme_color_override("font_focus_color", Color("#344658"))
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = Color("#EBE4D7")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(24)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	button.add_theme_stylebox_override("normal", sb)
	var hover = sb.duplicate()
	hover.bg_color = color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover)
	var pressed = sb.duplicate()
	pressed.bg_color = color.darkened(0.12)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(action)
	return button

func _header(layout: VBoxContainer, name: String, back: Callable = Callable()) -> void:
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	layout.add_child(header)
	if back.is_valid():
		header.add_child(_button("返回", back, Color("#FFFFFF"), Vector2(116, 58)))
	else:
		header.add_child(_label("✿", 34))
	var title = _label(name, 37, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_button("家長", Callable(self,"show_parent_gate"), Color("#FFFFFF"), Vector2(112, 58)))

func _spacer() -> Control:
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return spacer

func _panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#FFFDF1")
	style.set_corner_radius_all(28)
	style.set_border_width_all(3)
	style.border_color = Color("#FFFFFF")
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _animal_button(info: Dictionary, action: Callable, locked: bool = false) -> Button:
	var card = _button("", action, Color("#FFFDF3"), Vector2(165, 199))
	var column = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 8
	column.offset_top = 9
	column.offset_right = -8
	column.offset_bottom = -7
	card.add_child(column)
	var illustration = AnimalArt.new()
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illustration.setup(info)
	illustration.custom_minimum_size = Vector2(130, 139)
	illustration.size_flags_vertical = Control.SIZE_EXPAND_FILL
	illustration.modulate = Color(0.58,0.6,0.62,0.8) if locked else Color.WHITE
	column.add_child(illustration)
	column.add_child(_label("？" if locked else str(info.get("name","動物")), 24))
	return card

func _animal(id: String) -> Dictionary:
	return Data.get_animal(animals, id)

func _picture_button(item_id: String, caption: String, action: Callable, minimum: Vector2 = Vector2(242, 226)) -> Button:
	var card = _button("", action, Color("#FFFDF3"), minimum)
	var container = VBoxContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.offset_left = 10
	container.offset_top = 8
	container.offset_right = -10
	container.offset_bottom = -7
	card.add_child(container)
	var drawing = ChoiceArt.new()
	drawing.setup(item_id)
	drawing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawing.custom_minimum_size = Vector2(155, 150)
	drawing.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(drawing)
	container.add_child(_label(caption, 24))
	return card

func _narrate(message: String) -> void:
	sound.speak(message)

func _prompt_sound_later(id: String) -> void:
	await get_tree().create_timer(2.8).timeout
	if screen == "game" and selected_animal == id:
		sound.play_animal(id)

func _large_art(info: Dictionary, minimum: Vector2 = Vector2(320,320)) -> Control:
	var view = AnimalArt.new()
	view.setup(info)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.custom_minimum_size = minimum
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return view

func show_home() -> void:
	var layout = _switch("home")
	_header(layout, "動物探險島")
	layout.add_child(_label("今天想去哪裡玩？", 32))
	var row = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	layout.add_child(row)
	var places = [
		{"title":"農場樂園","sub":"認識乳牛、小豬、綿羊","zone":"farm","color":Color("#FFE7BD")},
		{"title":"森林樂園","sub":"發現兔子、狐狸、貓頭鷹","zone":"forest","color":Color("#C8EFCF")},
		{"title":"動物之家","sub":"幫小動物吃飯、洗澡","zone":"care","color":Color("#FCD9DB")},
		{"title":"動物圖鑑","sub":"收集可愛的動物貼紙","zone":"album","color":Color("#DBD9FC")}
	]
	for place in places:
		var destination = str(place["zone"])
		var outer = VBoxContainer.new()
		outer.add_theme_constant_override("separation", 12)
		row.add_child(outer)
		outer.add_child(_picture_button(destination,str(place["title"]), Callable(self, "_go").bind(destination),Vector2(271,195)))
		outer.add_child(_label(str(place["sub"]), 18))
	var count = int(progress.data["collected"].size())
	layout.add_child(_label("已認識 %d / 12 位動物朋友    每天都可以自由探索！" % count, 25))
	_narrate("歡迎來到動物探險島！看看圖片，點農場、森林或動物之家，就可以開始玩！")

func _go(where: String) -> void:
	match where:
		"farm", "forest":
			show_zone(where)
		"care":
			show_care()
		"album":
			show_album()

func show_zone(zone: String) -> void:
	current_zone = zone
	var layout = _switch(zone, zone)
	_header(layout, "農場樂園" if zone == "farm" else "森林樂園", Callable(self,"show_home"))
	layout.add_child(_label("點一下動物，認識新朋友吧！", 28))
	var panel = _panel()
	layout.add_child(panel)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	panel.add_child(grid)
	for info in animals:
		if str(info.get("zone","")) == zone:
			grid.add_child(_animal_button(info, Callable(self,"show_animal").bind(str(info["id"]))))
	layout.add_child(_label("小提示：所有動物都可以反覆點擊、聽聲音和玩遊戲。", 22))
	_narrate("這裡是%s。用手指點一隻動物，和牠交朋友吧！" % ("農場" if zone == "farm" else "森林"))

func show_animal(id: String) -> void:
	var info = _animal(id)
	if info.is_empty():
		show_home()
		return
	selected_animal = id
	current_zone = str(info["zone"])
	progress.unlock(id)
	var layout = _switch("animal",current_zone)
	_header(layout, str(info["name"]) + " 來啦！", Callable(self,"show_zone").bind(current_zone))
	var main = HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(main)
	var panel = _panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(panel)
	panel.add_child(_large_art(info,Vector2(380,390)))
	var side = VBoxContainer.new()
	side.custom_minimum_size = Vector2(465,0)
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	side.add_theme_constant_override("separation", 18)
	main.add_child(side)
	side.add_child(_label(str(info.get("desc","")), 28))
	side.add_child(_button("聽動物叫聲" if sound.has_natural_sound(id) else "聽聽動物介紹", Callable(self,"_play_animal").bind(id), Color("#F9E3B9")))
	side.add_child(_button("摸摸牠", Callable(self,"_pet").bind(id), Color("#F9DCE1")))
	side.add_child(_button("一起玩小遊戲", Callable(self,"show_game").bind(id), Color("#D5EEDD")))
	if bool(info.get("care",false)):
		side.add_child(_button("去動物之家照顧牠", Callable(self,"show_care").bind(id), Color("#DFE9FF")))
	side.add_child(_label("認識動物後，已自動加入圖鑑。", 20))
	_narrate("你好！我是%s。%s 你可以摸摸我、聽聽聲音，或玩小遊戲。" % [str(info["name"]),str(info["desc"])])

func _play_animal(id: String) -> void:
	if bool(progress.data["settings"].get("sound",true)):
		sound.play_animal(id)

func _pet(id: String) -> void:
	_play_animal(id)
	# A happy pose is temporary, next page returns to idle.
	for child in get_children():
		if child is MarginContainer:
			_set_mood_recursive(child)

func _set_mood_recursive(node: Node) -> void:
	if node is AnimalArt:
		node.mood = "happy"
		node.queue_redraw()
	for child in node.get_children():
		_set_mood_recursive(child)

func show_game(animal_id: String) -> void:
	var level = Data.get_level(levels, animal_id)
	if level.is_empty():
		show_zone(current_zone)
		return
	selected_animal = animal_id
	mistake_count = 0
	_render_game(level)

func _render_game(level: Dictionary) -> void:
	var layout = _switch("game",current_zone)
	_header(layout, "動物小遊戲", Callable(self,"show_animal").bind(selected_animal))
	var kind = str(level["type"])
	var prompt = str(level["prompt"])
	if kind == "sound":
		prompt = "聽一聽，找出是哪隻動物！"
	if kind == "habitat":
		prompt = "看看圖片，幫動物找家！"
	if kind == "food":
		prompt = "看看圖片，選適合動物的食物！"
	layout.add_child(_label(prompt, 29))
	var replay = _button("再聽一次" if kind != "sound" else "再聽叫聲", Callable(self, "_repeat_game_prompt").bind(level),Color("#FFE7BD"),Vector2(210,60))
	replay.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(replay)
	if kind == "sound":
		_narrate("仔細聽一聽，這是誰的聲音？看看圖片，點出正確的動物。")
		_prompt_sound_later.call_deferred(str(level["animal"]))
	else:
		_narrate(prompt)
	var opts = HBoxContainer.new()
	opts.size_flags_vertical = Control.SIZE_EXPAND_FILL
	opts.alignment = BoxContainer.ALIGNMENT_CENTER
	opts.add_theme_constant_override("separation",24)
	layout.add_child(opts)
	answer_buttons.clear()
	for value in level["options"]:
		var option = str(value)
		var button: Button
		if kind == "sound":
			button = _animal_button(_animal(option), Callable(self,"_answer").bind(option,level))
		else:
			var shown = option
			if kind == "habitat":
				shown = {"farm":"農場","forest":"森林","ocean":"海洋"}.get(option,option)
			button = _picture_button(option,shown,Callable(self,"_answer").bind(option,level))
		opts.add_child(button)
		answer_buttons.append(button)
	feedback_label = _label("看看圖案，慢慢選！",25)
	layout.add_child(feedback_label)

func _repeat_game_prompt(level: Dictionary) -> void:
	if str(level["type"]) == "sound":
		_play_animal(str(level["animal"]))
	else:
		_narrate(str(level["prompt"]))

func _answer(choice: String, level: Dictionary) -> void:
	if choice == str(level["answer"]):
		for b in answer_buttons:
			b.disabled = true
		if bool(progress.data["settings"].get("sound",true)):
			sound.play_good()
		progress.complete(int(level["id"]), str(level["animal"]))
		show_complete(level)
	else:
		mistake_count += 1
		if bool(progress.data["settings"].get("sound",true)):
			sound.play_try_again()
		if mistake_count >= 2:
			feedback_label.text = "再試試看！答案會發亮！"
			var correct_idx = level["options"].find(level["answer"])
			if correct_idx >= 0 and correct_idx < answer_buttons.size():
				answer_buttons[correct_idx].modulate = Color("#96F4A8")
			_narrate("看一看，亮亮的圖片就是提示，點點看！")
		else:
			feedback_label.text = "沒關係，我們再試一次！"

func _answer_name(value: String) -> String:
	var info = _animal(value)
	if not info.is_empty():
		return str(info["name"])
	return str({"farm":"農場","forest":"森林","ocean":"海洋"}.get(value,value))

func show_complete(level: Dictionary) -> void:
	var layout = _switch("complete",current_zone)
	_header(layout, "完成了！", Callable(self,"show_zone").bind(current_zone))
	layout.add_child(_spacer())
	layout.add_child(_label("恭喜認識「%s」！" % _answer_name(str(level["animal"])), 42))
	layout.add_child(_label("獲得一張可愛的動物貼紙", 30))
	var art = _large_art(_animal(str(level["animal"])),Vector2(245,245))
	art.set("mood", "happy")
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	layout.add_child(art)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",18)
	layout.add_child(row)
	row.add_child(_button("再玩一次",Callable(self,"show_game").bind(str(level["animal"]))))
	row.add_child(_button("回樂園",Callable(self,"show_zone").bind(current_zone),Color("#D9EECF")))
	layout.add_child(_spacer())
	_narrate("答對了！你得到%s的動物貼紙！再玩一次，或是回到樂園。" % _answer_name(str(level["animal"])))

func show_album() -> void:
	var layout = _switch("album")
	_header(layout,"我的動物圖鑑",Callable(self,"show_home"))
	layout.add_child(_label("已收集 %d / %d 張動物貼紙" % [int(progress.data["collected"].size()),animals.size()],29))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",18)
	scroll.add_child(grid)
	for info in animals:
		var is_collected = progress.data["collected"].has(str(info["id"]))
		var callback: Callable = Callable(self,"show_animal").bind(str(info["id"])) if is_collected else Callable(self,"_locked")
		grid.add_child(_animal_button(info,callback,not is_collected))
	layout.add_child(_label("探索時點擊動物，就能找到更多朋友！",21))
	_narrate("這是你的動物圖鑑。亮亮的貼紙，是你認識過的動物朋友。")

func _locked() -> void:
	# Locked stickers are intentionally non-destructive.
	pass

func show_care(id: String = "") -> void:
	if id != "":
		selected_animal = id
	var info = _animal(selected_animal)
	if info.is_empty() or not bool(info.get("care",false)):
		selected_animal = "cow"
		info = _animal(selected_animal)
	var layout = _switch("care","farm")
	_header(layout,"動物之家",Callable(self,"show_home"))
	var tabs = HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation",12)
	layout.add_child(tabs)
	for animal in animals:
		if bool(animal.get("care",false)):
			var aid = str(animal["id"])
			tabs.add_child(_button(str(animal["name"]),Callable(self,"show_care").bind(aid),Color("#D9F2D9") if aid == selected_animal else Color("#FFFDF1"),Vector2(150,58)))
	var center = HBoxContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation",20)
	layout.add_child(center)
	var photo = _panel()
	photo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(photo)
	photo.add_child(_large_art(info,Vector2(370,360)))
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",14)
	center.add_child(right)
	right.add_child(_label("今天也來照顧「%s」吧！" % info["name"],29))
	var stats = progress.care_stats(selected_animal)
	for pair in [["food","飽足"],["clean","清潔"],["happy","開心"]]:
		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(360,34)
		bar.value = float(stats[pair[0]])
		bar.show_percentage = false
		right.add_child(_label(str(pair[1]),21,HORIZONTAL_ALIGNMENT_LEFT))
		right.add_child(bar)
	var actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",10)
	layout.add_child(actions)
	for item in [["feed","餵食"],["wash","洗澡"],["play","玩耍"],["sleep","休息"]]:
		actions.add_child(_picture_button(str(item[0]),str(item[1]),Callable(self,"_care_action").bind(str(item[0])),Vector2(220,115)))
	layout.add_child(_label("小動物不會因為沒玩而挨餓，請放心慢慢陪伴牠。",21))
	_narrate("歡迎來到動物之家！可以點餵食、洗澡、玩耍，或休息的圖片照顧%s。" % str(info["name"]))

func _care_action(action: String) -> void:
	progress.care_for(selected_animal,action)
	if bool(progress.data["settings"].get("sound",true)):
		sound.play_good()
	show_care(selected_animal)

func show_parent_gate() -> void:
	if adult_unlocked:
		show_settings()
		return
	var layout = _switch("gate")
	_header(layout,"家長專區",Callable(self,"show_home"))
	layout.add_child(_spacer())
	layout.add_child(_label("請家長回答：8 + 5 = ?",37))
	var entry = LineEdit.new()
	entry.placeholder_text = "請輸入答案"
	entry.max_length = 3
	entry.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	entry.custom_minimum_size = Vector2(320,65)
	entry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(entry)
	var warning = _label("",23)
	layout.add_child(warning)
	layout.add_child(_button("確認",func() -> void:
		if entry.text.strip_edges() == "13":
			adult_unlocked = true
			show_settings()
		else:
			warning.text = "答案還不對喔！"))
	layout.add_child(_spacer())

func show_settings() -> void:
	var layout = _switch("settings")
	_header(layout,"家長設定",Callable(self,"show_home"))
	var settings: Dictionary = progress.data["settings"]
	for item in [["sound","動物音效"],["speech","中文語音引導"],["reduce_motion","降低動畫強度"]]:
		var key = str(item[0])
		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation",20)
		layout.add_child(row)
		row.add_child(_label(str(item[1]),28))
		row.add_child(_button("開啟" if bool(settings.get(key,false)) else "關閉", Callable(self,"_toggle").bind(key),Color("#FDEBD3")))
	layout.add_child(_label("資料會保存在本機。沒有廣告，也不需要登入。",23))
	layout.add_child(_spacer())

func _toggle(key: String) -> void:
	progress.toggle_setting(key)
	sound.enabled = bool(progress.data["settings"].get("sound",true))
	sound.speech_enabled = bool(progress.data["settings"].get("speech",true))
	show_settings()
