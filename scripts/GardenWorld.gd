extends VBoxContainer
## Child-friendly sowing: drag a vegetable icon over one or many empty plots.
signal farm_requested
const Rules=preload("res://scripts/GardenRules.gd")
const CropArt=preload("res://scripts/CropArt.gd")
const StockTile=preload("res://scripts/CropStockTile.gd")

var store
var narrator
var selected_crop: String="carrot"
var seed_buttons: Array=[]
var plot_buttons: Array=[]
var plot_images: Array=[]
var plot_texts: Array=[]
var inventory_tiles: Dictionary={}
var basket_label: Label
var selected_hint: Label
var hint_label: Label
var elapsed: float=0.0
var drag_preview: Control
var pointer_id: int=-1
var pointer_is_touch: bool=false
var drag_crop: String=""
var drag_origin: Vector2=Vector2.ZERO
var drag_previous: Vector2=Vector2.ZERO
var drag_active: bool=false
var planted_in_drag: Dictionary={}
var drag_planted_count: int=0
const DRAG_THRESHOLD: float=19.0
const DRAG_SAMPLE_STEP: float=12.0

func setup(data_store,voice) -> void:
	store=data_store
	narrator=voice

func _ready() -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",6)
	var top=HBoxContainer.new()
	top.add_theme_constant_override("separation",14)
	add_child(top)
	basket_label=_label("🧺",23)
	top.add_child(basket_label)
	for crop in Rules.CROPS:
		var tile=StockTile.new()
		tile.compact=true
		tile.setup(str(crop["id"]))
		top.add_child(tile)
		inventory_tiles[str(crop["id"])]=tile
	var spacer=Control.new()
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(_button("🐾 去餵動物",Callable(self,"_go_farm"),Vector2(174,46)))
	var seeds=HBoxContainer.new()
	seeds.alignment=BoxContainer.ALIGNMENT_CENTER
	seeds.add_theme_constant_override("separation",10)
	add_child(seeds)
	for crop in Rules.CROPS:
		var id=str(crop["id"])
		var b=_button("",Callable(self,"select_seed").bind(id),Vector2(183,66))
		seeds.add_child(b)
		seed_buttons.append(b)
		var body=HBoxContainer.new()
		body.mouse_filter=Control.MOUSE_FILTER_IGNORE
		body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(body)
		var illustration=CropArt.new()
		illustration.setup(id,3)
		illustration.mouse_filter=Control.MOUSE_FILTER_IGNORE
		illustration.custom_minimum_size=Vector2(68,57)
		body.add_child(illustration)
		body.add_child(_label("種 "+str(crop["name"]),20))
	selected_hint=_label("",17)
	selected_hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	seeds.add_child(selected_hint)
	var content=HBoxContainer.new()
	content.size_flags_vertical=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",14)
	add_child(content)
	var grid=GridContainer.new()
	grid.columns=3
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	content.add_child(grid)
	for i in range(6):
		var card=_button("",Callable(self,"press_plot").bind(i),Vector2(180,136))
		grid.add_child(card)
		plot_buttons.append(card)
		var body=VBoxContainer.new()
		body.mouse_filter=Control.MOUSE_FILTER_IGNORE
		body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		body.offset_left=4
		body.offset_right=-4
		body.offset_top=1
		body.offset_bottom=-3
		card.add_child(body)
		var illustration=CropArt.new()
		illustration.mouse_filter=Control.MOUSE_FILTER_IGNORE
		illustration.custom_minimum_size=Vector2(158,98)
		illustration.size_flags_vertical=Control.SIZE_EXPAND_FILL
		body.add_child(illustration)
		plot_images.append(illustration)
		var tag=_label("",17)
		body.add_child(tag)
		plot_texts.append(tag)
	var guide=VBoxContainer.new()
	guide.custom_minimum_size=Vector2(222,0)
	guide.add_theme_constant_override("separation",9)
	content.add_child(guide)
	guide.add_child(_label("🌻 拖曳種菜",22))
	guide.add_child(_label("👆 按住上方蔬菜\n拖到空田就種下！\n👉 不放開繼續滑\n可以一次種好多田！\n💧 點幼苗澆水\n🧺 點成熟蔬菜收成",18))
	guide.add_child(_button("💧 全部澆水",Callable(self,"water_all"),Vector2(208,51)))
	guide.add_child(_button("🧺 全部收成",Callable(self,"harvest_all"),Vector2(208,51)))
	guide.add_child(_label("種子免費，不會枯死！\n收成後就能餵動物 💗",17))
	hint_label=_label("👆 拖住上方蔬菜圖案，滑過空田就能連續種菜！",19)
	add_child(hint_label)
	# A separate canvas layer keeps the dragged vegetable above cards, and
	# never changes the layout or steals child touch events.
	var overlay=CanvasLayer.new()
	overlay.layer=8
	add_child(overlay)
	drag_preview=CropArt.new()
	drag_preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	drag_preview.size=Vector2(96,82)
	drag_preview.modulate=Color(1,1,1,.90)
	drag_preview.hide()
	overlay.add_child(drag_preview)
	_refresh()
	if narrator!=null:
		narrator.speak("歡迎來開心農田！按住上方蔬菜圖案，拖到空田就會種下。繼續拖過其他空田，可以一次種好多田！")

