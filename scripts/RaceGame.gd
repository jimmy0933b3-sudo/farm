extends VBoxContainer
## Toddler kart game: self-driving, three lanes, swipe or two giant buttons.
## No timers that punish the child, no flip/crash or online services.
signal finished(result: Dictionary)

const Rules = preload("res://scripts/RaceRules.gd")
const Track = preload("res://scripts/RaceTrack.gd")
const Kart = preload("res://scripts/RaceVehicle.gd")
const Effects = preload("res://scripts/RaceEffects.gd")
const Sounds = preload("res://scripts/RaceSounds.gd")

const FINISH_DISTANCE: float = 2350.0
var racer: Dictionary = {}
var opponents: Array = []
var race_track: Dictionary = {}
var narrator
var reduce_motion: bool = false

var lane: int = 1
var distance: float = 0.0
var stars: int = 0
var elapsed: float = 0.0
var boost_seconds: float = 0.0
var boost_cooldown: float = 0.0
var shield_seconds: float = 0.0
var slow_seconds: float = 0.0
var collisions: int = 0
var is_finished: bool = false
var enemy_distances: Array = [45.0,0.0,-40.0]
var enemy_lanes: Array = [0,2,1]
var things: Array = []
var hud: Label
var bar: ProgressBar
var countdown_remaining: float = 3.3
var countdown_digit: int = 4
var countdown_label: Label
var feedback_label: Label
var feedback_time: float = 0.0
var effects
var soundfx
var player_visual_x: float = -1.0
var help_text: Label
var track
var player_kart
var ai_karts: Array = []
var boost_button: Button
var touch_origin: Vector2 = Vector2.ZERO
var dragging: bool = false
var active_touch: int = -1
var mouse_dragging: bool = false
var last_hud_rank: int = 1
var hud_timer: float = 0.0

func configure(player: Dictionary, others: Array, chosen_track: Dictionary, voice, gentle: bool) -> void:
	racer = player
	opponents = others
	race_track = chosen_track
	narrator = voice
	reduce_motion = gentle

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",7)
	var top = HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.custom_minimum_size=Vector2(0,55)
	top.add_theme_constant_override("separation",12)
	add_child(top)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size",22)
	hud.add_theme_color_override("font_color",Color("#305553"))
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hud)
	bar=ProgressBar.new()
	bar.custom_minimum_size=Vector2(180,25)
	bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bar.max_value=FINISH_DISTANCE
	bar.show_percentage=false
	var bar_fill=StyleBoxFlat.new()
	bar_fill.bg_color=Color("#FFCF70")
	bar_fill.set_corner_radius_all(12)
	bar.add_theme_stylebox_override("fill",bar_fill)
	var bar_bg=StyleBoxFlat.new()
	bar_bg.bg_color=Color("#E9F1DA")
	bar_bg.set_corner_radius_all(12)
	bar.add_theme_stylebox_override("background",bar_bg)
	top.add_child(bar)

	track = Track.new()
	track.setup(str(race_track.get("id","farm")),reduce_motion)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.size_flags_vertical = Control.SIZE_EXPAND_FILL
	track.custom_minimum_size = Vector2(360,220)
	track.mouse_filter = Control.MOUSE_FILTER_STOP
	track.clip_contents=true
	add_child(track)
	track.gui_input.connect(_track_input)
	track.resized.connect(_position_karts)

	player_kart = Kart.new()
	player_kart.setup(racer,true)
	player_kart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(player_kart)
	for index in range(3):
		var animal: Dictionary = opponents[index] if index<opponents.size() else racer
		var kart = Kart.new()
		kart.setup(animal)
		kart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(kart)
		ai_karts.append(kart)

	effects=Effects.new()
	effects.reduce_motion=reduce_motion
	effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track.add_child(effects)
	countdown_label=Label.new()
	countdown_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	countdown_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	countdown_label.add_theme_font_size_override("font_size",96)
	countdown_label.add_theme_color_override("font_color",Color("#FFF5BD"))
	countdown_label.add_theme_color_override("font_outline_color",Color("#2D675A"))
	countdown_label.add_theme_constant_override("outline_size",13)
	countdown_label.text="3"
	track.add_child(countdown_label)
	feedback_label=Label.new()
	feedback_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	feedback_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	feedback_label.offset_top=8
	feedback_label.offset_bottom=42
	feedback_label.add_theme_font_size_override("font_size",23)
	feedback_label.add_theme_color_override("font_color",Color("#FFFFFF"))
	feedback_label.add_theme_color_override("font_outline_color",Color("#315B53"))
	feedback_label.add_theme_constant_override("outline_size",7)
	track.add_child(feedback_label)
	var bottom = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation",20)
	add_child(bottom)
	bottom.add_child(_control_button("⬅️ 往左",Callable(self,"move_lane").bind(-1)))
	boost_button = _control_button("🚀 加速",Callable(self,"accelerate"))
	bottom.add_child(boost_button)
	bottom.add_child(_control_button("往右 ➡️",Callable(self,"move_lane").bind(1)))
	help_text = Label.new()
	help_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_text.add_theme_font_size_override("font_size",17)
	help_text.add_theme_color_override("font_color",Color("#486B5F"))
	help_text.text = "左右滑動換車道 · 自動開車 · 撿星星換獎勵！"
	add_child(help_text)
	soundfx=Sounds.new()
	soundfx.enabled=narrator==null or bool(narrator.enabled)
	add_child(soundfx)
	_seed_items()
	_refresh_hud()
	_position_karts()
	if narrator != null:
		narrator.speak("%s準備好了嗎？三、二、一，出發！" % str(racer.get("name","你")))

