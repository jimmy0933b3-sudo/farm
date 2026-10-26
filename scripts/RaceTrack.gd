extends Control
## Original, fully drawn 2D cartoon track. Road geometry and hit targets share
## the same lane_center_at() math; curves never desync pickups or player.
var track_id: String = "farm"
var scroll: float = 0.0
var race_objects: Array = []
var race_distance: float = 0.0
var reduce_motion: bool = false
var boost_active: bool = false
var shield_active: bool = false
var speed_ratio: float = 1.0
var celebration: float = 0.0

const SCENES = {
	"farm":{"land":"#A7DF94","field":"#83CB78","road":"#D5A878",
		"border":"#FFF3D4","detail":"#6EB96C"},
	"flower":{"land":"#D3E8A3","field":"#A4D783","road":"#C9A7BD",
		"border":"#FFFFFF","detail":"#EFA5D4"},
	"rainbow":{"land":"#9FDCED","field":"#BCEAF2","road":"#B8B1DB",
		"border":"#FFF8ED","detail":"#8FC7ED"}
}

func setup(id: String, gentle: bool) -> void:
	track_id = id if SCENES.has(id) else "farm"
	reduce_motion = gentle
	queue_redraw()

func _curve(y: float) -> float:
	var h: float = maxf(size.y,1.0)
	var step: float = y / h
	var bend: float = sin((scroll * 0.0028) + (1.0-step)*2.0) * 24.0
	bend += sin(scroll*0.0013+(1.0-step)*5.3)*12.0
	return bend if not reduce_motion else bend*0.5

func _half_road(y: float) -> float:
	var fraction: float = clampf(y/maxf(size.y,1.0),0.0,1.0)
	return minf(size.x * 0.315,300.0)*(0.84+0.16*fraction)

func _road_center(y: float) -> float:
	return size.x*0.5+_curve(y)

func road_edges_at(y: float) -> Vector2:
	var cx: float = _road_center(y)
	var radius: float = _half_road(y)
	return Vector2(cx-radius,cx+radius)

func road_edges() -> Vector2:
	return road_edges_at(size.y*0.72)

func lane_center_at(lane: int, y: float) -> float:
	var edges: Vector2 = road_edges_at(y)
	return lerpf(edges.x,edges.y,(float(clampi(lane,0,2))+0.5)/3.0)

func lane_center(lane: int) -> float:
	return lane_center_at(lane,size.y*0.72)

func _quad(a: Vector2,b: Vector2,c: Vector2,d: Vector2,col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a,b,c,d]),col)

func _line(a: Vector2,b: Vector2,col: Color,width: float=3.0) -> void:
	draw_line(a,b,col,width,true)

func _draw() -> void:
	if size.x < 40.0 or size.y < 40.0:
		return
	var palette: Dictionary = SCENES[track_id]
	var ground: Color = Color(str(palette["land"]))
	var field: Color = Color(str(palette["field"]))
	var road: Color = Color(str(palette["road"]))
	var rim: Color = Color(str(palette["border"]))
	draw_rect(Rect2(Vector2.ZERO,size),ground)
	# Shaded crop fields, soft polka dots and decorative paths make the
	# worlds readable even on a small phone in landscape.
	for stripe in range(10):
		var yy: float = fposmod(float(stripe)*110.0+scroll*0.47, size.y+110.0)-55.0
		draw_rect(Rect2(0,yy,size.x,26),field.lightened(.06),false,20.0)
		for side in [-1,1]:
			var base_x: float = size.x*.17 if side==-1 else size.x*.83
			if track_id=="farm":
				for furrow in range(3):
					_line(Vector2(base_x+furrow*9.0-16.0,yy-15.0),
						Vector2(base_x+furrow*9.0-11.0,yy+65.0),
						field.darkened(.10),2.0)
	_draw_scenery()

	# Construct a continuous bent road from 18 quads; same interpolation is
	# used for lane lines, item hits, and the kart's position.
	var sections: int = 28
	var step_y: float = size.y/float(sections)
	for i in range(sections):
		var y0: float = float(i)*step_y
		var y1: float = float(i+1)*step_y+1.0
		var e0: Vector2 = road_edges_at(y0)
		var e1: Vector2 = road_edges_at(y1)
		_quad(Vector2(e0.x-15,y0),Vector2(e0.y+15,y0),
			Vector2(e1.y+15,y1),Vector2(e1.x-15,y1),rim)
		_quad(Vector2(e0.x,y0),Vector2(e0.y,y0),
			Vector2(e1.y,y1),Vector2(e1.x,y1),road)
		# Soft center shading gives the road depth without a 3D renderer.
		_quad(Vector2(e0.x+(e0.y-e0.x)*.35,y0),
			Vector2(e0.x+(e0.y-e0.x)*.65,y0),
			Vector2(e1.x+(e1.y-e1.x)*.65,y1),
			Vector2(e1.x+(e1.y-e1.x)*.35,y1),road.lightened(.055))
		for offset in [-8.0,-3.0,3.0,8.0]:
			var side0: float = e0.x if offset<0.0 else e0.y
			var side1: float = e1.x if offset<0.0 else e1.y
			var color: Color = Color("#F8F4DF") if int(absf(offset))==3 else Color("#EA916D")
			_line(Vector2(side0+offset,y0),Vector2(side1+offset,y1),color,3.4)
	# Moving lane markings follow the bends, including on top/bottom of screen.
	for divider in [1,2]:
		for n in range(-1,14):
			var y0: float = float(n)*70.0+fposmod(scroll*2.2,70.0)
			var y1: float = y0+31.0
			_line(Vector2(_lane_divider(divider,y0),y0),
				Vector2(_lane_divider(divider,y1),y1),Color("#FFFBE8"),4.5)

	# Special chequered start and finish ribbons.
	if race_distance < 140.0:
		_draw_checkered(size.y*.72+(40.0-race_distance)*1.4)
	if race_distance > 2130.0:
		_draw_checkered(size.y*.72+(2350.0-race_distance)*1.4)

	_draw_pickups()
	if boost_active and not reduce_motion:
		for side in [-1,1]:
			for i in range(9):
				var y: float = fposmod(scroll*3.0+float(i)*88.0,size.y)
				var x: float = size.x*.5+float(side)*(size.x*.34+float(i%3)*15)
				_line(Vector2(x,y),Vector2(x+float(side)*12.0,y+33),
					Color("#FFFFFF",.35),2.5)
	if celebration>0.0:
		for i in range(34):
			var x: float = fposmod(float(i*131+7),size.x)
			var y: float = fposmod(float(i*71)+scroll*.5,size.y)
			draw_rect(Rect2(x,y,8,13),[Color("#F46783"),Color("#FBD45F"),
				Color("#77CBB4"),Color("#AE91DB")][i%4])

