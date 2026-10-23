extends Control
## Original runtime-drawn animals, no unlicensed artwork or remote assets.

var animal_id: String = "cow"
var tint: Color = Color("#F1F0E8")
var mood: String = "idle"
# The coloring room uses this very same original artist, in monochrome mode.
var coloring_mode: bool = false
var coloring_colors: Dictionary = {}
# Finger-made brush points are painted INSIDE the original vector silhouette.
# Each stroke keeps its region/color and a series of local-space dots.
const BRUSH_RADIUS: float = 17.0
var coloring_strokes: Dictionary = {}
var color_shapes: Array = []
const COLOR_INK = Color("#27323B")

func _colorable(points: PackedVector2Array, original: Color, fillable: bool) -> void:
	if not coloring_mode:
		draw_colored_polygon(points,original)
		return
	if original.a < 0.45:
		# Transparent ground shadows are not an animal paint region.
		return
	if not fillable:
		# Highlights and pupils stay ink/white instead of creating dead masks.
		draw_colored_polygon(points,COLOR_INK if original.get_luminance()<0.42 else Color.WHITE)
		return
	var id="piece_%d" % color_shapes.size()
	_register_region(id,points)
	var code=str(coloring_colors.get(id,"#FFFFFF"))
	draw_colored_polygon(points,Color(code) if Color.html_is_valid(code) else Color.WHITE)
	_paint_saved_strokes(id,points)
	_stroke_outline(points)

func _register_region(id: String, polygon: PackedVector2Array) -> void:
	color_shapes.append({"id":id,"points":polygon.duplicate()})

func _stroke_outline(polygon: PackedVector2Array) -> void:
	var border=polygon.duplicate()
	border.append(polygon[0])
	draw_polyline(border,COLOR_INK,2.6,true)

func _paint_saved_strokes(id: String, polygon: PackedVector2Array) -> void:
	for stroke in coloring_strokes.get(id,[]):
		var code=str(stroke.get("color","#FFFFFF"))
		if not Color.html_is_valid(code):
			continue
		var pigment=Color(code)
		for dot in stroke.get("dots",[]):
			if not dot is Array or dot.size()!=2:
				continue
			var circle=_circle_polygon(float(dot[0]),float(dot[1]),BRUSH_RADIUS,BRUSH_RADIUS)
			for inside in Geometry2D.intersect_polygons(polygon,circle):
				if inside.size()>=3:
					draw_colored_polygon(inside,pigment)

func _accent_oval(x: float,y: float,rx: float,ry: float,color: Color) -> void:
	# Face details are intentionally ink, not an invisible overlaid paint target.
	var polygon=_circle_polygon(x,y,rx,ry)
	draw_colored_polygon(polygon,COLOR_INK if coloring_mode and color.get_luminance()<0.5 else color)

func _colorable_line(a: Vector2,b: Vector2,width: float,color: Color) -> void:
	if not coloring_mode:
		draw_line(a,b,color,width,true)
		return
	# Antlers and similar thin parts need a toddler-sized selectable target.
	var tangent=(b-a).normalized()
	var normal=Vector2(-tangent.y,tangent.x)*maxf(7.0,width*0.6)
	var polygon=PackedVector2Array([a+normal,b+normal,b-normal,a-normal])
	var id="line_%d" % color_shapes.size()
	_register_region(id,polygon)
	draw_colored_polygon(polygon,Color.WHITE)
	_paint_saved_strokes(id,polygon)
	_stroke_outline(polygon)

func get_coloring_regions() -> Array:
	return color_shapes.duplicate(true)

func color_region_at(local_pos: Vector2) -> String:
	var scale_value=minf(size.x/220.0,size.y/220.0)
	if scale_value<=0.0:
		return ""
	var p=(local_pos-Vector2(size.x*0.5,size.y*0.52))/scale_value
	for i in range(color_shapes.size()-1,-1,-1):
		if Geometry2D.is_point_in_polygon(p,color_shapes[i]["points"]):
			return str(color_shapes[i]["id"])
	return ""

func coloring_world_point(local_pos: Vector2) -> Vector2:
	var scale_value=minf(size.x/220.0,size.y/220.0)
	if scale_value<=0.0:
		return Vector2(100000.0,100000.0)
	return (local_pos-Vector2(size.x*0.5,size.y*0.52))/scale_value

