extends Control
## Large illustrated hiding place. Each press checks a real hidden animal,
## rather than a text quiz. Tappable surfaces are at least 140 px wide.

signal inspected(index: int)
const AnimalArt = preload("res://scripts/AnimalArt.gd")

var slot_index: int = 0
var cover_type: String = "bush"
var animal_info: Dictionary = {}
var revealed: bool = false
var hint: bool = false
var avatar: Control

func setup(index: int, cover: String, info: Dictionary) -> void:
	slot_index = index
	cover_type = cover
	animal_info = info

func _ready() -> void:
	# Decorative only. The parent map detects both taps and drags.
	# Never inherit Button theme background or steal swipe gestures.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar = AnimalArt.new()
	avatar.setup(animal_info)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar.visible = false
	add_child(avatar)

func set_hint(active: bool) -> void:
	hint = active
	queue_redraw()

func reveal() -> void:
	if revealed:
		return
	revealed = true
	hint = false
	avatar.visible = true
	avatar.set("mood","happy")
	avatar.queue_redraw()
	avatar.pivot_offset = avatar.size * 0.5
	avatar.scale = Vector2(0.35,0.35)
	avatar.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(avatar,"scale",Vector2.ONE,0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(avatar,"modulate:a",1.0,0.30)
	queue_redraw()

func _ell(x: float,y: float,rx: float,ry: float,color: Color) -> void:
	var shape=PackedVector2Array()
	for n in range(28):
		var a=TAU*float(n)/28.0
		shape.append(Vector2(x+cos(a)*rx,y+sin(a)*ry))
	draw_colored_polygon(shape,color)

func _draw() -> void:
	var scale_value=minf(size.x/200.0,size.y/175.0)
	draw_set_transform(Vector2(size.x*0.5,size.y*0.54),0.0,Vector2(scale_value,scale_value))
	_ell(0,65,86,22,Color("#59986E",0.75))
	# Different covers, not just six identical numbered boxes.
	match cover_type:
		"bush":
			for x in [-50.0,-14.0,30.0,60.0]:
				_ell(x,18+sin(x)*8.0,43,46,Color("#328C60"))
				_ell(x-14,-2,27,31,Color("#5FB479"))
		"trunk":
			draw_rect(Rect2(-43,-75,89,137),Color("#9E7050"))
			_ell(0,-9,26,37,Color("#664534"))
			for x in [-67.0,0.0,70.0]:
				_ell(x,-62,45,41,Color("#40976A"))
			_ell(-39,-85,30,35,Color("#71B982"))
		"flowers":
			for x in [-55.0,-20.0,15.0,50.0]:
				draw_line(Vector2(x,60),Vector2(x,-19),Color("#438E59"),6.0)
				_ell(x,-18,25,34,Color("#68B678"))
				for a in range(5):
					var ang=TAU*float(a)/5.0
					_ell(x+cos(ang)*15.0,-17+sin(ang)*14.0,11,11,Color("#F6CA9E"))
				_ell(x,-17,8,8,Color("#F7D86D"))
		"log":
			draw_rect(Rect2(-92,7,184,47),Color("#B48356"))
			_ell(-89,30,27,30,Color("#856044"))
			_ell(-89,30,18,19,Color("#E0B789"))
			_ell(53,-4,61,27,Color("#398A60"))
			_ell(11,-26,50,26,Color("#66B77C"))
		"rocks":
			_ell(-47,23,48,49,Color("#899899"))
			_ell(40,18,58,59,Color("#8FA7A1"))
			_ell(3,37,39,40,Color("#586F74"))
			_ell(31,-17,31,14,Color("#B8CBC0"))
			_ell(-43,-9,19,9,Color("#AFC3B7"))
		"branch":
			draw_line(Vector2(-80,42),Vector2(78,-44),Color("#906B4E"),22.0)
			draw_line(Vector2(8,6),Vector2(39,-79),Color("#906B4E"),12.0)
			for x in [-65.0,-13.0,44.0]:
				_ell(x,-25,37,41,Color("#3D956D"))
				_ell(x+15,-50,21,27,Color("#70C088"))
	if revealed:
		# Animal sprite renders above the foliage and is the reward.
		draw_arc(Vector2.ZERO,92.0,0,TAU,32,Color("#F6D377",0.8),4.0,true)
	elif hint:
		draw_arc(Vector2.ZERO,92.0,0,TAU,40,Color("#FFDE62"),11.0,true)
		_ell(0,-96,12,13,Color("#FFDF76"))
		draw_line(Vector2(0,-101),Vector2(0,-79),Color("#FFDF76"),7.0)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
