extends Control
## A playable first version: exploration, animal interactions, three quiz mechanics,
## collecting, four care actions and automatic offline progress persistence.

const Data = preload("res://scripts/GameData.gd")
const Store = preload("res://scripts/SaveData.gd")
const AnimalArt = preload("res://scripts/AnimalArt.gd")
const PettingArea = preload("res://scripts/PettingArea.gd")
const PrivateFarm = preload("res://scripts/PrivateFarm.gd")
const ColoringRoom = preload("res://scripts/ColoringRoom.gd")
const DrawingStudio = preload("res://scripts/DrawingStudio.gd")
const ForestDiscovery = preload("res://scripts/ForestDiscovery.gd")
const OceanDiscovery = preload("res://scripts/OceanDiscovery.gd")
const ZooDiscovery = preload("res://scripts/ZooDiscovery.gd")
const InsectDiscovery = preload("res://scripts/InsectDiscovery.gd")
const TouchAnimalScroll = preload("res://scripts/TouchAnimalScroll.gd")
const CareStage = preload("res://scripts/CareStage.gd")
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
var petting_area: Control
var care_stage: Control
var care_bars: Dictionary = {}
var care_feedback: Label
var care_action_buttons: Array = []
var care_intro_count: int = 0
var forest_game: Control
var ocean_game: Control
var zoo_game: Control
var insect_game: Control
var private_farm_game: Control
var coloring_game: Control
var drawing_game: Control
var settings_scroll: ScrollContainer
var parent_scroll_y: int=0

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
		"farm", "forest", "zoo", "insect", "ocean_park":
			show_zone("ocean" if saved_screen=="ocean_park" else saved_screen)
		"care":
			show_care()
		"album":
			show_album()
		"private_farm":
			show_private_farm()
		"coloring":
			show_coloring()
		"drawing":
			show_drawing()
		"forest_explore":
			show_forest_search()
		"forest_search":
			show_forest_search()
		"zoo_search":
			show_zoo_search()
		"insect_search":
			show_insect_search()
		"ocean", "ocean_search":
			show_ocean_search()
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
			if screen in ["animal","game","complete"]:
				show_zone(current_zone)
			elif screen in ["forest_search","forest_done"]:
				show_zone("forest")
			elif screen in ["ocean_search","ocean_done"]:
				show_zone("ocean")
			elif screen in ["zoo_search","zoo_done"]:
				show_zone("zoo")
			elif screen in ["insect_search","insect_done"]:
				show_zone("insect")
			else:
				show_home()

func _switch(name: String, bg: String = "home") -> VBoxContainer:
	sound.stop_speaking()
	screen = name
	if name in ["home","farm","forest","zoo","insect","insect_search","care","album","forest_search","private_farm","coloring","drawing","ocean_search","ocean_park","zoo_search"]:
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
		margin.add_theme_constant_override("margin_" + side, 20)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
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
	sb.border_color = Color("#FFFFFF")
	sb.set_border_width_all(2)
	sb.shadow_color = Color("#264D59",0.15)
	sb.shadow_size = 5
	sb.anti_aliasing = true
	sb.set_corner_radius_all(24)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	button.add_theme_stylebox_override("normal", sb)
	var hover = sb.duplicate()
	hover.bg_color = color.lightened(0.14)
	hover.shadow_size = 8
	button.add_theme_stylebox_override("hover", hover)
	var pressed = sb.duplicate()
	pressed.bg_color = color.darkened(0.09)
	pressed.shadow_size = 2
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if action.is_valid():
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
	var title = _label(name, 36, HORIZONTAL_ALIGNMENT_LEFT, Color("#28554D"))
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
	style.bg_color = Color("#FFFEF8",0.97)
	style.set_corner_radius_all(26)
	style.set_border_width_all(3)
	style.border_color = Color("#FFFFFF")
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.shadow_color = Color("#42696E",0.12)
	style.shadow_size = 7
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _animal_button(info: Dictionary, action: Callable, locked: bool = false, scroll: ScrollContainer = null) -> Button:
	var card = _button("", action if scroll==null else Callable(), Color("#F0F8E9") if str(info.get("zone",""))=="farm" else (Color("#EDF6E5") if str(info.get("zone",""))=="forest" else Color("#E6F7FC")), Vector2(165, 199))
	if scroll!=null:
		scroll.wire_button(card,action)
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