func set_coloring(enabled: bool, page: Dictionary={}) -> void:
	coloring_mode=enabled
	coloring_colors=page.duplicate(true)
	coloring_strokes.clear()
	var saved=page.get("strokes_v2",[])
	if saved is Array:
		for stroke in saved:
			if not stroke is Dictionary:
				continue
			var region=str(stroke.get("region",""))
			if region.is_empty():
				continue
			if not coloring_strokes.has(region):
				coloring_strokes[region]=[]
			coloring_strokes[region].append(stroke)
	queue_redraw()


func setup(info: Dictionary) -> void:
	animal_id = str(info.get("id", "cow"))
	tint = Color(str(info.get("color", "#F1F0E8")))
	queue_redraw()

func _oval(x: float, y: float, rx: float, ry: float, color: Color) -> void:
	var polygon = PackedVector2Array()
	for n in range(32):
		var angle = float(n) * TAU / 32.0
		polygon.append(Vector2(x + cos(angle) * rx, y + sin(angle) * ry))
	_colorable(polygon,color,rx>=7.0 and ry>=7.0 and color.a>=0.45)

func _poly(points: Array, color: Color) -> void:
	var packed = PackedVector2Array()
	for p in points:
		packed.append(p)
	_colorable(packed,color,true)

func _draw() -> void:
	color_shapes.clear()
	var scale_value = minf(size.x / 220.0, size.y / 220.0)
	if scale_value <= 0.0:
		return
	draw_set_transform(Vector2(size.x * 0.5, size.y * 0.52), 0.0, Vector2(scale_value, scale_value))
	if animal_id in ["clownfish","sea_turtle","dolphin","octopus","seahorse","pufferfish","seal"]:
		_draw_ocean_animal()
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		return
	if animal_id in ["camel","lion","tiger","elephant","hippo"]:
		_draw_zoo_animal()
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		return
	if animal_id == "snake":
		_draw_snake()
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
		return
	var dark = COLOR_INK if coloring_mode else tint.darkened(0.24)
	var cheek = Color.WHITE if coloring_mode else Color("#F5AAB2")
	var ink = Color("#323746")
	_oval(0, 75, 72, 12, Color(0.27, 0.34, 0.29, 0.14))
	# Body and feet.
	_oval(-39, 67, 20, 27, dark)
	_oval(39, 67, 20, 27, dark)
	_oval(0, 24, 79, 76, tint)
	if animal_id in ["fox", "squirrel", "meerkat"]:
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
		"raccoon", "boar", "hedgehog", "monkey", "meerkat":
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
	if animal_id == "meerkat":
		# Slim upright meerkat with mask, raised lookout stance and long tail.
		_oval(0,35,40,67,tint.lightened(0.15))
		_oval(-32,-43,22,25,Color("#59473F"))
		_oval(32,-43,22,25,Color("#59473F"))
		_oval(-74,-40,20,25,tint.darkened(0.12))
		_oval(74,-40,20,25,tint.darkened(0.12))
		_oval(0,-8,34,24,Color("#F2D6B2"))
	if animal_id == "guinea_pig":
		_oval(-60,-59,25,28,Color("#E7B99F"))
		_oval(60,-59,25,28,Color("#E7B99F"))
		_oval(-60,-59,15,17,Color("#EECBC9"))
		_oval(60,-59,15,17,Color("#EECBC9"))
		_oval(-48,4,27,35,Color("#FFF2D9"))
		_oval(33,-43,28,24,Color("#C67D53"))
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
		_colorable_line(Vector2(-32,-78),Vector2(-47,-125),6.0,dark)
		_colorable_line(Vector2(32,-78),Vector2(47,-125),6.0,dark)
		_colorable_line(Vector2(-40,-105),Vector2(-66,-116),5.0,dark)
		_colorable_line(Vector2(40,-105),Vector2(66,-116),5.0,dark)
	if animal_id == "cow":
		_oval(-44,-58,21,17,Color("#797B82"))
		_oval(47,-9,19,21,Color("#797B82"))
	if animal_id == "owl":
		_oval(-27,-39,31,38,Color("#FFF4D0"))
		_oval(27,-39,31,38,Color("#FFF4D0"))
	# Expressive eyes and cheeks for petting, eating, washing, playing and sleeping.
	if mood == "sleep" or mood == "blink":
		draw_arc(Vector2(-25,-37),13.0,0.15,PI-0.15,14,ink,3.5)
		draw_arc(Vector2(25,-37),13.0,0.15,PI-0.15,14,ink,3.5)
	elif mood in ["happy","clean","play","surprised"]:
		draw_arc(Vector2(-25,-36),12.0,PI+0.13,TAU-0.13,14,ink,4.0)
		draw_arc(Vector2(25,-36),12.0,PI+0.13,TAU-0.13,14,ink,4.0)
	else:
		_accent_oval(-25,-38,8,11,ink)
		_accent_oval(25,-38,8,11,ink)
		_accent_oval(-27,-42,3,4,Color.WHITE)
		_accent_oval(23,-42,3,4,Color.WHITE)
	var blush_size = 21.0 if mood in ["happy","clean","play","surprised"] else 12.0
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
	if mood in ["happy","play","clean","surprised"]:
		_oval(69,-110,9,10,Color("#F57892"))
		_oval(83,-115,9,10,Color("#F57892"))
		_poly([Vector2(60,-111),Vector2(92,-111),Vector2(76,-92)],Color("#F57892"))
	if mood == "eating":
		_oval(-13,25,4,6,Color("#DDB46B"))
		_oval(16,31,5,5,Color("#DDB46B"))
	if mood in ["happy","eating","clean","play","surprised"] and animal_id in ["cow","pig","horse","duck","chicken","owl"]:
		draw_arc(Vector2(0,24),18.0,0.15,PI-0.15,16,ink,3.0)
	if mood == "surprised":
		# Wow! Big eyes, a happy little open mouth and rosy cheeks.
		_oval(0,9,13,14,Color("#BD647B"))
		_oval(-49,-11,11,7,Color("#F99BB1"))
		_oval(49,-11,11,7,Color("#F99BB1"))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw_snake() -> void:
	# Curled limbless body, tongue, and raised head distinguish the snake.
	var dark=COLOR_INK if coloring_mode else tint.darkened(0.24)
	var ink=Color("#355448")
	_oval(0,78,88,11,Color(0.24,0.40,0.29,0.16))
	draw_arc(Vector2(-13,45),61.0,0.1,TAU*0.93,50,dark,49.0,true)
	draw_arc(Vector2(-13,45),59.0,0.1,TAU*0.93,50,Color(str(coloring_colors.get("snake_coils","#FFFFFF"))) if coloring_mode else tint,39.0,true)
	if coloring_mode:
		# The old 84px solid-circle hitbox included EMPTY space within the coil.
		# Register and paint the actual annular band in small arc segments.
		for i in range(32):
			var a0=0.1+(TAU*0.93-0.1)*float(i)/32.0
			var a1=0.1+(TAU*0.93-0.1)*float(i+1)/32.0
			var section=PackedVector2Array([
				Vector2(-13+cos(a0)*77,45+sin(a0)*77),
				Vector2(-13+cos(a1)*77,45+sin(a1)*77),
				Vector2(-13+cos(a1)*40,45+sin(a1)*40),
				Vector2(-13+cos(a0)*40,45+sin(a0)*40)
			])
			_register_region("snake_coils",section)
			_paint_saved_strokes("snake_coils",section)
	_oval(-25,45,28,28,Color("#E8DBA5"))
	draw_line(Vector2(40,42),Vector2(43,-49),dark,48.0,true)
	draw_line(Vector2(40,42),Vector2(43,-49),Color(str(coloring_colors.get("snake_neck","#FFFFFF"))) if coloring_mode else tint,37.0,true)
	if coloring_mode:
		var neck=PackedVector2Array([Vector2(23,44),Vector2(60,44),Vector2(60,-49),Vector2(23,-49)])
		_register_region("snake_neck",neck)
		_paint_saved_strokes("snake_neck",neck)
	_oval(42,-67,61,42,tint)
	_oval(42,-48,46,24,Color("#E7DAA2"))
	if mood in ["happy","play","clean"]:
		draw_arc(Vector2(15,-79),9,PI+0.1,TAU-0.1,12,ink,3.0,true)
		draw_arc(Vector2(68,-79),9,PI+0.1,TAU-0.1,12,ink,3.0,true)
	elif mood == "sleep":
		draw_line(Vector2(9,-79),Vector2(23,-79),ink,3.0,true)
		draw_line(Vector2(62,-79),Vector2(76,-79),ink,3.0,true)
	else:
		_oval(15,-79,7,9,ink)
		_oval(68,-79,7,9,ink)
	_oval(40,-53,4,4,ink)
	if mood in ["happy","play","surprised"]:
		_oval(4,-50,10,7,Color("#F69CB2"))
		_oval(82,-47,10,7,Color("#F69CB2"))
	if mood!="sleep":
		draw_line(Vector2(42,-45),Vector2(42,-23),COLOR_INK if coloring_mode else Color("#E78795"),3.0,true)
		draw_line(Vector2(42,-23),Vector2(32,-17),COLOR_INK if coloring_mode else Color("#E78795"),2.0,true)
		draw_line(Vector2(42,-23),Vector2(52,-17),COLOR_INK if coloring_mode else Color("#E78795"),2.0,true)

