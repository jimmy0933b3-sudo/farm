extends HBoxContainer
## Kid-friendly private animal farm: pick any discovered animals, place them
## in a saved sanctuary, select residents, pet with a tracked finger or play.
## No live internet, no text-only prerequisites, no forced daily feeding.
const AnimalArt = preload("res://scripts/AnimalArt.gd")
const PettingArea = preload("res://scripts/PettingArea.gd")
const CareStage = preload("res://scripts/CareStage.gd")
const Backdrop = preload("res://scripts/Backdrop.gd")

const CAPACITY = 8

var animals: Array = []
var save_data
var voice
var active_id: String = ""
var resident_buttons: Array = []
var available_buttons: Array = []
var resident_list: HBoxContainer
var available_list: HBoxContainer
var habitat: Control
var pet: Control
var care: Control
var info_label: Label
var counter: Label
var commands: HBoxContainer
var busy: bool = false

func setup(info: Array, store, narrator) -> void:
	animals = info
	save_data = store
	voice = narrator

func _ready() -> void:
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",18)
	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.size_flags_vertical=Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",9)
	add_child(left)
	info_label=_label("選一隻動物到你的農場玩！",24)
	left.add_child(info_label)
	habitat=Control.new()
	habitat.clip_contents=true
	habitat.custom_minimum_size=Vector2(440,270)
	habitat.size_flags_vertical=Control.SIZE_EXPAND_FILL
	habitat.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.add_child(habitat)
	var bg=Backdrop.new()
	bg.scene_type="farm"
	bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	habitat.add_child(bg)
	commands=HBoxContainer.new()
	commands.alignment=BoxContainer.ALIGNMENT_CENTER
	commands.add_theme_constant_override("separation",8)
	left.add_child(commands)
	for item in [["pet","摸摸牠"],["feed","餵食"],["play","玩耍"],["sound","聽聲音"]]:
		var button=_round(str(item[1]),Callable(self,"interact").bind(str(item[0])),Vector2(112,58))
		buttons_set_visible(button,false)
		commands.add_child(button)
	var right=VBoxContainer.new()
	right.custom_minimum_size=Vector2(370,0)
	right.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.size_flags_horizontal=Control.SIZE_FILL
	right.add_theme_constant_override("separation",8)
	add_child(right)
	counter=_label("農場裡的動物",23)
	right.add_child(counter)
	var chosen_scroller=ScrollContainer.new()
	chosen_scroller.custom_minimum_size=Vector2(360,148)
	chosen_scroller.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	chosen_scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	chosen_scroller.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(chosen_scroller)
	resident_list=HBoxContainer.new()
	resident_list.add_theme_constant_override("separation",9)
	chosen_scroller.add_child(resident_list)
	right.add_child(_label("點下方的動物，放進農場",21))
	var collected_scroller=ScrollContainer.new()
	collected_scroller.size_flags_vertical=Control.SIZE_EXPAND_FILL
	collected_scroller.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	collected_scroller.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	collected_scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(collected_scroller)
	available_list=HBoxContainer.new()
	available_list.add_theme_constant_override("separation",9)
	collected_scroller.add_child(available_list)
	if not save_data.data["private_farm"].is_empty():
		active_id=str(save_data.data["private_farm"][0])
	_rebuild_cards()
	_set_resident(active_id,false)
	voice.speak("歡迎來到私人農場！先在右邊點你已認識的動物，把牠帶進農場，再用手指摸摸牠。")

func buttons_set_visible(button: Button, enabled: bool) -> void:
	button.disabled = not enabled

func _label(value: String, size_value: int) -> Label:
	var l=Label.new()
	l.text=value
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",size_value)
	l.add_theme_color_override("font_color",Color("#31594A"))
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	return l

func _round(title: String, action: Callable, minimum: Vector2) -> Button:
	var b=Button.new()
	b.text=title
	b.custom_minimum_size=minimum
	b.add_theme_font_size_override("font_size",20)
	b.add_theme_color_override("font_color",Color("#31544C"))
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#FFE6AE")
	style.set_corner_radius_all(20)
	style.set_border_width_all(2)
	style.border_color=Color.WHITE
	b.add_theme_stylebox_override("normal",style)
	b.pressed.connect(action)
	return b

func _animal(id: String) -> Dictionary:
	for a in animals:
		if str(a.get("id","")) == id:
			return a
	return {}

