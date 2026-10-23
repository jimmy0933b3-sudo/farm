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
	if mood == "sleep":
		draw_arc(Vector2(-25,-37),13.0,0.15,PI-0.15,14,ink,3.5)
		draw_arc(Vector2(25,-37),13.0,0.15,PI-0.15,14,ink,3.5)
	elif mood in ["happy","clean","play"]:
		draw_arc(Vector2(-25,-36),12.0,PI+0.13,TAU-0.13,14,ink,4.0)
		draw_arc(Vector2(25,-36),12.0,PI+0.13,TAU-0.13,14,ink,4.0)
	else:
		_accent_oval(-25,-38,8,11,ink)
		_accent_oval(25,-38,8,11,ink)
		_accent_oval(-27,-42,3,4,Color.WHITE)
		_accent_oval(23,-42,3,4,Color.WHITE)
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
