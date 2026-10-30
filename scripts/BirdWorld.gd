extends VBoxContainer
## Twelve birds in four habitats, offline discovery and individual abilities.
signal flying_requested
signal album_requested
const BirdArt=preload("res://scripts/BirdArt.gd")
const Scenery=preload("res://scripts/BirdScenery.gd")
const HABITATS=[
	{"id":"wetland","name":"💧 湖畔濕地"},
	{"id":"woodland","name":"🌳 森林樹梢"},
	{"id":"mountain","name":"⛰️ 高空山谷"},
	{"id":"night","name":"🌙 月夜森林"}
]
var birds: Array=[]
var progress
var narrator
var area: String="wetland"
var selected: Dictionary={}
var stage: Control
var scenery
var portrait
var found_label: Label
var info_label: Label
var response_label: Label
var bird_buttons: Array=[]
var area_buttons: Array=[]
var interaction_buttons: Array=[]
var calm: bool=false
var flap_time: float=0.0
var flap_clock: float=0.0

func setup(catalog: Array,store,voice) -> void:
	birds=catalog
	progress=store
	narrator=voice
	calm=bool(store.data.get("settings",{}).get("reduce_motion",false))

func _ready() -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	var top=HBoxContainer.new()
	top.add_theme_constant_override("separation",12)
	add_child(top)
	found_label=_label("",20)
	found_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(found_label)
	top.add_child(_button("📖 鳥類圖鑑",Callable(self,"_open_album"),Vector2(155,54)))
	top.add_child(_button("🏆 飛行大賽",Callable(self,"_open_flight"),Vector2(190,54)))
	var nav=HBoxContainer.new()
	nav.add_theme_constant_override("separation",10)
	nav.alignment=BoxContainer.ALIGNMENT_CENTER
	add_child(nav)
	for habitat in HABITATS:
		var button=_button(str(habitat["name"]),Callable(self,"choose_area").bind(str(habitat["id"])),Vector2(190,54))
		nav.add_child(button)
		area_buttons.append(button)
	var middle=HBoxContainer.new()
	middle.size_flags_vertical=Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation",12)
	add_child(middle)
	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.size_flags_vertical=Control.SIZE_EXPAND_FILL
	middle.add_child(left)
	var guide=_label("找找看：點一下鳥兒，聽牠的介紹並收藏！",19)
	left.add_child(guide)
	stage=Control.new()
	stage.custom_minimum_size=Vector2(485,225)
	stage.size_flags_vertical=Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stage.clip_contents=true
	left.add_child(stage)
	scenery=Scenery.new()
	scenery.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(scenery)
	stage.resized.connect(_position_birds)
	var right=VBoxContainer.new()
	right.custom_minimum_size=Vector2(260,0)
	right.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",4)
	middle.add_child(right)
	info_label=_label("🐦 選一位鳥兒朋友",19)
	right.add_child(info_label)
	portrait=BirdArt.new()
	portrait.custom_minimum_size=Vector2(235,142)
	portrait.size_flags_vertical=Control.SIZE_EXPAND_FILL
	portrait.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	right.add_child(portrait)
	response_label=_label("發現鳥兒就會收藏進圖鑑。",17)
	response_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	right.add_child(response_label)
	for item in [["pet","💗 摸摸牠"],["flap","🪽 飛起來"],["ability","✨ 鳥兒特技"],["story","🔊 聽介紹"]]:
		var button=_button(str(item[1]),Callable(self,"interact").bind(str(item[0])),Vector2(245,44))
		button.disabled=true
		right.add_child(button)
		interaction_buttons.append(button)
	_refresh()
	if narrator!=null:
		narrator.speak("歡迎來鳥類樂園！四個地方共有十二種鳥兒。一起找鳥兒、聽故事，再參加飛行大賽！")

func _label(value: String,font_size: int) -> Label:
	var label=Label.new()
	label.text=value
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("#294B58"))
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	return label

func _button(title: String,callback: Callable,dimensions: Vector2) -> Button:
	var b=Button.new()
	b.text=title
	b.custom_minimum_size=dimensions
	b.add_theme_font_size_override("font_size",20)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		b.add_theme_color_override(key,Color("#223849"))
	b.add_theme_color_override("font_disabled_color",Color("#506070"))
	var box=StyleBoxFlat.new()
	box.bg_color=Color("#FFF1CF")
	box.border_color=Color("#8E7350")
	box.set_border_width_all(3)
	box.set_corner_radius_all(15)
	box.content_margin_left=10
	box.content_margin_right=10
	box.content_margin_top=6
	box.content_margin_bottom=6
	b.add_theme_stylebox_override("normal",box)
	var hover=box.duplicate()
	hover.bg_color=Color("#FFE1B0")
	b.add_theme_stylebox_override("hover",hover)
	var down=box.duplicate()
	down.bg_color=Color("#F5C875")
	b.add_theme_stylebox_override("pressed",down)
	var disabled=box.duplicate()
	disabled.bg_color=Color("#E0E7EA")
	b.add_theme_stylebox_override("disabled",disabled)
	b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	b.pressed.connect(callback)
	return b

