extends VBoxContainer
## Inclusive flight competition: auto-forward motion, up/down swipe or large buttons.
signal finished(result: Dictionary)
const Rules=preload("res://scripts/RaceRules.gd")
const BirdArt=preload("res://scripts/BirdArt.gd")
const Track=preload("res://scripts/BirdFlightTrack.gd")
const FINISH_DISTANCE: float=1480.0

var birds: Array=[]
var player: Dictionary={}
var course_id: String="lake"
var narrator
var calm: bool=false
var lane: int=1
var distance: float=0.0
var time_elapsed: float=0.0
var countdown: float=3.0
var stars: int=0
var clouds_touched: int=0
var boost_time: float=0.0
var boost_cooldown: float=0.0
var slow_time: float=0.0
var finished_race: bool=false
var opponents: Array=[]
var enemy_distances: Array=[30.0,4.0,-28.0]
var enemy_lanes: Array=[0,2,1]
var items: Array=[]
var track
var my_bird
var rival_birds: Array=[]
var hud: Label
var help_label: Label
var countdown_label: Label
var boost_button: Button
var start_touch: Vector2=Vector2.ZERO
var active_finger: int=-1
var mouse_down: bool=false
var wing_clock: float=0.0

func configure(chosen: Dictionary,catalog: Array,route: String,voice,gentle: bool) -> void:
	player=chosen
	birds=catalog
	course_id=route
	narrator=voice
	calm=gentle
	for entry in birds:
		if str(entry.get("id",""))!=str(player.get("id","")):
			opponents.append(entry)
	while opponents.size()>3:
		opponents.remove_at(opponents.size()-1)
	while opponents.size()<3:
		opponents.append(player)

func _ready() -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",7)
	hud=Label.new()
	hud.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hud.add_theme_font_size_override("font_size",23)
	hud.add_theme_color_override("font_color",Color("#28495A"))
	add_child(hud)
	track=Track.new()
	track.setup(course_id,calm)
	track.custom_minimum_size=Vector2(360,240)
	track.size_flags_vertical=Control.SIZE_EXPAND_FILL
	track.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	track.mouse_filter=Control.MOUSE_FILTER_STOP
	track.clip_contents=true
	add_child(track)
	track.gui_input.connect(_input_track)
	track.resized.connect(_place_birds)
	my_bird=BirdArt.new()
	my_bird.setup(player)
	my_bird.set_facing_right(true)
	my_bird.mouse_filter=Control.MOUSE_FILTER_IGNORE
	track.add_child(my_bird)
	for i in range(3):
		var rival=BirdArt.new()
		rival.setup(opponents[i])
		rival.set_facing_right(true)
		rival.mouse_filter=Control.MOUSE_FILTER_IGNORE
		track.add_child(rival)
		rival_birds.append(rival)
	countdown_label=Label.new()
	countdown_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	countdown_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	countdown_label.add_theme_font_size_override("font_size",95)
	countdown_label.add_theme_color_override("font_color",Color("#FFF3CB"))
	countdown_label.add_theme_color_override("font_outline_color",Color("#345D72"))
	countdown_label.add_theme_constant_override("outline_size",12)
	countdown_label.text="3"
	track.add_child(countdown_label)
	var controls=HBoxContainer.new()
	controls.add_theme_constant_override("separation",22)
	controls.alignment=BoxContainer.ALIGNMENT_CENTER
	add_child(controls)
	controls.add_child(_button("⬆️ 上升",Callable(self,"move_altitude").bind(-1)))
	boost_button=_button("✨ 加速",Callable(self,"boost"))
	controls.add_child(boost_button)
	controls.add_child(_button("⬇️ 下降",Callable(self,"move_altitude").bind(1)))
	help_label=Label.new()
	help_label.text="上下滑動換高度 · 自動向前飛 · 收集星星 ✨"
	help_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	help_label.add_theme_font_size_override("font_size",18)
	help_label.add_theme_color_override("font_color",Color("#315B63"))
	add_child(help_label)
	for i in range(1,20):
		var kind="star"
		if i%6==0:
			kind="wind"
		elif i%4==0:
			kind="cloud"
		items.append({"distance":float(i)*72.0,"lane":i%3,"type":kind,"taken":false})
	_refresh_hud()
	call_deferred("_place_birds")
	if narrator!=null:
		narrator.speak("三、二、一！飛起來！點上升或下降換高度，碰到雲朵也沒關係。")

func _button(title: String,callback: Callable) -> Button:
	var b=Button.new()
	b.text=title
	b.custom_minimum_size=Vector2(170,64)
	b.add_theme_font_size_override("font_size",23)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		b.add_theme_color_override(state,Color("#263C4D"))
	b.add_theme_color_override("font_disabled_color",Color("#526674"))
	var box=StyleBoxFlat.new()
	box.bg_color=Color("#FFE5AF")
	box.border_color=Color("#93653E")
	box.set_border_width_all(3)
	box.set_corner_radius_all(17)
	box.content_margin_left=15
	box.content_margin_right=15
	box.content_margin_top=8
	box.content_margin_bottom=8
	b.add_theme_stylebox_override("normal",box)
	var hover=box.duplicate()
	hover.bg_color=Color("#FFF0D2")
	b.add_theme_stylebox_override("hover",hover)
	var down=box.duplicate()
	down.bg_color=Color("#F7CD80")
	b.add_theme_stylebox_override("pressed",down)
	var disabled=box.duplicate()
	disabled.bg_color=Color("#E5E9EF")
	b.add_theme_stylebox_override("disabled",disabled)
	b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	b.pressed.connect(callback)
	return b

