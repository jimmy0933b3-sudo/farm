extends Control
## Original runtime-drawn animals, no unlicensed artwork or remote assets.

var animal_id: String = "cow"
var tint: Color = Color("#F1F0E8")
var mood: String = "idle"

func setup(info: Dictionary) -> void:
	animal_id = str(info.get("id", "cow"))
	tint = Color(str(info.get("color", "#F1F0E8")))
	queue_redraw()

func _oval(x: float, y: float, rx: float, ry: float, color: Color) -> void:
	var polygon = PackedVector2Array()
	for n in range(32):
		var angle = float(n) * TAU / 32.0
		polygon.append(Vector2(x + cos(angle) * rx, y + sin(angle) * ry))
	draw_colored_polygon(polygon, color)

func _poly(points: Array, color: Color) -> void:
	var packed = PackedVector2Array()
	for p in points:
		packed.append(p)
	draw_colored_polygon(packed, color)

func _draw() -> void:
	var scale_value = minf(size.x / 220.0, size.y / 220.0)
	if scale_value <= 0.0:
		return
	draw_set_transform(Vector2(size.x * 0.5, size.y * 0.52), 0.0, Vector2(scale_value, scale_value))
	var dark = tint.darkened(0.24)
	var cheek = Color("#F5AAB2")
	var ink = Color("#323746")
	_oval(0, 75, 72, 12, Color(0.27, 0.34, 0.29, 0.14))
	# Body and feet.
	_oval(-39, 67, 20, 27, dark)
	_oval(39, 67, 20, 27, dark)
	_oval(0, 24, 79, 76, tint)
	if animal_id in ["fox", "squirrel"]:
		_oval(73, 22, 31, 57, dark)
		_oval(78, 11, 25, 42, tint.lightened(0.18))
	# Distinctive silhouettes.
	match animal_id:
		"rabbit":
			_oval(-34, -98, 21, 63, tint)
			_oval(34, -98, 21, 63, tint)
			_oval(-34, -103, 9, 46, cheek)
			_oval(34, -103, 9, 46, cheek)
		"cow", "horse", "deer":
			_poly([Vector2(-66, -50),Vector2(-84, -99),Vector2(-26, -64)], dark)
			_poly([Vector2(66, -50),Vector2(84, -99),Vector2(26, -64)], dark)
		"fox", "squirrel":
			_poly([Vector2(-67,-45),Vector2(-67,-111),Vector2(-19,-73)],dark)
			_poly([Vector2(67,-45),Vector2(67,-111),Vector2(19,-73)],dark)
		"raccoon", "boar", "hedgehog", "monkey":
			_oval(-63,-63,27,30,dark)
			_oval(63,-63,27,30,dark)
		"chicken", "duck", "owl":
			_oval(-68, 7, 28, 45, tint.darkened(0.12))
			_oval(68, 7, 28, 45, tint.darkened(0.12))
		_:
			_oval(-61, -62, 23, 26, dark)
			_oval(61, -62, 23, 26, dark)
	# Head.
	_oval(0, -31, 70, 70, tint)
	if animal_id == "hedgehog":
		for i in range(11):
			var x=-69.0+float(i)*14.0
			_poly([Vector2(x-9,-64),Vector2(x,-125-12*float(i%2)),Vector2(x+13,-75)],dark)
	if animal_id == "raccoon":
		_oval(-29,-42,29,27,Color("#54585A"))
		_oval(29,-42,29,27,Color("#54585A"))
		for i in range(3):
			_oval(90,12+float(i)*19.0,15,8,Color("#54585A"))
	if animal_id == "monkey":
		_oval(-72,-35,29,30,tint.darkened(0.08))
		_oval(72,-35,29,30,tint.darkened(0.08))
		_oval(-72,-35,15,17,Color("#E9B99D"))
		_oval(72,-35,15,17,Color("#E9B99D"))
		_oval(0,-11,50,48,Color("#E8BC94"))
	if animal_id == "sheep":
		for cx in [-55.0, -28.0, 0.0, 28.0, 55.0]:
			_oval(cx, -90, 27, 25, Color("#FFFDF4"))
	if animal_id == "chicken":
		for cx in [-22.0, 0.0, 22.0]:
			_oval(cx, -97, 16, 22, Color("#E65658"))
	if animal_id == "deer":
		draw_line(Vector2(-32,-78),Vector2(-47,-125),dark,6.0)
		draw_line(Vector2(32,-78),Vector2(47,-125),dark,6.0)
		draw_line(Vector2(-40,-105),Vector2(-66,-116),dark,5.0)
		draw_line(Vector2(40,-105),Vector2(66,-116),dark,5.0)
	if animal_id == "cow":
		_oval(-44,-58,21,17,Color("#797B82"))
		_oval(47,-9,19,21,Color("#797B82"))
	if animal_id == "owl":
		_oval(-27,-39,31,38,Color("#FFF4D0"))
		_oval(27,-39,31,38,Color("#FFF4D0"))
	# Expressive eyes and cheeks for petting, eating, washing, playing and sleeping.
	if mood == "sleep":
		draw_arc(Vector2(-25,-37),13.0,0.15,PI-0.15,14,ink,3.5)
		draw_arc(Vector2(25,-37),13.0,0.15,PI-0.15,14,ink,3.5)
	elif mood in ["happy","clean","play"]:
		draw_arc(Vector2(-25,-36),12.0,PI+0.13,TAU-0.13,14,ink,4.0)
		draw_arc(Vector2(25,-36),12.0,PI+0.13,TAU-0.13,14,ink,4.0)
	else:
		_oval(-25,-38,8,11,ink)
		_oval(25,-38,8,11,ink)
		_oval(-27,-42,3,4,Color.WHITE)
		_oval(23,-42,3,4,Color.WHITE)
	var blush_size = 19.0 if mood in ["happy","clean","play"] else 13.0
	_oval(-43,-9,blush_size,9,cheek)
	_oval(43,-9,blush_size,9,cheek)
	if animal_id in ["duck", "chicken", "owl"]:
		_poly([Vector2(-16,-19),Vector2(16,-19),Vector2(0,5)],Color("#F6A83C"))
	elif animal_id in ["cow","pig","horse"]:
		_oval(0,-5,35,24, Color("#F5B4BC") if animal_id != "horse" else Color("#DEB48C"))
		_oval(-12,-4,4,6,dark)
		_oval(12,-4,4,6,dark)
	else:
		_oval(0,-14,9,7,Color("#705C54"))
		if mood in ["happy","clean","play","eating"]:
			draw_arc(Vector2(0,-6),18.0,0.15,PI-0.15,16,ink,3.0)
		elif mood == "sleep":
			draw_line(Vector2(-8,-1),Vector2(8,-1),ink,3.0)
		else:
			draw_line(Vector2(-9,-3),Vector2(0,3),ink,2.0)
			draw_line(Vector2(0,3),Vector2(9,-3),ink,2.0)
	if animal_id == "boar":
		_oval(0,-4,32,28,Color("#BD8A68"))
		_poly([Vector2(-28,11),Vector2(-43,1),Vector2(-34,26)],Color("#FFF6DA"))
		_poly([Vector2(28,11),Vector2(43,1),Vector2(34,26)],Color("#FFF6DA"))
	if animal_id == "pig":
		_oval(-66,-67,22,27,tint)
		_oval(66,-67,22,27,tint)
	if mood in ["happy","play","clean"]:
		_oval(69,-110,9,10,Color("#F57892"))
		_oval(83,-115,9,10,Color("#F57892"))
		_poly([Vector2(60,-111),Vector2(92,-111),Vector2(76,-92)],Color("#F57892"))
	if mood == "eating":
		_oval(-13,25,4,6,Color("#DDB46B"))
		_oval(16,31,5,5,Color("#DDB46B"))
	if mood in ["happy","eating","clean","play"] and animal_id in ["cow","pig","horse","duck","chicken","owl"]:
		draw_arc(Vector2(0,24),18.0,0.15,PI-0.15,16,ink,3.0)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
