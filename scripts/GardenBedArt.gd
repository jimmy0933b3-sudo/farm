extends Control
## Hand-drawn isometric raised soil beds: top furrows, earthen sides and grass.
## Geometry is independent of crops, so blank and planted plots share a field.
var ripe: bool=false

func set_ripe(value: bool) -> void:
	if ripe==value:
		return
	ripe=value
	queue_redraw()

func _polygon(points: Array,color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points),color)

func _draw() -> void:
	if size.x<2.0 or size.y<2.0:
		return
	var k=minf(size.x/174.0,size.y/119.0)
	draw_set_transform(Vector2(size.x*.5,size.y*.49),0.0,Vector2(k,k))
	# Grass beneath the raised bed and an offset cast shadow.
	_polygon([Vector2(-86,18),Vector2(-1,-18),Vector2(86,19),Vector2(2,61)],Color("#91BB75"))
	_polygon([Vector2(-77,27),Vector2(0,-5),Vector2(81,32),Vector2(0,70)],Color("#48703E",.22))
	for i in range(7):
		var gx=-77+float(i)*25
		draw_line(Vector2(gx,30),Vector2(gx-4,22),Color("#6EA85D"),2,true)
		draw_line(Vector2(gx,30),Vector2(gx+3,22),Color("#A5C871"),2,true)
	# Thick earthen side faces, giving the small plots visible volume.
	_polygon([Vector2(-77,4),Vector2(0,36),Vector2(0,57),Vector2(-77,24)],Color("#825237"))
	_polygon([Vector2(0,36),Vector2(77,4),Vector2(77,24),Vector2(0,57)],Color("#A06942"))
	_polygon([Vector2(-77,24),Vector2(0,57),Vector2(77,24),Vector2(77,29),Vector2(0,63),Vector2(-77,29)],Color("#6E442E",.9))
	# Top diamond with light, shallow crop furrows.
	_polygon([Vector2(-77,4),Vector2(0,-29),Vector2(77,4),Vector2(0,36)],
		Color("#A87A50") if ripe else Color("#B38357"))
	_polygon([Vector2(-69,3),Vector2(0,-25),Vector2(68,3),Vector2(0,31)],Color("#BC8C61"))
	_polygon([Vector2(-64,4),Vector2(0,-22),Vector2(62,4),Vector2(0,28)],Color("#95633F"))
	for n in range(3):
		var shift=float(n-1)*18.0
		var start=Vector2(-28+shift,-7+float(n)*7)
		var end=Vector2(19+shift,13+float(n)*5)
		draw_line(start,end,Color("#69472F",.62),4,true)
		draw_line(start+Vector2(0,-3),end+Vector2(0,-3),Color("#D2A276",.57),2,true)
	for n in range(6):
		var x=-48+float(n)*19
		var y=15.0 if n%2==0 else -3.0
		draw_circle(Vector2(x,y),2.3,Color("#DCC29D",.8))
	draw_line(Vector2(-77,4),Vector2(0,-29),Color("#E5BA89",.8),2,true)
	draw_line(Vector2(0,-29),Vector2(77,4),Color("#D7A67C",.9),2,true)
	if ripe:
		for i in range(3):
			var p=Vector2(-48+float(i)*48,-32+float(i%2)*5)
			draw_circle(p,5,Color("#F6E08A"))
			draw_line(p+Vector2(-9,0),p+Vector2(9,0),Color("#FFF5BD"),2,true)
			draw_line(p+Vector2(0,-9),p+Vector2(0,9),Color("#FFF5BD"),2,true)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
