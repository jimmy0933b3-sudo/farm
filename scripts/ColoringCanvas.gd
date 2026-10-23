extends Control
## Black and white animal coloring art; tap a closed region to fill.
signal region_touched(region: String)

const INK=Color("#26323B")
var animal_id="cow"
var colors: Dictionary={}
var parts: Array=[]
var drag_region=""

func setup(id: String, saved: Dictionary={}) -> void:
	animal_id=id
	colors=saved.duplicate(true)
	_make_parts()
	queue_redraw()

func _oval(id: String, x: float,y: float,rx: float,ry: float) -> void:
	parts.append({"id":id,"center":Vector2(x,y),"radius":Vector2(rx,ry)})

func _poly(id: String, points: Array) -> void:
	parts.append({"id":id,"poly":PackedVector2Array(points)})

func _make_parts() -> void:
	parts.clear()
	if animal_id=="snake":
		_oval("coils",-26,76,102,46)
		_oval("belly",-16,80,59,26)
		_poly("neck",[Vector2(21,81),Vector2(63,79),Vector2(66,-61),Vector2(25,-61)])
		_oval("head",41,-82,75,49)
		_oval("snout",65,-52,43,22)
		return
	if animal_id in ["fox","squirrel","raccoon","monkey"]:
		_oval("tail",91,54,28,69)
	elif animal_id in ["cow","horse","deer","pig","boar"]:
		_oval("tail",96,74,17,42)
	if animal_id in ["duck","chicken","owl"]:
		_oval("left_wing",-74,39,29,58)
		_oval("right_wing",74,39,29,58)
	if animal_id=="hedgehog":
		for i in range(9):
			var x=-91.0+float(i)*22.0
			_poly("spine_"+str(i),[Vector2(x-15,-35),Vector2(x,-128-float(i%2)*13),Vector2(x+20,-46)])
	_oval("foot_left",-46,121,30,20)
	_oval("foot_right",46,121,30,20)
	_oval("body",0,51,107,87)
	_oval("belly",0,63,58,58)
	if animal_id=="rabbit":
		_oval("ear_left",-44,-150,22,71)
		_oval("ear_right",44,-150,22,71)
	elif animal_id in ["fox","squirrel"]:
		_poly("ear_left",[Vector2(-82,-91),Vector2(-74,-168),Vector2(-15,-102)])
		_poly("ear_right",[Vector2(82,-91),Vector2(74,-168),Vector2(15,-102)])
	elif animal_id in ["cow","deer","horse"]:
		_poly("ear_left",[Vector2(-84,-96),Vector2(-119,-145),Vector2(-21,-110)])
		_poly("ear_right",[Vector2(84,-96),Vector2(119,-145),Vector2(21,-110)])
	else:
		_oval("ear_left",-75,-108,30,32)
		_oval("ear_right",75,-108,30,32)
	_oval("head",0,-69,94,91)
	if animal_id=="sheep":
		for i in range(5):
			_oval("wool_"+str(i),-65+float(i)*32,-144,25,26)
	if animal_id in ["cow","guinea_pig","raccoon"]:
		_oval("patch_left",-46,-82,30,27)
		_oval("patch_right",46,-70,29,30)
	if animal_id=="owl":
		_oval("face_left",-40,-84,40,43)
		_oval("face_right",40,-84,40,43)
	_oval("muzzle",0,-21,42,32)
	if animal_id in ["chicken","duck","owl"]:
		_poly("beak",[Vector2(-22,-24),Vector2(22,-24),Vector2(0,13)])
	elif animal_id in ["pig","boar"]:
		_oval("snout",0,-9,32,24)

func _vertices(part: Dictionary) -> PackedVector2Array:
	if part.has("poly"):
		return part["poly"]
	var vertices=PackedVector2Array()
	var c: Vector2=part["center"]
	var r: Vector2=part["radius"]
	for i in range(48):
		var a=TAU*float(i)/48.0
		vertices.append(c+Vector2(cos(a)*r.x,sin(a)*r.y))
	return vertices

func _draw() -> void:
	var scale_value=minf(size.x/340.0,size.y/365.0)
	if scale_value<=0.0: return
	draw_set_transform(Vector2(size.x*0.5,size.y*0.58),0,Vector2(scale_value,scale_value))
	for part in parts:
		var points=_vertices(part)
		var color=Color(str(colors.get(str(part["id"]),"#FFFFFF")))
		draw_colored_polygon(points,color)
		var border=points.duplicate()
		border.append(points[0])
		draw_polyline(border,INK,3.4,true)
	# Distinctive outlines, eyes, cheeks and hair remain black.
	var face_x=43.0 if animal_id=="snake" else 0.0
	var face_y=-92.0 if animal_id=="snake" else -88.0
	for x in [face_x-33,face_x+33]:
		draw_circle(Vector2(x,face_y),9,INK)
		draw_circle(Vector2(x-3,face_y-3),2.6,Color.WHITE)
	draw_circle(Vector2(face_x,face_y+36),5,INK)
	draw_arc(Vector2(face_x,face_y+45),19,0.15,PI-0.15,16,INK,3.0,true)
	if animal_id=="deer":
		for side in [-1,1]:
			draw_line(Vector2(side*36,-141),Vector2(side*52,-206),INK,5,true)
			draw_line(Vector2(side*45,-180),Vector2(side*75,-197),INK,4,true)
	elif animal_id=="cow":
		for side in [-1,1]:
			draw_line(Vector2(side*41,-148),Vector2(side*47,-167),INK,5,true)
	elif animal_id=="chicken":
		for i in range(3):
			draw_arc(Vector2(-20+float(i)*19,-151),17,PI,TAU,18,INK,3,true)
	# Monochrome decorative hatching that stays visible when colored.
	for i in range(3):
		var x=-46.0+float(i)*44.0
		draw_line(Vector2(x,68),Vector2(x+13,78),INK,2.0,true)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func region_at(local_pos: Vector2) -> String:
	var scale_value=minf(size.x/340.0,size.y/365.0)
	if scale_value<=0.0: return ""
	var point=(local_pos-Vector2(size.x*0.5,size.y*0.58))/scale_value
	for i in range(parts.size()-1,-1,-1):
		var part: Dictionary=parts[i]
		if part.has("poly"):
			if Geometry2D.is_point_in_polygon(point,part["poly"]):
				return str(part["id"])
		else:
			var offset: Vector2=(point-part["center"])/part["radius"]
			if offset.length_squared()<=1.0: return str(part["id"])
	return ""

func paint_at(local_pos: Vector2) -> String:
	var id=region_at(local_pos)
	if id!="" and id!=drag_region:
		drag_region=id
		region_touched.emit(id)
	return id

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_region=""
			paint_at(event.position)
		else:
			drag_region=""
		accept_event()
	elif event is InputEventScreenDrag:
		paint_at(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_region=""
			paint_at(event.position)
		else:
			drag_region=""
		accept_event()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT)!=0:
		paint_at(event.position)
		accept_event()