func _is_insect(id: String) -> bool:
	return str(_animal(id).get("zone",""))=="insect"

func _friend_word(id: String) -> String:
	return "昆蟲" if _is_insect(id) else "動物"

func _game_prompt(level: Dictionary) -> String:
	var id=str(level.get("animal",""))
	var kind=str(level.get("type",""))
	match kind:
		"sound":
			return "聽一聽，找出是哪隻%s！" % _friend_word(id)
		"habitat":
			return "看看圖片，幫%s找家！" % _friend_word(id)
		"food":
			return str(level.get("prompt","看看圖片，選適合昆蟲的食物！")) if _is_insect(id) else "看看圖片，選適合動物的食物！"
		_:
			return str(level.get("prompt",""))

func _picture_button(item_id: String, caption: String, action: Callable, minimum: Vector2 = Vector2(242, 226), scroll: ScrollContainer = null) -> Button:
	var color_choices={
		"farm":Color("#E6F4D2"),"forest":Color("#DDF1DE"),"zoo":Color("#FFE8C3"),"insect":Color("#E4F6D9"),"insect_search":Color("#E9F8C9"),
		"ocean_park":Color("#D7F0FA"),"private_farm":Color("#F7EAD7"),
		"coloring":Color("#F6E5F7"),"drawing":Color("#E7ECFF"),"care":Color("#FDECD5"),
		"album":Color("#F1E3CE"),"forest_explore":Color("#E4F1D9"),
		"ocean":Color("#DDF6FC")
	}
	var card = _button("", action if scroll==null else Callable(), color_choices.get(item_id,Color("#FFFDF3")), minimum)
	if scroll!=null:
		scroll.wire_button(card,action)
	var container = VBoxContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.offset_left = 10
	container.offset_top = 8
	container.offset_right = -10
	container.offset_bottom = -7
	card.clip_contents = true
	card.add_child(container)
	var drawing = ChoiceArt.new()
	drawing.setup(item_id)
	drawing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawing.custom_minimum_size = Vector2(145, maxf(58.0, minimum.y - 65.0))
	drawing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawing.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(drawing)
	container.add_child(_label(caption, 23))
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
	_header(layout,"動物探險島")
	layout.add_child(_label("今天一起探索哪個世界？ ✨",28,HORIZONTAL_ALIGNMENT_CENTER,Color("#3F7165")))
	# One vertical, touch-friendly scroll view, but two SEPARATE rows/groups:
	# child-oriented parks first, supporting activities clearly separated.
	var scrolling=TouchAnimalScroll.new()
	scrolling.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scrolling.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scrolling.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scrolling)
	var content=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",0)
	scrolling.add_child(content)
	var wide=get_viewport_rect().size.x>=880.0
	_home_section(content,scrolling,"🌿 探索樂園",[
		{"title":"農場樂園","zone":"farm"},
		{"title":"森林樂園","zone":"forest"},
		{"title":"動物園樂園","zone":"zoo"},
		{"title":"昆蟲樂園","zone":"insect"},
		{"title":"海底樂園","zone":"ocean_park"}
	],wide)
	var separation=Control.new()
	separation.custom_minimum_size=Vector2(0,42 if wide else 34)
	separation.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(separation)
	_home_section(content,scrolling,"🎨 我的動物天地",[
		{"title":"私人農場","zone":"private_farm"},
		{"title":"動物著色屋","zone":"coloring"},
		{"title":"動物畫畫學堂","zone":"drawing"},
		{"title":"動物之家","zone":"care"},
		{"title":"動物圖鑑","zone":"album"}
	],wide)
	layout.add_child(_label("★ 已認識 %d / %d 位動物與昆蟲朋友！" % [int(progress.data["collected"].size()),animals.size()],22,HORIZONTAL_ALIGNMENT_CENTER,Color("#34736F")))
	_narrate("歡迎來到動物探險島！五個樂園裡面可以找動物和昆蟲。下面有私人農場、動物著色屋、新的動物畫畫學堂，還有動物之家和圖鑑。")

