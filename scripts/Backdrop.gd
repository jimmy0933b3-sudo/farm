extends Control
## Hand-drawn colorful scenery: farms, trees, hills and clouds.

var scene_type: String = "home"

func _draw() -> void:
	var w = size.x
	var h = size.y
	draw_rect(Rect2(Vector2.ZERO,size),Color("#A9E3F6"))
	draw_circle(Vector2(w*0.84,h*0.18),h*0.10,Color("#FFE18A"))
	for idx in range(4):
		var x = w*(0.12+idx*0.28)
		var y = h*(0.13+float(idx%2)*0.09)
		draw_circle(Vector2(x,y),h*0.055,Color.WHITE)
		draw_circle(Vector2(x+w*0.04,y-h*0.017),h*0.045,Color.WHITE)
		draw_circle(Vector2(x-w*0.05,y+h*0.01),h*0.042,Color.WHITE)
	_oval(w*0.28,h*0.91,w*0.69,h*0.40,Color("#8DD6A2"))
	_oval(w*0.82,h*0.92,w*0.59,h*0.34,Color("#62C88D"))
	if scene_type == "zoo":
		draw_rect(Rect2(w*.04,h*.72,w*.92,h*.025),Color("#CAAE82"))
		for idx in range(9):
			var bx=w*(0.05+float(idx)*.112)
			draw_rect(Rect2(bx,h*.54,w*.015,h*.26),Color("#B99878"))
			draw_circle(Vector2(bx+w*.008,h*.54),h*.017,Color("#F5DEAF"))
		draw_rect(Rect2(w*.24,h*.43,w*.52,h*.04),Color("#D8B791"))
		_poly([Vector2(w*.22,h*.43),Vector2(w*.50,h*.30),Vector2(w*.78,h*.43)],Color("#E5AA7A"))
	if scene_type == "insect":
		for i in range(10):
			var x=w*(0.05+float(i)*0.105)
			draw_line(Vector2(x,h*.88),Vector2(x,h*.54),Color("#469B6A"),8,true)
			draw_circle(Vector2(x,h*.53),h*.055,Color("#F7C3D6") if i%2==0 else Color("#F6D889"))
			draw_circle(Vector2(x,h*.53),h*.018,Color("#F4A460"))
	if scene_type == "forest":
		for i in range(9):
			var x = w*(0.04+float(i)*0.12)
			var y = h*(0.56 + float(i%3)*0.08)
			draw_rect(Rect2(x-9,y,18,h*0.3),Color("#8A6B4C"))
			draw_circle(Vector2(x,y-12),h*0.105,Color("#318F64"))
			draw_circle(Vector2(x-23,y+7),h*0.064,Color("#4AB57A"))
	elif scene_type == "farm":
		draw_rect(Rect2(w*0.72,h*0.43,w*0.17,h*0.28),Color("#E97D71"))
		_poly([Vector2(w*0.70,h*0.44),Vector2(w*0.805,h*0.31),Vector2(w*0.91,h*0.44)],Color("#A75352"))
		draw_rect(Rect2(w*0.78,h*0.56,w*0.045,h*0.15),Color("#FFF3DA"))
	for idx in range(18):
		var x = float(idx)*w/18.0+w*0.013
		var y = h*(0.86+0.02*float(idx%4))
		draw_circle(Vector2(x,y),h*0.009,Color("#F8E39B"))

func _oval(x:float,y:float,rx:float,ry:float,color:Color) -> void:
	var p = PackedVector2Array()
	for i in range(38):
		var a = TAU * float(i) / 38.0
		p.append(Vector2(x+cos(a)*rx,y+sin(a)*ry))
	draw_colored_polygon(p,color)

func _poly(points:Array,color:Color) -> void:
	var p = PackedVector2Array()
	for point in points:
		p.append(point)
	draw_colored_polygon(p,color)
