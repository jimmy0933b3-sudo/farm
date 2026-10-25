extends Control
## Animal drawing academy: TRACE three distinctive outlines, then decorate.
## Unlike the coloring game this records free finger paths and scores how
## closely they followed the real animal's silhouette.
signal changed
const Art=preload("res://scripts/AnimalArt.gd")
const MAX_POINTS=3000
const TRACE_RADIUS=27.0
const REQUIRED_COVERAGE=0.57
const PAINTS=["#F36F78","#F6A85F","#F2D25A","#72BC7C","#48B6AD","#62B8E8",
	"#6989DA","#A884D8","#E78CC0","#825B42","#36495D","#FFFFFF"]
var artist: Control
var animal_id: String=""
var page: Dictionary={}
var guides: Array=[]
var stage: int=0
var brush: String=PAINTS[0]
var mode: String="brush"
var painting: bool=false
var finger: int=-1
var mouse_held: bool=false
var current_stroke: int=-1
var last_touch=Vector2.ZERO
var score_cache: Array=[]
var point_total: int=0
var guide_revision: int=0

func link_artist(original: Control) -> void:
	artist=original

func setup(info: Dictionary, saved: Dictionary={}) -> void:
	end_stroke()
	animal_id=str(info.get("id",""))
	page={"stage":clampi(int(saved.get("stage",0)),0,3),
		"strokes":saved.get("strokes",[]).duplicate(true) if saved.get("strokes",[]) is Array else [],
		"stamps":saved.get("stamps",[]).duplicate(true) if saved.get("stamps",[]) is Array else [],
		"completed":bool(saved.get("completed",false)),
		"stars":clampi(int(saved.get("stars",0)),0,3)}
	stage=int(page["stage"])
	guides.clear()
	score_cache.clear()
	point_total=_point_count()
	guide_revision+=1
	if is_instance_valid(artist):
		artist.setup(info)
		artist.set_coloring(true,{})
	_rebuild_after_render.call_deferred(guide_revision)
	queue_redraw()

func _rebuild_after_render(expected_revision: int) -> void:
	# Give the ORIGINAL AnimalArt two render frames to replace old shapes.
	# Otherwise a fast gallery switch can inherit the previous animal's guides.
	var scene_tree: SceneTree=get_tree()
	if scene_tree==null:
		return
	await scene_tree.process_frame
	if not is_inside_tree():
		return
	await scene_tree.process_frame
	if not is_inside_tree():
		return
	if expected_revision==guide_revision and is_instance_valid(artist):
		_build_guides()

func _process(_delta: float) -> void:
	# Godot renders Control artwork lazily. Read its vector polygons only
	# after the real animal has drawn and its size becomes nonzero. The
	# deferred refresh alone may be too early on a loaded scene.
	if guides.size()<3 and is_instance_valid(artist) and artist.animal_id==animal_id:
		if artist.get_coloring_regions().size()>=5:
			_build_guides()

func _world(point: Vector2) -> Vector2:
	var factor=minf(size.x/220.0,size.y/220.0)
	if factor<=0.0: return Vector2(10000,10000)
	return (point-Vector2(size.x*.5,size.y*.52))/factor

func _screen(point: Vector2) -> Vector2:
	var factor=minf(size.x/220.0,size.y/220.0)
	return Vector2(size.x*.5,size.y*.52)+point*factor

func _area(poly: PackedVector2Array) -> float:
	var result=0.0
	for i in range(poly.size()):
		var a=poly[i]
		var b=poly[(i+1)%poly.size()]
		result+=a.x*b.y-b.x*a.y
	return absf(result)*0.5

func _sample_outline(poly: PackedVector2Array) -> PackedVector2Array:
	var points=PackedVector2Array()
	for i in range(poly.size()):
		var a=poly[i]
		var b=poly[(i+1)%poly.size()]
		var sections=clampi(int(ceil(a.distance_to(b)/13.0)),1,18)
		for j in range(sections):
			points.append(a.lerp(b,float(j)/sections))
	return points