func _card(info: Dictionary, action: Callable, selected: bool, is_member: bool) -> Button:
	var label=str(info.get("name","動物"))
	var b=_round("",action,Vector2(116,130))
	var bg=StyleBoxFlat.new()
	bg.bg_color=Color("#D7F6C7") if selected else (Color("#FFF4D2") if is_member else Color("#F7FEF5"))
	bg.set_corner_radius_all(18)
	bg.set_border_width_all(3)
	bg.border_color=Color("#4DAB72") if selected else Color.WHITE
	b.add_theme_stylebox_override("normal",bg)
	b.clip_contents=true
	var col=VBoxContainer.new()
	col.mouse_filter=Control.MOUSE_FILTER_IGNORE
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left=8
	col.offset_right=-8
	col.offset_top=5
	col.offset_bottom=-5
	b.add_child(col)
	var art=AnimalArt.new()
	art.setup(info)
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	art.custom_minimum_size=Vector2(92,91)
	art.size_flags_vertical=Control.SIZE_EXPAND_FILL
	col.add_child(art)
	col.add_child(_label(label,19))
	return b

func _rebuild_cards() -> void:
	if not is_instance_valid(resident_list):
		return
	for group in [resident_list,available_list]:
		for child in group.get_children():
			group.remove_child(child)
			child.queue_free()
	resident_buttons.clear()
	available_buttons.clear()
	var saved: Array=save_data.data["private_farm"]
	counter.text="農場裡：%d / %d" % [saved.size(),CAPACITY]
	for id in saved:
		var info=_animal(str(id))
		if info.is_empty():
			continue
		var button=_card(info,Callable(self,"_set_resident").bind(str(id),true),str(id)==active_id,true)
		resident_list.add_child(button)
		resident_buttons.append(button)
	for a in animals:
		var id=str(a["id"])
		if save_data.data["collected"].has(id) and not saved.has(id):
			var button=_card(a,Callable(self,"place_animal").bind(id),false,false)
			available_list.add_child(button)
			available_buttons.append(button)
	if available_buttons.is_empty():
		available_list.add_child(_label("先去探索動物，或已全部放入農場！",19))

func place_animal(id: String) -> void:
	if not save_data.private_farm_add(id,CAPACITY):
		voice.speak("農場目前放滿了，可以先讓一隻動物回到圖鑑。")
		return
	_set_resident(id,false)
	_rebuild_cards()
	voice.speak("%s加入農場囉！一起摸摸牠！" % str(_animal(id).get("name","動物")))

func remove_current() -> void:
	if active_id.is_empty():
		return
	save_data.private_farm_remove(active_id)
	active_id=str(save_data.data["private_farm"].front()) if not save_data.data["private_farm"].is_empty() else ""
	_rebuild_cards()
	_set_resident(active_id,false)
	voice.speak("動物回到圖鑑了，隨時可以再放回農場。")

func _set_resident(id: String, announce: bool = true) -> void:
	if id != "" and not save_data.data["private_farm"].has(id):
		return
	if busy:
		return
	active_id=id
	for child in habitat.get_children():
		if child.get_script() == PettingArea or child.get_script() == CareStage:
			habitat.remove_child(child)
			child.queue_free()
	pet=null
	care=null
	if id.is_empty():
		info_label.text="從右邊挑選已收集的動物！"
	else:
		var info=_animal(id)
		info_label.text="%s正在農場玩！輕輕摸摸牠！" % str(info.get("name","動物"))
		pet=PettingArea.new()
		pet.setup(info,bool(save_data.data["settings"].get("reduce_motion",false)))
		pet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pet.stroked.connect(_on_petted)
		habitat.add_child(pet)
		care=CareStage.new()
		care.setup(info,bool(save_data.data["settings"].get("reduce_motion",false)))
		care.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		care.action_finished.connect(_on_care_finished)
		care.visible=false
		habitat.add_child(care)
	_rebuild_cards()
	for button in commands.get_children():
		buttons_set_visible(button,not id.is_empty())
	if announce and not id.is_empty():
		voice.speak("這是%s，來摸摸牠吧！" % str(_animal(id).get("name","動物")))

func _on_petted() -> void:
	if not active_id.is_empty():
		info_label.text="%s好開心！" % str(_animal(active_id).get("name","動物"))
		if is_instance_valid(pet) and int(pet.strokes)==1:
			voice.speak("摸得真好！動物很開心！")

func interact(action: String) -> void:
	if active_id.is_empty() or busy:
		return
	match action:
		"pet":
			if is_instance_valid(pet):
				pet.guide()
			voice.speak("把手指放在動物身上，輕輕來回滑動。")
		"sound":
			voice.play_animal(active_id)
		"feed","play":
			if not is_instance_valid(care) or not care.play_action(action):
				return
			busy=true
			pet.visible=false
			care.visible=true
			for b in commands.get_children():
				b.disabled=true
			save_data.care_for(active_id,action)
			info_label.text="吃得好開心！" if action=="feed" else "玩得好開心！"
			voice.speak("吃東西囉！" if action=="feed" else "一起玩球！")

func _on_care_finished(_action: String) -> void:
	busy=false
	if is_instance_valid(care):
		care.visible=false
	if is_instance_valid(pet):
		pet.visible=true
		pet.avatar.set("mood","happy")
		pet.joy_time=1.2
		pet.avatar.queue_redraw()
	for b in commands.get_children():
		b.disabled=false
