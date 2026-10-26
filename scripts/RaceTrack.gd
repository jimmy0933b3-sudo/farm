extends Control
## Procedural vertical-scrolling kart track. All scenery stays offline.
var track_id: String = "farm"
var scroll: float = 0.0
var reduce_motion: bool = false

func setup(id: String, gentle: bool) -> void:
	track_id = id
	reduce_motion = gentle
	queue_redraw()

func lane_center(lane: int) -> float:
	var w: float = minf(size.x * 0.70, 560.0)
	return size.x * 0.5 - w * 0.5 + w * (float(lane) + 0.5) / 3.0

func road_edges() -> Vector2:
	var w: float = minf(size.x * 0.70, 560.0)
	return Vector2((size.x-w)*0.5,(size.x+w)*0.5)

func _draw() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	var colors = {
		"farm": [Color("#ACE09B"),Color("#CEB28D"),Color("#6DAA59")],
		"flower": [Color("#F6CBDD"),Color("#B8BF97"),Color("#EA99B8")],
		"rainbow": [Color("#A2D6F9"),Color("#DED2C6"),Color("#70BFE6")]
	}
	var c: Array = colors.get(track_id,colors["farm"])
	draw_rect(Rect2(Vector2.ZERO,size),c[0])
	var edges: Vector2 = road_edges()
	var left: float = edges.x
	var width: float = edges.y-edges.x
	draw_rect(Rect2(left-14,0,width+28,size.y),Color("#FFFFFF"))
	draw_rect(Rect2(left,0,width,size.y),c[1])
	draw_line(Vector2(left,0),Vector2(left,size.y),Color("#FFFFFF"),6.0)
	draw_line(Vector2(left+width,0),Vector2(left+width,size.y),Color("#FFFFFF"),6.0)
	# Child-visible stripes plus recognizable scenery. This is not a real
	# perspective projection, so swiping always picks the intended lane.
	for divider in [1,2]:
		var x: float = left+width*float(divider)/3.0
		var k: int = -1
		while k < 9:
			var y: float = float(k)*95.0+fposmod(scroll,95.0)
			draw_line(Vector2(x,y),Vector2(x,y+49.0),Color("#FFFDF0",0.90),5.0)
			k += 1
	var period: float = 115.0
	for i in range(-1,10):
		var y: float = float(i)*period+fposmod(scroll*0.63,period)
		for side in [-1,1]:
			var x: float = (left-53.0) if side==-1 else (left+width+53.0)
			if track_id=="farm":
				# Round haystacks and apple trees.
				draw_circle(Vector2(x,y+8),19.0,c[2])
				draw_rect(Rect2(x-5,y+11,10,28),Color("#8D6844"))
				draw_circle(Vector2(x+6,y+1),5,Color("#E66D62"))
			elif track_id=="flower":
				for petal in range(5):
					var angle: float = float(petal)*TAU/5.0
					draw_circle(Vector2(x+cos(angle)*12,y+sin(angle)*12),10,c[2])
				draw_circle(Vector2(x,y),8,Color("#FFEE87"))
			else:
				draw_circle(Vector2(x,y),18,c[2])
				draw_circle(Vector2(x+5,y-7),8,Color("#FFE1A6"))
				draw_line(Vector2(x-10,y+17),Vector2(x+10,y+30),Color.WHITE,3.0)
	if track_id=="rainbow":
		for a in range(3):
			var y: float = fposmod(scroll*0.35+float(a)*220.0,size.y+220.0)
			draw_arc(Vector2(size.x*0.5,y),size.x*0.36,PI,TAU,36,
				[Color("#F56E86"),Color("#EEC65D"),Color("#78C7E1")][a],7.0)
