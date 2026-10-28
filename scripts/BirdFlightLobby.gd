extends VBoxContainer
## Choose one of eight bird pilots and one of two child-friendly sky routes.
signal start_requested(bird: Dictionary,course_id: String)
const BirdArt=preload("res://scripts/BirdArt.gd")
const COURSES=[
	{"id":"lake","name":"💧 湖畔微風盃"},
	{"id":"forest","name":"🌳 森林天空盃"}
]
var birds: Array=[]
var progress
var narrator
var options: Array=[]
var chosen_id: String=""
var course_id: String="lake"
var grid: GridContainer
var course_buttons: Array=[]
var status: Label

func setup(catalog: Array,store,voice) -> void:
	birds=catalog
	progress=store
	narrator=voice
	for bird in birds:
		if store.data.get("bird_found",[]).has(str(bird["id"])):
			options.append(bird)
	# A first-time player may practice with the mandarin duck.
	if options.is_empty() and not birds.is_empty():
		options.append(birds[0])
	if not options.is_empty():
		chosen_id=str(options[0]["id"])

func _ready() -> void:
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",7)
	var message=Label.new()
	message.text="🐦 選鳥兒、選天空賽道，大家一起飛！"
	message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size",24)
	message.add_theme_color_override("font_color",Color("#294F5E"))
	add_child(message)
	var tracks=HBoxContainer.new()
	tracks.alignment=BoxContainer.ALIGNMENT_CENTER
	tracks.add_theme_constant_override("separation",18)
	add_child(tracks)
	for course in COURSES:
		var b=_button(str(course["name"]),Callable(self,"choose_course").bind(str(course["id"])),Vector2(250,58))
		tracks.add_child(b)
		course_buttons.append(b)
	status=Label.new()
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size",20)
	status.add_theme_color_override("font_color",Color("#294F5E"))
	add_child(status)
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	grid=GridContainer.new()
	grid.columns=4
	grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation",15)
	grid.add_theme_constant_override("v_separation",10)
	scroll.add_child(grid)
	for bird in options:
		var b=_button("",Callable(self,"select_bird").bind(str(bird["id"])),Vector2(175,150))
		b.set_meta("bird_id",str(bird["id"]))
		grid.add_child(b)
		var column=VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.mouse_filter=Control.MOUSE_FILTER_IGNORE
		b.add_child(column)
		var art=BirdArt.new()
		art.setup(bird)
		art.custom_minimum_size=Vector2(163,111)
		art.size_flags_vertical=Control.SIZE_EXPAND_FILL
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		column.add_child(art)
		var caption=Label.new()
		caption.text=str(bird["name"])
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size",20)
		caption.add_theme_color_override("font_color",Color("#273F4D"))
		column.add_child(caption)
	var start=_button("🏁 開始飛行大賽",Callable(self,"start"),Vector2(300,65))
	add_child(start)
	_refresh()
	if narrator!=null:
		narrator.speak("選好鳥兒和飛行路線，就能參加飛行大賽！用上升和下降躲開雲朵，收集星星。")

func _button(title: String,callback: Callable,minimum: Vector2) -> Button:
	var b=Button.new()
	b.text=title
	b.custom_minimum_size=minimum
	b.add_theme_font_size_override("font_size",21)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		b.add_theme_color_override(state,Color("#233C4B"))
	var box=StyleBoxFlat.new()
	box.bg_color=Color("#FFF3D6")
	box.border_color=Color("#9F8360")
	box.set_border_width_all(3)
	box.set_corner_radius_all(16)
	box.content_margin_left=12
	box.content_margin_right=12
	box.content_margin_top=8
	box.content_margin_bottom=8
	b.add_theme_stylebox_override("normal",box)
	var hover=box.duplicate()
	hover.bg_color=Color("#FCE3B7")
	b.add_theme_stylebox_override("hover",hover)
	var pressed=box.duplicate()
	pressed.bg_color=Color("#F9D28D")
	b.add_theme_stylebox_override("pressed",pressed)
	b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	b.pressed.connect(callback)
	return b

func choose_course(id: String) -> void:
	course_id=id
	_refresh()

func select_bird(id: String) -> void:
	chosen_id=id
	_refresh()

func _refresh() -> void:
	if grid==null:
		return
	var who=""
	for bird in options:
		if str(bird["id"])==chosen_id:
			who=str(bird["name"])
	status.text="🪽 我的飛行員：%s　·　已收集 %d / %d 種" % [who,progress.data.get("bird_found",[]).size(),birds.size()]
	for i in range(course_buttons.size()):
		_highlight(course_buttons[i],str(COURSES[i]["id"])==course_id)
	for card in grid.get_children():
		_highlight(card,str(card.get_meta("bird_id",""))==chosen_id)

func _highlight(button: Button,selected: bool) -> void:
	var style=button.get_theme_stylebox("normal").duplicate()
	style.bg_color=Color("#C7E9D1") if selected else Color("#FFF3D6")
	style.border_color=Color("#3C886C") if selected else Color("#9F8360")
	button.add_theme_stylebox_override("normal",style)

func start() -> void:
	for bird in options:
		if str(bird["id"])==chosen_id:
			start_requested.emit(bird,course_id)
			return
