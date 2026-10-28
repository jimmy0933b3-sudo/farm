extends Control
## Two richly layered bird habitats: wetland lake and forest canopy.
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
	draw_rect(Rect2(Vector2.ZERO,size),Color("#C9E9EE") if habitat=="wetland" else Color("#DDF2D7"))
	draw_circle(Vector2(w*.86,h*.17),h*.10,Color("#FFF2B9"))
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
