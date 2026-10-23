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
	var unit=minf(size.x/200.0,size.y/175.0)
	draw_set_transform(Vector2(size.x*0.5,size.y*0.54),0,Vector2(unit,unit))
	match cover_type:
		"coral":
			for i in range(7):
				var x=-70+float(i)*23
				draw_line(Vector2(x,78),Vector2(x,-40-float(i%3)*13),Color("#E77B9D"),14.0,true)
				_ell(x,7,22,15,Color("#F7ACAA"))
			_ell(0,80,88,16,Color("#CA987E"))
		"shell":
			for i in range(6):
				_ell(-50+float(i)*18,40-float(i%2)*19,23,48,Color("#F4CEB0"))
			_ell(0,80,85,18,Color("#DCA895"))
		"kelp":
			for i in range(6):
				var x=-64+float(i)*28
				draw_line(Vector2(x,79),Vector2(x+sin(float(i))*28,-52),Color("#3A967A"),12,true)
				_ell(x+13,-21,13,32,Color("#66C2A4"))
		"rocks":
			_ell(-53,34,45,44,Color("#8BA7BB"))
			_ell(37,28,56,53,Color("#728FA9"))
			_ell(10,45,36,38,Color("#A3BCCD"))
			_ell(0,75,92,13,Color("#C8B1A0"))
		"reef":
			for i in range(5):
				var x=-62+float(i)*31
				_ell(x,25,22,56,Color("#CA89B4"))
				_ell(x-8,-17,15,22,Color("#ECADCB"))
		"wreck":
			draw_line(Vector2(-85,68),Vector2(73,-15),Color("#A57F6D"),23,true)
			draw_line(Vector2(-43,45),Vector2(-70,-53),Color("#96735F"),15,true)
			_ell(47,37,45,29,Color("#90B4A6"))
	if revealed:
		draw_arc(Vector2.ZERO,88,0,TAU,35,Color("#FFF1A6",0.8),5,true)
	elif hint:
		draw_arc(Vector2.ZERO,91,0,TAU,35,Color("#FFE77F"),10,true)
		_ell(0,-98,13,13,Color("#FFF1A6"))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
