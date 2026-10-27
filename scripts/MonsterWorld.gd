extends VBoxContainer
## Tap-and-find monster park with three habitats, saved collection and interactions.
signal racing_requested

const MonsterArt=preload("res://scripts/MonsterArt.gd")
const Scenery=preload("res://scripts/MonsterScenery.gd")

const ZONES=[
	{"id":"rainbow","name":"🌈 彩虹森林"},
	{"id":"candy","name":"🌋 糖果火山"},
	{"id":"sky","name":"🌙 星星天空島"}
]

var monsters: Array=[]
var progress
var narrator
var zone_id: String="rainbow"
var selected: Dictionary={}
var stage: Control
var background_art
var zone_buttons: Array=[]
var monster_buttons: Array=[]
var count_label: Label
var selected_label: Label
var tip_label: Label
var feedback_label: Label
var avatar
var play_buttons: Array=[]
var gentle: bool=false

func setup(catalog: Array, store, voice) -> void:
	monsters=catalog
	progress=store
	narrator=voice
	gentle=bool(progress.data.get("settings",{}).get("reduce_motion",false))

func _ready() -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	var top=HBoxContainer.new()
	top.add_theme_constant_override("separation",12)
	add_child(top)
	count_label=_label("",21)
	count_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(count_label)
	top.add_child(_button("🏎️ 怪獸賽車場",Callable(self,"_request_race"),Vector2(200,60)))
	var nav=HBoxContainer.new()
	nav.alignment=BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation",16)
	add_child(nav)
	for region in ZONES:
		var tab=_button(str(region["name"]),Callable(self,"choose_zone").bind(str(region["id"])),Vector2(190,59))
		nav.add_child(tab)
		zone_buttons.append(tab)
	var content=HBoxContainer.new()
	content.size_flags_vertical=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",14)
	add_child(content)
	var left=VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	left.size_flags_vertical=Control.SIZE_EXPAND_FILL
	content.add_child(left)
	tip_label=_label("找到怪獸就點一下，帶牠加入收藏吧！",19)
	left.add_child(tip_label)
	stage=Control.new()
	stage.custom_minimum_size=Vector2(525,270)
	stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical=Control.SIZE_EXPAND_FILL
	stage.clip_contents=true
	left.add_child(stage)
	background_art=Scenery.new()
	background_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	background_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(background_art)
	stage.resized.connect(_position_monsters)
	var right=VBoxContainer.new()
	right.custom_minimum_size=Vector2(280,0)
	right.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",6)
	content.add_child(right)
	selected_label=_label("👾 點選一隻怪獸",21)
	right.add_child(selected_label)
	avatar=MonsterArt.new()
	avatar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	avatar.custom_minimum_size=Vector2(225,185)
	avatar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	avatar.size_flags_vertical=Control.SIZE_EXPAND_FILL
	right.add_child(avatar)
	feedback_label=_label("試試看怪獸的超能力！",17)
	feedback_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	right.add_child(feedback_label)
	for action in [["feed","🍬 餵點心"],["pet","💗 摸摸牠"],["ability","✨ 超能力"]]:
		var btn=_button(str(action[1]),Callable(self,"play").bind(str(action[0])),Vector2(250,48))
		btn.disabled=true
		right.add_child(btn)
		play_buttons.append(btn)
	_refresh()
	if narrator!=null:
		narrator.speak("歡迎來怪獸樂園！選一個地方，找四隻可愛怪獸。摸摸牠們，也可以去賽車。")

func _label(value: String,font_size: int) -> Label:
	var label=Label.new()
	label.text=value
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("#294D5C"))
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	return label

func _button(title: String,action: Callable,minimum: Vector2) -> Button:
	var button=Button.new()
	button.text=title
	button.custom_minimum_size=minimum
	button.add_theme_font_size_override("font_size",21)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,Color("#203B4C"))
	button.add_theme_color_override("font_disabled_color",Color("#506475"))
	var style=StyleBoxFlat.new()
	style.bg_color=Color("#FFF2CE")
	style.border_color=Color("#99764E")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.content_margin_left=12
	style.content_margin_right=12
	style.content_margin_top=7
	style.content_margin_bottom=7
	button.add_theme_stylebox_override("normal",style)
	var hover=style.duplicate()
	hover.bg_color=Color("#FFE1A7")
	button.add_theme_stylebox_override("hover",hover)
	var pressed=style.duplicate()
	pressed.bg_color=Color("#F8CE81")
	button.add_theme_stylebox_override("pressed",pressed)
	var disabled=style.duplicate()
	disabled.bg_color=Color("#E7EAED")
	button.add_theme_stylebox_override("disabled",disabled)
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.pressed.connect(action)
	return button