func _home_section(parent: VBoxContainer, scroll: ScrollContainer, heading: String, places: Array, wide: bool) -> void:
	var section=VBoxContainer.new()
	section.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation",13)
	parent.add_child(section)
	section.add_child(_label(heading,24,HORIZONTAL_ALIGNMENT_CENTER,Color("#335F58")))
	var grid=GridContainer.new()
	grid.columns=4 if wide else 2
	grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation",16)
	grid.add_theme_constant_override("v_separation",15)
	section.add_child(grid)
	for place in places:
		var destination=str(place["zone"])
		var tile=_picture_button(destination,str(place["title"]),Callable(self,"_go").bind(destination),Vector2(188,134) if wide else Vector2(178,133),scroll)
		grid.add_child(tile)

func _go(where: String) -> void:
	match where:
		"farm", "forest", "zoo", "insect":
			show_zone(where)
		"care":
			show_care()
		"album":
			show_album()
		"forest_explore":
			show_forest_search()
		"private_farm":
			show_private_farm()
		"coloring":
			show_coloring()
		"drawing":
			show_drawing()
		"ocean":
			show_ocean_search()
		"ocean_park":
			show_zone("ocean")

func show_zone(zone: String) -> void:
	current_zone = zone
	var layout = _switch("ocean_park" if zone=="ocean" else zone, zone)
	_header(layout, str({"farm":"農場樂園","forest":"森林樂園","zoo":"動物園樂園","ocean":"海底樂園","insect":"昆蟲樂園"}.get(zone,"探索樂園")), Callable(self,"show_home"))
	layout.add_child(_label("挑一位昆蟲朋友，一起玩吧！" if zone=="insect" else "挑一位動物朋友，一起玩吧！", 25,HORIZONTAL_ALIGNMENT_CENTER,Color("#39766D")))
	if zone in ["forest","ocean","zoo","insect"]:
		var entries={
			"forest":["forest_explore","🌲 去大森林找動物"],
			"ocean":["ocean","🐠 去海底找朋友"],
			"zoo":["zoo_search","🦁 去動物園找六隻動物"],
			"insect":["insect_search","🦋 昆蟲大探險"]
		}
		var choice: Array=entries[zone]
		var destination=Callable(self,"show_forest_search") if zone=="forest" else (Callable(self,"show_ocean_search") if zone=="ocean" else (Callable(self,"show_zoo_search") if zone=="zoo" else Callable(self,"show_insect_search")))
		var seek_button=_picture_button(str(choice[0]),str(choice[1]),destination,Vector2(310,95))
		seek_button.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		layout.add_child(seek_button)
	var panel = _panel()
	layout.add_child(panel)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll = TouchAnimalScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 5 if get_viewport_rect().size.x>=1150 else 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for info in animals:
		if str(info.get("zone","")) == zone or (zone=="zoo" and str(info.get("id",""))=="monkey"):
			grid.add_child(_animal_button(info, Callable(self,"show_animal").bind(str(info["id"]),zone),false,scroll))
	layout.add_child(_label("點昆蟲圖片聽介紹、摸摸牠、玩小遊戲！" if zone=="insect" else "點動物圖片聽介紹、摸摸牠、玩小遊戲！", 19,HORIZONTAL_ALIGNMENT_CENTER,Color("#527975")))
	if zone=="insect":
		_narrate("這裡是昆蟲樂園！有七隻昆蟲朋友。用手指點一隻昆蟲，聽牠的介紹，也可以玩昆蟲大探險！")
	else:
		_narrate("這裡是%s。用手指點一隻動物，和牠交朋友吧！" % str({"farm":"農場","forest":"森林","zoo":"動物園","ocean":"海底樂園"}.get(zone,"探索樂園")))
	# The forest hide-and-seek entry uses its own illustrated button, not a text-only menu.

func show_zoo_search() -> void:
	current_zone="zoo"
	var layout=_switch("zoo_search","zoo")
	_header(layout,"動物園找動物",Callable(self,"show_zone").bind("zoo"))
	var zoo_animals: Array=[]
	for info in animals:
		if str(info.get("zone",""))=="zoo" or str(info.get("id",""))=="monkey":
			zoo_animals.append(info)
	zoo_game=ZooDiscovery.new()
	zoo_game.setup(zoo_animals,progress,sound)
	zoo_game.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	zoo_game.size_flags_vertical=Control.SIZE_EXPAND_FILL
	zoo_game.completed.connect(Callable(self,"show_zoo_complete"))
	layout.add_child(zoo_game)

