extends Control
## A simple illustrated guiding hand; drawn above the animal without external sprites.
var hand_position: Vector2 = Vector2.ZERO
var show_hand: bool = true
var celebrating: bool = false
var effect_time: float = 0.0
var progress: float = 0.0

func _draw() -> void:
	if show_hand:
		var position_to_draw = hand_position
		if position_to_draw == Vector2.ZERO:
			position_to_draw = Vector2(size.x * 0.42, size.y * 0.32)
		draw_set_transform(position_to_draw, -0.22, Vector2(1.05,1.05))
		# Outlined four fingers and a round palm. The fingertip follows the child's touch.
		var border = Color("#AC735C")
		var skin = Color("#FCE0B7")
		draw_circle(Vector2(2,37),31,border)
		draw_circle(Vector2(2,37),27,skin)
		for i in range(4):
			var x = -22.0 + i*15.0
			draw_line(Vector2(x,29), Vector2(x,-20.0+(abs(i-1.5)*7.0)),border,17.0,true)
			draw_line(Vector2(x,29), Vector2(x,-20.0+(abs(i-1.5)*7.0)),skin,12.5,true)
		draw_line(Vector2(-17,49),Vector2(-37,15),border,19.0,true)
		draw_line(Vector2(-17,49),Vector2(-37,15),skin,14.0,true)
		draw_circle(Vector2(2,47),20,skin)
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	if celebrating:
		var center = hand_position
		for i in range(4):
			var t = float(i)*1.4 + effect_time*1.5
			var px = center.x + sin(t)*55.0
			var py = center.y - 35.0 - effect_time*52.0 - float(i%2)*12.0
			var heart = Color("#F07F97",clampf(1.0-effect_time/1.1,0.0,1.0))
			draw_circle(Vector2(px-7,py-2),9,heart)
			draw_circle(Vector2(px+7,py-2),9,heart)
			var poly = PackedVector2Array([Vector2(px-16,py),Vector2(px+16,py),Vector2(px,py+19)])
			draw_colored_polygon(poly,heart)
	if progress > 0.01 and show_hand:
		draw_arc(Vector2(size.x*0.5,size.y*0.12),26.0,-PI*0.5,-PI*0.5+TAU*progress,24,Color("#F5A4A6"),6.0,true)
