extends Control
## Lightweight 2D sparkles, colorful score banners and confetti.
## Particle positions are local to the race viewport, never block touch input.
var particles: Array = []
var banner: String = ""
var banner_seconds: float = 0.0
var reduce_motion: bool = false
var clock: float = 0.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_process(true)

func cheer(kind: String, where: Vector2) -> void:
	match kind:
		"star": banner="⭐ +1 星星！"
		"boost": banner="⚡ 超級加速！"
		"shield": banner="🛡️ 護盾開啟！"
		"bump": banner="🌾 慢慢開，沒關係！"
		"go": banner="🏁 出發！"
		"pass": banner="🏎️ 超車成功！"
		"finish": banner="🏆 完成比賽！"
		_: banner=""
	banner_seconds=1.0 if kind!="finish" else 3.0
	if reduce_motion:
		queue_redraw()
		return
	var palette: Array = [
		Color("#FFE36F"),Color("#FC91A9"),Color("#98E5D1"),Color("#95CAEF")]
	var count: int = 26 if kind=="finish" else 12
	for i in range(count):
		var a: float=TAU*float(i)/float(count)
		var speed: float=70.0+float(i%6)*16.0
		particles.append({"p":where,"v":Vector2(cos(a)*speed,sin(a)*speed-40),
			"life":.7+float(i%5)*.12,"max":1.16,"color":palette[i%4]})

func _process(dt: float) -> void:
	var delta: float=minf(dt,.08)
	clock+=delta
	banner_seconds=maxf(0.0,banner_seconds-delta)
	for i in range(particles.size()-1,-1,-1):
		var item: Dictionary=particles[i]
		item["life"]=float(item["life"])-delta
		if float(item["life"])<=0.0:
			particles.remove_at(i)
			continue
		item["p"]=Vector2(item["p"])+Vector2(item["v"])*delta
		item["v"]=Vector2(item["v"])+Vector2(0,135)*delta
		particles[i]=item
	queue_redraw()

func _draw() -> void:
	for item in particles:
		var p: Vector2=item["p"]
		var ratio: float=clampf(float(item["life"])/float(item["max"]),.1,1)
		var color: Color=item["color"]
		color.a=ratio
		draw_circle(p,5*ratio,color)
		draw_circle(p+Vector2(-1,-2),1.5*ratio,Color.WHITE)
