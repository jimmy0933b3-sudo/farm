extends VBoxContainer
## Bird gallery independent of the 39 original animal quizzes.
const BirdArt=preload("res://scripts/BirdArt.gd")
var birds: Array=[]
var progress
var narrator
var detail: Label

func setup(catalog: Array,store,voice) -> void:
	birds=catalog
	progress=store
	narrator=voice

func _ready() -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	var owned: int=0
	for bird in birds:
		if progress.data.get("bird_found",[]).has(str(bird["id"])):
			owned+=1
	var heading=Label.new()
	heading.text="🐦 我的鳥類圖鑑　已找到 %d / %d 種" % [owned,birds.size()]
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size",24)
	heading.add_theme_color_override("font_color",Color("#2C5060"))
	add_child(heading)
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var grid=GridContainer.new()
	grid.columns=4 if get_viewport_rect().size.x>940.0 else 3
	grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",14)
	scroll.add_child(grid)
	for bird in birds:
		var collected=progress.data.get("bird_found",[]).has(str(bird["id"]))
		var card=Button.new()
		card.custom_minimum_size=Vector2(190,164)
		var style=StyleBoxFlat.new()
		style.bg_color=Color("#E7F5DF") if collected else Color("#E9EBF1")
		style.border_color=Color("#5B9E83") if collected else Color("#A8ADB8")
		style.set_border_width_all(3)
		style.set_corner_radius_all(16)
		card.add_theme_stylebox_override("normal",style)
		card.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		card.pressed.connect(Callable(self,"_describe").bind(bird,collected))
		grid.add_child(card)
		var column=VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(column)
		var art=BirdArt.new()
		art.setup(bird)
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		art.custom_minimum_size=Vector2(180,121)
		art.size_flags_vertical=Control.SIZE_EXPAND_FILL
		if not collected:
			art.modulate=Color("#BEC3CC")
		column.add_child(art)
		var label=Label.new()
		label.text=("✓ " if collected else "🔎 ")+str(bird["name"])
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size",19)
		label.add_theme_color_override("font_color",Color("#294B58"))
		column.add_child(label)
	detail=Label.new()
	detail.text="去鳥類樂園找找八位鳥兒朋友吧！"
	detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size",19)
	detail.add_theme_color_override("font_color",Color("#294B58"))
	add_child(detail)

func _describe(info: Dictionary,owned: bool) -> void:
	detail.text=("%s：%s" % [str(info["name"]),str(info.get("desc",""))]) if owned else "還沒找到%s，到鳥類樂園去找牠吧！" % str(info["name"])
	if narrator!=null:
		narrator.speak(detail.text)
