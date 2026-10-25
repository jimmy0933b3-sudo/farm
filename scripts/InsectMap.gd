extends Control
## Horizontally pannable, original illustrated forest world.
## The map owns all tap/drag input; hideout sprites never intercept a gesture.
signal hideout_tapped(index: int)

const Hideout = preload("res://scripts/InsectHideSpot.gd")
const WORLD_WIDTH: float = 3740.0
const X_POSITIONS: Array = [270.0, 790.0, 1310.0, 1830.0, 2350.0, 2860.0, 3390.0]
const Y_FRACTIONS: Array = [0.66, 0.48, 0.65, 0.48, 0.68, 0.47, 0.66]
const COVER_TYPES: Array = ["flower","leaf","log","mushroom","grass","hive","soil"]

var animals: Array = []
var placements: Array = []
var spots: Array = []
var camera_x: float = 0.0
var reduced_motion: bool = false
var phase: float = 0.0
var frame_clock: float = 0.0
var active_touch: int = -1
var touch_dragging: bool = false
var mouse_dragging: bool = false
var last_pointer: Vector2 = Vector2.ZERO
var total_drag: float = 0.0

func setup(info: Array, positions: Array, reduce_motion: bool = false) -> void:
	animals = info
	placements = positions
	reduced_motion = reduce_motion

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in range(placements.size()):
		var node = Hideout.new()
		node.setup(i,str(COVER_TYPES[i]),_get_animal(str(placements[i])))
		node.custom_minimum_size = Vector2.ZERO
		add_child(node)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

		spots.append(node)
	resized.connect(_relayout)
	call_deferred("_relayout")

func _get_animal(id: String) -> Dictionary:
	for a in animals:
		if str(a.get("id","")) == id:
			return a
	return {}

func _relayout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	camera_x = clampf(camera_x,0.0,maxf(0.0,WORLD_WIDTH-size.x))
	var diameter = minf(178.0,maxf(122.0,size.y*0.57))
	for i in range(spots.size()):
		var spot: Control = spots[i]
		spot.size = Vector2(diameter,diameter*0.89)
		spot.position = spot_center_screen(i) - spot.size*0.5
	queue_redraw()

func spot_center_world(index: int) -> Vector2:
	return Vector2(float(X_POSITIONS[index]),size.y*float(Y_FRACTIONS[index]))

func spot_center_screen(index: int) -> Vector2:
	return spot_center_world(index) - Vector2(camera_x,0.0)

func _set_camera(value: float) -> void:
	camera_x = clampf(value,0.0,maxf(0.0,WORLD_WIDTH-size.x))
	_relayout()

func pan_by(delta_pixels: float) -> void:
	_set_camera(camera_x+delta_pixels)

func focus_spot(index: int) -> void:
	if index < 0 or index >= spots.size():
		return
	var destination = clampf(float(X_POSITIONS[index]) - size.x*0.52,0.0,maxf(0.0,WORLD_WIDTH-size.x))
	var tween = create_tween()
	tween.tween_method(Callable(self,"_set_camera"),camera_x,destination,0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if reduced_motion:
		return
	frame_clock += delta
	if frame_clock > 0.066:
		phase += frame_clock
		frame_clock = 0.0
		queue_redraw()

func _start_drag(point: Vector2) -> void:
	last_pointer = point
	total_drag = 0.0

func _move_drag(point: Vector2) -> void:
	var delta = point-last_pointer
	last_pointer = point
	total_drag += delta.length()
	if total_drag > 6.0:
		pan_by(-delta.x)

func _end_drag(point: Vector2) -> void:
	if total_drag < 20.0:
		tap_point(point)
	total_drag = 0.0

func tap_point(point: Vector2) -> int:
	for i in range(spots.size()):
		var center = spot_center_screen(i)
		var spot_size: Vector2 = spots[i].size
		var diff = point-center
		if absf(diff.x) < spot_size.x*0.52 and absf(diff.y) < spot_size.y*0.55:
			hideout_tapped.emit(i)
			return i
	return -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1:
			active_touch = event.index
			touch_dragging = true
			_start_drag(event.position)
			accept_event()
		elif not event.pressed and active_touch == event.index:
			_end_drag(event.position)
			active_touch = -1
			touch_dragging = false
			accept_event()
	elif event is InputEventScreenDrag and touch_dragging and event.index == active_touch:
		_move_drag(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and active_touch == -1:
		if event.pressed:
			mouse_dragging = true
			_start_drag(event.position)
		elif mouse_dragging:
			_end_drag(event.position)
			mouse_dragging = false
		accept_event()
	elif event is InputEventMouseMotion and mouse_dragging and active_touch == -1:
		_move_drag(event.position)
		accept_event()

func _disc(cx: float,cy: float,rx: float,ry: float,tint: Color) -> void:
	var polygon=PackedVector2Array()
	for i in range(32):
		var rad = TAU*float(i)/32.0
		polygon.append(Vector2(cx+cos(rad)*rx,cy+sin(rad)*ry))
	draw_colored_polygon(polygon,tint)

func _draw() -> void:
	var h=size.y
	draw_rect(Rect2(Vector2.ZERO,size),Color("#D6F5F0"))
	draw_rect(Rect2(0,h*0.46,size.x,h*0.54),Color("#9DD68F"))
	draw_set_transform(Vector2(-camera_x,0),0,Vector2.ONE)
	for i in range(24):
		var x=float(i)*143.0+40.0
		_disc(x,h*0.2,42,23,Color("#FFFFFF",0.39))
	for i in range(16):
		var x=float(i)*215.0+50.0
		_disc(x,h*0.51,115,47,Color("#79C980"))
	for i in range(16):
		var x=112.0+float(i)*198.0
		draw_line(Vector2(x,h*.85),Vector2(x,h*.49),Color("#529A63"),7,true)
		for n in range(6):
			var angle=TAU*float(n)/6.0
			_disc(x+cos(angle)*23,h*.46+sin(angle)*23,21,19,Color("#F7B8D7") if i%2==0 else Color("#F5DB78"))
		_disc(x,h*.46,14,14,Color("#E4A158"))
	for i in range(26):
		var x=25.0+float(i)*124.0
		_disc(x,h*.91,48,20,Color("#78C079"))
		_disc(x+18,h*.83,22,13,Color("#B4DF93"))
	for i in range(14):
		var x=70.0+float(i)*238.0
		_disc(x,h*.99,71,12,Color("#E8C69F"))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if camera_x>15.0:
		draw_colored_polygon(PackedVector2Array([Vector2(5,h*.5),Vector2(28,h*.43),Vector2(28,h*.57)]),Color("#FFF6D4"))
	if camera_x<WORLD_WIDTH-size.x-15.0:
		draw_colored_polygon(PackedVector2Array([Vector2(size.x-5,h*.5),Vector2(size.x-28,h*.43),Vector2(size.x-28,h*.57)]),Color("#FFF6D4"))
