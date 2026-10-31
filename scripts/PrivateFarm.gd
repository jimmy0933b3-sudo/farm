extends VBoxContainer
## Private sanctuary: all 67 species share one permanent top roster and may roam together.
## Touch roaming animals to pet; drag a harvest from the basket to feed.
const AnimalArt = preload("res://scripts/AnimalArt.gd")
const RoamingAnimal = preload("res://scripts/RoamingAnimal.gd")
const SwimmingAnimal = preload("res://scripts/SwimmingAnimal.gd")
const TouchAnimalScroll = preload("res://scripts/TouchAnimalScroll.gd")
const TouchHand = preload("res://scripts/TouchHand.gd")
const PrivateFarmLandscape = preload("res://scripts/PrivateFarmLandscape.gd")
const GardenRules = preload("res://scripts/GardenRules.gd")
const CropArt = preload("res://scripts/CropArt.gd")
const StockTile = preload("res://scripts/CropStockTile.gd")

signal racing_requested
signal garden_requested

const CAPACITY: int = 67

var animals: Array = []
var save_data
var voice
var active_id: String = ""
var actors: Dictionary = {}
var resident_list: HBoxContainer
var resident_scroll: ScrollContainer
var remove_button: Button
var habitat: Control
var farm_view: Control
var camera_x: float = 0.0
var world_width: float = 6500.0
var pointer_last: Vector2 = Vector2.ZERO
var pan_start: Vector2 = Vector2.ZERO
var pan_distance: float = 0.0
var hand: Control
var info_label: Label
var counter: Label
var commands: HBoxContainer
var busy: bool = false
var touching_id: String = ""
var pointer_index: int = -1
var mouse_down: bool = false
var last_touch: Vector2 = Vector2.ZERO
var pet_feedback_count: int = 0
var reduce_motion: bool = false
var farm_inventory_tiles: Dictionary = {}
var stock_strip: HBoxContainer
var last_fed_crop: String = ""
# The basket owns its gesture; empty-ground swipes still pan and pets still work.
var food_pointer: int=-1
var food_touch: bool=false
var food_crop: String=""
var food_drag_origin: Vector2=Vector2.ZERO
var food_dragging: bool=false
var food_preview: Control
var food_hover_id: String=""
const FOOD_DRAG_DISTANCE: float=13.0

