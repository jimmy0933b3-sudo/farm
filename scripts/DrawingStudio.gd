extends HBoxContainer
## Four-stage animal drawing academy. Child draws on real AnimalArt template,
## traces body/feature/detail, then freely decorates using three stamp shapes.
const Canvas=preload("res://scripts/DrawingLessonCanvas.gd")
const Art=preload("res://scripts/AnimalArt.gd")
const TouchAnimalScroll=preload("res://scripts/TouchAnimalScroll.gd")

const STEP_NAMES=["① 描出身體輪廓","② 畫出大特徵","③ 補上細小部位","④ 自由裝飾作品"]
var animals: Array=[]
var save_data
var narrator
var selected_id: String=""
var drawing: Control
var preview: Control
var gallery: GridContainer
var gallery_scroll: ScrollContainer
var instruction: Label
var status: Label
var advance_button: Button
var color_buttons: Array=[]
var clear_armed: bool=false
var initializing: bool=false
var resident_count: Label

func setup(species: Array, storage, voice) -> void:
	animals=species
	save_data=storage
	narrator=voice

func _label(value: String, font: int) -> Label:
	var lbl=Label.new()
	lbl.text=value
	lbl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color",Color("#34565C"))
	lbl.add_theme_font_size_override("font_size",font)
	lbl.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return lbl

func _button(title: String, action: Callable, minimum: Vector2=Vector2(130,45)) -> Button:
	var b=Button.new()
	b.text=title
	b.custom_minimum_size=minimum
	b.add_theme_font_size_override("font_size",19)
	b.add_theme_color_override("font_color",Color("#39505E"))
	var normal=StyleBoxFlat.new()
	normal.bg_color=Color("#FFF0D3")
	normal.border_color=Color("#FFFFFF")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(15)
	b.add_theme_stylebox_override("normal",normal)
	if action.is_valid():
		b.pressed.connect(action)
	return b

func _ready() -> void:
	add_theme_constant_override("separation",13)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",7)
	add_child(left)
	instruction=_label("選動物或昆蟲，跟著淡藍色點點畫出牠！",21)
	left.add_child(instruction)
	var panel=PanelContainer.new()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var paper=StyleBoxFlat.new()
	paper.bg_color=Color("#FFFEF8")
	paper.border_color=Color("#E7D8BE")
	paper.set_border_width_all(3)
	paper.set_corner_radius_all(20)
	panel.add_theme_stylebox_override("panel",paper)
	left.add_child(panel)
	var surface=Control.new()
	surface.clip_contents=true
	surface.custom_minimum_size=Vector2(420,205)
	surface.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	surface.size_flags_vertical=Control.SIZE_EXPAND_FILL
	panel.add_child(surface)
	preview=Art.new()
	preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preview.modulate=Color(0.39,0.57,0.65,0.23)
	surface.add_child(preview)
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drawing=Canvas.new()
	drawing.mouse_filter=Control.MOUSE_FILTER_STOP
	surface.add_child(drawing)
	drawing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drawing.link_artist(preview)
	drawing.changed.connect(_drawing_changed)
	status=_label("沿著點點畫，先畫身體，再畫特色！",17)
	left.add_child(status)
	var actions=HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",7)
	left.add_child(actions)
	advance_button=_button("完成這一步 ✓",Callable(self,"next_stage"),Vector2(160,46))
	actions.add_child(advance_button)
	actions.add_child(_button("上一步",Callable(self,"undo"),Vector2(105,46)))
	actions.add_child(_button("重新畫",Callable(self,"reset_picture"),Vector2(105,46)))
	var colors=GridContainer.new()
	colors.columns=12
	colors.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	colors.add_theme_constant_override("h_separation",5)
	left.add_child(colors)
	for hex in Canvas.PAINTS:
		var b=Button.new()
		b.custom_minimum_size=Vector2(34,33)
		var style=StyleBoxFlat.new()
		style.bg_color=Color(hex)
		style.border_color=Color("#D59E54") if hex==drawing.brush else Color("#BBC4CA")
		style.set_border_width_all(4 if hex==drawing.brush else 2)
		style.set_corner_radius_all(10)
		for theme in ["normal","pressed","hover"]:
			b.add_theme_stylebox_override(theme,style)
		b.pressed.connect(Callable(self,"select_color").bind(hex))
		colors.add_child(b)
		color_buttons.append(b)
	var stickers=HBoxContainer.new()
	stickers.alignment=BoxContainer.ALIGNMENT_CENTER
	stickers.add_theme_constant_override("separation",7)
	left.add_child(stickers)
	for entry in [["✎ 畫筆","brush"],["★ 星星","star"],["♥ 愛心","heart"],["🐾 腳印","paw"]]:
		stickers.add_child(_button(str(entry[0]),Callable(self,"choose_tool").bind(str(entry[1])),Vector2(116,38)))
	var right=VBoxContainer.new()
	right.custom_minimum_size=Vector2(241,0)
	right.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",7)
	add_child(right)
	resident_count=_label("選一位已收集的朋友",19)
	right.add_child(resident_count)
	var side_panel=PanelContainer.new()
	side_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var frame=StyleBoxFlat.new()
	frame.bg_color=Color("#FFF6E8")
	frame.set_corner_radius_all(16)
	frame.content_margin_left=5
	frame.content_margin_right=5
	side_panel.add_theme_stylebox_override("panel",frame)
	right.add_child(side_panel)
	gallery_scroll=TouchAnimalScroll.new()
	gallery_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	side_panel.add_child(gallery_scroll)
	gallery=GridContainer.new()
	gallery.columns=2
	gallery.add_theme_constant_override("h_separation",5)
	gallery.add_theme_constant_override("v_separation",5)
	gallery_scroll.add_child(gallery)
	_rebuild_gallery()
	var unlocked=_collected()
	if unlocked.is_empty():
		drawing.visible=false
		instruction.text="先去樂園認識動物或昆蟲，才能照著牠的樣子畫畫！"
	else:
		select_animal(str(unlocked[0]),false)
	narrator.speak("歡迎動物畫畫學堂！昆蟲也可以畫喔！先挑一位朋友，順著藍色點點畫身體、畫特色、畫細節，再用星星和愛心裝飾畫作。")

