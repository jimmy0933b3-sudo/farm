extends VBoxContainer
## Child-friendly forest search: visual target, spoken guide, six real
## hiding locations with shuffled positions on each replay, no timer.
signal completed

const AnimalArt = preload("res://scripts/AnimalArt.gd")
const Backdrop = preload("res://scripts/Backdrop.gd")
const Spot = preload("res://scripts/ForestHideSpot.gd")

const COVERS: Array = ["bush","trunk","flowers","log","rocks","branch"]
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
var rng := RandomNumberGenerator.new()
var moving_on: bool = false

func setup(animals: Array, store, narrator) -> void:
	animal_info = animals
	save_data = store
	sound = narrator

func _ready() -> void:
	add_theme_constant_override("separation",7)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rng.randomize()
	# Hidden places shuffle while the six educational prompts stay predictable.
	placement = ORDER.duplicate()
	placement.shuffle()
	var prompt_row=HBoxContainer.new()
	prompt_row.add_theme_constant_override("separation",15)
	add_child(prompt_row)
	var target_frame=PanelContainer.new()
	target_frame.custom_minimum_size=Vector2(145,105)
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#FFF8DC")
	style.set_corner_radius_all(24)
	style.content_margin_left=10
	style.content_margin_right=10
	style.content_margin_top=8
	style.content_margin_bottom=8
	target_frame.add_theme_stylebox_override("panel",style)
	prompt_row.add_child(target_frame)
	target_art=AnimalArt.new()
	target_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	target_frame.add_child(target_art)
	var words=VBoxContainer.new()
	words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	words.alignment=BoxContainer.ALIGNMENT_CENTER
	prompt_row.add_child(words)
	target_label=_text("找到這隻動物！",30)
	words.add_child(target_label)
	status_label=_text("○ ○ ○ ○ ○ ○",26)
	words.add_child(status_label)
	var speak_button=_round_button("🔊 再聽一次",Callable(self,"repeat_hint"))
	prompt_row.add_child(speak_button)
	var help_button=_round_button("✨ 小提示",Callable(self,"hint_target"))
	prompt_row.add_child(help_button)
	stage=Control.new()
	stage.clip_contents=true
	stage.custom_minimum_size=Vector2(520,315)
	stage.size_flags_vertical=Control.SIZE_EXPAND_FILL
	stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_child(stage)
	var bg=Backdrop.new()
	bg.scene_type="forest"
	bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(bg)
	for i in range(placement.size()):
		var spot=Spot.new()
		spot.setup(i,str(COVERS[i]),_get_animal(str(placement[i])))
		spot.inspected.connect(attempt_spot)
		stage.add_child(spot)
		spots.append(spot)
	stage.resized.connect(_position_spots)
	call_deferred("_position_spots")
	var legend=_text("摸摸樹叢或樹洞，看看誰躲在裡面。",23)
	legend.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	add_child(legend)
	subtitle=legend
	_show_target(true)

func _text(text: String, font_size: int) -> Label:
	var label=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("#314C46"))
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label

func _round_button(label: String, callback: Callable) -> Button:
	var b=Button.new()
	b.text=label
	b.custom_minimum_size=Vector2(160,77)
	b.add_theme_font_size_override("font_size",23)
	b.add_theme_color_override("font_color",Color("#375E55"))
	var box=StyleBoxFlat.new()
	box.bg_color=Color("#FFF4D9")
	box.set_corner_radius_all(22)
	box.set_border_width_all(2)
	box.border_color=Color("#FFFFFF")
	b.add_theme_stylebox_override("normal",box)
	b.pressed.connect(callback)
	return b

func _position_spots() -> void:
	if not is_instance_valid(stage) or stage.size.x<=0.0 or stage.size.y<=0.0:
		return
	var size_x=minf(185.0,stage.size.x/3.35)
	var size_y=minf(170.0,stage.size.y/2.12)
	var cols=[0.18,0.50,0.82]
	var rows=[0.25,0.76]
	for i in range(spots.size()):
		var spot=spots[i]
		spot.size=Vector2(size_x,size_y)
		spot.position=Vector2(stage.size.x*float(cols[i%3])-size_x*0.5,stage.size.y*float(rows[int(i/3)])-size_y*0.5)

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
	sound.speak("找找看，%s 藏在森林哪裡呢？點樹叢、樹洞，找找牠！" % label)

func hint_target() -> void:
	if moving_on:
		return
	var i=target_spot()
	if i>=0 and i<spots.size():
		spots[i].set_hint(true)
		subtitle.text="金色亮圈就是小提示，點點看！"
		sound.speak("你看，發亮的地方有小秘密喔！")

func attempt_spot(i: int) -> void:
	if moving_on or i<0 or i>=spots.size() or i in found:
		return
	if i!=target_spot():
		miss_count+=1
		subtitle.text="不是這裡喔，再找找看！"
		if miss_count>=2:
			hint_target()
		else:
			sound.speak("再看看其他樹叢，動物朋友還在等你。")
		return
	moving_on=true
	found.append(i)
	var id=current_target()
	spots[i].reveal()
	save_data.mark_forest_found(id)
	status_label.text="%s / 6  ★" % str(found.size())
	subtitle.text="找到%s了！" % str(_get_animal(id).get("name","動物"))
	sound.speak("找到了！是%s！你好厲害！" % str(_get_animal(id).get("name","動物")))
	_continue_later(round_index)

func _continue_later(previous_round: int) -> void:
	await get_tree().create_timer(1.65).timeout
	if not is_inside_tree() or round_index!=previous_round:
		return
	round_index+=1
	miss_count=0
	moving_on=false
	if round_index>=ORDER.size():
		completed.emit()
	else:
		_show_target(false)

func _show_target(first_round: bool) -> void:
	var animal=_get_animal(current_target())
	target_art.setup(animal)
	target_label.text="找一找：%s" % str(animal.get("name","動物"))
	status_label.text="%s / 6  ★" % str(found.size())
	subtitle.text="用手指點森林裡的樹叢、石頭或樹洞！"
	for spot in spots:
		spot.set_hint(false)
	if first_round:
		sound.speak("歡迎來到森林尋寶！看看上面的動物圖片，點樹叢、石頭和樹洞，找出躲起來的動物朋友。")
	else:
		repeat_hint()