func setup(info: Array, store, narrator) -> void:
	animals = info
	save_data = store
	voice = narrator
	reduce_motion = bool(store.data["settings"].get("reduce_motion",false))

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",6)
	add_child(left)

	var farm_header=HBoxContainer.new()
	farm_header.add_theme_constant_override("separation",8)
	left.add_child(farm_header)
	info_label = _label("左右滑動逛農場，摸摸動物吧！",19)
	info_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	farm_header.add_child(info_label)
	farm_header.add_child(_round("🌱 Garden",Callable(self,"_request_garden"),Vector2(125,51)))
	farm_header.add_child(_round("🏎️ Racing",
		Callable(self,"_request_race"),Vector2(144,51)))
	# ONE horizontal, thumb-friendly strip. Every species has one permanent
	# tile, regardless of whether it is currently outside or inside the farm.
	# No second "available animals" section. Swiping never activates a tile.
	var roster_header=HBoxContainer.new()
	roster_header.add_theme_constant_override("separation",12)
	left.add_child(roster_header)
	counter=_label("🌿 0 / 67",19)
	counter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	roster_header.add_child(counter)
	roster_header.add_child(_label("👈  ➡️",20))
	remove_button=_round("Remove",Callable(self,"remove_current"),Vector2(98,41))
	roster_header.add_child(remove_button)
	resident_scroll=TouchAnimalScroll.new()
	resident_scroll.custom_minimum_size=Vector2(0,112)
	resident_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	resident_scroll.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	resident_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	resident_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(resident_scroll)
	resident_list=HBoxContainer.new()
	resident_list.add_theme_constant_override("separation",7)
	resident_scroll.add_child(resident_list)

	# Permanently visible, illustrated basket directly ABOVE the animals.
	# One direct drag to a roaming animal consumes one crop; no feeding menu.
	stock_strip=HBoxContainer.new()
	stock_strip.alignment=BoxContainer.ALIGNMENT_CENTER
	stock_strip.add_theme_constant_override("separation",12)
	left.add_child(stock_strip)
	stock_strip.add_child(_label("🧺",25))
	for crop in GardenRules.CROPS:
		var tile=StockTile.new()
		tile.setup(str(crop["id"]))
		tile.tooltip_text="按住%s拖到動物身上（每次扣 1）" % str(crop["name"])
		stock_strip.add_child(tile)
		farm_inventory_tiles[str(crop["id"])]=tile
	_refresh_farm_stock()
	# Wider-than-the-screen scenery under a fixed, clipped viewport.
	farm_view=Control.new()
	farm_view.custom_minimum_size=Vector2(555,310)
	farm_view.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	farm_view.size_flags_vertical=Control.SIZE_EXPAND_FILL
	farm_view.clip_contents=true
	farm_view.mouse_filter=Control.MOUSE_FILTER_STOP
	left.add_child(farm_view)
	habitat=Control.new()
	habitat.mouse_filter=Control.MOUSE_FILTER_IGNORE
	habitat.clip_contents=true
	habitat.size=Vector2(world_width,330)
	farm_view.add_child(habitat)
	farm_view.resized.connect(_resize_world)
	farm_view.gui_input.connect(_on_habitat_input)
	call_deferred("_resize_world")

	var bg = PrivateFarmLandscape.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	habitat.add_child(bg)

	hand = TouchHand.new()
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hand.show_hand = false
	habitat.add_child(hand)
	habitat.resized.connect(_layout_residents)

	commands = HBoxContainer.new()
	commands.alignment = BoxContainer.ALIGNMENT_CENTER
	commands.add_theme_constant_override("separation",6)
	left.add_child(commands)
	for data in [["wash","Bath"],["play","Play"],["sleep","Rest"],["sound","Sound"]]:
		var btn=_round(str(data[1]),Callable(self,"interact").bind(str(data[0])),Vector2(114,52))
		btn.disabled=true
		commands.add_child(btn)


	if not save_data.data["private_farm"].is_empty():
		active_id = str(save_data.data["private_farm"][0])
	_sync_residents()
	_rebuild_cards()
	call_deferred("_layout_residents")
	# Above all page content, without taking touches away from animal petting.
	var drag_layer=CanvasLayer.new()
	drag_layer.layer=9
	add_child(drag_layer)
	food_preview=CropArt.new()
	food_preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	food_preview.size=Vector2(100,92)
	food_preview.show_soil=false
	food_preview.modulate=Color(1,1,1,.9)
	food_preview.hide()
	drag_layer.add_child(food_preview)
	voice.speak("歡迎來到大大的私人農場！從菜籃拖曳蔬菜到動物身上就能餵食。手指左右滑動逛地圖，會飛的昆蟲在天空，螳螂、糞金龜和象鼻蟲在草地上爬行，右邊有大水池喔！也可以玩賽車！")

