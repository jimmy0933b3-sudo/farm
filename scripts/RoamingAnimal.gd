extends Control
## One small roaming resident in the personal farm.
## The farm owns touch events so children do not steal Android drag gestures.
signal petted(animal_id: String)
signal reaction_finished(animal_id: String)

const AnimalArt = preload("res://scripts/AnimalArt.gd")
const CareEffects = preload("res://scripts/CareEffects.gd")

var animal_info: Dictionary = {}
var animal_id: String = ""
var reduce_motion: bool = false
var is_flying: bool = false
var avatar: Control
var effects: Control
var rng := RandomNumberGenerator.new()
var roaming_bounds: Rect2 = Rect2(0, 0, 600, 300)
var destination: Vector2 = Vector2.ZERO
var walking: bool = false
var is_touched: bool = false
var walk_speed: float = 25.0
var idle_timer: float = 0.0
var step_time: float = 0.0
var reaction_time: float = 0.0
var reaction_action: String = ""
var heart_time: float = 0.0
var stroke_distance: float = 0.0
var pet_cooldown: float = 0.0
var strokes: int = 0
var selected: bool = false
var reaction_variant: int=0

func setup(info: Dictionary, gentle_motion: bool = false) -> void:
	animal_info = info
	animal_id = str(info.get("id", ""))
	reduce_motion = gentle_motion
	is_flying = bool(info.get("flies",false))
	rng.seed = abs(animal_id.hash()) + 93
	walk_speed = 62.0 if is_flying else (33.0 if animal_id in ["rabbit", "squirrel", "guinea_pig"] else 23.0)
	if animal_id == "snake":
		walk_speed = 17.0
	if reduce_motion:
		walk_speed *= 0.35

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ZERO
	size = Vector2(82, 88)
	avatar = AnimalArt.new()
	avatar.setup(animal_info)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(avatar)
	effects = CareEffects.new()
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(effects)
	idle_timer = rng.randf_range(0.35, 1.6)
	set_process(true)

func set_bounds(bounds: Rect2, initial_position: Vector2 = Vector2(-1, -1)) -> void:
	roaming_bounds = bounds
	if initial_position.x >= 0.0:
		position = _clamp_to_field(initial_position)
	else:
		position = _clamp_to_field(position)
	_new_destination()

func _clamp_to_field(candidate: Vector2) -> Vector2:
	return Vector2(
		clampf(candidate.x, roaming_bounds.position.x, maxf(roaming_bounds.position.x, roaming_bounds.end.x-size.x)),
		clampf(candidate.y, roaming_bounds.position.y, maxf(roaming_bounds.position.y, roaming_bounds.end.y-size.y))
	)

func _new_destination() -> void:
	destination = _clamp_to_field(
		position + Vector2(rng.randf_range(-235.0,235.0) if is_flying else rng.randf_range(-145.0,145.0),
		rng.randf_range(-52.0,52.0) if is_flying else rng.randf_range(-85.0,85.0))
	)
	walking = true