func show_zoo_complete() -> void:
	var layout=_switch("zoo_done","zoo")
	_header(layout,"動物園探索完成！",Callable(self,"show_zone").bind("zoo"))
	layout.add_child(_label("太棒了！六位動物朋友都找到了！",29))
	var panel=_panel()
	panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	layout.add_child(panel)
	var scroll=TouchAnimalScroll.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var grid=GridContainer.new()
	grid.columns=3
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",8)
	scroll.add_child(grid)
	for info in animals:
		if str(info.get("zone",""))=="zoo" or str(info.get("id",""))=="monkey":
			var tile=_animal_button(info,Callable(self,"show_animal").bind(str(info["id"]),"zoo"),false,scroll)
			tile.custom_minimum_size=Vector2(155,151)
			grid.add_child(tile)
	var actions=HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	layout.add_child(actions)
	actions.add_child(_button("再找一次",Callable(self,"show_zoo_search"),Color("#F8E5C6"),Vector2(200,70)))
	actions.add_child(_button("動物園樂園",Callable(self,"show_zone").bind("zoo"),Color("#DFF0DE"),Vector2(200,70)))
	_narrate("太棒啦！找到駱駝、獅子、老虎、大象、猴子和河馬！可以再玩一次！")

func show_insect_search() -> void:
	current_zone="insect"
	var layout=_switch("insect_search","insect")
	_header(layout,"昆蟲大探險",Callable(self,"show_zone").bind("insect"))
	var insect_animals: Array=[]
	for info in animals:
		if str(info.get("zone",""))=="insect":
			insect_animals.append(info)
	insect_game=InsectDiscovery.new()
	insect_game.setup(insect_animals,progress,sound)
	insect_game.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	insect_game.size_flags_vertical=Control.SIZE_EXPAND_FILL
	insect_game.completed.connect(Callable(self,"show_insect_complete"))
	layout.add_child(insect_game)

func show_insect_complete() -> void:
	var layout=_switch("insect_done","insect")
	_header(layout,"昆蟲大探險完成！",Callable(self,"show_zone").bind("insect"))
	layout.add_child(_label("太棒了！七位昆蟲朋友都找到了！",29))
	var panel=_panel()
	panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	layout.add_child(panel)
	var scroll=TouchAnimalScroll.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var grid=GridContainer.new()
	grid.columns=3
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",8)
	scroll.add_child(grid)
	for info in animals:
		if str(info.get("zone",""))=="insect":
			var tile=_animal_button(info,Callable(self,"show_animal").bind(str(info["id"]),"insect"),false,scroll)
			tile.custom_minimum_size=Vector2(155,151)
			grid.add_child(tile)
	var actions=HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	layout.add_child(actions)
	actions.add_child(_button("再找一次",Callable(self,"show_insect_search"),Color("#F8E5C6"),Vector2(200,70)))
	actions.add_child(_button("昆蟲樂園",Callable(self,"show_zone").bind("insect"),Color("#DFF0DE"),Vector2(200,70)))
	_narrate("太棒啦！找到獨角仙、鍬形蟲、蝴蝶、瓢蟲、蜜蜂、螳螂和推糞球的糞金龜！七位昆蟲朋友都找到了！可以再玩一次！")

func show_ocean_search() -> void:
	current_zone="ocean"
	var layout=_switch("ocean_search","home")
	_header(layout,"海底探索",Callable(self,"show_zone").bind("ocean"))
	var ocean_animals: Array=[]
	for info in animals:
		if str(info.get("zone",""))=="ocean":
			ocean_animals.append(info)
	ocean_game=OceanDiscovery.new()
	ocean_game.setup(ocean_animals,progress,sound)
	ocean_game.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	ocean_game.size_flags_vertical=Control.SIZE_EXPAND_FILL
	ocean_game.completed.connect(Callable(self,"show_ocean_complete"))
	layout.add_child(ocean_game)

