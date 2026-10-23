extends Control
## Dedicated farm background inspired by the approved pastoral illustration.
## No painted animals: live roaming residents remain the only animal sprites.
func _oval(center: Vector2, radius: Vector2, color: Color) -> void:
	var ps=PackedVector2Array()
	for i in range(36):
		var a=TAU*float(i)/36.0
		ps.append(center+Vector2(cos(a)*radius.x,sin(a)*radius.y))
	draw_colored_polygon(ps,color)
func _poly(points: Array, color: Color) -> void:
	var ps=PackedVector2Array()
	for p in points:
		ps.append(p)
	draw_colored_polygon(ps,color)
func _line(a: Vector2,b: Vector2,c: Color,thickness: float) -> void:
	draw_line(a,b,c,thickness,true)
func _tree(x: float,y: float,r: float) -> void:
	draw_rect(Rect2(x-r*0.15,y-r*0.10,r*0.30,r*1.1),Color("#976D4D"))
	_oval(Vector2(x,y-r*0.38),Vector2(r*0.88,r*0.74),Color("#4CA76C"))
	_oval(Vector2(x-r*0.33,y-r*0.56),Vector2(r*0.49,r*0.52),Color("#82CE86"))
	_oval(Vector2(x+r*0.33,y-r*0.73),Vector2(r*0.49,r*0.48),Color("#6FBB76"))
func _draw() -> void:
	var w=size.x
	var h=size.y
	if w<1 or h<1: return
	var u=minf(w/900.0,h/440.0)
	draw_rect(Rect2(Vector2.ZERO,size),Color("#A3E5F4"))
	_oval(Vector2(w*0.86,h*0.13),Vector2(h*0.10,h*0.10),Color("#FFDC6C"))
	for i in range(4):
		var cx=w*(0.17+float(i)*0.21)
		var cy=h*(0.13+0.035*float(i%2))
		_oval(Vector2(cx,cy),Vector2(30*u,13*u),Color("#FFFFFF"))
		_oval(Vector2(cx+15*u,cy-7*u),Vector2(25*u,15*u),Color("#FFFFFF"))
	_oval(Vector2(w*0.22,h*0.51),Vector2(w*0.47,h*0.32),Color("#B2DDA3"))
	_oval(Vector2(w*0.78,h*0.51),Vector2(w*0.55,h*0.29),Color("#9CD49D"))
	_poly([Vector2(0,h*0.44),Vector2(w*.27,h*.41),Vector2(w*.52,h*.46),Vector2(w*.82,h*.40),Vector2(w,h*.43),Vector2(w,h),Vector2(0,h)],Color("#9DDA79"))
	_oval(Vector2(w*.50,h*1.03),Vector2(w*.76,h*.50),Color("#8ED26F"))
	# A distant wooden fence behind the meadow, not in the play lane.
	for i in range(12):
		var fx=w*float(i)/11.0
		_line(Vector2(fx,h*.44),Vector2(fx,h*.52),Color("#B68C5D"),8*u)
	for fy in [h*.457,h*.495]:
		_line(Vector2(0,fy),Vector2(w,fy),Color("#C89B69"),5*u)
	_tree(w*.03,h*.41,68*u)
	_tree(w*.97,h*.43,76*u)
	# Barn to the left; red walls, sloped roof and stable doors.
	var bx=w*.15
	var by=h*.35
	var bw=w*.16
	var bh=h*.23
	draw_rect(Rect2(bx-bw*.5,by-bh*.52,bw,bh),Color("#E27668"))
	_poly([Vector2(bx-bw*.62,by-bh*.53),Vector2(bx,by-bh*1.17),Vector2(bx+bw*.62,by-bh*.53)],Color("#B14F4F"))
	draw_rect(Rect2(bx-bw*.19,by-bh*.05,bw*.38,bh*.52),Color("#FFEFD4"))
	_line(Vector2(bx-bw*.18,by-bh*.05),Vector2(bx+bw*.18,by+bh*.47),Color("#CF8A76"),3*u)
	_line(Vector2(bx+bw*.18,by-bh*.05),Vector2(bx-bw*.18,by+bh*.47),Color("#CF8A76"),3*u)
	# Winding sand path and hay bales.
	_poly([Vector2(0,h*.53),Vector2(w*.15,h*.47),Vector2(w*.26,h*.58),Vector2(w*.18,h*.68),Vector2(0,h*.77)],Color("#F0CA88"))
	for i in range(3):
		_oval(Vector2(w*.036+float(i)*22*u,h*.48),Vector2(18*u,13*u),Color("#F4CB69"))
	# A blue farm pond at right with stone border and lily pads.
	_oval(Vector2(w*.82,h*.65),Vector2(w*.16,h*.103),Color("#77C5D9"))
	_oval(Vector2(w*.82,h*.64),Vector2(w*.132,h*.073),Color("#AEE5ED"))
	for i in range(7):
		_oval(Vector2(w*(.68+float(i)*.043),h*.71),Vector2(14*u,8*u),Color("#92A6A0"))
	for i in range(3):
		_oval(Vector2(w*(.77+float(i)*.055),h*.64),Vector2(13*u,5*u),Color("#74BC78"))
	# Flowers and leaves across the foreground, behind the moving animals.
	for i in range(47):
		var x=fmod(float(i)*123*u+39*u,w)
		var y=h*(.57+.36*float((i*7)%19)/18.0)
		if x<w*.24 and y<h*.75: continue
		if x>w*.66 and y<h*.76: continue
		var fc=Color("#FFF3E4") if i%3 else Color("#F6A3B0")
		_line(Vector2(x,y+4*u),Vector2(x,y-6*u),Color("#68AF60"),2*u)
		for j in range(5):
			var a=TAU*float(j)/5.0
			_oval(Vector2(x+5*u*cos(a),y-6*u+5*u*sin(a)),Vector2(3*u,3*u),fc)
		_oval(Vector2(x,y-6*u),Vector2(3*u,3*u),Color("#FFDB80"))
	# Low foreground paddock fence: animals roam behind this earthbound edge.
	for i in range(6):
		var x=w*float(i)/5.0
		_line(Vector2(x,h*.96),Vector2(x,h),Color("#A67F57"),10*u)
	_line(Vector2(0,h*.97),Vector2(w,h*.97),Color("#C69B6F"),6*u)
