extends HBoxContainer
## Offline, picture-first coloring room for preschool children.
## All park species are visible; collecting a friend unlocks finger coloring.
const Canvas = preload("res://scripts/ColoringCanvas.gd")
const AnimalArt = preload("res://scripts/AnimalArt.gd")
const TouchAnimalScroll = preload("res://scripts/TouchAnimalScroll.gd")

# Sixty crayons. Keep the first thirty hues stable for saved artwork.
const PALETTE = [
	"#F26A72","#F49E50","#FFD95B","#81CA78","#3FBBAD","#67C8F3","#7189ED",
	"#AD7BE3","#EF98C9","#F1C7A3","#99684D","#747A83","#333F4B","#FFFFFF",
	"#C63F53","#FFB2A6","#E57C2D","#FFE8A2","#C4EA5F","#47984B","#A4E4C1",
	"#157E87","#3164B2","#253C8B","#BCE7FF","#D8BEFA","#793EA4","#D9589D",
	"#BE935E","#182432",
	"#F7B8BD","#FF6B50","#E94D32","#B12B39","#A52D74","#E644B4",
	"#F7C5D9","#FBC97E","#D88745","#8C4C28","#5A3829","#D7B093",
	"#FDF2CE","#D2CF88","#A2BA2E","#627A27","#294A29","#C1E8B3",
	"#49DB94","#08735C","#A6F3E7","#2AA8CD","#0677C9","#152E74",
	"#A0B1F4","#6636BA","#CA9AEA","#704676","#9CAAB5","#111A24"
]

var animals: Array=[]
var store
var voice
var selected_id: String=""
var selected_color: String=PALETTE[0]
var canvas: Control
var palette_buttons: Array=[]
var gallery: GridContainer
var gallery_scroll: ScrollContainer
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
	guide=_label("選好顏色，用手指在朋友身上來回塗滿！",22)
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
	canvas.stroke_began.connect(_on_stroke_began)
	canvas.stroke_finished.connect(_on_stroke_finished)
	canvas.brush_color=selected_color
	paper.add_child(canvas)
	var tools=HBoxContainer.new()
	tools.alignment=BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation",10)
	left.add_child(tools)
	undo_button=_button("上一步",Callable(self,"undo"),Vector2(136,47))
	tools.add_child(undo_button)
	tools.add_child(_button("全部重畫",Callable(self,"reset_coloring"),Vector2(154,47)))
	tools.add_child(_button("聽玩法",Callable(self,"repeat_guide"),Vector2(132,47)))
	left.add_child(_label("彩色筆 · 60 種顏色",17))
	var colors=GridContainer.new()
	# A 10x6 grid uses small swatches to keep the canvas large.
	colors.columns=10
	colors.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	colors.add_theme_constant_override("h_separation",4)
	colors.add_theme_constant_override("v_separation",3)
	left.add_child(colors)
	for hex in PALETTE:
		var button=Button.new()
		button.custom_minimum_size=Vector2(35,24)
		button.tooltip_text="彩色筆 %d" % [palette_buttons.size()+1]
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
	count_label=_label("全部樂園的動物圖案",21)
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
	var scroll=TouchAnimalScroll.new()
	gallery_scroll=scroll
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
		guide.text="所有樂園的角色都在右邊！先去樂園找到朋友，再回來幫牠上色。"
	voice.speak("歡迎動物著色屋！所有樂園的動物、鳥類、昆蟲和怪獸都在這裡。找到新朋友就能幫牠上色，有六十種顏色喔！")

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
	if callback.is_valid():
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
		var owned=store.data["collected"].has(id)
		if owned:
			count+=1
		var b=_button("",Callable(),Vector2(85,91))
		gallery_scroll.wire_button(b,Callable(self,"select_animal").bind(id,true) if owned else Callable(self,"_locked_friend").bind(id))
		var panel=StyleBoxFlat.new()
		panel.bg_color=Color("#D8F4DD") if id==selected_id else (Color("#FFFFFF") if owned else Color("#ECEDEC"))
		panel.border_color=Color("#55A77A") if id==selected_id else (Color("#E4E4D8") if owned else Color("#A9B0B5"))
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
		pic.modulate=Color.WHITE if owned else Color("#A4A4AE")
		col.add_child(pic)
		col.add_child(_label(("" if owned else "🔒")+str(info["name"]),16))
		gallery.add_child(b)
	count_label.text="已認識 %d / %d 位 · 亮色可上色" % [count,animals.size()]

func _locked_friend(id: String) -> void:
	var info=_info(id)
	guide.text="🔒 還沒認識%s！先到樂園找到牠，再回來著色。" % str(info.get("name","朋友"))
	if voice!=null:
		voice.speak(guide.text)

func select_animal(id: String, announce: bool=true) -> void:
	if not store.data["collected"].has(id):
		return
	# Saving is safe on navigation even if a finger was lifted elsewhere.
	canvas.finish_stroke()
	selected_id=id
	clear_armed=false
	history.clear()
	canvas.visible=true
	canvas.setup(id,store.get_coloring(id))
	guide.text="幫「%s」用手指來回塗，慢慢塗滿顏色！" % str(_info(id).get("name","動物"))
	undo_button.disabled=true
	_rebuild_gallery()
	if announce:
		voice.speak("現在幫%s上色。選一種顏色，用手指在身體上慢慢來回塗，塗滿整個區塊。" % str(_info(id).get("name","動物")))

func choose_color(hex: String) -> void:
	if not PALETTE.has(hex):
		return
	selected_color=hex
	canvas.brush_color=hex
	clear_armed=false
	for i in range(palette_buttons.size()):
		var style: StyleBoxFlat=palette_buttons[i].get_theme_stylebox("normal")
		var active=str(PALETTE[i])==hex
		style.border_color=Color("#F2C257") if active else Color("#ACB6C0")
		style.set_border_width_all(5 if active else 2)
		palette_buttons[i].queue_redraw()

func _on_stroke_began() -> void:
	if selected_id.is_empty() or not store.data["collected"].has(selected_id):
		return
	history.append(store.get_coloring(selected_id).duplicate(true))
	if history.size()>40:
		history.pop_front()
	undo_button.disabled=false
	clear_armed=false

func _on_stroke_finished(page: Dictionary) -> void:
	if selected_id.is_empty() or not store.data["collected"].has(selected_id):
		return
	if store.replace_coloring(selected_id,page):
		canvas.colors=store.get_coloring(selected_id)
		canvas.refresh_colors()
		guide.text="繼續來回塗，直到整個區塊都上色！"

func undo() -> void:
	if selected_id=="" or history.is_empty(): return
	canvas.finish_stroke()
	store.replace_coloring(selected_id,history.pop_back())
	canvas.colors=store.get_coloring(selected_id)
	canvas.refresh_colors()
	undo_button.disabled=history.is_empty()
	guide.text="退回上一步，可以繼續上色喔！"

func reset_coloring() -> void:
	if selected_id=="": return
	canvas.finish_stroke()
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
	guide.text="變回黑白線稿了！用手指來回塗滿顏色！"

func repeat_guide() -> void:
	voice.speak("選喜歡的顏色，手指按住圖片並來回移動，像畫畫一樣慢慢塗滿。點一下不會直接填滿。")
