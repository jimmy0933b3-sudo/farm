extends Control
## Always-visible, original vector illustrations for pre-reader choice cards.
## Do not rely on fonts or emoji to explain food, habitats or home navigation.
var item_id: String = "farm"

func setup(id: String) -> void:
	item_id = id
	queue_redraw()

func _oval(x: float, y: float, rx: float, ry: float, color: Color) -> void:
	var pts = PackedVector2Array()
	for n in range(36):
		var rad = TAU * float(n) / 36.0
		pts.append(Vector2(x + cos(rad) * rx, y + sin(rad) * ry))
	draw_colored_polygon(pts, color)

func _shape(points: Array, color: Color) -> void:
	var pts = PackedVector2Array()
	for point in points:
		pts.append(point)
	draw_colored_polygon(pts,color)

func _line(a: Vector2, b: Vector2, color: Color, width: float = 5.0) -> void:
	draw_line(a,b,color,width,true)

func _draw() -> void:
	var unit = minf(size.x / 220.0,size.y / 185.0)
	if unit <= 0.0:
		return
	draw_set_transform(Vector2(size.x*0.5,size.y*0.54),0.0,Vector2(unit,unit))
	match item_id:
		"昆蟲":
			_oval(0,17,43,60,Color("#80694D"))
			_oval(0,-35,30,25,Color("#80694D"))
			_oval(-14,-41,5,5,Color.WHITE)
			_oval(14,-41,5,5,Color.WHITE)
			for j in range(3):
				var y=-19.0+float(j)*34.0
				_line(Vector2(-33,y),Vector2(-79,y-23),Color("#80694D"),5.0)
				_line(Vector2(33,y),Vector2(79,y-23),Color("#80694D"),5.0)
		"根莖":
			for j in range(4):
				var x=-64.0+float(j)*42.0
				_shape([Vector2(x-18,-14),Vector2(x+19,-14),Vector2(x,75)],Color("#F0A355"))
				_oval(x-9,-27,18,25,Color("#69BA7D"))
				_oval(x+10,-28,14,25,Color("#58A469"))
		"香蕉":
			_oval(-7,18,76,63,Color("#E9BF4A"))
			_oval(1,-2,66,51,Color("#FFF4E5"))
			_oval(-8,39,55,29,Color("#F1C854"))
			_oval(57,-27,9,12,Color("#9F8051"))
		"牧草", "乾草", "葉子":
			for i in range(7):
				var x = -74.0 + i*25.0
				_line(Vector2(x,55),Vector2(x+12,-43 - i%3*8),Color("#489856"),6.0)
				_oval(x+3,-14,10,24,Color("#80C468"))
				_oval(x+23,-31,12,26,Color("#4BAE6C"))
			_oval(0,66,92,15,Color("#B78E58"))
		"肉":
			_oval(0,30,91,56,Color("#D87370"))
			_oval(-10,20,69,40,Color("#F09491"))
			_oval(22,15,23,23,Color("#FFF0DD"))
			_oval(22,15,13,13,Color("#CEB09F"))
		"青草":
			_oval(0,73,105,15,Color("#A3C77B"))
			for i in range(8):
				var x=-76.0+float(i)*23.0
				_shape([Vector2(x-9,69),Vector2(x+9,69),Vector2(x+8,-20-float(i%3)*12)],Color("#5CAD6E"))
				_shape([Vector2(x-8,64),Vector2(x+4,72),Vector2(x-16,-36)],Color("#79C889"))
		"魚":
			_oval(0,12,83,51,Color("#78BCE0"))
			_shape([Vector2(-69,11),Vector2(-111,-26),Vector2(-111,53)],Color("#5BA0CC"))
			_oval(54,-5,7,9,Color("#344E5D"))
			_oval(-13,12,7,43,Color("#EAF9FB"))
		"飼料":
			_oval(0,32,83,31,Color("#678EBC"))
			_shape([Vector2(-79,17),Vector2(79,17),Vector2(59,75),Vector2(-59,75)],Color("#85B3DE"))
			_oval(0,18,79,24,Color("#805A35"))
			for p in [Vector2(-40,6),Vector2(-12,-1),Vector2(20,10),Vector2(52,1),Vector2(-26,28),Vector2(18,28)]:
				_oval(p.x,p.y,14,9,Color("#C69A5E"))
		"穀粒", "堅果":
			_oval(0,57,88,14,Color("#DAC38B"))
			for i in range(9):
				var x=-64.0+float(i)*16.0
				_oval(x,25-abs(i-4)*4,10,24,Color("#F2BF42") if item_id=="穀粒" else Color("#B77A4C"))
				_line(Vector2(x,3),Vector2(x+7,-12),Color("#8B9951"),3.0)
		"巧克力":
			draw_rect(Rect2(-77,-53,154,106),Color("#A76C55"))
			draw_rect(Rect2(-66,-42,132,84),Color("#5D352F"))
			for n in range(1,3):
				_line(Vector2(-65+n*44,-41),Vector2(-65+n*44,40),Color("#AB725B"),4.0)
			_line(Vector2(-65,-2),Vector2(65,-2),Color("#AB725B"),4.0)
		"糖果":
			_shape([Vector2(-85,-18),Vector2(-109,-47),Vector2(-109,44),Vector2(-82,18)],Color("#86D2DB"))
			_shape([Vector2(85,-18),Vector2(109,-47),Vector2(109,44),Vector2(82,18)],Color("#86D2DB"))
			_oval(0,0,85,49,Color("#F58EB2"))
			for n in range(4):
				_oval(-49+n*32,0,9,22,Color("#FFE3ED"))
		"洋蔥":
			_oval(0,18,66,72,Color("#C3A0DF"))
			_shape([Vector2(-24,-43),Vector2(0,-86),Vector2(24,-43)],Color("#B38DCE"))
			for n in range(3):
				_line(Vector2(-18+n*18,-40),Vector2(-18+n*18,73),Color("#A379BB"),3.0)
		"果實", "蘋果":
			_oval(-29,8,43,59,Color("#E95B58"))
			_oval(27,8,44,59,Color("#F36B5D"))
			_line(Vector2(2,-46),Vector2(10,-72),Color("#79694B"),7.0)
			_oval(31,-57,22,11,Color("#5CB66C"))
		"汽水":
			_shape([Vector2(-57,-55),Vector2(57,-55),Vector2(42,76),Vector2(-42,76)],Color("#86CDEA"))
			_line(Vector2(24,-35),Vector2(45,-91),Color("#E85D69"),8.0)
			_line(Vector2(45,-91),Vector2(70,-91),Color("#E85D69"),8.0)
			_oval(0,-55,63,12,Color("#DAF4F9"))
		"zoo_search":
			# Zoo hide-and-seek: a magnifying glass, tall giraffe-like tree
			# silhouette and a lion face. Separate from the park entrance.
			_oval(0,65,104,24,Color("#A4CB84"))
			_oval(-22,12,58,55,Color("#E6B877"))
			_oval(-22,12,42,41,Color("#F8D399"))
			_oval(-37,0,6,7,Color("#45565D"))
			_oval(-7,0,6,7,Color("#45565D"))
			_oval(-22,22,8,6,Color("#7F5949"))
			_oval(61,-40,43,42,Color("#A7D5E0"))
			_oval(61,-40,30,29,Color("#E9F6E8"))
			_line(Vector2(87,-12),Vector2(119,32),Color("#C58C63"),12)
			_oval(55,-43,7,8,Color("#6E927B"))
			_oval(72,-40,7,8,Color("#6E927B"))
		"zoo":
			# Zoo entrance with lion, elephant and a friendly archway.
			_oval(0,73,110,26,Color("#92C88E"))
			_shape([Vector2(-101,49),Vector2(-101,-58),Vector2(101,-58),Vector2(101,49)],Color("#E8B78D"))
			_shape([Vector2(-83,45),Vector2(-83,-40),Vector2(83,-40),Vector2(83,45)],Color("#F6E3B9"))
			_oval(-39,2,47,53,Color("#C78C52"))
			_oval(-39,2,36,42,Color("#F2C982"))
			_oval(-53,-12,5,7,Color("#4D5C55"))
			_oval(-25,-12,5,7,Color("#4D5C55"))
			_oval(-39,14,8,6,Color("#72514B"))
			_oval(37,5,33,42,Color("#A6B5C0"))
			_oval(17,-23,19,30,Color("#91A7B7"))
			_oval(56,-23,19,30,Color("#91A7B7"))
			_line(Vector2(53,19),Vector2(56,60),Color("#9BABB9"),16)
			_oval(23,-6,4,6,Color("#384C52"))
			_oval(52,-6,4,6,Color("#384C52"))
		"ocean_park":
			# A different home icon from ocean searching: smiling sea friends.
			_oval(0,60,105,44,Color("#7DD6E1"))
			_oval(-39,19,50,39,Color("#F49D62"))
			_shape([Vector2(-77,18),Vector2(-103,-8),Vector2(-103,47)],Color("#E97A63"))
			_oval(-47,6,6,6,Color("#33566B"))
			_oval(52,-5,49,39,Color("#7CB4D2"))
			_shape([Vector2(27,-32),Vector2(46,-76),Vector2(65,-31)],Color("#629CBF"))
			_oval(69,-18,6,7,Color("#2B5362"))
			_oval(77,-44,9,9,Color("#E2FAFB"))
			_oval(90,-68,6,6,Color("#E2FAFB"))
			for j in range(4):
				var x=-75+float(j)*50
				_line(Vector2(x,91),Vector2(x+8,67),Color("#3DAE9C"),7)
				_oval(x+9,75,8,14,Color("#77CEB0"))
		"ocean":
			# Oversized unmistakable fish icon with coral and bubbles.
			_oval(0,38,108,78,Color("#55BCD7"))
			_oval(-28,30,65,38,Color("#F39B60"))
			_shape([Vector2(-74,31),Vector2(-115,-1),Vector2(-115,67)],Color("#E97A63"))
			for i in range(3):
				_oval(-48+float(i)*31,30,8,35,Color.WHITE)
			_oval(15,18,8,8,Color("#294757"))
			for i in range(3):
				_oval(44+float(i)*19,-34-float(i%2)*20,10,10,Color("#E5FAFE"))
			for i in range(6):
				var xx=-87+float(i)*35
				_line(Vector2(xx,93),Vector2(xx+float(i%2)*13,58),Color("#2FA982"),8)
				_oval(xx+8,72,11,19,Color("#69CBA3"))
		"drawing":
			# Pencil, tracing dots, portrait and decorative stars.
			_oval(0,67,102,28,Color("#BED7E9"))
			_oval(-25,-8,70,68,Color("#FFFCF0"))
			_oval(-58,-70,19,31,Color("#B9C6E5"))
			_oval(18,-70,19,31,Color("#B9C6E5"))
			_oval(-20,-8,52,54,Color("#DEE8FA"))
			_oval(-39,-20,6,7,Color("#36516B"))
			_oval(1,-20,6,7,Color("#36516B"))
			_oval(-20,-1,8,6,Color("#E4A6AB"))
			_line(Vector2(40,71),Vector2(89,-62),Color("#EAA665"),18)
			_shape([Vector2(80,-62),Vector2(93,-95),Vector2(103,-54)],Color("#486C9E"))
			for i in range(5):
				_oval(-72+float(i)*24,72-float(i%2)*7,4,4,Color("#4AACC2"))
			_shape([Vector2(-79,-45),Vector2(-72,-59),Vector2(-65,-45),Vector2(-51,-42),Vector2(-65,-37),Vector2(-72,-23)],Color("#F2C86D"))
		"coloring":
			# Crayon + black outline rabbit for the separate homepage tile.
			_oval(-16,39,63,65,Color.WHITE)
			draw_arc(Vector2(-16,39),64,0,TAU,40,Color("#374553"),4.5,true)
			_oval(-49,-51,14,52,Color.WHITE)
			_oval(17,-51,14,52,Color.WHITE)
			draw_arc(Vector2(-49,-51),53,PI*0.40,PI*1.65,20,Color("#374553"),3,true)
			_oval(-35,21,5,6,Color("#374553"))
			_oval(0,21,5,6,Color("#374553"))
			_oval(-17,43,7,5,Color("#374553"))
			_line(Vector2(35,73),Vector2(77,-62),Color("#ED9C54"),26)
			_shape([Vector2(62,-68),Vector2(89,-94),Vector2(95,-47)],Color("#5B8EDE"))
			_oval(44,65,17,16,Color("#ED9C54"))
			_oval(-57,66,18,13,Color("#6CC6F0"))
			_oval(-71,61,8,8,Color("#F16D91"))
		"private_farm":
			# Unique homepage tile with a fence, farmhouse and animal friends.
			_oval(0,71,106,28,Color("#84CA88"))
			_shape([Vector2(-91,-6),Vector2(0,-79),Vector2(91,-6)],Color("#E49380"))
			draw_rect(Rect2(-80,-6,160,76),Color("#FBE1B8"))
			for x in [-67.0,-22.0,23.0,68.0]:
				draw_rect(Rect2(x-5,31,10,48),Color("#AB8058"))
			_line(Vector2(-80,47),Vector2(80,47),Color("#AB8058"),7.0)
			_oval(-30,3,31,29,Color("#FFF7E9"))
			_oval(34,3,27,29,Color("#E8B095"))
			_oval(-39,-25,11,24,Color("#FFF7E9"))
			_oval(-18,-25,11,24,Color("#FFF7E9"))
			_oval(-37,0,4,4,Color("#3C5250"))
			_oval(-21,0,4,4,Color("#3C5250"))
			_oval(27,0,4,4,Color("#3C5250"))
			_oval(41,0,4,4,Color("#3C5250"))
			_oval(3,-72,9,10,Color("#ED8596"))
			_oval(20,-72,9,10,Color("#ED8596"))
			_shape([Vector2(-6,-71),Vector2(29,-71),Vector2(11,-51)],Color("#ED8596"))
		"forest_explore":
			# A standalone illustrated forest icon: magnifying glass, trees and rabbit ears.
			_oval(-49,32,33,48,Color("#4FA774"))
			_oval(12,-25,55,64,Color("#4AAE7A"))
			_oval(62,16,34,44,Color("#62BD86"))
			_line(Vector2(-55,85),Vector2(-13,32),Color("#C79462"),17.0)
			draw_arc(Vector2(24,-10),57.0,0,TAU,40,Color("#FAE5AE"),11.0,true)
			_oval(22,-17,26,29,Color("#FFF4DB"))
			_oval(3,-49,11,30,Color("#FFF4DB"))
			_oval(40,-49,11,30,Color("#FFF4DB"))
			_oval(11,-19,4,6,Color("#40594D"))
			_oval(33,-19,4,6,Color("#40594D"))
		"forest_seek":
			# Magnifying glass and a leafy tree for non-readers.
			draw_line(Vector2(-55,59),Vector2(-6,10),Color("#9B8067"),18.0,true)
			_oval(23,-14,48,48,Color("#D8FAEC"))
			draw_arc(Vector2(23,-14),49.0,0.0,TAU,36,Color("#549E83"),11.0,true)
			draw_rect(Rect2(16,-10,15,55),Color("#89694F"))
			_oval(23,-40,34,32,Color("#4BB479"))
			_oval(2,-24,23,24,Color("#8CDD9D"))
			_oval(42,-26,25,27,Color("#6CCA8C"))
		"farm":
			_oval(0,76,110,45,Color("#8FD19A"))
			draw_rect(Rect2(-65,-4,130,78),Color("#EA8B7D"))
			_shape([Vector2(-78,-5),Vector2(0,-78),Vector2(78,-5)],Color("#B65355"))
			draw_rect(Rect2(-20,28,40,46),Color("#FFF0C2"))
			_line(Vector2(-19,51),Vector2(20,51),Color("#CC9A73"),4.0)
		"forest":
			_oval(0,80,115,31,Color("#9DDAA8"))
			for x in [-65.0,0.0,65.0]:
				draw_rect(Rect2(x-10,-13,20,92),Color("#946B4C"))
				_oval(x,-40,43,56,Color("#4EAB77"))
				_oval(x-20,-55,27,38,Color("#7FD197"))
		"ocean":
			draw_rect(Rect2(-105,-80,210,160),Color("#86DCEF"))
			_oval(-44,8,48,25,Color("#76BCD9"))
			_shape([Vector2(-2,9),Vector2(38,-29),Vector2(35,46)],Color("#76BCD9"))
			_oval(-63,1,5,6,Color("#334B69"))
			for y in [42.0,65.0]:
				_line(Vector2(-104,y),Vector2(104,y),Color("#FFF9EF"),5.0)
		"feed":
			_oval(0,58,82,25,Color("#92B7DE"))
			_oval(0,44,70,13,Color("#B4D0F0"))
			_oval(-30,12,16,40,Color("#F1953D"))
			_oval(5,-7,16,45,Color("#E98332"))
			_oval(42,16,14,36,Color("#F1AA4D"))
			for x in [-34.0,5.0,43.0]:
				_oval(x,-30,10,20,Color("#76B576"))
		"wash":
			_oval(0,55,76,31,Color("#95CBE7"))
			_oval(0,37,70,18,Color("#D5F1F9"))
			for p in [Vector2(-50,-15),Vector2(20,-43),Vector2(58,4),Vector2(-8,-60)]:
				_oval(p.x,p.y,15,15,Color("#A1DCE9"))
				_oval(p.x-5,p.y-5,5,5,Color.WHITE)
		"play":
			_oval(0,3,64,65,Color("#E9A5A5"))
			for i in range(4):
				draw_arc(Vector2(0,3),64.0,TAU*float(i)/4.0,TAU*float(i+1)/4.0,12,Color("#FCDF94"),9.0,true)
			_oval(0,3,17,17,Color("#FFF7E5"))
		"sleep":
			_oval(0,30,82,44,Color("#C7B2ED"))
			_oval(-29,0,35,31,Color("#FFF1DB"))
			_shape([Vector2(16,2),Vector2(64,-16),Vector2(75,58),Vector2(-15,58)],Color("#A6D9EC"))
			_oval(49,-58,15,19,Color("#F9D65D"))
			_oval(57,-65,10,14,Color("#A9E5F2"))
		"care":
			_shape([Vector2(-85,-19),Vector2(0,-88),Vector2(85,-19)],Color("#E7848D"))
			draw_rect(Rect2(-72,-20,144,100),Color("#FFE9C9"))
			draw_rect(Rect2(-27,14,54,66),Color("#B78BC7"))
			_oval(-32,-53,29,26,Color("#ED91A3"))
			_oval(32,-53,29,26,Color("#ED91A3"))
			_shape([Vector2(-60,-47),Vector2(60,-47),Vector2(0,17)],Color("#ED91A3"))
		"album":
			draw_rect(Rect2(-91,-65,90,133),Color("#9DC9ED"))
			draw_rect(Rect2(1,-65,90,133),Color("#B6D8F3"))
			_line(Vector2(0,-65),Vector2(0,70),Color("#6788AA"),6.0)
			_oval(-44,-9,25,24,Color("#E69FAA"))
			_oval(45,13,25,26,Color("#EED47E"))
			_oval(-48,-50,6,7,Color("#FFFDF6"))
			_oval(48,-38,6,7,Color("#FFFDF6"))
		_:
			_oval(0,0,61,61,Color("#D7EFD8"))
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
