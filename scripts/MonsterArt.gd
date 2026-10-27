extends Control
## Twelve original vector monster silhouettes for the park, album and karts.
var info: Dictionary = {}
var monster_id: String = "monster_fire"
var tint: Color = Color("#F47B57")

func setup(data: Dictionary) -> void:
	info = data
	monster_id = str(data.get("id","monster_fire"))
	tint = Color(str(data.get("color","#F47B57")))
	queue_redraw()

func _oval(x: float,y: float,rx: float,ry: float,color: Color) -> void:
	var points=PackedVector2Array()
	for n in range(32):
		var angle=float(n)*TAU/32.0
		points.append(Vector2(x+cos(angle)*rx,y+sin(angle)*ry))
	draw_colored_polygon(points,color)

func _poly(points: Array,color: Color) -> void:
	var vertices=PackedVector2Array()
	for point in points:
		vertices.append(point)
	draw_colored_polygon(vertices,color)

func _eyes(count: int = 2, y: float = -13.0) -> void:
	var dark=Color("#334451")
	for n in range(count):
		var x=(float(n)-(float(count)-1.0)*.5)*(30.0 if count==3 else 52.0)
		_oval(x,y,12,15,Color.WHITE)
		_oval(x+2,y+2,6,9,dark)
		_oval(x+4,y-2,2.5,3,Color.WHITE)
	draw_arc(Vector2(0,21),17.0,.16,PI-.16,18,dark,3.5,true)
	_oval(-49,13,9,6,Color("#FC9BB0",.70))
	_oval(49,13,9,6,Color("#FC9BB0",.70))

func _draw() -> void:
	var factor=minf(size.x/230.0,size.y/230.0)
	if factor<=0.0:
		return
	draw_set_transform(Vector2(size.x*.5,size.y*.56),0.0,Vector2(factor,factor))
	var dark=tint.darkened(.20)
	var bright=tint.lightened(.24)
	var ink=Color("#334451")
	_oval(0,94,72,10,Color("#456A73",.15))
	match monster_id:
		"monster_fire":
			_poly([Vector2(-62,40),Vector2(-70,-33),Vector2(-31,-14),Vector2(-9,-105),Vector2(22,-63),Vector2(48,-94),Vector2(48,-27),Vector2(72,4),Vector2(58,63)],dark)
			_poly([Vector2(-49,33),Vector2(-48,-19),Vector2(-18,-4),Vector2(-2,-83),Vector2(21,-40),Vector2(39,-70),Vector2(37,-19),Vector2(62,24),Vector2(47,61)],tint)
			_oval(0,35,46,48,bright)
		"monster_water":
			_poly([Vector2(0,-111),Vector2(-65,-12),Vector2(-69,33),Vector2(-42,77),Vector2(0,88),Vector2(42,77),Vector2(69,33),Vector2(65,-12)],tint)
			_oval(-22,7,19,47,Color.WHITE*.15+Color("#8FEAFF")*.85)
			_oval(25,62,24,12,bright)
		"monster_sprout":
			_oval(0,21,69,66,tint)
			_oval(-31,-71,32,19,Color("#4FAD73"))
			_oval(29,-79,34,20,Color("#8EDE76"))
			draw_line(Vector2(0,-90),Vector2(0,-43),Color("#3C9669"),7,true)
			_oval(-34,72,23,15,dark)
			_oval(34,72,23,15,dark)
		"monster_bubble":
			for p in [Vector2(-44,-44),Vector2(51,-51),Vector2(-57,21),Vector2(58,26)]:
				_oval(p.x,p.y,30,29,Color("#C6E3FF",.89))
			_oval(0,16,60,59,tint)
			_oval(-32,-5,15,25,Color("#FFFFFF",.46))
			_oval(44,-85,16,16,Color("#D9F6FF",.75))
		"monster_stone":
			_poly([Vector2(-72,-60),Vector2(-48,-84),Vector2(47,-84),Vector2(75,-53),Vector2(70,61),Vector2(42,83),Vector2(-55,81),Vector2(-77,46)],dark)
			_poly([Vector2(-63,-54),Vector2(-41,-73),Vector2(44,-70),Vector2(62,-43),Vector2(61,58),Vector2(-51,63),Vector2(-63,39)],tint)
			draw_line(Vector2(-59,-17),Vector2(-32,-28),bright,6,true)
			_oval(34,53,13,9,bright)
		"monster_jelly":
			_oval(0,6,75,71,Color(tint.r,tint.g,tint.b,.70))
			_oval(0,22,69,61,tint)
			_oval(-38,-3,20,40,Color.WHITE*.14+bright*.86)
			_oval(-42,70,19,14,dark)
			_oval(42,70,19,14,dark)
			_oval(0,-78,28,13,bright)
		"monster_spark":
			_poly([Vector2(8,-113),Vector2(-49,-24),Vector2(-6,-24),Vector2(-46,68),Vector2(65,-43),Vector2(19,-42),Vector2(43,-100)],dark)
			_poly([Vector2(3,-98),Vector2(-36,-33),Vector2(9,-33),Vector2(-25,47),Vector2(47,-34),Vector2(9,-34),Vector2(28,-89)],tint)
			_oval(2,20,43,44,bright)
		"monster_cloud":
			for p in [Vector2(-56,14),Vector2(-40,-35),Vector2(0,-55),Vector2(41,-37),Vector2(62,15)]:
				_oval(p.x,p.y,37,41,tint)
			_oval(0,35,78,46,tint)
			for p in [Vector2(-55,-40),Vector2(3,-67),Vector2(45,-50)]:
				_oval(p.x,p.y,19,13,bright)
		"monster_star":
			var star=[]
			for n in range(10):
				var a=-PI/2.0+float(n)*PI/5.0
				var radius=87.0 if n%2==0 else 52.0
				star.append(Vector2(cos(a)*radius,sin(a)*radius))
			_poly(star,dark)
			_oval(0,12,57,57,tint)
			_oval(-8,-87,12,18,bright)
			_oval(55,50,10,10,bright)
		"monster_three_eyes":
			_oval(0,10,70,75,tint)
			_oval(-58,-59,18,37,dark)
			_oval(58,-59,18,37,dark)
			_oval(0,67,48,14,bright)
		"monster_wing":
			_oval(-71,-10,46,62,Color("#B5E5FF"))
			_oval(71,-10,46,62,Color("#D4E5FF"))
			_oval(-68,-30,22,31,bright)
			_oval(68,-30,22,31,bright)
			_oval(0,20,54,65,tint)
			_oval(-28,-75,21,40,tint)
			_oval(28,-75,21,40,tint)
		"monster_rainbow":
			for n in range(6):
				var p=Vector2(-65+float(n)*24,30+sin(float(n)*.8)*24)
				_oval(p.x,p.y,34,43,[
					Color("#EE829D"),Color("#F4B974"),Color("#F4E293"),
					Color("#9BDCAB"),Color("#9BCEF0"),Color("#B8A2ED")][n])
			_oval(-57,-21,53,55,tint)
			_oval(-73,-74,17,32,bright)
			_oval(-36,-79,17,32,bright)
		_:
			_oval(0,10,65,70,tint)
	if monster_id=="monster_three_eyes":
		_eyes(3,-19)
	elif monster_id=="monster_rainbow":
		draw_arc(Vector2(-57,20),18,.12,PI-.12,20,ink,3,true)
		for x in [-82.0,-34.0]:
			_oval(x,-30,12,15,Color.WHITE)
			_oval(x+2,-29,6,8,ink)
	else:
		_eyes(2,-12)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
