extends Control
## Eight identifiable original Taiwanese bird vector portraits. No fetched assets.
var info: Dictionary={}
var species: String="bird_mandarin"
var tint: Color=Color("#EFA66D")
var wing_flap: float=0.0
# Gallery and exploration portraits face left; in-flight birds face the direction
# of travel. Mirror only the vector drawing, not its Control or UI children.
var facing_right: bool=false

func set_facing_right(value: bool) -> void:
	facing_right=value
	queue_redraw()

func horizontal_draw_scale() -> float:
	return -1.0 if facing_right else 1.0

func setup(bird: Dictionary) -> void:
	info=bird
	species=str(bird.get("id","bird_mandarin"))
	tint=Color(str(bird.get("color","#EFA66D")))
	queue_redraw()

func set_flap(value: float) -> void:
	wing_flap=value
	queue_redraw()

func _oval(x: float,y: float,rx: float,ry: float,col: Color) -> void:
	var p=PackedVector2Array()
	for i in range(32):
		var a=TAU*float(i)/32.0
		p.append(Vector2(x+cos(a)*rx,y+sin(a)*ry))
	draw_colored_polygon(p,col)

func _poly(points: Array,col: Color) -> void:
	var p=PackedVector2Array()
	for point in points:
		p.append(point)
	draw_colored_polygon(p,col)

func _line(a: Vector2,b: Vector2,col: Color,w: float=3.0) -> void:
	draw_line(a,b,col,w,true)

func _eye(x: float=-42.0,y: float=-42.0,col: Color=Color("#293C4A")) -> void:
	_oval(x,y,8,8,Color("#FFFDF6"))
	_oval(x-1,y,4,5,col)
	_oval(x-2,y-2,2,2,Color.WHITE)