func _control_button(title: String, action: Callable) -> Button:
	var btn = Button.new()
	btn.text = title
	# High-contrast text and a large touch target for children.
	btn.custom_minimum_size = Vector2(172,68)
	btn.add_theme_font_size_override("font_size",23)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		btn.add_theme_color_override(state,Color("#233649"))
	btn.add_theme_color_override("font_disabled_color",Color("#485765"))
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#FFE8AA")
	style.border_color = Color("#976023")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal",style)
	var hover = style.duplicate()
	hover.bg_color = Color("#FFF2CD")
	btn.add_theme_stylebox_override("hover",hover)
	var pressed = style.duplicate()
	pressed.bg_color = Color("#F5C96B")
	btn.add_theme_stylebox_override("pressed",pressed)
	var disabled = style.duplicate()
	disabled.bg_color = Color("#E6EBEF")
	disabled.border_color = Color("#8F9BA3")
	btn.add_theme_stylebox_override("disabled",disabled)
	btn.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	btn.pressed.connect(action)
	return btn

func _seed_items() -> void:
	things.clear()
	# Fixed seeded layout avoids random unreachable obstacles. One item per
	# row and an empty passing lane on both sides.
	for i in range(1,23):
		var type: String = "star"
		if i%6==0:
			type="shield"
		elif i%4==0:
			type="bump"
		elif i%5==0:
			type="boost"
		things.append({"distance":float(i)*100.0+65.0,"lane":(i*2+1)%3,
			"type":type,"hit":false})

func _process(delta: float) -> void:
	if is_finished:
		return
	var dt: float = minf(delta,0.10)
	if countdown_remaining>0.0:
		countdown_remaining=maxf(0.0,countdown_remaining-dt)
		var number: int=ceili(countdown_remaining)
		if number!=countdown_digit:
			countdown_digit=number
			if number>0:
				countdown_label.text=str(number)
				soundfx.play_effect("count")
			else:
				countdown_label.text="GO!"
				soundfx.play_effect("go")
				effects.cheer("go",track.size*.5)
		_position_karts()
		track.queue_redraw()
		return
	if countdown_label.visible:
		countdown_label.hide()
	elapsed += dt
	feedback_time=maxf(0.0,feedback_time-dt)
	if feedback_time<=0.0:
		feedback_label.text=""
	boost_seconds = maxf(0.0,boost_seconds-dt)
	boost_cooldown = maxf(0.0,boost_cooldown-dt)
	shield_seconds = maxf(0.0,shield_seconds-dt)
	slow_seconds = maxf(0.0,slow_seconds-dt)
	var speed: float = 41.0
	if boost_seconds>0.0:
		speed=59.0
	if slow_seconds>0.0:
		speed=29.0
	distance += speed*dt
	for i in range(enemy_distances.size()):
		var competitor_speed: float = 36.0+float(i)*2.1
		competitor_speed += sin(elapsed*0.64+float(i)*2.0)*2.2
		enemy_distances[i] = float(enemy_distances[i])+competitor_speed*dt
		if int(elapsed/5.0+float(i)*1.7)%3==0:
			enemy_lanes[i]=(i+int(elapsed/5.0))%3
	for i in range(things.size()):
		var thing: Dictionary = things[i]
		if bool(thing.get("hit",false)):
			continue
		if distance >= float(thing["distance"]) and distance-float(thing["distance"])<speed*dt+1.0:
			thing["hit"]=true
			things[i]=thing
			if int(thing["lane"])==lane:
				_take_item(str(thing["type"]))
	track.scroll += speed*dt*(1.4 if not reduce_motion else 0.65)
	track.race_objects=things
	track.race_distance=distance
	track.boost_active=boost_seconds>0.0
	track.shield_active=shield_seconds>0.0
	track.speed_ratio=speed/41.0
	if bar!=null:
		bar.value=distance
	track.queue_redraw()
	_position_karts()
	boost_button.disabled = boost_cooldown>0.0
	boost_button.text="🚀 加速" if boost_cooldown<=0.0 else "🚀 %d 秒" % ceili(boost_cooldown)
	hud_timer += dt
	if hud_timer>0.15:
		hud_timer=0.0
		_refresh_hud()
	if distance>=FINISH_DISTANCE:
		_complete()