func _lane_divider(divider: int,y: float) -> float:
	var edge: Vector2=road_edges_at(y)
	return lerpf(edge.x,edge.y,float(divider)/3.0)

func _draw_checkered(y: float) -> void:
	if y< -30.0 or y>size.y+30.0:
		return
	var edges: Vector2=road_edges_at(y)
	var cell_w: float=(edges.y-edges.x)/12.0
	for col in range(12):
		for row in range(2):
			draw_rect(Rect2(edges.x+float(col)*cell_w,y+float(row)*12,
				cell_w+1.0,13.0),Color.WHITE if (col+row)%2==0 else Color("#333D4E"))

func _draw_scenery() -> void:
	for i in range(-2,12):
		var y: float=float(i)*103.0+fposmod(scroll*.77,103.0)
		for side in [-1,1]:
			var width: float=size.x
			var outer: float=width*.13 if side==-1 else width*.87
			var scatter: float=sin(float(i)*3.81+float(side)*2.27)*16.0
			var pos=Vector2(outer+scatter,y)
			if track_id=="farm":
				if i%4==0:
					_draw_barn(pos,.82)
				elif i%3==0:
					_draw_hay(pos)
				else:
					_draw_tree(pos,.9)
			elif track_id=="flower":
				if i%4==0:
					_draw_mushroom(pos,1.15)
				elif i%3==0:
					_draw_leaf(pos)
				else:
					_draw_flower(pos,1.2)
			else:
				if i%3==0:
					_draw_balloon(pos,.95)
				elif i%3==1:
					_draw_cloud(pos)
				else:
					_draw_rainbow_flower(pos)

func _draw_tree(p: Vector2,factor: float=1.0) -> void:
	draw_circle(p+Vector2(4,13)*factor,30.0*factor,Color("#6A9650",.22))
	draw_rect(Rect2(p.x-7*factor,p.y+3*factor,14*factor,40*factor),Color("#A9744D"))
	for off in [Vector2(-18,-10),Vector2(16,-14),Vector2(0,-25)]:
		draw_circle(p+off*factor,23*factor,Color("#458D54"))
		draw_circle(p+off*factor+Vector2(-5,-7)*factor,16*factor,Color("#74C671"))
	for off in [Vector2(-10,-21),Vector2(19,-17),Vector2(0,-37)]:
		draw_circle(p+off*factor,5*factor,Color("#E9675D"))

func _draw_hay(p: Vector2) -> void:
	draw_circle(p+Vector2(0,4),26.0,Color("#A17641",.23))
	draw_rect(Rect2(p.x-26,p.y-15,53,29),Color("#E5B657"))
	_line(p+Vector2(-19,-13),p+Vector2(11,13),Color("#FAE3A0"),3)
	_line(p+Vector2(1,-13),p+Vector2(25,11),Color("#B48A42"),2)

func _draw_barn(p: Vector2,factor: float) -> void:
	_quad(p+Vector2(-32,-7)*factor,p+Vector2(32,-7)*factor,
		p+Vector2(32,31)*factor,p+Vector2(-32,31)*factor,Color("#D86D58"))
	draw_colored_polygon(PackedVector2Array([
		p+Vector2(-40,-8)*factor,p+Vector2(0,-35)*factor,
		p+Vector2(40,-8)*factor]),Color("#8F5B59"))
	draw_rect(Rect2(p.x-12*factor,p.y+3*factor,24*factor,28*factor),
		Color("#654B43"))
	_line(p+Vector2(-7,6)*factor,p+Vector2(7,25)*factor,Color("#F3CCA4"),3)