func show_ocean_complete() -> void:
	var layout=_switch("ocean_done","home")
	_header(layout,"海底探險完成！",Callable(self,"show_zone").bind("ocean"))
	layout.add_child(_label("太棒了！七種海底生物都找到了！",31))
	var panel=_panel()
	panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	layout.add_child(panel)
	var scroll=TouchAnimalScroll.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var grid=GridContainer.new()
	grid.columns=4
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	scroll.add_child(grid)
	for info in animals:
		if str(info.get("zone",""))=="ocean":
			var tile=_animal_button(info,Callable(self,"show_animal").bind(str(info["id"])),false,scroll)
			tile.custom_minimum_size=Vector2(140,150)
			grid.add_child(tile)
	var actions=HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	layout.add_child(actions)
	actions.add_child(_button("再找一次",Callable(self,"show_ocean_search"),Color("#E5EFFF"),Vector2(220,72)))
	actions.add_child(_button("海底樂園",Callable(self,"show_zone").bind("ocean"),Color("#DEEFDA"),Vector2(220,72)))
	_narrate("七種海洋朋友都找到囉！可以再玩一次，也可以把牠們帶去私人農場的大水池！")

func show_drawing() -> void:
	var layout=_switch("drawing","home")
	_header(layout,"動物畫畫學堂",Callable(self,"show_home"))
	drawing_game=DrawingStudio.new()
	drawing_game.setup(animals,progress,sound)
	drawing_game.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	drawing_game.size_flags_vertical=Control.SIZE_EXPAND_FILL
	layout.add_child(drawing_game)

func show_coloring() -> void:
	var layout=_switch("coloring","home")
	_header(layout,"動物著色屋",Callable(self,"show_home"))
	coloring_game=ColoringRoom.new()
	coloring_game.setup(animals,progress,sound)
	coloring_game.size_flags_vertical=Control.SIZE_EXPAND_FILL
	coloring_game.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	layout.add_child(coloring_game)

func show_private_farm() -> void:
	var layout = _switch("private_farm","farm")
	_header(layout,"私人農場",Callable(self,"show_home"))
	private_farm_game = PrivateFarm.new()
	private_farm_game.setup(animals,progress,sound)
	private_farm_game.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	private_farm_game.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(private_farm_game)

func show_forest_search() -> void:
	current_zone = "forest"
	var layout = _switch("forest_search","forest")
	_header(layout,"大森林探索",Callable(self,"show_home"))
	var forest_animals: Array = []
	for a in animals:
		if str(a.get("zone",""))=="forest":
			forest_animals.append(a)
	forest_game = ForestDiscovery.new()
	forest_game.setup(forest_animals,progress,sound)
	forest_game.size_flags_vertical = Control.SIZE_EXPAND_FILL
	forest_game.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forest_game.completed.connect(Callable(self,"show_forest_complete"))
	layout.add_child(forest_game)

func show_forest_complete() -> void:
	var layout = _switch("forest_done","forest")
	_header(layout,"十二位動物朋友都找到了！",Callable(self,"show_zone").bind("forest"))
	layout.add_child(_label("太棒了！大森林探索完成！",35))
	var box=_panel()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(box)
	var grid=GridContainer.new()
	grid.columns=6
	grid.add_theme_constant_override("h_separation",10)
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_child(grid)
	for a in animals:
		if str(a.get("zone",""))=="forest":
			var avatar=_animal_button(a,Callable(self,"show_animal").bind(str(a["id"])))
			avatar.custom_minimum_size=Vector2(135,145)
			grid.add_child(avatar)
	var row=HBoxContainer.new()
	row.alignment=BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",28)
	layout.add_child(row)
	row.add_child(_button("再找一次",Callable(self,"show_forest_search"),Color("#FCE1AB"),Vector2(250,85)))
	row.add_child(_button("回首頁",Callable(self,"show_home"),Color("#D8EED4"),Vector2(210,85)))
	row.add_child(_button("回森林樂園",Callable(self,"show_zone").bind("forest"),Color("#E0E7FA"),Vector2(210,85)))
	_narrate("太棒了！完成大森林探索！十二隻森林動物都找到了！要再玩一次，還是回首頁呢？")

