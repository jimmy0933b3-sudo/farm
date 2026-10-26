extends "res://scripts/OceanHideSpot.gd"
## Decorative hideouts never block touch panning; their parent handles taps.
func _draw() -> void:
	var unit=minf(size.x/200.0,size.y/175.0)
	draw_set_transform(Vector2(size.x*0.5,size.y*0.54),0,Vector2(unit,unit))
	match cover_type:
		"flower":
			draw_line(Vector2(0,78),Vector2(0,-45),Color("#4D9A63"),13,true)
			for i in range(7):
				var a=TAU*float(i)/7.0
				_ell(cos(a)*40,-38+sin(a)*40,29,27,Color("#F59AC1"))
			_ell(0,-38,20,19,Color("#F9D66D"))
		"leaf":
			draw_line(Vector2(-60,79),Vector2(58,-67),Color("#4F945A"),13,true)
			_ell(-32,7,54,43,Color("#7BC778"))
			_ell(29,-38,61,48,Color("#55AE78"))
		"log":
			_ell(0,46,95,42,Color("#8C644A"))
			_ell(-65,46,26,37,Color("#C6A078"))
			_ell(-65,46,17,26,Color("#E1C5A1"))
		"mushroom":
			for x in [-49.0,48.0]:
				draw_line(Vector2(x,79),Vector2(x,12),Color("#F7E6C8"),23,true)
				_ell(x,7,52,35,Color("#E77B77"))
				_ell(x-17,2,10,9,Color("#FFF5D9"))
				_ell(x+19,-3,10,9,Color("#FFF5D9"))
		"grass":
			for i in range(10):
				var x=-87.0+float(i)*19.0
				draw_line(Vector2(x,78),Vector2(x+(-1 if i%2==0 else 1)*27,-31-float(i%3)*18),Color("#5AAE70"),10,true)
				_ell(x,57,13,23,Color("#7CCD8D"))
		"soil":
			_ell(0,62,98,33,Color("#B88959"))
			_ell(-51,48,44,34,Color("#AD7D4F"))
			_ell(43,41,41,36,Color("#C1956B"))
			for i in range(6):
				var x=-75.0+float(i)*31.0
				draw_line(Vector2(x,79),Vector2(x+8,-20),Color("#69B274"),7,true)
			_ell(4,28,36,30,Color("#825737"))
			_ell(-8,19,10,7,Color("#AA784F"))
		"seedpod":
			# An eighth, unmistakable seed pod where the new weevil hides.
			draw_line(Vector2(-14,81),Vector2(18,-69),Color("#5C9669"),11,true)
			_ell(-32,-28,24,16,Color("#71B87A"))
			_ell(42,-43,27,15,Color("#58A06D"))
			_ell(0,14,60,40,Color("#9B704B"))
			_ell(-10,3,42,29,Color("#C99E68"))
			_ell(16,8,9,9,Color("#7C5435"))
		"hive":
			draw_line(Vector2(0,-89),Vector2(0,-45),Color("#8A795C"),13,true)
			_ell(0,15,69,70,Color("#E5B660"))
			for y in [-23.0,0.0,26.0,48.0]:
				draw_line(Vector2(-55,y),Vector2(55,y),Color("#BF883D"),5,true)
			_ell(0,26,20,13,Color("#805634"))
	if revealed:
		draw_arc(Vector2.ZERO,88,0,TAU,35,Color("#FFF1A6",0.9),5,true)
	elif hint:
		draw_arc(Vector2.ZERO,91,0,TAU,35,Color("#FFE06B"),10,true)
		_ell(0,-98,13,13,Color("#FFF2AA"))
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