func _process(delta: float) -> void:
	if finished_race:
		return
	var dt=minf(delta,.1)
	if countdown>0.0:
		countdown=maxf(0.0,countdown-dt)
		if countdown<=0.0:
			countdown_label.hide()
		else:
			countdown_label.text=str(maxi(1,int(ceil(countdown))))
		return
	boost_time=maxf(0.0,boost_time-dt)
	boost_cooldown=maxf(0.0,boost_cooldown-dt)
	slow_time=maxf(0.0,slow_time-dt)
	var speed=33.0
	if boost_time>0.0:
		speed=48.0
	if slow_time>0.0:
		speed=25.0
	distance+=speed*dt
	time_elapsed+=dt
	wing_clock+=dt
	for i in range(3):
		var rival_speed=29.0+float(i)*1.8+sin(time_elapsed*.8+float(i))*.9
		enemy_distances[i]=float(enemy_distances[i])+rival_speed*dt
		if int(time_elapsed+float(i)*2.0)%8==0:
			enemy_lanes[i]=(i+int(time_elapsed/6.0))%3
	for i in range(items.size()):
		var item: Dictionary=items[i]
		if bool(item.get("taken",false)):
			continue
		if distance>=float(item["distance"]):
			item["taken"]=true
			items[i]=item
			if int(item["lane"])==lane:
				match str(item["type"]):
					"star":
						stars+=1
						help_label.text="⭐ 收到一顆星星！"
					"wind":
						boost_time=2.0
						help_label.text="💨 順風飛得更快！"
					"cloud":
						slow_time=1.0
						clouds_touched+=1
						help_label.text="☁️ 穿過軟軟的雲朵，繼續飛！"
	track.scroll+=dt*speed*(1.7 if not calm else .65)
	track.flight_distance=distance
	track.objects=items
	track.queue_redraw()
	boost_button.disabled=boost_cooldown>0.0
	if not calm:
		my_bird.set_flap(sin(wing_clock*9.0))
		for i in range(rival_birds.size()):
			rival_birds[i].set_flap(sin(wing_clock*8.0+float(i)))
	_place_birds()
	_refresh_hud()
	if distance>=FINISH_DISTANCE:
		_finish()

func _refresh_hud() -> void:
	hud.text="🏆 第 %d / 4 名　　⭐ %d 顆　　🪽 %d%%" % [
		Rules.rank(distance,enemy_distances),stars,
		clampi(int(distance/FINISH_DISTANCE*100.0),0,100)]

func _place_birds() -> void:
	if track==null or track.size.x<1.0 or my_bird==null:
		return
	var size_bird=Vector2(118,101)
	my_bird.size=size_bird
	my_bird.position=Vector2(track.player_x()-size_bird.x*.5,
		track.lane_y(lane)-size_bird.y*.5)
	for i in range(rival_birds.size()):
		var bird: Control=rival_birds[i]
		bird.size=size_bird*.78
		var offset=(float(enemy_distances[i])-distance)*1.55
		bird.position=Vector2(track.player_x()+offset-bird.size.x*.5,
			track.lane_y(int(enemy_lanes[i]))-bird.size.y*.5)
		bird.visible=bird.position.x> -bird.size.x and bird.position.x<track.size.x

func move_altitude(direction: int) -> void:
	if finished_race or countdown>0.0:
		return
	lane=clampi(lane+direction,0,2)
	_place_birds()

func boost() -> void:
	if finished_race or countdown>0.0 or boost_cooldown>0.0:
		return
	boost_time=2.0
	boost_cooldown=8.0
	help_label.text="✨ 加速飛翔！"

func _input_track(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_finger<0:
			active_finger=event.index
			start_touch=event.position
		elif not event.pressed and active_finger==event.index:
			_apply_swipe(event.position)
			active_finger=-1
			track.accept_event()
	elif event is InputEventScreenDrag and event.index==active_finger:
		track.accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_down=true
			start_touch=event.position
		elif mouse_down:
			mouse_down=false
			_apply_swipe(event.position)
	elif event is InputEventMouseMotion and mouse_down:
		track.accept_event()

func _apply_swipe(end_pos: Vector2) -> void:
	if absf(end_pos.y-start_touch.y)<35.0:
		return
	move_altitude(-1 if end_pos.y<start_touch.y else 1)

func _finish() -> void:
	if finished_race:
		return
	finished_race=true
	set_process(false)
	var place=Rules.rank(distance,enemy_distances)
	finished.emit({
		"bird_id":str(player.get("id","bird_mandarin")),
		"course_id":course_id,
		"place":place,
		"stars_collected":stars,
		"stars_earned":Rules.stars_awarded(place,stars),
		"clouds_touched":clouds_touched,
		"duration_seconds":time_elapsed
	})
