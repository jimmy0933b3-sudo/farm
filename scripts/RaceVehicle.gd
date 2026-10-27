extends Control
## Little illustrated karts that preserve each original animal/insect portrait.
## A vehicle has wheels, wing, rounded body, cockpit, headlights, steering lean,
## shield bubble, boost sparks, bobbing suspension and a readable racer name.
const AnimalArt = preload("res://scripts/AnimalArt.gd")
const MonsterArt = preload("res://scripts/MonsterArt.gd")

var info: Dictionary = {}
var selected: bool = false
var body_color: Color = Color("#F17972")
var avatar
var title_label: Label
var boosting: bool = false
var shielded: bool = false
var leaning: float = 0.0
var phase: float = 0.0
var reduce_motion: bool = false

func setup(animal_info: Dictionary, is_player: bool = false) -> void:
	info = animal_info
	selected = is_player
	body_color = Color("#F16B72") if selected else Color(str(info.get("color","#70B5D5")))
	if is_inside_tree():
		_attach_character()
	queue_redraw()

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size=Vector2(94,130)
	_attach_character()
	set_process(true)

func _process(delta: float) -> void:
	if reduce_motion:
		return
	phase+=minf(delta,.1)*(12.0 if boosting else 5.0)
	if avatar != null and is_instance_valid(avatar):
		avatar.rotation=sin(phase)*.022+leaning*.075
	if title_label != null:
		title_label.position.y = -16.0+sin(phase)*1.4
	queue_redraw()

func _attach_character() -> void:
	if avatar != null and is_instance_valid(avatar):
		avatar.queue_free()
	if title_label != null and is_instance_valid(title_label):
		title_label.queue_free()
	avatar=MonsterArt.new() if str(info.get("zone",""))=="monster" else AnimalArt.new()
	avatar.setup(info)
	avatar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	avatar.set_anchors_preset(Control.PRESET_FULL_RECT)
	# The face protrudes above the cockpit so beetle horns and butterfly wings
	# remain recognizable; no emoji substitute and no generic helmet.
	avatar.offset_left=-1.0
	avatar.offset_right=1.0
	avatar.offset_top=-5.0
	avatar.offset_bottom=-42.0
	add_child(avatar)
	title_label=Label.new()
	title_label.text=str(info.get("name","朋友"))
	title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top=-16
	title_label.offset_bottom=14
	title_label.add_theme_font_size_override("font_size",17)
	title_label.add_theme_color_override("font_color",Color("#263B46"))
	title_label.add_theme_color_override("font_shadow_color",Color("#FFFFFF"))
	title_label.add_theme_constant_override("shadow_offset_x",1)
	title_label.add_theme_constant_override("shadow_offset_y",1)
	add_child(title_label)

func _rounded_rect(rect: Rect2,fill: Color,radius: float) -> void:
	# Draw a rounded silhouette without textures or external assets.
	draw_rect(Rect2(rect.position.x+radius,rect.position.y,rect.size.x-2*radius,rect.size.y),fill)
	draw_rect(Rect2(rect.position.x,rect.position.y+radius,rect.size.x,rect.size.y-2*radius),fill)
	for corner in [Vector2(rect.position.x+radius,rect.position.y+radius),
		Vector2(rect.end.x-radius,rect.position.y+radius),
		Vector2(rect.position.x+radius,rect.end.y-radius),
		Vector2(rect.end.x-radius,rect.end.y-radius)]:
		draw_circle(corner,radius,fill)

func _draw() -> void:
	if size.x<45.0 or size.y<60.0:
		return
	var k: float=minf(size.x/94.0,size.y/130.0)
	var cx: float=size.x*.5
	var y: float=size.y-41.0*k
	var bounce: float=0.0 if reduce_motion else sin(phase*2.1)*1.6*k
	var ink=Color("#384654")
	var tire=Color("#3A4550")
	var wheel=Color("#BCC6CC")
	var chassis=body_color
	# Ground shadow, rear spoiler and thick cartoon wheels.
	draw_circle(Vector2(cx,y+29*k),38*k,Color("#29473E",.24))
	_rounded_rect(Rect2(cx-35*k,y-27*k+bounce,70*k,13*k),ink,6*k)
	_rounded_rect(Rect2(cx-30*k,y-30*k+bounce,60*k,12*k),chassis.lightened(.20),5*k)
	for side in [-1.0,1.0]:
		for offset in [-23.0,20.0]:
			var p: Vector2=Vector2(cx+side*35*k,y+offset*k+bounce)
			_rounded_rect(Rect2(p.x-8*k,p.y-14*k,16*k,25*k),tire,5*k)
			draw_circle(p,5*k,wheel)
			draw_circle(p,2*k,ink)
	# Body outline and racing stripes.
	_rounded_rect(Rect2(cx-34*k,y-19*k+bounce,68*k,64*k),ink,15*k)
	_rounded_rect(Rect2(cx-31*k,y-16*k+bounce,62*k,58*k),chassis,13*k)
	_rounded_rect(Rect2(cx-20*k,y-7*k+bounce,40*k,18*k),Color("#E2F6F3"),8*k)
	draw_line(Vector2(cx,y-4*k+bounce),Vector2(cx,y+34*k+bounce),
		chassis.lightened(.43),7*k,true)
	_rounded_rect(Rect2(cx-33*k,y+24*k+bounce,66*k,16*k),chassis.darkened(.17),7*k)
	# Friendly smiling bonnet: eyes are headlights, nose is the horn.
	for sign in [-1.0,1.0]:
		draw_circle(Vector2(cx+sign*22*k,y+29*k+bounce),6*k,Color("#FFF5CA"))
		draw_circle(Vector2(cx+sign*23*k,y+28*k+bounce),2.4*k,Color.WHITE)
	draw_arc(Vector2(cx,y+27*k+bounce),10*k,0.14,PI-0.14,12,
		Color("#FFFFFF"),2.4*k)
	if selected:
		draw_arc(Vector2(cx,y+5*k),48*k,PI*.15,PI*.85,24,
			Color("#FFE68A",.8),3.0*k)
	# Exhaust, protected bubble and speed sparks. Effects attach to the kart,
	# never obscure the species portrait above it.
	if boosting and not reduce_motion:
		for side in [-1.0,1.0]:
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx+side*20*k,y+42*k),
				Vector2(cx+side*14*k,y+(68+sin(phase*3.0)*9)*k),
				Vector2(cx+side*26*k,y+43*k)]),Color("#FFAB51"))
			draw_line(Vector2(cx+side*18*k,y+47*k),Vector2(cx+side*16*k,y+59*k),
				Color("#FFE9A5"),3*k,true)
	if shielded:
		draw_circle(Vector2(cx,y-9*k),51*k,Color("#A8F1FF",.14))
		draw_arc(Vector2(cx,y-9*k),51*k,0,TAU,48,Color("#77DCF4",.78),3*k)
		draw_arc(Vector2(cx-5*k,y-12*k),43*k,3.45,4.1,14,Color.WHITE,.9*k)
