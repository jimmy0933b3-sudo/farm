extends HBoxContainer
## Private sanctuary: all collected residents roam together in a single scene.
## Touch the actual moving animal, stroke to pet, tap to select for care actions.
const AnimalArt = preload("res://scripts/AnimalArt.gd")
const RoamingAnimal = preload("res://scripts/RoamingAnimal.gd")
const SwimmingAnimal = preload("res://scripts/SwimmingAnimal.gd")
const TouchAnimalScroll = preload("res://scripts/TouchAnimalScroll.gd")
const TouchHand = preload("res://scripts/TouchHand.gd")
const PrivateFarmLandscape = preload("res://scripts/PrivateFarmLandscape.gd")

const CAPACITY: int = 16

var animals: Array = []
var save_data
var voice
var active_id: String = ""
var actors: Dictionary = {}
var resident_list: GridContainer
var resident_scroll: ScrollContainer
var available_list: GridContainer
var available_scroll: ScrollContainer
var remove_button: Button
var habitat: Control
var farm_view: Control
var camera_x: float = 0.0
var world_width: float = 1680.0
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

	info_label = _label("左右滑動逛大農場，摸摸動物吧！",21)
	left.add_child(info_label)
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
	for data in [["feed","餵食"],["wash","洗澡"],["play","玩耍"],["sleep","休息"],["sound","聽聲音"]]:
		var btn = _round(str(data[1]),Callable(self,"interact").bind(str(data[0])),Vector2(99,54))
		btn.disabled = true
		commands.add_child(btn)

	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(275,0)
	right.size_flags_horizontal = Control.SIZE_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",5)
	add_child(right)

	var resident_header = HBoxContainer.new()
	resident_header.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_child(resident_header)
	counter = _label("農場裡",20)
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resident_header.add_child(counter)
	remove_button = _round("移回圖鑑",Callable(self,"remove_current"),Vector2(102,46))
	resident_header.add_child(remove_button)

	# Sixteen residents across four rows. The selector shows two rows at
	# a time; fingers can smoothly scroll down to select/remove slots 9-16.
	resident_scroll = TouchAnimalScroll.new()
	resident_scroll.custom_minimum_size = Vector2(268,176)
	resident_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resident_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	resident_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	resident_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right.add_child(resident_scroll)
	resident_list = GridContainer.new()
	resident_list.columns = 4
	resident_list.custom_minimum_size = Vector2(263,0)
	resident_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resident_list.add_theme_constant_override("h_separation",3)
	resident_list.add_theme_constant_override("v_separation",4)
	resident_scroll.add_child(resident_list)

	right.add_child(_label("點圖片，帶動物進農場",19))
	available_scroll = TouchAnimalScroll.new()
	available_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	available_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	available_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	available_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right.add_child(available_scroll)
	available_list = GridContainer.new()
	available_list.columns = 3
	available_list.add_theme_constant_override("h_separation",4)
	available_list.add_theme_constant_override("v_separation",5)
	available_scroll.add_child(available_list)

	if not save_data.data["private_farm"].is_empty():
		active_id = str(save_data.data["private_farm"][0])
	_sync_residents()
	_rebuild_cards()
	call_deferred("_layout_residents")
	voice.speak("歡迎來到大大的私人農場！手指左右滑動可以逛完整張地圖，摸摸動物會有開心反應，往右可以找到大水池喔！")

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
	btn.add_theme_color_override("font_color",Color("#31544C"))
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#FFE6AE")
	style.set_corner_radius_all(17)
	style.set_border_width_all(2)
	style.border_color = Color.WHITE
	btn.add_theme_stylebox_override("normal",style)
	if action.is_valid():
		btn.pressed.connect(action)
	return btn

func _animal(id: String) -> Dictionary:
	for a in animals:
		if str(a.get("id","")) == id:
			return a
	return {}

