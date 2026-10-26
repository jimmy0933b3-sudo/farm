extends Control
## Celebration card shown before the rewards. No failure screen for young kids.
const AnimalArt=preload("res://scripts/AnimalArt.gd")
var racer: Dictionary={}
var place: int=1
var time: float=0.0
var gentle: bool=false
var portrait

func setup(info: Dictionary,result_place: int,reduce_motion: bool) -> void:
	racer=info
	place=clampi(result_place,1,4)
	gentle=reduce_motion

func _ready() -> void:
	custom_minimum_size=Vector2(0,205)
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	portrait=AnimalArt.new()
	portrait.setup(racer)
	portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	resized.connect(_layout)
	_layout()
	set_process(not gentle)

func _layout() -> void:
	if portrait!=null:
		var h: float=minf(size.y*.55,152.0)
		portrait.size=Vector2(h*1.12,h)
		portrait.position=Vector2(size.x*.5-portrait.size.x*.5,size.y*.14)

func _process(delta: float) -> void:
	time+=minf(delta,.06)
	if portrait!=null:
		portrait.rotation=sin(time*4.3)*.05
	queue_redraw()

func _draw() -> void:
	if size.x<1.0 or size.y<1.0:
		return
	var center=Vector2(size.x*.5,size.y*.5)
	var medal: Color=[Color("#FFD26C"),Color("#CFD7E8"),
		Color("#E6A67B"),Color("#9AD8CB")][place-1]
	draw_circle(center+Vector2(0,15),size.y*.52,Color("#FFF1CD",.37))
	for side in [-1,1]:
		var p: Vector2=Vector2(center.x+float(side)*180.0,center.y-10.0)
		var beam=PackedVector2Array([p+Vector2(-35,-140),p+Vector2(35,-140),
			p+Vector2(83,140),p+Vector2(-83,140)])
		draw_colored_polygon(beam,Color("#FFE8AB",.15))
	var stage_width: float=124.0
	var foot: float=size.y*.82
	for n in range(3):
		var x: float=center.x+float(n-1)*stage_width
		var height: float=42.0+float(2-abs(n-1))*12.0
		var col: Color=[Color("#D6DFE9"),medal,Color("#D1CAA7")][n]
		draw_rect(Rect2(x-stage_width*.5,foot-height,stage_width-3,height),col)
		draw_line(Vector2(x-stage_width*.5,foot-height),Vector2(x+stage_width*.5-3,foot-height),
			Color.WHITE,4.0)
	draw_circle(Vector2(center.x,foot-86),21,medal)
	draw_arc(Vector2(center.x,foot-86),26,0,TAU,32,Color.WHITE,4.0)
	for i in range(32):
		var px: float=fposmod(float(i*127+7),size.x)
		var py: float=fposmod(float(i*87)+time*42.0,size.y)
		var color: Color=[Color("#F989A8"),Color("#FFE18C"),
			Color("#84DFB9"),Color("#9CC8F3")][i%4]
		draw_rect(Rect2(px,py,7,11),color)
