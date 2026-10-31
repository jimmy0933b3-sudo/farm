extends VBoxContainer
## Child-friendly sowing: drag a vegetable icon over one or many empty plots.
signal farm_requested
const Rules=preload("res://scripts/GardenRules.gd")
const CropArt=preload("res://scripts/CropArt.gd")
const StockTile=preload("res://scripts/CropStockTile.gd")
const GardenBedArt=preload("res://scripts/GardenBedArt.gd")

var store
var narrator
var selected_crop: String="carrot"
var seed_buttons: Array=[]
var plot_buttons: Array=[]
var plot_images: Array=[]
var plot_beds: Array=[]
var plot_texts: Array=[]
var inventory_tiles: Dictionary={}
var basket_label: Label
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
	# A narrow top toolbar with icons only. Real illustrated crop stock stays
	# visible without dedicating a row of large inventory cards to it.
	var top=HBoxContainer.new()
	top.alignment=BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation",9)
	add_child(top)
	basket_label=_label("🧺",25)
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
	var collect=_button("🌾",Callable(self,"harvest_all"),Vector2(52,48))
	collect.tooltip_text="收成所有成熟蔬菜"
	top.add_child(collect)
	var feed=_button("🐾",Callable(self,"_go_farm"),Vector2(52,48))
	feed.tooltip_text="帶蔬菜去餵動物"
	top.add_child(feed)
	# Pick a pictured crop by dragging it. No written tutorial occupies the top.
	var seeds=HBoxContainer.new()
	seeds.alignment=BoxContainer.ALIGNMENT_CENTER
	seeds.add_theme_constant_override("separation",14)
	add_child(seeds)
	for crop in Rules.CROPS:
		var id=str(crop["id"])
		var b=_button("",Callable(self,"select_seed").bind(id),Vector2(112,70))
		b.tooltip_text="按住並拖曳%s到田地" % str(crop["name"])
		seeds.add_child(b)
		seed_buttons.append(b)
		var illustration=CropArt.new()
		illustration.setup(id,3)
		illustration.mouse_filter=Control.MOUSE_FILTER_IGNORE
		illustration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(illustration)
	# Raised beds arranged compactly on green ground, surrounded by paths.
	var content=CenterContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_child(content)
	var meadow=PanelContainer.new()
	var meadow_style=StyleBoxFlat.new()
	meadow_style.bg_color=Color("#BFDCA0")
	meadow_style.border_color=Color("#8DB76D")
	meadow_style.set_border_width_all(3)
	meadow_style.set_corner_radius_all(23)
	meadow_style.content_margin_left=20
	meadow_style.content_margin_right=20
	meadow_style.content_margin_top=14
	meadow_style.content_margin_bottom=14
	meadow.add_theme_stylebox_override("panel",meadow_style)
	content.add_child(meadow)
	var grid=GridContainer.new()
	grid.columns=3
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",9)
	meadow.add_child(grid)
	for i in range(6):
		var card=_button("",Callable(self,"press_plot").bind(i),Vector2(156,116))
		# The illustrated soil itself is the visual button, without a flat card.
		card.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		card.add_theme_stylebox_override("disabled",StyleBoxEmpty.new())
		card.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		card.tooltip_text="田地 %d：拖菜種植，成熟後點一下收成" % (i+1)
		grid.add_child(card)
		plot_buttons.append(card)
		var body=VBoxContainer.new()
		body.mouse_filter=Control.MOUSE_FILTER_IGNORE
		body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		body.offset_left=2
		body.offset_right=-2
		body.offset_top=1
		body.offset_bottom=-2
		body.add_theme_constant_override("separation",0)
		card.add_child(body)
		var art_space=Control.new()
		art_space.mouse_filter=Control.MOUSE_FILTER_IGNORE
		art_space.custom_minimum_size=Vector2(150,89)
		art_space.size_flags_vertical=Control.SIZE_EXPAND_FILL
		body.add_child(art_space)
		var soil=GardenBedArt.new()
		soil.mouse_filter=Control.MOUSE_FILTER_IGNORE
		soil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art_space.add_child(soil)
		plot_beds.append(soil)
		var plant=CropArt.new()
		plant.show_soil=false
		plant.mouse_filter=Control.MOUSE_FILTER_IGNORE
		plant.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art_space.add_child(plant)
		plot_images.append(plant)
		var caption=_label("",16)
		body.add_child(caption)
		plot_texts.append(caption)
	# Feedback appears only after an action. No persistent instruction text.
	hint_label=_label("",17)
	add_child(hint_label)
	var overlay=CanvasLayer.new()
	overlay.layer=8
	add_child(overlay)
	drag_preview=CropArt.new()
	drag_preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	drag_preview.size=Vector2(88,75)
	drag_preview.modulate=Color(1,1,1,.92)
	drag_preview.hide()
	overlay.add_child(drag_preview)
	_refresh()
	if narrator!=null:
		narrator.speak("歡迎來開心農田！拖曳上方的蔬菜圖案到小田地，就能種植。等待倒數結束，點成熟的蔬菜就能收成。")

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
	hint_label.text=""
	_refresh()
	if narrator!=null:
		narrator.speak(str(Rules.crop_for(id)["name"]))

func press_plot(index: int) -> void:
	var now=int(Time.get_unix_time_from_system())
	var plots: Array=store.data.get("garden_plots",[])
	if index<0 or index>=plots.size():
		return
	var plot: Dictionary=plots[index]
	var id=str(plot.get("crop",""))
	var msg: String=""
	if id.is_empty():
		msg="🌱 ⬇️"
	elif now>=int(plot.get("ready_at",0)):
		if store.garden_harvest(index,now):
			var crop=Rules.crop_for(id)
			msg="🧺 +%d" % int(crop["harvest"])
	else:
		# No watering, tapping or acceleration during growth. Countdown
		# runs from the saved planting time even while the app is closed.
		msg="⏳ %s" % Rules.wait_text(int(plot["ready_at"])-now)
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
			hint_label.text="🌱 × %d" % drag_planted_count
		else:
			hint_label.text="🌱 ⬇️"
		if narrator!=null:
			narrator.speak("種好%d塊%s了！" % [drag_planted_count,name] if drag_planted_count>0 else "請拖到空田種植")
		get_viewport().set_input_as_handled()
	drag_preview.hide()
	pointer_id=-1
	pointer_is_touch=false
	drag_crop=""
	drag_active=false
	planted_in_drag.clear()

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
	hint_label.text="🧺 +%d" % gained if count>0 else "⏳"
	_refresh()
	if narrator!=null:
		narrator.speak("收成%d塊田，得到%d份蔬菜！" % [count,gained] if count>0 else "還沒有成熟的蔬菜")

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
		plot_beds[i].set_ripe(stage==3)
		var label="＋"
		if not crop.is_empty():
			if stage==3:
				label="🧺 +%d" % int(crop["harvest"])
			else:
				label="⏳ %s" % Rules.wait_text(int(plot.get("ready_at",now))-now)
		plot_texts[i].text=label

func _process(delta: float) -> void:
	elapsed+=minf(delta,.5)
	if elapsed>=1.0:
		elapsed=0.0
		_refresh()

func _go_farm() -> void:
	farm_requested.emit()