func choose_area(id: String) -> void:
	area=id
	selected={}
	_refresh()

func _refresh() -> void:
	if scenery==null:
		return
	scenery.setup(area)
	for i in range(area_buttons.size()):
		var active=area==str(HABITATS[i]["id"])
		var style=area_buttons[i].get_theme_stylebox("normal").duplicate()
		style.bg_color=Color("#BFE8CF") if active else Color("#FFF1CF")
		style.border_color=Color("#427766") if active else Color("#8E7350")
		area_buttons[i].add_theme_stylebox_override("normal",style)
	for old in bird_buttons:
		stage.remove_child(old)
		old.queue_free()
	bird_buttons.clear()
	for bird in birds:
		if str(bird.get("area",""))!=area:
			continue
		var id=str(bird["id"])
		var owned=progress.data.get("bird_found",[]).has(id)
		var card=_button("",Callable(self,"discover").bind(id),Vector2(106,120))
		var frame=card.get_theme_stylebox("normal").duplicate()
		frame.bg_color=Color("#E9F7ED") if owned else Color("#FFF6EA")
		frame.border_color=Color("#4C9A7F") if owned else Color("#AD9167")
		card.add_theme_stylebox_override("normal",frame)
		var stack=VBoxContainer.new()
		stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
		stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(stack)
		var art=BirdArt.new()
		art.setup(bird)
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		art.custom_minimum_size=Vector2(101,89)
		art.size_flags_vertical=Control.SIZE_EXPAND_FILL
		stack.add_child(art)
		stack.add_child(_label(("✓ " if owned else "🔎 ")+str(bird["name"]),17))
		stage.add_child(card)
		card.size=Vector2(106,120)
		bird_buttons.append(card)
	_position_birds()
	var found=0
	for bird in birds:
		if progress.data.get("bird_found",[]).has(str(bird["id"])):
			found+=1
	found_label.text="🐦 已認識 %d / %d 隻鳥兒" % [found,birds.size()]
	portrait.visible=not selected.is_empty()
	if selected.is_empty():
		info_label.text="🐦 選一位鳥兒朋友"
		response_label.text="點一下鳥兒，就能收藏貼紙和聽故事。"
	else:
		info_label.text=str(selected.get("name","鳥兒"))+" · "+str(selected.get("trait",""))
		portrait.setup(selected)
		response_label.text=str(selected.get("desc",""))
	for button in interaction_buttons:
		button.disabled=selected.is_empty()

func _position_birds() -> void:
	if stage==null or stage.size.x<=0.0 or bird_buttons.is_empty():
		return
	# Arrange 5 wetland birds as 3+2, center single owl and two mountain raptors.
	var count=bird_buttons.size()
	var columns=mini(3,count)
	var rows=int(ceil(float(count)/float(columns)))
	var width=bird_buttons[0].size.x
	var height=bird_buttons[0].size.y
	var gap_x=maxf(8.0,minf(58.0,(stage.size.x-float(columns)*width)/float(columns+1)))
	var gap_y=maxf(6.0,(stage.size.y-float(rows)*height)/float(rows+1))
	for i in range(count):
		var row=int(i/columns)
		var col=i%columns
		var in_row=mini(columns,count-row*columns)
		var row_width=float(in_row)*width+float(in_row-1)*gap_x
		var x=maxf(4.0,(stage.size.x-row_width)*.5)+float(col)*(width+gap_x)
		var y=gap_y+float(row)*(height+gap_y)
		bird_buttons[i].position=Vector2(x,y)

func discover(id: String) -> void:
	for bird in birds:
		if str(bird.get("id",""))!=id:
			continue
		var first=not progress.data.get("bird_found",[]).has(id)
		selected=bird
		progress.record_bird_found(id)
		_refresh()
		response_label.text=("🎉 第一次找到！" if first else "歡迎回來！")+str(bird.get("desc",""))
		if narrator!=null:
			narrator.speak(("%s，" % str(bird["name"]))+str(bird.get("desc","")))
		return

func interact(action: String) -> void:
	if selected.is_empty():
		return
	progress.record_bird_interaction(str(selected["id"]))
	var name=str(selected.get("name","鳥兒"))
	match action:
		"pet":
			response_label.text="摸摸%s的羽毛，牠開心地點點頭！" % name
		"flap":
			response_label.text="%s展開翅膀，輕輕飛起來！" % name
			flap_time=1.4
			flap_clock=0.0
		"ability":
			response_label.text=str(selected.get("activity",str(selected.get("name","鳥兒"))+"展示了自己的飛行本領！"))
			flap_time=1.8
			flap_clock=0.0
		"story":
			response_label.text=str(selected.get("desc",""))
	if narrator!=null:
		narrator.speak(response_label.text)

func _process(delta: float) -> void:
	if flap_time<=0.0:
		return
	flap_time=maxf(0.0,flap_time-minf(delta,.1))
	flap_clock+=delta
	portrait.set_flap(sin(flap_clock*16.0) if not calm else 0.0)
	if flap_time<=0.0:
		portrait.set_flap(0.0)

func _open_album() -> void:
	album_requested.emit()

func _open_flight() -> void:
	flying_requested.emit()
