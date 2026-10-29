extends VBoxContainer
## Six persistent plots. Plant, water once to speed up, harvest, fill the basket.
signal farm_requested
const Rules=preload("res://scripts/GardenRules.gd")
const CropArt=preload("res://scripts/CropArt.gd")
var store
var narrator
var selected_crop: String="carrot"
var seed_buttons: Array=[]
var plot_buttons: Array=[]
var plot_images: Array=[]
var plot_texts: Array=[]
var basket_label: Label
var hint_label: Label
var elapsed: float=0.0

func setup(data_store,voice) -> void:
	store=data_store
	narrator=voice

func _ready() -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",7)
	var top=HBoxContainer.new()
	top.alignment=BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation",14)
	add_child(top)
	basket_label=_label("",20)
	basket_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(basket_label)
	top.add_child(_button("🐾 去餵動物",Callable(self,"_go_farm"),Vector2(178,52)))
	var seeds=HBoxContainer.new()
	seeds.alignment=BoxContainer.ALIGNMENT_CENTER
	seeds.add_theme_constant_override("separation",14)
	add_child(seeds)
	for crop in Rules.CROPS:
		var b=_button("%s %s" % [str(crop["emoji"]),str(crop["name"])],
			Callable(self,"select_seed").bind(str(crop["id"])),Vector2(168,56))
		seeds.add_child(b)
		seed_buttons.append(b)
	var content=HBoxContainer.new()
	content.size_flags_vertical=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",15)
	add_child(content)
	var grid=GridContainer.new()
	grid.columns=3
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	content.add_child(grid)
	for i in range(6):
		var card=_button("",Callable(self,"press_plot").bind(i),Vector2(190,146))
		grid.add_child(card)
		plot_buttons.append(card)
		var view=VBoxContainer.new()
		view.mouse_filter=Control.MOUSE_FILTER_IGNORE
		view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		view.offset_left=6
		view.offset_right=-6
		view.offset_top=5
		view.offset_bottom=-4
		card.add_child(view)
		var drawing=CropArt.new()
		drawing.mouse_filter=Control.MOUSE_FILTER_IGNORE
		drawing.custom_minimum_size=Vector2(165,106)
		drawing.size_flags_vertical=Control.SIZE_EXPAND_FILL
		view.add_child(drawing)
		plot_images.append(drawing)
		var tag=_label("",16)
		view.add_child(tag)
		plot_texts.append(tag)
	var guide=VBoxContainer.new()
	guide.custom_minimum_size=Vector2(225,0)
	guide.add_theme_constant_override("separation",8)
	content.add_child(guide)
	guide.add_child(_label("🌻 種菜小教室",23))
	guide.add_child(_label("① 選擇蔬菜種子\n② 點一塊空田種下\n③ 再點一次澆水\n④ 長大後點擊收成",18))
	guide.add_child(_label("💧 澆水會縮短等待\n🥕 收成放進蔬菜籃\n💗 動物吃到會開心",17))
	hint_label=_label("種子免費，田地不會枯萎！",19)
	add_child(hint_label)
	_refresh()
	if narrator!=null:
		narrator.speak("歡迎來開心農田！挑選胡蘿蔔、小白菜或南瓜，再點空田種下。澆水能讓菜長得更快。")

func _label(value: String,amount: int) -> Label:
	var l=Label.new()
	l.text=value
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",amount)
	l.add_theme_color_override("font_color",Color("#315247"))
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func _button(title: String,callback: Callable,dimensions: Vector2) -> Button:
	var b=Button.new()
	b.text=title
	b.custom_minimum_size=dimensions
	b.add_theme_font_size_override("font_size",21)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		b.add_theme_color_override(key,Color("#273F38"))
	var box=StyleBoxFlat.new()
	box.bg_color=Color("#FFF0C9")
	box.border_color=Color("#9F794B")
	box.set_border_width_all(3)
	box.set_corner_radius_all(16)
	box.content_margin_left=11
	box.content_margin_right=11
	box.content_margin_top=7
	box.content_margin_bottom=7
	b.add_theme_stylebox_override("normal",box)
	var hover=box.duplicate()
	hover.bg_color=Color("#FFE3A2")
	b.add_theme_stylebox_override("hover",hover)
	var pressed=box.duplicate()
	pressed.bg_color=Color("#F4D189")
	b.add_theme_stylebox_override("pressed",pressed)
	b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	b.pressed.connect(callback)
	return b

