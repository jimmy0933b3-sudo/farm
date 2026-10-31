extends Control
## Original vector crops. Four growth stages, readable without external assets.
var crop_id: String=""
var growth_stage: int=0
# Garden beds draw their own raised 3D soil beneath the plant.
var show_soil: bool=true

func setup(id: String,stage_value: int) -> void:
	crop_id=id
	growth_stage=clampi(stage_value,0,3)
	queue_redraw()

func _oval(x: float,y: float,rx: float,ry: float,color: Color) -> void:
	var points=PackedVector2Array()
	for i in range(32):
		var a=float(i)*TAU/32.0
		points.append(Vector2(x+cos(a)*rx,y+sin(a)*ry))
	draw_colored_polygon(points,color)

func _poly(points: Array,color: Color) -> void:
	var shape=PackedVector2Array()
	for p in points:
		shape.append(p)
	draw_colored_polygon(shape,color)

func _draw() -> void:
	if size.x<=1.0 or size.y<=1.0:
		return
	var k=minf(size.x/175.0,size.y/145.0)
	draw_set_transform(Vector2(size.x*.5,size.y*.52),0.0,Vector2(k,k))
	if show_soil:
		_oval(0,53,77,17,Color("#B58558"))
		_oval(0,48,72,12,Color("#926746"))
		for i in range(5):
			_oval(-50+float(i)*24,48+float(i%2)*3,4,3,Color("#D6A57A"))
	if growth_stage==0:
		if show_soil:
			_oval(0,46,9,5,Color("#F8DD9A"))
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		return
	var factor=.42 if growth_stage==1 else (.72 if growth_stage==2 else 1.0)
	draw_line(Vector2(0,44),Vector2(0,36-47*factor),Color("#589E59"),6,true)
	if crop_id=="carrot":
		if growth_stage>=2:
			_poly([Vector2(-27*factor,26),Vector2(29*factor,26),
				Vector2(5*factor,48+12*factor),Vector2(-6*factor,48+12*factor)],
				Color("#E98036"))
			_oval(0,27,28*factor,26*factor,Color("#F5A047"))
			for i in range(3):
				draw_line(Vector2(-13*factor,20+float(i)*8),Vector2(12*factor,24+float(i)*8),Color("#D87737"),2,true)
		for n in range(3):
			var x=float(n-1)*23*factor
			_oval(x,-2-37*factor,13*factor,31*factor,Color("#76BE6B"))
			draw_line(Vector2(0,36),Vector2(x,-3-35*factor),Color("#488A54"),4,true)
	elif crop_id=="cabbage":
		for n in range(5):
			var x=float(n-2)*20*factor
			_oval(x,27-20*factor+absf(float(n-2))*5,23*factor,39*factor,
				Color("#63A966") if n%2==0 else Color("#9BD27D"))
		_oval(0,16,33*factor,35*factor,Color("#BEEA91"))
		for n in range(4):
			draw_arc(Vector2(float(n-2)*10*factor,23),23*factor,PI,TAU,20,Color("#6EA76C"),2,true)
	else:
		for n in range(5):
			var x=float(n-2)*19*factor
			_oval(x,29,29*factor,32*factor,Color("#E58A38") if n%2==0 else Color("#F5AA4C"))
		_oval(0,27,33*factor,32*factor,Color("#F5A852"))
		_oval(0,-7*factor,11*factor,7*factor,Color("#75AF62"))
		draw_line(Vector2(0,-6),Vector2(9*factor,-32*factor),Color("#558C50"),5,true)
		_oval(18*factor,-27*factor,20*factor,9*factor,Color("#7AC071"))
	if growth_stage==3:
		for n in range(3):
			var x=-54+float(n)*54
			draw_circle(Vector2(x,-48),4,Color("#FFF1B8"))
			draw_line(Vector2(x-7,-48),Vector2(x+7,-48),Color("#FFF1B8"),2,true)
			draw_line(Vector2(x,-55),Vector2(x,-41),Color("#FFF1B8"),2,true)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