func _process(delta: float) -> void:
	if not is_touched and reaction_time <= 0.0:
		if idle_timer > 0.0:
			idle_timer -= delta
			walking = false
		else:
			var diff = destination-position
			if diff.length() <= 2.0:
				idle_timer = rng.randf_range(0.05,0.24) if is_flying else rng.randf_range(0.65, 2.4)
				walking = false
				avatar.set("mood","blink")
			else:
				walking = true
				position = _clamp_to_field(position.move_toward(destination, walk_speed*delta))
				if absf(diff.x) > 3.0:
					avatar.pivot_offset = avatar.size*0.5
					avatar.scale.x = 1.0 if diff.x >= 0.0 else -1.0
		if idle_timer <= 0.0 and not walking:
			_new_destination()

	step_time += delta
	pet_cooldown = maxf(0.0,pet_cooldown-delta)
	if reaction_time > 0.0:
		reaction_time = maxf(0.0, reaction_time-delta)
		effects.set("phase",1.0-reaction_time/1.65)
		effects.queue_redraw()
		if reaction_time <= 0.0:
			reaction_action = ""
			effects.set("action","")
			avatar.set("mood","idle")
			reaction_finished.emit(animal_id)
	elif not is_touched:
		avatar.set("mood","happy" if heart_time > 0.0 else ("idle" if walking else ("blink" if fmod(step_time,4.8)<0.14 else "idle")))
	if heart_time > 0.0:
		heart_time = maxf(0.0,heart_time-delta)
	if not reduce_motion and not is_touched and reaction_time <= 0.0:
		avatar.position.y = sin(step_time*6.5)*5.0 if is_flying else (-absf(sin(step_time*8.0))*2.7 if walking else sin(step_time*1.5)*1.2)
		avatar.rotation = sin(step_time*9.0)*0.060 if is_flying else (sin(step_time*9.0)*0.052 if is_touched or heart_time>0.0 else (sin(step_time*4.0)*0.017 if walking else 0.0))
		avatar.scale = Vector2.ONE*(1.0+0.045*sin(step_time*13.0)) if is_flying else (Vector2.ONE*(1.0+0.024*sin(step_time*10.0)) if heart_time>0.0 else Vector2.ONE)
	else:
		avatar.position.y = 0.0
		avatar.rotation=0.0
		avatar.scale=Vector2.ONE
	avatar.queue_redraw()
	queue_redraw()

func distance_to_touch(point: Vector2) -> float:
	return (position+size*0.5).distance_to(point)

func contains_touch(point: Vector2) -> bool:
	var local = point-(position+size*0.5)
	return absf(local.x)<=size.x*0.60 and absf(local.y)<=size.y*0.60

func begin_pet() -> void:
	is_touched = true
	walking = false
	stroke_distance = 0.0
	tap_reaction()

func move_pet(distance: float) -> void:
	if not is_touched:
		return
	stroke_distance += minf(distance,65.0)
	if stroke_distance >= 42.0 and pet_cooldown <= 0.0:
		pet_cooldown = 0.55
		stroke_distance = 0.0
		heart_time = 1.15
		strokes += 1
		reaction_variant=strokes%3
		avatar.set("mood","surprised" if reaction_variant==1 else "happy")
		petted.emit(animal_id)

func end_pet() -> void:
	is_touched = false
	stroke_distance = 0.0
	idle_timer = rng.randf_range(0.65,1.4)

func tap_reaction() -> void:
	idle_timer = 1.3
	walking = false
	heart_time = 0.7
	avatar.set("mood","surprised")
	avatar.queue_redraw()

func perform(action: String) -> bool:
	if action not in ["feed","wash","play","sleep"]:
		return false
	reaction_time = 1.65
	reaction_action = action
	idle_timer = 0.8
	walking = false
	avatar.set("mood",{"feed":"eating","wash":"clean","play":"play","sleep":"sleep"}[action])
	effects.set("action",action)
	effects.set("phase",0.0)
	effects.queue_redraw()
	return true

func _draw() -> void:
	var center = size*0.5
	# Never paint a ground shadow under a flying insect. Land residents keep it.
	if not is_flying:
		var shadow = PackedVector2Array()
		for i in range(24):
			var a=TAU*float(i)/24.0
			shadow.append(Vector2(center.x+cos(a)*size.x*0.31,size.y*0.92+sin(a)*size.y*0.052))
		draw_colored_polygon(shadow,Color("#427A4B",0.27))
	if selected:
		draw_arc(center+Vector2(0,33),42,0,TAU,24,Color("#FFF6B6",0.9),3,true)
	if heart_time > 0.0:
		var rise=(1.15-heart_time)*25.0
		for n in range(2):
			var x=center.x+(-20 if n==0 else 24)
			var y=center.y-46-rise-(n*9)
			var color=Color("#E76C93",clampf(heart_time/0.65,0.0,1.0))
			draw_circle(Vector2(x-5,y),7,color)
			draw_circle(Vector2(x+5,y),7,color)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x-12,y+2),Vector2(x+12,y+2),Vector2(x,y+16)
			]),color)
