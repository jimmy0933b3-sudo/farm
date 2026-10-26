extends Control
## The original animal/insect illustrator is seated above a cute procedural kart.
const AnimalArt = preload("res://scripts/AnimalArt.gd")

var info: Dictionary = {}
var selected: bool = false
var body_color: Color = Color("#EE8B6F")
var avatar: Control

func setup(animal_info: Dictionary, is_player: bool = false) -> void:
	info = animal_info
	selected = is_player
	body_color = Color("#F39C75") if is_player else Color(str(info.get("color","#71AED4")))
	if is_inside_tree():
		_attach_character()
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(82,115)
	_attach_character()

func _attach_character() -> void:
	if avatar != null and is_instance_valid(avatar):
		avatar.queue_free()
	avatar = AnimalArt.new()
	avatar.setup(info)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar.offset_left = 1
	avatar.offset_right = -1
	avatar.offset_top = 0
	avatar.offset_bottom = -42
	add_child(avatar)

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var cx: float = size.x*0.5
	var sy: float = size.y
	var tire: Color = Color("#394451")
	for px in [-27.0,27.0]:
		draw_rect(Rect2(cx+px-9.0,sy-44.0,18.0,25.0),tire)
	draw_rect(Rect2(cx-29.0,sy-52.0,58.0,40.0),body_color)
	draw_rect(Rect2(cx-23.0,sy-41.0,46.0,23.0),body_color.lightened(0.16))
	draw_rect(Rect2(cx-26.0,sy-50.0,52.0,9.0),Color("#FFE0A9"))
	draw_circle(Vector2(cx,sy-34.0),7.0,Color("#F9FEFB"))
	if selected:
		draw_arc(Vector2(cx,sy-51.0),35,PI,TAU,24,Color("#FFD34A"),4.0)