func _label(value: String,font_size: int) -> Label:
	var l=Label.new()
	l.text=value
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",Color("#294E3E"))
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func _button(value: String,callback: Callable,minimum: Vector2) -> Button:
	var b=Button.new()
	b.text=value
	b.custom_minimum_size=minimum
	b.add_theme_font_size_override("font_size",21)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		b.add_theme_color_override(key,Color("#273F38"))
	b.add_theme_color_override("font_disabled_color",Color("#53675B"))
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#FFF1CE")
	style.border_color=Color("#9F794B")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.content_margin_left=8
	style.content_margin_right=8
	style.content_margin_top=6
	style.content_margin_bottom=6
	b.add_theme_stylebox_override("normal",style)
	var hover=style.duplicate()
	hover.bg_color=Color("#FFE0A0")
	b.add_theme_stylebox_override("hover",hover)
	var down=style.duplicate()
	down.bg_color=Color("#F6CF83")
	b.add_theme_stylebox_override("pressed",down)
	b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	b.pressed.connect(callback)
	return b

func select_seed(id: String) -> void:
	if Rules.crop_for(id).is_empty():
		return
	selected_crop=id
	hint_label.text="👆 按住%s拖到空田，還能連續拖過好幾塊田！" % str(Rules.crop_for(id)["name"])
	_refresh()
	if narrator!=null:
		narrator.speak(hint_label.text)

func press_plot(index: int) -> void:
	var now=int(Time.get_unix_time_from_system())
	var plots: Array=store.data.get("garden_plots",[])
	if index<0 or index>=plots.size():
		return
	var plot: Dictionary=plots[index]
	var id=str(plot.get("crop",""))
	var msg: String=""
	if id.is_empty():
		msg="👆 請從上方拖一株蔬菜到空田，滑過多塊田也可以喔！"
	elif now>=int(plot.get("ready_at",0)):
		if store.garden_harvest(index,now):
			var crop=Rules.crop_for(id)
			msg="🧺 收成%s +%d份！菜籃庫存已增加。" % [str(crop["name"]),int(crop["harvest"])]
	elif not bool(plot.get("watered",false)):
		if store.garden_water(index,now):
			msg="💧 澆水成功，蔬菜長得更快囉！"
	else:
		msg="🌿 正在長大，再等%s就能收成！" % Rules.wait_text(int(plot["ready_at"])-now)
	if not msg.is_empty():
		hint_label.text=msg
		if narrator!=null:
			narrator.speak(msg)
	_refresh()


