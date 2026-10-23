extends Control
## The enlarged ORIGINAL AnimalArt. This layer owns finger painting gestures,
## never a second drawing of an animal. Tap alone only selects a brush start;
## pigment is laid down progressively while the finger is MOVING.
signal stroke_began
signal stroke_finished(page: Dictionary)

const OriginalArt = preload("res://scripts/AnimalArt.gd")
const SPACING: float = 7.0
const MAX_DOTS_PER_ANIMAL: int = 4800

var animal_id: String="cow"
var colors: Dictionary={}
var brush_color: String="#F26A72"
var avatar: Control
var tracking: bool=false
var touch_id: int=-1
var mouse_tracking: bool=false
var last_pos: Vector2=Vector2.ZERO
var active_region: String=""
var active_stroke_index: int=-1
var dirty: bool=false
var sample_total: int=0

func setup(id: String, saved: Dictionary={}) -> void:
	finish_stroke()
	animal_id=id
	colors=saved.duplicate(true)
	sample_total=_dots_count()
	if is_instance_valid(avatar):
		avatar.setup({"id":animal_id,"color":"#FFFFFF"})
		avatar.set_coloring(true,colors)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	avatar=OriginalArt.new()
	avatar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(avatar)
	avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar.setup({"id":animal_id,"color":"#FFFFFF"})
	avatar.set_coloring(true,colors)

func get_regions() -> Array:
	return avatar.get_coloring_regions() if is_instance_valid(avatar) else []

func region_at(point: Vector2) -> String:
	if not is_instance_valid(avatar):
		return ""
	return avatar.color_region_at(point)

func refresh_colors() -> void:
	if not tracking:
		sample_total=_dots_count()
	if is_instance_valid(avatar):
		avatar.set_coloring(true,colors)

func _dots_count() -> int:
	var total=0
	for stroke in colors.get("strokes_v2",[]):
		total+=stroke.get("dots",[]).size()
	return total

func begin_stroke(point: Vector2) -> void:
	if tracking:
		finish_stroke()
	tracking=true
	last_pos=point
	active_region=""
	active_stroke_index=-1
	dirty=false
	# Important: DOWN alone never paints or fills a whole shape.

func _paint_dot(point: Vector2) -> void:
	if sample_total>=MAX_DOTS_PER_ANIMAL:
		return
	var region=region_at(point)
	if region.is_empty():
		active_region=""
		active_stroke_index=-1
		return
	var world: Vector2=avatar.coloring_world_point(point)
	if absf(world.x)>260.0 or absf(world.y)>260.0:
		return
	if not dirty:
		stroke_began.emit()
		dirty=true
	if not colors.has("strokes_v2") or not colors["strokes_v2"] is Array:
		colors["strokes_v2"]=[]
	if active_region!=region or active_stroke_index<0:
		active_region=region
		var stroke={"region":region,"color":brush_color,"dots":[]}
		colors["strokes_v2"].append(stroke)
		active_stroke_index=colors["strokes_v2"].size()-1
	# Round coordinates to reduce save size without visible stepping.
	var point_pair=[snappedf(world.x,0.5),snappedf(world.y,0.5)]
	colors["strokes_v2"][active_stroke_index]["dots"].append(point_pair)
	sample_total+=1

func move_stroke(point: Vector2) -> void:
	if not tracking:
		return
	var distance=last_pos.distance_to(point)
	# Ignore micro-jitter; a single tap never fills a region.
	if distance<2.0:
		return
	var steps=clampi(int(ceil(distance/SPACING)),1,60)
	for i in range(1,steps+1):
		var intermediate=last_pos.lerp(point,float(i)/float(steps))
		_paint_dot(intermediate)
	last_pos=point
	if dirty:
		refresh_colors()

func finish_stroke() -> void:
	if not tracking:
		return
	tracking=false
	if dirty:
		stroke_finished.emit(colors.duplicate(true))
	dirty=false
	active_region=""
	active_stroke_index=-1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id==-1 and not mouse_tracking:
			touch_id=event.index
			begin_stroke(event.position)
			accept_event()
		elif not event.pressed and touch_id==event.index:
			finish_stroke()
			touch_id=-1
			accept_event()
	elif event is InputEventScreenDrag and touch_id==event.index:
		move_stroke(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and touch_id==-1:
		if event.pressed and not mouse_tracking:
			mouse_tracking=true
			begin_stroke(event.position)
		elif not event.pressed and mouse_tracking:
			finish_stroke()
			mouse_tracking=false
		accept_event()
	elif event is InputEventMouseMotion and mouse_tracking and touch_id==-1:
		move_stroke(event.position)
		accept_event()

func _exit_tree() -> void:
	finish_stroke()