func _collected() -> Array:
	var result=[]
	for info in animals:
		if save_data.data["collected"].has(str(info["id"])):
			result.append(str(info["id"]))
	return result

func _find_info(id: String) -> Dictionary:
	for info in animals:
		if str(info["id"])==id:
			return info
	return {}

func _rebuild_gallery() -> void:
	for old in gallery.get_children():
		gallery.remove_child(old)
		old.queue_free()
	var found=_collected()
	resident_count.text="已收集 %d 隻，選一隻來畫" % found.size()
	for id in found:
		var b=_button("",Callable(),Vector2(107,94))
		gallery_scroll.wire_button(b,Callable(self,"select_animal").bind(id,true))
		var box=VBoxContainer.new()
		box.mouse_filter=Control.MOUSE_FILTER_IGNORE
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(box)
		var art=Art.new()
		art.setup(_find_info(id))
		art.custom_minimum_size=Vector2(88,69)
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		box.add_child(art)
		var title=_label(str(_find_info(id).get("name","動物")),15)
		box.add_child(title)
		gallery.add_child(b)
	if found.is_empty():
		gallery.add_child(_label("先去收集動物或昆蟲！",18))

func select_animal(id: String, announce: bool=true) -> void:
	if not save_data.data["collected"].has(id): return
	if is_instance_valid(drawing): drawing.end_stroke()
	selected_id=id
	clear_armed=false
	drawing.visible=true
	initializing=true
	drawing.setup(_find_info(id),save_data.get_drawing_lesson(id))
	initializing=false
	_update_status()
	if announce:
		narrator.speak("現在來畫%s。先沿著藍色點點慢慢畫，完成一個步驟就能畫下一步！" % str(_find_info(id).get("name","動物")))

func select_color(hex: String) -> void:
	drawing.set_color(hex)
	for i in range(color_buttons.size()):
		var b=color_buttons[i]
		var style: StyleBoxFlat=b.get_theme_stylebox("normal")
		var selected=Canvas.PAINTS[i]==hex
		style.border_color=Color("#D59E54") if selected else Color("#BBC4CA")
		style.set_border_width_all(4 if selected else 2)
		b.queue_redraw()

func choose_tool(kind: String) -> void:
	drawing.set_mode(kind)
	if drawing.stage!=3 and kind!="brush":
		status.text="先沿線描完三步，最後才能蓋星星、愛心和腳印！"
		narrator.speak("先把這位朋友的輪廓畫好，才能自由裝飾。")
	elif kind!="brush":
		status.text="點一下畫紙，就能蓋上喜歡的裝飾！"

func _drawing_changed() -> void:
	if initializing or selected_id.is_empty(): return
	# Persist actual trace paths, unlike the coloring area's region fills.
	if not save_data.replace_drawing_lesson(selected_id,drawing.page):
		return
	_update_status()

func _update_status() -> void:
	if selected_id.is_empty(): return
	if drawing.stage>=3:
		instruction.text="④ 自由裝飾：可以畫背景、蓋星星或腳印"
		var stamp_count=int(drawing.page.get("stamps",[]).size())
		status.text="已放 %d 個裝飾，畫完按完成作品！" % stamp_count
		advance_button.text="完成作品 ★"
		advance_button.disabled=false
	else:
		instruction.text=STEP_NAMES[drawing.stage]+" · %s" % str(_find_info(selected_id).get("name","動物"))
		var percentage=int(drawing.trace_coverage(drawing.stage)*100)
		status.text="描畫進度 %d%%，沿著虛線畫到 57%% 就能下一步" % percentage
		advance_button.text="完成這一步 ✓"
		advance_button.disabled=not drawing.can_advance()

func next_stage() -> void:
	if selected_id.is_empty(): return
	if drawing.stage==3:
		var stars=drawing.finish_picture()
		if stars<=0: return
		instruction.text="太棒了！%s 的畫作完成！" % str(_find_info(selected_id).get("name","動物"))
		status.text="獲得 %d 顆星！可以繼續裝飾，或選其他朋友。" % stars
		narrator.speak("你的%s畫好了！得到%d顆星，太棒了！" % [str(_find_info(selected_id).get("name","動物")),stars])
		return
	if drawing.advance():
		_update_status()
		if drawing.stage==3:
			narrator.speak("三個描畫步驟都完成了！現在可以畫背景、蓋上星星和愛心。")
		else:
			narrator.speak("描得真好！接下來畫%s的下一個部分。" % ("昆蟲" if str(_find_info(selected_id).get("zone",""))=="insect" else "動物"))
	else:
		narrator.speak("再沿著淡藍色的點點慢慢畫一些，就可以過關了。")

func undo() -> void:
	if selected_id.is_empty(): return
	drawing.undo()
	_update_status()

func reset_picture() -> void:
	if selected_id.is_empty(): return
	if not clear_armed:
		clear_armed=true
		status.text="再按一次「重新畫」，才會清除這隻動物的畫作。"
		narrator.speak("要全部重畫嗎？再按一次重新畫。")
		return
	drawing.reset_picture()
	clear_armed=false
	_update_status()

func _exit_tree() -> void:
	if is_instance_valid(drawing):
		drawing.end_stroke()
