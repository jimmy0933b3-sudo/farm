extends VBoxContainer
## A complete, readable-at-age-four large forest adventure.
## Keeps compatibility with the existing forest game/test interface.
signal completed

const AnimalArt = preload("res://scripts/AnimalArt.gd")
const Map = preload("res://scripts/ForestPanMap.gd")
const ORDER: Array = ["rabbit","squirrel","fox","deer","bear","owl"]

var animal_info: Array = []
var save_data
var sound
var spots: Array = []
var placement: Array = []
var found: Array = []
var round_index: int = 0
var miss_count: int = 0
var stage: Control
var target_art: Control
var target_label: Label
var status_label: Label
var subtitle: Label
var moving_on: bool = false

func setup(animals: Array, store, narrator) -> void:
	animal_info = animals
	save_data = store
	sound = narrator

func _ready() -> void:
	add_theme_constant_override("separation",8)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var session: Dictionary = save_data.get_forest_explore_session(ORDER)
	placement = session.get("placement",[]).duplicate()
	var discovered: Array = session.get("found",[])
	for animal_id in discovered:
		found.append(placement.find(animal_id))
	round_index = found.size()

	var banner = HBoxContainer.new()
	banner.add_theme_constant_override("separation",12)
	add_child(banner)
	var target_frame=PanelContainer.new()
	target_frame.custom_minimum_size=Vector2(140,112)
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#FFFAE8")
	style.set_corner_radius_all(22)
	style.set_border_width_all(3)
	style.border_color=Color("#FFFFFF")
	style.content_margin_left=8
	style.content_margin_right=8
	style.content_margin_top=6
	style.content_margin_bottom=6
	target_frame.add_theme_stylebox_override("panel",style)
	banner.add_child(target_frame)
	target_art = AnimalArt.new()
	target_art.custom_minimum_size=Vector2(122,105)
	target_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	target_frame.add_child(target_art)
	var words=VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment=BoxContainer.ALIGNMENT_CENTER
	banner.add_child(words)
	target_label=_text("找找看，動物藏哪裡？",29)
	words.add_child(target_label)
	status_label=_text("★ 0 / 6",26)
	words.add_child(status_label)
	banner.add_child(_rounded("🔊 再聽一次",Callable(self,"repeat_hint"),Vector2(164,75)))
	banner.add_child(_rounded("✨ 找找提示",Callable(self,"hint_target"),Vector2(164,75)))
	stage=Map.new()
	stage.setup(animal_info,placement,bool(save_data.data["settings"].get("reduce_motion",false)))
	stage.custom_minimum_size=Vector2(550,320)
	stage.hideout_tapped.connect(attempt_spot)
	stage.size_flags_vertical=Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_child(stage)
	spots=stage.spots
	for index in found:
		if index>=0 and index<spots.size():
			spots[index].reveal()
	var arrows=HBoxContainer.new()
	arrows.add_theme_constant_override("separation",24)
	arrows.alignment=BoxContainer.ALIGNMENT_CENTER
	add_child(arrows)
	arrows.add_child(_rounded("◀ 往左",Callable(self,"_move_left"),Vector2(175,64)))
	arrows.add_child(_text("用手指拖動森林找動物",22))
	arrows.add_child(_rounded("往右 ▶",Callable(self,"_move_right"),Vector2(175,64)))
	subtitle=_text("看看樹洞、草叢和小溪旁！",22)
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)
	_show_target(true)

func _move_left() -> void:
	stage.pan_by(-stage.size.x*0.65)

func _move_right() -> void:
	stage.pan_by(stage.size.x*0.65)

func _text(text: String, font_size: int) -> Label:
	var label=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("#365548"))
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label

func _rounded(label: String, action: Callable, minimum: Vector2) -> Button:
	var button=Button.new()
	button.text=label
	button.custom_minimum_size=minimum
	button.add_theme_font_size_override("font_size",22)
	button.add_theme_color_override("font_color",Color("#31564C"))
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#FFF1D0")
	style.set_corner_radius_all(23)
	style.set_border_width_all(3)
	style.border_color=Color("#FFFFFF")
	button.add_theme_stylebox_override("normal",style)
	button.pressed.connect(action)
	return button

func _get_animal(id: String) -> Dictionary:
	for entry in animal_info:
		if str(entry.get("id",""))==id:
			return entry
	return {}

func current_target() -> String:
	if round_index>=ORDER.size():
		return ""
	return str(ORDER[round_index])

func target_spot() -> int:
	return placement.find(current_target())

func repeat_hint() -> void:
	if moving_on or round_index>=ORDER.size():
		return
	var label=str(_get_animal(current_target()).get("name","動物"))
	sound.speak("找找看，%s 藏在大森林哪裡？左右滑動森林，摸摸草叢、樹洞和石頭。" % label)

func hint_target() -> void:
	if moving_on:
		return
	var index=target_spot()
	if index>=0 and index<spots.size():
		spots[index].set_hint(true)
		stage.focus_spot(index)
		subtitle.text="跟著金色亮圈，找找小動物！"
		sound.speak("順著亮亮的金色光圈找一找，就在附近喔！")

func attempt_spot(index: int) -> void:
	if moving_on or index<0 or index>=spots.size() or found.has(index):
		return
	if index!=target_spot():
		miss_count+=1
		subtitle.text="沒關係，再看看其他地方！"
		if miss_count>=2:
			hint_target()
		else:
			sound.speak("動物朋友還在躲貓貓，再找找其他地方！")
		return
	moving_on=true
	found.append(index)
	var id=current_target()
	spots[index].reveal()
	save_data.record_forest_explore_found(id)
	status_label.text="★ %d / 6" % found.size()
	subtitle.text="找到%s了！" % str(_get_animal(id).get("name","動物"))
	sound.speak("找到啦！這是%s！好厲害！" % str(_get_animal(id).get("name","動物")))
	_continue_later(round_index)

func _continue_later(previous_round: int) -> void:
	await get_tree().create_timer(1.65).timeout
	if not is_inside_tree() or round_index!=previous_round:
		return
	round_index+=1
	miss_count=0
	moving_on=false
	if round_index>=ORDER.size():
		save_data.finish_forest_explore(ORDER)
		completed.emit()
	else:
		_show_target(false)

func _show_target(first_round: bool) -> void:
	var animal=_get_animal(current_target())
	target_art.setup(animal)
	target_label.text="找一找：%s" % str(animal.get("name","動物"))
	status_label.text="★ %d / 6" % found.size()
	subtitle.text="左右滑動森林，再點樹叢找找看！"
	for spot in spots:
		spot.set_hint(false)
	if first_round:
		sound.speak("歡迎來到大森林探索！看上面要找的動物圖片。用手指左右滑動森林，再點樹洞、草叢和石頭，找動物朋友！")
	else:
		repeat_hint()
