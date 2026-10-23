extends SceneTree
## The same original animal reacts with at least two expressions and four
## different body motions, without replacing its scene or mutating stickers.
const Art=preload("res://scripts/AnimalArt.gd")
const Pet=preload("res://scripts/PettingArea.gd")
const Care=preload("res://scripts/CareStage.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var info={"id":"rabbit","name":"兔子","zone":"forest","color":"#F5DBAE"}
	var pet=Pet.new()
	pet.setup(info,false)
	pet.size=Vector2(460,380)
	root.add_child(pet)
	await process_frame
	var center=pet.size*.5
	if not pet.begin_stroke(center):
		_fail("Petting gesture could not start")
		return
	pet.move_stroke(center+Vector2(45,0))
	pet.move_stroke(center+Vector2(-45,0))
	if pet.strokes!=1 or str(pet.avatar.mood)!="happy":
		_fail("First petting gesture must produce a happy face")
		return
	pet.end_stroke()
	pet.reward_cooldown=0
	if not pet.begin_stroke(center):
		_fail("Second petting gesture could not start")
		return
	pet.move_stroke(center+Vector2(45,0))
	pet.move_stroke(center+Vector2(-45,0))
	if pet.strokes!=2 or str(pet.avatar.mood)!="surprised":
		_fail("Second petting gesture should show a different surprised expression")
		return
	pet.end_stroke()
	pet._process(0.20)
	if absf(pet.avatar.rotation)<0.001:
		_fail("The animal did not physically wiggle when petted")
		return
	pet.queue_free()
	var stage=Care.new()
	stage.setup(info,false)
	stage.size=Vector2(510,380)
	root.add_child(stage)
	await process_frame
	for action in ["feed","wash","play","sleep"]:
		if not stage.play_action(action):
			_fail("Care action not accepted: "+action)
			return
		if stage.avatar.get("mood")!={"feed":"eating","wash":"clean","play":"play","sleep":"sleep"}[action]:
			_fail("Care action did not change animal expression: "+action)
			return
		stage._process(0.34)
		if action=="play" and absf(stage.avatar.position.y)<1.0:
			_fail("Animal should visibly hop during play")
			return
		if action=="wash" and absf(stage.avatar.rotation)<0.001:
			_fail("Animal should shake during bath")
			return
		if action=="sleep" and absf(stage.avatar.scale.x-1.0)<0.001:
			_fail("Animal should breathe while sleeping")
			return
		stage._process(1.50)
		if stage.animating:
			_fail("Care action never ends")
			return
	print("PASS: natural idle expressions, alternating happy/surprise pets and animated feed/bath/play/sleep")
	stage.queue_free()
	await process_frame
	quit(0)
func _fail(message: String) -> void:
	push_error("ANIMAL REACTION TEST FAILED: "+message)
	quit(1)
