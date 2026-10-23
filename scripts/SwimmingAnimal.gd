extends "res://scripts/RoamingAnimal.gd"
## Underwater residents: only swim in pond bounds, never walk on grass.
var bubble_phase: float=0.0

func _process(delta: float) -> void:
	step_time+=delta
	bubble_phase+=delta
	pet_cooldown=maxf(0.0,pet_cooldown-delta)
	if not is_touched and reaction_time<=0.0:
		if idle_timer>0.0:
			idle_timer-=delta
			walking=false
		else:
			if position.distance_to(destination)<2.0:
				idle_timer=rng.randf_range(0.4,1.6)
				_new_destination()
			else:
				walking=true
				var diff=destination-position
				position=_clamp_to_field(position.move_toward(destination,walk_speed*delta))
				if absf(diff.x)>3.0:
					avatar.pivot_offset=avatar.size*0.5
					avatar.scale.x=1.0 if diff.x>0.0 else -1.0
		avatar.set("mood","happy" if heart_time>0.0 else "idle")
	if reaction_time>0.0:
		reaction_time=maxf(0.0,reaction_time-delta)
		effects.set("phase",1.0-reaction_time/1.65)
		effects.queue_redraw()
		if reaction_time<=0.0:
			reaction_action=""
			effects.set("action","")
			avatar.set("mood","idle")
			reaction_finished.emit(animal_id)
	if heart_time>0.0:
		heart_time=maxf(0.0,heart_time-delta)
	avatar.position.y=0.0 if reduce_motion else sin(bubble_phase*2.1+float(animal_id.hash()%23))*2.4
	avatar.queue_redraw()
	queue_redraw()

func _draw() -> void:
	# No ground shadow. Bubble trail establishes swimming movement.
	var center=size*0.5
	if selected:
		draw_arc(center,38,0,TAU,28,Color("#FFF1A5",0.95),3,true)
	for i in range(3):
		var y=fmod(bubble_phase*16.0+float(i)*19.0,65.0)
		draw_arc(Vector2(size.x*.15+float(i%2)*6,size.y*.90-y),5.0+float(i%2)*2,0,TAU,18,Color("#E3FBFF",0.68),1.5,true)
	if heart_time>0.0:
		draw_circle(Vector2(center.x,center.y-34-heart_time*4),7,Color("#F89CAD",heart_time))
