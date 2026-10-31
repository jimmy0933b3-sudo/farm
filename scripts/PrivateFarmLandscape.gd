extends Control
## Storybook landscape. Scene coordinates use world pixels, never a percentage
## of the 6500px panorama: scenery stays proportional on every phone and
## continues smoothly instead of stretching buildings across the full map.
## All animals are separate live Control nodes above this painted scenery.

func _poly(points: Array, color: Color) -> void:
	var vertices=PackedVector2Array()
	for point in points:
		vertices.append(point)
	draw_colored_polygon(vertices,color)

func _oval(at: Vector2,radii: Vector2,color: Color) -> void:
	var vertices=PackedVector2Array()
	for i in range(32):
		var a=TAU*float(i)/32.0
		vertices.append(at+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(vertices,color)

func _line(a: Vector2,b: Vector2,color: Color,thickness: float) -> void:
	draw_line(a,b,color,thickness,true)

func _flower(x: float,y: float,u: float,petals: Color) -> void:
	_line(Vector2(x,y+4*u),Vector2(x,y-5*u),Color("#529765"),2.0*u)
	for i in range(5):
		var angle=TAU*float(i)/5.0
		_oval(Vector2(x+4*u*cos(angle),y-6*u+4*u*sin(angle)),
			Vector2(3.4*u,3.1*u),petals)
	_oval(Vector2(x,y-6*u),Vector2(2.7*u,2.7*u),Color("#FBC868"))

func _tree(x: float,ground: float,u: float) -> void:
	_oval(Vector2(x+8*u,ground+6*u),Vector2(65*u,11*u),Color("#659C56",0.24))
	draw_rect(Rect2(x-9*u,ground-73*u,18*u,78*u),Color("#976743"))
	_line(Vector2(x,ground-45*u),Vector2(x-25*u,ground-67*u),Color("#976743"),7*u)
	_oval(Vector2(x,ground-102*u),Vector2(71*u,60*u),Color("#34895F"))
	_oval(Vector2(x-32*u,ground-121*u),Vector2(44*u,42*u),Color("#6ABB71"))
	_oval(Vector2(x+30*u,ground-122*u),Vector2(49*u,47*u),Color("#76C879"))
	_oval(Vector2(x-4*u,ground-146*u),Vector2(51*u,36*u),Color("#95D987"))
	for i in range(6):
		var ax=x+float((i*43)%104-52)*u
		var ay=ground-float(94+(i*23)%60)*u
		_oval(Vector2(ax,ay),Vector2(6*u,7*u),Color("#F18355"))
		_oval(Vector2(ax-2*u,ay-2*u),Vector2(1.8*u,2*u),Color("#FFCE8B"))

func _pine(x: float,y: float,u: float) -> void:
	_line(Vector2(x,y),Vector2(x,y-36*u),Color("#618864"),4*u)
	for i in range(3):
		var top=y-(64.0-float(i)*14.0)*u
		var spread=(17.0+float(i)*8.0)*u
		_poly([Vector2(x,top),Vector2(x-spread,y-(21.0+float(i)*7.0)*u),
			Vector2(x+spread,y-(21.0+float(i)*7.0)*u)],Color("#56A88B") if i%2==0 else Color("#70BC91"))

func _barn(x: float,ground: float,u: float) -> void:
	_oval(Vector2(x,ground+5*u),Vector2(122*u,14*u),Color("#578B54",0.23))
	draw_rect(Rect2(x-76*u,ground-103*u,152*u,104*u),Color("#E98171"))
	draw_rect(Rect2(x-77*u,ground-104*u,9*u,105*u),Color("#FFE6CB"))
	draw_rect(Rect2(x+68*u,ground-104*u,9*u,105*u),Color("#FFE6CB"))
	_poly([Vector2(x-94*u,ground-103*u),Vector2(x,ground-171*u),
		Vector2(x+94*u,ground-103*u)],Color("#A94A4B"))
	_poly([Vector2(x-80*u,ground-109*u),Vector2(x,ground-163*u),
		Vector2(x+80*u,ground-109*u)],Color("#C36359"))
	draw_rect(Rect2(x-25*u,ground-77*u,50*u,78*u),Color("#FFF1D7"))
	draw_rect(Rect2(x-18*u,ground-70*u,36*u,71*u),Color("#8F5C49"))
	_line(Vector2(x-17*u,ground-65*u),Vector2(x+17*u,ground-4*u),Color("#C98B71"),3*u)
	_line(Vector2(x+17*u,ground-65*u),Vector2(x-17*u,ground-4*u),Color("#C98B71"),3*u)
	draw_rect(Rect2(x-13*u,ground-131*u,26*u,22*u),Color("#FFF4D8"))
	draw_rect(Rect2(x-8*u,ground-126*u,16*u,12*u),Color("#8FC9D8"))
	_line(Vector2(x,ground-126*u),Vector2(x,ground-114*u),Color("#FAF0D6"),2*u)
	_line(Vector2(x-8*u,ground-120*u),Vector2(x+8*u,ground-120*u),Color("#FAF0D6"),2*u)

func _windmill(x: float,ground: float,u: float) -> void:
	_line(Vector2(x-20*u,ground),Vector2(x,ground-92*u),Color("#A97955"),7*u)
	_line(Vector2(x+20*u,ground),Vector2(x,ground-92*u),Color("#A97955"),7*u)
	for i in range(3):
		_line(Vector2(x-15*u,ground-(i*24+10)*u),
			Vector2(x+15*u,ground-(i*24+10)*u),Color("#BB8C64"),4*u)
	var pivot=Vector2(x,ground-93*u)
	for i in range(4):
		var angle=PI*.25+float(i)*TAU/4.0
		var direction=Vector2(cos(angle),sin(angle))
		var side=Vector2(-direction.y,direction.x)
		_poly([pivot+direction*11*u+side*5*u,
			pivot+direction*55*u+side*12*u,
			pivot+direction*55*u-side*5*u,
			pivot+direction*11*u-side*4*u],Color("#F1DAB5"))
		_line(pivot+direction*14*u,pivot+direction*52*u,Color("#AF8359"),2*u)
	_oval(pivot,Vector2(8*u,8*u),Color("#956E52"))

func _fence(start_x: float,end_x: float,y: float,u: float) -> void:
	_line(Vector2(start_x,y-25*u),Vector2(end_x,y-25*u),Color("#F7E7C6"),7*u)
	_line(Vector2(start_x,y-11*u),Vector2(end_x,y-11*u),Color("#D5B38A"),6*u)
	var x=start_x
	while x<=end_x:
		draw_rect(Rect2(x-5*u,y-40*u,10*u,43*u),Color("#FCF3DB"))
		_poly([Vector2(x-5*u,y-40*u),Vector2(x,y-48*u),
			Vector2(x+5*u,y-40*u)],Color("#FCF3DB"))
		_line(Vector2(x+3*u,y-35*u),Vector2(x+3*u,y),Color("#CBA77F"),2*u)
		x+=66*u

func _garden(x: float,y: float,u: float) -> void:
	# Small illustrated vegetable beds are scenery only, never interactive plots.
	_oval(Vector2(x,y),Vector2(144*u,36*u),Color("#5B9862",0.26))
	_poly([Vector2(x-145*u,y-15*u),Vector2(x+115*u,y-15*u),
		Vector2(x+145*u,y+25*u),Vector2(x-111*u,y+25*u)],Color("#A26E52"))
	for row in range(2):
		for column in range(6):
			var px=x+(-107.0+float(column)*42.0+float(row)*8.0)*u
			var py=y+(-4.0+float(row)*18.0)*u
			_oval(Vector2(px,py+4*u),Vector2(10*u,4*u),Color("#7C503F"))
			if column%3==0:
				_oval(Vector2(px,py-5*u),Vector2(8*u,7*u),Color("#EFA35A"))
				_line(Vector2(px,py-9*u),Vector2(px,py-17*u),Color("#548C49"),3*u)
			else:
				_oval(Vector2(px,py-8*u),Vector2(11*u,9*u),Color("#77B965"))
				_oval(Vector2(px-4*u,py-10*u),Vector2(5*u,6*u),Color("#A5D983"))
	_fence(x-153*u,x+155*u,y+36*u,u)

func _pond(center: Vector2,radii: Vector2,u: float) -> void:
	_oval(center+Vector2(0,5*u),radii+Vector2(22*u,10*u),Color("#C9E7B1"))
	_oval(center,radii+Vector2(12*u,5*u),Color("#81BAAD"))
	_oval(center,radii,Color("#329FD3"))
	_oval(center-Vector2(0,5*u),radii-Vector2(15*u,8*u),Color("#68CCE6"))
	for i in range(12):
		var angle=TAU*float(i)/12.0
		var p=center+Vector2(cos(angle)*radii.x,sin(angle)*radii.y)
		_oval(p,Vector2(11*u,6*u),Color("#E7DDC0"))
	for i in range(8):
		var ax=center.x+(float((i*71)%140)/100.0-.7)*radii.x
		var ay=center.y+(float((i*37)%110)/100.0-.5)*radii.y
		_oval(Vector2(ax,ay),Vector2(16*u,5*u),Color("#57B68B"))
		_oval(Vector2(ax+7*u,ay-2*u),Vector2(5*u,3*u),Color("#9AD8A4"))

func _draw() -> void:
	var w=size.x
	var h=size.y
	if w<100.0 or h<100.0:
		return
	# Use vertical proportions for the panorama, fixed world-unit width for props.
	var u=clampf(h/320.0,0.55,1.25)
	draw_rect(Rect2(Vector2.ZERO,size),Color("#86D5F6"))
	draw_rect(Rect2(0,h*.29,w,h*.20),Color("#A9E2F2"))
	# Gentle contiguous mountains and hills. No full-width stretched triangles.
	for i in range(int(ceil(w/390.0))+2):
		var px=float(i)*390.0-190.0
		_poly([Vector2(px-230,h*.49),Vector2(px,h*.13+float(i%3)*h*.06),
			Vector2(px+230,h*.49)],Color("#A4CDE2") if i%2==0 else Color("#C1DEEA"))
	for i in range(int(ceil(w/330.0))+2):
		var x=float(i)*330.0
		_oval(Vector2(x,h*.47),Vector2(240*u,55*u),Color("#8FCCAA") if i%2==0 else Color("#A4D8AF"))
	for i in range(int(ceil(w/250.0))+1):
		var x=90.0+float(i)*250.0
		_oval(Vector2(x,h*.15+float(i%3)*13*u),Vector2(43*u,13*u),Color("#FFFDF4",0.85))
		_oval(Vector2(x+15*u,h*.12+float(i%3)*13*u),Vector2(27*u,17*u),Color("#FFFDF4",0.86))
	draw_rect(Rect2(0,h*.46,w,h*.54),Color("#87CD77"))
	draw_rect(Rect2(0,h*.56,w,h*.44),Color("#93D47D"))
	for i in range(int(ceil(w/115.0))+2):
		var x=35.0+float(i)*115.0
		_pine(x,h*.56,u*.68)
	# A continuous winding lane and a fixed-height fence instead of broken strips.
	var path=PackedVector2Array()
	for i in range(int(ceil(w/55.0))+2):
		var x=float(i)*55.0
		path.append(Vector2(x,h*.67+sin(x/240.0)*20*u))
	draw_polyline(path,Color("#E8BE7D"),91*u,true)
	draw_polyline(path,Color("#F6D59A"),80*u,true)
	_fence(0,w,h*.60,u*.72)
	# Repeating objects use fixed world x locations, never percentages of w.
	var segment_count=int(ceil(w/1500.0))
	for segment in range(segment_count):
		var origin=float(segment)*1500.0
		_tree(origin+230*u,h*.66,u*.85)
		_garden(origin+680*u,h*.84,u*.80)
		_barn(origin+1145*u,h*.66,u*.78)
		_windmill(origin+920*u,h*.57,u*.70)
		for i in range(2):
			var x=origin+(385.0+float(i)*575.0)*u
			_oval(Vector2(x,h*.73),Vector2(21*u,10*u),Color("#8EAF91"))
			_oval(Vector2(x-4*u,h*.70),Vector2(18*u,9*u),Color("#D2D7BC"))
	# Land decoration. A small pond is decorative; sea residents live in the
	# large, separately placed water habitat on the right side of the panorama.
	_pond(Vector2(125*u,h*.88),Vector2(125*u,31*u),u*.65)
	# The real water region exactly matches PrivateFarm's ocean roaming bounds.
	_pond(Vector2(w*.774,h*.73),Vector2(w*.172,h*.21),u)
	# In the ocean portion, cover the distant crop/barn decoration with wetlands.
	for i in range(28):
		var x=w*.625+float(i)*w*.29/28.0
		var y=h*(.72+.08*float((i*7)%9)/9.0)
		_line(Vector2(x,y+8*u),Vector2(x+3*u,y-15*u),Color("#3F9B6C"),3*u)
		_oval(Vector2(x+3*u,y-16*u),Vector2(3*u,8*u),Color("#BDB57B"))
	# Light foreground blossoms and stones avoid obscuring touchable animals.
	for i in range(int(w/75.0)+1):
		var x=17.0+float(i)*75.0
		var y=h*(.94-.045*float((i*3)%5)/5.0)
		if x>w*.65 and x<w*.91:
			continue
		_flower(x,y,u*.68,Color("#FFF2EB") if i%3 else Color("#F8AFB6"))
		if i%5==0:
			_oval(Vector2(x+29*u,y+8*u),Vector2(16*u,6*u),Color("#77AA73",.55))