func _circle_polygon(x: float,y: float,rx: float,ry: float) -> PackedVector2Array:
	var pts=PackedVector2Array()
	for i in range(44):
		var a=TAU*float(i)/44.0
		pts.append(Vector2(x+cos(a)*rx,y+sin(a)*ry))
	return pts


func _draw_ocean_animal() -> void:
	# Original vector sea creatures share their geometry with the coloring room.
	# Every large piece uses _oval / _poly so touch-paint works on the very same shape.
	var dark=COLOR_INK if coloring_mode else tint.darkened(0.22)
	var belly=Color.WHITE if coloring_mode else tint.lightened(0.36)
	match animal_id:
		"clownfish":
			_poly([Vector2(-60,5),Vector2(-113,-47),Vector2(-111,56)],dark)
			_oval(0,10,91,53,tint)
			_poly([Vector2(-27,-28),Vector2(-8,-69),Vector2(19,-37)],dark)
			_poly([Vector2(-31,46),Vector2(-8,78),Vector2(19,50)],dark)
			_poly([Vector2(-14,15),Vector2(-43,64),Vector2(24,48)],tint.lightened(0.12))
			_oval(-34,10,12,51,belly)
			_oval(20,10,13,50,belly)
			_oval(68,-6,7,9,COLOR_INK)
			draw_arc(Vector2(69,27),14,0.15,PI-0.15,16,COLOR_INK,3,true)
		"pufferfish":
			for i in range(12):
				var a=TAU*float(i)/12.0
				var base=Vector2(cos(a)*74,sin(a)*69)
				_poly([base+Vector2(-10,-8),base+Vector2(cos(a)*28,sin(a)*28),base+Vector2(10,8)],dark)
			_oval(0,10,80,78,tint)
			_oval(0,48,54,36,belly)
			_oval(-29,-21,9,11,COLOR_INK)
			_oval(29,-21,9,11,COLOR_INK)
			_oval(0,5,10,9,belly)
			draw_arc(Vector2(0,11),14,0.1,PI-0.1,14,COLOR_INK,3,true)
		"sea_turtle":
			_oval(-65,55,30,42,tint)
			_oval(68,55,30,42,tint)
			_oval(-59,-44,32,26,tint)
			_oval(67,-45,32,26,tint)
			_poly([Vector2(-89,12),Vector2(-115,-21),Vector2(-106,42)],tint)
			_oval(0,12,83,77,dark)
			_oval(0,6,72,66,Color("#A7C984") if not coloring_mode else Color.WHITE)
			for i in range(6):
				var a=TAU*float(i)/6.0
				_oval(cos(a)*43,6+sin(a)*37,18,18,dark)
			_oval(92,-14,36,37,tint)
			_oval(102,-24,6,7,COLOR_INK)
			draw_arc(Vector2(99,-4),12,0.1,PI-0.15,12,COLOR_INK,2.6,true)
		"dolphin":
			_poly([Vector2(-90,23),Vector2(-136,-17),Vector2(-118,60)],dark)
			_poly([Vector2(-6,-25),Vector2(-24,-86),Vector2(40,-44)],dark)
			_poly([Vector2(1,46),Vector2(-35,91),Vector2(58,42)],dark)
			_oval(0,0,102,47,tint)
			_oval(18,23,69,23,belly)
			_poly([Vector2(70,-14),Vector2(131,-4),Vector2(92,21)],tint)
			_oval(64,-25,10,9,COLOR_INK)
			draw_arc(Vector2(82,14),14,0,PI,12,COLOR_INK,2.8,true)
		"octopus":
			for i in range(8):
				var x=-91+float(i)*26.0
				_oval(x,73+float(i%3)*7,20,38,tint)
				_oval(x,90,10,11,dark)
			_oval(0,-9,76,84,tint)
			_oval(-27,-28,12,16,Color.WHITE)
			_oval(29,-28,12,16,Color.WHITE)
			_oval(-27,-29,6,9,COLOR_INK)
			_oval(29,-29,6,9,COLOR_INK)
			draw_arc(Vector2(0,13),20,0.12,PI-0.12,17,COLOR_INK,3.2,true)
		"seal":
			# Streamlined seal, distinct rounded flippers and pale muzzle.
			_oval(-89,48,27,34,dark)
			_oval(83,49,27,34,dark)
			_poly([Vector2(-76,12),Vector2(-119,-27),Vector2(-97,59)],dark)
			_oval(0,15,94,65,tint)
			_oval(13,35,73,41,belly)
			_oval(65,-31,49,49,tint)
			_oval(88,-23,30,26,belly)
			_oval(59,-45,8,10,COLOR_INK)
			_oval(63,-48,2.5,3.2,Color.WHITE)
			_oval(102,-17,8,6,COLOR_INK)
			draw_arc(Vector2(91,0),12,0.2,PI-0.2,14,COLOR_INK,2.6,true)
		"seahorse":
			_poly([Vector2(14,48),Vector2(-56,77),Vector2(-41,26)],dark)
			_oval(-8,32,38,73,tint)
			_oval(0,-38,45,54,tint)
			_poly([Vector2(31,-46),Vector2(88,-26),Vector2(31,-16)],tint)
			for i in range(5):
				var yy=-73+float(i)*29
				_poly([Vector2(-40,yy),Vector2(-70,yy+13),Vector2(-38,yy+23)],dark)
			_oval(6,-51,7,10,COLOR_INK)
			_oval(-3,104,33,23,tint)
			_oval(11,103,16,10,belly)
	# All sea creatures respond visually to petting and care as land animals do.
	if mood in ["happy","play","clean","surprised"]:
		_oval(-89,-102,9,11,Color("#F793B4"))
		_oval(-75,-109,9,11,Color("#F793B4"))
		_poly([Vector2(-98,-105),Vector2(-66,-105),Vector2(-82,-87)],Color("#F793B4"))
		_oval(85,-79,8,9,Color("#F7B5BA"))
	elif mood=="sleep":
		draw_arc(Vector2(65,-21),12,0.15,PI-0.15,16,COLOR_INK,2.5,true)
	elif mood=="eating":
		_oval(90,-20,8,9,Color("#FFF1A9"))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)