func _take_item(kind: String) -> void:
	var location=Vector2(track.lane_center(lane),track.size.y*.72)
	if effects!=null:
		effects.cheer(kind,location)
	if soundfx!=null:
		soundfx.play_effect(kind)
	feedback_time=1.2
	if feedback_label!=null:
		feedback_label.text=match_text(kind)
	match kind:
		"star":
			stars+=1
			help_text.text="⭐ 撿到星星啦！"
		"boost":
			boost_seconds=2.3
			help_text.text="🚀 超級加速！"
		"shield":
			shield_seconds=4.0
			help_text.text="🛡️ 泡泡保護車車！"
		"bump":
			if shield_seconds<=0.0:
				slow_seconds=1.2
				collisions+=1
				help_text.text="碰到小稻草，慢慢開也沒關係！"

func match_text(kind: String) -> String:
	match kind:
		"star": return "⭐ 撿到星星！"
		"boost": return "⚡ 加速！"
		"shield": return "🛡️ 泡泡護盾！"
		"bump": return "🌾 慢慢開也沒關係！"
	return ""

func move_lane(direction: int) -> void:
	if is_finished:
		return
	lane=clampi(lane+direction,0,2)
	_position_karts()

func accelerate() -> void:
	if is_finished or boost_cooldown>0.0:
		return
	boost_seconds=2.0
	boost_cooldown=8.0
	help_text.text="🚀 加速囉！"
	if effects!=null:
		effects.cheer("boost",Vector2(track.lane_center(lane),track.size.y*.72))
	if soundfx!=null:
		soundfx.play_effect("boost")

func _track_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch<0:
			active_touch=event.index
			touch_origin=event.position
			dragging=true
		elif not event.pressed and active_touch==event.index:
			_apply_swipe(event.position)
			active_touch=-1
			dragging=false
			track.accept_event()
	elif event is InputEventScreenDrag and dragging and event.index==active_touch:
		track.accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_dragging=true
			touch_origin=event.position
		elif mouse_dragging:
			mouse_dragging=false
			_apply_swipe(event.position)
	elif event is InputEventMouseMotion and mouse_dragging:
		track.accept_event()

func _apply_swipe(end_pos: Vector2) -> void:
	var next_lane: int = Rules.lane_after_swipe(lane,end_pos.x-touch_origin.x)
	if next_lane!=lane:
		lane=next_lane
		_position_karts()

func _position_karts() -> void:
	if track==null or not is_instance_valid(track) or player_kart==null:
		return
	if track.size.x<1.0 or track.size.y<1.0:
		return
	var scale_value: float = clampf(track.size.y/430.0,0.60,1.04)
	var ksize: Vector2 = Vector2(94,130)*scale_value
	player_kart.size=ksize
	var player_y: float=track.size.y*.70-ksize.y*.55
	var goal_x: float=track.lane_center_at(lane,player_y+ksize.y*.55)
	if player_visual_x<0.0 or reduce_motion:
		player_visual_x=goal_x
	else:
		player_visual_x=lerpf(player_visual_x,goal_x,.24)
	player_kart.position=Vector2(player_visual_x-ksize.x*.5,player_y)
	player_kart.leaning=clampf((goal_x-player_visual_x)/60.0,-1.0,1.0)
	player_kart.boosting=boost_seconds>0.0
	player_kart.shielded=shield_seconds>0.0
	player_kart.reduce_motion=reduce_motion
	player_kart.queue_redraw()
	for i in range(ai_karts.size()):
		var kart=ai_karts[i]
		kart.size=ksize*.93
		var offset: float=(float(enemy_distances[i])-distance)*1.15
		var ky: float=track.size.y*.52-offset-ksize.y*.46
		kart.position=Vector2(track.lane_center_at(int(enemy_lanes[i]),ky+ksize.y*.46)
			-kart.size.x*.5,ky)
		kart.visible=ky>-ksize.y and ky<track.size.y+ksize.y
		kart.reduce_motion=reduce_motion
		kart.boosting=false
		kart.shielded=false
		kart.queue_redraw()

func _refresh_hud() -> void:
	var current_rank: int=Rules.rank(distance,enemy_distances)
	if distance>170.0 and current_rank<last_hud_rank and soundfx!=null:
		soundfx.play_effect("pass")
		if effects!=null:
			effects.cheer("pass",Vector2(track.lane_center(lane),track.size.y*.68))
	last_hud_rank=current_rank
	hud.text="🏁 第 %d / 4 名    ⭐ %d    🛡️ %s" % [
		last_hud_rank,stars,"ON" if shield_seconds>0.0 else "OFF"]

func _complete() -> void:
	is_finished=true
	set_process(false)
	if soundfx!=null:
		soundfx.play_effect("finish")
	var place: int=Rules.rank(distance,enemy_distances)
	var gained: int=Rules.stars_awarded(place,stars)
	var result: Dictionary={
		"animal_id":str(racer.get("id","cow")),
		"track_id":str(race_track.get("id","farm")),
		"place":place,"stars_collected":stars,"stars_earned":gained,
		"duration_seconds":elapsed,"collisions":collisions
	}
	finished.emit(result)
