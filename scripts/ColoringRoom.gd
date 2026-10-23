extends HBoxContainer
## Offline, picture-first coloring room for preschool children.
## Only already-collected animals may be colored. Every fill auto-saves.
const Canvas = preload("res://scripts/ColoringCanvas.gd")
const AnimalArt = preload("res://scripts/AnimalArt.gd")

const PALETTE = [
	"#F26A72","#F49E50","#FFD95B","#81CA78","#3FBBAD","#67C8F3","#7189ED",
	"#AD7BE3","#EF98C9","#F1C7A3","#99684D","#747A83","#333F4B","#FFFFFF"
]

var animals: Array=[]
var store
var voice
var selected_id: String=""
var selected_color: String=PALETTE[0]
var canvas: Control
var palette_buttons: Array=[]
var gallery: GridContainer
var guide: Label
var count_label: Label
var clear_armed: bool=false
var history: Array=[]
var undo_button: Button

func setup(data: Array, progress, narrator) -> void:
	animals=data
	store=progress
	voice=narrator

func _ready() -> void:
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",13)
	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",5)
	add_child(left)
	guide=_label("先選動物，再選顏色，用手指點線稿！",22)
	left.add_child(guide)
	var paper=PanelContainer.new()
	paper.size_flags_vertical=Control.SIZE_EXPAND_FILL
	paper.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var background=StyleBoxFlat.new()
	background.bg_color=Color("#FFFFFF")
	background.border_color=Color("#E4D5BD")
	background.set_border_width_all(4)
	background.set_corner_radius_all(23)
	paper.add_theme_stylebox_override("panel",background)
	left.add_child(paper)
	canvas=Canvas.new()
	canvas.mouse_filter=Control.MOUSE_FILTER_STOP
	canvas.custom_minimum_size=Vector2(370,245)
	canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL
	canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	canvas.region_touched.connect(_on_color_region)
	paper.add_child(canvas)
	var tools=HBoxContainer.new()
	tools.alignment=BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation",10)
	left.add_child(tools)
	undo_button=_button("上一步",Callable(self,"undo"),Vector2(136,47))
	tools.add_child(undo_button)
	tools.add_child(_button("全部重畫",Callable(self,"reset_coloring"),Vector2(154,47)))
	tools.add_child(_button("聽玩法",Callable(self,"repeat_guide"),Vector2(132,47)))
	var colors=GridContainer.new()
	colors.columns=7
	colors.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	colors.add_theme_constant_override("h_separation",8)
	colors.add_theme_constant_override("v_separation",5)
	left.add_child(colors)
	for hex in PALETTE:
		var button=Button.new()
		button.custom_minimum_size=Vector2(61,41)
		var style=StyleBoxFlat.new()
		style.bg_color=Color(hex)
		style.border_color=Color("#EBCB78") if hex==selected_color else Color("#ACB6C0")
		style.set_border_width_all(5 if hex==selected_color else 2)
		style.set_corner_radius_all(16)
		button.add_theme_stylebox_override("normal",style)
		button.add_theme_stylebox_override("hover",style)
		button.add_theme_stylebox_override("pressed",style)
		button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		button.pressed.connect(Callable(self,"choose_color").bind(hex))
		colors.add_child(button)
		palette_buttons.append(button)
	var right=VBoxContainer.new()
	right.custom_minimum_size=Vector2(274,0)
	right.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",7)
	add_child(right)
	count_label=_label("選已收集的動物",21)
	right.add_child(count_label)
	var panel=PanelContainer.new()
	panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var frame=StyleBoxFlat.new()
	frame.bg_color=Color("#FFF8E9")
	frame.set_corner_radius_all(18)
	frame.set_border_width_all(2)
	frame.border_color=Color("#FFFFFF")
	panel.add_theme_stylebox_override("panel",frame)
	right.add_child(panel)
	var scroll=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll)
	gallery=GridContainer.new()
	gallery.columns=3
	gallery.add_theme_constant_override("h_separation",5)
	gallery.add_theme_constant_override("v_separation",5)
	scroll.add_child(gallery)
	_rebuild_gallery()
	var collected: Array=_collected_ids()
	if not collected.is_empty():
		select_animal(str(collected[0]),false)
	else:
		canvas.visible=false
		guide.text="先去農場或森林收集動物，就能幫牠們上色！"
	voice.speak("歡迎動物著色屋！先選已收集的動物，再選喜歡的顏色，點動物的耳朵、頭或身體，就會變成那個顏色。")

func _collected_ids() -> Array:
	var result: Array=[]
	for info in animals:
		var id=str(info["id"])
		if store.data["collected"].has(id):
			result.append(id)
	return result