func _build_guides() -> void:
	if not is_instance_valid(artist): return
	var regions: Array=artist.get_coloring_regions()
	if regions.size()<5: return
	var choices=[]
	for region in regions:
		var poly: PackedVector2Array=region.get("points",PackedVector2Array())
		var area=_area(poly)
		if poly.size()<3 or area<200.0 or area>38000.0:
			continue
		choices.append({"points":poly,"area":area})
	choices.sort_custom(func(a,b): return float(a["area"])>float(b["area"]))
	guides.clear()
	for item in choices:
		var outline=_sample_outline(item["points"])
		if outline.size()<12: continue
		var is_distinct=true
		for prev in guides:
			var first: Vector2=outline[0]
			if first.distance_to(prev[0])<9.0:
				is_distinct=false
		if is_distinct:
			guides.append(outline)
		if guides.size()>=3: break
	if guides.size()<3:
		# Original vector polygons supply a fallback for very small species.
		for item in choices:
			if guides.size()>=3: break
			guides.append(_sample_outline(item["points"]))
	score_cache.clear()
	queue_redraw()
	changed.emit()

func trace_coverage(target: int) -> float:
	if target<0 or target>=guides.size(): return 0.0
	var outline: PackedVector2Array=guides[target]
	var matched=0
	var samples=0
	for i in range(0,outline.size(),2):
		samples+=1
		var point: Vector2=outline[i]
		var seen=false
		for stroke in page.get("strokes",[]):
			if int(stroke.get("stage",-1))!=target: continue
			for pair in stroke.get("points",[]):
				if Vector2(float(pair[0]),float(pair[1])).distance_to(point)<=TRACE_RADIUS:
					seen=true
					break
			if seen: break
		if seen: matched+=1
	return float(matched)/float(maxi(1,samples))

func can_advance() -> bool:
	if stage>=3: return false
	return trace_coverage(stage)>=REQUIRED_COVERAGE

func advance() -> bool:
	if not can_advance(): return false
	stage+=1
	page["stage"]=stage
	queue_redraw()
	changed.emit()
	return true

func set_color(hex: String) -> void:
	if PAINTS.has(hex):
		brush=hex

func set_mode(next: String) -> void:
	if next in ["brush","star","heart","paw"]:
		mode=next

func _point_count() -> int:
	var count=0
	for stroke in page.get("strokes",[]):
		count+=stroke.get("points",[]).size()
	return count

func start_stroke(screen_point: Vector2) -> void:
	if guides.size()<3: return
	end_stroke()
	var point=_world(screen_point)
	if absf(point.x)>143.0 or absf(point.y)>155.0: return
	if stage==3 and mode!="brush":
		if page["stamps"].size()<70:
			page["stamps"].append({"pos":[snappedf(point.x,.5),snappedf(point.y,.5)],
				"kind":mode,"color":brush})
			queue_redraw()
			changed.emit()
		return
	if point_total>=MAX_POINTS: return
	current_stroke=page["strokes"].size()
	page["strokes"].append({"stage":stage,"color":brush,"points":[[point.x,point.y]]})
	point_total+=1
	painting=true
	last_touch=screen_point
	queue_redraw()

func drag_stroke(screen_point: Vector2) -> void:
	if not painting: return
	var movement=screen_point-last_touch
	if movement.length()<2.0: return
	var steps=clampi(int(ceil(movement.length()/9.0)),1,45)
	for i in range(1,steps+1):
		if point_total>=MAX_POINTS: break
		var point=_world(last_touch.lerp(screen_point,float(i)/steps))
		if absf(point.x)>143.0 or absf(point.y)>155.0: continue
		page["strokes"][current_stroke]["points"].append([snappedf(point.x,.5),snappedf(point.y,.5)])
		point_total+=1
	last_touch=screen_point
	queue_redraw()

func end_stroke() -> void:
	if not painting: return
	painting=false
	current_stroke=-1
	queue_redraw()
	changed.emit()

