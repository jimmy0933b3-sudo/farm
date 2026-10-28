extends Control
## Side-scrolling 2D sky race; birds occupy three real altitude lanes.
var course: String="lake"
var scroll: float=0.0
var flight_distance: float=0.0
var objects: Array=[]
var reduce_motion: bool=false

func setup(id: String,gentle: bool) -> void:
	course=id
	reduce_motion=gentle
	queue_redraw()

func lane_y(lane: int) -> float:
	return size.y*(.22+.28*float(clampi(lane,0,2)))

func player_x() -> float:
	return size.x*.27

func item_x(world_distance: float) -> float:
	return player_x()+(world_distance-flight_distance)*1.55

func _oval(pos: Vector2,rx: float,ry: float,color: Color) -> void:
	var vertices=PackedVector2Array()
	for n in range(32):
		var a=TAU*float(n)/32.0
		vertices.append(pos+Vector2(cos(a)*rx,sin(a)*ry))
	draw_colored_polygon(vertices,color)

func _cloud(pos: Vector2,k: float,col: Color) -> void:
	_oval(pos+Vector2(0,8)*k,41*k,17*k,col)
	_oval(pos+Vector2(-23,-2)*k,24*k,24*k,col)
	_oval(pos+Vector2(10,-15)*k,28*k,27*k,col)
	_oval(pos+Vector2(36,1)*k,23*k,20*k,col)

func _star(p: Vector2,r: float,col: Color) -> void:
	var polygon=PackedVector2Array()
	for i in range(10):
		var a=-PI/2.0+float(i)*PI/5.0
		var distance=r if i%2==0 else r*.45
		polygon.append(p+Vector2(cos(a)*distance,sin(a)*distance))
	draw_colored_polygon(polygon,col)

func _draw() -> void:
	if size.x<=1.0 or size.y<=1.0:
		return
	var lake=course=="lake"
	var sky=Color("#A9D7E8") if lake else Color("#B4DACE")
	var horizon=Color("#D8EFE5") if lake else Color("#CDE6BD")
	draw_rect(Rect2(Vector2.ZERO,size),sky)
	for n in range(16):
		var y=float(n)*size.y/15.0
		draw_line(Vector2(0,y),Vector2(size.x,y),
			sky.lerp(horizon,.10+float(n)/35.0),maxf(2.0,size.y/15.0)+1.0,true)
	draw_circle(Vector2(size.x*.80,size.y*.17),size.y*.065,Color("#FFF3C5"))
	# Parallax mountain canopy, low enough to keep flight paths readable.
	for n in range(13):
		var x=fposmod(float(n)*139.0-scroll*.24,size.x+260.0)-130.0
		if lake:
			_oval(Vector2(x,size.y*.99),115,70,Color("#97C6B3"))
			_oval(Vector2(x+37,size.y*1.02),106,56,Color("#83B6AE"))
			draw_line(Vector2(x-40,size.y*.90),Vector2(x-45,size.y*.77),Color("#689E8F"),5,true)
		else:
			draw_rect(Rect2(x-8,size.y*.77,16,size.y*.20),Color("#8E8469"))
			_oval(Vector2(x,size.y*.77),72,54,Color("#7FB99E"))
			_oval(Vector2(x-15,size.y*.74),52,38,Color("#A0CDB1",.82))
	for n in range(11):
		var x=fposmod(float(n)*180.0-scroll*.65,size.x+230.0)-120.0
		var y=size.y*(.09+float(n%5)*.16)
		_cloud(Vector2(x,y),.40+float(n%3)*.08,Color("#EEF9F4",.48))
	# Guidance lines remain subtle, not an artificial road.
	for lane in range(3):
		var y=lane_y(lane)
		for n in range(12):
			var x=fposmod(float(n)*101.0-scroll*1.5,size.x+110.0)-55.0
			draw_line(Vector2(x,y+40),Vector2(x+30,y+40),
				Color("#F7FFF7",.30),3,true)
	for obj in objects:
		if bool(obj.get("taken",false)):
			continue
		var x=item_x(float(obj.get("distance",0.0)))
		if x < -35.0 or x>size.x+40.0:
			continue
		var p=Vector2(x,lane_y(int(obj.get("lane",1))))
		match str(obj.get("type","star")):
			"star":
				_star(p,19,Color("#FFDC78"))
				draw_arc(p,22,0,TAU,24,Color("#FFFFFF",.62),2,true)
			"cloud":
				_cloud(p,.55,Color("#F8FAFF",.92))
				draw_arc(p,26,0,TAU,24,Color("#7FA7B8",.45),2,true)
			"wind":
				draw_arc(p,22,0,TAU,28,Color("#F5DD8B"),6,true)
				draw_arc(p,12,0,TAU,28,Color("#FFF8E1"),3,true)
	if flight_distance<80.0:
		_ribbon(player_x()+(42.0-flight_distance)*1.55)
	if flight_distance>1370.0:
		_ribbon(player_x()+(1480.0-flight_distance)*1.55)

func _ribbon(x: float) -> void:
	if x < -20 or x>size.x+20:
		return
	for i in range(3):
		for j in range(2):
			draw_rect(Rect2(x+float(j)*12,30+float(i)*30,12,30),
				Color("#FFF9E9") if (i+j)%2==0 else Color("#4C6475"))