func _input(event: InputEvent) -> void:
	# Capture the starting vegetable at the beginning of a touch or mouse
	# gesture. We process the whole gesture here so a swipe across multiple
	# Buttons plants continuously instead of becoming one click per field.
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_seed_pointer(event.index,event.position,true)
		elif pointer_is_touch and event.index==pointer_id:
			_end_seed_pointer(event.position)
	elif event is InputEventScreenDrag:
		if pointer_is_touch and event.index==pointer_id:
			_move_seed_pointer(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and pointer_id==-1:
			_begin_seed_pointer(-2,event.position,false)
		elif not event.pressed and pointer_id==-2 and not pointer_is_touch:
			_end_seed_pointer(event.position)
	elif event is InputEventMouseMotion:
		if pointer_id==-2 and not pointer_is_touch:
			_move_seed_pointer(event.position)

func _begin_seed_pointer(id: int,position: Vector2,touch: bool) -> void:
	if pointer_id!=-1:
		return
	for i in range(seed_buttons.size()):
		if seed_buttons[i].get_global_rect().has_point(position):
			pointer_id=id
			pointer_is_touch=touch
			drag_crop=str(Rules.CROPS[i]["id"])
			selected_crop=drag_crop
			drag_origin=position
			drag_previous=position
			drag_active=false
			drag_planted_count=0
			planted_in_drag.clear()
			_refresh()
			return

func _move_seed_pointer(position: Vector2) -> void:
	if pointer_id==-1:
		return
	if not drag_active:
		if drag_origin.distance_to(position)<DRAG_THRESHOLD:
			return
		drag_active=true
		drag_preview.setup(drag_crop,3)
		drag_preview.show()
	drag_preview.position=position-drag_preview.size*.5
	_plant_along_segment(drag_previous if drag_previous.distance_to(drag_origin)>=DRAG_THRESHOLD else drag_origin,position)
	drag_previous=position
	get_viewport().set_input_as_handled()

func _plant_along_segment(from: Vector2,to: Vector2) -> void:
	if not drag_active or store==null:
		return
	# Sweep along the entire path, so quick finger movements never skip a
	# field between input frames. Empty plots are planted at most once.
	var steps=maxi(1,int(ceil(from.distance_to(to)/DRAG_SAMPLE_STEP)))
	for n in range(steps+1):
		var point=from.lerp(to,float(n)/float(steps))
		var index=_plot_at_position(point)
		if index<0 or planted_in_drag.has(index):
			continue
		planted_in_drag[index]=true
		if store.garden_plant(index,drag_crop,int(Time.get_unix_time_from_system())):
			drag_planted_count+=1
			_refresh()

func _plot_at_position(position: Vector2) -> int:
	for i in range(plot_buttons.size()):
		if plot_buttons[i].get_global_rect().has_point(position):
			return i
	return -1

func _end_seed_pointer(position: Vector2) -> void:
	if pointer_id==-1:
		return
	if drag_active:
		_plant_along_segment(drag_previous,position)
		var name=str(Rules.crop_for(drag_crop).get("name","蔬菜"))
		if drag_planted_count>0:
			hint_label.text="🌱 成功種下 %d 塊%s！繼續拖就能種更多！" % [drag_planted_count,name]
		else:
			hint_label.text="🌱 沒有空田可以種，請拖到空田喔！"
		if narrator!=null:
			narrator.speak(hint_label.text)
		get_viewport().set_input_as_handled()
	drag_preview.hide()
	pointer_id=-1
	pointer_is_touch=false
	drag_crop=""
	drag_active=false
	planted_in_drag.clear()

func water_all() -> void:
	var now=int(Time.get_unix_time_from_system())
	var count=0
	for i in range(store.data.get("garden_plots",[]).size()):
		if store.garden_water(i,now):
			count+=1
	hint_label.text="💧 已幫 %d 塊田澆水！" % count if count>0 else "💧 目前沒有需要澆水的田地"
	_refresh()
	if narrator!=null:
		narrator.speak(hint_label.text)

func harvest_all() -> void:
	var now=int(Time.get_unix_time_from_system())
	var count=0
	var gained=0
	var snapshot: Array=store.data.get("garden_plots",[]).duplicate(true)
	for i in range(snapshot.size()):
		var crop=Rules.crop_for(str(snapshot[i].get("crop","")))
		if store.garden_harvest(i,now):
			count+=1
			gained+=int(crop.get("harvest",0))
	hint_label.text="🧺 收成 %d 塊田，共 %d 份蔬菜放進菜籃！" % [count,gained] if count>0 else "🌱 還沒有成熟蔬菜，等一下再來！"
	_refresh()
	if narrator!=null:
		narrator.speak(hint_label.text)

func _refresh() -> void:
	if store==null or plot_buttons.is_empty():
		return
	var basket: Dictionary=store.data.get("garden_inventory",{})
	for crop in Rules.CROPS:
		var id=str(crop["id"])
		inventory_tiles[id].set_count(int(basket.get(id,0)))
		for i in range(seed_buttons.size()):
			if str(Rules.CROPS[i]["id"])==id:
				var style=seed_buttons[i].get_theme_stylebox("normal").duplicate()
				var active=id==selected_crop
				style.bg_color=Color("#D5EDBC") if active else Color("#FFF1CE")
				style.border_color=Color("#437F5C") if active else Color("#9F794B")
				seed_buttons[i].add_theme_stylebox_override("normal",style)
	selected_hint.text="👆 按住蔬菜往下拖，可連種多田"
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
		var label="%d 號田 · 🌱 拖菜來種" % (i+1)
		if not crop.is_empty():
			var name=str(crop["name"])
			if stage==3:
				label="🧺 收成%s +%d" % [name,int(crop["harvest"])]
			elif not bool(plot.get("watered",false)):
				label="💧 幫%s澆水" % name
			else:
				label="🌿 %s · 剩%s" % [name,Rules.wait_text(int(plot.get("ready_at",now))-now)]
		plot_texts[i].text=label
		var style=plot_buttons[i].get_theme_stylebox("normal").duplicate()
		style.bg_color=Color("#E0F3CE") if stage==3 else (Color("#EAF5E2") if stage>0 else Color("#F9EAD4"))
		style.border_color=Color("#478D60") if stage==3 else Color("#B2906B")
		plot_buttons[i].add_theme_stylebox_override("normal",style)

func _process(delta: float) -> void:
	elapsed+=minf(delta,.5)
	if elapsed>=1.0:
		elapsed=0.0
		_refresh()

func _go_farm() -> void:
	farm_requested.emit()
