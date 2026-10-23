extends SceneTree
## A brush stroke is owned by exactly one shape, even when the child drags
## over the neighbor, leaves the silhouette and returns to the original part.
const Canvas=preload("res://scripts/ColoringCanvas.gd")
func _initialize() -> void:
	call_deferred("_run")

func _at(canvas: Control, world: Vector2) -> Vector2:
	var scale_value=minf(canvas.size.x/220.0,canvas.size.y/220.0)
	return Vector2(canvas.size.x*.5,canvas.size.y*.52)+world*scale_value

func _run() -> void:
	var canvas=Canvas.new()
	canvas.size=Vector2(510,510)
	root.add_child(canvas)
	await process_frame
	for kind in ["rabbit","cow","meerkat","snake","clownfish","octopus"]:
		canvas.setup(kind,{})
		await process_frame
		var spots: Dictionary={}
		# Find two DIFFERENT visibly exposed body regions without relying on
		# hardcoded drawing indices, across all species.
		for yy in range(-150,105,7):
			if spots.size()>=2: break
			for xx in range(-100,100,7):
				var world=Vector2(xx,yy)
				var hit=canvas.region_at(_at(canvas,world))
				if not hit.is_empty() and not spots.has(hit):
					spots[hit]=_at(canvas,world)
					if spots.size()>=2: break
		if spots.size()<2:
			_fail("Need at least 2 touchable body parts on "+kind)
			return
		var keys=spots.keys()
		var first: String=str(keys[0])
		var second: String=str(keys[1])
		var begin: Vector2=spots[first]
		var finish: Vector2=spots[second]
		canvas.brush_color="#F26A72"
		canvas.begin_stroke(begin)
		if canvas.locked_region!=first:
			_fail(kind+": first touched region was not locked")
			return
		canvas.move_stroke(finish)
		canvas.move_stroke(finish+Vector2(2,1))
		canvas.move_stroke(begin)
		canvas.finish_stroke()
		var strokes: Array=canvas.colors.get("strokes_v2",[])
		if strokes.is_empty():
			_fail(kind+": moving finger produced no pigment in first region")
			return
		for stroke in strokes:
			if str(stroke["region"])!=first:
				_fail(kind+": one finger gesture painted another region "+str(stroke["region"]))
				return
		if canvas.locked_region!="":
			_fail(kind+": lock not cleared on release")
			return
		var initial=strokes.size()
		canvas.begin_stroke(finish)
		canvas.move_stroke(begin)
		canvas.finish_stroke()
		strokes=canvas.colors.get("strokes_v2",[])
		if strokes.size()<=initial:
			_fail(kind+": new touch must be allowed to color a different region")
			return
		for j in range(initial,strokes.size()):
			if str(strokes[j]["region"])!=second:
				_fail(kind+": second gesture did not lock to newly touched region")
				return
		canvas.setup(kind,{})
		canvas.begin_stroke(Vector2(1,1))
		canvas.move_stroke(finish)
		canvas.finish_stroke()
		if not canvas.colors.get("strokes_v2",[]).is_empty():
			_fail(kind+": touch-down on blank paper colored a body part")
			return
	# Never fill a neighbor, even when a very long swipe crosses and exits.
	print("PASS: six species finger strokes stay locked to touched part, no cross-bleed, independent next gesture")
	canvas.queue_free()
	await process_frame
	quit(0)
func _fail(reason: String) -> void:
	push_error("PAINT BOUNDARY TEST FAILED: "+reason)
	quit(1)
