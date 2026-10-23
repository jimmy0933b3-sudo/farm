extends Control
## Move a little hand with a finger/mouse over the animal. A real stroke,
## rather than a button press, rewards the player with happy body language.
signal stroked

const AnimalArt = preload("res://scripts/AnimalArt.gd")
const TouchHand = preload("res://scripts/TouchHand.gd")

var animal_info: Dictionary = {}
var avatar: Control
var hand: Control
var dragging: bool = false
var active_touch: int = -1
var dragging_mouse: bool = false
var last_point: Vector2
var traveled: float = 0.0
var reward_cooldown: float = 0.0
var joy_time: float = 0.0
var reduce_motion: bool = false
var strokes: int = 0

func setup(info: Dictionary, motion_reduced: bool = false) -> void:
	animal_info = info
	reduce_motion = motion_reduced

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	avatar = AnimalArt.new()
	avatar.setup(animal_info)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(avatar)
	hand = TouchHand.new()
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hand)
	set_process(true)

func _pettable(pos: Vector2) -> bool:
	if size.x <= 0.0 or size.y <= 0.0:
		return false
	var px = (pos.x-size.x*0.5)/(size.x*0.35)
	var py = (pos.y-size.y*0.5)/(size.y*0.41)
	return px*px+py*py <= 1.0

func begin_stroke(pos: Vector2) -> bool:
	if not _pettable(pos):
		return false
	dragging = true
	last_point = pos
	traveled = 0.0
	hand.show_hand = true
	hand.hand_position = pos
	hand.progress = 0.0
	hand.queue_redraw()
	return true

func move_stroke(pos: Vector2) -> void:
	if not dragging:
		return
	if not _pettable(pos):
		# Touching outside the animal should not count as petting.
		last_point = pos
		return
	var step = last_point.distance_to(pos)
	if step > 0.5 and step < size.length()*0.5:
		traveled += step
	last_point = pos
	hand.hand_position = pos
	hand.progress = clampf(traveled/72.0,0.0,1.0)
	hand.queue_redraw()
	if traveled >= 72.0 and reward_cooldown <= 0.0:
		traveled = 0.0
		reward_cooldown = 0.55
		joy_time = 1.25
		strokes += 1
		avatar.set("mood","happy")
		avatar.queue_redraw()
		hand.celebrating = true
		hand.effect_time = 0.0
		stroked.emit()

func end_stroke() -> void:
	dragging = false
	dragging_mouse = false
	active_touch = -1
	traveled = 0.0
	hand.progress = 0.0
	hand.queue_redraw()

func guide() -> void:
	hand.show_hand = true
	hand.hand_position = Vector2(size.x*0.5,size.y*0.35)
	hand.queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1:
			if begin_stroke(event.position):
				active_touch = event.index
				accept_event()
		elif not event.pressed and event.index == active_touch:
			end_stroke()
			accept_event()
	elif event is InputEventScreenDrag and event.index == active_touch:
		move_stroke(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if active_touch != -1:
			return
		if event.pressed:
			dragging_mouse = begin_stroke(event.position)
		elif dragging_mouse:
			end_stroke()
		accept_event()
	elif event is InputEventMouseMotion and dragging_mouse and active_touch == -1:
		move_stroke(event.position)
		accept_event()

func _process(delta: float) -> void:
	reward_cooldown = maxf(0.0,reward_cooldown-delta)
	joy_time = maxf(0.0,joy_time-delta)
	if hand.celebrating:
		hand.effect_time += delta
		if hand.effect_time >= 1.1:
			hand.celebrating = false
		hand.queue_redraw()
	if joy_time > 0.0:
		avatar.set("mood","happy")
		if not reduce_motion:
			avatar.pivot_offset = avatar.size*0.5
			avatar.rotation = sin(joy_time*11.0)*0.025
		avatar.queue_redraw()
	elif not dragging:
		avatar.set("mood","idle")
		avatar.rotation = 0.0
		avatar.queue_redraw()