func show_animal(id: String, source_zone: String = "") -> void:
	var info = _animal(id)
	if info.is_empty():
		show_home()
		return
	selected_animal = id
	current_zone = source_zone if not source_zone.is_empty() else str(info["zone"])
	progress.unlock(id)
	var layout = _switch("animal",current_zone)
	_header(layout, str(info["name"]) + " 來啦！", Callable(self,"show_zone").bind(current_zone))
	var main = HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(main)
	var panel = _panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(panel)
	petting_area = PettingArea.new()
	petting_area.setup(info,bool(progress.data["settings"].get("reduce_motion",false)))
	petting_area.custom_minimum_size = Vector2(380,390)
	petting_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	petting_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	petting_area.stroked.connect(Callable(self,"_on_pet_stroke"))
	panel.add_child(petting_area)
	var side = VBoxContainer.new()
	side.custom_minimum_size = Vector2(465,0)
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	side.add_theme_constant_override("separation", 18)
	main.add_child(side)
	side.add_child(_label(str(info.get("desc","")), 28))
	side.add_child(_button(("聽昆蟲聲音" if _is_insect(id) else "聽動物叫聲") if sound.has_natural_sound(id) else ("聽聽昆蟲介紹" if _is_insect(id) else "聽聽動物介紹"), Callable(self,"_play_animal").bind(id), Color("#F9E3B9")))
	side.add_child(_button("摸摸牠", Callable(self,"_pet").bind(id), Color("#F9DCE1")))
	side.add_child(_button("一起玩小遊戲", Callable(self,"show_game").bind(id), Color("#D5EEDD")))
	if bool(info.get("care",false)):
		side.add_child(_button("去動物之家照顧牠", Callable(self,"show_care").bind(id), Color("#DFE9FF")))
	side.add_child(_label("用手指在%s身上滑動，牠會開心喔！" % _friend_word(id), 20))
	_narrate("你好！我是%s。%s 用手指在我身上輕輕滑動，就能摸摸我喔！" % [str(info["name"]),str(info["desc"])])

func _play_animal(id: String) -> void:
	if bool(progress.data["settings"].get("sound",true)):
		sound.play_animal(id)

func _pet(_id: String) -> void:
	# The button is an instruction, not an artificial 'pet success' shortcut.
	if is_instance_valid(petting_area):
		petting_area.guide()
	_narrate("把手指放在%s身上，輕輕來回滑動，讓牠開心！" % _friend_word(selected_animal))

func _on_pet_stroke() -> void:
	# Reward only the first successful stroke with audio; the animation
	# continues smoothly without restarting a long spoken introduction.
	if is_instance_valid(petting_area) and int(petting_area.strokes) == 1:
		_play_animal(selected_animal)

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
	_header(layout, "昆蟲小遊戲" if _is_insect(selected_animal) else "動物小遊戲", Callable(self,"show_animal").bind(selected_animal))
	var kind = str(level["type"])
	var prompt = _game_prompt(level)
	layout.add_child(_label(prompt, 29))
	var replay = _button("再聽一次" if kind != "sound" else "再聽叫聲", Callable(self, "_repeat_game_prompt").bind(level),Color("#FFE7BD"),Vector2(210,60))
	replay.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(replay)
	if kind == "sound":
		_narrate("仔細聽一聽，這是誰的聲音？看看圖片，點出正確的%s。" % _friend_word(str(level["animal"])))
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
				shown = {"farm":"農場","forest":"森林","ocean":"海洋","insect":"昆蟲樂園"}.get(option,option)
			button = _picture_button(option,shown,Callable(self,"_answer").bind(option,level))
		opts.add_child(button)
		answer_buttons.append(button)
	feedback_label = _label("看看圖案，慢慢選！",25)
	layout.add_child(feedback_label)

func _repeat_game_prompt(level: Dictionary) -> void:
	if str(level["type"]) == "sound":
		_play_animal(str(level["animal"]))
	else:
		_narrate(_game_prompt(level))

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
	layout.add_child(_label("獲得一張可愛的%s貼紙" % _friend_word(str(level["animal"])), 30))
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
	_narrate("答對了！你得到%s的%s貼紙！再玩一次，或是回到樂園。" % [_answer_name(str(level["animal"])),_friend_word(str(level["animal"]))])