func choose_zone(id: String) -> void:
	zone_id=id
	selected={}
	_refresh()

func _refresh() -> void:
	for i in range(zone_buttons.size()):
		var active: bool=str(ZONES[i]["id"])==zone_id
		var style=zone_buttons[i].get_theme_stylebox("normal").duplicate()
		style.bg_color=Color("#F5D7FE") if active else Color("#FFF2CE")
		style.border_color=Color("#6B518D") if active else Color("#99764E")
		zone_buttons[i].add_theme_stylebox_override("normal",style)
	background_art.setup(zone_id)
	for old in monster_buttons:
		stage.remove_child(old)
		old.queue_free()
	monster_buttons.clear()
	for monster in monsters:
		if str(monster.get("area",""))!=zone_id:
			continue
		var id=str(monster["id"])
		var found=progress.data.get("monster_found",[]).has(id)
		var btn=_button("",Callable(self,"discover").bind(id),Vector2(112,123))
		var style=btn.get_theme_stylebox("normal").duplicate()
		style.bg_color=Color("#EAF8EC") if found else Color("#FCEFFF")
		style.border_color=Color("#569D80") if found else Color("#AD79B8")
		btn.add_theme_stylebox_override("normal",style)
		var vbox=VBoxContainer.new()
		vbox.mouse_filter=Control.MOUSE_FILTER_IGNORE
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.add_child(vbox)
		var art=MonsterArt.new()
		art.setup(monster)
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		art.custom_minimum_size=Vector2(100,91)
		art.size_flags_vertical=Control.SIZE_EXPAND_FILL
		vbox.add_child(art)
		vbox.add_child(_label(("✓ " if found else "🔎 ")+str(monster["name"]),16))
		stage.add_child(btn)
		monster_buttons.append(btn)
	_position_monsters()
	var count: int=0
	for monster in monsters:
		if progress.data.get("monster_found",[]).has(str(monster["id"])):
			count+=1
	count_label.text="👾 怪獸收藏：%d / %d" % [count,monsters.size()]
	if selected.is_empty():
		selected_label.text="👾 點選一隻怪獸"
		feedback_label.text="找到怪獸後，可以跟牠玩！"
		avatar.visible=false
	else:
		selected_label.text=str(selected.get("name","怪獸"))
		avatar.visible=true
		avatar.setup(selected)
		feedback_label.text=str(selected.get("desc",""))
	for btn in play_buttons:
		btn.disabled=selected.is_empty()

func _position_monsters() -> void:
	if stage==null or stage.size.x<=0.0:
		return
	for i in range(monster_buttons.size()):
		var card: Control=monster_buttons[i]
		var x: float=stage.size.x*(.04+float(i)*.247)
		var y: float=stage.size.y*(.18+float(i%2)*.25)
		card.position=Vector2(x,y)

func discover(id: String) -> void:
	for info in monsters:
		if str(info.get("id",""))!=id:
			continue
		selected=info
		var first: bool=not progress.data.get("monster_found",[]).has(id)
		progress.record_monster_found(id)
		_refresh()
		tip_label.text="🌟 新朋友加入收藏！" if first else "💖 歡迎回來，再一起玩！"
		if narrator!=null:
			narrator.speak(("找到%s！" if first else "又見面了，%s！")+" "+str(info.get("desc","")) % str(info["name"]))
		return

func play(action: String) -> void:
	if selected.is_empty():
		return
	var id: String=str(selected.get("id",""))
	progress.record_monster_play(id)
	var sentence: String=""
	match action:
		"feed":
			sentence="%s吃了%s，開心地笑了！" % [str(selected["name"]),str(selected.get("food","點心"))]
		"pet":
			sentence="摸摸%s，牠搖搖身體向你說謝謝！" % str(selected["name"])
		"ability":
			sentence="%s使用超能力：%s！" % [str(selected["name"]),str(selected.get("ability","變魔法"))]
	feedback_label.text=sentence
	if not gentle:
		var tween=create_tween()
		tween.tween_property(avatar,"scale",Vector2(1.08,1.08),.14)
		tween.tween_property(avatar,"scale",Vector2.ONE,.20)
	if narrator!=null:
		narrator.speak(sentence)

func _request_race() -> void:
	racing_requested.emit()
