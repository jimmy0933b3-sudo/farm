extends VBoxContainer
## Toddler kart game: self-driving, three lanes, swipe or two giant buttons.
## No timers that punish the child, no flip/crash or online services.
signal finished(result: Dictionary)

const Rules = preload("res://scripts/RaceRules.gd")
const Track = preload("res://scripts/RaceTrack.gd")
const Kart = preload("res://scripts/RaceVehicle.gd")

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
var help_text: Label
var track: Control
var player_kart: Control
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
	add_child(top)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size",22)
	hud.add_theme_color_override("font_color",Color("#305553"))
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hud)

	track = Track.new()
	track.setup(str(race_track.get("id","farm")),reduce_motion)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.size_flags_vertical = Control.SIZE_EXPAND_FILL
	track.custom_minimum_size = Vector2(360,220)
	track.mouse_filter = Control.MOUSE_FILTER_STOP
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

	var bottom = HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation",14)
	add_child(bottom)
	bottom.add_child(_control_button("⬅️ 往左",Callable(self,"move_lane").bind(-1)))
	boost_button = _control_button("🚀 加速",Callable(self,"accelerate"))
	bottom.add_child(boost_button)
	bottom.add_child(_control_button("往右 ➡️",Callable(self,"move_lane").bind(1)))
	help_text = Label.new()
	help_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_text.add_theme_font_size_override("font_size",17)
	help_text.add_theme_color_override("font_color",Color("#486B5F"))
	help_text.text = "左右滑動換車道 · 自動往前開 · 收集星星！"
	add_child(help_text)
	_seed_items()
	_refresh_hud()
	_position_karts()
	if narrator != null:
		narrator.speak("準備好了！%s要跟農場朋友賽車囉！左右滑動換車道，看到星星記得收集。" % str(racer.get("name","你")))

func _control_button(title: String, action: Callable) -> Button:
	var btn = Button.new()
	btn.text = title
	btn.custom_minimum_size = Vector2(148,56)
	btn.add_theme_font_size_override("font_size",21)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#FFE3A6")
	style.border_color = Color("#FFFFFF")
	style.set_border_width_all(3)
	style.set_corner_radius_all(17)
	btn.add_theme_stylebox_override("normal",style)
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
	elapsed += dt
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
	track.set("race_objects",things)
	track.set("race_distance",distance)
	track.queue_redraw()
	_position_karts()
	boost_button.disabled = boost_cooldown>0.0
	hud_timer += dt
	if hud_timer>0.15:
		hud_timer=0.0
		_refresh_hud()
	if distance>=FINISH_DISTANCE:
		_complete()

func _take_item(kind: String) -> void:
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
	var scale_value: float = clampf(track.size.y/450.0,0.62,1.0)
	var ksize: Vector2 = Vector2(82,115)*scale_value
	player_kart.size=ksize
	player_kart.position=Vector2(track.lane_center(lane)-ksize.x*0.5,
		track.size.y*0.72-ksize.y*0.55)
	for i in range(ai_karts.size()):
		var kart: Control=ai_karts[i]
		kart.size=ksize
		var offset: float = (float(enemy_distances[i])-distance)*1.15
		kart.position=Vector2(track.lane_center(int(enemy_lanes[i]))-ksize.x*0.5,
			track.size.y*0.55-offset-ksize.y*0.5)
		kart.visible=kart.position.y>-ksize.y and kart.position.y<track.size.y+ksize.y

func _refresh_hud() -> void:
	last_hud_rank=Rules.rank(distance,enemy_distances)
	hud.text="🏁 第 %d / 4 名     ⭐ %d     %d%%     🛡️ %s" % [
		last_hud_rank,stars,int(distance/FINISH_DISTANCE*100.0),
		"有" if shield_seconds>0.0 else "無"]

func _complete() -> void:
	is_finished=true
	set_process(false)
	var place: int=Rules.rank(distance,enemy_distances)
	var gained: int=Rules.stars_awarded(place,stars)
	var result: Dictionary={
		"animal_id":str(racer.get("id","cow")),
		"track_id":str(race_track.get("id","farm")),
		"place":place,"stars_collected":stars,"stars_earned":gained,
		"duration_seconds":elapsed,"collisions":collisions
	}
	finished.emit(result)