func show_album() -> void:
	var layout = _switch("album")
	_header(layout,"我的動物圖鑑",Callable(self,"show_home"))
	layout.add_child(_label("已收集 %d / %d 張動物與昆蟲貼紙" % [int(progress.data["collected"].size()),animals.size()],29))
	var scroll = TouchAnimalScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 5 if get_viewport_rect().size.x>=1150 else 4
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",18)
	scroll.add_child(grid)
	for info in animals:
		var is_collected = progress.data["collected"].has(str(info["id"]))
		var callback: Callable = Callable(self,"show_animal").bind(str(info["id"])) if is_collected else Callable(self,"_locked")
		grid.add_child(_animal_button(info,callback,not is_collected,scroll))
	layout.add_child(_label("探索時點擊動物或昆蟲，就能找到更多朋友！",21))
	_narrate("這是你的動物與昆蟲圖鑑。亮亮的貼紙，是你認識過的動物和昆蟲朋友。")

func _locked() -> void:
	# Locked stickers are intentionally non-destructive.
	pass

func show_care(id: String = "", announce: bool = true) -> void:
	if id != "":
		selected_animal = id
	var info = _animal(selected_animal)
	if info.is_empty() or not bool(info.get("care",false)):
		selected_animal = "cow"
		info = _animal(selected_animal)
	var layout = _switch("care","farm")
	_header(layout,"動物之家",Callable(self,"show_home"))
	var tab_scroll = TouchAnimalScroll.new()
	tab_scroll.custom_minimum_size=Vector2(0,66)
	tab_scroll.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	tab_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	tab_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	tab_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(tab_scroll)
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation",12)
	tab_scroll.add_child(tabs)
	for animal in animals:
		if bool(animal.get("care",false)):
			var aid = str(animal["id"])
			var button=_button(str(animal["name"]),Callable(),Color("#D9F2D9") if aid == selected_animal else Color("#FFFDF1"),Vector2(190,58))
			tab_scroll.wire_button(button,Callable(self,"show_care").bind(aid,false))
			tabs.add_child(button)
	var center = HBoxContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation",20)
	layout.add_child(center)
	var photo = _panel()
	photo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(photo)
	care_stage = CareStage.new()
	care_stage.setup(info,bool(progress.data["settings"].get("reduce_motion",false)))
	care_stage.custom_minimum_size = Vector2(370,345)
	care_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	care_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	care_stage.action_finished.connect(Callable(self,"_on_care_finished"))
	photo.add_child(care_stage)
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",12)
	center.add_child(right)
	care_feedback = _label("今天和「%s」玩什麼？" % info["name"],26)
	right.add_child(care_feedback)
	care_bars.clear()
	var stats = progress.care_stats(selected_animal)
	for pair in [["food","飽足"],["clean","清潔"],["happy","開心"]]:
		var bar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(320,30)
		bar.value = float(stats[pair[0]])
		bar.show_percentage = false
		right.add_child(_label(str(pair[1]),20,HORIZONTAL_ALIGNMENT_LEFT))
		right.add_child(bar)
		care_bars[str(pair[0])] = bar
	var actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",10)
	layout.add_child(actions)
	care_action_buttons.clear()
	for item in [["feed","餵食"],["wash","洗澡"],["play","玩耍"],["sleep","休息"]]:
		var button = _picture_button(str(item[0]),str(item[1]),Callable(self,"_care_action").bind(str(item[0])),Vector2(220,115))
		actions.add_child(button)
		care_action_buttons.append(button)
	layout.add_child(_label("看看圖片，點一下就可以照顧動物。",21))
	if announce:
		care_intro_count += 1
		_narrate("歡迎來到動物之家！看看下面的圖片，可以餵食、洗澡、玩耍，或讓%s休息。" % str(info["name"]))
	elif id != "":
		_narrate("現在來照顧%s。" % str(info["name"]))