func undo() -> void:
	end_stroke()
	var stamps: Array=page.get("stamps",[])
	var strokes: Array=page.get("strokes",[])
	if stage==3 and not stamps.is_empty():
		stamps.pop_back()
	elif not strokes.is_empty():
		strokes.pop_back()
	point_total=_point_count()
	changed.emit()
	queue_redraw()

func reset_picture() -> void:
	end_stroke()
	page={"stage":0,"strokes":[],"stamps":[],"completed":false,"stars":0}
	stage=0
	point_total=0
	changed.emit()
	queue_redraw()

func finish_picture() -> int:
	if stage!=3: return 0
	var traced=0.0
	for step in range(3):
		traced+=trace_coverage(step)
	traced/=3.0
	var decorations=int(page.get("stamps",[]).size())
	var stars=1
	if traced>=0.74: stars=2
	if traced>=0.86 and decorations>=2: stars=3
	page["stars"]=maxi(int(page.get("stars",0)),stars)
	page["completed"]=true
	changed.emit()
	return int(page["stars"])

func _draw_stamp(point: Vector2, kind: String, pigment: Color) -> void:
	match kind:
		"star":
			var vertices=PackedVector2Array()
			for i in range(10):
				var angle=-PI*.5+TAU*float(i)/10.0
				var radius=13.0 if i%2==0 else 6.0
				vertices.append(point+Vector2(cos(angle),sin(angle))*radius)
			draw_colored_polygon(vertices,pigment)
		"heart":
			draw_circle(point+Vector2(-6,-2),7,pigment)
			draw_circle(point+Vector2(6,-2),7,pigment)
			draw_colored_polygon(PackedVector2Array([point+Vector2(-13,1),point+Vector2(13,1),point+Vector2(0,15)]),pigment)
		"paw":
			draw_circle(point+Vector2(0,7),8,pigment)
			for x in [-12.0,-4.0,5.0,13.0]:
				draw_circle(point+Vector2(x,-7),4,pigment)

func _draw() -> void:
	if guides.size()<3: return
	var factor=minf(size.x/220.0,size.y/220.0)
	if factor<=0.0: return
	draw_set_transform(Vector2(size.x*.5,size.y*.52),0,Vector2(factor,factor))
	if stage<3:
		var active: PackedVector2Array=guides[stage]
		# The dotted guide is printed over a faded ORIGINAL animal portrait.
		for i in range(0,active.size(),3):
			draw_circle(active[i],2.5,Color("#38A2C0",0.8))
		if active.size()>0:
			draw_circle(active[0],9,Color("#FFE0A0",0.86))
	for stroke in page.get("strokes",[]):
		var points=PackedVector2Array()
		for pair in stroke.get("points",[]):
			points.append(Vector2(float(pair[0]),float(pair[1])))
		var pigment=Color(str(stroke.get("color","#F36F78")))
		if points.size()>=2:
			draw_polyline(points,pigment,5.8,true)
		elif points.size()==1:
			draw_circle(points[0],3.1,pigment)
	for sticker in page.get("stamps",[]):
		var pair=sticker.get("pos",[0,0])
		if pair is Array and pair.size()==2:
			_draw_stamp(Vector2(float(pair[0]),float(pair[1])),str(sticker.get("kind","star")),Color(str(sticker.get("color","#F2D25A"))))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger==-1 and not mouse_held:
			finger=event.index
			start_stroke(event.position)
		elif not event.pressed and finger==event.index:
			end_stroke()
			finger=-1
		accept_event()
	elif event is InputEventScreenDrag and event.index==finger:
		drag_stroke(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and finger==-1:
		if event.pressed and not mouse_held:
			mouse_held=true
			start_stroke(event.position)
		elif not event.pressed and mouse_held:
			end_stroke()
			mouse_held=false
		accept_event()
	elif event is InputEventMouseMotion and mouse_held and finger==-1:
		drag_stroke(event.position)
		accept_event()

func _exit_tree() -> void:
	end_stroke()