func _draw_zoo_animal() -> void:
	# Five new zoo species use the SAME vector rendering primitives as the
	# original album, interactive pet area and black-white finger coloring.
	# Detailed distinctive silhouettes make them identifiable without reading.
	var dark=COLOR_INK if coloring_mode else tint.darkened(0.27)
	var light=Color.WHITE if coloring_mode else tint.lightened(0.27)
	var ink=Color("#333F46")
	var face=Vector2(0,-29)
	_oval(0,73,81,10,Color("#67806B",0.13))
	match animal_id:
		"camel":
			_oval(-40,63,16,37,dark)
			_oval(45,63,16,37,dark)
			_oval(-28,17,47,43,tint)
			_oval(-48,-30,31,53,tint)
			_oval(17,-29,33,59,tint)
			_oval(61,-34,24,51,tint)
			_oval(63,6,30,41,tint)
			_oval(63,-53,37,34,tint)
			_oval(93,-42,29,20,light)
			_oval(44,-92,11,27,dark)
			_oval(77,-91,11,27,dark)
			_oval(71,-66,9,12,ink)
			_oval(72,-69,3,4,Color.WHITE)
			draw_arc(Vector2(94,-23),12,0.2,PI-0.2,16,ink,3,true)
			face=Vector2(68,-42)
		"lion":
			_oval(68,28,24,54,dark)
			_oval(-42,65,23,35,tint)
			_oval(43,65,23,35,tint)
			_oval(0,12,74,74,tint)
			_oval(0,-28,87,92,dark)
			_oval(0,-30,68,72,tint)
			_oval(-58,-87,24,28,dark)
			_oval(58,-87,24,28,dark)
			_oval(-58,-88,12,14,light)
			_oval(58,-88,12,14,light)
			_oval(0,5,38,27,light)
		"tiger":
			_oval(79,29,18,56,dark)
			_oval(-47,64,25,34,tint)
			_oval(45,64,25,34,tint)
			_oval(0,14,79,73,tint)
			_oval(-60,-84,28,32,dark)
			_oval(60,-84,28,32,dark)
			_oval(0,-30,73,70,tint)
			_oval(-60,-84,13,18,light)
			_oval(60,-84,13,18,light)
			_oval(0,8,41,30,light)
			for i in range(3):
				var bx=-62+float(i)*53
				_poly([Vector2(bx,-81),Vector2(bx+21,-78),Vector2(bx+13,-56)],dark)
				_poly([Vector2(bx-7,32),Vector2(bx+13,42),Vector2(bx-9,61)],dark)
			_poly([Vector2(-73,-33),Vector2(-52,-25),Vector2(-73,-14)],dark)
			_poly([Vector2(73,-33),Vector2(52,-25),Vector2(73,-14)],dark)
		"elephant":
			_oval(-57,65,22,38,dark)
			_oval(53,65,22,38,dark)
			_oval(0,23,83,80,tint)
			_oval(-76,-27,40,59,tint.lightened(0.12))
			_oval(76,-27,40,59,tint.lightened(0.12))
			_oval(0,-30,69,70,tint)
			_oval(0,15,23,66,tint)
			_oval(5,64,25,19,tint)
			_oval(-41,30,10,20,light)
			_oval(42,30,10,20,light)
		"hippo":
			_oval(-48,64,24,30,dark)
			_oval(46,64,24,30,dark)
			_oval(0,33,96,69,tint)
			_oval(-69,-92,22,24,tint)
			_oval(69,-92,22,24,tint)
			_oval(0,-32,83,68,tint)
			_oval(0,7,80,39,tint.lightened(0.09))
			_oval(-31,6,11,9,dark)
			_oval(31,6,11,9,dark)
			_oval(-24,15,5,4,light)
			_oval(24,15,5,4,light)
	if animal_id in ["lion","tiger","elephant","hippo"]:
		var lx=face.x-31.0
		var rx=face.x+31.0
		if mood in ["sleep","blink"]:
			draw_arc(Vector2(lx,-39),12,0.15,PI-0.15,16,ink,3.3,true)
			draw_arc(Vector2(rx,-39),12,0.15,PI-0.15,16,ink,3.3,true)
		else:
			_oval(lx,-39,9,12,ink)
			_oval(rx,-39,9,12,ink)
			_oval(lx-3,-42,3,4,Color.WHITE)
			_oval(rx-3,-42,3,4,Color.WHITE)
		if animal_id in ["lion","tiger"]:
			_poly([Vector2(-12,-8),Vector2(12,-8),Vector2(0,3)],dark)
		if mood in ["happy","play","clean","surprised","eating"]:
			draw_arc(Vector2(0,9),22,0.15,PI-0.15,20,ink,4,true)
		elif mood=="sleep":
			draw_line(Vector2(-14,13),Vector2(14,13),ink,3,true)
		else:
			draw_arc(Vector2(0,5),14,0.2,PI-0.2,16,ink,2.5,true)
	if mood in ["happy","play","clean","surprised"]:
		for side in [-1,1]:
			_oval(face.x+float(side)*56,face.y+42,13,8,Color("#F6B7A7"))
		_oval(90,-119,9,11,Color("#F48DAC"))
		_oval(106,-122,9,11,Color("#F48DAC"))
		_poly([Vector2(81,-120),Vector2(115,-120),Vector2(98,-98)],Color("#F48DAC"))
	elif mood=="eating":
		_oval(10,45,8,7,Color("#E8C77D"))