func _care_action(action: String) -> void:
	if not is_instance_valid(care_stage):
		return
	if not bool(care_stage.play_action(action)):
		return
	progress.care_for(selected_animal,action)
	var stats = progress.care_stats(selected_animal)
	for key in care_bars.keys():
		var bar: ProgressBar = care_bars[key]
		create_tween().tween_property(bar,"value",float(stats[key]),0.38)
	var phrases = {"feed":"真好吃！牠開心地吃飯了！","wash":"好多泡泡！洗得乾乾淨淨！","play":"玩得好開心！一起玩球吧！","sleep":"晚安！讓牠舒服地休息。"}
	care_feedback.text = str(phrases.get(action,"牠很開心！"))
	for button in care_action_buttons:
		button.disabled = true
	# Don't navigate/recreate the care screen. That previously retriggered
	# _switch and replayed the full 'welcome to animal home' introduction.
	_narrate(str(phrases.get(action,"真棒！")))

func _on_care_finished(_action: String) -> void:
	for button in care_action_buttons:
		if is_instance_valid(button):
			button.disabled = false

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
	var restore_y=parent_scroll_y
	var layout = _switch("settings")
	_header(layout,"家長設定",Callable(self,"show_home"))
	# The header stays fixed. All settings AND explanatory information scroll.
	var scroll = TouchAnimalScroll.new()
	settings_scroll=scroll
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",13)
	scroll.add_child(content)
	var settings: Dictionary = progress.data["settings"]
	content.add_child(_section_title("遊戲體驗","🔊"))
	for item in [
		["sound","動物音效","播放動物的聲音與遊戲鼓勵音效"],
		["speech","中文語音引導","讓還不認識文字的孩子也能玩"],
		["reduce_motion","溫和動畫","減少快速跳動，維持舒適節奏"]
	]:
		var key = str(item[0])
		var row_panel = _panel()
		row_panel.custom_minimum_size = Vector2(0,88)
		content.add_child(row_panel)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation",14)
		row_panel.add_child(row)
		var text_side = VBoxContainer.new()
		text_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text_side)
		text_side.add_child(_label(str(item[1]),25,HORIZONTAL_ALIGNMENT_LEFT))
		text_side.add_child(_label(str(item[2]),17,HORIZONTAL_ALIGNMENT_LEFT,Color("#637A83")))
		var on=bool(settings.get(key,false))
		var b=_button("✓ 開" if on else "○ 關",Callable(),Color("#D6EEDF") if on else Color("#EAEFF4"),Vector2(120,58))
		scroll.wire_button(b,Callable(self,"_toggle").bind(key))
		row.add_child(b)
	content.add_child(_section_title("陪伴孩子的小提醒","♥"))
	for note in [
		"遊戲完全離線，不需要註冊帳號，也沒有廣告。",
		"動物圖鑑、私人農場住客、著色作品都會保存在此裝置。",
		"四歲孩子可以用大圖示、觸摸、拖曳與語音來探索。",
		"長時間遊玩後可以休息、眨眨眼，和家人聊聊認識的新動物。"
	]:
		var panel=_panel()
		content.add_child(panel)
		var note_label=_label(note,21,HORIZONTAL_ALIGNMENT_LEFT)
		note_label.custom_minimum_size=Vector2(0,68)
		panel.add_child(note_label)
	content.add_child(_label("往上滑動，可以查看所有家長設定與說明。",17,HORIZONTAL_ALIGNMENT_LEFT,Color("#6F8391")))
	_restore_parent_scroll.call_deferred(scroll,restore_y)

func _restore_parent_scroll(scroll: ScrollContainer, value: int) -> void:
	if is_instance_valid(scroll):
		scroll.scroll_vertical=value

func _section_title(message: String, symbol: String) -> HBoxContainer:
	var row=HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	row.add_child(_label(symbol,29,HORIZONTAL_ALIGNMENT_LEFT,Color("#E89A64")))
	row.add_child(_label(message,28,HORIZONTAL_ALIGNMENT_LEFT,Color("#344658")))
	return row

func _toggle(key: String) -> void:
	if is_instance_valid(settings_scroll):
		parent_scroll_y=settings_scroll.scroll_vertical
	progress.toggle_setting(key)
	sound.enabled = bool(progress.data["settings"].get("sound",true))
	sound.speech_enabled = bool(progress.data["settings"].get("speech",true))
	show_settings()