func _label(value: String, font: int) -> Label:
	var l=Label.new()
	l.text=value
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",font)
	l.add_theme_color_override("font_color",Color("#3B4B50"))
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func _button(label: String, callback: Callable, minimum: Vector2) -> Button:
	var b=Button.new()
	b.text=label
	b.custom_minimum_size=minimum
	b.add_theme_font_size_override("font_size",21)
	b.add_theme_color_override("font_color",Color("#354C4B"))
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#FFF2D7")
	style.set_corner_radius_all(18)
	style.set_border_width_all(2)
	style.border_color=Color("#FFFFFF")
	b.add_theme_stylebox_override("normal",style)
	b.pressed.connect(callback)
	return b

func _info(id: String) -> Dictionary:
	for a in animals:
		if str(a["id"])==id:
			return a
	return {}

func _rebuild_gallery() -> void:
	for node in gallery.get_children():
		gallery.remove_child(node)
		node.queue_free()
	var count=0
	for info in animals:
		var id=str(info["id"])
		if not store.data["collected"].has(id):
			continue
		count+=1
		var b=_button("",Callable(self,"select_animal").bind(id,true),Vector2(85,91))
		var panel=StyleBoxFlat.new()
		panel.bg_color=Color("#D8F4DD") if id==selected_id else Color("#FFFFFF")
		panel.border_color=Color("#55A77A") if id==selected_id else Color("#E4E4D8")
		panel.set_border_width_all(3)
		panel.set_corner_radius_all(14)
		b.add_theme_stylebox_override("normal",panel)
		b.clip_contents=true
		var col=VBoxContainer.new()
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		col.offset_left=4
		col.offset_right=-4
		col.offset_top=3
		col.offset_bottom=-3
		col.mouse_filter=Control.MOUSE_FILTER_IGNORE
		b.add_child(col)
		var pic=AnimalArt.new()
		pic.setup(info)
		pic.custom_minimum_size=Vector2(74,65)
		pic.size_flags_vertical=Control.SIZE_EXPAND_FILL
		pic.mouse_filter=Control.MOUSE_FILTER_IGNORE
		col.add_child(pic)
		col.add_child(_label(str(info["name"]),16))
		gallery.add_child(b)
	count_label.text="已收集 %d 隻，可選來上色" % count
	if count==0:
		gallery.add_child(_label("先去探索動物吧！",18))

func select_animal(id: String, announce: bool=true) -> void:
	if not store.data["collected"].has(id):
		return
	selected_id=id
	clear_armed=false
	history.clear()
	canvas.visible=true
	canvas.setup(id,store.get_coloring(id))
	guide.text="幫「%s」選顏色，點身體塗上去！" % str(_info(id).get("name","動物"))
	undo_button.disabled=true
	_rebuild_gallery()
	if announce:
		voice.speak("現在來幫%s上色。選好顏色，再點動物身上的白色區塊。" % str(_info(id).get("name","動物")))

func choose_color(hex: String) -> void:
	if not PALETTE.has(hex):
		return
	selected_color=hex
	clear_armed=false
	for i in range(palette_buttons.size()):
		var style: StyleBoxFlat=palette_buttons[i].get_theme_stylebox("normal")
		var active=str(PALETTE[i])==hex
		style.border_color=Color("#F2C257") if active else Color("#ACB6C0")
		style.set_border_width_all(5 if active else 2)
		palette_buttons[i].queue_redraw()

func _on_color_region(region: String) -> void:
	if selected_id=="" or not store.data["collected"].has(selected_id):
		return
	var previous=store.get_coloring(selected_id)
	if str(previous.get(region,"#FFFFFF")).to_upper()==selected_color.to_upper():
		return
	history.append(previous.duplicate(true))
	if history.size()>40:
		history.pop_front()
	if store.color_animal_region(selected_id,region,selected_color):
		canvas.colors=store.get_coloring(selected_id)
		canvas.refresh_colors()
		guide.text="好漂亮！繼續選顏色，點動物其他地方！"
		undo_button.disabled=false
		clear_armed=false

func undo() -> void:
	if selected_id=="" or history.is_empty(): return
	store.replace_coloring(selected_id,history.pop_back())
	canvas.colors=store.get_coloring(selected_id)
	canvas.refresh_colors()
	undo_button.disabled=history.is_empty()
	guide.text="退回上一步，可以繼續上色喔！"

func reset_coloring() -> void:
	if selected_id=="": return
	if not clear_armed:
		clear_armed=true
		guide.text="再按一次「全部重畫」，才會清掉這隻動物的顏色。"
		voice.speak("再按一次全部重畫，才會把顏色清掉。")
		return
	history.append(store.get_coloring(selected_id).duplicate(true))
	store.replace_coloring(selected_id,{})
	canvas.colors={}
	canvas.refresh_colors()
	undo_button.disabled=false
	clear_armed=false
	guide.text="變回黑白線稿了！選顏色，再畫一次！"

func repeat_guide() -> void:
	voice.speak("選一種喜歡的顏色，點動物的頭、耳朵、身體或尾巴，就能上色。想重畫也可以喔。")
