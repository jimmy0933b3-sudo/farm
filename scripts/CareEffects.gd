extends Control
## Animated visual props drawn in front of an animal.
var action: String = ""
var phase: float = 0.0
var crop_id: String = ""

func _oval(x:float,y:float,rx:float,ry:float,color:Color) -> void:
	var points=PackedVector2Array()
	for i in range(28):
		var a=TAU*float(i)/28.0
		points.append(Vector2(x+cos(a)*rx,y+sin(a)*ry))
	draw_colored_polygon(points,color)

func _draw() -> void:
	if action == "":
		return
	var k=minf(size.x/420.0,size.y/340.0)
	draw_set_transform(Vector2(size.x*0.5,size.y*0.48),0.0,Vector2(k,k))
	match action:
		"garden_feed":
			# Fresh vegetables float to the mouth while hearts appear above.
			var t=minf(1.0,phase*1.9)
			var x=-91.0+91.0*t
			var y=112.0-112.0*t
			if crop_id=="carrot":
				draw_colored_polygon(PackedVector2Array([
					Vector2(x-20,y-13),Vector2(x+20,y-13),Vector2(x,y+38)]),Color("#F1A14C"))
				for n in range(3):
					_oval(x-16+float(n)*16,y-25,9,17,Color("#78B967"))
			elif crop_id=="cabbage":
				for n in range(5):
					_oval(x-24+float(n)*12,y,17,28,Color("#81C87D"))
				_oval(x,y,24,24,Color("#B8E99C"))
			else:
				for n in range(5):
					_oval(x-24+float(n)*12,y,17,26,Color("#E99444"))
				_oval(x,y-27,13,8,Color("#71AE66"))
			for n in range(5):
				var cx=-95+float(n)*47
				var cy=-104-sin(phase*TAU+float(n)*.17)*15-35*phase
				var color=Color("#F07E9F",.95)
				_oval(cx-7,cy,10,10,color)
				_oval(cx+7,cy,10,10,color)
				draw_colored_polygon(PackedVector2Array([
					Vector2(cx-16,cy+4),Vector2(cx+16,cy+4),Vector2(cx,cy+23)]),color)
		"feed":
			# Hay/food visibly moves up to the animal's mouth, then disappears.
			var p=minf(1.0,phase*2.0)
			_oval(-82+82*p,110-132*p,45,12,Color("#A97B4D"))
			for i in range(5):
				var xx=-104+82*p+i*12
				_oval(xx,93-120*p,8,18,Color("#68B573"))
			if phase>0.55:
				_oval(4,-15,18,8,Color("#F5D07B"))
		"wash":
			# Large moving blue waterdrops + playful bubbles.
			for i in range(11):
				var t=phase*6.0+float(i)*0.8
				var x=sin(t*1.7)*91.0
				var y=100.0-fmod(t*48.0,220.0)
				var tint=Color("#8EDCEF",0.85)
				_oval(x,y,12.0+float(i%3)*4.0,12.0+float(i%3)*4.0,tint)
				_oval(x-4,y-4,3,3,Color.WHITE)
		"play":
			# Bright toy ball travels left and right and bounces.
			var x=sin(phase*TAU*1.5)*135.0
			var y=105.0-absf(sin(phase*TAU*2.5))*125.0
			_oval(x,y,28,28,Color("#F79B8A"))
			_oval(x-9,y-11,11,12,Color("#FFF0A0"))
			_oval(x+10,y+10,8,9,Color("#7DC4E8"))
		"sleep":
			# A blanket, stars and crescent tell a bedtime story without words.
			var blanket=Color("#B9C8F1",0.88)
			draw_rect(Rect2(-112,18,224,94),blanket)
			_oval(0,18,112,24,blanket)
			_oval(133,-113,24,25,Color("#FBE1A5"))
			_oval(145,-127,19,24,Color("#FFFDF1"))
			for i in range(4):
				var xx=-124+float(i)*75.0
				var yy=-111-sin(phase*TAU+float(i))*10.0
				_oval(xx,yy,7,7,Color("#FFDC89"))
				draw_line(Vector2(xx-13,yy),Vector2(xx+13,yy),Color("#FFDC89"),3.0)
				draw_line(Vector2(xx,yy-13),Vector2(xx,yy+13),Color("#FFDC89"),3.0)
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
