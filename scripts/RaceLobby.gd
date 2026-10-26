extends VBoxContainer
## Race entry screen inside Private Farm. Only collected/owned friends appear.
signal start_requested(animal: Dictionary, track_data: Dictionary)

const Rules = preload("res://scripts/RaceRules.gd")
const AnimalArt = preload("res://scripts/AnimalArt.gd")
const TouchAnimalScroll = preload("res://scripts/TouchAnimalScroll.gd")

var animals: Array = []
var store
var narrator
var options: Array = []
var selected_id: String = ""
var track_id: String = "farm"
var header: Label
var chosen_label: Label
var grid: GridContainer
var track_buttons: Array = []
var scroll

func configure(catalog: Array, progress, voice) -> void:
	animals=catalog
	store=progress
	narrator=voice
	options=Rules.candidates(animals,store.data.get("private_farm",[]),
		store.data.get("collected",[]))
	if not options.is_empty():
		selected_id=str(options[0].get("id","cow"))

func _ready() -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",10)
	header=_text("🏎️ 選一位動物或昆蟲朋友開賽車！",24)
	add_child(header)
	var track_row=HBoxContainer.new()
	track_row.alignment=BoxContainer.ALIGNMENT_CENTER
	track_row.add_theme_constant_override("separation",12)
	add_child(track_row)
	for t in Rules.TRACKS:
		var choice=_button(str(t["name"]),Callable(self,"choose_track").bind(str(t["id"])))
		choice.custom_minimum_size=Vector2(205,66)
		track_row.add_child(choice)
		track_buttons.append(choice)
	chosen_label=_text("",21)
	add_child(chosen_label)
	scroll=TouchAnimalScroll.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	grid=GridContainer.new()
	grid.columns=4
	grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",10)
	scroll.add_child(grid)
	for animal in options:
		grid.add_child(_character_button(animal))
	var start=_button("🏁 開始比賽！",Callable(self,"start"))
	start.custom_minimum_size=Vector2(280,70)
	add_child(start)
	_refresh()
	if narrator!=null:
		narrator.speak("歡迎來到動物昆蟲賽車場！先選動物朋友，再選賽道，按開始比賽。")

func _text(value: String,font_size: int) -> Label:
	var lbl=Label.new()
	lbl.text=value
	lbl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size",font_size)
	lbl.add_theme_color_override("font_color",Color("#34594D"))
	return lbl

func _button(title: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = title
	button.add_theme_font_size_override("font_size",22)
	# Set every interaction state explicitly; the default disabled/hover
	# colors can otherwise wash out labels against pastel backgrounds.
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,Color("#233649"))
	button.add_theme_color_override("font_disabled_color",Color("#475765"))
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#FFE8B5")
	style.set_corner_radius_all(18)
	style.set_border_width_all(3)
	style.border_color = Color("#A1763C")
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	button.add_theme_stylebox_override("normal",style)
	var hover = style.duplicate()
	hover.bg_color = Color("#FFF1CB")
	button.add_theme_stylebox_override("hover",hover)
	var pressed = style.duplicate()
	pressed.bg_color = Color("#F7D28A")
	button.add_theme_stylebox_override("pressed",pressed)
	var disabled = style.duplicate()
	disabled.bg_color = Color("#E5EAEE")
	disabled.border_color = Color("#98A3AD")
	button.add_theme_stylebox_override("disabled",disabled)
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	if callback.is_valid():
		button.pressed.connect(callback)
	return button

func _style_selection(button: Button, selected: bool) -> void:
	# Highlight the border/background only. Never fade the icon or text.
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#FFE4A0") if selected else Color("#FFF4DA")
	style.border_color = Color("#246B54") if selected else Color("#B18D61")
	style.set_border_width_all(4 if selected else 2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	button.add_theme_stylebox_override("normal",style)
	var hover = style.duplicate()
	hover.bg_color = Color("#FFD786") if selected else Color("#FFE9BB")
	button.add_theme_stylebox_override("hover",hover)
	var pressed = style.duplicate()
	pressed.bg_color = Color("#F6C76A")
	button.add_theme_stylebox_override("pressed",pressed)

func _character_button(animal: Dictionary) -> Button:
	var id=str(animal.get("id",""))
	var btn=_button("",Callable())
	btn.custom_minimum_size=Vector2(130,132)
	scroll.wire_button(btn,Callable(self,"choose_animal").bind(id))
	var column=VBoxContainer.new()
	column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(column)
	var art=AnimalArt.new()
	art.setup(animal)
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size=Vector2(107,94)
	art.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(art)
	column.add_child(_text(str(animal.get("name","動物")),17))
	btn.set_meta("racer_id",id)
	return btn

func choose_animal(id: String) -> void:
	for option in options:
		if str(option.get("id",""))==id:
			selected_id=id
			_refresh()
			if narrator!=null:
				narrator.speak("%s要開賽車囉！" % str(option.get("name","動物")))
			return

func choose_track(id: String) -> void:
	track_id=id
	_refresh()

func _refresh() -> void:
	var animal_name="動物"
	for option in options:
		if str(option.get("id",""))==selected_id:
			animal_name=str(option.get("name","動物"))
	for btn in grid.get_children():
		var chosen: bool=str(btn.get_meta("racer_id",""))==selected_id
		_style_selection(btn,chosen)
	chosen_label.text="目前選擇：%s    賽道：%s" % [animal_name,str(Rules.track_for(track_id)["name"])]
	for index in range(track_buttons.size()):
		_style_selection(track_buttons[index],str(Rules.TRACKS[index]["id"])==track_id)

func start() -> void:
	for option in options:
		if str(option.get("id",""))==selected_id:
			start_requested.emit(option,Rules.track_for(track_id))
			return