func select_seed(id: String) -> void:
	if Rules.crop_for(id).is_empty():
		return
	selected_crop=id
	_refresh()
	if narrator!=null:
		narrator.speak("選好%s了！點空田就能種下。" % str(Rules.crop_for(id)["name"]))

func press_plot(index: int) -> void:
	var now=int(Time.get_unix_time_from_system())
	var plots: Array=store.data.get("garden_plots",[])
	if index<0 or index>=plots.size():
		return
	var plot: Dictionary=plots[index]
	var crop_id=str(plot.get("crop",""))
	var message: String=""
	if crop_id.is_empty():
		if store.garden_plant(index,selected_crop,now):
			message="🌱 種下%s，等待發芽！" % str(Rules.crop_for(selected_crop)["name"])
	elif now>=int(plot.get("ready_at",0)):
		if store.garden_harvest(index,now):
			var crop: Dictionary=Rules.crop_for(crop_id)
			message="🧺 收成%s，獲得%d份！" % [str(crop["name"]),int(crop["harvest"])]
	elif not bool(plot.get("watered",false)):
		if store.garden_water(index,now):
			message="💧 澆水成功，蔬菜長得更快了！"
	else:
		message="🌿 正在長大，再等%s就可以收成！" % Rules.wait_text(
			int(plot.get("ready_at",now))-now)
	hint_label.text=message
	if narrator!=null and not message.is_empty():
		narrator.speak(message)
	_refresh()

func _refresh() -> void:
	if store==null or plot_buttons.is_empty():
		return
	var inventory: Dictionary=store.data.get("garden_inventory",{})
	basket_label.text="🧺 蔬菜籃　🥕 %d　🥬 %d　🎃 %d" % [
		int(inventory.get("carrot",0)),int(inventory.get("cabbage",0)),
		int(inventory.get("pumpkin",0))]
	for i in range(seed_buttons.size()):
		var seed=Rules.CROPS[i]
		var active=str(seed["id"])==selected_crop
		var style=seed_buttons[i].get_theme_stylebox("normal").duplicate()
		style.bg_color=Color("#C7EBC4") if active else Color("#FFF0C9")
		style.border_color=Color("#437F5C") if active else Color("#9F794B")
		seed_buttons[i].add_theme_stylebox_override("normal",style)
	var now=int(Time.get_unix_time_from_system())
	var plots: Array=store.data.get("garden_plots",[])
	for i in range(plot_buttons.size()):
		if i>=plots.size():
			continue
		var plot: Dictionary=plots[i]
		var id=str(plot.get("crop",""))
		var crop=Rules.crop_for(id)
		var stage=Rules.stage(plot,now)
		plot_images[i].setup(id,stage)
		var text_value="%d 號田 · 點一下種菜" % (i+1)
		if not crop.is_empty():
			var name=str(crop["name"])
			if stage==3:
				text_value="✨ %s · 點擊收成" % name
			elif not bool(plot.get("watered",false)):
				text_value="💧 %s · 點擊澆水" % name
			else:
				text_value="🌱 %s · %s" % [name,Rules.wait_text(int(plot.get("ready_at",now))-now)]
		plot_texts[i].text=text_value
		var style=plot_buttons[i].get_theme_stylebox("normal").duplicate()
		style.bg_color=Color("#E4F5D6") if stage==3 else (
			Color("#EAF5E2") if stage>0 else Color("#F9EAD4"))
		style.border_color=Color("#579766") if stage==3 else Color("#B2906B")
		plot_buttons[i].add_theme_stylebox_override("normal",style)

func _process(delta: float) -> void:
	elapsed+=minf(delta,.5)
	if elapsed>=1.0:
		elapsed=0.0
		_refresh()

func _go_farm() -> void:
	farm_requested.emit()
