extends Control
## Offline hand-drawn scenes for the three monster habitats.
var zone_id: String = "rainbow"

func setup(id: String) -> void:
	zone_id=id
	queue_redraw()

func _draw() -> void:
	var w=size.x
	var h=size.y
	if w<1.0 or h<1.0:
		return
	var sky=Color("#D5F3EE")
	if zone_id=="candy":
		sky=Color("#FFE5E3")
	elif zone_id=="sky":
		sky=Color("#B7D3F8")
	draw_rect(Rect2(Vector2.ZERO,size),sky)
	if zone_id=="rainbow":
		draw_circle(Vector2(w*.84,h*.17),h*.12,Color("#FFF1A4"))
		for n in range(5):
			draw_arc(Vector2(w*.48,h*.63),h*(.55-float(n)*.055),PI,TAU,50,[
				Color("#F9A5B5"),Color("#FBC885"),Color("#FBEF9B"),Color("#A4DDB5"),Color("#9BC8F5")][n],7,true)
		_oval(w*.5,h*.98,w*.75,h*.35,Color("#A4D991"))
		for n in range(8):
			var x=w*(.05+float(n)*.13)
			draw_rect(Rect2(x-7,h*.60,14,h*.28),Color("#A88666"))
			draw_circle(Vector2(x,h*.59),h*.07,[Color("#C6B4EF"),Color("#F1A6BB"),Color("#93D6BD")][n%3])
	elif zone_id=="candy":
		_oval(w*.44,h*.98,w*.67,h*.36,Color("#F3C8A8"))
		_oval(w*.92,h*.98,w*.41,h*.33,Color("#E6A6C1"))
		for n in range(6):
			var x=w*(.10+float(n)*.16)
			var y=h*(.46+float(n%3)*.095)
			draw_rect(Rect2(x-5,y,10,h*.39),Color("#BE927C"))
			draw_circle(Vector2(x,y),h*.077,[
				Color("#F0ACCC"),Color("#E8D88D"),Color("#A6D8CF")][n%3])
			draw_circle(Vector2(x-8,y-8),h*.013,Color.WHITE)
		for n in range(5):
			var x=w*(.06+float(n)*.22)
			_oval(x,h*.81,30,20,Color("#D28DB5"))
			_oval(x,h*.79,20,12,Color("#FFF1C8"))
	else:
		draw_circle(Vector2(w*.85,h*.19),h*.12,Color("#FFF0BC"))
		_oval(w*.53,h*.97,w*.66,h*.28,Color("#B1B7F0"))
		for n in range(27):
			var x=fposmod(float(n*139+19),w)
			var y=fposmod(float(n*53+23),h*.62)
			draw_circle(Vector2(x,y),2.5+float(n%3)*1.5,Color("#FFF8DE"))
		for n in range(7):
			var x=w*(.04+float(n)*.15)
			var y=h*(.44+float(n%3)*.12)
			_oval(x,y,49,15,Color("#EDF7FF"))
			_oval(x+20,y-11,34,18,Color("#FFFFFF"))
			_oval(x-17,y-7,31,17,Color("#FFFFFF"))

func _oval(x: float,y: float,rx: float,ry: float,color: Color) -> void:
	var points=PackedVector2Array()
	for n in range(32):
		var a=float(n)*TAU/32.0
		points.append(Vector2(x+cos(a)*rx,y+sin(a)*ry))
	draw_colored_polygon(points,color)