func _draw_flower(p: Vector2,factor: float) -> void:
	for n in range(6):
		var a: float=float(n)*TAU/6
		draw_circle(p+Vector2(cos(a),sin(a))*18*factor,13*factor,
			[Color("#F6A1C8"),Color("#F8B7E1"),Color("#E889C6")][n%3])
	draw_circle(p,11*factor,Color("#FDE586"))
	draw_circle(p+Vector2(-3,-3)*factor,3*factor,Color.WHITE)

func _draw_mushroom(p: Vector2,factor: float) -> void:
	draw_rect(Rect2(p.x-9*factor,p.y-2*factor,18*factor,31*factor),Color("#FFF7DE"))
	draw_circle(p+Vector2(0,-5)*factor,26*factor,Color("#D877A8"))
	draw_rect(Rect2(p.x-27*factor,p.y-5*factor,54*factor,26*factor),Color("#D3E8A3"))
	for d in [Vector2(-13,-14),Vector2(4,-21),Vector2(16,-10)]:
		draw_circle(p+d*factor,5*factor,Color("#FFF5EC"))

func _draw_leaf(p: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		p+Vector2(-26,11),p+Vector2(-7,-24),p+Vector2(27,-19),
		p+Vector2(21,17)]),Color("#65A97C"))
	_line(p+Vector2(-21,15),p+Vector2(20,-18),Color("#D1EBB6"),3)

func _draw_balloon(p: Vector2,factor: float) -> void:
	draw_line(p+Vector2(0,18)*factor,p+Vector2(4,58)*factor,Color("#FFFFFF"),2)
	draw_circle(p,23*factor,Color("#FC8EAE"))
	draw_circle(p+Vector2(-8,-10)*factor,5*factor,Color("#FFEBD9",.8))

func _draw_cloud(p: Vector2) -> void:
	for offset in [Vector2(-14,3),Vector2(11,0),Vector2(0,-12)]:
		draw_circle(p+offset,21,Color.WHITE)
	draw_rect(Rect2(p.x-26,p.y-1,54,14),Color.WHITE)

func _draw_rainbow_flower(p: Vector2) -> void:
	for n in range(6):
		var a: float=float(n)*TAU/6.0
		draw_circle(p+Vector2(cos(a),sin(a))*18,13,
			[Color("#FF8F9E"),Color("#FFD279"),Color("#89DCA7"),
			Color("#8BCAEC"),Color("#B79FDC"),Color("#FFB5DF")][n])
	draw_circle(p,10,Color("#FFF9DC"))

func _draw_pickups() -> void:
	for thing in race_objects:
		if bool(thing.get("hit",false)):
			continue
		var y: float=size.y*.72-(float(thing.get("distance",0))-race_distance)*1.4
		if y < -45.0 or y>size.y+45.0:
			continue
		var x: float=lane_center_at(int(thing.get("lane",1)),y)
		var center: Vector2=Vector2(x,y)
		var pulse: float=1.0+sin(scroll*.023+float(thing.get("distance",0)))*.06
		var kind: String=str(thing.get("type","star"))
		if kind=="star":
			draw_circle(center+Vector2(0,4),25*pulse,Color("#FFFBCA",.6))
			_draw_star(center,21*pulse,10*pulse,Color("#FFD449"))
		elif kind=="boost":
			draw_circle(center,25*pulse,Color("#FC7DAE"))
			draw_circle(center,20*pulse,Color("#FFF0BA"))
			draw_colored_polygon(PackedVector2Array([
				center+Vector2(2,-17),center+Vector2(-9,2),
				center+Vector2(-1,2),center+Vector2(-6,17),
				center+Vector2(13,-5),center+Vector2(3,-5)]),Color("#FA8C3C"))
		elif kind=="shield":
			draw_circle(center,25*pulse,Color("#8EE5FC",.64))
			draw_arc(center,22*pulse,0,TAU,32,Color("#FFFFFF"),3.5)
			_line(center+Vector2(-8,-7),center+Vector2(-1,7),Color("#FFFFFF"),3)
			_line(center+Vector2(-1,7),center+Vector2(12,-11),Color("#FFFFFF"),3)
		else:
			draw_rect(Rect2(x-23,y-17,46,34),Color("#A8763D"))
			draw_rect(Rect2(x-19,y-13,38,26),Color("#E8BD6B"))
			_line(center+Vector2(-18,-9),center+Vector2(19,10),Color("#FFF0B4"),3)
			_line(center+Vector2(12,-10),center+Vector2(-9,11),Color("#C18F52"),3)

func _draw_star(p: Vector2,outer: float,inner: float,color: Color) -> void:
	var star=PackedVector2Array()
	for i in range(10):
		var a: float=-PI*.5+float(i)*PI/5.0
		var radius: float=outer if i%2==0 else inner
		star.append(p+Vector2(cos(a),sin(a))*radius)
	draw_colored_polygon(star,color)