func _draw() -> void:
	var k=minf(size.x/250.0,size.y/210.0)
	if k<=0.0:
		return
	draw_set_transform(Vector2(size.x*.5,size.y*.52),0.0,
		Vector2(k*horizontal_draw_scale(),k))
	var dark=tint.darkened(.25)
	var light=tint.lightened(.24)
	# Distinct wings, heads, feet and tails. Flight portraits are mirrored to face right.
	match species:
		"bird_mandarin":
			_oval(5,51,94,12,Color("#5C8592",.13))
			_oval(8,17,83,49,Color("#8B604A"))
			_oval(-21,11,60,32,Color("#EEE3CC"))
			_oval(-47,-45,34,35,Color("#277766"))
			_oval(-53,-54,27,16,Color("#529D79"))
			_poly([Vector2(-76,-39),Vector2(-109,-20),Vector2(-78,-16)],Color("#E96952"))
			_oval(-62,-36,12,11,Color("#FFF1B9"))
			_eye(-59,-43)
			_poly([Vector2(29,5),Vector2(42,-68),Vector2(78,1)],Color("#ED8E4F"))
			_poly([Vector2(36,8),Vector2(53,-52),Vector2(76,6)],Color("#FFD09C"))
			_poly([Vector2(52,32),Vector2(113,41),Vector2(86,55)],Color("#614D56"))
			_line(Vector2(-6,53),Vector2(-9,80),Color("#CF785A"),5)
			_line(Vector2(35,52),Vector2(31,77),Color("#CF785A"),5)
		"bird_teal":
			_oval(8,18,83,43,Color("#9B8468"))
			_oval(2,24,60,27,Color("#D9C4A3"))
			_oval(-48,-30,30,30,Color("#935C4D"))
			_oval(-53,-33,21,16,Color("#258D7D"))
			_line(Vector2(-75,-46),Vector2(-32,-39),Color("#E8DDB2"),5)
			_poly([Vector2(-73,-26),Vector2(-108,-15),Vector2(-80,-9)],Color("#414E58"))
			_eye(-58,-43)
			_oval(22,1,45,21,Color("#5D7C87"))
			_oval(41,-3,20,9,Color("#A5C6AA"))
			_poly([Vector2(70,13),Vector2(112,30),Vector2(69,38)],Color("#7F735F"))
			_line(Vector2(-7,54),Vector2(-12,79),Color("#DE995C"),4)
			_line(Vector2(29,53),Vector2(34,78),Color("#DE995C"),4)
		"bird_myna":
			_oval(2,14,76,47,Color("#36414D"))
			_poly([Vector2(49,11),Vector2(116,51),Vector2(73,57)],Color("#252F3D"))
			_oval(-48,-35,34,39,Color("#2A3440"))
			_poly([Vector2(-72,-56),Vector2(-67,-95),Vector2(-51,-62)],Color("#313B47"))
			_poly([Vector2(-78,-40),Vector2(-112,-28),Vector2(-78,-17)],Color("#EDB55B"))
			_oval(12,10,46,31,Color("#222C37"))
			_poly([Vector2(2,13),Vector2(44,25),Vector2(28,34),Vector2(-9,27)],Color.WHITE)
			_eye(-58,-47,Color("#E0B84E"))
			_line(Vector2(-7,54),Vector2(-9,85),Color("#EDB55B"),4)
			_line(Vector2(23,54),Vector2(26,85),Color("#EDB55B"),4)
		"bird_sparrow":
			_oval(8,17,78,46,Color("#9D785D"))
			_poly([Vector2(55,13),Vector2(115,47),Vector2(66,47)],Color("#826451"))
			_oval(-40,-28,36,38,Color("#A16D50"))
			_oval(-41,-12,26,24,Color("#F1DFC7"))
			_poly([Vector2(-65,-31),Vector2(-97,-18),Vector2(-65,-9)],Color("#54453F"))
			_poly([Vector2(-56,-3),Vector2(-27,-4),Vector2(-42,22)],Color("#4B4544"))
			_oval(14,14,43,26,Color("#795B51"))
			for j in range(4):
				_line(Vector2(-5+float(j)*15,5),Vector2(31+float(j)*10,33),Color("#CEAA83"),3)
			_eye(-49,-36)
			_line(Vector2(0,55),Vector2(-3,83),Color("#BA8662"),4)
			_line(Vector2(31,56),Vector2(35,84),Color("#BA8662"),4)
		"bird_jacana":
			_oval(7,13,70,30,Color("#A26340"))
			_oval(-43,-29,32,30,Color("#EAE7DB"))
			_oval(-51,-43,24,19,Color("#2E414C"))
			_poly([Vector2(-70,-40),Vector2(-117,-33),Vector2(-70,-27)],Color("#E0B650"))
			_oval(21,5,37,18,Color("#7F4A37"))
			_poly([Vector2(58,4),Vector2(111,37),Vector2(64,32)],Color("#644739"))
			_eye(-59,-43)
			_line(Vector2(-4,37),Vector2(-14,90),Color("#727C82"),4)
			_line(Vector2(21,39),Vector2(34,91),Color("#727C82"),4)
			for x in [-14.0,34.0]:
				for d in [-1.0,0.0,1.0]:
					_line(Vector2(x,90),Vector2(x+d*30,98+absf(d)*4),Color("#727C82"),2)
		"bird_barbet":
			_oval(9,10,77,51,Color("#4AAB6D"))
			_poly([Vector2(58,9),Vector2(114,44),Vector2(59,47)],Color("#3B8859"))
			_oval(-42,-34,36,37,Color("#347F8B"))
			_oval(-54,-52,23,17,Color("#3474B2"))
			_oval(-44,-16,20,15,Color("#EFDA65"))
			_oval(-48,1,15,15,Color("#D95A57"))
			_poly([Vector2(-75,-39),Vector2(-116,-20),Vector2(-73,-18)],Color("#454F57"))
			_oval(16,10,43,31,Color("#62BD74"))
			_line(Vector2(-5,55),Vector2(-8,86),Color("#647B68"),4)
			_line(Vector2(25,55),Vector2(28,85),Color("#647B68"),4)
			_eye(-60,-46)
		"bird_heron":
			_oval(7,6,76,45,Color("#90A0B0"))
			_poly([Vector2(53,-2),Vector2(119,31),Vector2(71,41)],Color("#66758A"))
			_oval(-42,-35,28,32,Color("#EDEAE6"))
			_oval(-46,-54,30,18,Color("#313D50"))
			_poly([Vector2(-72,-48),Vector2(-121,-37),Vector2(-71,-27)],Color("#333D49"))
			_oval(18,-2,44,28,Color("#647488"))
			_line(Vector2(7,47),Vector2(-10,100),Color("#CEB166"),4)
			_line(Vector2(38,49),Vector2(45,103),Color("#CEB166"),4)
			_line(Vector2(-10,100),Vector2(-32,103),Color("#CEB166"),3)
			_line(Vector2(45,103),Vector2(67,103),Color("#CEB166"),3)
			_eye(-55,-54,Color("#D54346"))
		"bird_swallow":
			_poly([Vector2(13,11),Vector2(126,-15),Vector2(80,30),Vector2(115,85),Vector2(30,44)],Color("#284F73"))
			_poly([Vector2(45,34),Vector2(125,92),Vector2(62,49),Vector2(85,108),Vector2(25,44)],Color("#2C526F"))
			_oval(-9,8,75,36,Color("#325A7D"))
			_oval(-37,12,45,25,Color("#F2EEE9"))
			_oval(-51,-18,29,29,Color("#294B70"))
			_oval(-56,-31,24,11,Color("#C97C5D"))
			_poly([Vector2(-76,-22),Vector2(-117,-12),Vector2(-78,-5)],Color("#313E49"))
			_eye(-60,-23)
			# Suspended feet and swept-back feathered wings.
			_line(Vector2(-17,36),Vector2(-12,51),Color("#8A675B"),3)
			_line(Vector2(1,35),Vector2(11,49),Color("#8A675B"),3)
		_:
			_oval(0,0,70,45,tint)
	# Wings move subtly during flight without replacing species-specific colors.
	if absf(wing_flap)>0.01:
		var lift=clampf(wing_flap,-1.0,1.0)*24.0
		_poly([Vector2(-9,0),Vector2(32,-49-lift),Vector2(69,-17-lift),Vector2(30,25)],tint.darkened(.10))
		_line(Vector2(17,-9),Vector2(42,-24-lift),light,3)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
