extends Control
## Four bird habitats: wetland, canopy, mountain canyon and moonlit woods.
var habitat: String="wetland"
var movement: float=0.0

func setup(id: String) -> void:
	habitat=id
	queue_redraw()

func _oval(x: float,y: float,rx: float,ry: float,col: Color) -> void:
	var p=PackedVector2Array()
	for i in range(32):
		var a=TAU*float(i)/32.0
		p.append(Vector2(x+cos(a)*rx,y+sin(a)*ry))
	draw_colored_polygon(p,col)

func _draw() -> void:
	var w=size.x
	var h=size.y
	if w<1.0 or h<1.0:
		return
	var night=habitat=="night"
	var mountain=habitat=="mountain"
	var sky=Color("#C9E9EE") if habitat=="wetland" else (Color("#DDF2D7") if habitat=="woodland" else (Color("#C4DFEF") if mountain else Color("#3D5682")))
	draw_rect(Rect2(Vector2.ZERO,size),sky)
	draw_circle(Vector2(w*.86,h*.17),h*.10,Color("#F8F2D4") if night else Color("#FFF2B9"))
	if night:
		for n in range(42):
			var x=fposmod(float(n*113+17),w)
			var y=fposmod(float(n*73+31),h*.69)
			draw_circle(Vector2(x,y),1.7+float(n%3),Color("#FAEFC5"))
	for n in range(5):
		var x=w*(.09+float(n)*.20)
		var y=h*(.14+float(n%2)*.08)
		_oval(x,y,w*.08,h*.034,Color("#FFFFFF",.65))
	if habitat=="wetland":
		_oval(w*.50,h*.91,w*.75,h*.27,Color("#8ED1CE"))
		_oval(w*.42,h*.94,w*.66,h*.18,Color("#6FB8C7"))
		for n in range(6):
			var x=w*(.06+float(n)*.165)
			var y=h*(.70+float(n%3)*.060)
			_oval(x,y,38,13,Color("#73BA8B"))
			_oval(x-4,y-6,16,6,Color("#A5DE9E"))
			draw_line(Vector2(x+31,y+9),Vector2(x+31,y-42),Color("#649F7B"),4,true)
			draw_line(Vector2(x+31,y-42),Vector2(x+20,y-60),Color("#649F7B"),6,true)
		for n in range(3):
			var x=w*(.15+float(n)*.34)
			var y=h*.87
			draw_arc(Vector2(x,y),23,PI,TAU,18,Color("#D8F9F4"),2,true)
	elif habitat=="mountain":
		for n in range(5):
			var x=w*(-.25+float(n)*.35)
			var peak=h*(.29+float(n%2)*.12)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x-w*.28,h),Vector2(x,peak),Vector2(x+w*.3,h)]),
				Color("#839EAE") if n%2==0 else Color("#9BB7C1"))
			draw_colored_polygon(PackedVector2Array([
				Vector2(x-w*.09,peak+h*.21),Vector2(x,peak),Vector2(x+w*.085,peak+h*.21)]),
				Color("#F5F5E9"))
		_oval(w*.5,h*1.10,w*.78,h*.29,Color("#87B6A2"))
		for n in range(8):
			var x=w*(.04+float(n)*.14)
			var base=h*(.83+float(n%2)*.10)
			draw_line(Vector2(x,base),Vector2(x,base-h*.22),Color("#796E60"),7,true)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x-22,base-h*.08),Vector2(x,base-h*.36),Vector2(x+22,base-h*.08)]),Color("#558D7B"))
	elif night:
		_oval(w*.5,h*1.07,w*.85,h*.38,Color("#263D63"))
		_oval(w*.9,h*.93,w*.45,h*.30,Color("#355679"))
		for n in range(9):
			var x=w*(.03+float(n)*.118)
			var base=h*(.91+float(n%3)*.05)
			draw_line(Vector2(x,base),Vector2(x,base-h*.18),Color("#425B6F"),8,true)
			for t in range(3):
				var top=base-h*(.43-float(t)*.09)
				draw_colored_polygon(PackedVector2Array([
					Vector2(x-h*.085,top+h*.16),Vector2(x,top),Vector2(x+h*.085,top+h*.16)]),
					Color("#446F75") if n%2==0 else Color("#537A7B"))
	else:
		_oval(w*.4,h*1.02,w*.80,h*.28,Color("#87C997"))
		for n in range(7):
			var x=w*(.01+float(n)*.17)
			var y=h*(.59+float(n%3)*.08)
			draw_rect(Rect2(x-10,y,20,h*.39),Color("#967A60"))
			for s in [-1,0,1]:
				_oval(x+float(s)*24,y-18-float(s%2)*7,36,38,Color("#71B88A") if n%2==0 else Color("#89C8A2"))
				_oval(x+float(s)*24-8,y-30,13,12,Color("#ACDBA9",.60))
		draw_line(Vector2(0,h*.72),Vector2(w,h*.63),Color("#9D7A5E"),14,true)
		for n in range(9):
			var x=w*(.05+float(n)*.117)
			_oval(x,h*(.72-float(n)*.01),9,5,Color("#F0C57D"))