func _card(info: Dictionary, action: Callable, selected: bool, is_member: bool) -> Button:
	var b = _round("",Callable(),Vector2(63,79) if is_member else Vector2(87,101))
	if is_member:
		resident_scroll.wire_button(b,action)
	else:
		available_scroll.wire_button(b,action)
	var box = StyleBoxFlat.new()
	box.bg_color = Color("#D7F6C7") if selected else (Color("#FFF4D2") if is_member else Color("#F7FEF5"))
	box.set_corner_radius_all(14)
	box.set_border_width_all(2)
	box.border_color = Color("#4DAB72") if selected else Color.WHITE
	b.add_theme_stylebox_override("normal",box)
	b.clip_contents = true
	var col = VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 5
	col.offset_right = -5
	col.offset_top = 3
	col.offset_bottom = -4
	b.add_child(col)
	var art = AnimalArt.new()
	art.setup(info)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size = Vector2(55,52) if is_member else Vector2(70,70)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(art)
	col.add_child(_label(str(info.get("name","動物")),14 if is_member else 17))
	return b

func _rebuild_cards() -> void:
	if not is_instance_valid(resident_list):
		return
	for group in [resident_list,available_list]:
		for child in group.get_children():
			group.remove_child(child)
			child.queue_free()
	var members: Array = save_data.data["private_farm"]
	counter.text = "農場：%d / %d" % [members.size(),CAPACITY]
	remove_button.disabled = active_id.is_empty()
	for id in members:
		var info = _animal(str(id))
		if not info.is_empty():
			resident_list.add_child(_card(info,Callable(self,"_set_resident").bind(str(id),true),str(id)==active_id,true))
	var n = 0
	for info in animals:
		var id = str(info["id"])
		if save_data.data["collected"].has(id) and not members.has(id):
			available_list.add_child(_card(info,Callable(self,"place_animal").bind(id),false,false))
			n += 1
	if n == 0:
		available_list.add_child(_label("先去找更多動物！",17))

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
		creature.size = Vector2(66,68) if str(info.get("zone",""))=="ocean" else Vector2(74,78)
		creature.petted.connect(_on_animal_petted)
		creature.reaction_finished.connect(_on_reaction_finished)
		habitat.add_child(creature)
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
	world_width=maxf(2350.0,farm_view.size.x*2.6)
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
	var land_slot=0
	var sea_slot=0
	for id in save_data.data["private_farm"]:
		var name=str(id)
		if not actors.has(name):
			continue
		var creature=actors[name]
		if str(_animal(name).get("zone",""))=="ocean":
			# All seven marine species fit into their wide pond in one row.
			# Prevent stacked sea animals at the bottom of the old 3x2 grid.
			var col=sea_slot%7
			var pos=Vector2(
				pond.position.x+pond.size.x*(float(col)+0.5)/7.0-creature.size.x*0.5,
				pond.position.y+pond.size.y*0.50-creature.size.y*0.5
			)
			creature.set_bounds(pond,pos)
			sea_slot+=1
		else:
			# Up to 16 land species: two staggered rows of eight. Each row
			# has room for a full-sized touchable animal in the long meadow.
			var col=land_slot%8
			var row=int(land_slot/8)
			var lane=float(col)+(0.28 if row==0 else 0.72)
			var pos=Vector2(
				grass.position.x+grass.size.x*lane/8.0-creature.size.x*0.5,
				grass.position.y+grass.size.y*(0.25 if row==0 else 0.75)-creature.size.y*0.5
			)
			creature.set_bounds(grass,pos)
			land_slot+=1

func place_animal(id: String) -> void:
	var result: String = save_data.private_farm_add_status(id,CAPACITY)
	match result:
		"locked":
			info_label.text = "還沒認識這隻動物，先去探索吧！"
			voice.speak("還沒收集到這隻動物，先去森林或農場找找看！")
			return
		"full":
			info_label.text = "農場已住滿 16 隻！先選一隻移回圖鑑。"
			voice.speak("農場已經住滿十六隻動物了！先選一隻，按移回圖鑑，就能換新朋友進來。")
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
	info_label.text = "%s到水池游泳囉！" % str(_animal(id).get("name","動物")) if str(_animal(id).get("zone",""))=="ocean" else "%s來農場散步啦！" % str(_animal(id).get("name","動物"))
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
	info_label.text = "動物回圖鑑了，還可以再來玩！"

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
		info_label.text = "摸摸正在游泳的%s！" % str(_animal(id).get("name","動物")) if str(_animal(id).get("zone",""))=="ocean" else "摸摸正在散步的%s！" % str(_animal(id).get("name","動物"))
	if announce and not id.is_empty():
		focus_resident(id)
		voice.speak("這是%s。點一下牠，或輕輕摸摸牠。" % str(_animal(id).get("name","動物")))

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
		"feed":"吃得好開心！",
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
