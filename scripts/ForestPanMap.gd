extends Control
## Horizontally pannable, original illustrated forest world.
## The map owns all tap/drag input; hideout sprites never intercept a gesture.
signal hideout_tapped(index: int)

const Hideout = preload("res://scripts/ForestHideSpot.gd")
const WORLD_WIDTH: float = 2920.0
const X_POSITIONS: Array = [310.0, 800.0, 1280.0, 1760.0, 2240.0, 2730.0]
const Y_FRACTIONS: Array = [0.64, 0.37, 0.62, 0.38, 0.65, 0.40]
const COVER_TYPES: Array = ["bush","trunk","flowers","log","rocks","branch"]

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
		node.custom_minimum_size = Vector2(194,174)
		add_child(node)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.focus_mode = Control.FOCUS_NONE
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
	var diameter = minf(196.0,maxf(135.0,size.y*0.48))
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

func _leaves(x: float,y: float,r: float,kind: int) -> void:
	var breeze = 0.0 if reduced_motion else sin(phase*0.7+float(kind)*2.3)*5.0
	draw_line(Vector2(x,y+50),Vector2(x+breeze*0.4,y-48),Color("#86684D"),13.0,true)
	_disc(x+breeze,y-54,r,r*0.8,Color("#378F65"))
	_disc(x-r*0.4+breeze,y-45,r*0.7,r*0.65,Color("#5AB679"))
	_disc(x+r*0.45+breeze,y-59,r*0.5,r*0.55,Color("#77C88D"))

func _draw() -> void:
	var height = size.y
	draw_rect(Rect2(Vector2.ZERO,size),Color("#B7EAF4"))
	_disc(size.x*0.83,height*0.14,47.0,47.0,Color("#FFF1A6"))
	draw_set_transform(Vector2(-camera_x,0.0),0.0,Vector2.ONE)
	# The world is over twice a tablet viewport in width. Seven scenic regions
	# are drawn in one coherent strip, not a static six-card grid.
	_disc(430.0,height*0.95,760.0,height*0.58,Color("#95D9A6"))
	_disc(1480.0,height*0.95,880.0,height*0.54,Color("#78CB9A"))
	_disc(2560.0,height*0.94,920.0,height*0.63,Color("#6ABB90"))
	draw_rect(Rect2(0,height*0.80,WORLD_WIDTH,height*0.24),Color("#77BF84"))
	for i in range(29):
		var x=50.0+float(i)*101.0
		var r=32.0+float(i%4)*8.0
		_leaves(x,height*0.32+float(i%3)*21.0,r,i)
	# A curving stream and wooden bridge around the middle of the world.
	var river=PackedVector2Array([
		Vector2(1480,-20),Vector2(1615,-20),
		Vector2(1575,height*0.38),Vector2(1630,height*0.62),
		Vector2(1690,height+20),Vector2(1500,height+20),
		Vector2(1514,height*0.62),Vector2(1450,height*0.38)
	])
	draw_colored_polygon(river,Color("#87D5E4"))
	for y in [0.22,0.43,0.7,0.85]:
		draw_line(Vector2(1510,height*float(y)),Vector2(1554,height*float(y)),Color("#E5F9FC"),4.0,true)
	draw_rect(Rect2(1448,height*0.68,225,29),Color("#AA815D"))
	for i in range(8):
		var bx=1460.0+float(i)*28.0
		draw_line(Vector2(bx,height*0.675),Vector2(bx,height*0.76),Color("#77563E"),3.0)
	# Flower meadow, fallen logs, mushroom patches, rock trail and owl tree.
	for i in range(20):
		var fx=1020.0+float(i)*21.0
		var fy=height*(0.78+float(i%4)*0.034)
		draw_line(Vector2(fx,fy),Vector2(fx,fy-18),Color("#488B55"),3.0)
		_disc(fx,fy-19,6.0,6.0,Color("#F7C9A9") if i%2==0 else Color("#F6F2A9"))
	for i in range(9):
		var sx=1980.0+float(i)*30.0
		_disc(sx,height*0.87,20,11,Color("#A8B6AA"))
		_disc(sx+8,height*0.84,10,5,Color("#D3E1D2"))
	for i in range(6):
		var mx=480.0+float(i)*47.0
		_disc(mx,height*0.88,18,10,Color("#E58A77"))
		_disc(mx,height*0.92,7,14,Color("#F6EBDB"))
	draw_line(Vector2(2515,height*0.82),Vector2(2715,height*0.74),Color("#966E4B"),24.0,true)
	for i in range(13):
		var px=85.0+float(i)*225.0
		_disc(px,height*0.94,16,7,Color("#E7E5AE",0.9))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	# Always-visible page direction markers independent of written instructions.
	if camera_x > 30.0:
		draw_colored_polygon(PackedVector2Array([Vector2(6,height*0.5),Vector2(30,height*0.44),Vector2(30,height*0.56)]),Color("#FFFCED",0.9))
	if camera_x < WORLD_WIDTH-size.x-30.0:
		draw_colored_polygon(PackedVector2Array([Vector2(size.x-6,height*0.5),Vector2(size.x-30,height*0.44),Vector2(size.x-30,height*0.56)]),Color("#FFFCED",0.9))
