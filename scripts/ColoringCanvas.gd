extends Control
## IMPORTANT: Do not draw a second likeness. This directly embeds and
## enlarges the ORIGINAL AnimalArt used in the farm, forest and album.
## The same drawing functions generate both black/white regions and touch hits.
signal region_touched(region: String)
const OriginalArt = preload("res://scripts/AnimalArt.gd")

var animal_id: String = "cow"
var colors: Dictionary = {}
var avatar: Control
var drag_region: String = ""

func setup(id: String, saved: Dictionary={}) -> void:
	animal_id=id
	colors=saved.duplicate(true)
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

func region_at(local_pos: Vector2) -> String:
	if not is_instance_valid(avatar):
		return ""
	return avatar.color_region_at(local_pos)

func paint_at(local_pos: Vector2) -> String:
	var id=region_at(local_pos)
	if id!="" and id!=drag_region:
		drag_region=id
		region_touched.emit(id)
	return id

func refresh_colors() -> void:
	if is_instance_valid(avatar):
		avatar.set_coloring(true,colors)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_region=""
			paint_at(event.position)
		else:
			drag_region=""
		accept_event()
	elif event is InputEventScreenDrag:
		paint_at(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_region=""
			paint_at(event.position)
		else:
			drag_region=""
		accept_event()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT)!=0:
		paint_at(event.position)
		accept_event()
