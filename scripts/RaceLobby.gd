extends VBoxContainer
## Race entry inside the Private Farm; EVERY collected species can race, even if not a resident.
signal start_requested(animal: Dictionary, track_data: Dictionary)

const Rules = preload("res://scripts/RaceRules.gd")
const AnimalArt = preload("res://scripts/AnimalArt.gd")
const MonsterArt = preload("res://scripts/MonsterArt.gd")
const Track = preload("res://scripts/RaceTrack.gd")
const Kart = preload("res://scripts/RaceVehicle.gd")
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
var showcase_kart
var track_previews: Array = []
var monsters_only_mode: bool = false
var monster_mode_supported: bool = false
var filter_buttons: Array = []

func configure(catalog: Array, progress, voice, only_monsters: bool=false) -> void:
	animals=catalog
	store=progress
	narrator=voice
	monsters_only_mode=only_monsters
	monster_mode_supported=only_monsters
	track_id="candy" if only_monsters else "farm"
	_rebuild_options()

func _rebuild_options() -> void:
	var unlocked: Array=Rules.candidates(animals,store.data.get("private_farm",[]),
		store.data.get("collected",[]))
	options=[]
	for item in unlocked:
		if not monsters_only_mode or str(item.get("zone",""))=="monster":
			options.append(item)
	if options.is_empty() and monsters_only_mode:
		# A starter racer is available even before the child finds a monster.
		for item in animals:
			if str(item.get("id",""))=="monster_fire":
				options.append(item)
				break
	if not options.any(func(item): return str(item.get("id",""))==selected_id):
		selected_id=str(options[0].get("id","")) if not options.is_empty() else ""

func choose_filter(only_monsters: bool) -> void:
	monsters_only_mode=only_monsters
	_rebuild_options()
	for card in grid.get_children():
		grid.remove_child(card)
		card.queue_free()
	for animal in options:
		grid.add_child(_character_button(animal))
	_refresh()

func _ready() -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",10)
	header=_text("👾 怪獸賽車 · 找到怪獸就能來參賽！" if monster_mode_supported else "🏁 賽車嘉年華 · 所有已收集的朋友都可以參賽！",25)
	add_child(header)
	if monster_mode_supported:
		var filter_row=HBoxContainer.new()
		filter_row.alignment=BoxContainer.ALIGNMENT_CENTER
		filter_row.add_theme_constant_override("separation",15)
		add_child(filter_row)
		for entry in [[true,"👾 怪獸車手"],[false,"⭐ 全部已收集"]]:
			var button=_button(str(entry[1]),Callable(self,"choose_filter").bind(bool(entry[0])))
			button.custom_minimum_size=Vector2(210,52)
			filter_row.add_child(button)
			filter_buttons.append(button)
	var track_scroll=ScrollContainer.new()
	track_scroll.custom_minimum_size=Vector2(0,140)
	track_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	track_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	track_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(track_scroll)
	var track_row=HBoxContainer.new()
	track_row.alignment=BoxContainer.ALIGNMENT_CENTER
	track_row.add_theme_constant_override("separation",12)
	track_scroll.add_child(track_row)
	for t in Rules.TRACKS:
		var choice=_button(str(t["name"]),Callable(self,"choose_track").bind(str(t["id"])))
		choice.custom_minimum_size=Vector2(217,125)
		choice.text=""
		track_row.add_child(choice)
		var artwork=Track.new()
		artwork.setup(str(t["id"]),true)
		artwork.mouse_filter=Control.MOUSE_FILTER_IGNORE
		artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		artwork.offset_left=8
		artwork.offset_right=-8
		artwork.offset_top=8
		artwork.offset_bottom=-8
		choice.add_child(artwork)
		track_previews.append(artwork)
		var caption=Label.new()
		caption.text=str(t["name"])
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		caption.offset_top=-36
		caption.offset_bottom=-5
		caption.add_theme_font_size_override("font_size",19)
		caption.add_theme_color_override("font_color",Color("#203B40"))
		caption.add_theme_color_override("font_outline_color",Color("#FFFCDE"))
		caption.add_theme_constant_override("outline_size",6)
		choice.add_child(caption)
		track_buttons.append(choice)
	chosen_label=_text("",21)
	add_child(chosen_label)
	var center=HBoxContainer.new()
	center.size_flags_vertical=Control.SIZE_EXPAND_FILL
	center.alignment=BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation",14)
	add_child(center)
	scroll=TouchAnimalScroll.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	center.add_child(scroll)
	grid=GridContainer.new()
	grid.columns=4
	grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",10)
	scroll.add_child(grid)
	for animal in options:
		grid.add_child(_character_button(animal))
	var showcase=PanelContainer.new()
	showcase.custom_minimum_size=Vector2(235,260)
	var panel=StyleBoxFlat.new()
	panel.bg_color=Color("#ECF9E7")
	panel.border_color=Color("#FFF0C6")
	panel.set_border_width_all(5)
	panel.set_corner_radius_all(22)
	showcase.add_theme_stylebox_override("panel",panel)
	center.add_child(showcase)
	var preview_stack=VBoxContainer.new()
	preview_stack.alignment=BoxContainer.ALIGNMENT_CENTER
	showcase.add_child(preview_stack)
	preview_stack.add_child(_text("⭐ 我的賽車手",20))
	showcase_kart=Kart.new()
	showcase_kart.custom_minimum_size=Vector2(178,200)
	showcase_kart.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	showcase_kart.size_flags_vertical=Control.SIZE_EXPAND_FILL
	showcase_kart.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(showcase_kart)
	preview_stack.add_child(_text("選好就出發！",17))
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
	var art=MonsterArt.new() if str(animal.get("zone",""))=="monster" else AnimalArt.new()
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
	for i in range(filter_buttons.size()):
		_style_selection(filter_buttons[i],monsters_only_mode if i==0 else not monsters_only_mode)
	var animal_name="動物"
	for option in options:
		if str(option.get("id",""))==selected_id:
			animal_name=str(option.get("name","動物"))
	for btn in grid.get_children():
		var chosen: bool=str(btn.get_meta("racer_id",""))==selected_id
		_style_selection(btn,chosen)
	chosen_label.text="🧸 車手：%s     🗺️ 賽道：%s     🔓 已收集 %d 位車手" % [animal_name,str(Rules.track_for(track_id)["name"]),options.size()]
	if showcase_kart!=null:
		for candidate in options:
			if str(candidate.get("id",""))==selected_id:
				showcase_kart.setup(candidate,true)
				break
	for index in range(track_buttons.size()):
		_style_selection(track_buttons[index],str(Rules.TRACKS[index]["id"])==track_id)

func start() -> void:
	for option in options:
		if str(option.get("id",""))==selected_id:
			start_requested.emit(option,Rules.track_for(track_id))
			return
