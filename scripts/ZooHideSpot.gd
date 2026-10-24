extends "res://scripts/OceanHideSpot.gd"
## Zoo hiding places share reveal animation and touch-safe hitboxes.
func _draw() -> void:
	var unit=minf(size.x/200.0,size.y/175.0)
	draw_set_transform(Vector2(size.x*.5,size.y*.54),0,Vector2(unit,unit))
	match cover_type:
		"bush":
			_ell(-51,35,50,40,Color("#72BB7B"))
			_ell(37,26,54,50,Color("#5EA970"))
			_ell(1,-5,51,45,Color("#8BC985"))
			_ell(0,73,92,15,Color("#BDA078"))
		"rock":
			_ell(-46,46,43,45,Color("#ACADAA"))
			_ell(36,36,52,55,Color("#899DA2"))
			_ell(0,61,33,29,Color("#CFCEBE"))
		"tree":
			draw_line(Vector2(0,80),Vector2(5,-51),Color("#A47C52"),21,true)
			_ell(-46,-54,53,37,Color("#7DBC7A"))
			_ell(27,-70,59,49,Color("#5DAD7C"))
			_ell(0,-94,48,31,Color("#98CD80"))
		"hay":
			for i in range(5):
				var x=-65+float(i)*32
				_ell(x,40-float(i%2)*8,33,38,Color("#EAC17C"))
				draw_line(Vector2(x-11,21),Vector2(x+13,56),Color("#CB9B5E"),2,true)
			_ell(0,72,90,17,Color("#D7AD76"))
		"sign":
			draw_line(Vector2(0,85),Vector2(0,-60),Color("#A97951"),15,true)
			_ell(0,-35,87,50,Color("#DDAE7C"))
			_ell(0,-35,72,36,Color("#FFF1D5"))
			_ell(0,72,69,16,Color("#88B57A"))
		"pond":
			_ell(0,62,98,35,Color("#7AA8BD"))
			_ell(0,59,86,27,Color("#83C9D3"))
			_ell(-58,25,25,32,Color("#83B785"))
			_ell(47,29,31,32,Color("#6BAB74"))
	if revealed:
		draw_arc(Vector2.ZERO,88,0,TAU,35,Color("#FFF1A6",0.86),5,true)
	elif hint:
		draw_arc(Vector2.ZERO,91,0,TAU,35,Color("#FFDE65"),10,true)
		_ell(0,-98,13,13,Color("#FFF2AA"))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