func _label(value: String, size_value: int) -> Label:
	var l = Label.new()
	l.text = value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",size_value)
	l.add_theme_color_override("font_color",Color("#31594A"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _round(title: String, action: Callable, minimum: Vector2) -> Button:
	var btn = Button.new()
	btn.text = title
	btn.custom_minimum_size = minimum
	btn.add_theme_font_size_override("font_size",19)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		btn.add_theme_color_override(state,Color("#233E39"))
	btn.add_theme_color_override("font_disabled_color",Color("#54685E"))
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#FFE6AE")
	style.set_corner_radius_all(17)
	style.set_border_width_all(3)
	style.border_color = Color("#B08A5B")
	style.content_margin_left=9
	style.content_margin_right=9
	style.content_margin_top=7
	style.content_margin_bottom=7
	btn.add_theme_stylebox_override("normal",style)
	var hover=style.duplicate()
	hover.bg_color=Color("#FFF0D0")
	btn.add_theme_stylebox_override("hover",hover)
	var pressed=style.duplicate()
	pressed.bg_color=Color("#F5C980")
	btn.add_theme_stylebox_override("pressed",pressed)
	var disabled=style.duplicate()
	disabled.bg_color=Color("#E9ECE8")
	disabled.border_color=Color("#B4BDB5")
	btn.add_theme_stylebox_override("disabled",disabled)
	btn.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	if action.is_valid():
		btn.pressed.connect(action)
	return btn

func _animal(id: String) -> Dictionary:
	for a in animals:
		if str(a.get("id","")) == id:
			return a
	return {}

func _card(info: Dictionary,selected: bool,is_member: bool,unlocked: bool) -> Button:
	var id=str(info.get("id",""))
	var tile=_round("",Callable(),Vector2(100,104))
	resident_scroll.wire_button(tile,Callable(self,"_toggle_resident").bind(id))
	var panel=StyleBoxFlat.new()
	panel.bg_color=Color("#DCF6DA") if is_member else Color("#FCF4DF")
	panel.border_color=Color("#52B579") if is_member else Color("#D2AB64")
	panel.set_border_width_all(3 if selected or is_member else 2)
	panel.set_corner_radius_all(16)
	tile.add_theme_stylebox_override("normal",panel)
	tile.clip_contents=true
	var contents=VBoxContainer.new()
	contents.mouse_filter=Control.MOUSE_FILTER_IGNORE
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_left=5
	contents.offset_right=-5
	contents.offset_top=3
	contents.offset_bottom=-3
	tile.add_child(contents)
	var pic=AnimalArt.new()
	pic.setup(info)
	pic.custom_minimum_size=Vector2(84,64)
	pic.size_flags_vertical=Control.SIZE_EXPAND_FILL
	pic.mouse_filter=Control.MOUSE_FILTER_IGNORE
	pic.modulate=Color.WHITE
	contents.add_child(pic)
	var badge="✓ " if is_member else "＋ "
	contents.add_child(_label(badge+str(info.get("name","朋友")),14))
	tile.tooltip_text="點一下收回（仍留在上方清單）" if is_member else "點一下放到農場"
	return tile

func _toggle_resident(id: String) -> void:
	if save_data.data["private_farm"].has(id):
		_set_resident(id,false)
		remove_current()
	else:
		place_animal(id)

func _restore_roster_scroll(previous: int) -> void:
	if is_instance_valid(resident_scroll):
		resident_scroll.scroll_horizontal=previous

func _rebuild_cards() -> void:
	if not is_instance_valid(resident_list):
		return
	var previous=resident_scroll.scroll_horizontal
	for child in resident_list.get_children():
		resident_list.remove_child(child)
		child.queue_free()
	var members: Array=save_data.data["private_farm"]
	counter.text="🌿 %d / %d     👆 ✓ / ＋" % [members.size(),CAPACITY]
	remove_button.disabled=active_id.is_empty()
	# Stable original catalogue order is essential. Released animals stay in
	# place on the strip, turning from a green check to a yellow plus.
	for info in animals:
		var id=str(info["id"])
		var in_farm=members.has(id)
		var unlocked=true
		resident_list.add_child(_card(info,id==active_id,in_farm,unlocked))
	call_deferred("_restore_roster_scroll",previous)

func _sync_residents() -> void:
	var members: Array = save_data.data["private_farm"]
	for id in actors.keys():
		if not members.has(id):
			var stale: Control = actors[id]
			habitat.remove_child(stale)
			stale.queue_free()
			actors.erase(id)
	for id in members:
		var name = str(id)
		if actors.has(name):
			continue
		var info = _animal(name)
		if info.is_empty():
			continue
		var creature = SwimmingAnimal.new() if str(info.get("zone",""))=="ocean" else RoamingAnimal.new()
		creature.setup(info,reduce_motion)
		creature.petted.connect(_on_animal_petted)
		creature.reaction_finished.connect(_on_reaction_finished)
		habitat.add_child(creature)
		# Assign the final touchable dimensions after _ready(), which sets a default size.
		creature.size = Vector2(66,68) if str(info.get("zone",""))=="ocean" else (Vector2(68,64) if bool(info.get("flies",false)) or str(info.get("zone",""))=="bird" else (Vector2(108,78) if bool(info.get("pushes_dung",false)) else Vector2(74,78)))
		actors[name] = creature
	if is_instance_valid(hand):
		habitat.move_child(hand,habitat.get_child_count()-1)
	for id in actors.keys():
		actors[id].selected = (str(id)==active_id)
		actors[id].queue_redraw()
	# Place newcomers on the grass immediately; defer once more if the
	# containing page has not yet received its first layout pass.
	_layout_residents()
	call_deferred("_layout_residents")

func _resize_world() -> void:
	if not is_instance_valid(farm_view) or not is_instance_valid(habitat):
		return
	if farm_view.size.x<100.0 or farm_view.size.y<100.0:
		return
	world_width=maxf(6500.0,farm_view.size.x*8.0)
	habitat.size=Vector2(world_width,farm_view.size.y)
	_set_camera(camera_x)
	_layout_residents()

func _set_camera(value: float) -> void:
	if not is_instance_valid(habitat) or not is_instance_valid(farm_view):
		return
	camera_x=clampf(value,0.0,maxf(0.0,world_width-farm_view.size.x))
	habitat.position=Vector2(-camera_x,0)

func pan_by(distance: float) -> void:
	_set_camera(camera_x+distance)

func focus_resident(id: String) -> void:
	if actors.has(id) and is_instance_valid(farm_view):
		var actor=actors[id]
		_set_camera(actor.position.x+actor.size.x*.5-farm_view.size.x*.5)

func _layout_residents() -> void:
	if not is_instance_valid(habitat) or habitat.size.x < 300.0 or habitat.size.y < 180.0:
		return
	# Separate two true habitats. Grass residents stay left; swimmers stay in
	# the large pond on the right. Do not let either group cross habitats.
	var grass=Rect2(
		Vector2(14,habitat.size.y*0.535),
		Vector2(habitat.size.x*0.515,habitat.size.y*0.43)
	)
	var pond=Rect2(
		Vector2(habitat.size.x*0.632,habitat.size.y*0.535),
		Vector2(habitat.size.x*0.285,habitat.size.y*0.29)
	)
	# Flying insects use an aerial lane ABOVE both grass and pond. Keep the
	# sky as a dedicated region so they never crawl across the ground.
	var sky=Rect2(
		Vector2(16,habitat.size.y*0.055),
		Vector2(habitat.size.x-32,habitat.size.y*0.395)
	)
	var land_slot=0
	var sea_slot=0
	var air_slot=0
	for id in save_data.data["private_farm"]:
		var name=str(id)
		if not actors.has(name):
			continue
		var creature=actors[name]
		if str(_animal(name).get("zone",""))=="ocean":
			# All eight aquatic species fit in a wide pond without stacking.
			# Prevent stacked sea animals at the bottom of the old 3x2 grid.
			var col=sea_slot%8
			var pos=Vector2(
				pond.position.x+pond.size.x*(float(col)+0.5)/8.0-creature.size.x*0.5,
				pond.position.y+pond.size.y*0.50-creature.size.y*0.5
			)
			creature.set_bounds(pond,pos)
			sea_slot+=1
		elif bool(_animal(name).get("flies",false)) or str(_animal(name).get("zone",""))=="bird":
			# Flying insects get wide horizontal lanes with independent
			# fluttering motion; the water/grass actors are unaffected.
			var column=air_slot%12
			var pos=Vector2(
				sky.position.x+sky.size.x*(float(column)+0.5)/12.0-creature.size.x*0.5,
				sky.position.y+sky.size.y*0.5-creature.size.y*0.5
			)
			creature.set_bounds(sky,pos)
			air_slot+=1
		else:
			 # Up to 32 land species: two staggered rows of sixteen along
			# a longer meadow, preserving roomy individual touch targets.
			var col=land_slot%20
			var row=int(land_slot/20)
			var lane=float(col)+(0.22 if row%2==0 else 0.71)
			var pos=Vector2(
				grass.position.x+grass.size.x*lane/20.0-creature.size.x*0.5,
				grass.position.y+grass.size.y*(0.18+0.31*float(row%3))-creature.size.y*0.5
			)
			creature.set_bounds(grass,pos)
			land_slot+=1

func place_animal(id: String) -> void:
	var result: String = save_data.private_farm_add_status(id,CAPACITY)
	match result:
		"locked":
			info_label.text = "還沒認識這隻動物，先去探索吧！"
			voice.speak("還沒收集到這位朋友，先去樂園找找看！")
			return
		"full":
			info_label.text = "農場已住滿所有 67 位朋友！請先收回一位。"
			voice.speak("農場已經住滿全部六十七位朋友了！可以點上方清單的綠色卡片收回，再放出其他朋友。")
			return
		"already":
			_set_resident(id,false)
			return
		"added":
			pass
		_:
			return
	active_id = id
	_sync_residents()
	_rebuild_cards()
	focus_resident(id)
	info_label.text = "%s到水池游泳囉！" % str(_animal(id).get("name","動物")) if str(_animal(id).get("zone",""))=="ocean" else ("%s飛到天空囉！" % str(_animal(id).get("name","昆蟲")) if bool(_animal(id).get("flies",false)) else ("%s在草地推糞球囉！" % str(_animal(id).get("name","昆蟲")) if bool(_animal(id).get("pushes_dung",false)) else ("%s在草地爬行囉！" % str(_animal(id).get("name","昆蟲")) if id in ["mantis","weevil"] else "%s來農場散步啦！" % str(_animal(id).get("name","動物")))))
	voice.speak("%s來玩囉！" % str(_animal(id).get("name","動物")))
	_update_command_buttons()

func remove_current() -> void:
	if active_id.is_empty():
		return
	_finish_touch()
	save_data.private_farm_remove(active_id)
	active_id = str(save_data.data["private_farm"][0]) if not save_data.data["private_farm"].is_empty() else ""
	_sync_residents()
	_rebuild_cards()
	_update_command_buttons()
	info_label.text = "朋友回圖鑑了，還可以再來玩！"

func _set_resident(id: String, announce: bool = true) -> void:
	if not id.is_empty() and not save_data.data["private_farm"].has(id):
		return
	active_id = id
	for key in actors.keys():
		var creature = actors[key]
		creature.selected = (key==id)
		creature.queue_redraw()
	_rebuild_cards()
	_update_command_buttons()
	if not id.is_empty():
		info_label.text = "摸摸正在游泳的%s！" % str(_animal(id).get("name","動物")) if str(_animal(id).get("zone",""))=="ocean" else ("摸摸在天空飛行的%s！" % str(_animal(id).get("name","昆蟲")) if bool(_animal(id).get("flies",false)) else ("看看%s推著糞球走！" % str(_animal(id).get("name","昆蟲")) if bool(_animal(id).get("pushes_dung",false)) else ("摸摸爬行中的%s！" % str(_animal(id).get("name","昆蟲")) if id in ["mantis","weevil"] else "摸摸正在散步的%s！" % str(_animal(id).get("name","動物")))))
	if announce and not id.is_empty():
		focus_resident(id)
		voice.speak("這是%s。點一下牠，或輕輕摸摸牠。" % str(_animal(id).get("name","動物")))

func _refresh_farm_stock() -> void:
	if save_data==null:
		return
	var basket: Dictionary=save_data.data.get("garden_inventory",{})
	for crop in GardenRules.CROPS:
		var id=str(crop["id"])
		if farm_inventory_tiles.has(id):
			farm_inventory_tiles[id].set_count(int(basket.get(id,0)))

func _input(event: InputEvent) -> void:
	# Global coordinates let a drag begin on a stock tile and finish over
	# the clipped, horizontally-panned animal world without opening a dialog.
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_food_pointer(event.position,event.index,true)
		elif food_touch and food_pointer==event.index:
			_finish_food_pointer(event.position)
	elif event is InputEventScreenDrag:
		if food_touch and food_pointer==event.index:
			_move_food_pointer(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and food_pointer==-1:
			_start_food_pointer(event.position,-2,false)
		elif not event.pressed and food_pointer==-2 and not food_touch:
			_finish_food_pointer(event.position)
	elif event is InputEventMouseMotion:
		if food_pointer==-2 and not food_touch:
			_move_food_pointer(event.position)

func _start_food_pointer(point: Vector2,index: int,touch: bool) -> void:
	if food_pointer!=-1 or busy or save_data==null:
		return
	var basket: Dictionary=save_data.data.get("garden_inventory",{})
	for crop in GardenRules.CROPS:
		var id=str(crop["id"])
		if not farm_inventory_tiles.has(id):
			continue
		if not farm_inventory_tiles[id].get_global_rect().has_point(point):
			continue
		if int(basket.get(id,0))<1:
			info_label.text="🧺 %s還沒收成，去農田採收吧！" % str(crop["name"])
			return
		food_pointer=index
		food_touch=touch
		food_crop=id
		food_drag_origin=point
		food_dragging=false
		food_hover_id=""
		return

func _move_food_pointer(point: Vector2) -> void:
	if food_pointer==-1:
		return
	if not food_dragging:
		if food_drag_origin.distance_to(point)<FOOD_DRAG_DISTANCE:
			return
		food_dragging=true
		food_preview.setup(food_crop,3)
		food_preview.show()
	food_preview.position=point-food_preview.size*.5
	var hovered=_food_target_at(point)
	if hovered!=food_hover_id:
		food_hover_id=hovered
		for key in actors.keys():
			actors[key].selected=(str(key)==hovered or (hovered.is_empty() and str(key)==active_id))
			actors[key].queue_redraw()
	if not hovered.is_empty():
		var name=str(_animal(hovered).get("name","動物"))
		var allowed=save_data.garden_can_feed(hovered,food_crop)
		info_label.text="💗 放開餵%s" % name if allowed else "⛔ %s不適合吃這種蔬菜" % name
		food_preview.modulate=Color(1,1,1,.94) if allowed else Color("#EBA4A4",.90)
	else:
		info_label.text="🥕 拖到農場裡的動物身上"
		food_preview.modulate=Color(1,1,1,.90)
	get_viewport().set_input_as_handled()

func _food_target_at(point: Vector2) -> String:
	if farm_view==null or not farm_view.get_global_rect().has_point(point):
		return ""
	var local=point-farm_view.get_global_rect().position+Vector2(camera_x,0)
	return _actor_at(local)

func _finish_food_pointer(point: Vector2) -> void:
	if food_pointer==-1:
		return
	if food_dragging:
		var id=_food_target_at(point)
		if not id.is_empty():
			if save_data.garden_can_feed(id,food_crop) and not busy:
				feed_garden(food_crop,id)
			else:
				info_label.text="⛔ %s不能吃%s，菜籃不會扣除！" % [
					str(_animal(id).get("name","動物")),
					str(GardenRules.crop_for(food_crop).get("name","蔬菜"))]
		else:
			info_label.text="🥕 把蔬菜拖到動物身上才能餵食"
		get_viewport().set_input_as_handled()
	food_preview.hide()
	food_pointer=-1
	food_touch=false
	food_crop=""
	food_dragging=false
	food_hover_id=""
	for key in actors.keys():
		actors[key].selected=str(key)==active_id
		actors[key].queue_redraw()

func feed_garden(crop_id: String,animal_id: String="") -> bool:
	# Only direct stock-to-animal drags call this in the UI. The optional
	# recipient parameter permits targeting ANY animal without preselection.
	var recipient=animal_id if not animal_id.is_empty() else active_id
	if busy or recipient.is_empty() or not actors.has(recipient):
		return false
	if not save_data.garden_can_feed(recipient,crop_id):
		info_label.text="這種菜不適合這位朋友，或是蔬菜籃還沒有收成！"
		return false
	var before=int(save_data.data.get("garden_inventory",{}).get(crop_id,0))
	var creature=actors[recipient]
	if not creature.perform("garden_feed"):
		return false
	if not save_data.garden_feed(recipient,crop_id):
		return false
	_set_resident(recipient,false)
	var after=int(save_data.data.get("garden_inventory",{}).get(crop_id,0))
	creature.effects.crop_id=crop_id
	creature.effects.queue_redraw()
	last_fed_crop=crop_id
	busy=true
	_update_command_buttons()
	_refresh_farm_stock()
	var crop=GardenRules.crop_for(crop_id)
	info_label.text="💗 %s吃了%s，開心跳跳！🧺 %d → %d" % [
		str(_animal(recipient).get("name","動物")),str(crop.get("name","蔬菜")),before,after]
	# Use recorded calls on known species; TTS announces the actual food.
	if voice!=null:
		voice.speak(info_label.text)
		if voice.has_natural_sound(recipient):
			voice.play_animal(recipient)
	return true

func _update_command_buttons() -> void:
	for b in commands.get_children():
		b.disabled = active_id.is_empty() or busy

func _actor_at(point: Vector2) -> String:
	var winner = ""
	var best = 1.0e10
	for key in actors.keys():
		var creature = actors[key]
		if creature.contains_touch(point):
			var distance = creature.distance_to_touch(point)
			if distance < best:
				best = distance
				winner = str(key)
	return winner

func _start_touch(point: Vector2) -> bool:
	var id = _actor_at(point)
	if id.is_empty():
		return false
	_set_resident(id,false)
	touching_id = id
	last_touch = point
	var creature = actors[id]
	creature.begin_pet()
	hand.show_hand = true
	hand.hand_position = point
	hand.queue_redraw()
	return true

func _move_touch(point: Vector2) -> void:
	if touching_id.is_empty() or not actors.has(touching_id):
		return
	var step = last_touch.distance_to(point)
	last_touch = point
	hand.hand_position = point
	hand.queue_redraw()
	var creature = actors[touching_id]
	if creature.contains_touch(point):
		creature.move_pet(step)

func _finish_touch() -> void:
	if not touching_id.is_empty() and actors.has(touching_id):
		actors[touching_id].end_pet()
	touching_id = ""
	pointer_index = -1
	mouse_down = false
	if is_instance_valid(hand):
		hand.show_hand = false
		hand.queue_redraw()

func _begin_world_gesture(point: Vector2) -> void:
	pointer_last=point
	pan_start=point
	pan_distance=0.0
	_start_touch(point+Vector2(camera_x,0))

func _drag_world_gesture(point: Vector2) -> void:
	if not touching_id.is_empty():
		_move_touch(point+Vector2(camera_x,0))
	else:
		var movement=point-pointer_last
		pan_distance=maxf(pan_distance,point.distance_to(pan_start))
		if pan_distance>12.0:
			pan_by(-movement.x)
	pointer_last=point

func _on_habitat_input(event: InputEvent) -> void:
	# Touch an animal to pet; drag EMPTY ground to scroll. Same for mouse.
	if event is InputEventScreenTouch:
		if event.pressed and pointer_index==-1 and not mouse_down:
			pointer_index=event.index
			_begin_world_gesture(event.position)
			farm_view.accept_event()
		elif not event.pressed and pointer_index==event.index:
			_finish_touch()
			farm_view.accept_event()
	elif event is InputEventScreenDrag and event.index==pointer_index:
		_drag_world_gesture(event.position)
		farm_view.accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and pointer_index==-1:
		if event.pressed:
			mouse_down=true
			_begin_world_gesture(event.position)
		elif mouse_down:
			_finish_touch()
		farm_view.accept_event()
	elif event is InputEventMouseMotion and mouse_down and pointer_index==-1:
		_drag_world_gesture(event.position)
		farm_view.accept_event()

func _on_animal_petted(id: String) -> void:
	pet_feedback_count += 1
	info_label.text = "%s好開心，還想讓你摸摸！" % str(_animal(id).get("name","動物"))
	hand.celebrating = true
	hand.effect_time = 0.0
	hand.queue_redraw()
	if pet_feedback_count == 1:
		voice.speak("摸得真好！牠好開心！")

func interact(action: String) -> void:
	if action=="feed":
		return # General feeding is gone; food only comes from harvested crops.
	if active_id.is_empty() or not actors.has(active_id) or busy:
		return
	if action == "sound":
		voice.play_animal(active_id)
		return
	var creature = actors[active_id]
	if not creature.perform(action):
		return
	save_data.care_for(active_id,action)
	busy = true
	_update_command_buttons()
	var msg: Dictionary = {
		"wash":"好多泡泡，好乾淨！",
		"play":"一起玩，好開心！",
		"sleep":"牠正在休息，輕聲一點喔。"
	}
	info_label.text = str(msg.get(action,"動物很開心！"))
	voice.speak(info_label.text)

func _process(delta: float) -> void:
	if is_instance_valid(hand) and hand.celebrating:
		hand.effect_time += delta
		if hand.effect_time >= 1.1:
			hand.celebrating = false
		hand.queue_redraw()

func _on_reaction_finished(_id: String) -> void:
	busy = false
	_update_command_buttons()
	_refresh_farm_stock()

func _request_race() -> void:
	racing_requested.emit()

func _request_garden() -> void:
	garden_requested.emit()
