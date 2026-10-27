extends Control
## Drawn-on-device celebratory effects for every monster action, no asset downloads.
var monster_id: String=""
var activity: String=""
var time_left: float=0.0
var elapsed: float=0.0
var gentle: bool=false

func trigger(id: String, action: String, reduce_motion: bool=false) -> void:
	monster_id=id
	activity=action
	gentle=reduce_motion
	time_left=1.7
	elapsed=0.0
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_process(not gentle)
	queue_redraw()

func _process(delta: float) -> void:
	time_left=maxf(0.0,time_left-minf(delta,.1))
	elapsed+=minf(delta,.1)
	if time_left<=0.0:
		set_process(false)
	queue_redraw()

func _star(center: Vector2, radius: float, fill: Color) -> void:
	var shape=PackedVector2Array()
	for n in range(10):
		var angle=-PI/2.0+float(n)*PI/5.0
		var r=radius if n%2==0 else radius*.46
		shape.append(center+Vector2(cos(angle),sin(angle))*r)
	draw_colored_polygon(shape,fill)

func _draw() -> void:
	if time_left<=0.0 or size.x<=0.0:
		return
	var fade=clampf(time_left/1.7,0.0,1.0)
	var center=Vector2(size.x*.5,size.y*.44)
	for i in range(18):
		var phase=float(i)*TAU/18.0
		var spread=(52.0+elapsed*76.0+float(i%3)*22.0) if not gentle else 86.0
		var p=center+Vector2(cos(phase),sin(phase))*spread
		var color=Color("#FFDA7C")
		if activity=="pet":
			color=Color("#F5A2CE")
		elif activity=="feed":
			color=Color("#FFCE97")
		elif monster_id in ["monster_water","monster_bubble","monster_wing"]:
			color=Color("#89DDF2")
		elif monster_id in ["monster_sprout","monster_three_eyes"]:
			color=Color("#A9E58F")
		elif monster_id in ["monster_spark","monster_star","monster_rainbow"]:
			color=Color("#FAED97")
		elif monster_id in ["monster_cloud","monster_jelly"]:
			color=Color("#E9B3F4")
		color.a=fade*.85
		if monster_id in ["monster_water","monster_bubble","monster_cloud","monster_jelly"] and activity=="ability":
			draw_circle(p,7.0+float(i%4)*2.0,Color(color.r,color.g,color.b,fade*.37))
			draw_arc(p,7.0+float(i%4)*2.0,0,TAU,20,color,2.0,true)
		else:
			_star(p,7.0+float(i%3)*2.0,color)
	if activity=="ability" and monster_id=="monster_rainbow":
		for i in range(5):
			draw_arc(center,60.0+float(i)*8.0,PI,TAU,32,[
				Color("#F49BAE"),Color("#FFC98C"),Color("#FCF29F"),
				Color("#9FDFBB"),Color("#9ECBF0")][i]*Color(1,1,1,fade),4.0,true)
